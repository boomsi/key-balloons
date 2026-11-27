#include "tray_controls.h"

#include "app_preferences.h"
#include "keyboard_monitor.h"
#include "process_memory.h"

#include <QAction>
#include <QCoreApplication>
#include <QLocale>
#include <QMessageBox>
#include <QPainter>
#include <QPushButton>
#include <QQuickWindow>
#include <QTimer>

#ifdef Q_OS_MACOS
#include "macos/input_monitoring_guide.h"
#endif

namespace {
QIcon trayIcon()
{
    QPixmap image(36, 36);
    image.setDevicePixelRatio(2);
    image.fill(Qt::transparent);

    QPainter painter(&image);
    painter.setRenderHint(QPainter::Antialiasing);
#ifdef Q_OS_MACOS
    painter.setPen(QPen(Qt::black, 1.5));
    painter.setBrush(Qt::NoBrush);
#else
    painter.setPen(QPen(QColor(223, 238, 255), 1.5));
    painter.setBrush(QColor(48, 77, 129));
#endif
    painter.drawRoundedRect(QRectF(2, 10.5, 14, 5.5), 2, 2);
    painter.drawLine(QPointF(5, 13.25), QPointF(13, 13.25));
    painter.save();
    painter.translate(7, 6);
    painter.rotate(-15);
    painter.drawRoundedRect(QRectF(-3, -2.25, 6, 4.5), 1.5, 1.5);
    painter.restore();
    painter.drawRoundedRect(QRectF(12, 2, 3.2, 2.6), 0.9, 0.9);
    painter.end();
    QIcon icon(image);
#ifdef Q_OS_MACOS
    icon.setIsMask(true);
#endif
    return icon;
}
}

TrayControls::TrayControls(KeyboardMonitor &monitor, QQuickWindow &window, AppPreferences &preferences,
                           MouseFeedbackServer &feedback)
    : monitor_(monitor),
      tray_(trayIcon()),
      memory_(menu_.addAction(QString{})),
      status_(menu_.addAction(QString{})),
      toggle_(menu_.addAction(QString{})),
      settings_(menu_.addAction(QString{})),
      quit_(nullptr)
{
    memory_->setEnabled(false);
    status_->setEnabled(false);
    menu_.addSeparator();
    quit_ = menu_.addAction(QString{}, qApp, &QCoreApplication::quit);
    QObject::connect(&menu_, &QMenu::aboutToShow, &tray_, [this] { refreshMemory(); });
    QObject::connect(&preferences, &AppPreferences::languageChanged, &tray_, [this] {
        statusDetail_.clear();
        refreshMenuText();
#ifdef Q_OS_MACOS
        if (permissionGuide_)
            permissionGuide_->retranslate();
#endif
    });
    QObject::connect(settings_, &QAction::triggered, &window, [&window] {
        QMetaObject::invokeMethod(&window, "showSettings", Qt::QueuedConnection);
    });
    QObject::connect(toggle_, &QAction::triggered, &tray_, [this] {
        if (listening_) {
            listening_ = false;
            monitor_.stop();
            setStatus(Status::Paused);
        } else {
            start(true);
        }
    });
    QObject::connect(&monitor_, &KeyboardMonitor::keyPressed, &tray_,
                     [this, &window](const QString &label, bool repeat) {
        if (listening_ && !repeat)
            QMetaObject::invokeMethod(&window, "showKey", Q_ARG(QString, label));
    }, Qt::QueuedConnection);
    QObject::connect(&monitor_, &KeyboardMonitor::mouseFeedback, &tray_, [this, &feedback](MouseFeedback event) {
        if (listening_)
            feedback.publish(event);
    }, Qt::QueuedConnection);
    QObject::connect(&monitor_, &KeyboardMonitor::interrupted, &tray_, [this](const QString &reason) {
        listening_ = false;
        monitor_.stop();
        setStatus(Status::Unavailable, reason);
    }, Qt::QueuedConnection);

    tray_.setContextMenu(&menu_);
    refreshMenuText();
    tray_.show();
}

void TrayControls::start()
{
    start(false);
#ifdef Q_OS_MACOS
    if (!listening_ && !hasMacInputMonitoringPermission()) {
        QTimer::singleShot(0, &tray_, [this] {
            if (listening_)
                return;
            if (hasMacInputMonitoringPermission())
                start(false);
            else
                showStartupPermissionPrompt();
        });
    }
#endif
}

#ifdef Q_OS_MACOS
void TrayControls::showStartupPermissionPrompt()
{
    auto *prompt = new QMessageBox(QMessageBox::Information, tr("Key Balloons"),
        tr("Enable Input Monitoring to show keyboard and mouse input. "
                    "The next step opens System Settings and shows you where to drag Key Balloons."));
    prompt->setAttribute(Qt::WA_DeleteOnClose);
    auto *open = prompt->addButton(tr("Open Input Monitoring"), QMessageBox::AcceptRole);
    auto *dismiss = prompt->addButton(tr("Not Now"), QMessageBox::RejectRole);
    prompt->setDefaultButton(open);
    prompt->setEscapeButton(dismiss);
    QObject::connect(prompt, &QMessageBox::finished, &tray_, [this, prompt, open] {
        if (prompt->clickedButton() == open)
            QTimer::singleShot(0, &tray_, [this] { start(true); });
    });
    prompt->open();
}
#endif

void TrayControls::start(bool requestPermission)
{
#ifdef Q_OS_MACOS
    if (requestPermission && !hasMacInputMonitoringPermission()) {
        if (!permissionGuide_) {
            permissionGuide_ = std::make_unique<InputMonitoringGuide>(
                hasMacInputMonitoringPermission, [this] { start(false); });
        }
        if (!permissionGuide_->open()) {
            QMessageBox::warning(nullptr, tr("Could not open Input Monitoring"),
                tr("Open System Settings, go to Privacy & Security → Input Monitoring, "
                            "then add Key Balloons and turn on its switch."));
        }
        return;
    }
#endif
    const auto error = monitor_.start(false);
    listening_ = error.isEmpty();
    auto status = listening_ ? Status::Running : Status::Unavailable;
#ifdef Q_OS_MACOS
    if (!listening_ && !hasMacInputMonitoringPermission())
        status = Status::PermissionRequired;
#endif
    setStatus(status, error);
    if (!listening_ && requestPermission)
        QMessageBox::information(nullptr, tr("Key Balloons"), error);
}

TrayControls::~TrayControls() = default;

void TrayControls::setStatus(Status status, const QString &detail)
{
    currentStatus_ = status;
    statusDetail_ = detail;
    refreshMenuText();
}

QString TrayControls::statusText() const
{
    switch (currentStatus_) {
    case Status::Paused: return tr("Monitoring paused");
    case Status::Running: return tr("Monitoring keyboard and mouse");
    case Status::Unavailable: return tr("Monitoring unavailable");
    case Status::PermissionRequired: return tr("Input Monitoring required");
    }
    return {};
}

void TrayControls::refreshMenuText()
{
    const auto summary = statusText();
    status_->setText(summary);
    toggle_->setText(listening_ ? tr("Pause monitoring") : tr("Enable monitoring…"));
    settings_->setText(tr("Settings…"));
    quit_->setText(tr("Quit Key Balloons"));
    tray_.setToolTip(statusDetail_.isEmpty() ? tr("Key Balloons · %1").arg(summary) : statusDetail_);
    refreshMemory();
}

void TrayControls::refreshMemory()
{
    const auto bytes = currentProcessMemoryBytes();
    memory_->setVisible(bytes.has_value());
    if (bytes) {
        const double mebibytes = *bytes / (1024.0 * 1024.0);
        memory_->setText(tr("Memory %1 MiB").arg(QLocale().toString(mebibytes, 'f', 1)));
    }
}

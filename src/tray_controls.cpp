#include "tray_controls.h"

#include "keyboard_monitor.h"

#include <QAction>
#include <QCoreApplication>
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

TrayControls::TrayControls(KeyboardMonitor &monitor, QQuickWindow &window)
    : monitor_(monitor),
      tray_(trayIcon()),
      status_(menu_.addAction(QString{})),
      toggle_(menu_.addAction(QString{}))
{
    status_->setEnabled(false);
    menu_.addSeparator();
    menu_.addAction(QObject::tr("Quit Key Balloons"), qApp, &QCoreApplication::quit);
    QObject::connect(toggle_, &QAction::triggered, &tray_, [this] {
        if (listening_) {
            listening_ = false;
            monitor_.stop();
            setStatus(QObject::tr("Monitoring paused"));
        } else {
            start(true);
        }
    });
    QObject::connect(&monitor_, &KeyboardMonitor::keyPressed, &tray_,
                     [this, &window](const QString &label, bool repeat) {
        if (listening_ && !repeat)
            QMetaObject::invokeMethod(&window, "showKey", Q_ARG(QString, label));
    }, Qt::QueuedConnection);
    QObject::connect(&monitor_, &KeyboardMonitor::interrupted, &tray_, [this](const QString &reason) {
        listening_ = false;
        monitor_.stop();
        setStatus(reason);
    }, Qt::QueuedConnection);

    tray_.setContextMenu(&menu_);
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
    auto *prompt = new QMessageBox(QMessageBox::Information, QObject::tr("Key Balloons"),
        QObject::tr("Enable Input Monitoring to show the keys you press. "
                    "The next step opens System Settings and shows you where to drag Key Balloons."));
    prompt->setAttribute(Qt::WA_DeleteOnClose);
    auto *open = prompt->addButton(QObject::tr("Open Input Monitoring"), QMessageBox::AcceptRole);
    auto *dismiss = prompt->addButton(QObject::tr("Not Now"), QMessageBox::RejectRole);
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
            QMessageBox::warning(nullptr, QObject::tr("Could not open Input Monitoring"),
                QObject::tr("Open System Settings, go to Privacy & Security → Input Monitoring, "
                            "then add Key Balloons and turn on its switch."));
        }
        return;
    }
#endif
    const auto error = monitor_.start(false);
    listening_ = error.isEmpty();
    auto status = listening_ ? QObject::tr("Monitoring keyboard") : QObject::tr("Monitoring unavailable");
#ifdef Q_OS_MACOS
    if (!listening_ && !hasMacInputMonitoringPermission())
        status = QObject::tr("Input Monitoring required");
#endif
    setStatus(status);
    if (!listening_) {
        tray_.setToolTip(error);
        if (requestPermission)
            QMessageBox::information(nullptr, QObject::tr("Key Balloons"), error);
    }
}

TrayControls::~TrayControls() = default;

void TrayControls::setStatus(const QString &summary)
{
    status_->setText(summary);
    toggle_->setText(listening_ ? QObject::tr("Pause monitoring")
                               : QObject::tr("Enable monitoring…"));
    tray_.setToolTip(QObject::tr("Key Balloons · %1").arg(summary));
}

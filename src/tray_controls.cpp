#include "tray_controls.h"

#include "keyboard_monitor.h"

#include <QAction>
#include <QCoreApplication>
#include <QMessageBox>
#include <QPainter>
#include <QQuickWindow>

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
    painter.drawRoundedRect(QRectF(2, 9, 14, 6.5), 2, 2);
    painter.drawRoundedRect(QRectF(6.5, 2, 5, 4.5), 1.5, 1.5);
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

void TrayControls::start(bool requestPermission)
{
    const auto error = monitor_.start(requestPermission);
    listening_ = error.isEmpty();
    setStatus(listening_ ? QObject::tr("Monitoring keyboard") : QObject::tr("Monitoring unavailable"));
    if (!listening_) {
        tray_.setToolTip(error);
        if (requestPermission)
            QMessageBox::information(nullptr, QObject::tr("Key Balloons"), error);
    }
}

void TrayControls::setStatus(const QString &summary)
{
    status_->setText(summary);
    toggle_->setText(listening_ ? QObject::tr("Pause monitoring")
                               : QObject::tr("Enable monitoring…"));
    tray_.setToolTip(QObject::tr("Key Balloons · %1").arg(summary));
}

#pragma once

#include <QMenu>
#include <QSystemTrayIcon>

#ifdef Q_OS_MACOS
#include <memory>
class InputMonitoringGuide;
#endif

class KeyboardMonitor;
class QQuickWindow;

class TrayControls
{
public:
    TrayControls(KeyboardMonitor &monitor, QQuickWindow &window);
    ~TrayControls();
    void start(bool requestPermission);

private:
    void setStatus(const QString &summary);

    KeyboardMonitor &monitor_;
    QMenu menu_;
    QSystemTrayIcon tray_;
    QAction *status_;
    QAction *toggle_;
    bool listening_ = false;
#ifdef Q_OS_MACOS
    std::unique_ptr<InputMonitoringGuide> permissionGuide_;
#endif
};

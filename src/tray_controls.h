#pragma once

#include <QMenu>
#include <QSystemTrayIcon>

class KeyboardMonitor;
class QQuickWindow;

class TrayControls
{
public:
    TrayControls(KeyboardMonitor &monitor, QQuickWindow &window);
    void start(bool requestPermission);

private:
    void setStatus(const QString &summary);

    KeyboardMonitor &monitor_;
    QMenu menu_;
    QSystemTrayIcon tray_;
    QAction *status_;
    QAction *toggle_;
    bool listening_ = false;
};

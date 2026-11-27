#pragma once

#include <QMenu>
#include <QObject>
#include <QSystemTrayIcon>

#ifdef Q_OS_MACOS
#include <memory>
class InputMonitoringGuide;
#endif

class KeyboardMonitor;
class MouseFeedbackServer;
class AppPreferences;
class QQuickWindow;

class TrayControls final : public QObject
{
    Q_OBJECT

public:
    TrayControls(KeyboardMonitor &monitor, QQuickWindow &window, AppPreferences &preferences,
                 MouseFeedbackServer &feedback);
    ~TrayControls() override;
    void start();

private:
    enum class Status { Paused, Running, Unavailable, PermissionRequired };

    void start(bool requestPermission);
#ifdef Q_OS_MACOS
    void showStartupPermissionPrompt();
#endif
    void setStatus(Status status, const QString &detail = {});
    void refreshMenuText();
    void refreshMemory();
    QString statusText() const;

    KeyboardMonitor &monitor_;
    QMenu menu_;
    QSystemTrayIcon tray_;
    QAction *memory_;
    QAction *status_;
    QAction *toggle_;
    QAction *settings_;
    QAction *quit_;
    bool listening_ = false;
    Status currentStatus_ = Status::Paused;
    QString statusDetail_;
#ifdef Q_OS_MACOS
    std::unique_ptr<InputMonitoringGuide> permissionGuide_;
#endif
};

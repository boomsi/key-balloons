#pragma once

#include <QObject>

#include <memory>

class QQuickWindow;
class AppPreferences;

class MacSettingsPopover final : public QObject
{
    Q_OBJECT

public:
    static void install(QQuickWindow &overlay, AppPreferences &preferences);
    ~MacSettingsPopover() override;

private slots:
    void show();

private:
    MacSettingsPopover(QQuickWindow &overlay, AppPreferences &preferences);

    struct Native;
    QQuickWindow &overlay_;
    std::unique_ptr<Native> native_;
};

#pragma once

#include <QObject>

#include <memory>

class QQuickWindow;

class MacSettingsPopover final : public QObject
{
    Q_OBJECT

public:
    static void install(QQuickWindow &overlay);
    ~MacSettingsPopover() override;

private slots:
    void toggle();

private:
    explicit MacSettingsPopover(QQuickWindow &overlay);

    struct Native;
    QQuickWindow &overlay_;
    std::unique_ptr<Native> native_;
};

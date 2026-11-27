#pragma once

#include <QRect>

#include <functional>
#include <memory>

bool hasMacInputMonitoringPermission();
QRect inputMonitoringGuideFrame(QRect settings, QRect workArea, QSize size);

class InputMonitoringGuide final
{
public:
    InputMonitoringGuide(std::function<bool()> authorized, std::function<void()> resumeMonitoring);
    ~InputMonitoringGuide();

    bool open();

private:
    void refresh();

    struct Native;
    std::unique_ptr<Native> native_;
};

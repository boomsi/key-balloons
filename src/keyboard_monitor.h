#pragma once

#include <QObject>
#include <QString>

#include <memory>

class KeyboardMonitor : public QObject
{
    Q_OBJECT

public:
    virtual QString start(bool requestPermission) = 0;
    virtual void stop() = 0;

signals:
    void keyPressed(const QString &label, bool autoRepeat);
    void interrupted(const QString &reason);
};

std::unique_ptr<KeyboardMonitor> makeKeyboardMonitor();

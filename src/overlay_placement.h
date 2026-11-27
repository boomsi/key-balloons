#pragma once

#include <QList>
#include <QObject>
#include <QRect>

class QQuickWindow;
class QScreen;

int nearestScreenIndex(QPoint point, const QList<QRect> &screens);
QPoint bottomSnapPosition(const QRect &box, const QRect &workArea);

class OverlayPlacement final : public QObject
{
    Q_OBJECT

public:
    explicit OverlayPlacement(QQuickWindow &window);
    void setSnapEnabled(bool enabled);

private slots:
    void snapToBottom();

private:
    void watchScreen(QScreen *screen);
    void scheduleSnap();

    QQuickWindow &window_;
    bool snapEnabled_ = false;
};

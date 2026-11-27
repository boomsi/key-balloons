#include "overlay_placement.h"

#include <QGuiApplication>
#include <QQuickWindow>
#include <QScreen>
#include <QTimer>

#include <limits>

int nearestScreenIndex(QPoint point, const QList<QRect> &screens)
{
    int nearest = -1;
    auto shortestDistance = std::numeric_limits<qint64>::max();
    for (int index = 0; index < screens.size(); ++index) {
        const auto &screen = screens.at(index);
        const qint64 dx = qBound(screen.left(), point.x(), screen.right()) - qint64(point.x());
        const qint64 dy = qBound(screen.top(), point.y(), screen.bottom()) - qint64(point.y());
        const auto distance = dx * dx + dy * dy;
        if (distance < shortestDistance) {
            nearest = index;
            shortestDistance = distance;
        }
    }
    return nearest;
}

QPoint bottomSnapPosition(const QRect &box, const QRect &workArea)
{
    const int lastX = workArea.left() + qMax(0, workArea.width() - box.width());
    const int lastY = workArea.top() + qMax(0, workArea.height() - box.height());
    return {qBound(workArea.left(), box.x(), lastX), lastY};
}

OverlayPlacement::OverlayPlacement(QQuickWindow &window) : window_(window)
{
    connect(&window_, SIGNAL(snapToBottomRequested()), this, SLOT(snapToBottom()));
    connect(qGuiApp, &QGuiApplication::screenAdded, this, &OverlayPlacement::watchScreen);
    connect(qGuiApp, &QGuiApplication::screenRemoved, this, &OverlayPlacement::scheduleSnap);
    for (auto *screen : QGuiApplication::screens())
        watchScreen(screen);
}

void OverlayPlacement::setSnapEnabled(bool enabled)
{
    snapEnabled_ = enabled;
    snapToBottom();
}

void OverlayPlacement::watchScreen(QScreen *screen)
{
    connect(screen, &QScreen::availableGeometryChanged, this, &OverlayPlacement::scheduleSnap);
    scheduleSnap();
}

void OverlayPlacement::scheduleSnap()
{
    if (snapEnabled_)
        QTimer::singleShot(0, this, &OverlayPlacement::snapToBottom);
}

void OverlayPlacement::snapToBottom()
{
    if (!snapEnabled_ || window_.property("snapDragInProgress").toBool())
        return;

    const auto screens = QGuiApplication::screens();
    QList<QRect> geometries;
    geometries.reserve(screens.size());
    for (const auto *screen : screens)
        geometries.append(screen->geometry());

    const auto box = window_.geometry();
    const int screenIndex = nearestScreenIndex(box.center(), geometries);
    if (screenIndex >= 0) {
        const auto position = bottomSnapPosition(box, screens.at(screenIndex)->availableGeometry());
        if (position != box.topLeft())
            window_.setPosition(position);
    }
}

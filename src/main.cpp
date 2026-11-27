#include "keyboard_monitor.h"
#include "tray_controls.h"

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QScreen>
#include <QTimer>
#include <QtEnvironmentVariables>

#include <cstdlib>

#ifdef Q_OS_MACOS
#include "macos/overlay.h"
#include "macos/settings_popover.h"
#endif

namespace {
void keepOverlayVisible(QQuickWindow &window, QScreen *removedScreen = nullptr)
{
    const auto bounds = window.geometry();
    auto *screen = QGuiApplication::screenAt(bounds.center());
    if (!screen || screen == removedScreen) {
        screen = QGuiApplication::primaryScreen();
        if (screen == removedScreen) {
            screen = nullptr;
            for (auto *remaining : QGuiApplication::screens()) {
                if (remaining != removedScreen) {
                    screen = remaining;
                    break;
                }
            }
        }
    }
    if (!screen)
        return;

    if (screen->geometry().contains(bounds)) {
        if (removedScreen && window.screen() == removedScreen) {
            window.setScreen(screen);
            window.setPosition(bounds.topLeft());
        }
        return;
    }
    const auto area = screen->availableGeometry();
    const auto size = bounds.size().boundedTo(area.size());
    const auto x = qBound(area.left(), bounds.x(), area.right() - size.width() + 1);
    const auto y = qBound(area.top(), bounds.y(), area.bottom() - size.height() + 1);
    if (window.screen() != screen)
        window.setScreen(screen);
    window.setGeometry(x, y, size.width(), size.height());
}

void anchorOverlay(QQuickWindow &window, QApplication &app)
{
    if (auto *screen = app.primaryScreen()) {
        const auto area = screen->availableGeometry();
        const auto size = window.size().boundedTo(area.size());
        const auto x = area.x() + (area.width() - size.width()) / 2;
        const auto y = area.y() + qMax(0, area.height() - size.height() - 12);
        window.setScreen(screen);
        window.setGeometry(x, y, size.width(), size.height());
    }

    const auto watchDisplay = [&window](QScreen *screen) {
        QObject::connect(screen, &QScreen::geometryChanged, &window, [&window] {
            QTimer::singleShot(0, &window, [&window] { keepOverlayVisible(window); });
        });
    };
    for (auto *screen : app.screens())
        watchDisplay(screen);
    QObject::connect(&app, &QGuiApplication::screenAdded, &window, watchDisplay);
    QObject::connect(&app, &QGuiApplication::screenRemoved, &window, [&window](QScreen *screen) {
        keepOverlayVisible(window, screen);
    });
}

void trackSettingsWorkArea(QQuickWindow &window)
{
    auto trackScreen = [&window, geometryChanged = QMetaObject::Connection{}](QScreen *screen) mutable {
        QObject::disconnect(geometryChanged);
        if (!screen)
            return;
        const auto publish = [&window](const QRect &area) {
            window.setProperty("settingsWorkArea", QRectF(area));
        };
        publish(screen->availableGeometry());
        geometryChanged = QObject::connect(screen, &QScreen::availableGeometryChanged,
                                           &window, publish);
    };
    trackScreen(window.screen());
    QObject::connect(&window, &QWindow::screenChanged, &window, trackScreen);
}
}

int main(int argc, char *argv[])
{
    // The render thread must use elapsed time even when the display cannot pace frames.
    qputenv("QSG_USE_SIMPLE_ANIMATION_DRIVER", "1");
    QApplication app(argc, argv);
    QApplication::setApplicationName(QStringLiteral("Key Balloons"));
    QApplication::setApplicationVersion(QStringLiteral("0.1.0"));
    QApplication::setQuitOnLastWindowClosed(false);
    QQuickWindow::setDefaultAlphaBuffer(true);

    QQmlApplicationEngine engine;
    engine.loadFromModule("KeyBalloons", "Main");
    if (engine.rootObjects().isEmpty())
        return EXIT_FAILURE;
    auto &window = *qobject_cast<QQuickWindow *>(engine.rootObjects().first());

    if (!QSystemTrayIcon::isSystemTrayAvailable()) {
        qCritical("Key Balloons requires the system tray to pause or quit.");
        return EXIT_FAILURE;
    }

    anchorOverlay(window, app);
    trackSettingsWorkArea(window);
#ifdef Q_OS_MACOS
    auto *flights = window.property("flightWindow").value<QQuickWindow *>();
    if (!flights) {
        qCritical("Key Balloons could not find the animation window.");
        return EXIT_FAILURE;
    }
    prepareMacOverlayGroup(window, *flights);
    MacSettingsPopover::install(window);
#endif
    window.show();
    auto monitor = makeKeyboardMonitor();
    TrayControls tray(*monitor, window);
    tray.start(false);
    return app.exec();
}

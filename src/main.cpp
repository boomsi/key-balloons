#include "keyboard_monitor.h"
#include "tray_controls.h"

#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QScreen>
#include <QtEnvironmentVariables>

#include <cstdlib>

#ifdef Q_OS_MACOS
#include "macos/overlay.h"
#endif

namespace {
void positionOverlay(QQuickWindow &window, QScreen *screen, const QSize &preferredSize)
{
    if (!screen)
        return;

    const auto area = screen->availableGeometry();
    const auto size = preferredSize.boundedTo(area.size());
    const auto x = area.x() + (area.width() - size.width()) / 2;
    const auto y = area.y() + qMax(0, area.height() - size.height() - 12);
    window.setScreen(screen);
    window.setGeometry(x, y, size.width(), size.height());
}

void anchorOverlay(QQuickWindow &window, QApplication &app)
{
    const auto preferredSize = window.size();
    auto setScreen = [&window, preferredSize, geometryChanged = QMetaObject::Connection{}]
                     (QScreen *screen) mutable {
        QObject::disconnect(geometryChanged);
        positionOverlay(window, screen, preferredSize);
        if (screen) {
            geometryChanged = QObject::connect(screen, &QScreen::availableGeometryChanged, &window,
                                               [&window, screen, preferredSize] {
                positionOverlay(window, screen, preferredSize);
            });
        }
    };
    setScreen(app.primaryScreen());
    QObject::connect(&app, &QGuiApplication::primaryScreenChanged, &window, setScreen);
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
#ifdef Q_OS_MACOS
    prepareMacOverlay(window);
    auto *flights = window.property("flightWindow").value<QQuickWindow *>();
    if (!flights) {
        qCritical("Key Balloons could not find the animation window.");
        return EXIT_FAILURE;
    }
    prepareMacOverlay(*flights);
#endif
    window.show();
    auto monitor = makeKeyboardMonitor();
    TrayControls tray(*monitor, window);
    tray.start(false);
    return app.exec();
}

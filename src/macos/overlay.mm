#include "overlay.h"

#include <QWindow>
#import <AppKit/AppKit.h>

void prepareMacOverlay(QWindow &window)
{
    auto *view = reinterpret_cast<NSView *>(window.winId());
    NSWindow *nativeWindow = view.window;
    // AppKit panels hide on deactivation by default. The overlay belongs above other apps.
    nativeWindow.hidesOnDeactivate = NO;
}

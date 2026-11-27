#include "overlay.h"

#include <QPlatformSurfaceEvent>
#include <QPointer>
#include <QTimer>
#include <QWindow>
#import <AppKit/AppKit.h>

namespace {
NSWindow *nativeWindow(QWindow *window)
{
    if (!window || !window->handle())
        return nil;
    auto *view = reinterpret_cast<NSView *>(window->winId());
    return view.window;
}

void configureOverlay(NSWindow *window)
{
    window.hidesOnDeactivate = NO;
    const auto conflicting = NSWindowCollectionBehaviorMoveToActiveSpace
        | NSWindowCollectionBehaviorFullScreenPrimary | NSWindowCollectionBehaviorFullScreenNone
        | NSWindowCollectionBehaviorPrimary | NSWindowCollectionBehaviorAuxiliary;
    const auto acrossSpaces = NSWindowCollectionBehaviorCanJoinAllSpaces
        | NSWindowCollectionBehaviorFullScreenAuxiliary
        | NSWindowCollectionBehaviorCanJoinAllApplications;
    window.collectionBehavior = (window.collectionBehavior & ~conflicting) | acrossSpaces;
}

class MacOverlayGroup final : public QObject
{
public:
    MacOverlayGroup(QWindow &box, QWindow &animation)
        : QObject(&box), box_(&box), animation_(&animation)
    {
        box.create();
        animation.create();
        refresh();
        box.installEventFilter(this);
        animation.installEventFilter(this);
    }

protected:
    bool eventFilter(QObject *, QEvent *event) override
    {
        if (event->type() == QEvent::Show
            || (event->type() == QEvent::PlatformSurface
                && static_cast<QPlatformSurfaceEvent *>(event)->surfaceEventType()
                    == QPlatformSurfaceEvent::SurfaceCreated)) {
            QTimer::singleShot(0, this, [this] { refresh(); });
        }
        return false;
    }

private:
    void refresh()
    {
        NSWindow *box = nativeWindow(box_);
        NSWindow *animation = nativeWindow(animation_);
        configureOverlay(box);
        configureOverlay(animation);
        if (box && animation && box_->isVisible() && animation_->isVisible()
            && animation.parentWindow != box) {
            [box addChildWindow:animation ordered:NSWindowAbove];
        }
    }

    QPointer<QWindow> box_;
    QPointer<QWindow> animation_;
};
}

void prepareMacOverlayGroup(QWindow &box, QWindow &animation)
{
    new MacOverlayGroup(box, animation);
}

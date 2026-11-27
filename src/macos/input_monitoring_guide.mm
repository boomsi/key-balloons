#include "input_monitoring_guide.h"

#include <QElapsedTimer>
#include <QGuiApplication>
#include <QScreen>
#include <QTimer>

#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>
#import <QuartzCore/QuartzCore.h>

#include <array>
#include <utility>

namespace {
const QSize guideSize(290, 110);
constexpr auto settingsIntervalMs = 400;

QRect settingsWindowBounds(pid_t pid)
{
    NSArray<NSDictionary *> *windows = CFBridgingRelease(CGWindowListCopyWindowInfo(
        kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID));
    for (NSDictionary *window in windows) {
        if ([window[(__bridge NSString *)kCGWindowOwnerPID] intValue] != pid
            || [window[(__bridge NSString *)kCGWindowLayer] intValue] != 0)
            continue;

        CGRect frame = CGRectZero;
        auto bounds = (__bridge CFDictionaryRef)window[(__bridge NSString *)kCGWindowBounds];
        if (bounds && CGRectMakeWithDictionaryRepresentation(bounds, &frame)
            && frame.size.width >= 400 && frame.size.height >= 300) {
            return QRectF(frame.origin.x, frame.origin.y, frame.size.width, frame.size.height)
                .toAlignedRect();
        }
    }
    return {};
}
}

QRect inputMonitoringGuideFrame(QRect settings, QRect workArea, QSize size)
{
    constexpr int gap = 10;
    size = size.boundedTo(workArea.size());
    const int right = workArea.right() - size.width() + 1;
    const int bottom = workArea.bottom() - size.height() + 1;
    const int centeredX = qBound(workArea.left(), settings.center().x() - (size.width() - 1) / 2, right);
    const int centeredY = qBound(workArea.top(), settings.center().y() - (size.height() - 1) / 2, bottom);
    const std::array candidates{
        QRect(QPoint(centeredX, settings.bottom() + 1 + gap), size),
        QRect(QPoint(centeredX, settings.top() - gap - size.height()), size),
        QRect(QPoint(settings.right() + 1 + gap, centeredY), size),
        QRect(QPoint(settings.left() - gap - size.width(), centeredY), size)
    };
    for (const auto &candidate : candidates) {
        if (workArea.contains(candidate))
            return candidate;
    }
    return QRect(QPoint(right, bottom), size);
}

@interface KeyBalloonsPermissionTile : NSView <NSDraggingSource>
@property (nonatomic, readonly, getter=isDragging) BOOL dragging;
- (instancetype)initWithFrame:(NSRect)frame bundleURL:(NSURL *)bundleURL;
- (NSDraggingItem *)dragItem;
@end

@implementation KeyBalloonsPermissionTile {
    NSURL *bundleURL_;
    NSImage *icon_;
    BOOL dragging_;
}

- (instancetype)initWithFrame:(NSRect)frame bundleURL:(NSURL *)bundleURL
{
    self = [super initWithFrame:frame];
    if (!self)
        return nil;

    bundleURL_ = bundleURL;
    icon_ = [NSWorkspace.sharedWorkspace iconForFile:bundleURL.path];
    self.wantsLayer = YES;
    self.layer.cornerRadius = 10;
    self.layer.backgroundColor = [NSColor.controlBackgroundColor colorWithAlphaComponent:0.7].CGColor;

    auto *image = [[NSImageView alloc] initWithFrame:NSMakeRect(9, 6, 31, 31)];
    image.image = icon_;
    [self addSubview:image];
    auto *name = [NSTextField labelWithString:@"Key Balloons"];
    name.font = [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold];
    name.frame = NSMakeRect(49, 13, frame.size.width - 56, 17);
    [self addSubview:name];
    return self;
}

- (NSView *)hitTest:(NSPoint)point
{
    return [super hitTest:point] ? self : nil;
}

- (BOOL)isDragging
{
    return dragging_;
}

- (NSDraggingItem *)dragItem
{
    return [[NSDraggingItem alloc] initWithPasteboardWriter:bundleURL_];
}

- (void)mouseDragged:(NSEvent *)event
{
    if (dragging_)
        return;
    auto *item = [self dragItem];
    const NSPoint mouse = [self convertPoint:event.locationInWindow fromView:nil];
    [item setDraggingFrame:NSMakeRect(mouse.x - 17, mouse.y - 17, 34, 34) contents:icon_];
    dragging_ = YES;
    [self beginDraggingSessionWithItems:@[item] event:event source:self];
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session
    sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    return NSDragOperationCopy;
}

- (void)draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)point
              operation:(NSDragOperation)operation
{
    dragging_ = NO;
}
@end

namespace {
NSTextField *guideLabel(NSString *text, NSRect frame)
{
    auto *label = [NSTextField labelWithString:text];
    label.frame = frame;
    label.alignment = NSTextAlignmentCenter;
    return label;
}

NSPanel *makeGuidePanel(KeyBalloonsPermissionTile **tile)
{
    const auto frame = NSMakeRect(0, 0, guideSize.width(), guideSize.height());
    const auto style = NSWindowStyleMaskBorderless | NSWindowStyleMaskNonactivatingPanel;
    auto *panel = [[NSPanel alloc] initWithContentRect:frame styleMask:style
                                             backing:NSBackingStoreBuffered defer:NO];
    panel.title = @"Key Balloons — Input Monitoring";
    panel.floatingPanel = YES;
    panel.level = NSFloatingWindowLevel;
    panel.hidesOnDeactivate = NO;
    panel.opaque = NO;
    panel.backgroundColor = NSColor.clearColor;
    panel.hasShadow = YES;
    panel.collectionBehavior = NSWindowCollectionBehaviorMoveToActiveSpace
        | NSWindowCollectionBehaviorFullScreenAuxiliary;

    auto *background = [[NSVisualEffectView alloc] initWithFrame:frame];
    background.material = NSVisualEffectMaterialPopover;
    background.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    background.state = NSVisualEffectStateActive;
    background.wantsLayer = YES;
    background.layer.cornerRadius = 14;
    background.layer.masksToBounds = YES;

    auto *heading = guideLabel(NSLocalizedString(@"Drag into Input Monitoring", nil),
                               NSMakeRect(12, 83, 266, 17));
    heading.font = [NSFont systemFontOfSize:13 weight:NSFontWeightSemibold];
    [background addSubview:heading];

    *tile = [[KeyBalloonsPermissionTile alloc] initWithFrame:NSMakeRect(59, 31, 172, 43)
                                                   bundleURL:NSBundle.mainBundle.bundleURL];
    [background addSubview:*tile];

    auto *hint = guideLabel(NSLocalizedString(@"Remove an old entry before adding again.", nil),
                            NSMakeRect(8, 9, 274, 15));
    hint.font = [NSFont systemFontOfSize:10];
    hint.textColor = NSColor.secondaryLabelColor;
    [background addSubview:hint];
    panel.contentView = background;
    return panel;
}
}

struct InputMonitoringGuide::Native {
    NSPanel *panel = nil;
    KeyBalloonsPermissionTile *tile = nil;
    QTimer timer;
    QElapsedTimer opening;
    std::function<bool()> authorized;
    std::function<void()> resumeMonitoring;
    bool sawSettings = false;
    bool sawWindow = false;

    void dismiss()
    {
        timer.stop();
        [panel orderOut:nil];
    }
};

bool hasMacInputMonitoringPermission()
{
    return CGPreflightListenEventAccess();
}

InputMonitoringGuide::InputMonitoringGuide(std::function<bool()> authorized,
                                           std::function<void()> resumeMonitoring)
    : native_(std::make_unique<Native>())
{
    native_->authorized = std::move(authorized);
    native_->resumeMonitoring = std::move(resumeMonitoring);
    KeyBalloonsPermissionTile *tile = nil;
    native_->panel = makeGuidePanel(&tile);
    native_->tile = tile;
    QObject::connect(&native_->timer, &QTimer::timeout, [this] { refresh(); });
}

InputMonitoringGuide::~InputMonitoringGuide()
{
    native_->dismiss();
}

bool InputMonitoringGuide::open()
{
    auto *workspace = NSWorkspace.sharedWorkspace;
    auto *url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ListenEvent"];
    if (![workspace openURL:url]
        && ![workspace openURL:[NSURL URLWithString:@"x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"]])
        return false;

    native_->opening.start();
    native_->sawSettings = false;
    native_->sawWindow = false;
    native_->timer.start(settingsIntervalMs);
    refresh();
    return true;
}

void InputMonitoringGuide::refresh()
{
    if (native_->tile.isDragging)
        return;
    if (native_->authorized()) {
        native_->dismiss();
        native_->resumeMonitoring();
        return;
    }

    auto *settings = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.systempreferences"].firstObject;
    if (!settings) {
        if (native_->sawSettings || native_->opening.hasExpired(10000))
            native_->dismiss();
        return;
    }
    native_->sawSettings = true;

    if (!settings.active) {
        [native_->panel orderOut:nil];
        if (native_->timer.interval() != 1000)
            native_->timer.setInterval(1000);
        return;
    }
    if (native_->timer.interval() != settingsIntervalMs)
        native_->timer.setInterval(settingsIntervalMs);

    const auto bounds = settingsWindowBounds(settings.processIdentifier);
    if (bounds.isEmpty()) {
        if (native_->sawWindow)
            native_->dismiss();
        return;
    }
    native_->sawWindow = true;
    auto *screen = QGuiApplication::screenAt(bounds.center());
    if (!screen)
        screen = QGuiApplication::primaryScreen();
    if (!screen)
        return;

    const auto frame = inputMonitoringGuideFrame(bounds, screen->availableGeometry(), guideSize);
    const auto desktopTop = NSMaxY(NSScreen.screens.firstObject.frame);
    const auto cocoaFrame = NSMakeRect(frame.x(), desktopTop - frame.y() - frame.height(),
                                       frame.width(), frame.height());
    if (!NSEqualRects(native_->panel.frame, cocoaFrame))
        [native_->panel setFrame:cocoaFrame display:YES];
    if (!native_->panel.visible)
        [native_->panel orderFrontRegardless];
}

#include "settings_popover.h"

#include <QPointer>
#include <QQuickWindow>

#import <AppKit/AppKit.h>

#include <cmath>

namespace {
constexpr NSSize settingsSize = {224, 158};

NSStackView *settingsRow(NSView *label, NSView *control)
{
    auto *row = [[NSStackView alloc] init];
    row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    row.alignment = NSLayoutAttributeCenterY;
    [row addView:label inGravity:NSStackViewGravityLeading];
    [row addView:control inGravity:NSStackViewGravityTrailing];
    return row;
}

NSTextField *percentageLabel()
{
    auto *label = [NSTextField labelWithString:@"100%"];
    label.font = [NSFont monospacedDigitSystemFontOfSize:NSFont.systemFontSize weight:NSFontWeightRegular];
    return label;
}
}

@interface KeyBalloonsSettingsContent : NSViewController
- (instancetype)initWithOverlay:(QQuickWindow *)overlay;
- (void)updateControls;
@end

@implementation KeyBalloonsSettingsContent {
    QPointer<QQuickWindow> overlay_;
    NSSwitch *dragging_;
    NSSlider *opacity_;
    NSTextField *opacityPercentage_;
    NSSlider *size_;
    NSTextField *sizePercentage_;
}

- (instancetype)initWithOverlay:(QQuickWindow *)overlay
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
        overlay_ = overlay;
    return self;
}

- (void)loadView
{
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, settingsSize.width, settingsSize.height)];

    dragging_ = [[NSSwitch alloc] init];
    dragging_.controlSize = NSControlSizeSmall;
    dragging_.target = self;
    dragging_.action = @selector(changeDragging:);
    [dragging_ setAccessibilityLabel:NSLocalizedString(@"Allow dragging", nil)];

    opacity_ = [NSSlider sliderWithValue:100 minValue:20 maxValue:100
                                 target:self action:@selector(changeOpacity:)];
    opacity_.continuous = YES;
    [opacity_ setAccessibilityLabel:NSLocalizedString(@"Opacity", nil)];

    opacityPercentage_ = percentageLabel();

    size_ = [NSSlider sliderWithValue:100 minValue:overlay_->property("minimumSizePercent").toInt()
                             maxValue:overlay_->property("maximumSizePercent").toInt()
                               target:self action:@selector(changeSize:)];
    size_.continuous = YES;
    [size_ setAccessibilityLabel:NSLocalizedString(@"Size", nil)];
    sizePercentage_ = percentageLabel();

    auto *draggingRow = settingsRow([NSTextField labelWithString:NSLocalizedString(@"Allow dragging", nil)],
                                   dragging_);
    auto *opacityRow = settingsRow([NSTextField labelWithString:NSLocalizedString(@"Opacity", nil)],
                                   opacityPercentage_);
    auto *sizeRow = settingsRow([NSTextField labelWithString:NSLocalizedString(@"Size", nil)],
                                sizePercentage_);
    auto *stack = [NSStackView stackViewWithViews:@[draggingRow, opacityRow, opacity_, sizeRow, size_]];
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.alignment = NSLayoutAttributeLeading;
    stack.spacing = 8;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:14],
        [stack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-14],
        [stack.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [draggingRow.widthAnchor constraintEqualToAnchor:stack.widthAnchor],
        [opacityRow.widthAnchor constraintEqualToAnchor:stack.widthAnchor],
        [opacity_.widthAnchor constraintEqualToAnchor:stack.widthAnchor],
        [sizeRow.widthAnchor constraintEqualToAnchor:stack.widthAnchor],
        [size_.widthAnchor constraintEqualToAnchor:stack.widthAnchor],
    ]];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    auto *window = self.view.window;
    [window makeKeyWindow];
    [window makeFirstResponder:dragging_];
}

- (void)updateControls
{
    (void)self.view;
    dragging_.state = overlay_->property("allowDragging").toBool() ? NSControlStateValueOn
                                                                  : NSControlStateValueOff;
    const auto opacityPercent = overlay_->property("opacityPercent").toInt();
    opacity_.integerValue = opacityPercent;
    opacityPercentage_.stringValue = [NSString stringWithFormat:@"%d%%", opacityPercent];
    const auto sizePercent = overlay_->property("sizePercent").toInt();
    size_.integerValue = sizePercent;
    sizePercentage_.stringValue = [NSString stringWithFormat:@"%d%%", sizePercent];
}

- (void)changeDragging:(NSSwitch *)sender
{
    if (overlay_)
        overlay_->setProperty("allowDragging", sender.state == NSControlStateValueOn);
}

- (void)changeOpacity:(NSSlider *)sender
{
    const auto percent = static_cast<int>(std::lround(sender.doubleValue));
    if (overlay_)
        overlay_->setProperty("opacityPercent", percent);
    opacityPercentage_.stringValue = [NSString stringWithFormat:@"%d%%", percent];
}

- (void)changeSize:(NSSlider *)sender
{
    const auto percent = static_cast<int>(std::lround(sender.doubleValue));
    if (overlay_)
        overlay_->setProperty("sizePercent", percent);
    sizePercentage_.stringValue = [NSString stringWithFormat:@"%d%%", percent];
}

@end

struct MacSettingsPopover::Native {
    NSPopover *popover;
    KeyBalloonsSettingsContent *content;
    id activationObserver;
};

MacSettingsPopover::MacSettingsPopover(QQuickWindow &overlay)
    : QObject(&overlay), overlay_(overlay), native_(std::make_unique<Native>())
{
    native_->popover = [[NSPopover alloc] init];
    native_->content = [[KeyBalloonsSettingsContent alloc] initWithOverlay:&overlay];
    native_->popover.behavior = NSPopoverBehaviorTransient;
    native_->popover.contentViewController = native_->content;
    native_->popover.contentSize = settingsSize;

    auto *workspace = NSWorkspace.sharedWorkspace;
    const auto ownPid = NSRunningApplication.currentApplication.processIdentifier;
    __weak NSPopover *popover = native_->popover;
    native_->activationObserver =
        [workspace.notificationCenter addObserverForName:NSWorkspaceDidActivateApplicationNotification
                                                   object:workspace
                                                    queue:NSOperationQueue.mainQueue
                                               usingBlock:^(NSNotification *notification) {
        NSRunningApplication *application = notification.userInfo[NSWorkspaceApplicationKey];
        if (application && application.processIdentifier != ownPid && popover.shown)
            [popover close];
    }];
}

MacSettingsPopover::~MacSettingsPopover()
{
    [NSWorkspace.sharedWorkspace.notificationCenter removeObserver:native_->activationObserver];
    [native_->popover close];
}

void MacSettingsPopover::install(QQuickWindow &overlay)
{
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 260000
    if (@available(macOS 26.0, *)) {
        auto *settings = new MacSettingsPopover(overlay);
        if (QObject::connect(&overlay, SIGNAL(nativeSettingsRequested()), settings, SLOT(toggle()))) {
            overlay.setProperty("nativeSettingsEnabled", true);
        } else {
            delete settings;
        }
    }
#else
    Q_UNUSED(overlay);
#endif
}

void MacSettingsPopover::toggle()
{
    if (native_->popover.shown) {
        [native_->popover performClose:nil];
        return;
    }

    auto *view = (__bridge NSView *)reinterpret_cast<void *>(overlay_.winId());
    if (!view.window)
        return;

    [native_->content updateControls];
    const NSRect box = [view.window convertRectToScreen:[view convertRect:view.bounds toView:nil]];
    const NSRect workArea = view.window.screen.visibleFrame;
    const CGFloat requiredWidth = settingsSize.width + 20;
    const bool fitsRight = NSMaxX(workArea) - NSMaxX(box) >= requiredWidth;
    const bool fitsLeft = NSMinX(box) - NSMinX(workArea) >= requiredWidth;
    const NSRectEdge side = fitsRight || !fitsLeft ? NSMaxXEdge : NSMinXEdge;
    if (!NSApp.active)
        [NSApp activate];
    [native_->popover showRelativeToRect:view.bounds ofView:view preferredEdge:side];
}

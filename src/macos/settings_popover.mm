#include "settings_popover.h"

#include "../app_preferences.h"

#include <QCoreApplication>
#include <QPointer>
#include <QQuickWindow>

#import <AppKit/AppKit.h>

#include <cmath>

namespace {
constexpr CGFloat panelWidth = 310;
constexpr CGFloat panelPadding = 14;

NSString *settingsText(const char *source)
{
    return QCoreApplication::translate("Main", source).toNSString();
}

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

NSTextField *sectionLabel()
{
    auto *label = [NSTextField labelWithString:@""];
    label.font = [NSFont systemFontOfSize:NSFont.systemFontSize weight:NSFontWeightSemibold];
    return label;
}

NSSwitch *settingsSwitch(id target, SEL action)
{
    auto *control = [[NSSwitch alloc] init];
    control.controlSize = NSControlSizeSmall;
    control.target = target;
    control.action = action;
    return control;
}

void addStack(NSView *view, NSStackView *stack, NSArray<NSView *> *fullWidth)
{
    stack.orientation = NSUserInterfaceLayoutOrientationVertical;
    stack.alignment = NSLayoutAttributeLeading;
    stack.spacing = 8;
    stack.detachesHiddenViews = YES;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:stack];
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:view.leadingAnchor constant:panelPadding],
        [stack.trailingAnchor constraintEqualToAnchor:view.trailingAnchor constant:-panelPadding],
        [stack.topAnchor constraintEqualToAnchor:view.topAnchor constant:panelPadding],
    ]];
    for (NSView *row in fullWidth)
        [row.widthAnchor constraintEqualToAnchor:stack.widthAnchor].active = YES;
}
}

@interface KeyBalloonsSettingsContent : NSViewController <NSPopoverDelegate>
- (instancetype)initWithOverlay:(QQuickWindow *)overlay
                   preferences:(AppPreferences *)preferences
                       popover:(NSPopover *)popover;
- (void)prepareToShow;
- (void)focusWindow;
- (void)retranslate;
@end

@implementation KeyBalloonsSettingsContent {
    QPointer<QQuickWindow> overlay_;
    QPointer<AppPreferences> preferences_;
    __weak NSPopover *popover_;
    id localClickMonitor_;
    id globalClickMonitor_;
    bool needsInitialFocus_;
    NSStackView *stack_;
    NSTextField *appearanceHeading_;
    NSTextField *positionHeading_;
    NSTextField *draggingLabel_;
    NSTextField *snapLabel_;
    NSTextField *integrationsLabel_;
    NSTextField *languageLabel_;
    NSTextField *opacityLabel_;
    NSTextField *sizeLabel_;
    NSSwitch *dragging_;
    NSSwitch *snap_;
    NSSwitch *integrations_;
    NSSlider *opacity_;
    NSSlider *size_;
    NSTextField *opacityPercentage_;
    NSTextField *sizePercentage_;
    NSPopUpButton *language_;
    NSButton *advancedButton_;
    NSStackView *integrationsRow_;
}

- (instancetype)initWithOverlay:(QQuickWindow *)overlay
                   preferences:(AppPreferences *)preferences
                       popover:(NSPopover *)popover
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        overlay_ = overlay;
        preferences_ = preferences;
        popover_ = popover;
    }
    return self;
}

- (void)makeAppearanceControls
{
    appearanceHeading_ = sectionLabel();
    opacityLabel_ = [NSTextField labelWithString:@""];
    sizeLabel_ = [NSTextField labelWithString:@""];
    opacity_ = [NSSlider sliderWithValue:100 minValue:20 maxValue:100
                                 target:self action:@selector(changeOpacity:)];
    size_ = [NSSlider sliderWithValue:100 minValue:overlay_->property("minimumSizePercent").toInt()
                             maxValue:overlay_->property("maximumSizePercent").toInt()
                               target:self action:@selector(changeSize:)];
    opacity_.continuous = YES;
    size_.continuous = YES;
    opacityPercentage_ = percentageLabel();
    sizePercentage_ = percentageLabel();
}

- (void)makePreferenceControls
{
    positionHeading_ = sectionLabel();
    draggingLabel_ = [NSTextField labelWithString:@""];
    snapLabel_ = [NSTextField labelWithString:@""];
    integrationsLabel_ = [NSTextField labelWithString:@""];
    languageLabel_ = [NSTextField labelWithString:@""];
    dragging_ = settingsSwitch(self, @selector(changeDragging:));
    snap_ = settingsSwitch(self, @selector(changeSnap:));
    integrations_ = settingsSwitch(self, @selector(changeIntegrations:));
    language_ = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    language_.target = self;
    language_.action = @selector(changeLanguage:);
    for (const auto &entry : preferences_->languages()) {
        const auto language = entry.toMap();
        [language_ addItemWithTitle:language.value(QStringLiteral("label")).toString().toNSString()];
        language_.lastItem.representedObject = language.value(QStringLiteral("code")).toString().toNSString();
    }
    advancedButton_ = [NSButton buttonWithTitle:@"" target:self action:@selector(toggleAdvanced:)];
    advancedButton_.bordered = NO;
    advancedButton_.alignment = NSTextAlignmentLeft;
}

- (void)loadView
{
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, panelWidth, 300)];
    [self makeAppearanceControls];
    [self makePreferenceControls];

    auto *opacityRow = settingsRow(opacityLabel_, opacityPercentage_);
    auto *sizeRow = settingsRow(sizeLabel_, sizePercentage_);
    auto *draggingRow = settingsRow(draggingLabel_, dragging_);
    auto *snapRow = settingsRow(snapLabel_, snap_);
    auto *languageRow = settingsRow(languageLabel_, language_);
    integrationsRow_ = settingsRow(integrationsLabel_, integrations_);
    stack_ = [NSStackView stackViewWithViews:@[
        appearanceHeading_, opacityRow, opacity_, sizeRow, size_, positionHeading_,
        draggingRow, snapRow, languageRow, advancedButton_, integrationsRow_,
    ]];
    addStack(self.view, stack_, @[opacityRow, opacity_, sizeRow, size_, draggingRow, snapRow,
                                languageRow]);
    [integrationsRow_.widthAnchor constraintEqualToConstant:panelWidth - 2 * panelPadding].active = YES;
    integrationsRow_.hidden = YES;
}

- (void)focusWindow
{
    auto *window = self.view.window;
    if (!window)
        return;
    [window makeKeyWindow];
    if (needsInitialFocus_) {
        [window makeFirstResponder:nil];
        needsInitialFocus_ = !window.isKeyWindow;
    }
}

- (void)popoverWillShow:(NSNotification *)notification
{
    needsInitialFocus_ = true;
    const auto clicks = NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown | NSEventMaskOtherMouseDown;
    __weak NSPopover *popover = popover_;
    localClickMonitor_ = [NSEvent addLocalMonitorForEventsMatchingMask:clicks handler:^NSEvent *(NSEvent *event) {
        NSPopover *current = popover;
        NSWindow *window = current.contentViewController.view.window;
        if (current.shown && window && event.window != window && event.window.parentWindow != window)
            [current close];
        return event;
    }];
    globalClickMonitor_ = [NSEvent addGlobalMonitorForEventsMatchingMask:clicks handler:^(NSEvent *) {
        if (popover.shown)
            [popover close];
    }];
}

- (void)popoverDidShow:(NSNotification *)notification
{
    [self focusWindow];
}

- (void)removeClickMonitors
{
    if (localClickMonitor_) {
        [NSEvent removeMonitor:localClickMonitor_];
        localClickMonitor_ = nil;
    }
    if (globalClickMonitor_) {
        [NSEvent removeMonitor:globalClickMonitor_];
        globalClickMonitor_ = nil;
    }
}

- (void)popoverWillClose:(NSNotification *)notification
{
    [self removeClickMonitors];
}

- (void)dealloc
{
    [self removeClickMonitors];
}

- (void)retranslate
{
    if (!self.isViewLoaded)
        return;
    appearanceHeading_.stringValue = settingsText("Appearance");
    positionHeading_.stringValue = settingsText("Position");
    opacityLabel_.stringValue = settingsText("Opacity");
    sizeLabel_.stringValue = settingsText("Size");
    draggingLabel_.stringValue = settingsText("Allow dragging");
    snapLabel_.stringValue = settingsText("Snap box to screen bottom");
    integrationsLabel_.stringValue = settingsText("Allow local mouse integrations");
    languageLabel_.stringValue = settingsText("Language");
    [opacity_ setAccessibilityLabel:opacityLabel_.stringValue];
    [size_ setAccessibilityLabel:sizeLabel_.stringValue];
    [dragging_ setAccessibilityLabel:draggingLabel_.stringValue];
    [snap_ setAccessibilityLabel:snapLabel_.stringValue];
    [integrations_ setAccessibilityLabel:integrationsLabel_.stringValue];
    [language_ setAccessibilityLabel:languageLabel_.stringValue];
    [self updateAdvancedButton];
}

- (void)updateAdvancedButton
{
    NSString *arrow = integrationsRow_.hidden ? @"▸ " : @"▾ ";
    advancedButton_.title = [arrow stringByAppendingString:settingsText("Advanced")];
}

- (void)resizePopover
{
    [self.view layoutSubtreeIfNeeded];
    popover_.contentSize = NSMakeSize(panelWidth, std::ceil(stack_.fittingSize.height) + 2 * panelPadding);
}

- (void)prepareToShow
{
    (void)self.view;
    integrationsRow_.hidden = YES;
    [self retranslate];
    dragging_.state = overlay_->property("allowDragging").toBool() ? NSControlStateValueOn : NSControlStateValueOff;
    snap_.state = preferences_->autoSnapToBottom() ? NSControlStateValueOn : NSControlStateValueOff;
    integrations_.enabled = preferences_->integrationsAvailable();
    integrations_.state = preferences_->integrationsEnabled() ? NSControlStateValueOn : NSControlStateValueOff;

    const auto opacityPercent = overlay_->property("opacityPercent").toInt();
    opacity_.integerValue = opacityPercent;
    opacityPercentage_.stringValue = [NSString stringWithFormat:@"%d%%", opacityPercent];
    const auto sizePercent = overlay_->property("sizePercent").toInt();
    size_.integerValue = sizePercent;
    sizePercentage_.stringValue = [NSString stringWithFormat:@"%d%%", sizePercent];

    NSString *currentCode = preferences_->language().toNSString();
    for (NSMenuItem *item in language_.itemArray) {
        if ([currentCode isEqualToString:item.representedObject]) {
            [language_ selectItem:item];
            break;
        }
    }
    [self resizePopover];
}

- (void)toggleAdvanced:(NSButton *)sender
{
    integrationsRow_.hidden = !integrationsRow_.hidden;
    [self updateAdvancedButton];
    [self resizePopover];
}

- (void)changeDragging:(NSSwitch *)sender
{
    if (overlay_)
        overlay_->setProperty("allowDragging", sender.state == NSControlStateValueOn);
}

- (void)changeSnap:(NSSwitch *)sender
{
    if (preferences_)
        preferences_->setAutoSnapToBottom(sender.state == NSControlStateValueOn);
}

- (void)changeIntegrations:(NSSwitch *)sender
{
    if (!preferences_)
        return;
    preferences_->setIntegrationsEnabled(sender.state == NSControlStateValueOn);
    sender.state = preferences_->integrationsEnabled() ? NSControlStateValueOn : NSControlStateValueOff;
}

- (void)changeLanguage:(NSPopUpButton *)sender
{
    if (preferences_)
        preferences_->setLanguage(QString::fromNSString(sender.selectedItem.representedObject));
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
    id appActivationObserver;
};

MacSettingsPopover::MacSettingsPopover(QQuickWindow &overlay, AppPreferences &preferences)
    : QObject(&overlay), overlay_(overlay), native_(std::make_unique<Native>())
{
    native_->popover = [[NSPopover alloc] init];
    native_->content = [[KeyBalloonsSettingsContent alloc] initWithOverlay:&overlay
        preferences:&preferences popover:native_->popover];
    native_->popover.behavior = NSPopoverBehaviorTransient;
    native_->popover.contentViewController = native_->content;
    native_->popover.delegate = native_->content;
    connect(&preferences, &AppPreferences::languageChanged, this, [this] { [native_->content retranslate]; });

    __weak NSPopover *popover = native_->popover;
    __weak KeyBalloonsSettingsContent *content = native_->content;
    native_->appActivationObserver = [NSNotificationCenter.defaultCenter
        addObserverForName:NSApplicationDidBecomeActiveNotification object:NSApp queue:nil
        usingBlock:^(NSNotification *) {
        if (popover.shown)
            [content focusWindow];
    }];

    auto *workspace = NSWorkspace.sharedWorkspace;
    const auto ownPid = NSRunningApplication.currentApplication.processIdentifier;
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
    [NSNotificationCenter.defaultCenter removeObserver:native_->appActivationObserver];
    [NSWorkspace.sharedWorkspace.notificationCenter removeObserver:native_->activationObserver];
    [native_->popover close];
}

void MacSettingsPopover::install(QQuickWindow &overlay, AppPreferences &preferences)
{
#if __MAC_OS_X_VERSION_MAX_ALLOWED >= 260000
    if (@available(macOS 26.0, *)) {
        auto *settings = new MacSettingsPopover(overlay, preferences);
        if (QObject::connect(&overlay, SIGNAL(nativeSettingsRequested()), settings, SLOT(show()))) {
            overlay.setProperty("nativeSettingsEnabled", true);
        } else {
            delete settings;
        }
    }
#else
    Q_UNUSED(overlay);
    Q_UNUSED(preferences);
#endif
}

void MacSettingsPopover::show()
{
    if (!NSApp.active)
        [NSApp activate];
    if (native_->popover.shown) {
        [native_->content focusWindow];
        return;
    }

    auto *view = (__bridge NSView *)reinterpret_cast<void *>(overlay_.winId());
    if (!view.window)
        return;

    [native_->content prepareToShow];
    const NSRect box = [view.window convertRectToScreen:[view convertRect:view.bounds toView:nil]];
    const NSRect workArea = view.window.screen.visibleFrame;
    const CGFloat requiredWidth = panelWidth + 20;
    const bool fitsRight = NSMaxX(workArea) - NSMaxX(box) >= requiredWidth;
    const bool fitsLeft = NSMinX(box) - NSMinX(workArea) >= requiredWidth;
    const NSRectEdge side = fitsRight || !fitsLeft ? NSMaxXEdge : NSMinXEdge;
    [native_->popover showRelativeToRect:view.bounds ofView:view preferredEdge:side];
    [native_->content focusWindow];
}

#include "../keyboard_monitor.h"

#include <ApplicationServices/ApplicationServices.h>
#include <Carbon/Carbon.h>
#include <IOKit/hidsystem/IOLLEvent.h>

#include <array>

namespace {
struct Modifier {
    UInt16 code;
    CGEventFlags flag;
    const char16_t *label;
};

constexpr std::array modifiers{
    Modifier{kVK_Command, NX_DEVICELCMDKEYMASK, u"⌘"},
    Modifier{kVK_RightCommand, NX_DEVICERCMDKEYMASK, u"⌘"},
    Modifier{kVK_Shift, NX_DEVICELSHIFTKEYMASK, u"⇧"},
    Modifier{kVK_RightShift, NX_DEVICERSHIFTKEYMASK, u"⇧"},
    Modifier{kVK_Control, NX_DEVICELCTLKEYMASK, u"⌃"},
    Modifier{kVK_RightControl, NX_DEVICERCTLKEYMASK, u"⌃"},
    Modifier{kVK_Option, NX_DEVICELALTKEYMASK, u"⌥"},
    Modifier{kVK_RightOption, NX_DEVICERALTKEYMASK, u"⌥"},
    Modifier{kVK_CapsLock, 0, u"Caps"},
    Modifier{kVK_Function, kCGEventFlagMaskSecondaryFn, u"Fn"},
};

QString modifierLabel(UInt16 key, CGEventFlags flags)
{
    for (const auto &modifier : modifiers) {
        if (modifier.code == key && (modifier.flag == 0 || (flags & modifier.flag)))
            return QString(modifier.label);
    }
    return {};
}

QString namedKey(UInt16 key)
{
    constexpr std::array functionKeys{
        kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6, kVK_F7, kVK_F8, kVK_F9,
        kVK_F10, kVK_F11, kVK_F12, kVK_F13, kVK_F14, kVK_F15, kVK_F16, kVK_F17,
        kVK_F18, kVK_F19, kVK_F20,
    };
    for (std::size_t i = 0; i < functionKeys.size(); ++i) {
        if (functionKeys[i] == key)
            return QStringLiteral("F%1").arg(i + 1);
    }

    switch (key) {
    case kVK_Return: return QStringLiteral("↵");
    case kVK_ANSI_KeypadEnter: return QStringLiteral("⌅");
    case kVK_Tab: return QStringLiteral("Tab");
    case kVK_Space: return QStringLiteral("Space");
    case kVK_Delete: return QStringLiteral("⌫");
    case kVK_ForwardDelete: return QStringLiteral("Del");
    case kVK_Escape: return QStringLiteral("Esc");
    case kVK_LeftArrow: return QStringLiteral("←");
    case kVK_RightArrow: return QStringLiteral("→");
    case kVK_UpArrow: return QStringLiteral("↑");
    case kVK_DownArrow: return QStringLiteral("↓");
    case kVK_Home: return QStringLiteral("Home");
    case kVK_End: return QStringLiteral("End");
    case kVK_PageUp: return QStringLiteral("PgUp");
    case kVK_PageDown: return QStringLiteral("PgDn");
    case kVK_Help: return QStringLiteral("Help");
    default: return {};
    }
}

QString layoutLabel(UInt16 key)
{
    const auto inputSource = TISCopyCurrentKeyboardLayoutInputSource();
    if (!inputSource)
        return {};

    const auto data = static_cast<CFDataRef>(
        TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData));
    std::array<UniChar, 8> text{};
    UniCharCount count = 0;
    UInt32 deadKey = 0;
    OSStatus result = paramErr;
    if (data) {
        const auto layout = reinterpret_cast<const UCKeyboardLayout *>(CFDataGetBytePtr(data));
        result = UCKeyTranslate(layout, key, kUCKeyActionDisplay, 0, LMGetKbdType(),
                                kUCKeyTranslateNoDeadKeysMask, &deadKey, text.size(),
                                &count, text.data());
    }
    CFRelease(inputSource);

    if (result != noErr || count == 0 || !QChar(text.front()).isPrint())
        return {};

    return QString::fromUtf16(reinterpret_cast<const char16_t *>(text.data()), count).toUpper();
}

class MacKeyboardMonitor final : public KeyboardMonitor
{
    Q_DECLARE_TR_FUNCTIONS(MacKeyboardMonitor)

public:
    ~MacKeyboardMonitor() override { stop(); }

    QString start(bool requestPermission) override
    {
        if (tap_)
            return {};

        const bool allowed = CGPreflightListenEventAccess()
            || (requestPermission && CGRequestListenEventAccess());
        if (!allowed) {
            return tr("Allow Key Balloons in System Settings → Privacy & Security → "
                      "Input Monitoring, then retry or reopen the app.");
        }

        const auto events = CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventFlagsChanged)
            | CGEventMaskBit(kCGEventLeftMouseDown) | CGEventMaskBit(kCGEventRightMouseDown)
            | CGEventMaskBit(kCGEventOtherMouseDown) | CGEventMaskBit(kCGEventScrollWheel);
        tap_ = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, kCGEventTapOptionListenOnly,
                                events, readEvent, this);
        if (!tap_)
            return tr("macOS could not start the keyboard listener.");

        source_ = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap_, 0);
        if (!source_) {
            stop();
            return tr("macOS could not attach the keyboard listener to the event loop.");
        }

        CFRunLoopAddSource(CFRunLoopGetMain(), source_, kCFRunLoopCommonModes);
        CGEventTapEnable(tap_, true);
        return {};
    }

    void stop() override
    {
        if (!tap_)
            return;

        CGEventTapEnable(tap_, false);
        if (source_) {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source_, kCFRunLoopCommonModes);
            CFRelease(source_);
            source_ = nullptr;
        }
        CFMachPortInvalidate(tap_);
        CFRelease(tap_);
        tap_ = nullptr;
    }

private:
    bool readMouseEvent(CGEventType type, CGEventRef event)
    {
        switch (type) {
        case kCGEventLeftMouseDown:
            emit mouseFeedback(MouseFeedback::Left);
            return true;
        case kCGEventRightMouseDown:
            emit mouseFeedback(MouseFeedback::Right);
            return true;
        case kCGEventOtherMouseDown:
            if (CGEventGetIntegerValueField(event, kCGMouseEventButtonNumber) == kCGMouseButtonCenter)
                emit mouseFeedback(MouseFeedback::Wheel);
            return true;
        case kCGEventScrollWheel:
            if (CGEventGetIntegerValueField(event, kCGScrollWheelEventPointDeltaAxis1)
                || CGEventGetIntegerValueField(event, kCGScrollWheelEventPointDeltaAxis2)
                || CGEventGetIntegerValueField(event, kCGScrollWheelEventDeltaAxis1)
                || CGEventGetIntegerValueField(event, kCGScrollWheelEventDeltaAxis2)) {
                emit mouseFeedback(MouseFeedback::Wheel);
            }
            return true;
        default:
            return false;
        }
    }

    static CGEventRef readEvent(CGEventTapProxy, CGEventType type, CGEventRef event, void *context)
    {
        auto &monitor = *static_cast<MacKeyboardMonitor *>(context);
        if (type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput) {
            if (CGPreflightListenEventAccess())
                CGEventTapEnable(monitor.tap_, true);
            else
                emit monitor.interrupted(tr("Keyboard monitoring permission was removed."));
            return event;
        }
        if (monitor.readMouseEvent(type, event))
            return event;

        const auto code = static_cast<UInt16>(
            CGEventGetIntegerValueField(event, kCGKeyboardEventKeycode));
        if (type == kCGEventFlagsChanged) {
            const auto label = modifierLabel(code, CGEventGetFlags(event));
            if (!label.isEmpty())
                emit monitor.keyPressed(label, false);
            return event;
        }

        const bool repeat = CGEventGetIntegerValueField(event, kCGKeyboardEventAutorepeat) != 0;
        auto label = namedKey(code);
        if (label.isEmpty())
            label = layoutLabel(code);
        if (!label.isEmpty())
            emit monitor.keyPressed(label, repeat);
        return event;
    }

    CFMachPortRef tap_ = nullptr;
    CFRunLoopSourceRef source_ = nullptr;
};
}

std::unique_ptr<KeyboardMonitor> makeKeyboardMonitor()
{
    return std::make_unique<MacKeyboardMonitor>();
}

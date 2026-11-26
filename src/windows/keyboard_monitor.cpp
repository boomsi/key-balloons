#include "../keyboard_monitor.h"

#ifndef NOMINMAX
#define NOMINMAX
#endif
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <ntddkbd.h>

#include <set>
#include <utility>

namespace {
constexpr wchar_t receiverClass[] = L"KeyBalloons.RawKeyboardReceiver";
constexpr USHORT genericDesktopUsagePage = 0x01;
constexpr USHORT keyboardUsage = 0x06;

QString namedKey(USHORT key)
{
    if (key >= VK_F1 && key <= VK_F24)
        return QStringLiteral("F%1").arg(key - VK_F1 + 1);
    if (key >= VK_NUMPAD0 && key <= VK_NUMPAD9)
        return QString::number(key - VK_NUMPAD0);

    switch (key) {
    case VK_RETURN: return QStringLiteral("↵");
    case VK_TAB: return QStringLiteral("Tab");
    case VK_SPACE: return QStringLiteral("Space");
    case VK_BACK: return QStringLiteral("⌫");
    case VK_DELETE: return QStringLiteral("Del");
    case VK_ESCAPE: return QStringLiteral("Esc");
    case VK_LEFT: return QStringLiteral("←");
    case VK_RIGHT: return QStringLiteral("→");
    case VK_UP: return QStringLiteral("↑");
    case VK_DOWN: return QStringLiteral("↓");
    case VK_HOME: return QStringLiteral("Home");
    case VK_END: return QStringLiteral("End");
    case VK_PRIOR: return QStringLiteral("PgUp");
    case VK_NEXT: return QStringLiteral("PgDn");
    case VK_INSERT: return QStringLiteral("Ins");
    case VK_SHIFT: case VK_LSHIFT: case VK_RSHIFT: return QStringLiteral("Shift");
    case VK_CONTROL: case VK_LCONTROL: case VK_RCONTROL: return QStringLiteral("Ctrl");
    case VK_MENU: case VK_LMENU: case VK_RMENU: return QStringLiteral("Alt");
    case VK_LWIN: case VK_RWIN: return QStringLiteral("Win");
    case VK_CAPITAL: return QStringLiteral("Caps");
    case VK_NUMLOCK: return QStringLiteral("Num");
    case VK_SNAPSHOT: return QStringLiteral("PrtSc");
    case VK_SCROLL: return QStringLiteral("Scroll");
    case VK_PAUSE: return QStringLiteral("Pause");
    case VK_ADD: return QStringLiteral("+");
    case VK_SUBTRACT: return QStringLiteral("−");
    case VK_MULTIPLY: return QStringLiteral("×");
    case VK_DIVIDE: return QStringLiteral("÷");
    case VK_VOLUME_MUTE: return QStringLiteral("Mute");
    case VK_VOLUME_DOWN: return QStringLiteral("Vol−");
    case VK_VOLUME_UP: return QStringLiteral("Vol+");
    default: return {};
    }
}

QString layoutLabel(const RAWKEYBOARD &key)
{
    const auto thread = GetWindowThreadProcessId(GetForegroundWindow(), nullptr);
    const auto layout = GetKeyboardLayout(thread);
    const auto mapped = MapVirtualKeyExW(key.VKey, MAPVK_VK_TO_CHAR, layout);
    const QChar symbol(static_cast<char16_t>(mapped & 0xffff));
    return symbol.isPrint() ? QString(symbol).toUpper() : QString{};
}

QString windowsError(const QString &message, DWORD code)
{
    return message + QStringLiteral(" (Win32 %1).").arg(code);
}

class WindowsKeyboardMonitor final : public KeyboardMonitor
{
public:
    ~WindowsKeyboardMonitor() override { stop(); }

    QString start(bool) override
    {
        if (receiver_)
            return {};

        const HINSTANCE instance = GetModuleHandleW(nullptr);
        WNDCLASSW windowClass{};
        windowClass.lpfnWndProc = dispatch;
        windowClass.hInstance = instance;
        windowClass.lpszClassName = receiverClass;
        if (!RegisterClassW(&windowClass))
            return windowsError(tr("Could not register the keyboard receiver"), GetLastError());

        receiver_ = CreateWindowExW(0, receiverClass, L"", 0, 0, 0, 0, 0,
                                    HWND_MESSAGE, nullptr, instance, this);
        if (!receiver_) {
            const auto error = GetLastError();
            UnregisterClassW(receiverClass, instance);
            return windowsError(tr("Could not create the keyboard receiver"), error);
        }

        const RAWINPUTDEVICE registration{
            genericDesktopUsagePage, keyboardUsage, RIDEV_INPUTSINK | RIDEV_DEVNOTIFY, receiver_,
        };
        if (!RegisterRawInputDevices(&registration, 1, sizeof(registration))) {
            const auto error = GetLastError();
            stop();
            return windowsError(tr("Could not start global keyboard monitoring"), error);
        }
        registered_ = true;
        return {};
    }

    void stop() override
    {
        if (!receiver_)
            return;

        if (registered_) {
            const RAWINPUTDEVICE removal{genericDesktopUsagePage, keyboardUsage, RIDEV_REMOVE, nullptr};
            if (!RegisterRawInputDevices(&removal, 1, sizeof(removal)))
                emit interrupted(windowsError(tr("Could not unregister the keyboard receiver"), GetLastError()));
            registered_ = false;
        }
        DestroyWindow(receiver_);
        UnregisterClassW(receiverClass, GetModuleHandleW(nullptr));
        receiver_ = nullptr;
        pressed_.clear();
    }

private:
    static LRESULT CALLBACK dispatch(HWND window, UINT message, WPARAM wParam, LPARAM lParam)
    {
        if (message == WM_NCCREATE) {
            const auto *creation = reinterpret_cast<const CREATESTRUCTW *>(lParam);
            SetWindowLongPtrW(window, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(creation->lpCreateParams));
        }

        auto *monitor = reinterpret_cast<WindowsKeyboardMonitor *>(
            GetWindowLongPtrW(window, GWLP_USERDATA));
        if (monitor && message == WM_INPUT)
            monitor->readInput(reinterpret_cast<HRAWINPUT>(lParam));
        if (monitor && message == WM_INPUT_DEVICE_CHANGE && wParam == GIDC_REMOVAL)
            monitor->removeDevice(reinterpret_cast<HANDLE>(lParam));

        // Foreground WM_INPUT requires DefWindowProc to release the message data.
        return DefWindowProcW(window, message, wParam, lParam);
    }

    void readInput(HRAWINPUT message)
    {
        RAWINPUT input{};
        UINT size = sizeof(input);
        if (GetRawInputData(message, RID_INPUT, &input, &size, sizeof(RAWINPUTHEADER)) == UINT(-1)
            || input.header.dwType != RIM_TYPEKEYBOARD) {
            return;
        }

        const auto &key = input.data.keyboard;
        if (key.MakeCode == KEYBOARD_OVERRUN_MAKE_CODE || key.VKey >= 0xff)
            return;

        const auto scanCode = key.MakeCode == 0 ? key.VKey : key.MakeCode;
        const auto extended = key.Flags & (RI_KEY_E0 | RI_KEY_E1);
        const KeyId id{reinterpret_cast<quintptr>(input.header.hDevice),
                       (quint32(extended) << 16) | scanCode};
        if (key.Flags & RI_KEY_BREAK) {
            pressed_.erase(id);
            return;
        }

        const bool repeat = !pressed_.insert(id).second;
        auto label = namedKey(key.VKey);
        if (label.isEmpty())
            label = layoutLabel(key);
        if (!label.isEmpty())
            emit keyPressed(label, repeat);
    }

    void removeDevice(HANDLE device)
    {
        const auto address = reinterpret_cast<quintptr>(device);
        auto key = pressed_.lower_bound({address, 0});
        while (key != pressed_.end() && key->first == address)
            key = pressed_.erase(key);
    }

    using KeyId = std::pair<quintptr, quint32>;
    HWND receiver_ = nullptr;
    bool registered_ = false;
    std::set<KeyId> pressed_;
};
}

std::unique_ptr<KeyboardMonitor> makeKeyboardMonitor()
{
    return std::make_unique<WindowsKeyboardMonitor>();
}

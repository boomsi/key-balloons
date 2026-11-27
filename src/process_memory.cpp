#include "process_memory.h"

#ifdef Q_OS_MACOS
#include <mach/mach.h>
#elif defined(Q_OS_WIN)
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <psapi.h>
#endif

std::optional<quint64> currentProcessMemoryBytes()
{
#ifdef Q_OS_MACOS
    mach_task_basic_info_data_t memory{};
    mach_msg_type_number_t count = MACH_TASK_BASIC_INFO_COUNT;
    if (task_info(mach_task_self(), MACH_TASK_BASIC_INFO, reinterpret_cast<task_info_t>(&memory), &count)
        == KERN_SUCCESS) {
        return memory.resident_size;
    }
#elif defined(Q_OS_WIN)
    PROCESS_MEMORY_COUNTERS memory{};
    memory.cb = sizeof(memory);
    if (K32GetProcessMemoryInfo(GetCurrentProcess(), &memory, memory.cb))
        return memory.WorkingSetSize;
#endif
    return std::nullopt;
}

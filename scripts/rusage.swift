// Prints a process' cumulative CPU time and wake-up counters (proc_pid_rusage):
// "<cpu_ms> <interrupt_wakeups> <idle_wakeups> <footprint_bytes>"
// Usage: swift scripts/rusage.swift <pid>
import Darwin

guard CommandLine.arguments.count == 2, let pid = Int32(CommandLine.arguments[1]) else {
    print("usage: rusage <pid>")
    exit(2)
}
var info = rusage_info_v4()
let rc = withUnsafeMutablePointer(to: &info) { pointer in
    pointer.withMemoryRebound(to: rusage_info_t?.self, capacity: 1) { proc_pid_rusage(pid, RUSAGE_INFO_V4, $0) }
}
guard rc == 0 else {
    print("proc_pid_rusage failed for \(pid)")
    exit(1)
}
var timebase = mach_timebase_info_data_t()
mach_timebase_info(&timebase)
let cpuNanos = (info.ri_user_time + info.ri_system_time) * UInt64(timebase.numer) / UInt64(timebase.denom)
print(cpuNanos / 1_000_000, info.ri_interrupt_wkups, info.ri_pkg_idle_wkups, info.ri_phys_footprint)

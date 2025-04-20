const std = @import("std");
const microzig = @import("microzig");

const MicroBuild = microzig.MicroBuild(.{
    .rp2xxx = true,
});

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const mz_dep = b.dependency("microzig", .{});
    const mb = MicroBuild.init(b, mz_dep) orelse return;

    const firmware = mb.add_firmware(.{
        .name = "pico-dns",
        .target = mb.ports.rp2xxx.boards.raspberrypi.pico,
        .optimize = .ReleaseSmall,
        .root_source_file = b.path("src/main.zig"),
    });

    mb.install_firmware(firmware, .{});
    mb.install_firmware(firmware, .{ .format = .elf });
}

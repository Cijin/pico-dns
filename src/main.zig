const std = @import("std");
const microzig = @import("microzig");
const ssd1306 = @import("./ssd1306.zig");
const rp2040 = microzig.hal;
const time = microzig.drivers.time;
const i2c = rp2040.i2c;
const gpio = rp2040.gpio;

// Compile-time pin configuration
const pin_config = rp2040.pins.GlobalConfiguration{
    .GPIO25 = .{
        .name = "led",
        .direction = .out,
    },
};

const pins = pin_config.pins();
const i2c0 = i2c.instance.num(0);

pub fn main() !void {
    pin_config.apply();
    const sda_pin = gpio.num(0);
    const scl_pin = gpio.num(1);
    inline for (&.{ scl_pin, sda_pin }) |pin| {
        pin.set_slew_rate(.slow);
        pin.set_schmitt_trigger(.enabled);
        pin.set_function(.i2c);
    }

    i2c0.apply(.{
        .clock_config = rp2040.clock_config,
    }) catch {
        pins.led.put(1);
    };

    ssd1306.init(i2c0) catch {
        pins.led.put(1);
    };

    const a = [_]u8{
        0x00,
        0x20,
        0x50,
        0x88,
        0x88,
        0xF8,
        0x88,
        0x88,
        0x00,
        0x00,
    };
    var buf: [512]u8 = .{0x00} ** 512;
    // this gets printed but the orientation is not coorect
    for (0..a.len) |i| {
        buf[i] = a[i];
    }
    var r_idx: usize = 0;
    _ = &r_idx;
    ssd1306.write_data(i2c0, buf[r_idx..buf.len]) catch {
        pins.led.put(1);
    };
}

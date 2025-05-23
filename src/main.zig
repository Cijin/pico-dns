const std = @import("std");
const microzig = @import("microzig");
const ssd1306 = @import("ssd1306.zig");
const esp01s = @import("esp01s.zig");
const font = @import("font.zig");
const assert = std.debug.assert;
const rp2040 = microzig.hal;
const i2c = rp2040.i2c;
const gpio = rp2040.gpio;

const pin_config = rp2040.pins.GlobalConfiguration{
    .GPIO25 = .{
        .name = "led",
        .direction = .out,
    },
};

const pins = pin_config.pins();
const i2c0 = i2c.instance.num(0);

// Todo:
// * Use smaller font size for display
// * Connect to Wifi
// * How much can you monitor without connecting to the Wifi?
// * Monitoring DNS lookup?
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
        return;
    };

    ssd1306.init(i2c0) catch {
        pins.led.put(1);
        return;
    };

    write_line("Display: Ok") catch {
        pins.led.put(1);
        return;
    };

    var buf: [256]u8 = .{0} ** 256;
    var temp_buf: [256]u8 = .{0} ** 256;
    const code = esp01s.init(&buf);
    const codeString = std.fmt.bufPrint(&temp_buf, "{d}", .{code}) catch {
        pins.led.put(1);
        return;
    };

    write_line(codeString) catch {
        pins.led.put(1);
        return;
    };

    write_line(&buf) catch {
        pins.led.put(1);
        return;
    };

    return;
}

fn write_line(str: []const u8) !void {
    var buf: [128]u8 = .{0x00} ** 128;
    var bitmap: [6]u8 = undefined;
    var idx: usize = 0;
    assert(str.len < buf.len);

    for (str) |char| {
        assert((char - font.asscii_offset) <= font.bitmap.len);
        assert((char - font.asscii_offset) >= 0);
        assert(str.len + idx <= buf.len);

        bitmap = font.bitmap[char - font.asscii_offset];
        for (0..bitmap.len) |i| {
            buf[idx] = bitmap[i];
            idx += 1;
        }
    }

    try ssd1306.write_data(i2c0, buf[0..buf.len]);
}

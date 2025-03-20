const std = @import("std");
const microzig = @import("microzig");
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

const CONTROL_COMMAND = 0x00;
const CONTROL_DATA = 0x40;
const COMMAND_ADDRESSING_MODE = 0x20;
const COMMAND_COLUMN_ADDRESS = 0x21;
const COMMAND_PAGE_ADDRESS = 0x22;
const init = [_]u8{ CONTROL_COMMAND, 0xAE, CONTROL_COMMAND, 0xA8, 0x1F, CONTROL_COMMAND, 0xD3, 0x00, CONTROL_COMMAND, 0x40, CONTROL_COMMAND, 0xA0, CONTROL_COMMAND, 0xC0, CONTROL_COMMAND, 0xDA, 0x02, CONTROL_COMMAND, 0x81, 0x7F, CONTROL_COMMAND, 0xA4, CONTROL_COMMAND, 0xD5, 0x80, CONTROL_COMMAND, 0x8D, 0x14, CONTROL_COMMAND, 0xAF };

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

    const a: i2c.Address = @enumFromInt(0x3C);

    i2c0.write_blocking(a, &init, time.Duration.from_ms(500)) catch {
        pins.led.put(1);
    };

    const addressingMode = [3]u8{ CONTROL_COMMAND, COMMAND_ADDRESSING_MODE, 0x00 };
    i2c0.write_blocking(a, &addressingMode, time.Duration.from_ms(500)) catch {
        pins.led.put(1);
    };

    const columnAddress = [_]u8{
        CONTROL_COMMAND,
        COMMAND_COLUMN_ADDRESS,
        0x00,
        0x7F,
        COMMAND_PAGE_ADDRESS,
        0x00,
        0x03,
    };
    i2c0.write_blocking(a, &columnAddress, time.Duration.from_ms(500)) catch {
        pins.led.put(1);
    };

    var buf: [512]u8 = .{0x00} ** 512;
    for (0..buf.len) |i| {
        var data = [2]u8{ CONTROL_DATA, buf[i] };
        i2c0.write_blocking(a, &data, time.Duration.from_ms(500)) catch {
            pins.led.put(1);
        };
    }

    buf = .{0x01} ** 512;
    for (0..buf.len) |i| {
        var data = [2]u8{ CONTROL_DATA, buf[i] };
        i2c0.write_blocking(a, &data, time.Duration.from_ms(500)) catch {
            pins.led.put(1);
        };
    }
}

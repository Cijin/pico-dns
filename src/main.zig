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
const init = [_]u8{ CONTROL_COMMAND, 0xAE, CONTROL_COMMAND, 0xA8, 0x1F, CONTROL_COMMAND, 0xD3, 0x00, CONTROL_COMMAND, 0x40, CONTROL_COMMAND, 0xA0, CONTROL_COMMAND, 0xC0, CONTROL_COMMAND, 0xDA, 0x02, CONTROL_COMMAND, 0x81, 0x7F, CONTROL_COMMAND, 0xA4, CONTROL_COMMAND, 0xD5, 0x80, CONTROL_COMMAND, 0x8D, 0x14, CONTROL_COMMAND, 0xAF };

const i2c0 = i2c.instance.num(0);

pub fn main() !void {
    pin_config.apply();

    i2c0.apply(.{
        .clock_config = rp2040.clock_config,
    }) catch {
        pins.led.put(0);
    };

    const a: i2c.Address = @enumFromInt(0x3C);
    i2c0.write_blocking(a, &init, time.Duration.from_ms(500)) catch {
        pins.led.put(1);
    };
}
// Todo:
// 1. Slave address bit: 0  1 1 1 1 0 SA0 R/W# ---> 0x3C for write | 0x3D for read
// 2. ACK
// 3. Control byte: C0 D/C# 0 0 0 0 0 0 ---> 0x80 control byte | 0x40 next byte saved to GDDRAM
// 4. ACK
// 5. Control byte: ...
// 6. ACK
// 7. ...
// 8 STOP
//
// Turn OLED Display On in normal mode: 0xAF
// Sleep mode: 0xAE
// To turn display on: 0xA5
//
//

const microzig = @import("microzig");
const rp2040 = microzig.hal;
const time = microzig.drivers.time;
const i2c = rp2040.i2c;

const CONTROL_COMMAND = 0x00;
const CONTROL_DATA = 0x40;
const COMMAND_ADDRESSING_MODE = 0x20;
const COMMAND_COLUMN_ADDRESS = 0x21;
const COMMAND_PAGE_ADDRESS = 0x22;
const VERTICAL_SHIFT = 0xD3;
const COLUMN_PIN_CONFIG = 0xDA;

const INIT_SEQUENCE = [_]u8{
    CONTROL_COMMAND,
    0xAE,
    CONTROL_COMMAND,
    0xA8,
    0x1F,
    CONTROL_COMMAND,
    0xD3,
    0x00,
    CONTROL_COMMAND,
    0x40,
    CONTROL_COMMAND,
    0xA0,
    CONTROL_COMMAND,
    0xC0,
    CONTROL_COMMAND,
    0xDA,
    0x02,
    CONTROL_COMMAND,
    0x81,
    0x7F,
    CONTROL_COMMAND,
    0xA4,
    CONTROL_COMMAND,
    0xD5,
    0x80,
    CONTROL_COMMAND,
    0x8D,
    0x14,
    CONTROL_COMMAND,
    0xAF,
};

const a: i2c.Address = @enumFromInt(0x3C);

// Todo:
// 1. Switch to page adressing
// 2. Create method to allow going to the next page
// 3. Note: column should reset to 0 when updating page
// 4. This is the last thing to be done, we can move on to ??

pub fn init(pin: i2c.I2C) !void {
    try pin.write_blocking(a, &INIT_SEQUENCE, time.Duration.from_ms(500));

    const addressingMode = [3]u8{ CONTROL_COMMAND, COMMAND_ADDRESSING_MODE, 0x00 };
    try pin.write_blocking(a, &addressingMode, time.Duration.from_ms(500));

    const column_page_address = [_]u8{
        CONTROL_COMMAND,
        COMMAND_COLUMN_ADDRESS,
        0x00,
        0x7F,
        CONTROL_COMMAND,
        COMMAND_PAGE_ADDRESS,
        0x00,
        0x03,
    };
    try pin.write_blocking(a, &column_page_address, time.Duration.from_ms(500));

    const reset_orientation = [_]u8{
        CONTROL_COMMAND,
        0xA1,
        CONTROL_COMMAND,
        0xC8,
    };
    try pin.write_blocking(a, &reset_orientation, time.Duration.from_ms(500));

    const buf: [512]u8 = .{0x00} ** 512;
    for (0..buf.len) |i| {
        try pin.write_blocking(a, &[2]u8{ CONTROL_DATA, buf[i] }, null);
    }
}

pub fn write_data(pin: i2c.I2C, data: []const u8) !void {
    for (0..data.len) |i| {
        try pin.write_blocking(a, &[2]u8{ CONTROL_DATA, data[i] }, null);
    }
}

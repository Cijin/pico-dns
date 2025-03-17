const microzig = @import("microzig");
const rp2040 = microzig.hal;
const gpio = microzig.gpio;
const i2c = rp2040.i2c;
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
const i2c0 = i2c.num(0);
_ = i2c0.apply(.{
    .clock_config = rp2040.clock_config,
    .scl_pin =  gpio.num(1),
    .sda_pin = gpio.num(0),
    .baud_rate = 4000,
})

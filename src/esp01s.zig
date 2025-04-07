const microzig = @import("microzig");
const rp2040 = microzig.hal;
const clock = rp2040.clocks;
const gpio = rp2040.gpio;
const uart = rp2040.uart.instance.num(0);
const RecieveError = rp2040.uart.ReceiveError;
const time = microzig.drivers.time;

const BAUD_RATE = 74880;
const uart_tx = gpio.num(16);
const uart_rx = gpio.num(17);

pub fn init(buf: []u8) u8 {
    inline for (&.{ uart_tx, uart_rx }) |pin| {
        pin.set_function(.uart);
    }

    uart.apply(.{
        .clock_config = rp2040.clock_config,
        .baud_rate = BAUD_RATE,
    });

    uart.write_blocking("AT", time.Duration.from_ms(100)) catch {
        return 10;
    };

    // Todo: fix this, it currently fails with an error for framing error
    uart.read_blocking(buf, time.Duration.from_ms(100)) catch |err| {
        if (err == RecieveError.OverrunError) {
            return 20;
        }
        if (err == RecieveError.BreakError) {
            return 21;
        }
        if (err == RecieveError.ParityError) {
            return 22;
        }
        if (err == RecieveError.FramingError) {
            return 23;
        }
        if (err == RecieveError.Timeout) {
            return 24;
        }
        return 20;
    };

    return 0;
}

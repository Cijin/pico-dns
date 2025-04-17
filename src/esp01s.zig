const microzig = @import("microzig");

const t = microzig.drivers.time;
const rp2040 = microzig.hal;
const clock = rp2040.clocks;
const gpio = rp2040.gpio;
const time = rp2040.time;
const ReceiveError = rp2040.uart.ReceiveError;

const uart = rp2040.uart.instance.num(0);
const BAUD_RATE = 115200;
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

    uart.write_blocking("AT+CWMODE?\r\n", t.Duration.from_ms(100)) catch {
        uart.clear_errors();
        return 10;
    };

    uart.read_blocking(buf, t.Duration.from_ms(100)) catch |err| {
        uart.clear_errors();
        if (err == ReceiveError.OverrunError) {
            return 20;
        }
        if (err == ReceiveError.BreakError) {
            return 21;
        }
        if (err == ReceiveError.ParityError) {
            return 22;
        }
        if (err == ReceiveError.FramingError) {
            return 23;
        }
        if (err == ReceiveError.Timeout) {
            return 24;
        }
        return 20;
    };

    return 0;
}

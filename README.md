# UART in Verilog

8N1 UART transmitter and receiver, verified with self-checking testbenches in Icarus Verilog.

## Files
- `uart_tx.v`: transmitter (IDLE/START/DATA/STOP state machine)
- `uart_rx.v`: receiver (2-flip-flop input synchronizer, mid-bit sampling, start-bit glitch rejection)
- `tb_uart_tx.v`: self-checking TX testbench; samples the TX line mid-bit and rebuilds each byte
- `tb_uart_loopback.v`: connects TX to RX and checks every byte (7 directed corner cases + 50 random bytes, with a timeout)

## How to run
```
iverilog -o loop_sim uart_tx.v uart_rx.v tb_uart_loopback.v
vvp loop_sim
```
Expected: `ALL 57 TESTS PASSED`

## Design notes
- Frame format: 1 start bit, 8 data bits (LSB first), 1 stop bit, no parity
- `CLKS_PER_BIT` parameter sets the baud rate (clock frequency / baud rate); simulations use 10

## Status
TX, RX and loopback test verified in simulation. Not yet tested on hardware.

## Possible extensions
- Framing-error flag in the RX
- Testing at different baud rates
- SystemVerilog testbench

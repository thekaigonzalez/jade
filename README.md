# JADE - Just Another Decompiler Engine

A decompiler, and bytecode interpreter, which supports 32-bit and 8-bit
bytecode.

## Installation

You can install JADE from the releases page on this github page.

## Usage

```bash
jade -h
```

## RASterized Mode

Use `-r` to enable RASterized mode, which is an optimization extension to remove
data casts to registers and store them in the CPU's stack instead. On
extremely time-critical code this could potentially speed up the code.

## License

MIT

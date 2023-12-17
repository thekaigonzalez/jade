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

## Speed Tests

### OpenLUD

OpenLUD's simple 'A' program (hello.asm)

```
A
________________________________________________________
Executed in    7.56 millis    fish           external
   usr time    3.90 millis  376.00 micros    3.52 millis
   sys time    3.76 millis  233.00 micros    3.52 millis
```

JADE (without RASterized mode):

```
A
________________________________________________________
Executed in    2.11 millis    fish           external
   usr time    1.98 millis  331.00 micros    1.65 millis
   sys time    0.21 millis  207.00 micros    0.00 millis
```

JADE (with RASterized mode):

```
A
________________________________________________________
Executed in    2.01 millis    fish           external
   usr time    0.31 millis  309.00 micros    0.00 millis
   sys time    1.79 millis  191.00 micros    1.59 millis
```

## License

MIT

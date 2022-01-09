# Dervish FV-1 Bank Assembler and Annotator
Helper scripts for building and uploading bank files for gbiz Dervish (FV-1 based eurorack module).

## Basics
Building nicely labelled banks requires a bunch of boilerplate, so it seems to make sense to keep that in a central place for multiple banks and across projects.
It can be added to the bank/project folder as a submodule or subproject or whatever your preferred method is.

### Requirements
- `make` and a shell
- [asfv1](https://github.com/ndf-zz/asfv1)
- Uploading requires `fv1-eeprom-host` in the path and a valid `DERVISH_TTY` environment variable (I tend to just set these using `direnv` in the project folder, rather than globally).

### Creating Banks
- `newbank` creates a new bank folder with empty program files for slots 0-7.
Example:

```
> mkdir muhfx
> cd muhfx
> git clone https://github.com/patrickdowling/derbanka.git

> ./derbanka/newbank testbank "Testing 1-2-3" # bank name is optional, defaults to directory name
> ls testbank
0_source.asm 1_source.asm 2_source.asm 3_source.asm 4_source.asm 5_source.asm 6_source.asm 7_source.asm Makefile
> make -C testbank
...
Building build/Testing_1-2-3.bank...
```
The resulting file can then be found in `muhfx/testbank/build/Testing_1-2-3.bank`

Now you can edit or rename the program files; the only really important thing is to maintain the `[0-7]_*` filename pattern.

### Labelling
The program name and pot labels are generated from special comments in the `.asm` files and follows what seems to be a common pattern. The files are initially populated with an empty header:
```
; Program:
; POT0: --
; POT1: --
; POT2: --
```
- The maximum length is 20 characters, anything else will be truncated.
- Program name defaults to file name.
- The program number isn't automatically included; this may be a future improvement.

### Upload
`make -C <directory> upload`

You can specifiy the bank number/slot to upload to either in the generated makefile or the command line using `BANK_SLOT=n`. The default is 0. 

In the makefile it may be preferable to use
```
BANK_SLOT ?= 1
```
since then it can still be specified externally.


## Advanced
### "Macro Assembler"
While banks of test programs for another project I found myself repeating chunks of code. So before `.asm` files are sent to the assembler, they are pre-processed and can include other files.
The syntax is simple:
```
.include "filename"
```

So in tests programs for LFO tests there are things like
```
.include "pot0_rate.asm"
```
which reads the pot and set the rate, or you can set up a file with common definitions like
```
EQU RATE_POT POT0
EQU MAX 0x7fffff
```
etc. pp.

- The contents of the file is inserted verbatim so there's no recursive includes or other fancy stuff.
- If the included file includes a `; POT0:` or other label, it overrides the default in the header.
- Doesn't do any path searching, so filenames should be absolute or relative to the `.asm` file.
- Caveat: `make` doesn't know about the dependencies.

### Other
- Takes some cues from [ndf-zz/fv1build](https://github.com/ndf-zz/fv1build). Thanks!
- Yes, my project naming skillz are awesome ;)


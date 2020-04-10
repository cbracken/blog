+++
title = "Hand-decoding an ELF binary image"
date = "2018-10-31T00:00:00Z"
slug = "decoding-an-elf-binary"
tags = ["Software"]
+++

While recovering from some dentistry the other day I figured I'd have a go at
better understanding the ELF binary format. What better way to do that than to
compile a small program and hand-decode the resulting binary with a hex editor
and whatever ELF format spec I could find.

## Overview

Below, we'll use `nasm` to build a small assembly Hello World program to a
64-bit ELF object file, then link that into an ELF executable with GNU `ld`.
Finally, we'll run the resulting object file and binary image through `xxd` and
hand-decode the resulting hex.

The code and instructions below work on FreeBSD 11 on x86_64 hardware. For
other operating systems, hardware, and toolchains, you're on your own! I'd
imagine this should all work just fine on Linux. If I get bored one day, I may
redo this for Mach-O binaries on macOS.

## hello.asm

First we'll bang up a minimal Hello World program in assembly. In the `.data`
section, we add a null-terminated string, `hello`, and its length `hbytes`. In
the program text, we set up and execute the `write(stdout, hello, hbytes)`
syscall, then set up and execute an `exit(0)` syscall.

Note that 64-bit FreeBSD, macOS, and Linux all use the SysV AMD64 calling
convention. For calls against the kernel interface, the syscall number is
stored in `rax` and up to six parameters are passed, in order, in `rdi`, `rsi`,
`rdx`, `r10`, `r8`, `r9`. For user calls, replace `r10` with `rcx` in this
list, and pass further arguments on the stack. In all cases, the return value
is passed through `rax`.  More details can be found in section A.2.1 of the
[System V AMD64 ABI Reference][amd64_abi].

    ; hello.asm
    
    %define stdin   0
    %define stdout  1
    %define stderr  2
    
    %define SYS_exit      1
    %define SYS_write     4
    
    %macro  system    1
            mov       rax, %1
            syscall
    %endmacro
    
    %macro  sys.exit  0
            system    SYS_exit
    %endmacro
    
    %macro  sys.write 0
            system    SYS_write
    %endmacro
    
    section  .data
        hello   db     'Hello, World!', 0Ah
        hbytes  equ    $-hello
    
    section .text
    global  _start
    _start:
        mov     rdi, stdout
        mov     rsi, hello
        mov     rdx, hbytes
        sys.write
    
        xor     rdi,rdi
        sys.exit

## Compile to object code

Next, we'll compile `hello.asm` to a 64-bit ELF object file using `nasm`:

    % nasm -f elf64 hello.asm

This emits `hello.o`, an 880-byte ELF-64 object file. Since we haven't yet run
this through the linker, addresses of global symbols (in this case, `hello`)
are not yet known and thus left with address 0x0 placeholders. We can see this
in the `movabs` instruction at offset 0x15 of the `.text` section below.

The relocation section (Section 6: `.rela.text`) contains an entry for each
symbolic reference that needs to be filled in by the linker. In this case
there's just a single entry for the symbol `hello` (which points to our hello
world string). The relocation table entry's `r_offset` indicates the address to
replace is at an offset of 0x7 into the section of the associated symbol table
entry. Its `r_info` (0x0000000200000001) encodes a relocation type in its lower
4 bytes (0x1: `R_AMD64_64`) and the associated symbol table entry in its upper
4 bytes (0x2, which, if we look it up in the symbol table is the `.text`
section).  The `r_addend` field (0x0) specifies an additional adjustment to the
substituted symbol to be applied at link time; specifically, for the
`R_AMD64_64`, the final address is computed as S + A, where S is the
substituted symbol value (in our case, the address of `hello`) and A is the
addend (in our case, 0x0).

Without further ado, let's dump the object file:

    % xxd hello.o

With whatever ELF64 [linker & loader guide][guide_linker] we can find at hand,
let's get decoding this thing:

                                                                         ELF Header
    00000000: 7f45 4c46 0201 0100 0000 0000 0000 0000  .ELF............  e_ident[EI_MAG0..EI_MAG3]  0x7f + ELF          Magic
    00000010: 0100 3e00 0100 0000 0000 0000 0000 0000  ..>.............  e_ident[EI_CLASS]          0x02                64-bit
    00000020: 0000 0000 0000 0000 4000 0000 0000 0000  ........@.......  e_ident[EI_DATA]           0x01                Little-endian
    00000030: 0000 0000 4000 0000 0000 4000 0700 0300  ....@.....@.....  e_ident[EI_VERSION]        0x01                ELF v1
                                                                         e_ident[EI_OSABI]          0x00                System V
                                                                         e_ident[EI_ABIVERSION]     0x00                Unused
                                                                         e_ident[EI_PAD]            0x00000000000000    7 bytes unused padding
                                                                         e_type                     0x0001              ET_REL
                                                                         e_machine                  0x003e              x86_64
                                                                         e_version                  0x00000001          Version 1
                                                                         e_entry                    0x0000000000000000  Entrypoint address (none)
                                                                         e_phoff                    0x0000000000000000  Program header table offset in image (none)
                                                                         e_shoff                    0x0000000000000040  Section header table offset in image
                                                                         e_flags                    0x00000000
                                                                         e_ehsize                   0x0040
                                                                         e_phentsize                0x0000
                                                                         e_phnum                    0x0000
                                                                         e_shentsize                0x0040
                                                                         e_shnum                    0x0007
                                                                         e_shstrndx                 0x0003
    
                                                                         Section header table: Entry 0 (null)
    00000040: 0000 0000 0000 0000 0000 0000 0000 0000  ................  sh_name                    0x00000000          Offset into .shstrtab
    00000050: 0000 0000 0000 0000 0000 0000 0000 0000  ................  sh_type                    0x00000000          SHT_NULL
    00000060: 0000 0000 0000 0000 0000 0000 0000 0000  ................  sh_flags                   0x0000000000000000  Section attributes
    00000070: 0000 0000 0000 0000 0000 0000 0000 0000  ................  sh_addr                    0x0000000000000000  Virtual address of section in memory
                                                                         sh_offset                  0x0000000000000000  Offset of section in file image
                                                                         sh_size                    0x0000000000000000  Size in bytes of section in file image
                                                                         sh_link                    0x00000000          Section index of associated section
                                                                         sh_info                    0x00000000          Extra info about section
                                                                         sh_addralign               0x0000000000000000  Alignment
                                                                         sh_entsize                 0x0000000000000000  Size in bytes of each entry
    
                                                                         Section header table: Entry 1 (.data)
    00000080: 0100 0000 0100 0000 0300 0000 0000 0000  ................  sh_name                    0x00000001          Offset into .shstrtab
    00000090: 0000 0000 0000 0000 0002 0000 0000 0000  ................  sh_type                    0x00000001          SHT_PROGBITS
    000000a0: 0e00 0000 0000 0000 0000 0000 0000 0000  ................  sh_flags                   0x0000000000000003  SHF_WRITE | SHF_ALLOC
    000000b0: 0400 0000 0000 0000 0000 0000 0000 0000  ................  sh_addr                    0x0000000000000000  Virtual address of section in memory
                                                                         sh_offset                  0x0000000000000200  Offset of section in file image
                                                                         sh_size                    0x000000000000000e  Size in bytes of section in file image
                                                                         sh_link                    0x00000000          Section index of associated section
                                                                         sh_info                    0x00000000          Extra info about section
                                                                         sh_addralign               0x0000000000000004  Alignment
                                                                         sh_entsize                 0x0000000000000000  Size in bytes of each entry
    
                                                                         Section header table: Entry 2 (.text)
    000000c0: 0700 0000 0100 0000 0600 0000 0000 0000  ................  sh_name                    0x00000007          Offset into .shstrtab
    000000d0: 0000 0000 0000 0000 1002 0000 0000 0000  ................  sh_type                    0x00000001          SHT_PROGBITS
    000000e0: 2500 0000 0000 0000 0000 0000 0000 0000  %...............  sh_flags                   0x0000000000000006  SHF_ALLOC | SHF_EXECINSTR
    000000f0: 1000 0000 0000 0000 0000 0000 0000 0000  ................  sh_addr                    0x0000000000000000  Virtual address of section in memory
                                                                         sh_offset                  0x0000000000000210  Offset of section in file image
                                                                         sh_size                    0x0000000000000025  Size in bytes of section in file image
                                                                         sh_link                    0x00000000          Section index of associated section
                                                                         sh_info                    0x00000000          Extra info about section
                                                                         sh_addralign               0x0000000000000001  Alignment
                                                                         sh_entsize                 0x0000000000000000  Size in bytes of each entry
    
                                                                         Section header table: Entry 3 (.shstrtab)
    00000100: 0d00 0000 0300 0000 0000 0000 0000 0000  ................  sh_name                    0x0000000d          Offset into .shstrtab
    00000110: 0000 0000 0000 0000 4002 0000 0000 0000  ........@.......  sh_type                    0x00000003          SHT_STRTAB
    00000120: 3200 0000 0000 0000 0000 0000 0000 0000  2...............  sh_flags                   0x0000000000000000  Section attributes
    00000130: 0100 0000 0000 0000 0000 0000 0000 0000  ................  sh_addr                    0x0000000000000000  Virtual address of section in memory
                                                                         sh_offset                  0x0000000000000240  Offset of section in file image
                                                                         sh_size                    0x0000000000000032  Size in bytes of section in file image
                                                                         sh_link                    0x00000000          Section index of associated section
                                                                         sh_info                    0x00000000          Extra info about section
                                                                         sh_addralign               0x0000000000000001  Alignment
                                                                         sh_entsize                 0x0000000000000000  Size in bytes of each entry
    
                                                                         Section header table: Entry 4 (.symtab)
    00000140: 1700 0000 0200 0000 0000 0000 0000 0000  ................  sh_name                    0x00000017          Offset into .shstrtab
    00000150: 0000 0000 0000 0000 8002 0000 0000 0000  ................  sh_type                    0x00000002          SHT_SYMTAB
    00000160: a800 0000 0000 0000 0500 0000 0600 0000  ................  sh_flags                   0x0000000000000000  Section attributes
    00000170: 0800 0000 0000 0000 1800 0000 0000 0000  ................  sh_addr                    0x0000000000000000  Virtual address of section in memory
                                                                         sh_offset                  0x0000000000000280  Offset of section in file image
                                                                         sh_size                    0x00000000000000a8  Size in bytes of section in file image
                                                                         sh_link                    0x00000005          Section index of associated section
                                                                         sh_info                    0x00000006          Extra info about section
                                                                         sh_addralign               0x0000000000000008  Alignment
                                                                         sh_entsize                 0x0000000000000018  Size in bytes of each entry
    
                                                                         Section header table: Entry 5 (.strtab)
    00000180: 1f00 0000 0300 0000 0000 0000 0000 0000  ................  sh_name                    0x0000001f          Offset into .shstrtab
    00000190: 0000 0000 0000 0000 3003 0000 0000 0000  ........0.......  sh_type                    0x00000003          SHT_STRTAB
    000001a0: 1f00 0000 0000 0000 0000 0000 0000 0000  ................  sh_flags                   0x0000000000000000  Section attributes
    000001b0: 0100 0000 0000 0000 0000 0000 0000 0000  ................  sh_addr                    0x0000000000000000  Virtual address of section in memory
                                                                         sh_offset                  0x0000000000000330  Offset of section in file image
                                                                         sh_size                    0x000000000000001f  Size in bytes of section in file image
                                                                         sh_link                    0x00000000          Section index of associated section
                                                                         sh_info                    0x00000000          Extra info about section
                                                                         sh_addralign               0x0000000000000001  Alignment
                                                                         sh_entsize                 0x0000000000000000  Size in bytes of each entry
    
                                                                         Section header table: Entry 6 (.rela.text)
    000001c0: 2700 0000 0400 0000 0000 0000 0000 0000  '...............  sh_name                    0x00000027          Offset into .shstrtab
    000001d0: 0000 0000 0000 0000 5003 0000 0000 0000  ........P.......  sh_type                    0x00000004          SHT_RELA
    000001e0: 1800 0000 0000 0000 0400 0000 0200 0000  ................  sh_flags                   0x0000000000000000  Section attributes
    000001f0: 0800 0000 0000 0000 1800 0000 0000 0000  ................  sh_addr                    0x0000000000000000  Virtual address of section in memory
                                                                         sh_offset                  0x0000000000000350  Offset of section in file image
                                                                         sh_size                    0x0000000000000018  Size in bytes of section in file image
                                                                         sh_link                    0x00000004          Section index of associated section
                                                                         sh_info                    0x00000002          Extra info about section
                                                                         sh_addralign               0x0000000000000008  Alignment
                                                                         sh_entsize                 0x0000000000000018  Size in bytes of each entry
    
                                                                         Section 1: .data (SHT_PROGBITS; SHF_WRITE | SHF_ALLOC)
    00000200: 4865 6c6c 6f2c 2057 6f72 6c64 210a       Hello, World!.    0x000000  'Hello, World!\n'
    
    0000020e:                                    0000                ..  Unused zero-padding
    
                                                                         Section 2: .text (SHT_PROGBITS; SHF_ALLOC | SHF_EXECINSTR)
    00000210: bf01 0000 0048 be00 0000 0000 0000 00ba  .....H..........  0x000010  mov       edi, 0x1
    00000220: 0e00 0000 b804 0000 000f 0548 31ff b801  ...........H1...  0x000015  movabs    rsi, 0x000000 (placeholder for db hello)
    00000230: 0000 000f 05                             .....             0x00001f  mov       edx, 0xe
                                                                         0x000024  mov       eax, 0x4
                                                                         0x400029  syscall
                                                                         0x40002b  xor       rdi, rdi
                                                                         0x40002e  mov       eax, 0x1
                                                                         0x400033  syscall
    
    00000235:             00 0000 0000 0000 0000 0000       ...........  Unused zero-padding
    
                                                                         Section 3: .shstrtab (SHT_STRTAB;)
    00000240: 002e 6461 7461 002e 7465 7874 002e 7368  ..data..text..sh  0x00: ''
    00000250: 7374 7274 6162 002e 7379 6d74 6162 002e  strtab..symtab..  0x01: '.data'
    00000260: 7374 7274 6162 002e 7265 6c61 2e74 6578  strtab..rela.tex  0x07: '.text'
    00000270: 7400                                     t.                0x0d: '.shstrtab'
                                                                         0x17: '.symtab'
                                                                         0x1f: '.strtab'
                                                                         0x27: '.rela.text'
    
    00000272:      0000 0000 0000 0000 0000 0000 0000    ..............  Unused zero-padding
    
                                                                         Section 4: .symtab' (SHT_SYMTAB;)
                                                                         Symbol table entry 0
    00000280: 0000 0000 0000 0000 0000 0000 0000 0000  ................  st_name                    0x00000000
    00000290: 0000 0000 0000 0000                      ........          st_info                    0x00
                                                                         st_other                   0x00
                                                                         st_shndx                   0x0000 (SHN_UNDEF)
                                                                         st_value                   0x0000000000000000
                                                                         st_size                    0x0000000000000000
    
                                                                         Symbol table entry 1 (hello.asm)
    00000298:                     0100 0000 0400 f1ff          ........  st_name                    0x00000001
    000002a0: 0000 0000 0000 0000 0000 0000 0000 0000  ................  st_info                    0x04 (STT_FILE)
                                                                         st_other                   0x00
                                                                         st_shndx                   0xfff1 (SHN_ABS)
                                                                         st_value                   0x0000000000000000
                                                                         st_size                    0x0000000000000000
    
                                                                         Symbol table entry 2
    000002b0: 0000 0000 0300 0100 0000 0000 0000 0000  ................  st_name                    0x00000000
    000002c0: 0000 0000 0000 0000                      ........          st_info                    0x03 (STT_OBJECT | STT_FUNC)
                                                                         st_other                   0x00
                                                                         st_shndx                   0x0001 (Section 1: .data)
                                                                         st_value                   0x0000000000000000
                                                                         st_size                    0x0000000000000000
    
                                                                         Symbol table entry 3
    000002c8:                     0000 0000 0300 0200          ........  st_name                    0x00000000
    000002d0: 0000 0000 0000 0000 0000 0000 0000 0000  ................  st_info                    0x03 (STT_OBJECT | STT_FUNC)
                                                                         st_other                   0x00
                                                                         st_shndx                   0x0002 (Section 2: .text)
                                                                         st_value                   0x0000000000000000
                                                                         st_size                    0x0000000000000000
    
                                                                         Symbol table entry 4 (hello)
    000002e0: 0b00 0000 0000 0100 0000 0000 0000 0000  ................  st_name                    0x0000000b
    000002f0: 0000 0000 0000 0000                      ........          st_info                    0x00
                                                                         st_other                   0x00
                                                                         st_shndx                   0x0001 (Section 1: .data)
                                                                         st_value                   0x0000000000000000
                                                                         st_size                    0x0000000000000000
    
                                                                         Symbol table entry 5 (hbytes)
    000002f8:                     1100 0000 0000 f1ff          ........  st_name                    0x00000011
    00000300: 0e00 0000 0000 0000 0000 0000 0000 0000  ................  st_info                    0x00
                                                                         st_other                   0x00
                                                                         st_shndx                   0xfff1 (SHN_ABS)
                                                                         st_value                   0x000000000000000e
                                                                         st_size                    0x0000000000000000
    
                                                                         Symbol table entry 6 (_start)
    00000310: 1800 0000 1000 0200 0000 0000 0000 0000  ................  st_name                    0x00000018
    00000320: 0000 0000 0000 0000                      ........          st_info                    0x01 (STT_OBJECT)
                                                                         st_other                   0x00
                                                                         st_shndx                   0x0002 (Section 2: .text)
                                                                         st_value                   0x0000000000000000
                                                                         st_size                    0x0000000000000000
    
    00000328:                     0000 0000 0000 0000          ........  Unused zero-padding
    
                                                                         Section 5: .strtab (SHT_STRTAB;)
    00000330: 0068 656c 6c6f 2e61 736d 0068 656c 6c6f  .hello.asm.hello  0x00: ''
    00000340: 0068 6279 7465 7300 5f73 7461 7274 00    .hbytes._start.   0x01: 'hello.asm'
                                                                         0x0b: 'hello'
                                                                         0x11: 'hbytes'
                                                                         ox18: '_start'
    
    0000034f:                                      00                 .  Unused zero-padding
    
                                                                         Section 6: .rela.text (SHT_RELA;)
    00000350: 0700 0000 0000 0000 0100 0000 0200 0000  ................  r_offset                   0x0000000000000007
    00000360: 0000 0000 0000 0000                      ........          r_info                     0x0000000200000001 (Symbol table entry 2, type R_AMD64_64)
                                                                         r_addend                   0x0000000000000000
    
    00000368:                     0000 0000 0000 0000          ........  Unused zero-padding

## Link to executable image

Next, let's link `hello.o` into a 64-bit ELF executable:

    % ld -o hello hello.o

This emits `hello`, a 951-byte ELF-64 executable image.

Since the linker has decided which segment each section maps into (if any) and
what the segment addresses are, addresses are now known for all (statically
linked) symbols, and address 0x0 placeholders have been replaced with actual
addresses. We can see this in the `mov` instruction at address 0x4000b5, which
now specifies an address of 0x6000d8.

Running the linked executable image through `xxd` as above and picking our
trusty linker & loader guide back up, here we go again:

                                                                         ELF Header
    00000000: 7f45 4c46 0201 0109 0000 0000 0000 0000  .ELF............  e_ident[EI_MAG0..EI_MAG3]  0x7f + ELF          Magic
    00000010: 0200 3e00 0100 0000 b000 4000 0000 0000  ..>.......@.....  e_ident[EI_CLASS]          0x02                64-bit
    00000020: 4000 0000 0000 0000 1001 0000 0000 0000  @...............  e_ident[EI_DATA]           0x01                Little-endian
    00000030: 0000 0000 4000 3800 0200 4000 0600 0300  ....@.8...@.....  e_ident[EI_VERSION]        0x01                ELF v1
                                                                         e_ident[EI_OSABI]          0x09                FreeBSD
                                                                         e_ident[EI_ABIVERSION]     0x00                Unused
                                                                         e_ident[EI_PAD]            0x0000000000        7 bytes unused padding
                                                                         e_type                     0x0002              ET_EXEC
                                                                         e_machine                  0x003e              x86_64
                                                                         e_version                  0x00000001          Version 1
                                                                         e_entry                    0x00000000004000b0  Entrypoint addr
                                                                         e_phoff                    0x0000000000000040  Program header table offset in image
                                                                         e_shoff                    0x0000000000000110  Section header table offset in image
                                                                         e_flags                    0x00000000          Architecture-dependent interpretation
                                                                         e_ehsize                   0x0040              Size of this ELF header
                                                                         e_phentsize                0x0038              Size of program header table entry
                                                                         e_phnum                    0x0002              Number of program header table entries
                                                                         e_shentsize                0x0040              Size of section header table entry
                                                                         e_shnum                    0x0006              Number of section header table entries
                                                                         e_shstrndx                 0x0003              Index of section header with section names
    
                                                                         Program header table: Entry 0 (PF_X | PF_R)
    00000040: 0100 0000 0500 0000 0000 0000 0000 0000  ................  p_type                     0x00000001          PT_LOAD
    00000050: 0000 4000 0000 0000 0000 4000 0000 0000  ..@.......@.....  p_flags                    0x00000005          PF_X | PF_R
    00000060: d500 0000 0000 0000 d500 0000 0000 0000  ................  p_offset                   0x00000000          Offset of segment in file image
    00000070: 0000 2000 0000 0000                      .. .............  p_vaddr                    0x0000000000400000  Virtual address of segment in memory
                                                                         p_paddr                    0x0000000000400000  Physical address of segment
                                                                         p_filesz                   0x00000000000000d5  Size in bytes of segment in file image
                                                                         p_memsz                    0x00000000000000d5  Size in bytes of segment in memory
                                                                         p_align                    0x0000000000200000  Alignment (2MB)
    
                                                                         Program header table: Entry 1 (PF_W | PF_R)
    00000078:                     0100 0000 0600 0000          ........  p_type                     0x00000001          PT_LOAD
    00000080: d800 0000 0000 0000 d800 6000 0000 0000  ..........`.....  p_flags                    0x00000006          PF_W | PF_R
    00000090: d800 6000 0000 0000 0e00 0000 0000 0000  ..`.............  p_offset                   0x00000000000000d8  Offset of segment in file image
    000000a0: 0e00 0000 0000 0000 0000 2000 0000 0000  .......... .....  p_vaddr                    0x00000000006000d8  Virtual address of segment in memory
                                                                         p_paddr                    0x00000000006000d8  Physical address of segment
                                                                         p_filesz                   0x000000000000000e  Size in bytes of segment in file image
                                                                         p_memsz                    0x000000000000000e  Size in bytes of segment in memory
                                                                         p_align                    0x0000000000200000  Alignment (2MB)
    
                                                                         Section 1: .text (SHT_PROGBITS; SHF_ALLOC | SHF_EXECINSTR)
    000000b0: bf01 0000 0048 bed8 0060 0000 0000 00ba  .....H...`......  0x4000b0  mov       edi, 0x1
    000000c0: 0e00 0000 b804 0000 000f 0548 31ff b801  ...........H1...  0x4000b5  movabs    rsi, 0x6000d8
    000000d0: 0000 000f 05                             .....             0x4000bf  mov       edx, 0xe
                                                                         0x4000c4  mov       eax, 0x4
                                                                         0x4000c9  syscall
                                                                         0x4000cb  xor       rdi, rdi
                                                                         0x4000ce  mov       eax, 0x1
                                                                         0x4000d3  syscall
    
    000000d5:             00 0000                                        Unused zero-padding
    
                                                                         Section 2: .data (SHT_PROGBITS; SHF_WRITE | SHF_ALLOC)
    000000d8:                     4865 6c6c 6f2c 2057          Hello, W  0x6000d8  'Hello, World!\n'
    000000e0: 6f72 6c64 210a                           orld!.
    
                                                                         Section 3: .shstrtab (SHT_STRTAB;)
    000000e6:                002e 7379 6d74 6162 002e        ..symtab..  0x00: ''
    000000f0: 7374 7274 6162 002e 7368 7374 7274 6162  strtab..shstrtab  0x01: '.symtab'
    00000100: 002e 7465 7874 002e 6461 7461 00         ..text..data.     0x09: '.strtab'
                                                                         0x11: '.shstrtab'
                                                                         0x1b: '.text'
                                                                         0x21: '.data'
    
    0000010d:                                 00 0000               ...  Unused zero-padding
    
                                                                         Section header table: Entry 0 (null)
    00000110: 0000 0000 0000 0000 0000 0000 0000 0000  ................  sh_name                    0x00000000          Offset into .shstrtab
    00000120: 0000 0000 0000 0000 0000 0000 0000 0000  ................  sh_type                    0x00000000          SHT_NULL
    00000130: 0000 0000 0000 0000 0000 0000 0000 0000  ................  sh_flags                   0x0000000000000000  Section attributes
    00000140: 0000 0000 0000 0000 0000 0000 0000 0000  ................  sh_addr                    0x0000000000000000  Virtual address of section in memory
                                                                         sh_offset                  0x0000000000000000  Offset of section in file image
                                                                         sh_size                    0x0000000000000000  Size in bytes of section in file image
                                                                         sh_link                    0x00000000          Section index of associated section
                                                                         sh_info                    0x00000000          Extra info about section
                                                                         sh_addralign               0x0000000000000000  Alignment
                                                                         sh_entsize                 0x0000000000000000  Size in bytes of each entry
    
                                                                         Section header table: Entry 1 (.text)
    00000150: 1b00 0000 0100 0000 0600 0000 0000 0000  ................  sh_name                    0x0000001b          Offset into .shstrtab
    00000160: b000 4000 0000 0000 b000 0000 0000 0000  ..@.............  sh_type                    0x00000001          SHT_PROGBITS
    00000170: 2500 0000 0000 0000 0000 0000 0000 0000  %...............  sh_flags                   0x00000006          SHF_ALLOC | SHF_EXECINSTR
    00000180: 1000 0000 0000 0000 0000 0000 0000 0000  ................  sh_addr                    0x00000000004000b0  Virtual address of section in memory
                                                                         sh_offset                  0x00000000000000b0  Offset of section in file image
                                                                         sh_size                    0x0000000000000025  Size in bytes of section in file image
                                                                         sh_link                    0x00000000          Section index of associated section
                                                                         sh_info                    0x00000000          Extra info about section
                                                                         sh_addralign               0x0000000000000010  Alignment (2B)
                                                                         sh_entsize                 0x0000000000000000  Size in bytes of each entry
    
                                                                         Section header table: Entry 2 (.data)
    00000190: 2100 0000 0100 0000 0300 0000 0000 0000  !...............  sh_name                    0x00000021          Offset into .shstrtab
    000001a0: d800 6000 0000 0000 d800 0000 0000 0000  ..`.............  sh_type                    0x00000001          SHT_PROGBITS
    000001b0: 0e00 0000 0000 0000 0000 0000 0000 0000  ................  sh_flags                   0x0000000000000003  SHF_WRITE | SHF_ALLOC
    000001c0: 0400 0000 0000 0000 0000 0000 0000 0000  ................  sh_addr                    0x00000000006000d8  Virtual address of section in memory
                                                                         sh_offset                  0x00000000000000d8  Offset of section in file image
                                                                         sh_size                    0x000000000000000e  Size in bytes of section in file image
                                                                         sh_link                    0x00000000          Section index of associated section
                                                                         sh_info                    0x00000000          Extra info about section
                                                                         sh_addralign               0x0000000000000004  Alignment (4B)
                                                                         sh_entsize                 0x0000000000000000  Size in bytes of each entry
    
                                                                         Section header table: Entry 3 (.shstrtab)
    000001d0: 1100 0000 0300 0000 0000 0000 0000 0000  ................  sh_name                    0x00000011          Offset into .shstrtab
    000001e0: 0000 0000 0000 0000 e600 0000 0000 0000  ................  sh_type                    0x00000003          SHT_STRTAB
    000001f0: 2700 0000 0000 0000 0000 0000 0000 0000  '...............  sh_flags                   0x00000000          No flags
    00000200: 0100 0000 0000 0000 0000 0000 0000 0000  ................  sh_addr                    0x0000000000000000  Virtual address of section in memory
                                                                         sh_offset                  0x00000000000000e6  Offset of section in file image
                                                                         sh_size                    0x0000000000000027  Size in bytes of section in file image
                                                                         sh_link                    0x00000000          Section index of associated section
                                                                         sh_info                    0x00000000          Extra info about section
                                                                         sh_addralign               0x0000000000000001  Alignment (1B)
                                                                         sh_entsize                 0x0000000000000000  Size in bytes of each entry
    
                                                                         Section header table: Entry 4 (.symtab)
    00000210: 0100 0000 0200 0000 0000 0000 0000 0000  ................  sh_name                    0x00000001          Offset into .shstrtab
    00000220: 0000 0000 0000 0000 9002 0000 0000 0000  ................  sh_type                    0x00000002          SHT_SYMTAB
    00000230: f000 0000 0000 0000 0500 0000 0600 0000  ................  sh_flags                   0x00000000          No flags
    00000240: 0800 0000 0000 0000 1800 0000 0000 0000  ................  sh_addr                    0x0000000000000000  Virtual address of section in memory
                                                                         sh_offset                  0x0000000000000290  Offset of section in file image
                                                                         sh_size                    0x00000000000000f0  Size in bytes of section in file image
                                                                         sh_link                    0x00000005          Section index of associated section
                                                                         sh_info                    0x00000006          Flags
                                                                         sh_addralign               0x0000000000000008  Alignment (8B)
                                                                         sh_entsize                 0x0000000000000018  Size in bytes of each entry (24B)
    
                                                                         Section header table: Entry 5 (.strtab)
    00000250: 0900 0000 0300 0000 0000 0000 0000 0000  ................  sh_name                    0x00000009          Offset into .shstrtab
    00000260: 0000 0000 0000 0000 8003 0000 0000 0000  ................  sh_type                    0x00000003          SHT_STRTAB
    00000270: 3700 0000 0000 0000 0000 0000 0000 0000  7...............  sh_flags                   0x0000000000000000  No flags
    00000280: 0100 0000 0000 0000 0000 0000 0000 0000  ................  sh_addr                    0x0000000000000000  Virtual address of section in memory
                                                                         sh_offset                  0x0000000000000380  Offset of section in file image
                                                                         sh_size                    0x0000000000000037  Size in bytes of section in file image
                                                                         sh_link                    0x00000000          Section index of associated section
                                                                         sh_info                    0x00000000          Extrac info about section
                                                                         sh_addralign               0x0000000000000001  Alignment (1B)
                                                                         sh_entsize                 0x0000000000000000  Size in bytes of each entry
    
                                                                         Section 4: .symtab (SHT_SYMTAB;)
                                                                         Symbol table entry 0
    00000290: 0000 0000 0000 0000 0000 0000 0000 0000  ................  st_name                    0x00000000
    000002a0: 0000 0000 0000 0000                      ........          st_info                    0x00
                                                                         st_other                   0x00
                                                                         st_shndx                   0x0000 (SHN_UNDEF)
                                                                         st_value                   0x0000000000000000
                                                                         st_size                    0x0000000000000000
    
                                                                         Symbol table entry 1
    000002a8:                     0000 0000 0300 0100          ........  st_name                    0x00000000
    000002b0: b000 4000 0000 0000 0000 0000 0000 0000  ..@.............  st_info                    0x03 (STT_OBJECT | STT_FUNC)
                                                                         st_other                   0x00
                                                                         st_shndx                   0x0001 (Section 1: .text)
                                                                         st_value                   0x00000000004000b0
                                                                         st_size                    0x0000000000000000
    
                                                                         Symbol table entry 2
    000002c0: 0000 0000 0300 0200 d800 6000 0000 0000  ..........`.....  st_name                    0x00000000
    000002d0: 0000 0000 0000 0000                      ........          st_info                    0x03 (STT_OBJECT | STT_FUNC)
                                                                         st_other                   0x00
                                                                         st_shndx                   0x0002 (Section 2: .data)
                                                                         st_value                   0x00000000006000d8
                                                                         st_size                    0x0000000000000000
    
                                                                         Symbol table entry 3 (hello.asm)
    000002d0:                     0100 0000 0400 f1ff          ........  st_name                    0x00000001
    000002e0: 0000 0000 0000 0000 0000 0000 0000 0000  ................  st_info                    0x04 (STT_FILE)
                                                                         st_other                   0x00
                                                                         st_shndx                   0xfff1 (SHN_ABS)
                                                                         st_value                   0x0000000000000000
                                                                         st_size                    0x0000000000000000
    
    
                                                                         Symbol table entry 4 (hello)
    000002f0: 0b00 0000 0000 0200 d800 6000 0000 0000  ..........`.....  st_name                    0x0000000b
    00000300: 0000 0000 0000 0000                      ................  st_info                    0x00
                                                                         st_other                   0x00
                                                                         st_shndx                   0x0002 (Section 2: .data)
                                                                         st_value                   0x00000000006000d8
                                                                         st_size                    0x0000000000000000
    
                                                                         Symbol table entry 5 (hbytes)
    00000300:                     1100 0000 0000 f1ff          ........  st_name                    0x00000011
    00000310: 0e00 0000 0000 0000 0000 0000 0000 0000  ................  st_info                    0x00
                                                                         st_other                   0x00
                                                                         st_shndx                   0xfff1 (SHN_ABS)
                                                                         st_value                   0x000000000000000e
                                                                         st_size                    0x0000000000000000
    
                                                                         Symbol table entry 6 (_start)
    00000320: 1800 0000 1000 0100 b000 4000 0000 0000  ..........@.....  st_name                    0x00000018
    00000330: 0000 0000 0000 0000                      ........          st_info                    0x10 (STB_GLOBAL)
                                                                         st_other                   0x00
                                                                         st_shndx                   0x0001 (Section 1: .text)
                                                                         st_value                   0x00000000004000b0
                                                                         st_size                    0x0000000000000000
    
                                                                         Symbol table entry 7 (__bss_start)
    00000330:                     1f00 0000 1000 f1ff          ........  st_name                    0x0000001f
    00000340: e600 6000 0000 0000 0000 0000 0000 0000  ..`.............  st_info                    0x10 (STB_GLOBAL)
                                                                         st_other                   0x00
                                                                         st_shndx                   0xfff1 (SHN_ABS)
                                                                         st_value                   0x00000000006000e6
                                                                         st_size                    0x0000000000000000
    
                                                                         Symbol table entry 8 (_edata)
    00000350: 2b00 0000 1000 f1ff e600 6000 0000 0000  +.........`.....  st_name                    0x0000002b
    00000360: 0000 0000 0000 0000                      ........          st_info                    0x10 (STB_GLOBAL)
                                                                         st_other                   0x00
                                                                         st_shndx                   0xfff1 (SHN_ABS)
                                                                         st_value                   0x00000000006000e6
                                                                         st_size                    0x0000000000000000
    
                                                                         Symbol table entry 8 (_end)
    00000360:                     3200 0000 1000 f1ff          2.......  st_name                    0x00000032
    00000370: e800 6000 0000 0000 0000 0000 0000 0000  ..`.............  st_info                    0x10 (STB_GLOBAL)
                                                                         st_other                   0x00
                                                                         st_shndx                   0xfff1 (SHN_ABS)
                                                                         st_value                   0x00000000006000e8
                                                                         st_size                    0x0000000000000000
    
                                                                         Section 6: .strtab (SHT_STRTAB;)
    00000380: 0068 656c 6c6f 2e61 736d 0068 656c 6c6f  .hello.asm.hello  0x00: ''
    00000390: 0068 6279 7465 7300 5f73 7461 7274 005f  .hbytes._start._  0x01: 'hello.asm'
    000003a0: 5f62 7373 5f73 7461 7274 005f 6564 6174  _bss_start._edat  0x0b: 'hello'
    000003b0: 6100 5f65 6e64 00                        a._end.           0x11: 'hbytes'
                                                                         0x18: '_start'
                                                                         0x1f: '__bss_start'
                                                                         0x2b: '_edata'
                                                                         0x32: '_end'

## Effect of stripping

Running `strip` on the binary has the effect of dropping the `.symtab` and
`.strtab` sections along with their section headers and 16 bytes of data (the
section names `.symtab` and `.strtab`) from the `.shstrtab` section, reducing the
total binary size to 512 bytes.

## In-memory process image

FreeBSD uses a memory superpage size of 2MB (page size of 4kB) on x86_64. Since
attributes are set at the page level, read+execute program `.text` and
read+write `.data` are loaded into two separate segments on separate pages, as
laid-out by the linker.

On launch, the kernel maps the binary image into memory as specified in the
program header table:
  * PHT Entry 0: The ELF header, program header table, and Section 1 (`.text`)
    are mapped from offset 0x00 of the binary image (with length 0xd6 bytes)
    into Segment 1 (readable, executable) at address 0x400000.
  * PHT Entry 1: Section 2 (`.data`) at offset 0xd8 of the binary image is
    mapped into Segment 2 (readable, writeable) at address 0x600000 from offset
    0xd8 with length 0x0e bytes.

The program entrypoint is specified to be 0x4000b0, the start of the `.text`
section.

And that's it! Any corrections or comments are always welcome. Shoot me an
email at [chris@bracken.jp][email].

[amd64_abi]: https://software.intel.com/sites/default/files/article/402129/mpx-linux64-abi.pdf
[guide_linker]: https://docs.oracle.com/cd/E19120-01/open.solaris/819-0690/index.html
[email]: mailto:chris@bracken.jp

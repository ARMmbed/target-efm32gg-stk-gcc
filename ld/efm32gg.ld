/* Linker script for Silicon Labs EFM32GG devices */
/*                                                                  */
/* This file is subject to the license terms as defined in ARM's    */
/* CMSIS END USER LICENSE AGREEMENT.pdf, governing the use of       */
/* Example Code.                                                    */
/*                                                                  */
/* Silicon Laboratories, Inc. 2014                                  */
MEMORY
{
  FLASH (rx) : ORIGIN = 0x00000000, LENGTH = 1048576
  RAM (rwx)  : ORIGIN = 0x20000000, LENGTH = 131072
}
/* MBED: mbed needs to be able to dynamically set the interrupt vector table.
 * We make room for the table at the very beginning of RAM, i.e. at
 * 0x20000000. We need (16+39) * sizeof(uint32_t) = 220 bytes for EFM32GG */
__vector_size = 0xE0;

/* Linker script to place sections and symbol values. Should be used together
 * with other linker script that defines memory regions FLASH and RAM.
 * It references following symbols, which must be defined in code:
 *   Reset_Handler : Entry of reset handler
 *
 * It defines following symbols, which code can use without definition:
 *   __exidx_start
 *   __exidx_end
 *   __etext
 *   __data_start__
 *   __preinit_array_start
 *   __preinit_array_end
 *   __init_array_start
 *   __init_array_end
 *   __fini_array_start
 *   __fini_array_end
 *   __data_end__
 *   __bss_start__
 *   __bss_end__
 *   __end__
 *   end
 *   __HeapLimit
 *   __StackLimit
 *   __StackTop
 *   __stack
 */
ENTRY(Reset_Handler)

SECTIONS
{
  .text :
  {
    KEEP(*(.isr_vector))
    *(.text*)

    KEEP(*(.init))
    KEEP(*(.fini))

    /* .ctors */
    *crtbegin.o(.ctors)
    *crtbegin?.o(.ctors)
    *(EXCLUDE_FILE(*crtend?.o *crtend.o) .ctors)
    *(SORT(.ctors.*))
    *(.ctors)

    /* .dtors */
    *crtbegin.o(.dtors)
    *crtbegin?.o(.dtors)
    *(EXCLUDE_FILE(*crtend?.o *crtend.o) .dtors)
    *(SORT(.dtors.*))
    *(.dtors)

    *(.rodata*)

    KEEP(*(.eh_frame*))
  } > FLASH

  .ARM.extab :
  {
    *(.ARM.extab* .gnu.linkonce.armextab.*)
  } > FLASH

  __exidx_start = .;
  .ARM.exidx :
  {
    *(.ARM.exidx* .gnu.linkonce.armexidx.*)
  } > FLASH
  __exidx_end = .;

  __etext = .;

  /* Set stack size. Stack overflow will trigger HardFault.
   */
  .stack (NOLOAD):
  {
      __stack_start__ = .;
      *(.stack*);
      . += 0x1000 - (. - __stack_start__);
      . = ALIGN(4);
      __stack_end__ = .;
  } > RAM

  .data : AT (__etext)
  {
    __data_start__ = .;
    *("dma")
    PROVIDE( __start_vector_table__ = .);
  	. += __vector_size;
  	PROVIDE( __end_vector_table__ = .);
    *(vtable)
    *(.data*)
    . = ALIGN (4);
    *(.ram)

    . = ALIGN(4);
    /* preinit data */
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP(*(.preinit_array))
    PROVIDE_HIDDEN (__preinit_array_end = .);

    . = ALIGN(4);
    /* init data */
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP(*(SORT(.init_array.*)))
    KEEP(*(.init_array))
    PROVIDE_HIDDEN (__init_array_end = .);

    . = ALIGN(4);
    /* finit data */
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP(*(SORT(.fini_array.*)))
    KEEP(*(.fini_array))
    PROVIDE_HIDDEN (__fini_array_end = .);

    . = ALIGN(4);
    /* All data end */
    __data_end__ = .;

  } > RAM

  .bss :
  {
    __bss_start__ = .;
    *(.bss*)
    *(COMMON)
    __bss_end__ = .;
  } > RAM

  .heap :
  {
    __end__ = .;

    __heap_start = .;
    *(.heap*)

  } > RAM

  /* heap limit is all the available memory, */
  __heap_end = ORIGIN(RAM) + LENGTH(RAM);

  PROVIDE(__heap_size = __heap_end - __heap_start);
  PROVIDE(__mbed_sbrk_start = __heap_start);
  PROVIDE(__mbed_krbs_start = __heap_end);

  /* Set stack top to end of RAM, and stack limit move down by
   * size of stack_dummy section */
  __StackTop = __stack_end__;
  __StackLimit = __stack_start__;
  PROVIDE(__stack = __StackTop);

  /* Check if data + heap + stack exceeds RAM limit */
  ASSERT(__end__ <= __heap_end, "region RAM overflowed with stack")
}

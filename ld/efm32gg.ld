/* Linker script for Energy Micro EFM32GG devices */
/*                                                                  */
/* This file is subject to the license terms as defined in ARM's    */
/* CMSIS END USER LICENSE AGREEMENT.pdf, governing the use of       */
/* Example Code.                                                    */
/*                                                                  */
/* Energy Micro AS, 2012                                            */
MEMORY
{
  FLASH (rx) : ORIGIN = 0x00000000, LENGTH = 1048576
  RAM (rwx)  : ORIGIN = 0x20000000, LENGTH = 131072
}

/* Linker script to place sections and symbol values. Should be used together
 * with other linker script that defines memory regions FLASH and RAM.
 * It references following symbols, which must be defined in code:
 *   Reset_Handler : Entry of reset handler
 * 
 * It defines following symbols, which code can use without definition:
 *   __exidx_start
 *   __exidx_end
 *   __etext
 *   __data_initialisers_start__
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
    
    /* NB: no .ctors / .dtors handling here (GNUlib abi), sections are including in
     * init and fini arrys below instead. Clang emits module initialisers
     * (required by objective c runtime) in the .ctors section, where
     * arm-none-eabi-gcc startup code ignores them.
     */

    *(.rodata*)

    KEEP(*(.eh_frame*))
  } > FLASH

  /* there should be nothing in .init and .fini sections */
  .init :
  {
    *(.init)
  } > FLASH
  .fini :
  {
    *(.fini)
  } > FLASH
  ASSERT(SIZEOF(.init) == 0, ".init section not supported, use .init_array")
  ASSERT(SIZEOF(.fini) == 0, ".fini section not supported, use .fini_array")

  /* No exception support or unwinding, so discard unwind tables. */
  /DISCARD/ /*.ARM.extab*/ :
  {
    *(.ARM.extab* .gnu.linkonce.armextab.*)
  } > FLASH

  __exidx_start = .;
  /DISCARD/ /*.ARM.exidx*/ :
  {
    *(.ARM.exidx* .gnu.linkonce.armexidx.*)
  } > FLASH
  __exidx_end = .;


  __etext = .;
  __data_initialisers_start__ = .;

  .data : AT (__data_initialisers_start__)
  {
    __data_start__ = .;
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
    /* init data, including .ctors sections generated  */
    PROVIDE_HIDDEN (__init_array_start = .);
    /* NB: both .objc_load_functions and c++ _GLOBAL__I_a (which calls static
     * constructors) are put into the .ctors section: THE ORDER IS IMPORTANT.
     * objc load functions must be executed first, as the compiler inserts an
     * objective-c autorelease pool push/pop into the _GLOBAL__I_a function,
     * which requires the runtime to have been initialised.
     *
     * Since sections are included in the order they are linked, the objc
     * runtime MUST be before any c++ libraries on the linker command line.
     */
    KEEP(*(SORT(.ctors.*)))
    KEEP(*(.ctors))
    KEEP(*(SORT(.init_array.*)))
    KEEP(*(.init_array))
    PROVIDE_HIDDEN (__init_array_end = .);

    . = ALIGN(4);
    /* finit data */
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP(*(SORT(.dtors.*)))
    KEEP(*(.dtors))
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

    __heap_pools_start = .;
    KEEP(*(.heap_pools))
    __heap_pools_limit = .;

    __heap_start = .;
    KEEP(*(.heap))
    __heap_end = .;
  } > RAM

  /* .stack_dummy section doesn't contains any symbols. It is only
   * used for linker to calculate size of stack sections, and assign
   * values to stack symbols later */
  .stack_dummy :
  {
    *(.stack)
  } > RAM

  /* Set stack top to end of RAM, and stack limit move down by
   * size of stack_dummy section */
  __stack_top = ORIGIN(RAM) + LENGTH(RAM);
  __stack_limit = __stack_top - SIZEOF(.stack_dummy);
  PROVIDE(__stack = __stack_top);

  /* heap limit is all the available memory, */
  __heap_limit = __stack_limit;


  ASSERT(SIZEOF(.stack_dummy) > 0, "no stack size set")
  ASSERT(__heap_pools_limit - __heap_pools_start > 0, "no heap pools size set")

  /* Check if data + heap + stack exceeds RAM limit */
  ASSERT(__stack_limit >= __heap_limit, "region RAM overflowed with stack")
  
  /* Backwards compatibility */
  PROVIDE(__StackLimit = __stack_limit);
  PROVIDE(__HeapLimit = __heap_limit);
  PROVIDE(__HeapPoolsLimit = __heap_pools_limit);
  PROVIDE(end = __end__);
  PROVIDE(_end = __end__);
}


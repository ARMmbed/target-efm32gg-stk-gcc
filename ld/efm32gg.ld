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
  /* ensure that uvisor bss is at the beginning of memory */
  .uvisor.bss (NOLOAD):
  {
    . = ALIGN(32);
    __uvisor_bss_start = .;

    /* protected uvisor main bss */
    . = ALIGN(32);
    __uvisor_bss_main_start = .;
    KEEP(*(.keep.uvisor.bss.main))
    . = ALIGN(32);
    __uvisor_bss_main_end = .;

    /* protected uvisor secure boxes bss */
    . = ALIGN(32);
    __uvisor_bss_boxes_start = .;
    KEEP(*(.keep.uvisor.bss.boxes))
    . = ALIGN(32);
    *("dma")
    __uvisor_bss_boxes_end = .;

    . = ALIGN(32);
    . = 0x4000;
    __uvisor_bss_end = .;
  } > RAM
  
  .text :
  {
    KEEP(*(.isr_vector))
    
    /* uVisor code and data */
    . = 0x100;
    . = ALIGN(4);
    __uvisor_main_start = .;
    *(.uvisor.main)
    __uvisor_main_end = .;
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

  /* .stack section doesn't contains any symbols. It is only
   * used for linker to reserve space for the main stack section
   * WARNING: .stack should come immediately after the last secure memory
   * section.  This provides stack overflow detection. */
  .stack (NOLOAD):
  {
    __StackLimit = .;
    *(.stack*);
    . += 0x8000 - (. - __StackLimit);
  } > RAM

  /* Set stack top to end of RAM, and stack limit move down by
   * size of stack_dummy section */
  __StackTop = ADDR(.stack) + SIZEOF(.stack);
  __StackLimit = ADDR(.stack);
  PROVIDE(__stack = __StackTop);

  .data :
  {
    PROVIDE( __etext = LOADADDR(.data) );
    
    __data_start__ = .;
    PROVIDE( __start_vector_table__ = .);
  	. += __vector_size;
  	PROVIDE( __end_vector_table__ = .);
    *(vtable)
    *(.data*)

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
    . = ALIGN(32);
    __data_end__ = .;

  } > RAM AT>FLASH

  /* uvisor configuration data */
  .uvisor.secure :
  {
    . = ALIGN(32);
    __uvisor_secure_start = .;

    /* uvisor secure boxes configuration tables */
    . = ALIGN(32);
    __uvisor_cfgtbl_start = .;
    KEEP(*(.keep.uvisor.cfgtbl))
    . = ALIGN(32);
    __uvisor_cfgtbl_end = .;

    /* pointers to uvisor secure boxes configuration tables */
    /* note: no further alignment here, we need to have the exact list of pointers */
    __uvisor_cfgtbl_ptr_start = .;
    KEEP(*(.keep.uvisor.cfgtbl_ptr_first))
    KEEP(*(.keep.uvisor.cfgtbl_ptr))
    __uvisor_cfgtbl_ptr_end = .;

    . = ALIGN(32);
    __uvisor_secure_end = .;
  } >FLASH
  
  .bss (NOLOAD):
  {
    __bss_start__ = .;
    *(.bss*)
    *(COMMON)
    __bss_end__ = .;
  } > RAM

  .heap (NOLOAD):
  {
    __end__ = .;
    end = __end__;
    *(.heap*);
    . += (ORIGIN(RAM) + LENGTH(RAM) - .);
    __HeapLimit = .;
  } > RAM
  PROVIDE(__heap_size = SIZEOF(.heap));
  PROVIDE(__mbed_sbrk_start = ADDR(.heap));
  PROVIDE(__mbed_krbs_start = ADDR(.heap) + SIZEOF(.heap));
    
  /* heap limit is all the available memory, */
  __heap_end = ORIGIN(RAM) + LENGTH(RAM);

  /* Check if data + heap + stack exceeds RAM limit */
  ASSERT(__end__ <= __heap_end, "region RAM overflowed with stack")
}

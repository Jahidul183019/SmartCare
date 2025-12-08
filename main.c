#include <stdint.h>

// ITM register addresses
#define ITM_PORT0   (*((volatile uint32_t *)0xE0000000))
#define ITM_TER     (*((volatile uint32_t *)0xE0000E00))
#define ITM_TCR     (*((volatile uint32_t *)0xE0000E80))

// ONLY function: Send a single character
void ITM_SendChar_C(char ch) {
    while ((ITM_PORT0 & 1) == 0);
    ITM_PORT0 = ch;
}

// Optional: Initialize ITM (called from assembly)
void ITM_Init_C(void) {
    ITM_TCR = 0x0001000D;
    ITM_TER = 0x00000001;
}

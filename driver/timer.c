#include <am.h>
#include <klib.h>
#include <klib-macros.h>

#define TIMER0_BASE_ADDR 0x10004000
#define TIMER0_REG_CTRL  *((volatile uint32_t *)(TIMER0_BASE_ADDR + 0))
#define TIMER0_REG_PSCR  *((volatile uint32_t *)(TIMER0_BASE_ADDR + 4))
#define TIMER0_REG_CNT   *((volatile uint32_t *)(TIMER0_BASE_ADDR + 8))
#define TIMER0_REG_CMP   *((volatile uint32_t *)(TIMER0_BASE_ADDR + 12))
#define TIMER0_REG_STAT  *((volatile uint32_t *)(TIMER0_BASE_ADDR + 16))

void timer_init() {
    TIMER0_REG_CTRL = (uint32_t)0x0;
    while(TIMER0_REG_STAT == 1);           // clear irq
    TIMER0_REG_CMP  = (uint32_t)(50000-1); // 50MHz for 1ms
    printf("CTRL: %d PSCR: %d CMP: %d\n", TIMER0_REG_CTRL, TIMER0_REG_PSCR, TIMER0_REG_CMP);
}

void delay_ms(uint32_t val) {
    TIMER0_REG_CTRL = (uint32_t)0xD;
    for(int i = 1; i <= val; ++i) {
        while(TIMER0_REG_STAT == 0);
    }
    TIMER0_REG_CTRL = (uint32_t)0x0;
}

int main(){
    putstr("timer test\n");
    timer_init();

    putstr("no div test start\n");
    for(int i = 1; i <= 10; ++i) {
        delay_ms(1000);
        putstr("delay 1s\n");
    }

    putstr("no div test done\n");
    putstr("div test start\n");
    TIMER0_REG_CTRL = (uint32_t)0x0;
    while(TIMER0_REG_STAT == 1);               // clear irq
    TIMER0_REG_PSCR = (uint32_t)(50 - 1);      // div/50
    TIMER0_REG_CMP  = (uint32_t)(1000000 - 1); // 50MHz for 1s
    printf("CTRL: %d PSCR: %d CMP: %d\n", TIMER0_REG_CTRL, TIMER0_REG_PSCR, TIMER0_REG_CMP);

    for(int i = 1; i <= 10; ++i) {
        TIMER0_REG_CTRL = (uint32_t)0xD;       // 0000_1101 down count
        while(TIMER0_REG_STAT == 0);
        TIMER0_REG_CTRL = (uint32_t)0x0;
        putstr("delay 1s\n");
    }
    printf("CTRL: %d PSCR: %d CMP: %d\n", TIMER0_REG_CTRL, TIMER0_REG_PSCR, TIMER0_REG_CMP);
    putstr("test done\n");

    return 0;
}

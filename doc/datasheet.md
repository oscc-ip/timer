## Datasheet

### Overview
The `timer` IP is a fully parameterised soft IP using for some timing tasks. The IP features an APB4 slave interface, fully compliant with the AMBA APB Protocol Specification v2.0.

### Feature
* Programmable prescaler
    * max division factor is up to 2^20
    * can be changed ongoing
* 32-bit programmable timer counter and compare register
* Auto reload counter
* Multiple clock source
    * internal division clock
    * external low-speed clock
* Multiple counter mode
    * up counting
    * down counting
* Input capture mode support
    * 1 channel
    * rise or fall trigger
* Maskable overflow interrupt
* Static synchronous design
* Full synthesizable

### Interface
| port name | type        | description          |
|:--------- |:------------|:---------------------|
| apb4      | interface   | apb4 slave interface |
| timer ->    | interface   | timer slave interface |
| `timer.exclk_i` | input | extern periodic signal |
| `timer.capch_i` | input | capture input |
| `timer.irq_o` | output | interrupt output|

### Register
| name | offset  | length | description |
|:----:|:-------:|:-----: | :---------: |
| [CTRL](#control-register) | 0x0 | 4 | control register |
| [PSCR](#prescaler-reigster) | 0x4 | 4 | prescaler register |
| [CNT](#counter-reigster) | 0x8 | 4 | counter register |
| [CMP](#compare-reigster) | 0xC | 4 | compare register |
| [STAT](#state-register) | 0x10 | 4 | state register |

#### Control Register
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:8]` | none | reserved |
| `[7:7]` | RW | EEN |
| `[6:4]` | RW | ETM |
| `[3:3]` | RW | IDM |
| `[2:2]` | RW | EN |
| `[1:1]` | RW | ETR |
| `[0:0]` | RW | OVIE |

reset value: `0x0000_0000`

* EEN: extern capture enable
    * `EEN = 1'b0`: extern capture mode disabled
    * `EEN = 1'b1`: extern capture mode enabled

* ETM: extern trigger mode
    * `ETM = 3'b000(NONE)`: none
    * `ETM = 3'b001(RISE)`: rise edge trigger
    * `ETM = 3'b010(FALL)`: fall edge trigger
    * `ETM = 3'b011(CLER)`: clear time counter
    * `ETM = 3'b100(LOAD)`: load time counter

* IDM: time count direction mode
    * `IDM = 1'b0`: count up
    * `IDM = 1'b1`: count down

* EN: time counter enable
    * `EN = 1'b0`: time counter disabled
    * `EN = 1'b1`: timer counter enabled

* ETR: extern tick clock trigger
    * `ETR = 1'b0`: intern clock trigger
    * `ETR = 1'b1`: extern periodic signal trigger

* OVIE: overflow interrupt enable
    * `OVIE = 1'b0`: overflow interrupt disabled
    * `OVIE = 1'b1`: overflow interrupt enabled

#### Prescaler Reigster
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:20]` | none | reserved |
| `[19:0]` | RW | PSCR |

reset value: `0x0000_0002`

* PSCR: the 20-bit prescaler value

#### Counter Reigster
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:0]` | none | CNT |

reset value: `0x0000_0000`

* CNT: the 32-bit extern capture counter value

#### Compare Reigster
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:0]` | RW | CMP |

reset value: `0x0000_0000`

* CMP: the 32-bit compare register value

#### State Reigster
| bit | access  | description |
|:---:|:-------:| :---------: |
| `[31:1]` | none | reserved |
| `[0:0]` | RO | OVIF |

reset value: `0x0000_0000`

* OVIF: the overflow interrupt flag

### Program Guide
These registers can be accessed by 4-byte aligned read and write. C-like pseudocode for the initialization operation:
```c
timer.CTRL = 0x00000000 // reset ctrl register
while(timer.STAT == 1); // clear irq state
timer.PSCR = PSCR_32_bit
timer.CMP = CMP_32_bit
```
timing mode:
```c
REG_CTRL.[EN, OVIE] = 1 // enable intern counter and interrupt

// polling style
while(timer.STAT == 0);

// interrupt style
timer_interrupt_handle() {
    timer.CTRL.OVIE = 0   // disable interrupt
    STAT_VAL = timer.STAT // clear interrupt flag
    ... // do something
    timer.CTRL.OVIE = 1   // enable interrupt
}

```
### Resoureces
### References
### Revision History
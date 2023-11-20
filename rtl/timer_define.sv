// Copyright (c) 2023 Beijing Institute of Open Source Chip
// timer is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`ifndef INC_TIMER_DEF_SV
`define INC_TIMER_DEF_SV

/* register mapping
 * TIM_CTRL:
 * BITS:   | 31:4 | 3    | 2  | 1   | 0    |
 * FIELDS: | RES  | MODE | EN | ETR | OVIE |
 * PERMS:  | NONE | RW   | RW | RW  | RW   |
 * -----------------------------------------
 * TIM_PSCR:
 * BITS:   | 31:20 | 19:0 |
 * FIELDS: | RES   | PSCR |
 * PERMS:  | NONE  | RW   |
 * ------------------------------------
 * TIM_CNT:
 * BITS:   | 31:0 |
 * FIELDS: | CNT  |
 * PERMS:  | none |
 * ------------------------------------
 * TIM_CMP:
 * BITS:   | 31:0 |
 * FIELDS: | CMP  |
 * PERMS:  | RW   |
 * ------------------------------------
 * TIM_STAT:
 * BITS:   | 31:1  | 0    |
 * FIELDS: | RES   | OVIF |
 * PERMS:  | NONE  | R    |
 * ------------------------------------
*/
// 50MHz * 1
// min: 1/50 = 0.02us = 20ns
// max: 100/2^20 * 2^32us = 100*2^12us = 409600us = 409.6ms
// timing range: [20ns ~ 409.6ms]
// verilog_format: off
`define TIM_CTRL 4'b0000 // BASEADDR + 0x00
`define TIM_PSCR 4'b0001 // BASEADDR + 0x04
`define TIM_CNT  4'b0010 // BASEADDR + 0x08
`define TIM_CMP  4'b0011 // BASEADDR + 0x0C
`define TIM_STAT 4'b0100 // BASEADDR + 0x10

`define TIM_CTRL_ADDR {26'b0, `TIM_CTRL, 2'b00}
`define TIM_PSCR_ADDR {26'b0, `TIM_PSCR, 2'b00}
`define TIM_CNT_ADDR  {26'b0, `TIM_CNT , 2'b00}
`define TIM_CMP_ADDR  {26'b0, `TIM_CMP , 2'b00}
`define TIM_STAT_ADDR {26'b0, `TIM_STAT, 2'b00}

`define TIM_CTRL_WIDTH 4
`define TIM_PSCR_WIDTH 20
`define TIM_CNT_WIDTH  32
`define TIM_CMP_WIDTH  32
`define TIM_STAT_WIDTH 1

`define PSCR_MIN_VAL  {{(`TIM_PSCR_WIDTH-2){1'b0}}, 2'd2}
// verilog_format: on

interface timer_if ();
  logic exclk_i;
  logic capch_i;
  logic irq_o;

  modport dut(input exclk_i, input capch_i, output irq_o);
  modport tb(output exclk_i, output capch_i, input irq_o);
endinterface
`endif

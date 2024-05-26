// Copyright (c) 2023 Beijing Institute of Open Source Chip
// tmr is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`ifndef INC_TMR_DEF_SV
`define INC_TMR_DEF_SV

/* register mapping
 * TMR_CTRL:
 * BITS:   | 31:8 | 7   | 6:4 | 3   | 2  | 1   | 0    |
 * FIELDS: | RES  | EEN | ETM | IDM | EN | ETR | OVIE |
 * PERMS:  | NONE | RW  | RW  | RW  | RW | RW  | RW   |
 * ----------------------------------------------------
 * TMR_PSCR:
 * BITS:   | 31:20 | 19:0 |
 * FIELDS: | RES   | PSCR |
 * PERMS:  | NONE  | RW   |
 * -----------------------------------------------------
 * TMR_CNT:
 * BITS:   | 31:0 |
 * FIELDS: | CNT  |
 * PERMS:  | none |
 * -----------------------------------------------------
 * TMR_CMP:
 * BITS:   | 31:0 |
 * FIELDS: | CMP  |
 * PERMS:  | RW   |
 * -----------------------------------------------------
 * TMR_STAT:
 * BITS:   | 31:1 | 0    |
 * FIELDS: | RES  | OVIF |
 * PERMS:  | NONE | RO   |
 * -----------------------------------------------------
*/
// 50MHz * 1
// min: 1/50 = 0.02us = 20ns
// max: 2^20 / 10^8 * 2^32s = 45035996s = 521day
// timing range: [20ns ~ 521day]
// verilog_format: off
`define TMR_CTRL 4'b0000 // BASEADDR + 0x00
`define TMR_PSCR 4'b0001 // BASEADDR + 0x04
`define TMR_CNT  4'b0010 // BASEADDR + 0x08
`define TMR_CMP  4'b0011 // BASEADDR + 0x0C
`define TMR_STAT 4'b0100 // BASEADDR + 0x10

`define TMR_CTRL_ADDR {26'b0, `TMR_CTRL, 2'b00}
`define TMR_PSCR_ADDR {26'b0, `TMR_PSCR, 2'b00}
`define TMR_CNT_ADDR  {26'b0, `TMR_CNT , 2'b00}
`define TMR_CMP_ADDR  {26'b0, `TMR_CMP , 2'b00}
`define TMR_STAT_ADDR {26'b0, `TMR_STAT, 2'b00}

`define TMR_CTRL_WIDTH 8
`define TMR_PSCR_WIDTH 20
`define TMR_CNT_WIDTH  32
`define TMR_CMP_WIDTH  32
`define TMR_STAT_WIDTH 1

`define TMR_PSCR_MIN_VAL  {{(`TMR_PSCR_WIDTH-2){1'b0}}, 2'd2}

`define TMR_ETM_NONE 3'b000
`define TMR_ETM_RISE 3'b001
`define TMR_ETM_FALL 3'b010
`define TMR_ETM_CLER 3'b011
`define TMR_ETM_LOAD 3'b100
// verilog_format: on

interface tmr_if (
    input logic exclk_i
);
  logic capch_i;
  logic irq_o;

  modport dut(input exclk_i, input capch_i, output irq_o);
  modport tb(input exclk_i, output capch_i, input irq_o);
endinterface
`endif

// Copyright (c) 2023 Beijing Institute of Open Source Chip
// timer is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`ifndef INC_TIMER_TEST_SV
`define INC_TIMER_TEST_SV

`include "apb4_master.sv"
`include "timer_define.sv"

class TimerTest extends APB4Master;
  string                 name;
  virtual apb4_if.master apb4;

  extern function new(string name = "timer_test", virtual apb4_if.master apb4);
  extern task automatic test_reset_reg();
  extern task automatic test_wr_rd_reg(input bit [31:0] run_times = 1000);
  extern task automatic test_irq(input bit [31:0] run_times = 1000);
endclass

function TimerTest::new(string name, virtual apb4_if.master apb4);
  super.new("apb4_master", apb4);
  this.name = name;
  this.apb4 = apb4;
endfunction

task automatic TimerTest::test_reset_reg();
  super.test_reset_reg();
  // verilog_format: off
  // this.rd_check(`GPIO_PADDIR_ADDR, "PADDIR REG", 32'b0 & this.gpio_mask, Helper::EQUL, Helper::INFO);
  // this.rd_check(`GPIO_PADIN_ADDR, "PADIN REG", 32'b0 & this.gpio_mask, Helper::EQUL, Helper::INFO);
  // this.rd_check(`GPIO_PADOUT_ADDR, "PADOUT REG", 32'b0 & this.gpio_mask, Helper::EQUL, Helper::INFO);
  // verilog_format: on
endtask

task automatic TimerTest::test_wr_rd_reg(input bit [31:0] run_times = 1000);
  super.test_wr_rd_reg();
  // verilog_format: off
  for (int i = 0; i < run_times; i++) begin
    // this.wr_rd_check(`GPIO_PADDIR_ADDR, "PADDIR REG", $random & this.gpio_mask, Helper::EQUL);
    // this.wr_rd_check(`GPIO_PADOUT_ADDR, "PADOUT REG", $random & this.gpio_mask, Helper::EQUL);
    // this.wr_rd_check(`GPIO_INTEN_ADDR, "INTEN REG", $random & this.gpio_mask, Helper::EQUL);
    // this.wr_rd_check(`GPIO_INTTYPE0_ADDR, "INTTYPE0 REG", $random & this.gpio_mask, Helper::EQUL);
    // this.wr_rd_check(`GPIO_INTTYPE1_ADDR, "INTTYPE1 REG", $random & this.gpio_mask, Helper::EQUL);
    // this.wr_rd_check(`GPIO_IOFCFG_ADDR, "IOFCFG REG", $random & this.gpio_mask, Helper::EQUL);
  end
  // verilog_format: on
endtask

`endif

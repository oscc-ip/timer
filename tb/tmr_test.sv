// Copyright (c) 2023 Beijing Institute of Open Source Chip
// tmr is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`ifndef INC_TMR_TEST_SV
`define INC_TMR_TEST_SV

`include "apb4_master.sv"
`include "tmr_define.sv"

class TMRTest extends APB4Master;
  string                 name;
  int                    wr_val;
  int                    ext_pulse_peroid;
  virtual apb4_if.master apb4;
  virtual tmr_if.tb      tmr;

  extern function new(string name = "tmr_test", virtual apb4_if.master apb4, virtual tmr_if.tb tmr);
  extern task automatic test_reset_reg();
  extern task automatic test_wr_rd_reg(input bit [31:0] run_times = 1000);
  extern task automatic test_clk_div(input bit [31:0] run_times = 10);
  extern task automatic test_inc_cnt(input bit [31:0] run_times = 10);
  extern task automatic test_dec_cnt(input bit [31:0] run_times = 10);
  extern task automatic test_irq(input bit [31:0] run_times = 1000);
  extern task automatic test_ext_clk(input bit [31:0] run_times = 10);
  extern task automatic test_ext_cap(input bit [31:0] run_times = 10);
endclass

function TMRTest::new(string name, virtual apb4_if.master apb4, virtual tmr_if.tb tmr);
  super.new("apb4_master", apb4);
  this.name             = name;
  this.wr_val           = 0;
  this.ext_pulse_peroid = 80;
  this.apb4             = apb4;
  this.tmr              = tmr;
endfunction

task automatic TMRTest::test_reset_reg();
  super.test_reset_reg();
  // verilog_format: off
  this.rd_check(`TMR_CTRL_ADDR, "CTRL REG", 32'b0 & {`TMR_CTRL_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`TMR_PSCR_ADDR, "PSCR REG", 32'd2 & {`TMR_PSCR_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`TMR_CMP_ADDR, "CMP REG", 32'b0 & {`TMR_CMP_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  this.rd_check(`TMR_STAT_ADDR, "STAT REG", 32'b0 & {`TMR_STAT_WIDTH{1'b1}}, Helper::EQUL, Helper::INFO);
  // verilog_format: on
endtask

task automatic TMRTest::test_wr_rd_reg(input bit [31:0] run_times = 1000);
  super.test_wr_rd_reg();
  // verilog_format: off
  for (int i = 0; i < run_times; i++) begin
    this.wr_rd_check(`TMR_CTRL_ADDR, "CTRL REG", $random & {`TMR_CTRL_WIDTH{1'b1}}, Helper::EQUL);
    this.wr_rd_check(`TMR_CMP_ADDR, "CMP REG", $random & {`TMR_CMP_WIDTH{1'b1}}, Helper::EQUL);
  end
  // verilog_format: on
endtask

task automatic TMRTest::test_clk_div(input bit [31:0] run_times = 10);
  $display("=== [test tmr clk div] ===");
  this.read(`TMR_STAT_ADDR);  // clear irq

  repeat (200) @(posedge this.apb4.pclk);
  this.write(`TMR_CTRL_ADDR, 32'b0 & {`TMR_CTRL_WIDTH{1'b1}});
  repeat (200) @(posedge this.apb4.pclk);
  this.write(`TMR_PSCR_ADDR, 32'd10 & {`TMR_PSCR_WIDTH{1'b1}});
  repeat (200) @(posedge this.apb4.pclk);
  this.write(`TMR_PSCR_ADDR, 32'd4 & {`TMR_PSCR_WIDTH{1'b1}});
  repeat (200) @(posedge this.apb4.pclk);
  for (int i = 0; i < run_times; i++) begin
    this.wr_val = ($random % 20) & {`TMR_PSCR_WIDTH{1'b1}};
    if (this.wr_val < 2) this.wr_val = 2;
    if (this.wr_val % 2) this.wr_val -= 1;
    this.wr_rd_check(`TMR_PSCR_ADDR, "PSCR REG", this.wr_val, Helper::EQUL);
    repeat (200) @(posedge this.apb4.pclk);
  end
endtask

task automatic TMRTest::test_inc_cnt(input bit [31:0] run_times = 10);
  $display("=== [test tmr inc cnt] ===");
  this.write(`TMR_CTRL_ADDR, 32'b0 & {`TMR_CTRL_WIDTH{1'b1}});
  this.read(`TMR_STAT_ADDR);  // clear irq
  this.write(`TMR_PSCR_ADDR, 32'd4 & {`TMR_PSCR_WIDTH{1'b1}});
  this.write(`TMR_CMP_ADDR, -32'hF & {`TMR_CMP_WIDTH{1'b1}});
  this.write(`TMR_CTRL_ADDR, 32'b0101 & {`TMR_CTRL_WIDTH{1'b1}});
  repeat (200) @(posedge this.apb4.pclk);
endtask

task automatic TMRTest::test_dec_cnt(input bit [31:0] run_times = 10);
  $display("=== [test tmr dec cnt] ===");
  this.write(`TMR_CTRL_ADDR, 32'b0 & {`TMR_CTRL_WIDTH{1'b1}});
  this.read(`TMR_STAT_ADDR);  // clear irq
  this.write(`TMR_PSCR_ADDR, 32'd4 & {`TMR_PSCR_WIDTH{1'b1}});
  this.write(`TMR_CMP_ADDR, 32'hF & {`TMR_CMP_WIDTH{1'b1}});
  this.write(`TMR_CTRL_ADDR, 32'b1101 & {`TMR_CTRL_WIDTH{1'b1}});
  repeat (200) @(posedge this.apb4.pclk);
endtask

task automatic TMRTest::test_irq(input bit [31:0] run_times = 1000);
  super.test_irq();
  this.write(`TMR_CTRL_ADDR, 32'b0 & {`TMR_CTRL_WIDTH{1'b1}});
  this.read(`TMR_STAT_ADDR);  // clear irq
  this.write(`TMR_PSCR_ADDR, 32'd4 & {`TMR_PSCR_WIDTH{1'b1}});
  this.write(`TMR_CMP_ADDR, -32'hF & {`TMR_CMP_WIDTH{1'b1}});
  this.write(`TMR_CTRL_ADDR, 32'b0101 & {`TMR_CTRL_WIDTH{1'b1}});

  wait (this.tmr.irq_o);
  repeat (200) @(posedge this.apb4.pclk);
  this.write(`TMR_CTRL_ADDR, 32'b0100 & {`TMR_CTRL_WIDTH{1'b1}});
  this.read(`TMR_STAT_ADDR);
  $display("super.rd_data: %h", super.rd_data);
  repeat (200) @(posedge this.apb4.pclk);
  // this.write(`TMR_CTRL_ADDR, 32'b0101 & {`TMR_CTRL_WIDTH{1'b1}});
endtask

task automatic TMRTest::test_ext_clk(input bit [31:0] run_times = 10);
  $display("=== [test ext clk input with dec count] ===");
  repeat (200) @(posedge this.apb4.pclk);
  this.write(`TMR_CTRL_ADDR, 32'b0 & {`TMR_CTRL_WIDTH{1'b1}});
  this.read(`TMR_STAT_ADDR);  // clear irq
  this.write(`TMR_PSCR_ADDR, 32'd4 & {`TMR_PSCR_WIDTH{1'b1}});
  this.write(`TMR_CMP_ADDR, 32'hF & {`TMR_CMP_WIDTH{1'b1}});
  this.write(`TMR_CTRL_ADDR, 32'b1111 & {`TMR_CTRL_WIDTH{1'b1}});
  repeat (200) @(posedge this.apb4.pclk);
endtask

task automatic TMRTest::test_ext_cap(input bit [31:0] run_times = 10);
  $display("=== [test ext cap func] ===");

  repeat (200) @(posedge this.apb4.pclk);
  fork
    begin
      for (int i = 0; i < 1000; i++) begin
        this.tmr.capch_i = 1'b0;
        #(this.ext_pulse_peroid / 2);
        this.tmr.capch_i = 1'b1;
        #(this.ext_pulse_peroid / 2);
      end
    end
    begin
      repeat (20) @(posedge this.apb4.pclk);
      this.write(`TMR_CMP_ADDR, 32'hFF & {`TMR_CMP_WIDTH{1'b1}});
      this.write(`TMR_PSCR_ADDR, 32'd2 & {`TMR_PSCR_WIDTH{1'b1}});
      this.write(`TMR_CTRL_ADDR, 32'b0 & {`TMR_CTRL_WIDTH{1'b1}});
      this.read(`TMR_STAT_ADDR);  // clear irq
      this.write(`TMR_CTRL_ADDR, 32'b0011_0100 & {`TMR_CTRL_WIDTH{1'b1}});  // clr cap cnt
      this.write(`TMR_CTRL_ADDR, 32'b0100_0100 & {`TMR_CTRL_WIDTH{1'b1}});  // load cap cnt
      this.write(`TMR_CTRL_ADDR,
                 32'b1001_0100 & {`TMR_CTRL_WIDTH{1'b1}});  // config rise mode and run
    end
  join

  repeat (200) @(posedge this.apb4.pclk);
  this.read(`TMR_CNT_ADDR);
  $display("%t tim cap cnt: %h", $time, super.rd_data);

endtask

`endif

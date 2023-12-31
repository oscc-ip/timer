// Copyright (c) 2023 Beijing Institute of Open Source Chip
// timer is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`include "apb4_if.sv"
`include "helper.sv"
`include "timer_define.sv"

program automatic test_top (
    apb4_if.master apb4,
    timer_if.tb    timer
);

  string wave_name = "default.fsdb";
  task sim_config();
    $timeformat(-9, 1, "ns", 10);
    if ($test$plusargs("WAVE_ON")) begin
      $value$plusargs("WAVE_NAME=%s", wave_name);
      $fsdbDumpfile(wave_name);
      $fsdbDumpvars("+all");
    end
  endtask

  TimerTest timer_hdl;

  initial begin
    Helper::start_banner();
    sim_config();
    @(posedge apb4.presetn);
    Helper::print("tb init done");
    timer_hdl = new("timer_test", apb4, timer);
    timer_hdl.init();

    timer_hdl.test_reset_reg();
    timer_hdl.test_wr_rd_reg();
    timer_hdl.test_clk_div();
    timer_hdl.test_inc_cnt();
    timer_hdl.test_dec_cnt();
    timer_hdl.test_irq();
    timer_hdl.test_ext_clk();
    timer_hdl.test_ext_cap();
    Helper::end_banner();
    #20000 $finish;
  end

endprogram

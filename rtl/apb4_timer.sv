// Copyright (c) 2023 Beijing Institute of Open Source Chip
// timer is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`include "register.sv"
`include "clk_int_div.sv"
`include "cdc_sync.sv"
`include "counter.sv"
`include "timer_define.sv"

module apb4_timer (
    apb4_if.slave apb4,
    timer_if.dut  timer
);

  logic [3:0] s_apb4_addr;
  logic [`TIM_CTRL_WIDTH-1:0] s_tim_ctrl_d, s_tim_ctrl_q;
  logic [`TIM_PSCR_WIDTH-1:0] s_tim_pscr_d, s_tim_pscr_q;
  logic [`TIM_CMP_WIDTH-1:0] s_tim_cmp_d, s_tim_cmp_q;
  logic [`TIM_STAT_WIDTH-1:0] s_tim_stat_d, s_tim_stat_q;
  logic s_valid, s_done, s_inclk, s_tr_clk, s_ov_irq, s_cnt_ov;
  logic s_apb4_wr_hdshk, s_apb4_rd_hdshk, s_normal_mode;

  assign s_apb4_addr = apb4.paddr[5:2];
  assign s_apb4_wr_hdshk = apb4.psel && apb4.penable && apb4.pwrite;
  assign s_apb4_rd_hdshk = apb4.psel && apb4.penable && (~apb4.pwrite);
  assign apb4.pready = 1'b1;
  assign apb4.pslverr = 1'b0;

  assign s_tr_clk = s_tim_ctrl_q[1] ? timer.exclk_i : s_inclk;
  assign s_normal_mode = s_tim_ctrl_q[2] & s_done;
  assign s_ov_irq = s_tim_ctrl_q[1] & s_tim_stat_q[0];
  assign timer.irq_o = s_ov_irq;

  assign s_tim_ctrl_d = (s_apb4_wr_hdshk && s_apb4_addr == `TIM_CTRL) ? apb4.pwdata[`TIM_CTRL_WIDTH-1:0]: s_tim_ctrl_q;
  dffr #(`TIM_CTRL_WIDTH) u_tim_ctrl_dffr (
      apb4.pclk,
      apb4.presetn,
      s_tim_ctrl_d,
      s_tim_ctrl_q
  );

  always_comb begin
    s_tim_pscr_d = s_tim_pscr_q;
    if (s_apb4_wr_hdshk && s_apb4_addr == `TIM_PSCR) begin
      s_tim_pscr_d = apb4.pwdata[`TIM_PSCR_WIDTH-1:0] < `PSCR_MIN_VAL ? `PSCR_MIN_VAL : apb4.pwdata[`TIM_PSCR_WIDTH-1:0];
    end
  end

  dffrc #(`TIM_PSCR_WIDTH, `PSCR_MIN_VAL) u_tim_pscr_dffr (
      .clk_i  (apb4.pclk),
      .rst_n_i(apb4.presetn),
      .dat_i  (s_tim_pscr_d),
      .dat_o  (s_tim_pscr_q)
  );

  assign s_valid = s_apb4_wr_hdshk && s_apb4_addr == `TIM_PSCR && s_done;
  clk_int_even_div_simple #(`TIM_PSCR_WIDTH) u_clk_int_even_div_simple (
      .clk_i      (apb4.pclk),
      .rst_n_i    (apb4.presetn),
      .div_i      (s_tim_pscr_q),
      .div_valid_i(s_valid),
      .div_ready_o(),
      .div_done_o (s_done),
      .clk_o      (s_inclk)
  );

  counter #(`TIM_CNT_WIDTH) u_tim_cnt_counter (
      .clk_i  (s_tr_clk),
      .rst_n_i(apb4.presetn),
      .clr_i  (~s_normal_mode),
      .en_i   (s_normal_mode),
      .load_i (s_cnt_ov),
      .down_i (s_tim_ctrl_q[3]),
      .dat_i  (s_tim_cmp_q),
      .dat_o  (),
      .ovf_o  (s_cnt_ov)
  );

  assign s_tim_cmp_d = (s_apb4_wr_hdshk && s_apb4_addr == `TIM_CMP) ? apb4.pwdata[`TIM_CMP_WIDTH-1:0] : s_tim_cmp_q;
  dffr #(`TIM_CMP_WIDTH) u_tim_cmp_dffr (
      apb4.pclk,
      apb4.presetn,
      s_tim_cmp_d,
      s_tim_cmp_q
  );

  cdc_sync #(2, 1) u_irq_cdc_sync (
      apb4.pclk,
      apb4.presetn,
      s_cnt_ov,
      s_tim_stat_d[0]
  );

  // assign s_tim_stat_d = s_tim_stat_q;
  dffr #(`TIM_STAT_WIDTH) u_tim_stat_dffr (
      apb4.pclk,
      apb4.presetn,
      s_tim_stat_d,
      s_tim_stat_q
  );

  always_comb begin
    apb4.prdata = '0;
    if (s_apb4_rd_hdshk) begin
      unique case (s_apb4_addr)
        `TIM_CTRL: apb4.prdata[`TIM_CTRL_WIDTH-1:0] = s_tim_ctrl_q;
        `TIM_PSCR: apb4.prdata[`TIM_PSCR_WIDTH-1:0] = s_tim_pscr_q;
        `TIM_CMP:  apb4.prdata[`TIM_CMP_WIDTH-1:0] = s_tim_cmp_q;
        `TIM_STAT: apb4.prdata[`TIM_STAT_WIDTH-1:0] = s_tim_stat_q;
        default:   apb4.prdata = '0;
      endcase
    end
  end

endmodule


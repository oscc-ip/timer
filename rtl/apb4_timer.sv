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
`include "timer_define.sv"

module apb4_timer (
    // verilog_format: off
    apb4_if.slave apb4,
    output logic irq_o
    // verilog_format: on
);

  logic [3:0] s_apb4_addr;
  logic [`TIM_CTRL_WIDTH-1:0] s_tim_ctrl_d, s_tim_ctrl_q;
  logic [`TIM_PSCR_WIDTH-1:0] s_tim_pscr_d, s_tim_pscr_q;
  logic [`TIM_CNT_WIDTH-1:0] s_tim_cnt_d, s_tim_cnt_q;
  logic [`TIM_CMP_WIDTH-1:0] s_tim_cmp_d, s_tim_cmp_q;
  logic s_valid, s_done, s_tr_clk, s_ov_irq;
  logic s_apb4_wr_hdshk, s_apb4_rd_hdshk, s_normal_mode;

  assign s_apb4_addr     = apb4.paddr[5:2];
  assign s_apb4_wr_hdshk = apb4.psel && apb4.penable && apb4.pwrite;
  assign s_apb4_rd_hdshk = apb4.psel && apb4.penable && (~apb4.pwrite);
  assign apb4.pready     = 1'b1;
  assign apb4.pslverr    = 1'b0;

  assign s_normal_mode   = s_tim_ctrl_q[2] & s_done;
  assign s_ov_irq        = s_tim_ctrl_q[1] & s_tim_ctrl_q[0];
  assign irq_o           = s_ov_irq;

  always_comb begin
    s_tim_pscr_d = s_tim_pscr_q;
    if (s_apb4_wr_hdshk && s_apb4_addr == `TIM_PSCR) begin
      s_tim_pscr_d = apb4.pwdata[`TIM_PSCR_WIDTH-1:0] < `PSCR_MIN_VAL ? `PSCR_MIN_VAL : apb4.pwdata[`TIM_PSCR_WIDTH-1:0];
    end
  end

  dffr #(`TIM_PSCR_WIDTH) u_tim_pscr_dffr (
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
      .clk_o      (s_tr_clk)
  );

  always_comb begin
    s_tim_cnt_d = s_tim_cnt_q;
    if (s_normal_mode) begin
      if (s_tim_cnt_q == s_tim_cmp_q) begin
        s_tim_cnt_d = '0;
      end else begin
        s_tim_cnt_d = s_tim_cnt_q + 1'b1;
      end
    end
  end

  dffr #(`TIM_CNT_WIDTH) u_tim_cnt_dffr (
      s_tr_clk,
      apb4.presetn,
      s_tim_cnt_d,
      s_tim_cnt_q
  );

  always_comb begin
    s_tim_ctrl_d = s_tim_ctrl_q;
    if (s_apb4_wr_hdshk && s_apb4_addr == `TIM_CTRL) begin
      s_tim_ctrl_d = apb4.pwdata[`TIM_CTRL_WIDTH-1:0];
    end else if (s_normal_mode) begin
      if (s_tim_cnt_q == s_tim_cmp_q) begin
        s_tim_ctrl_d[0] = 1'b1;
      end else begin
        s_tim_ctrl_d[0] = 1'b0; // TODO:
      end
    end
  end

  dffr #(`TIM_CTRL_WIDTH) u_tim_ctrl_dffr (
      apb4.pclk,
      apb4.presetn,
      s_tim_ctrl_d,
      s_tim_ctrl_q
  );

  assign s_tim_cmp_d = (s_apb4_wr_hdshk && s_apb4_addr == `TIM_CMP) ? apb4.pwdata[`TIM_CMP_WIDTH-1:0] : s_tim_cmp_q;
  dffr #(`TIM_CMP_WIDTH) u_tim_cmp_dffr (
      apb4.pclk,
      apb4.presetn,
      s_tim_cmp_d,
      s_tim_cmp_q
  );

  always_comb begin
    apb4.prdata = '0;
    if (s_apb4_rd_hdshk) begin
      unique case (s_apb4_addr)
        `TIM_CTRL: apb4.prdata[`TIM_CTRL_WIDTH-1:0] = s_tim_ctrl_q;
        `TIM_PSCR: apb4.prdata[`TIM_PSCR_WIDTH-1:0] = s_tim_pscr_q;
        `TIM_CMP:  apb4.prdata[`TIM_CMP_WIDTH-1:0] = s_tim_cmp_q;
        default:   apb4.prdata = '0;
      endcase
    end
  end

endmodule


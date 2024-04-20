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
`include "edge_det.sv"
`include "timer_define.sv"

module apb4_timer (
    apb4_if.slave apb4,
    timer_if.dut  timer
);

  logic [3:0] s_apb4_addr;
  logic s_apb4_wr_hdshk, s_apb4_rd_hdshk;
  logic [`TIM_CNT_WIDTH-1:0] s_tim_cap_cnt;
  logic [`TIM_CTRL_WIDTH-1:0] s_tim_ctrl_d, s_tim_ctrl_q;
  logic s_tim_ctrl_en;
  logic [`TIM_PSCR_WIDTH-1:0] s_tim_pscr_d, s_tim_pscr_q;
  logic s_tim_pscr_en;
  logic [`TIM_CMP_WIDTH-1:0] s_tim_cmp_d, s_tim_cmp_q;
  logic s_tim_cmp_en;
  logic [`TIM_STAT_WIDTH-1:0] s_tim_stat_d, s_tim_stat_q;
  logic s_time_stat_en;
  logic s_cap_gap_cnt_d, s_cap_gap_cnt_q;
  logic s_cap_gap_cnt_en;
  logic s_bit_ovie, s_bit_etr, s_bit_en, s_bit_idm;
  logic [2:0] s_bit_etm;
  logic s_valid, s_done, s_inclk, s_tc_clk, s_ov_trg, s_ov_irq_trg, s_normal_mode;
  logic s_norm_trg1, s_norm_trg2;
  logic s_cap_in, s_cap_rise, s_cap_fall, s_cap_clr, s_cap_load, s_cap_en, s_cap_trg;

  assign s_apb4_addr     = apb4.paddr[5:2];
  assign s_apb4_wr_hdshk = apb4.psel && apb4.penable && apb4.pwrite;
  assign s_apb4_rd_hdshk = apb4.psel && apb4.penable && (~apb4.pwrite);
  assign apb4.pready     = 1'b1;
  assign apb4.pslverr    = 1'b0;

  assign s_bit_ovie      = s_tim_ctrl_q[0];
  assign s_bit_etr       = s_tim_ctrl_q[1];
  assign s_bit_en        = s_tim_ctrl_q[2];
  assign s_bit_idm       = s_tim_ctrl_q[3];
  assign s_bit_etm       = s_tim_ctrl_q[6:4];
  assign s_cap_en        = s_tim_ctrl_q[7];
  assign s_bit_ovif      = s_tim_stat_q[0];
  assign s_cap_clr       = s_bit_etm == `TIM_ETM_CLER;
  assign s_cap_load      = s_bit_etm == `TIM_ETM_LOAD;
  assign s_tc_clk        = s_bit_etr ? timer.exclk_i : s_inclk;
  assign s_normal_mode   = s_bit_en & s_done;
  assign timer.irq_o     = s_bit_ovif;

  assign s_tim_ctrl_en   = s_apb4_wr_hdshk && s_apb4_addr == `TIM_CTRL;
  assign s_tim_ctrl_d    = apb4.pwdata[`TIM_CTRL_WIDTH-1:0];
  dffer #(`TIM_CTRL_WIDTH) u_tim_ctrl_dffer (
      apb4.pclk,
      apb4.presetn,
      s_tim_ctrl_en,
      s_tim_ctrl_d,
      s_tim_ctrl_q
  );

  assign s_tim_pscr_en = s_apb4_wr_hdshk && s_apb4_addr == `TIM_PSCR;
  always_comb begin
    s_tim_pscr_d = s_tim_pscr_q;
    if (s_tim_pscr_en) begin
      s_tim_pscr_d = apb4.pwdata[`TIM_PSCR_WIDTH-1:0] < `TIM_PSCR_MIN_VAL ? `TIM_PSCR_MIN_VAL : apb4.pwdata[`TIM_PSCR_WIDTH-1:0];
    end
  end
  dfferc #(`TIM_PSCR_WIDTH, `TIM_PSCR_MIN_VAL) u_tim_pscr_dfferc (
      apb4.pclk,
      apb4.presetn,
      s_tim_pscr_en,
      s_tim_pscr_d,
      s_tim_pscr_q
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

  cdc_sync_det #(
      .STAGE     (2),
      .DATA_WIDTH(1)
  ) u_cnt_cdc_sync (
      s_tc_clk,
      apb4.presetn,
      s_normal_mode,
      s_norm_trg1,
      s_norm_trg2
  );

  // count up/down
  counter #(`TIM_CNT_WIDTH) u_tim_cnt_counter (
      .clk_i  (s_tc_clk),
      .rst_n_i(apb4.presetn),
      .clr_i  (~s_normal_mode),
      .en_i   (s_normal_mode),
      .load_i ((~s_norm_trg2 && s_norm_trg1) || s_ov_trg),
      .down_i (s_bit_idm),
      .dat_i  (s_tim_cmp_q),
      .dat_o  (),
      .ovf_o  (s_ov_trg)
  );

  assign s_tim_cmp_en = s_apb4_wr_hdshk && s_apb4_addr == `TIM_CMP;
  assign s_tim_cmp_d  = apb4.pwdata[`TIM_CMP_WIDTH-1:0];
  dffer #(`TIM_CMP_WIDTH) u_tim_cmp_dffer (
      apb4.pclk,
      apb4.presetn,
      s_tim_cmp_en,
      s_tim_cmp_d,
      s_tim_cmp_q
  );

  cdc_sync #(
      .STAGE     (2),
      .DATA_WIDTH(1)
  ) u_irq_cdc_sync (
      apb4.pclk,
      apb4.presetn,
      s_ov_trg,
      s_ov_irq_trg
  );

  assign s_tim_stat_en = (s_bit_ovif && s_apb4_rd_hdshk && s_apb4_addr == `TIM_STAT) || (~s_bit_ovif && s_bit_en && s_bit_ovie && s_ov_irq_trg);
  always_comb begin
    s_tim_stat_d = s_tim_stat_q;
    if (s_bit_ovif && s_apb4_rd_hdshk && s_apb4_addr == `TIM_STAT) begin
      s_tim_stat_d = '0;
    end else if (~s_bit_ovif && s_bit_en && s_bit_ovie && s_ov_irq_trg) begin
      s_tim_stat_d = '1;
    end
  end
  dffer #(`TIM_STAT_WIDTH) u_tim_stat_dffer (
      apb4.pclk,
      apb4.presetn,
      s_tim_stat_en,
      s_tim_stat_d,
      s_tim_stat_q
  );

  always_comb begin
    apb4.prdata = '0;
    if (s_apb4_rd_hdshk) begin
      unique case (s_apb4_addr)
        `TIM_CTRL: apb4.prdata[`TIM_CTRL_WIDTH-1:0] = s_tim_ctrl_q;
        `TIM_PSCR: apb4.prdata[`TIM_PSCR_WIDTH-1:0] = s_tim_pscr_q;
        `TIM_CNT:  apb4.prdata[`TIM_CNT_WIDTH-1:0] = s_tim_cap_cnt;
        `TIM_CMP:  apb4.prdata[`TIM_CMP_WIDTH-1:0] = s_tim_cmp_q;
        `TIM_STAT: apb4.prdata[`TIM_STAT_WIDTH-1:0] = s_tim_stat_q;
        default:   apb4.prdata = '0;
      endcase
    end
  end

  // pulse capture
  edge_det #(
      .STAGE     (3),
      .DATA_WIDTH(1)
  ) u_edge_det (
      apb4.pclk,
      apb4.presetn,
      timer.capch_i,
      s_cap_in,
      s_cap_rise,
      s_cap_fall
  );

  always_comb begin
    s_cap_trg = '0;
    if (s_bit_etm == `TIM_ETM_RISE) begin
      s_cap_trg = s_cap_rise;
    end else if (s_bit_etm == `TIM_ETM_FALL) begin
      s_cap_trg = s_cap_fall;
    end
  end

  assign s_cap_gap_cnt_en = s_cap_clr || s_cap_trg;
  always_comb begin
    s_cap_gap_cnt_d = s_cap_gap_cnt_q;
    if (s_cap_clr) begin
      s_cap_gap_cnt_d = '0;
    end else if (s_cap_trg && s_cap_gap_cnt_q < 1'b1) begin
      s_cap_gap_cnt_d = s_cap_gap_cnt_q + 1'b1;
    end
  end
  dffer #(1) u_cap_gap_cnt_dffer (
      apb4.pclk,
      apb4.presetn,
      s_cap_gap_cnt_en,
      s_cap_gap_cnt_d,
      s_cap_gap_cnt_q
  );

  // count down
  counter #(`TIM_CNT_WIDTH) u_tim_cap_cnt_counter (
      .clk_i  (apb4.pclk),
      .rst_n_i(apb4.presetn),
      .clr_i  (s_cap_clr),
      .en_i   (s_cap_en && (s_cap_gap_cnt_q < 1'b1)),
      .load_i (s_cap_load),
      .down_i (1'b1),
      .dat_i  ('1),
      .dat_o  (s_tim_cap_cnt),
      .ovf_o  ()
  );


endmodule


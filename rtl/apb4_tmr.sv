// Copyright (c) 2023 Beijing Institute of Open Source Chip
// tmr is licensed under Mulan PSL v2.
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
`include "tmr_define.sv"

module apb4_tmr (
    apb4_if.slave apb4,
    tmr_if.dut    tmr
);

  logic [3:0] s_apb4_addr;
  logic s_apb4_wr_hdshk, s_apb4_rd_hdshk;
  logic [`TMR_CNT_WIDTH-1:0] s_tmr_cap_cnt;
  logic [`TMR_CTRL_WIDTH-1:0] s_tmr_ctrl_d, s_tmr_ctrl_q;
  logic s_tmr_ctrl_en;
  logic [`TMR_PSCR_WIDTH-1:0] s_tmr_pscr_d, s_tmr_pscr_q;
  logic s_tmr_pscr_en;
  logic [`TMR_CMP_WIDTH-1:0] s_tmr_cmp_d, s_tmr_cmp_q;
  logic s_tmr_cmp_en;
  logic [`TMR_STAT_WIDTH-1:0] s_tmr_stat_d, s_tmr_stat_q;
  logic s_tmre_stat_en;
  logic s_cap_gap_cnt_d, s_cap_gap_cnt_q;
  logic s_cap_gap_cnt_en;
  logic s_bit_ovie, s_bit_etr, s_bit_en, s_bit_idm;
  logic [2:0] s_bit_etm;
  logic s_valid, s_done, s_in_trg, s_ext_trg, s_tc_trg, s_ov_trg, s_ov_irq_trg;
  logic s_normal_mode, s_norm_trg1, s_norm_trg2;
  logic s_cap_in, s_cap_rise, s_cap_fall, s_cap_clr, s_cap_load, s_cap_en, s_cap_trg;

  assign s_apb4_addr     = apb4.paddr[5:2];
  assign s_apb4_wr_hdshk = apb4.psel && apb4.penable && apb4.pwrite;
  assign s_apb4_rd_hdshk = apb4.psel && apb4.penable && (~apb4.pwrite);
  assign apb4.pready     = 1'b1;
  assign apb4.pslverr    = 1'b0;

  assign s_bit_ovie      = s_tmr_ctrl_q[0];
  assign s_bit_etr       = s_tmr_ctrl_q[1];
  assign s_bit_en        = s_tmr_ctrl_q[2];
  assign s_bit_idm       = s_tmr_ctrl_q[3];
  assign s_bit_etm       = s_tmr_ctrl_q[6:4];
  assign s_cap_en        = s_tmr_ctrl_q[7];
  assign s_bit_ovif      = s_tmr_stat_q[0];
  assign s_cap_clr       = s_bit_etm == `TMR_ETM_CLER;
  assign s_cap_load      = s_bit_etm == `TMR_ETM_LOAD;
  assign s_tc_trg        = s_bit_etr ? s_ext_trg : s_in_trg;
  assign s_normal_mode   = s_bit_en & s_done;
  assign tmr.irq_o       = s_bit_ovif;

  assign s_tmr_ctrl_en   = s_apb4_wr_hdshk && s_apb4_addr == `TMR_CTRL;
  assign s_tmr_ctrl_d    = apb4.pwdata[`TMR_CTRL_WIDTH-1:0];
  dffer #(`TMR_CTRL_WIDTH) u_tmr_ctrl_dffer (
      apb4.pclk,
      apb4.presetn,
      s_tmr_ctrl_en,
      s_tmr_ctrl_d,
      s_tmr_ctrl_q
  );

  assign s_tmr_pscr_en = s_apb4_wr_hdshk && s_apb4_addr == `TMR_PSCR;
  assign s_tmr_pscr_d  = apb4.pwdata[`TMR_PSCR_WIDTH-1:0];
  dffer #(`TMR_PSCR_WIDTH) u_tmr_pscr_dffer (
      apb4.pclk,
      apb4.presetn,
      s_tmr_pscr_en,
      s_tmr_pscr_d,
      s_tmr_pscr_q
  );

  assign s_valid = s_apb4_wr_hdshk && s_apb4_addr == `TMR_PSCR && s_done;
  clk_int_div_simple #(`TMR_PSCR_WIDTH) u_clk_int_div_simple (
      .clk_i      (apb4.pclk),
      .rst_n_i    (apb4.presetn),
      .div_i      (s_tmr_pscr_q),
      .div_valid_i(s_valid),
      .div_ready_o(),
      .div_done_o (s_done),
      .clk_trg_o  (s_in_trg)
  );

  cdc_sync #(
      .STAGE     (2),
      .DATA_WIDTH(1)
  ) u_ext_trg_cdc_sync (
      apb4.pclk,
      apb4.presetn,
      tmr.exclk_i,
      s_ext_trg
  );

  cdc_sync_det #(
      .STAGE     (2),
      .DATA_WIDTH(1)
  ) u_cnt_cdc_sync_det (
      apb4.pclk,
      apb4.presetn,
      s_normal_mode,
      s_norm_trg1,
      s_norm_trg2
  );

  // count up/down
  counter #(`TMR_CNT_WIDTH) u_tmr_cnt_counter (
      .clk_i  (apb4.pclk),
      .rst_n_i(apb4.presetn),
      .clr_i  (~s_normal_mode),
      .en_i   (s_normal_mode && s_tc_trg),
      .load_i ((~s_norm_trg2 && s_norm_trg1) || s_ov_trg),
      .down_i (s_bit_idm),
      .dat_i  (s_tmr_cmp_q),
      .dat_o  (),
      .ovf_o  (s_ov_trg)
  );

  assign s_tmr_cmp_en = s_apb4_wr_hdshk && s_apb4_addr == `TMR_CMP;
  assign s_tmr_cmp_d  = apb4.pwdata[`TMR_CMP_WIDTH-1:0];
  dffer #(`TMR_CMP_WIDTH) u_tmr_cmp_dffer (
      apb4.pclk,
      apb4.presetn,
      s_tmr_cmp_en,
      s_tmr_cmp_d,
      s_tmr_cmp_q
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

  assign s_tmr_stat_en = (s_bit_ovif && s_apb4_rd_hdshk && s_apb4_addr == `TMR_STAT) || (~s_bit_ovif && s_bit_en && s_bit_ovie && s_ov_irq_trg);
  always_comb begin
    s_tmr_stat_d = s_tmr_stat_q;
    if (s_bit_ovif && s_apb4_rd_hdshk && s_apb4_addr == `TMR_STAT) begin
      s_tmr_stat_d = '0;
    end else if (~s_bit_ovif && s_bit_en && s_bit_ovie && s_ov_irq_trg) begin
      s_tmr_stat_d = '1;
    end
  end
  dffer #(`TMR_STAT_WIDTH) u_tmr_stat_dffer (
      apb4.pclk,
      apb4.presetn,
      s_tmr_stat_en,
      s_tmr_stat_d,
      s_tmr_stat_q
  );

  always_comb begin
    apb4.prdata = '0;
    if (s_apb4_rd_hdshk) begin
      unique case (s_apb4_addr)
        `TMR_CTRL: apb4.prdata[`TMR_CTRL_WIDTH-1:0] = s_tmr_ctrl_q;
        `TMR_PSCR: apb4.prdata[`TMR_PSCR_WIDTH-1:0] = s_tmr_pscr_q;
        `TMR_CNT:  apb4.prdata[`TMR_CNT_WIDTH-1:0] = s_tmr_cap_cnt;
        `TMR_CMP:  apb4.prdata[`TMR_CMP_WIDTH-1:0] = s_tmr_cmp_q;
        `TMR_STAT: apb4.prdata[`TMR_STAT_WIDTH-1:0] = s_tmr_stat_q;
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
      tmr.capch_i,
      s_cap_in,
      s_cap_rise,
      s_cap_fall
  );

  always_comb begin
    s_cap_trg = '0;
    if (s_bit_etm == `TMR_ETM_RISE) begin
      s_cap_trg = s_cap_rise;
    end else if (s_bit_etm == `TMR_ETM_FALL) begin
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
  counter #(`TMR_CNT_WIDTH) u_tmr_cap_cnt_counter (
      .clk_i  (apb4.pclk),
      .rst_n_i(apb4.presetn),
      .clr_i  (s_cap_clr),
      .en_i   (s_cap_en && (s_cap_gap_cnt_q < 1'b1)),
      .load_i (s_cap_load),
      .down_i (1'b1),
      .dat_i  ('1),
      .dat_o  (s_tmr_cap_cnt),
      .ovf_o  ()
  );


endmodule


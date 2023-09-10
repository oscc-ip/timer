// Copyright 2015 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// -- Adaptable modifications are redistributed under compatible License --
//
// Copyright (c) 2023 Beijing Institute of Open Source Chip
// timer is licensed under Mulan PSL v2.
// You can use this software according to the terms and conditions of the Mulan PSL v2.
// You may obtain a copy of Mulan PSL v2 at:
//             http://license.coscl.org.cn/MulanPSL2
// THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
// EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
// MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
// See the Mulan PSL v2 for more details.

`define REGS_MAX_ADR 2'd2
`define REGS_MAX_IDX 'd2
`define REG_TIMER 2'b00
`define REG_TIMER_CTRL 2'b01
`define REG_CMP 2'b10
`define PRESCALER_STARTBIT 'd3
`define PRESCALER_STOPBIT 'd5
`define ENABLE_BIT 'd0

module apb4_timer #(
    parameter TIM_NUM        = 2
) (
    apb4_if                       apb4,
    logic  [(TIM_NUM * 2) - 1:0] irq_o
);

  logic [          TIM_NUM-1:0]       psel;
  logic [          TIM_NUM-1:0]       pready;
  logic [          TIM_NUM-1:0]       pslverr;
  logic [          TIM_NUM-1:0][31:0] prdata;
  logic [$clog2(TIM_NUM) - 1:0]       addr;

  assign addr = apb.paddr[$clog2(TIM_NUM)+`REGS_MAX_ADR+1:`REGS_MAX_ADR+2];

  always_comb begin
    psel       = '0;
    psel[addr] = apb.psel;
  end

  always_comb begin
    if (psel != '0) begin
      apb.prdata  = prdata[addr];
      apb.pready  = pready[addr];
      apb.pslverr = pslverr[addr];
    end else begin
      apb.prdata  = '0;
      apb.pready  = 1'd1;
      apb.pslverr = 1'd0;
    end
  end

  genvar i;
  generate
    for (i = 0; i < TIM_NUM; i++) begin : TIMER_GEN
      timer u_timer (apb.);
    end
  endgenerate
endmodule

module timer  (
           apb_if       apb,
    output logic  [1:0] irq_o
);

  // APB register interface
  logic [`REGS_MAX_IDX-1:0] reg_addr;
  assign reg_addr    = apb.paddr[`REGS_MAX_IDX+2:2];
  // APB logic: we are always ready to capture the data into our regs
  // not supporting transfare failure
  assign apb.pready  = 1'b1;
  assign apb.pslverr = 1'b0;
  // registers
  logic [0:`REGS_MAX_IDX][31:0] regs_q;
  logic [0:`REGS_MAX_IDX][31:0] regs_n;
  logic [           31:0]       cycle_counter_n;
  logic [           31:0]       cycle_counter_q;
  logic [            2:0]       prescaler_int;

  //irq
  always_comb begin
    irq_o = 2'b00;
    // overlow irq
    if (regs_q[`REG_TIMER] == 32'hFFFF_FFFF) irq_o[0] = 1'b1;
    // compare match irq if compare reg ist set
    if (regs_q[`REG_CMP] != 'b0 && regs_q[`REG_TIMER] == regs_q[`REG_CMP]) irq_o[1] = 1'b1;

  end

  assign prescaler_int = regs_q[`REG_TIMER_CTRL][`PRESCALER_STOPBIT:`PRESCALER_STARTBIT];
  // register write logic
  always_comb begin
    regs_n          = regs_q;
    cycle_counter_n = cycle_counter_q + 1;

    // reset timer after cmp or overflow
    if (irq_o[0] == 1'b1 || irq_o[1] == 1'b1) regs_n[`REG_TIMER] = 'b0;
    else if(regs_q[`REG_TIMER_CTRL][`ENABLE_BIT] && prescaler_int != 'b0 && prescaler_int == cycle_counter_q) // prescaler
      regs_n[`REG_TIMER] = regs_q[`REG_TIMER] + 1;  //prescaler mode
    else if (regs_q[`REG_TIMER_CTRL][`ENABLE_BIT] && prescaler_int == 'b0)  // normal count mode
      regs_n[`REG_TIMER] = regs_q[`REG_TIMER] + 1;

    // reset prescaler cycle counter
    if (cycle_counter_q >= regs_q[`REG_TIMER_CTRL]) cycle_counter_n = 32'b0;

    // written from APB bus - gets priority
    if (apb.psel && apb.penable && apb.pwrite) begin
      unique case (reg_addr)
        `REG_TIMER:      regs_n[`REG_TIMER] = apb.pwdata;
        `REG_TIMER_CTRL: regs_n[`REG_TIMER_CTRL] = apb.pwdata;
        `REG_CMP: begin
          regs_n[`REG_CMP]   = apb.pwdata;
          regs_n[`REG_TIMER] = 32'b0;  // reset timer if compare register is written
        end
      endcase
    end
  end

  // APB register read logic
  always_comb begin
    apb.prdata = 'd0;
    if (apb.psel && apb.penable && !apb.pwrite) begin
      unique case (reg_addr)
        `REG_TIMER:      apb.prdata = regs_q[`REG_TIMER];
        `REG_TIMER_CTRL: apb.prdata = regs_q[`REG_TIMER_CTRL];
        `REG_CMP:        apb.prdata = regs_q[`REG_CMP];
      endcase
    end
  end

  always_ff @(posedge apb.pclk, negedge apb.presetn) begin
    if (~apb.presetn) begin
      regs_q          <= '{default: 32'd0};
      cycle_counter_q <= 32'd0;
    end else begin
      regs_q          <= regs_n;
      cycle_counter_q <= cycle_counter_n;
    end
  end
endmodule


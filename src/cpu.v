// RISCV32 CPU top module
// port modification allowed for debugging purposes
module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here
// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

always @(posedge clk_in)
  begin
    if (rst_in)
      begin
        
      end
    else if (!rdy_in)
      begin

      end
    else
      begin
      
      end
  end

  assign mem_dout = lsb.ram_data;
  assign mem_a = lsb.ram_addr;
  assign mem_wr = lsb.ram_writing;
  assign dbgreg_dout = 0;

AU au(
  .clk(clk_in),
  .rst(ic.rst),
  .value1(rs.memory_value1),
  .value2(rs.memory_imm),
  .op_input(rs.memory_op),
  .rob_number_input(rs.memory_des),
  .ls_value(rs.memory_value2)
);

ALU alu(
  .clk(clk_in),
  .rst(ic.rst),
  .value_1(rs.alu_value1),
  .value_2(rs.alu_value2),
  .op(rs.alu_op),
  .des_input(rs.alu_des)
);

IC ic(
  .clk(clk_in),
  .data(lsb.ins_value),
  .data_ready(lsb.ins_ready),
  .branch_taken(rob.branch_taken),
  .branch_pc(rob.branch_pc),
  .jalr_addr(rob.jalr_pc),
  .jalr_ready(rob.jalr_ready),
  .pc_ready(rob.pc_ready),
  .nxt_pc(rob.nxt_pc),
  .lsb_full(lsb.if_full),
  .iq_full(iq.iq_full)
);

Decoder decoder(
  .clk(clk_in),
  .rst(ic.rst),
  .instruction(ic.instruction)
);

IQ iq(
  .clk(clk_in),
  .rst(ic.rst),
  .op(decoder.op),
  .rs1(decoder.rs1),
  .rs2(decoder.rs2),
  .rd(decoder.rd),
  .imm(decoder.imm),
  .rob_full(rob.rob_full)
);

ROB rob(
  .clk(clk_in),
  .rst(ic.rst),
  .has_imm(iq.has_imm),
  .imm(iq.imm_out),
  .now_pc(ic.pc),
  .rd(iq.rd_out),
  .op(iq.op_out),
  .value1_rf(rf.value1),
  .value2_rf(rf.value2),
  .query1_rf(rf.query1),
  .query2_rf(rf.query2),
  .rs_full(rs.rs_full),
  .alu_num(alu.des),
  .alu_value(alu.result),
  .mem_num(lsb.output_number),
  .mem_value(lsb.output_value),
  .ready_load_num(lsb.can_be_load)
);

RF rf(
  .clk(clk_in),
  .rst(ic.rst),
  .commit(rob.commit),
  .reg_num(rob.rd_out),
  .data_in(rob.value_out),
  .num_in(rob.num_out),
  .instruction(iq.shooted),
  .rs1(iq.rs1_out),
  .rs2(iq.rs2_out),
  .rd(iq.rd_out),
  .dependency_num(rob.tail) 
);

RS rs(
  .clk(clk_in),
  .rst(ic.rst),
  .alu_data(alu.result),
  .alu_des_in(alu.des),
  .memory_data(lsb.output_value),
  .memory_des_in(lsb.output_number),
  .des_in(rob.target),
  .op(rob.op_out),
  .value1(rob.value1_out),
  .value2(rob.value2_out),
  .query1(rob.query1_out),
  .query2(rob.query2_out),
  .memory_busy(lsb.buffer_full),
  .imm_in(rob.imm_out)
);

LSB lsb(
  .clk(clk_in),
  .rst(ic.rst),
  .pc_addr(ic.addr),
  .new_ins(ic.asking),
  .addr(au.addr),
  .data(au.ls_value_output),
  .rob_number(au.rob_number),
  .op(au.op),
  .committed_number(rob.ls_num_out),
  .ram_loaded_data(mem_din)
);

endmodule


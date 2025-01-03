module ROB(
        input wire clk,
        input wire rst,
        input wire pause,
        input wire has_imm,
        input wire[31:0] imm,
        input wire[31:0] now_pc,
        input wire[4:0] rd,
        input wire[4:0] op,
        input wire [31:0] value1_rf,
        input wire [31:0] value2_rf,
        input wire [2:0] query1_rf,
        input wire [2:0] query2_rf,
        input wire[2:0] alu_num,
        input wire[31:0] alu_value,
        input wire is_branch_input,
        input wire[2:0] mem_num,
        input wire[31:0] mem_value,
        input wire[2:0] ready_load_num,
        output reg rob_full,
        output reg[4:0] op_out,
        output reg[31:0] value1_out,
        output reg[31:0] value2_out,
        output reg[2:0] query1_out,
        output reg[2:0] query2_out,
        output reg is_branch_out,
        output reg commit,
        output reg[4:0] rd_out,
        output reg[2:0] num_out,
        output reg[31:0] value_out,
        output reg[2:0] ls_num_out,
        output reg branch_taken,
        output reg[31:0] branch_pc,
        output reg jalr_ready,
        output reg[31:0] jalr_pc,
        output reg pc_ready,
        output reg[31:0] nxt_pc,
        output reg[2:0] tail,
        output reg[2:0] target,
        output reg[31:0] imm_out,
        output reg branch_not_taken
    );
    reg[2:0] last_ins;
    reg [2:0] head;
    reg to_shoot;
    reg [4:0] rob_op[7:0];
    reg [4:0] rob_rd[7:0];
    reg [4:0] head_op;
    reg [31:0] head_value;
    reg [0:0]rob_busy[7:0];
    reg [1:0]rob_ready[7:0];//00:executing, 01:can be load_store committed, 10: branch not taken, 11: can be committed
    reg [31:0]rob_value[7:0];
    reg [2:0] cnt;
    reg add;
    reg minus;
    integer init;
    initial begin
        head_op = 5'b11111;
        rob_full = 0;
        op_out = 5'b11111;
        value1_out = 0;
        value2_out = 0;
        query1_out = 0;
        query2_out = 0;
        is_branch_out = 0;
        commit = 0;
        rd_out = 0;
        num_out = 0;
        value_out = 0;
        ls_num_out = 0;
        branch_taken = 0;
        branch_pc = 0;
        jalr_ready = 0;
        jalr_pc = 0;
        pc_ready = 0;
        nxt_pc = 0;
        target = 0;
        imm_out = 0;
        is_branch_out = 0;
        add = 0;
        minus = 0;
        cnt = 0;
        jalr_ready = 0;
        pc_ready = 0;
        branch_not_taken = 0;
        ls_num_out = 0;
        head = 1;
        tail = 1;
        head_value = 0;
        last_ins = 7;
        i = 0;
        rob_full = 0;
        to_shoot = 0;
        commit = 0;
        op_out = 5'b11111;
        for(init = 0; init < 8; init = init + 1) begin
            rob_busy[init] = 1'b0;
            rob_op[init] = 5'b11111;
            rob_value[init] = 0;
            rob_ready[init] = 2'b00;
        end
    end
    localparam [4:0]
               ADD = 5'b00000,
               AND = 5'b00001,
               OR  = 5'b00010,
               SLL = 5'b00011,
               SRL = 5'b00100,
               SLT  = 5'b00101,
               SLTU = 5'b00110,
               SRA = 5'b00111,
               SUB = 5'b01000,
               XOR = 5'b01001,
               BEQ  = 5'b01010,
               BGE  = 5'b01011,
               BNE = 5'b01100,
               BGEU = 5'b01101,
               LUI = 5'b01110,
               AUIPC = 5'b01111,
               JAL = 5'b10000,
               JALR = 5'b10001,
               LB = 5'b10010,
               LH = 5'b10011,
               LW = 5'b10100,
               LBU = 5'b10101,
               LHU = 5'b10110,
               SB = 5'b10111,
               SH = 5'b11000,
               SW = 5'b11001,
               BLT = 5'b11010,
               BLTU = 5'b11011,
               JAL_C = 5'b11100;

    integer i;
    always@(posedge clk) begin
        if(!pause)begin
        add = 0;
        if(!rst)begin
            rob_value[mem_num] = mem_value;
            rob_ready[mem_num] = 2'b11;
            if((mem_num != ready_load_num) && (rob_ready[ready_load_num] != 2'b11)) begin
                rob_ready[ready_load_num] = 2'b01;
            end
        end else begin
            tail = 1;
            to_shoot = 0;
        end
        if(!rst) begin
                if(is_branch_input) begin
                    if(alu_value == 0) begin
                        rob_ready[alu_num] = 2'b10;
                    end
                    else begin
                        rob_ready[alu_num] = 2'b11;
                    end
                end
                else begin
                    rob_value[alu_num] = alu_value;
                    rob_ready[alu_num] = 2'b11;
                end
        end
        if(!rst) begin
            if(op != 5'b11111) begin
                rob_op[tail] = op;
                 if(op == LUI || op == AUIPC || op == JAL || op == JAL_C) begin
                    rob_ready[tail] = 2'b11;
                end else begin
                    rob_ready[tail] = 2'b00;
                end
                rob_rd[tail] <= rd;
                rob_value[tail] = imm;
                if(tail != 7) begin
                    tail = tail + 1;
                end
                else begin
                    tail = 1;
                end
                add = 1;
                to_shoot = 1;
            end
            else begin
                to_shoot = 0;
            end
        end else begin
          for(i = 1; i < 8; i = i + 1) begin
            rob_ready[i] = 0;
          end
        end
        if(tail == 0) begin
            tail = 1;
        end
        head_value = rob_value[head];
        head_op = rob_op[head];
        last_ins = (tail == 1) ? 7 : (tail - 1);
    end
    end
    always@(negedge clk) begin
        if(!pause)begin
        if(!rst) begin
            cnt = cnt + add;
            rob_full <= (cnt >= 5);
            if(to_shoot) begin
                rob_busy[last_ins] = 1;
                if(op == LUI || op == AUIPC || op == JAL || op == JAL_C) begin
                    op_out <= 5'b11111;
                end
                else begin
                    op_out <= rob_op[last_ins];
                end
                if(op == BEQ || op == BGE || op == BNE || op == BGEU || op == BLT || op == BLTU) begin
                    is_branch_out <= 1;
                end else begin
                    is_branch_out <= 0;
                end
                if(query1_rf == 0) begin
                    value1_out <= value1_rf;
                    query1_out <= query1_rf;
                end
                else if(rob_ready[query1_rf] == 2'b11 || rob_ready[query1_rf] == 2'b10) begin
                    value1_out <= rob_value[query1_rf];
                    query1_out <= 0;
                end
                else begin
                    value1_out <= 0;
                    query1_out <= query1_rf;
                end
                if(has_imm && (!((rob_op[last_ins] >= SB) && (rob_op[last_ins] <= BLTU))) && (!((rob_op[last_ins] >= BEQ) && (rob_op[last_ins] <= BGEU)))) begin
                    value2_out <= imm;
                    query2_out <= 0;
                end
                else begin
                    if(query2_rf == 0) begin
                        value2_out <= value2_rf;
                        query2_out <= query2_rf;
                    end
                    else if(rob_ready[query2_rf] == 2'b11 || rob_ready[query2_rf] == 2'b10) begin
                        value2_out <= rob_value[query2_rf];
                        query2_out <= 0;
                    end
                    else begin
                        value2_out <= 0;
                        query2_out <= query2_rf;
                    end
                end
                imm_out <= imm;
                target <= last_ins;
            end
            else begin
                op_out <= 5'b11111;
                target <= 0;
            end
            if(rob_busy[head] == 0) begin
                commit <= 0;
                pc_ready <= 0;
                branch_taken <= 0;
                branch_not_taken <= 0;
                jalr_ready <= 0;
            end
            else begin
                if(rob_ready[head] == 2'b01) begin
                    ls_num_out <= head;
                end
                else begin
                    ls_num_out <= 0;
                end
                if(rob_ready[head] == 2'b11) begin
                    branch_not_taken <= 0;
                    rob_busy[head] = 1'b0;
                    if(rob_rd[head] != 0) begin
                        commit <= 1;
                        rd_out <= rob_rd[head];
                        case(head_op)
                        JALR:
                            value_out <= (now_pc + 4);
                        JAL:
                            value_out <= (now_pc + 4);
                        JAL_C:
                            value_out <= (now_pc + 2);
                        AUIPC:
                            value_out <= (now_pc + head_value);
                        default:
                            value_out <= head_value;
                    endcase
                        num_out <= head;
                    end
                    if(head != 7) begin
                        head <= head + 1;
                    end
                    else begin
                        head <= 1;
                    end
                    cnt = cnt - 1;
                    if(rob_op[head] == JALR) begin
                        branch_not_taken <= 0;
                        branch_taken <= 0;
                        pc_ready <= 0;
                        jalr_ready <= 1;
                        jalr_pc <= rob_value[head];
                    end
                    else begin
                        jalr_ready <= 0;
                        if(rob_op[head] == BNE || rob_op[head] == BEQ || rob_op[head] == BLT || rob_op[head] == BLTU || rob_op[head] == BGE || rob_op[head] == BGEU) begin
                            pc_ready <= 0;
                            branch_not_taken <= 0;
                            branch_taken <= 1;
                            branch_pc <= rob_value[head] + now_pc;
                        end
                        else begin
                            branch_taken <= 0;
                            branch_not_taken <= 0;
                            pc_ready <= 1;
                            if(rob_op[head] == JAL || rob_op[head] == JAL_C) begin
                                nxt_pc = (rob_value[head] + now_pc);
                            end
                            else begin
                                    nxt_pc = 32'hffffffff;
                            end
                        end
                    end
                end
                else begin
                    if(rob_ready[head] == 2'b10) begin
                        commit <= 1;
                        rob_busy[head] = 1'b0;
                        rd_out <= 0;
                        value_out <= 0;
                        num_out <= head;
                        if(head != 7) begin
                            head <= head + 1;
                        end
                        else begin
                            head <= 1;
                        end
                        cnt = cnt - 1;
                        pc_ready <= 0;
                        branch_taken <= 0;
                        jalr_ready <= 0;
                        branch_not_taken <= 1;
                        nxt_pc = 32'hffffffff;
                    end
                    else begin
                        branch_not_taken <= 0;
                        commit <= 0;
                        pc_ready <= 0;
                        branch_taken <= 0;
                        jalr_ready <= 0;
                    end
                end
            end
        end
        else begin
            cnt = 0;
            ls_num_out <= 0;
            branch_taken <= 0;
            jalr_ready <= 0;
            pc_ready <= 0;
            head <= 1;
            rob_full <= 0;
            commit <= 0;
            op_out <= 5'b11111;
            for(i = 1; i < 8; i = i + 1) begin
                rob_busy[i] = 1'b0;
            end
        end
    end
    end
endmodule

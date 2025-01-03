module RS(
        input wire clk,
        input wire rst,
        input wire pause,
        input wire[31:0] alu_data,
        input wire[2:0] alu_des_in,
        input wire[31:0] memory_data,
        input wire[2:0] memory_des_in,
        input wire[2:0] des_in,
        input wire[4:0] op,
        input wire[31:0] value1,
        input wire[31:0] value2,
        input wire[31:0] imm_in,
        input wire[2:0] query1,
        input wire[2:0] query2,
        input wire is_branch_input,
        output reg[4:0] alu_op,
        output reg[31:0] alu_value1,
        output reg[31:0] alu_value2,
        output reg is_branch_out,
        output reg[2:0] alu_des,
        output reg[4:0] memory_op,
        output reg[31:0] memory_value1,
        output reg[31:0] memory_value2,
        output reg[31:0] memory_imm,
        output reg[2:0] memory_des,
        output reg rs_full
    );
    reg [2:0]alu_in_tmp;
    reg [2:0]memory_in_tmp;
    reg [31:0]alu_data_tmp;
    reg [31:0]memory_data_tmp;
    reg[4:0] op_rs[5:0];
    reg[31:0] value1_rs[5:0];
    reg[31:0] value2_rs[5:0];
    reg[2:0] des_rs[5:0];
    reg[5:0] query1_rs[5:0];
    reg[5:0] query2_rs[5:0];
    reg[0:0] is_branch[5:0];
    reg[31:0] imm[5:0];
    reg busy[6:0];
    reg alu_shooted;
    reg memory_shooted;
    reg [2:0]busy_check_alu;
    reg [2:0]busy_check_memory;
    integer i;
    integer j;
    integer k;
    integer l;
    reg [2:0] alu_shoot_tmp;
    reg [2:0] memory_shoot_tmp;
    reg flag;
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
               BLTU = 5'b11011;
    initial begin
        rs_full = 0;
        busy[0] = 0;
        busy[1] = 0;
        busy[2] = 0;
        busy[3] = 0;
        busy[4] = 0;
        flag = 0;
        busy[5] = 0;
        alu_op = 5'b11111;
        memory_op = 5'b11111;
        is_branch_out = 0;
        alu_des = 0;
        memory_des = 0;
        alu_shooted = 0;
        memory_shooted = 0;
        alu_shoot_tmp = 6;
        memory_shoot_tmp = 6;
        alu_data_tmp = 0;
        alu_in_tmp = 0;
        alu_value1 = 0;
        alu_value2 = 0;
        busy_check_alu = 0;
        busy_check_memory = 0;
        i = 0;
        j = 0;
        k = 0;
        l = 0;
        memory_data_tmp = 0;
        memory_in_tmp = 0;
        memory_imm = 0;
        memory_value1 = 0;
        memory_value2 = 0;
    end

    always@(posedge clk) begin
        if(!pause) begin
        alu_in_tmp = alu_des_in;
        memory_in_tmp = memory_des_in;
        alu_data_tmp = alu_data;
        memory_data_tmp = memory_data;
        if(!rst) begin
            busy[alu_shoot_tmp] = 0;
            busy[memory_shoot_tmp] = 0;
            for(j = 0; j < 6; j = j + 1) begin
                if(busy[j]) begin
                    if(alu_des_in != 0) begin
                        if(query1_rs[j] == alu_des_in) begin
                            value1_rs[j] <= alu_data;
                            query1_rs[j] <= 0;
                        end
                        if(query2_rs[j] == alu_des_in) begin
                            value2_rs[j] <= alu_data;
                            query2_rs[j] <= 0;
                        end
                    end
                    if(memory_des_in != 0) begin
                        if(query1_rs[j] == memory_des_in) begin
                            value1_rs[j] <= memory_data;
                            query1_rs[j] <= 0;
                        end
                        if(query2_rs[j] == memory_des_in) begin
                            value2_rs[j] <= memory_data;
                            query2_rs[j] <= 0;
                        end
                    end
                end
            end
            if(op != 5'b11111) begin
                flag = 1;
                if(op >= LB && (!(op > SW))) begin
                    for(i = 3; (i < 6) && flag; i = i + 1) begin
                        if(!busy[i]) begin
                            busy[i] = 1;
                            op_rs[i] <= op;
                            des_rs[i] <= des_in;
                            if(query1 == 0) begin
                                value1_rs[i] <= value1;
                                query1_rs[i] <= query1;
                            end
                            else begin
                                if(query1 == alu_in_tmp) begin
                                    value1_rs[i] <= alu_data_tmp;
                                    query1_rs[i] <= 0;
                                end
                                else if(query1 == memory_in_tmp) begin
                                    value1_rs[i] <= memory_data_tmp;
                                    query1_rs[i] <= 0;
                                end
                                else begin
                                    value1_rs[i] <= 0;
                                    query1_rs[i] <= query1;
                                end
                            end

                            if(query2 == 0) begin
                                value2_rs[i] <= value2;
                                query2_rs[i] <= query2;
                            end
                            else begin
                                if(query2 == alu_in_tmp) begin
                                    value2_rs[i] <= alu_data_tmp;
                                    query2_rs[i] <= 0;
                                end
                                else if(query2 == memory_in_tmp) begin
                                    value2_rs[i] <= memory_data_tmp;
                                    query2_rs[i] <= 0;
                                end
                                else begin
                                    value2_rs[i] <= 0;
                                    query2_rs[i] <= query2;
                                end
                            end
                            imm[i] <= imm_in;
                            flag = 0;
                        end
                    end
                end
                else begin
                    for(i = 0; (i < 3) && flag; i = i + 1) begin
                        if(!busy[i]) begin
                            busy[i] = 1;
                            is_branch[i] <= is_branch_input;
                            op_rs[i] <= op;
                            des_rs[i] <= des_in;
                            if(query1 == 0) begin
                                value1_rs[i] <= value1;
                                query1_rs[i] <= query1;
                            end
                            else begin
                                if(query1 == alu_in_tmp) begin
                                    value1_rs[i] <= alu_data_tmp;
                                    query1_rs[i] <= 0;
                                end
                                else if(query1 == memory_in_tmp) begin
                                    value1_rs[i] <= memory_data_tmp;
                                    query1_rs[i] <= 0;
                                end
                                else begin
                                    value1_rs[i] <= 0;
                                    query1_rs[i] <= query1;
                                end
                            end

                            if(query2 == 0) begin
                                value2_rs[i] <= value2;
                                query2_rs[i] <= query2;
                            end
                            else begin
                                if(query2 == alu_in_tmp) begin
                                    value2_rs[i] <= alu_data_tmp;
                                    query2_rs[i] <= 0;
                                end
                                else if(query2 == memory_in_tmp) begin
                                    value2_rs[i] <= memory_data_tmp;
                                    query2_rs[i] <= 0;
                                end
                                else begin
                                    value2_rs[i] <= 0;
                                    query2_rs[i] <= query2;
                                end
                            end
                            flag = 0;
                        end
                    end
                end
            end
        end else begin
            busy[0] = 0;
            busy[1] = 0;
            busy[2] = 0;
            busy[3] = 0;
            busy[4] = 0;
            busy[5] = 0;
        end
    end
    end

    always@(negedge clk) begin
        if(!pause)begin
        if(!rst) begin
            busy_check_alu = busy[0] + busy[1] + busy[2];
            busy_check_memory = busy[3] + busy[4] + busy[5];
            if(((busy_check_alu & 2'b10) != 0) || ((busy_check_memory & 2'b10) != 0)) begin
                rs_full <= 1;
            end else begin
                rs_full <= 0;
            end
            alu_shooted = 0;
            memory_shooted = 0;
            for(k = 0; k < 3 && (!alu_shooted); k = k + 1) begin
                if(busy[k]) begin
                    if(query1_rs[k] == 0 && query2_rs[k] == 0) begin
                        alu_value1 <= value1_rs[k];
                        alu_value2 <= value2_rs[k];
                        alu_des <= des_rs[k];
                        alu_op <= op_rs[k];
                        is_branch_out <= is_branch[k];
                        alu_shoot_tmp = k;
                        alu_shooted = 1;
                    end
                end
            end
            for(l = 3; l < 6 && (!memory_shooted); l = l + 1) begin
                if(busy[l]) begin
                    if(query1_rs[l] == 0 && query2_rs[l] == 0) begin
                        memory_value1 <= value1_rs[l];
                        memory_value2 <= value2_rs[l];
                        memory_des <= des_rs[l];
                        memory_op <= op_rs[l];
                        memory_imm <= imm[l];
                        memory_shoot_tmp = l;
                        memory_shooted = 1;
                    end
                end
            end
            if(!alu_shooted) begin
                alu_des <= 0;
                alu_shoot_tmp = 6;
            end
            if(!memory_shooted) begin
                memory_op <= 5'b11111;
                memory_shoot_tmp = 6;
                memory_des <= 0;
            end
        end
        else begin
            alu_shooted = 0;
            memory_shooted = 0;
            rs_full = 0;
        end
    end
    end
endmodule

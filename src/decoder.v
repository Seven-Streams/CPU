module Decoder(
        input wire clk,
        input wire rst,
        input [31:0] instruction,
        output reg[4:0] op,
        output reg[4:0] rs1,
        output reg[4:0] rs2,
        output reg[4:0] rd,
        output reg[31:0] imm,
        output reg has_imm
    );
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
    integer value[3:0];
    reg[4:0] op_tmp;
    reg[4:0] rs1_tmp;
    reg[4:0] rs2_tmp;
    reg[4:0] rd_tmp;
    reg[31:0] imm_tmp;
    reg [0:0]has_imm_tmp;

    always@(posedge clk) begin
        op_tmp = 5'b11111;
        if(instruction != 0) begin
            if(instruction[1:0] == 2'b11) begin
                case(instruction[6:0])
                    7'b0110111: begin
                        op_tmp <= LUI;
                        rd_tmp <= instruction[11:7];
                        imm_tmp <= (instruction[31:12] << 12);
                        has_imm_tmp <= 1;
                        rs1_tmp <= 0;
                        rs2_tmp <= 0;
                    end
                    7'b0010111: begin
                        op_tmp <= AUIPC;
                        rd_tmp <= instruction[11:7];
                        imm_tmp <= (instruction[31:12] << 12);
                        has_imm_tmp <= 1;
                        rs1_tmp <= 0;
                        rs2_tmp <= 0;
                    end
                    7'b1101111: begin
                        op_tmp <= JAL;
                        value[0] = instruction[31];
                        value[0] = value[0] << 20;
                        value[1] = instruction[19:12];
                        value[1] = value[1] << 12;
                        value[2] = instruction[20];
                        value[2] = value[2] << 11;
                        value[3] = instruction[30:21];
                        value[3] = value[3] << 1;
                        imm_tmp  <= (value[0] + value[1] + value[2] + value[3]);
                        rd_tmp <= instruction[11:7];
                        has_imm_tmp <= 1;
                        rs1_tmp <= 0;
                        rs2_tmp <= 0;
                    end
                    7'b1100111: begin
                        op_tmp <= JALR;
                        rs1_tmp <= instruction[19:15];
                        rd_tmp <= instruction[11:7];
                        imm_tmp <= instruction[31:20];
                        rs2_tmp <= 0;
                        has_imm_tmp <= 1;
                    end
                    7'b1100011: begin
                        case (instruction[14:12])
                            3'b000:
                                op_tmp  <= BEQ;
                            3'b001:
                                op_tmp  <= BNE;
                            3'b100:
                                op_tmp  <= BLT;
                            3'b101:
                                op_tmp  <= BGE;
                            3'b110:
                                op_tmp  <= BLTU;
                            3'b111:
                                op_tmp  <= BGEU;
                            default:
                                op_tmp  <= 5'b11111;
                        endcase
                        rs1_tmp  <= instruction[19:15];
                        rs2_tmp  <= instruction[24:20];
                        rd_tmp   <= 0;
                        value[0] = instruction[31];
                        value[0] = value[0] << 12;
                        value[1] = instruction[7];
                        value[1] = value[1] << 11;
                        value[2] = instruction[30:25];
                        value[2] = value[2] << 5;
                        value[3] = instruction[11:8];
                        value[3] = value[3] << 1;
                        imm_tmp  <= (value[0] + value[1] + value[2] + value[3]);
                        has_imm_tmp <= 1;
                    end
                    7'b0000011: begin
                        case(instruction[14:12])
                            3'b000:
                                op_tmp  <= LB;
                            3'b001:
                                op_tmp  <= LH;
                            3'b010:
                                op_tmp  <= LW;
                            3'b100:
                                op_tmp  <= LBU;
                            3'b101:
                                op_tmp  <= LHU;
                            default:
                                op_tmp  <= 5'b11111;
                        endcase
                        rs1_tmp  <= instruction[19:15];
                        rd_tmp  <= instruction[11:7];
                        imm_tmp  <= instruction[31:20];
                        rs2_tmp  <= 0;
                        has_imm_tmp <= 1;
                    end
                    7'b0100011: begin
                        case(instruction[14:12])
                            3'b000:
                                op_tmp  <= SB;
                            3'b001:
                                op_tmp  <= SH;
                            3'b010:
                                op_tmp  <= SW;
                            default:
                                op_tmp  <= 5'b11111;
                        endcase
                        rs1_tmp  <= instruction[19:15];
                        rd_tmp   <= 0;
                        rs2_tmp  <= instruction[24:20];
                        value[0] = instruction[31:25];
                        value[0] = value[0] << 5;
                        value[1] = instruction[11:7];
                        imm_tmp  <= value[0] + value[1];
                        has_imm_tmp <= 1;
                    end
                    7'b0010011: begin
                        if(instruction[14:12] == 3'b101) begin
                            if(instruction[30] == 0) begin
                                op_tmp  <= SRL;
                                imm_tmp  <= instruction[25:20];
                            end
                            else begin
                                op_tmp  <= SRA;
                            end
                        end
                        else begin
                            case(instruction[14:12])
                                3'b000:
                                    op_tmp  <= ADD;
                                3'b001:
                                    op_tmp  <= SLL;
                                3'b010:
                                    op_tmp  <= SLT;
                                3'b011:
                                    op_tmp  <= SLTU;
                                3'b100:
                                    op_tmp  <= XOR;
                                3'b110:
                                    op_tmp  <= OR;
                                3'b111:
                                    op_tmp  <= AND;
                                default:
                                    op_tmp  <= 5'b11111;
                            endcase
                            imm_tmp  <= instruction[31:20];
                        end
                        rs1_tmp  <= instruction[19:15];
                        rd_tmp  <= instruction[11:7];
                        rs2_tmp  <= 0;
                        has_imm_tmp <= 1;
                    end
                    7'b0110011: begin
                        case(instruction[14:12])
                            3'b000: begin
                                if(instruction[30] == 0) begin
                                    op_tmp  <= ADD;
                                end
                                else begin
                                    op_tmp  <= SUB;
                                end
                            end
                            3'b001:
                                op_tmp  <= SLL;
                            3'b010:
                                op_tmp  <= SLT;
                            3'b011:
                                op_tmp  <= SLTU;
                            3'b100:
                                op_tmp  <= XOR;
                            3'b101: begin
                                if(instruction[30] == 0) begin
                                    op_tmp  <= SRL;
                                end
                                else begin
                                    op_tmp  <= SRA;
                                end
                            end
                            3'b110:
                                op_tmp  <= OR;
                            3'b111:
                                op_tmp  <= AND;
                            default:
                                op_tmp  <= 5'b11111;
                        endcase
                        imm_tmp  <= 32'hffffffff;
                        rs1_tmp  <= instruction[19:15];
                        rs2_tmp  <= instruction[24:20];
                        rd_tmp  <= instruction[11:7];
                        has_imm_tmp <= 0;
                    end
                endcase
            end
            else begin
                case(instruction[1:0])
                    2'b10: begin
                        case(instruction[15:13])
                            3'b000: begin
                                op_tmp <= ADD;
                                value[0] = instruction[12];
                                value[0] = value[0] << 5;
                                value[1] = instruction[6:2];
                                imm_tmp <= value[0] + value[1];
                                rd_tmp <= instruction[11:7];
                                rs1_tmp <= instruction[11:7];
                                rs2_tmp <= 0;
                                has_imm_tmp <= 1;
                            end
                            3'b001: begin
                                op_tmp <= JAL_C;
                                value[0] = instruction[12];
                                value[0] = value[0] << 1;
                                value[0] = value[0] + instruction[8];
                                value[0] = value[0] << 2;
                                value[0] = value[0] + instruction[10:9];
                                value[0] = value[0] << 1;
                                value[0] = value[0] + instruction[6];
                                value[0] = value[0] << 1;
                                value[0] = value[0] + instruction[7];
                                value[0] = value[0] << 1;
                                value[0] = value[0] + instruction[2];
                                value[0] = value[0] << 1;
                                value[0] = value[0] + instruction[11];
                                value[0] = value[0] << 3;
                                value[0] = value[0] + instruction[5:3];
                                value[0] = value[0] << 1;
                                imm_tmp <= value[0];
                                rd_tmp <= 1;
                                rs1_tmp <= 0;
                                rs2_tmp <= 0;
                                has_imm_tmp <= 1;
                            end
                            3'b011: begin
                                if(instruction[11:7] == 5'b00010) begin
                                    op_tmp <= ADD;
                                    rd_tmp <= 2;
                                    value[0] = instruction[12];
                                    value[0] = value[0] << 2;
                                    value[0] = value[0] + instruction[4:3];
                                    value[0] = value[0] << 1;
                                    value[0] = value[0] + instruction[5];
                                    value[0] = value[0] << 1;
                                    value[0] = value[0] + instruction[3];
                                    value[0] = value[0] << 1;
                                    value[0] = value[0] + instruction[6];
                                    value[0] = value[0] << 4;
                                    imm_tmp <= value[0];
                                    has_imm_tmp <= 1;
                                    rs1_tmp <= 2;
                                    rs2_tmp <= 0;
                                end
                                else begin
                                    op_tmp <= LUI;
                                    rd_tmp <= instruction[11:7];
                                    value[0] = instruction[12];
                                    value[0] = value[0] << 17;
                                    value[1] = instruction[6:2];
                                    value[1] = value[1] << 12;
                                    imm_tmp <= value[0] + value[1];
                                    rs1_tmp <= 0;
                                    rs2_tmp <= 0;
                                    has_imm_tmp <= 1;
                                end
                            end
                            3'b100: begin
                                rs1_tmp <= instruction[9:7] + 8;
                                rd_tmp <= instruction[9:7] + 8;
                                if(instruction[11:10] == 2'b11) begin
                                    has_imm_tmp <= 0;
                                    rs2_tmp <= instruction[4:2] + 8;
                                    case(instruction[6:5])
                                        2'b00:
                                            op_tmp <= SUB;
                                        2'b01:
                                            op_tmp <= XOR;
                                        2'b10:
                                            op_tmp <= OR;
                                        2'b11:
                                            op_tmp <= AND;
                                    endcase
                                end
                                else begin
                                    has_imm_tmp <= 1;
                                    rs2_tmp <= 0;
                                    value[0] = instruction[12];
                                    value[0] = value[0] << 5;
                                    value[1] = instruction[6:2];
                                    imm_tmp <= value[0] + value[1];
                                    case(instruction[11:10])
                                        2'b00:
                                            op_tmp <= SRL;
                                        2'b01:
                                            op_tmp <= SRA;
                                        2'b10:
                                            op_tmp <= AND;
                                    endcase
                                end
                            end
                        endcase
                    end
                    2'b00: begin
                        if(instruction[15:13] == 3'b010) begin
                            op_tmp <= LW;
                            rd_tmp <= instruction[4:2] + 8;
                            rs1_tmp <= instruction[9:7] + 8;
                            rs2_tmp <= 0;
                            value[0] = instruction[12:10];
                            value[0] = value[0] << 3;
                            value[1] = instruction[5];
                            value[1] = value[1] << 6;
                            value[2] = instruction[6];
                            value[2] = value[2] << 2;
                            imm_tmp <= value[0] + value[1] + value[2];
                            has_imm_tmp <= 1;
                        end
                        else begin
                            op_tmp <= SW;
                            rs1_tmp <= instruction[9:7] + 8;
                            rs2_tmp <= instruction[4:2] + 8;
                            value[0] = instruction[12:10];
                            value[0] = value[0] << 3;
                            value[1] = instruction[5];
                            value[1] = value[1] << 6;
                            value[2] = instruction[6];
                            value[2] = value[2] << 2;
                            imm_tmp <= value[0] + value[1] + value[2];
                            rd_tmp <= 0;
                            has_imm_tmp <= 1;
                        end
                    end
                    2'b10: begin
                        case(instruction[15:13])
                            3'b000: begin
                                op_tmp <= SLL;
                                rd_tmp <= instruction[11:7];
                                rs1_tmp <= instruction[11:7];
                                rs2_tmp <= 0;
                                value[0] = instruction[12];
                                value[0] = value[0] << 5;
                                value[1] = instruction[6:2];
                                imm_tmp <= value[0] + value[1];
                                has_imm_tmp <= 1;
                            end
                            3'b100: begin
                                if(instruction[6:2] == 5'b00000) begin
                                    op_tmp <= JALR;
                                    rs1_tmp <= instruction[11:7];
                                    rd_tmp <= 1;
                                    rs2_tmp <= 0;
                                    has_imm_tmp <= 0;
                                end
                                else begin
                                    op_tmp <= ADD;
                                    rd_tmp <= instruction[11:7];
                                    rs1_tmp <= instruction[11:7];
                                    rs2_tmp <= instruction[6:2];
                                    has_imm_tmp <= 0;
                                end
                            end
                        endcase
                    end
                endcase
            end
        end
    end
    always@(negedge clk) begin
        if(!rst) begin
            op <= op_tmp;
            rs1 <= rs1_tmp;
            rs2 <= rs2_tmp;
            rd <= rd_tmp;
            imm <= imm_tmp;
            has_imm <= has_imm_tmp;
        end
        else begin
            op <= 5'b11111;
        end
    end
endmodule

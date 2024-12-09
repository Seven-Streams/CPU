module AU(
        input wire clk,
        input wire rst,
        input wire[31:0] value1,
        input wire[31:0] value2,
        input wire[4:0] op_input,
        input wire[2:0] rob_number_input,
        input wire[31:0] ls_value,
        output reg[31:0] addr,
        output reg[4:0] op,
        output reg[2:0] rob_number,
        output reg[31:0] ls_value_output
    );
    reg [31:0] value_tmp;
    reg [4:0] op_tmp;
    reg [2:0] rob_number_tmp;
    reg [31:0] ls_value_tmp;
    always@(posedge clk) begin
        value_tmp = value1 + value2;
        op_tmp = op_input;
        rob_number_tmp = rob_number_input;
        ls_value_tmp = ls_value;
    end
    always@(negedge clk) begin
        if(!rst) begin
            ls_value_output <= ls_value_tmp;
            addr <= value_tmp;
            op <= op_tmp;
            rob_number <= rob_number_tmp;
        end
        else begin
            rob_number <= 3'b0;
        end
    end
endmodule

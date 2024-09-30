module regfile (
    input clk, resetn,
    input [4:0] rs1, rs2, rd, // register source 1, 2; register destination
    input reg_write,
    input [31:0] write_data,
    output [31:0] read_data1, read_data2,

    input wire [31:0] core_reg_file [0:31] // Huy debug
);
    integer i;
    reg [31:0] reg_file [0:31]; 

    // write data
    always @(posedge clk or negedge resetn)
    begin
        if(!resetn)
            for (i= 0; i<32; i = i+1)
                reg_file[i] <= 0;
        else if(reg_write & (rd != 0))
            reg_file[rd] <= write_data; 
    end 

    // read data
    assign read_data1 = reg_file[rs1]; // reg_file[0] hardwired to 0
    assign read_data2 = reg_file[rs2];

    assign core_reg_file = reg_file; // Huy debug

endmodule

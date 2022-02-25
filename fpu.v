module fpu (
    input clk,
    input rst,
    input start,
    input [31:0] input_a,
    input [31:0] input_b,
    input [1:0] opcode,

    output [31:0] output_z,
    output [2:0] error,
    output done
);

fpu_cu cu_dut(
    .clk(clk),
    .rst(rst),
    .start(start),
    .opcode(opcode),
    .add_done(add_done),
    .sub_done(sub_done), 
    .mul_done(mul_done),
    .div_done(div_done),
    .add(add),
    .sub(sub),
    .mul(mul),
    .div(div),
    .done(done)
);

fpu_dp dp_dut(
    .clk(clk),
    .rst(rst),
    .start(start),
    .input_a(input_a),
    .input_b(input_b),
    .add_done(add_done),
    .sub_done(sub_done), 
    .mul_done(mul_done),
    .div_done(div_done),
    .add(add),
    .sub(sub),
    .mul(mul),
    .div(div),
    .output_z(output_z),
    .error(error)
);
endmodule

// control unit
module fpu_cu(
    input clk,
    input rst,
    input start,
    input [1:0] opcode,

    input add_done,
    input sub_done, 
    input mul_done,
    input div_done,

    output reg add,
    output reg sub,
    output reg mul,
    output reg div,

    output reg done
);

    localparam  ADD_OP  = 2'b00,
                SUB_OP  = 2'b01,
                MUL_OP  = 2'b10,
                DIV_OP  = 2'b11;
    
    localparam  IDLE    = 3'b000,
                ADD     = 3'b001,
                SUB     = 3'b010,
                MUL     = 3'b011,
                DIV     = 3'b100;

    reg [2:0] state, next_state;

    always @ (posedge clk) begin 
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @( 
            start,
            state,
            opcode,
            add_done,
            sub_done,
            mul_done,
            div_done
            ) 
     begin
        add = 0; 
        sub = 0; 
        mul = 0; 
        div = 0; 
        done = 0;

        case (state) 
            IDLE: begin 
                if (start == 1) begin
                    if (opcode == 2'b00)
                        next_state = ADD;
                    else if (opcode == 2'b01)
                        next_state = SUB;
                    else if (opcode == 2'b10)
                        next_state = MUL;
                    else if (opcode == 2'b11)
                        next_state = DIV;
                end
                else 
                    next_state = IDLE;
                add = 0; sub = 0; mul = 0; div = 0; done = 1;
            end

            ADD: begin
                if (add_done == 1) begin
                    next_state = IDLE;
                end else begin
                    next_state = ADD;
                end
                add = 1; sub = 0; mul = 0; div = 0; done = 0;
            end

            SUB: begin
                if (sub_done == 1) begin
                    next_state = IDLE;
                end else begin
                    next_state = SUB;
                end
                add = 0; sub = 1; mul = 0; div = 0; done = 0;
            end

            MUL: begin
                if (mul_done == 1) begin
                    next_state = IDLE;
                end else begin
                    next_state = MUL;
                end
                add = 0; sub = 0; mul = 1; div = 0; done = 0;
            end

            DIV: begin
                if (div_done == 1) begin
                    next_state = IDLE;
                end else begin
                    next_state = DIV;
                end
                add = 0; sub = 0; mul = 0; div = 1; done = 0;
            end

            default : next_state = IDLE;
        endcase
    end

endmodule

// data path
module fpu_dp(
    input clk,
    input rst,
    input start,
    input [31:0] input_a,
    input [31:0] input_b,

    input add,
    input sub,
    input mul,
    input div,

    output reg add_done,
    output reg sub_done,
    output reg mul_done,
    output reg div_done,

    output reg [31:0] output_z,
    output reg [2:0] error
);
    reg [31:0] input_b_add;
    wire [31:0] output_z_add;
    wire [31:0] output_z_mul;
    wire [31:0] output_z_div;
    wire [2:0] error_add;
    wire [2:0] error_mul;    
    wire [2:0] error_div;
    wire done_add;
    wire done_mul;
    wire done_div;

    add add_dut(
        .start(start),
        .clk(clk),
        .rst(rst),
        .input_a(input_a),
        .input_b(input_b_add), 
        .output_z(output_z_add),
        .error(error_add),
        .done(done_add)
    );

    mul mul_dut(
        .start(start),
        .clk(clk),
        .rst(rst),
        .input_a(input_a),
        .input_b(input_b), 
        .output_z(output_z_mul),
        .error(error_mul),
        .done(done_mul)
    );

    div div_dut(
        .start(start),
        .clk(clk),
        .rst(rst),
        .input_a(input_a),
        .input_b(input_b), 
        .output_z(output_z_div),
        .error(error_div),
        .done(done_div)
    );

    always @ (posedge clk) begin  
        if (rst) begin
            add_done <= 0;
            sub_done <= 0;
            mul_done <= 0;
            div_done <= 0;
        end else if (add == 1) begin
            input_b_add = input_b;
            output_z = output_z_add;
            error = error_add;
            if (done_add == 1)
            begin
                add_done <= 1;
            end
        end else if (sub == 1) begin
            input_b_add = {~input_b[31], input_b[30:0]};
            output_z = output_z_add;
            error = error_add;
            if (done_add == 1)
            begin
                sub_done <= 1;
            end
        end else if (mul == 1) begin
            output_z = output_z_mul;
            error = error_mul;
            if (done_mul == 1)
            begin
                mul_done <= 1;
            end
        end else if (div == 1) begin
            output_z = output_z_div;
            error = error_div;
            if (done_div == 1)
            begin
                div_done <= 1;
            end
        end
    end
endmodule

// module fpu_tb();
    // reg clk;
    // reg rst;
    // reg start;
    // reg [31:0] input_a;
    // reg [31:0] input_b;
    // reg [1:0] opcode;

    // wire [31:0] output_z;
    // wire [2:0] error;
    // wire done;

    // fpu fpu_dut(
    //     .clk(clk),
    //     .rst(rst),
    //     .start(start),
    //     .input_a(input_a),
    //     .input_b(input_b),
    //     .opcode(opcode),
    //     .output_z(output_z),
    //     .error(error),
    //     .done(done)
    // );

    // initial begin
    //     clk = 1;
    //     forever #5 clk = ~clk;
    // end

    // initial begin
    //     $monitor("%t: a = %b, b = %b, z = %b, error = %b", $time, input_a, input_b, output_z, error);
    // end

    // initial begin
    //     rst = 1;
    //     #15
    //     rst = 0;
    //     #15
    //     start = 1;
    //     input_a = 32'b11000001001010000000000000000000; // 10.5
    //     input_b = 32'b01000000001000000000000000000000; // 3.5
    //     opcode = 2'b10;
    //     #10
    //     start = 0;
    // end
// endmodule
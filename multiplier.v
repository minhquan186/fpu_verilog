module mul (
    input clk,
    input rst,
    input start,
    input [31:0] input_a,
    input [31:0] input_b,

    output [31:0]   output_z,
    output [2:0]    error,
    output          done
);
    wire    got_input, 
            special, 
            normal, 
            normed_a, 
            normed_b, 
            normed_z_1, 
            normed_z_2, 
            rounded, 
            normalize_z_1, 
            normalize_z_2,
            packed_z,
            got_output;

mul_cu cu_dut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .got_output(got_output),
    .special(special),
    .normal(normal),
    .normed_a(normed_a),
    .normed_b(normed_b),
    .rounded(rounded),
    .normed_z_1(normed_z_1),
    .normed_z_2(normed_z_2),

    .packed_z(packed_z),
    .proc_input(proc_input),
    .got_input(got_input),
    .check_specials(check_specials),
    .normalize_a(normalize_a),
    .normalize_b(normalize_b),
    .normalize_z_1(normalize_z_1),
    .normalize_z_2(normalize_z_2),
    .multiply_0(multiply_0),
    .multiply_1(multiply_1),
    .round(round),
    .pack(pack),
    .put_z(put_z),
    .done(done)
);

mul_dp dp_dut (
    .clk(clk),
    .rst(rst),
    .input_a(input_a),
    .input_b(input_b),
    .proc_input(proc_input),
    .check_specials(check_specials),
    .normalize_a(normalize_a),
    .normalize_b(normalize_b),
    .normalize_z_1(normalize_z_1),
    .normalize_z_2(normalize_z_2),
    .multiply_0(multiply_0),
    .multiply_1(multiply_1),
    .round(round),
    .pack(pack),
    .put_z(put_z),
    
    .got_input(got_input),
    .special(special),
    .normal(normal),
    .normed_a(normed_a),
    .normed_b(normed_b),
    .got_output(got_output),
    .normed_z_1(normed_z_1),
    .normed_z_2(normed_z_2),
    .rounded(rounded),
    .packed_z(packed_z),
    .output_z(output_z),
    .error(error)
);
endmodule

module mul_cu(
    input clk,
    input rst,

    input start,

    input got_input,
    input special,
    input normal,
    input normed_a,
    input normed_b,
    input normed_z_1,
    input normed_z_2,
    input rounded,
    input packed_z,
    input got_output,

    output reg proc_input,
    output reg check_specials,
    output reg normalize_a,
    output reg normalize_b,
    output reg normalize_z_1,
    output reg normalize_z_2,
    output reg multiply_0,
    output reg multiply_1,
    output reg round,
    output reg pack,
    output reg put_z,
    output reg done
);

    localparam  IDLE          = 4'd0,
                GET_INPUT     = 4'd1,
                SPECIAL_CASES = 4'd2,
                NORMALIZE_A   = 4'd3,
                NORMALIZE_B   = 4'd4,
                MULTIPLY_0    = 4'd5,
                MULTIPLY_1    = 4'd6,
                NORMALIZE_1   = 4'd7,
                NORMALIZE_2   = 4'd8,
                ROUND         = 4'd9,
                PACK          = 4'd10,
                PUT_Z         = 4'd11,
                NOTHING       = 4'd12;

    reg [3:0] state, next_state;

    always @(posedge clk) begin 
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(   state,
                start,  
                special,
                normal, 
                normed_a, 
                normed_b, 
                normed_z_1, 
                normed_z_2,
                got_input,
                rounded,
                packed_z,
                got_output) 
    begin
        proc_input      = 0;
        check_specials  = 0;
        normalize_a     = 0;
        normalize_b     = 0;
        multiply_0      = 0;
        multiply_1      = 0;
        normalize_z_1   = 0;
        normalize_z_2   = 0;
        round           = 0;
        pack            = 0;
        put_z           = 0;

        case(state)
            IDLE: begin
                if (start) begin
                    done = 0;
                    next_state = GET_INPUT;
                end else begin
                    next_state = IDLE;
                end   
            end

            GET_INPUT: begin 
                proc_input = 1;
                if (got_input) begin
                    next_state = SPECIAL_CASES;
                end else begin
                    next_state = GET_INPUT;
                end          
            end

            SPECIAL_CASES: begin
                check_specials = 1;
                if (special) begin
                    next_state = PUT_Z;
                end else if (normal) begin
                    next_state = NORMALIZE_A;
                end else 
                    next_state = SPECIAL_CASES;
            end

            NORMALIZE_A: begin
                normalize_a = 1;
                if (normed_a) begin
                    next_state = NORMALIZE_B;
                end else begin
                    next_state = NORMALIZE_A;
                end
            end

            NORMALIZE_B: begin
                normalize_b = 1;
                if (normed_b) begin
                    next_state = MULTIPLY_0;
                end else begin
                    next_state = NORMALIZE_B;
                end
            end

            MULTIPLY_0: begin
                multiply_0 = 1;
                next_state = MULTIPLY_1;
            end

            MULTIPLY_1: begin
                multiply_1 = 1;
                next_state = NORMALIZE_1;
            end

            NORMALIZE_1: begin
                normalize_z_1 = 1; 
                if (normed_z_1) begin
                    next_state  = NORMALIZE_2;
                end else begin
                    next_state = NORMALIZE_1;
                end
            end

            NORMALIZE_2: begin
                normalize_z_2 = 1;
                if (normed_z_2) begin
                    next_state = ROUND;
                end else begin
                    next_state = NORMALIZE_2;
                end
            end

            ROUND: begin
                round = 1;
                if (rounded) begin
                    next_state = PACK;
                end else begin
                    next_state = ROUND;
                end
            end

            PACK: begin
                pack = 1;
                if (packed_z) begin
                    next_state = PUT_Z;
                end else begin
                    next_state = PACK;
                end
            end

            PUT_Z: begin
                put_z = 1;
                if (got_output) begin
                    next_state = NOTHING;
                    done = 1;
                end else begin
                    next_state = PUT_Z;
                end
            end

            NOTHING: begin
                next_state = NOTHING;
            end
            
            default : next_state = NOTHING;
        endcase
    end
endmodule

module mul_dp(
        input clk,
        input rst,
        input [31:0] input_a,
        input [31:0] input_b,

        input proc_input,
        input check_specials,
        input normalize_a,
        input normalize_b,
        input normalize_z_1,
        input normalize_z_2,
        input multiply_0,
        input multiply_1,
        input round,
        input pack,
        input put_z,

        output reg got_input,
        output reg special,
        output reg normal,
        output reg normed_a,
        output reg normed_b,
        output reg normed_z_1,
        output reg normed_z_2,
        output reg rounded,
        output reg packed_z,
        output reg got_output,

        output reg [31:0] output_z,
        output reg [2:0]  error
);

    localparam  NoError     = 3'b000,
                NaN         = 3'b001,
                Overflow    = 3'b010,
                Underflow   = 3'b011,
                DivideBy0   = 3'b100;

    reg  [31:0] z;
    reg  [23:0] a_m, b_m, z_m;
    reg  [9:0] a_e, b_e, z_e;
    reg  a_s, b_s, z_s;
    reg  guard, round_bit, sticky; 
    reg  [47:0] product;
    reg  [9:0] z_e_buffer;

    always @(posedge clk) begin 
        if (rst) begin
            output_z        <= 0;
            got_output      <= 0;
            got_input       <= 0;
            special         <= 0;
            normal          <= 0;
            normed_a        <= 0;
            normed_b        <= 0;
            normed_z_1      <= 0;
            normed_z_2      <= 0;
            rounded         <= 0;
            packed_z        <= 0;
            z_e_buffer      <= 0;
            error           <= NoError;

            z  <= 0;

            a_m<= 0; 
            b_m<= 0; 
            z_m<= 0;

            a_e<= 0; 
            b_e<= 0; 
            z_e<= 0;

            a_s<= 0; 
            b_s<= 0; 
            z_s<= 0;

            guard       <= 0; 
            round_bit   <= 0; 
            sticky      <= 0; 
            product     <= 0;

        end else if (proc_input) begin
            a_m <= input_a[22 : 0];
            b_m <= input_b[22 : 0];
            a_e <= input_a[30 : 23] - 127;
            b_e <= input_b[30 : 23] - 127;
            a_s <= input_a[31];
            b_s <= input_b[31];
            got_input <= 1;
            
        end else if (check_specials) begin
            // NaN
            if ((a_e == 128 && a_m != 0) || (b_e == 128 && b_m != 0)) begin
                z[31] <= 1;
                z[30:23] <= 255;
                z[22] <= 1;
                z[21:0] <= 0;
                error <= NaN;
                special <= 1;
            //if a is inf return inf
            end else if (a_e == 128) begin
                //if b is zero return NaN
                if (($signed(b_e) == -127) && (b_m == 0)) begin
                    z[31] <= 1;
                    z[30:23] <= 255;
                    z[22] <= 1;
                    z[21:0] <= 0;
                    special <= 1;
                    error <= NaN;
                end
                else begin 
                    z[31]       <= a_s ^ b_s;
                    z[30:23]    <= 255;
                    z[22:0]     <= 0;
                    special     <= 1;
                    error       <= Overflow;    
                end
            //if b is inf return inf
            end else if (b_e == 128) begin
                //if a is zero return NaN
                if (($signed(a_e) == -127) && (a_m == 0)) begin
                    z[31] <= 1;
                    z[30:23] <= 255;
                    z[22] <= 1;
                    z[21:0] <= 0;
                    special <= 1;
                    error <= NaN;
                end
                else begin
                    z[31]       <= a_s ^ b_s;
                    z[30:23]    <= 255;
                    z[22:0]     <= 0;
                    special     <= 1;
                    error       <= Overflow;
                end
            //if a is zero return zero
            end else if (($signed(a_e) == -127) && (a_m == 0)) begin
                z[31]       <= a_s ^ b_s;
                z[30:23]    <= 0;
                z[22:0]     <= 0;
                special     <= 1;
            //if b is zero return zero
            end else if (($signed(b_e) == -127) && (b_m == 0)) begin
                z[31] <= a_s ^ b_s;
                z[30:23] <= 0;
                z[22:0] <= 0;
                special <= 1;
            end else begin
            //Denormalised Number
                normal <= 1;
                if ($signed(a_e) == -127) begin
                    a_e <= -126;
                end else begin
                    a_m[23] <= 1;
                end
                //Denormalised Number
                if ($signed(b_e) == -127) begin
                    b_e <= -126;
                end else begin
                    b_m[23] <= 1;
                end
            end
        end else if (normalize_a) begin
            if (a_m[23]) begin
            normed_a <= 1;
            end else begin
            a_m <= a_m << 1;  
            a_e <= a_e - 1;   
            end
        end else if (normalize_b) begin
            if (b_m[23]) begin
            normed_b <= 1;
            end else begin
            b_m <= b_m << 1;  
            b_e <= b_e - 1;   
            end
        end else if (multiply_0) begin
            z_s     <= a_s ^ b_s;
            z_e     <= a_e + b_e + 1;   // theo cong thuc
            product <= a_m * b_m;
        end else if (multiply_1) begin
            z_m         <= product  [47:24];  // 24 bits
            guard       <= product  [23];
            round_bit   <= product  [22];
            sticky      <= (product[21:0] != 0);
        end else if (normalize_z_1) begin
            if (z_m[23] == 0) begin
                z_e <= z_e - 1;
                z_m <= z_m << 1;
                z_m[0] <= guard;
                guard <= round_bit;
                round_bit <= 0;           
            end else begin
                normed_z_1 <= 1;
            end
        end else if (normalize_z_2) begin
            if ($signed(z_e) < -126) begin    
                z_e_buffer <= -126 - $signed(z_e);
                z_e     <= z_e +  z_e_buffer;
                z_m     <= z_m >> z_e_buffer;   
                guard   <= z_m[0];   
                round_bit <= guard;  
                sticky <= sticky | round_bit;  
            end else begin
                normed_z_2 <= 1;
            end
        end else if (round) begin
            if (guard && (round_bit | sticky | z_m[0])) begin   
                guard <=  z_m[0];   
                round_bit <= guard; 
                sticky <= sticky | round_bit; 
                z_m <= z_m + 1;
                if (z_m == 24'hffffff) begin
                    z_e <= z_e + 1;
                end
            end else begin
                rounded <= 1; 
            end
        end else if (pack) begin
            z[22 : 0] <= z_m[22:0];
            z[30 : 23] <= z_e[7:0] + 127;
            z[31] <= z_s;
            if ($signed(z_e) == -126 && z_m[23] == 0) begin
                z[30 : 23] <= 0;
                packed_z <= 1;
            end
            //if overflow occurs, return inf
            else if ($signed(z_e) > 127) begin
                z[22 : 0] <= 0;
                z[30 : 23] <= 255;
                z[31] <= z_s;
                error <= 3'b01;
                packed_z <= 1;
            end
            else begin
                packed_z <= 1;
            end
        end else if (put_z) begin
            got_output <= 1;
            output_z <= z;
        end else begin
            // got_output <= 1;
            output_z <= output_z;
        end
    end
endmodule

module mul_tb();
    reg clk;
    reg rst;
    reg start;
    reg [31:0] input_a;
    reg [31:0] input_b;
    
    wire [31:0] output_z;
    wire [2:0] error;
    wire done;

    mul dut(
        .clk(clk),
        .rst(rst),
        .start(start),
        .input_a(input_a),
        .input_b(input_b),
        .output_z(output_z),
        .error(error),
        .done(done)
    );

    initial begin
        clk = 1;
        forever #5 clk = ~clk;
    end

    initial begin
        $monitor("%t: a = %b, b = %b, z = %b, error = %b", $time, input_a, input_b, output_z, error);
    end

    initial begin
        rst = 1;
        #15
        rst = 0;
        #15
        start = 1;
        input_a = 32'b11000001001010000000000000000000;  
        input_b = 32'b01000000001000000000000000000000; 
    end
endmodule

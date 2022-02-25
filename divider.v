module div(
    input clk,
    input rst,
    input start,
    input [31:0] input_a,
    input [31:0] input_b,

    output [31:0] output_z,
    output [2:0] error,
    output done
);
    wire    got_input, 
            special, 
            normal, 
            normed_a, 
            normed_b, 
            divided_1,
            divided_2,
            normed_z_1, 
            normed_z_2, 
            rounded, 
            normalize_z_1, 
            normalize_z_2,
            packed_z,
            got_output;
        
div_cu cu_dut(
    .clk(clk), 
    .rst(rst),
    .start(start),

    .got_input(got_input),
    .special(special),
    .normal(normal),
    .normed_a(normed_a),
    .normed_b(normed_b),
    .divided_1(divided_1),
    .divided_2(divided_2),
    .normed_z_1(normed_z_1),
    .normed_z_2(normed_z_2),
    .rounded(rounded),
    .packed_z(packed_z),
    .got_output(got_output),

    .proc_input(proc_input),
    .check_specials(check_specials),
    .normalize_a(normalize_a),
    .normalize_b(normalize_b),
    .divide_0(divide_0),
    .divide_1(divide_1),
    .divide_2(divide_2),
    .divide_3(divide_3),
    .normalize_z_1(normalize_z_1),
    .normalize_z_2(normalize_z_2),
    .round(round),
    .pack(pack), 
    .put_z(put_z),
    .done(done)
);

div_dp dp_dut(
    .clk(clk), 
    .rst(rst),
    .input_a(input_a),
    .input_b(input_b),

    .proc_input(proc_input),
    .check_specials(check_specials),
    .normalize_a(normalize_a),
    .normalize_b(normalize_b),
    .divide_0(divide_0),
    .divide_1(divide_1),
    .divide_2(divide_2),
    .divide_3(divide_3),
    .normalize_z_1(normalize_z_1),
    .normalize_z_2(normalize_z_2),
    .round(round),
    .pack(pack), 
    .put_z(put_z),

    .got_input(got_input),
    .special(special),
    .normal(normal),
    .normed_a(normed_a),
    .normed_b(normed_b),
    .divided_1(divided_1),
    .divided_2(divided_2),
    .normed_z_1(normed_z_1),
    .normed_z_2(normed_z_2),
    .rounded(rounded),
    .packed_z(packed_z),
    .got_output(got_output),

    .output_z(output_z),
    .error(error)
);
endmodule

// control unit
module div_cu(
    input clk, 
    input rst,
    input start,

    input got_input,
    input special,
    input normal,
    input normed_a,
    input normed_b,
    input divided_1,
    input divided_2,
    input normed_z_1,
    input normed_z_2,
    input rounded,
    input packed_z,
    input got_output,

    output reg proc_input,
    output reg check_specials,
    output reg normalize_a,
    output reg normalize_b,
    output reg divide_0,
    output reg divide_1,
    output reg divide_2,
    output reg divide_3,
    output reg normalize_z_1,
    output reg normalize_z_2,
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
                DIVIDE_0      = 4'd5,
                DIVIDE_1      = 4'd6,
                DIVIDE_2      = 4'd7,
                DIVIDE_3      = 4'd8,
                NORMALIZE_1   = 4'd9,
                NORMALIZE_2   = 4'd10,
                ROUND         = 4'd11,
                PACK          = 4'd12,
                PUT_Z         = 4'd13,
                NOTHING       = 4'd14;
    
    reg [3:0] state, next_state;

    always @ (posedge clk) begin : proc_state
        if (rst) begin
            state <= 0;
        end else begin
            state <= next_state;
        end
    end

    always @ (  state,
                start,
                got_input, 
                special, 
                normal,
                normed_a,
                normed_b,
                divided_1,
                divided_2,
                normed_z_1,
                normed_z_2,
                rounded,
                packed_z,
                got_output)
    begin  
        proc_input      = 0;
        check_specials  = 0;
        normalize_a     = 0;
        normalize_b     = 0;
        divide_0        = 0;
        divide_1        = 0;
        divide_2        = 0;
        divide_3        = 0;
        normalize_z_1   = 0;
        normalize_z_2   = 0;
        round           = 0;
        pack            = 0;
        put_z           = 0;
    
        case (state)
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
                end else begin
                    next_state = SPECIAL_CASES;
                end
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
                    next_state = DIVIDE_0;
                end else begin
                    next_state = NORMALIZE_B;
                end
            end

            DIVIDE_0: begin
                divide_0 = 1;
                next_state = DIVIDE_1;
            end

            DIVIDE_1: begin
                divide_1 = 1;
                next_state = DIVIDE_2;
            end

            DIVIDE_2: begin
                divide_2 = 1;
                if (divided_1) begin
                    next_state = DIVIDE_3;
                end else if (divided_2) begin
                    next_state = DIVIDE_1;
                end else begin
                    next_state = DIVIDE_2;
                end
            end

            DIVIDE_3: begin
                divide_3 = 1;
                next_state = NORMALIZE_1;
            end

            NORMALIZE_1: begin
                normalize_z_1 = 1;
                if (normed_z_1) begin
                    next_state = NORMALIZE_2;
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

            default: 
                next_state = NOTHING;
        endcase
    end
endmodule

// datapath
module div_dp(
    input clk,
    input rst,
    input [31:0] input_a,
    input [31:0] input_b,

    input proc_input,
    input check_specials,
    input normalize_a,
    input normalize_b,
    input divide_0,
    input divide_1,
    input divide_2,
    input divide_3,
    input normalize_z_1,
    input normalize_z_2,
    input round,
    input pack, 
    input put_z,

    output reg got_input,
    output reg special,
    output reg normal,
    output reg normed_a,
    output reg normed_b,
    output reg divided_1,
    output reg divided_2,
    output reg normed_z_1,
    output reg normed_z_2,
    output reg rounded,
    output reg packed_z,
    output reg got_output,

    output reg [31:0] output_z,
    output reg [3:0] error
); 
    
    reg [31:0] z;
    reg [23:0] a_m, b_m, z_m;
    reg [9:0] a_e, b_e , z_e;
    reg a_s, b_s, z_s;
    reg guard, round_bit, sticky;
    reg [50:0] quotient, divisor, dividend, remainder;
    reg [5:0] count;

    localparam  CORRECT     = 3'b000,
                NAN         = 3'b001,
                OVERFLOW    = 3'b010,
                UNDERFLOW   = 3'b011,
                DIVIDE_ZERO = 3'b100;

    always @ (posedge clk) begin
        if (rst) begin
            got_input   <= 0;
            special     <= 0;
            normal      <= 0;
            normed_a    <= 0;
            normed_b    <= 0;
            divided_1   <= 0;
            divided_2   <= 0;
            normed_z_1  <= 0;
            normed_z_2  <= 0;
            rounded     <= 0;
            packed_z    <= 0;
            output_z    <= 0;
            error       <= 0;

            z           <= 0;
            a_m         <= 0; 
            b_m         <= 0; 
            z_m         <= 0;
            a_e         <= 0; 
            b_e         <= 0; 
            z_e         <= 0;
            a_s         <= 0; 
            b_s         <= 0; 
            z_s         <= 0;

            guard       <= 0; 
            round_bit   <= 0; 
            sticky      <= 0; 
            quotient    <= 0; 
            divisor     <= 0;
            dividend    <= 0;
            remainder   <= 0;
            count       <= 0;
        end else if (proc_input) begin
            a_m <= input_a[22 : 0];
            b_m <= input_b[22 : 0];
            a_e <= input_a[30 : 23] - 127;
            b_e <= input_b[30 : 23] - 127;
            a_s <= input_a[31];
            b_s <= input_b[31];
            got_input <= 1; 
        end else if (check_specials) begin
            //if a is NaN or b is NaN return NaN 
            if ((a_e == 128 && a_m != 0) || (b_e == 128 && b_m != 0)) begin
                z[31] <= 1;
                z[30:23] <= 255;
                z[22] <= 1;
                z[21:0] <= 0;
                error <= 3'b001;
                special <= 1;
            //if a is inf and b is inf return NaN 
            end else if ((a_e == 128) && (b_e == 128)) begin
                z[31] <= 1;
                z[30:23] <= 255;
                z[22] <= 1;
                z[21:0] <= 0;
                error <= 3'b001;
                special <= 1;
            //if a is inf return inf
            end else if (a_e == 128) begin
                //if b is zero return NaN
                if ($signed(b_e == -127) && (b_m == 0)) begin
                    z[31] <= 1;
                    z[30:23] <= 255;
                    z[22] <= 1;
                    z[21:0] <= 0;
                    error <= 3'b001;
                    special <= 1;
                end else begin
                    z[31] <= a_s ^ b_s;
                    z[30:23] <= 255;
                    z[22:0] <= 0;
                    error <= 3'b010;
                    special <= 1;
                end   
            //if b is inf return zero
            end else if (b_e == 128) begin
                z[31] <= a_s ^ b_s;
                z[30:23] <= 0;
                z[22:0] <= 0;
                special <= 1;
            //if a is zero return zero
            end else if (($signed(a_e) == -127) && (a_m == 0)) begin
                //if b is zero return NaN
                if (($signed(b_e) == -127) && (b_m == 0)) begin
                    z[31] <= 1;
                    z[30:23] <= 255;
                    z[22] <= 1;
                    z[21:0] <= 0;
                    error <= 3'b001;
                    special <= 1;
                // if b is inf return NaN
                end else if (b_e == 128) begin
                    z[31] <= 1;
                    z[30:23] <= 255;
                    z[22] <= 1;
                    z[21:0] <= 0;
                    error <= 3'b001;
                    special <= 1;
                end else begin
                    z[31] <= a_s ^ b_s;
                    z[30:23] <= 0;
                    z[22:0] <= 0;
                    special <= 1;
                end
            //if b is zero return inf
            end else if (($signed(b_e) == -127) && (b_m == 0)) begin
                z[31] <= a_s ^ b_s;
                z[30:23] <= 255;
                z[22:0] <= 0;
                error <= 3'b100;
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
        end else if (divide_0) begin
            z_s <= a_s ^ b_s;
            z_e <= a_e - b_e;
            quotient <= 0;
            remainder <= 0;
            count <= 0;
            dividend <= a_m << 27;
            divisor <= b_m;
        end else if (divide_1) begin
            quotient <= quotient << 1;
            remainder <= remainder << 1;
            remainder[0] <= dividend[50];
            dividend <= dividend << 1;
        end else if (divide_2) begin
            if (remainder >= divisor) begin
                quotient[0] <= 1;
                remainder <= remainder - divisor;
            end
            if (count == 49) begin
                divided_1 <= 1;
            end else begin
                count <= count + 1;
                divided_2 <= 1;
            end
        end else if (divide_3) begin
            z_m <= quotient[26:3];
            guard <= quotient[2];
            round_bit <= quotient[1];
            sticky <= quotient[0] | (remainder != 0);
        end else if (normalize_z_1) begin
            if (z_m[23] == 0 && $signed(z_e) > -126) begin
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
                z_e <= z_e + 1;
                z_m <= z_m >> 1;
                guard <= z_m[0];
                round_bit <= guard;
                sticky <= sticky | round_bit;
            end else begin
                normed_z_2 <= 1;
            end
        end else if (round) begin
            if (guard && (round_bit | sticky | z_m[0])) begin
                guard <= z_m[0];
                round_bit <= guard;
                sticky <= sticky | round_bit;
                z_m <= z_m + 1;
                if (z_m == 24'hffffff) begin
                    z_e = z_e + 1;
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
            end
            if ($signed(z_e) > 127) begin
                z[22 : 0] <= 0;
                z[30 : 23] <= 255;
                z[31] <= z_s;
                error <= 3'b010;
            end begin
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

module div_tb ();
    reg clk;
    reg rst;
    reg start;
    reg [31:0] input_a;
    reg [31:0] input_b;
    
    wire [31:0] output_z;
    wire [2:0] error;
    wire done;

    div dut(
        .start(start),
        .input_a(input_a),
        .input_b(input_b),
        .clk(clk),
        .rst(rst),
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
        input_a = 32'b01000001001010000000000000000000;  
        input_b = 32'b01000000011000000000000000000000; 
    end

endmodule


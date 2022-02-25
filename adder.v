module add(
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
            aligned,
            normed_z_1,
            normed_z_2,
            rounded,
            packed_z,
            got_output;

add_cu cu_dut(
    .clk(clk),
    .rst(rst),
    .start(start),

    .got_input(got_input),
    .special(special),
    .normal(normal),
    .aligned(aligned),
    .normed_z_1(normed_z_1),
    .normed_z_2(normed_z_2),
    .rounded(rounded),
    .packed_z(packed_z),
    .got_output(got_output),

    .proc_input(proc_input),
    .check_specials(check_specials),
    .align(align),
    .add_0(add_0),
    .add_1(add_1),
    .normalize_z_1(normalize_z_1),
    .normalize_z_2(normalize_z_2),
    .round(round),
    .pack(pack),
    .put_z(put_z),

    .done(done)
);

add_dp dp_dut(
    .clk(clk),
    .rst(rst),
    .input_a(input_a),
    .input_b(input_b),

    .proc_input(proc_input),
    .check_specials(check_specials),
    .align(align),
    .add_0(add_0),
    .add_1(add_1),
    .normalize_z_1(normalize_z_1),
    .normalize_z_2(normalize_z_2),
    .round(round),
    .pack(pack),
    .put_z(put_z),

    .got_input(got_input),
    .special(special),
    .normal(normal),
    .aligned(aligned),
    .normed_z_1(normed_z_1),
    .normed_z_2(normed_z_2),
    .rounded(rounded),
    .packed_z(packed_z),
    .got_output(got_output),

    .output_z(output_z),
    .error(error)
);

endmodule

module add_cu(
    input clk,
    input rst,
    input start,

    input got_input,
    input special,
    input normal,
    input aligned,
    input normed_z_1,
    input normed_z_2,
    input rounded,
    input packed_z,
    input got_output,

    output reg proc_input,
    output reg check_specials,
    output reg align,
    output reg add_0,
    output reg add_1,
    output reg normalize_z_1,
    output reg normalize_z_2,
    output reg round,
    output reg pack,
    output reg put_z,

    output reg done
);
// Encode State
localparam  IDLE          = 4'd0,
            GET_INPUT     = 4'd1,
            SPECIAL_CASES = 4'd2,
            ALIGN         = 4'd3,
            ADD_0         = 4'd4,
            ADD_1         = 4'd5,
            NORMALIZE_Z_1 = 4'd6,
            NORMALIZE_Z_2 = 4'd7,
            ROUND         = 4'd8,
            PACK          = 4'd9,
            PUT_Z         = 4'd10,
            NOTHING       = 4'd11;

reg [3:0] state, next_state;

always @(posedge clk) begin : proc_state
    if(rst)
    begin
        state <= 0;
    end
    else
    begin
        state <= next_state;
    end
end

always @(
        state,
        start,
        got_input,
        special,
        normal,
        aligned,
        normed_z_1,
        normed_z_2,
        rounded,
        packed_z,
        got_output
        )
begin

    proc_input      = 0;
    check_specials  = 0;
    align           = 0;
    add_0           = 0;
    add_1           = 0;
    normalize_z_1   = 0;
    normalize_z_2   = 0;
    round           = 0;
    pack            = 0;
    put_z           = 0;


    case(state)

    IDLE:
    begin
        if (start)
        begin
            done = 0;
            next_state = GET_INPUT;
        end
        else
        begin
            next_state = IDLE;
        end
    end


    GET_INPUT:
    begin
        proc_input = 1;
        if (got_input)
        begin
            next_state = SPECIAL_CASES;
        end
        else
        begin
            next_state = GET_INPUT;
        end
    end

    SPECIAL_CASES:
    begin
        check_specials = 1;
        if (special)
            next_state = PUT_Z;
        else if (normal)
            next_state = ALIGN;
        else
            next_state = SPECIAL_CASES;
    end

    ALIGN:
    begin
        align = 1;
        if (aligned)
        begin
            next_state = ADD_0;
        end
        else
        begin
            next_state = ALIGN;
        end
    end

    ADD_0:
    begin
        add_0 = 1;
        next_state = ADD_1;
    end

    ADD_1:
    begin
        add_1 = 1;
        next_state = NORMALIZE_Z_1;
    end

    NORMALIZE_Z_1:
    begin
        normalize_z_1 = 1;
        if (normed_z_1)
        begin
            next_state = NORMALIZE_Z_2;
        end
        else
        begin
            next_state = NORMALIZE_Z_1;
        end
    end

    NORMALIZE_Z_2:
    begin
        normalize_z_2 = 1;
        if (normed_z_2)
        begin
            next_state = ROUND;
        end
        else
        begin
            next_state = NORMALIZE_Z_2;
        end
    end

    ROUND:
    begin
        round = 1;
        if (rounded)
        begin
            next_state = PACK;
        end
        else
        begin
            next_state = ROUND;
        end
    end

    PACK:
    begin
        pack = 1;
        if (packed_z)
        begin
            next_state = PUT_Z;
        end
        else
        begin
            next_state = PACK;
        end
    end

    PUT_Z:
    begin
        put_z = 1;
        if (got_output)
        begin
            next_state = NOTHING;
            done = 1;
        end
        else
        begin
            next_state = PUT_Z;
        end
    end

    NOTHING:
    begin
        next_state = NOTHING;
    end

    default:
        next_state = NOTHING;

    endcase

end

endmodule

module add_dp(
    input clk,
    input rst,
    input [31:0] input_a,
    input [31:0] input_b,


    input proc_input,
    input check_specials,
    input align,
    input add_0,
    input add_1,
    input normalize_z_1,
    input normalize_z_2,
    input round,
    input pack,
    input put_z,

    output reg got_input,
    output reg special,
    output reg normal,
    output reg aligned,
    output reg normed_z_1,
    output reg normed_z_2,
    output reg rounded,
    output reg packed_z,
    output reg got_output,

    output reg [31:0] output_z,
    output reg [2:0] error
);

// Encode Error
localparam  NO_ERROR    = 3'b000,
            NAN         = 3'b001,
            OVERFLOW    = 3'b010,
            UNDERFLOW   = 3'b011,
            DIVIDE_BY_0 = 3'b100;

    reg       [31:0] z;
    reg       [26:0] a_m, b_m;
    reg       [23:0] z_m;
    reg       [9:0] a_e, b_e, z_e;
    reg       a_s, b_s, z_s;
    reg       guard, round_bit, sticky;
    reg       [27:0] sum;

always @(posedge clk) begin : proc_cnt
    if(rst)
    begin
        output_z    <= 0;
        got_input   <= 0;
        special     <= 0;
        normal      <= 0;
        aligned     <= 0;
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
        sum         <= 0;
    end

    else if (proc_input)
    begin
        a_m <= {input_a[22 : 0], 3'd0};
        b_m <= {input_b[22 : 0], 3'd0};
        a_e <= input_a[30 : 23] - 127;
        b_e <= input_b[30 : 23] - 127;
        a_s <= input_a[31];
        b_s <= input_b[31];
        got_input <= 1;
    end

    else if (check_specials)
    begin
        //if a is NaN or b is NaN return NaN
        if ((a_e == 128 && a_m != 0) || (b_e == 128 && b_m != 0))
        begin
            z[31] <= 1;
            z[30:23] <= 255;
            z[22] <= 1;
            z[21:0] <= 0;
            special <= 1;
            error <= NAN;
        end
        // if a is inf
        else if (a_e == 128)
        begin
            //if a is inf and signs don't match return nan
            if ((b_e == 128) && (a_s != b_s))
            begin
                z[31] <= b_s;
                z[30:23] <= 255;
                z[22] <= 1;
                z[21:0] <= 0;
                special <= 1;
                error <= NAN;
            end
            //if a is inf return inf
            else
            begin
                z[31] <= a_s;
                z[30:23] <= 255;
                z[22:0] <= 0;
                special <= 1;
                error <= OVERFLOW;
            end
        end
        //if b is inf return inf
        else if (b_e == 128)
        begin
            z[31] <= b_s;
            z[30:23] <= 255;
            z[22:0] <= 0;
            special <= 1;
            error <= OVERFLOW;
        end
        //if a is zero return b
        else if ((($signed(a_e) == -127) && (a_m == 0)) && (($signed(b_e) == -127) && (b_m == 0)))
        begin
            z[31] <= a_s & b_s;
            z[30:23] <= b_e[7:0] + 127;
            z[22:0] <= b_m[26:3];
            special <= 1;
            error <= NO_ERROR;
        end
        //if a is zero return b
        else if (($signed(a_e) == -127) && (a_m == 0))
        begin
            z[31] <= b_s;
            z[30:23] <= b_e[7:0] + 127;
            z[22:0] <= b_m[26:3];
            special <= 1;
            error <= NO_ERROR;
        end
        //if b is zero return a
        else if (($signed(b_e) == -127) && (b_m == 0))
        begin
            z[31] <= a_s;
            z[30:23] <= a_e[7:0] + 127;
            z[22:0] <= a_m[26:3];
            special <= 1;
            error <= NO_ERROR;
        end
        else
        begin
            normal <= 1;
            //Denormalised Number
            if ($signed(a_e) == -127)
            begin
                a_e <= -126;
            end
            else
            begin
                a_m[26] <= 1;
            end
            //Denormalised Number
            if ($signed(b_e) == -127)
            begin
                b_e <= -126;
            end
            else
            begin
                b_m[26] <= 1;
            end
        end
    end

    else if (align)
    begin
        if ($signed(a_e) > $signed(b_e))
        begin
            b_e <= b_e + 1;
            b_m <= b_m >> 1;
            b_m[0] <= b_m[0] | b_m[1];
        end
        else if ($signed(a_e) < $signed(b_e))
        begin
            a_e <= a_e + 1;
            a_m <= a_m >> 1;
            a_m[0] <= a_m[0] | a_m[1];
        end
        else
        begin
            aligned <= 1;
        end
    end

    else if (add_0)
    begin
        z_e <= a_e;
        if (a_s == b_s)
        begin
            sum <= a_m + b_m;
            z_s <= a_s;
        end
        else
        begin
            if (a_m >= b_m)
            begin
                sum <= a_m - b_m;
                z_s <= a_s;
            end
            else
            begin
                sum <= b_m - a_m;
                z_s <= b_s;
            end
        end
    end

    else if (add_1)
    begin
        if (sum[27])
        begin
            z_m <= sum[27:4];
            guard <= sum[3];
            round_bit <= sum[2];
            sticky <= sum[1] | sum[0];
            z_e <= z_e + 1;
        end
        else
        begin
            z_m <= sum[26:3];
            guard <= sum[2];
            round_bit <= sum[1];
            sticky <= sum[0];
        end
    end

    else if (normalize_z_1)
    begin
        if (z_m[23] == 0 && $signed(z_e) > -126)
        begin
            z_e <= z_e - 1;
            z_m <= z_m << 1;
            z_m[0] <= guard;
            guard <= round_bit;
            round_bit <= 0;
        end
        else
        begin
            normed_z_1 <= 1;
        end
    end

    else if (normalize_z_2)
    begin
        if ($signed(z_e) < -126)
        begin
            z_e <= z_e + 1;
            z_m <= z_m >> 1;
            guard <= z_m[0];
            round_bit <= guard;
            sticky <= sticky | round_bit;
        end
        else
        begin
            normed_z_2 <= 1;
        end
    end

    else if (round)
    begin
        if (guard && (round_bit | sticky | z_m[0]))
        begin
        z_m <= z_m + 1;
        if (z_m == 24'hffffff)
            begin
                z_e <=z_e + 1;
            end
        end
        rounded <= 1;
    end

    else if (pack)
    begin
        z[22 : 0] <= z_m[22:0];
        z[30 : 23] <= z_e[7:0] + 127;
        z[31] <= z_s;
        if ($signed(z_e) == -126 && z_m[23] == 0)
        begin
            z[30 : 23] <= 0;
        end
        if ($signed(z_e) == -126 && z_m[23:0] == 24'h0) 
        begin
            z[31] <= 1'b0; // FIX SIGN BUG: -a + a = +0.
        end
        //if overflow occurs, return inf
        if ($signed(z_e) > 127) 
        begin
            z[22 : 0] <= 0;
            z[30 : 23] <= 255;
            z[31] <= z_s;
            error <= OVERFLOW;
        end

        begin
        packed_z <= 1;
        end
    end

    else if (put_z)
    begin
        got_output <= 1;
        output_z <= z;
    end
    else
    begin
        // got_output <= 1;
        output_z <= output_z;
    end

end

endmodule

module add_tb ();
    reg clk;
    reg rst;
    reg start;
    reg [31:0] input_a;
    reg [31:0] input_b;

    wire [31:0] output_z;
    wire [2:0] error;
    wire done;

    add dut(
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
        // input_a = 32'b11000001001010000000000000000000; // 10.5
        // input_b = 32'b11000000011000000000000000000000; // 3.5
        input_a = 32'b00000000010000111101011100001010;
        input_b = 32'b00000000001001100110011001100110;
    end

endmodule
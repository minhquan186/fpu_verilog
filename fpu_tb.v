module fpu_tb();
    parameter NUM_CASES = 10;
    reg clk;
    reg rst;
    reg start;

    wire [31:0] output_z;
    wire [2:0] error;
    wire done;

    integer addr;
    reg [65:0] stim;
    reg [65:0] inout_pattern [0:NUM_CASES-1];


    integer res_file;

    fpu fpu_dut(
        .clk(clk),
        .rst(rst),
        .start(start),
        .input_a(stim[63:32]),
        .input_b(stim[31:0]),
        .opcode(stim[65:64]),
        .output_z(output_z),
        .error(error),
        .done(done)
    );

    initial 
    begin
        clk = 1;
        forever #5 clk = ~clk;
    end

    initial 
    begin
        $readmemb("tb_input_gen.txt", inout_pattern);
    end

    initial
    begin
        res_file = $fopen("output_tb_fpu.txt", "w");
        for (addr = 0; addr < NUM_CASES; addr = addr + 1)
            begin
                $display("Start loop #%0d", addr);
                rst     = 1;
                #10
                rst     = 0;
                #10
                start   = 1;
                stim = inout_pattern[addr][100:0];
                wait ((done) == 1);
                # 5; 
                $display("End loop #%0d", addr);
            end
        $fclose(res_file);
        $stop;
    end

    always@(posedge done)
        begin
        $display("%t: opcode = %b, a = %b, b = %b, z = %b, error = %b", 
                    $time, stim[65:64], stim[63:32], stim[31:0], output_z,error);
        $fdisplay(res_file,"%b%b", output_z, error);
        end
endmodule
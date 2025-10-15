`timescale 1ns/1ps

module tb_decode_cycle();

    // Inputs
    reg clk;
    reg rst;
    reg RegWriteW;
    reg [4:0] RDW;
    reg [31:0] InstrD, PCD, PCPlus4D, ResultW;

    // Outputs
    wire RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE;
    wire [2:0] ALUControlE;
    wire [31:0] RD1_E, RD2_E, Imm_Ext_E;
    wire [4:0] RS1_E, RS2_E, RD_E;
    wire [31:0] PCE, PCPlus4E;

    // Instantiate DUT (note: capital D)
    Decode_Cycle dut (
        .clk(clk),
        .rst(rst),
        .InstrD(InstrD),
        .PCD(PCD),
        .PCPlus4D(PCPlus4D),
        .RegWriteW(RegWriteW),
        .RDW(RDW),
        .ResultW(ResultW),
        .RegWriteE(RegWriteE),
        .ALUSrcE(ALUSrcE),
        .MemWriteE(MemWriteE),
        .ResultSrcE(ResultSrcE),
        .BranchE(BranchE),
        .ALUControlE(ALUControlE),
        .RD1_E(RD1_E),
        .RD2_E(RD2_E),
        .Imm_Ext_E(Imm_Ext_E),
        .RD_E(RD_E),
        .PCE(PCE),
        .PCPlus4E(PCPlus4E),
        .RS1_E(RS1_E),
        .RS2_E(RS2_E)
    );

    // Clock generation
    always #5 clk = ~clk;  // 10ns period = 100MHz

    // Stimulus
    initial begin
        // Initialize
        clk = 0;
        rst = 0;
        RegWriteW = 0;
        RDW = 0;
        InstrD = 0;
        PCD = 32'h00000000;
        PCPlus4D = 32'h00000004;
        ResultW = 32'h00000000;

        // Apply reset
        #10 rst = 1;

        // --- Test 1: R-type (add x3, x1, x2) ---
        InstrD = 32'b0000000_00010_00001_000_00011_0110011; 
        RDW = 5'd3;
        ResultW = 32'hA5A5A5A5;
        RegWriteW = 1;
        #10 RegWriteW = 0;

        // --- Test 2: I-type (addi x5, x2, 10) ---
        InstrD = 32'b000000001010_00010_000_00101_0010011; 
        #10;

        // --- Test 3: Load (lw x6, 4(x1)) ---
        InstrD = 32'b000000000100_00001_010_00110_0000011; 
        #10;

        // --- Test 4: Store (sw x7, 8(x1)) ---
        InstrD = 32'b0000000_00111_00001_010_01000_0100011; 
        #10;

        // --- Test 5: Branch (beq x1, x2, offset=16) ---
        InstrD = 32'b0000000_00010_00001_000_00010_1100011; 
        #10;

        $display("✅ Simulation complete!");
        #20 $finish;
    end

    // Dump waves
    initial begin
        $dumpfile("decode_cycle_tb.vcd");
        $dumpvars(0, tb_decode_cycle);
    end

endmodule

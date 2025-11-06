`timescale 1ns / 1ps

module execute_cycle_tb;

    // ----------------------------------------------------
    // 1. Declare TB Signals (Wires/Regs)
    // ----------------------------------------------------
    reg clk, rst;
    reg RegWriteE, ALUSrcE, MemWriteE, ResultSrcE, BranchE;
    reg [2:0] ALUControlE;
    reg [31:0] RD1_E, RD2_E, Imm_Ext_E;
    reg [4:0] RD_E;
    reg [31:0] PCE, PCPlus4E;
    reg [31:0] ResultW; 
    reg [1:0] ForwardA_E, ForwardB_E;

    // Outputs from the Execute_Cycle module (M signals)
    wire PCSrcE, RegWriteM, MemWriteM, ResultSrcM;
    wire [4:0] RD_M; 
    wire [31:0] PCPlus4M, WriteDataM, ALU_ResultM;
    wire [31:0] PCTargetE; 

    // ----------------------------------------------------
    // 2. Instantiate the Module Under Test (MUT)
    // ----------------------------------------------------
    Execute_Cycle MUT (
        .clk(clk),
        .rst(rst),
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
        .ResultW(ResultW),
        .ForwardA_E(ForwardA_E),
        .ForwardB_E(ForwardB_E),
        .PCSrcE(PCSrcE),
        .RegWriteM(RegWriteM),
        .MemWriteM(MemWriteM),
        .ResultSrcM(ResultSrcM),
        .RD_M(RD_M),
        .PCPlus4M(PCPlus4M),
        .WriteDataM(WriteDataM),
        .ALU_ResultM(ALU_ResultM),
        .PCTargetE(PCTargetE)
    );

    // ----------------------------------------------------
    // 3. Clock Generation
    // ----------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // ----------------------------------------------------
    // 4. Waveform Dump Setup
    // ----------------------------------------------------
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, execute_cycle_tb);
    end

    // ----------------------------------------------------
    // 5. Test Vectors (Stimulus)
    // ----------------------------------------------------
    initial begin
        // Initialize all inputs
        rst = 1'b0;
        RegWriteE = 1'b0; MemWriteE = 1'b0; ALUSrcE = 1'b0; BranchE = 1'b0;
        ResultSrcE = 1'b0; ALUControlE = 3'b000;
        RD1_E = 32'h0; RD2_E = 32'h0; Imm_Ext_E = 32'h0; RD_E = 5'h0;
        PCE = 32'h0; PCPlus4E = 32'h4;
        ResultW = 32'h0; ForwardA_E = 2'b00; ForwardB_E = 2'b00;
        
        // Apply Reset
        #10 rst = 1'b1;

        // --- Test 1: R-Type Instruction (ADD) ---
        // ADD x3, x1, x2  (Assume x1=10, x2=20)
        // Expected: ALU_ResultM = 30
        #10;
        $display("--- Starting Test 1: ADD (10 + 20) ---");
        // Control: RegWrite ON, ALU uses both registers (ALUSrcE=0), ALU op is ADD (000)
        RegWriteE = 1'b1;  // Write back result
        ALUSrcE = 1'b0;    // ALU Source B is RD2_E
        ALUControlE = 3'b000; // ADD operation (assuming ALU.v uses 000 for ADD)
        
        // Data: x1=10, x2=20, Destination x3 (00011)
        RD1_E = 32'd10;
        RD2_E = 32'd20;
        RD_E = 5'd3; 
        
        #10;
        $display("ALU Result (ADD): %h (Expected: 1e)", ALU_ResultM); // 1e hex is 30 dec

        // --- Test 2: I-Type Instruction (ADDI) ---
        // ADDI x4, x1, 5  (Assume x1=10)
        // Expected: ALU_ResultM = 15
        #10;
        $display("--- Starting Test 2: ADDI (10 + 5) ---");
        // Control: RegWrite ON, ALU uses Immediate (ALUSrcE=1), ALU op is ADD (000)
        ALUSrcE = 1'b1;    // ALU Source B is Imm_Ext_E
        Imm_Ext_E = 32'd5; // Immediate value 5
        RD1_E = 32'd10;    // x1 value 10
        RD_E = 5'd4;       // Destination x4
        
        #10;
        $display("ALU Result (ADDI): %h (Expected: 0f)", ALU_ResultM); // 0f hex is 15 dec

        // --- Test 3: Load/Store Address Calc (SW) ---
        // SW x5, 4(x1) (Assume x1=100)
        // Expected: ALU_ResultM (Address) = 104
        #10;
        $display("--- Starting Test 3: SW Address Calc (100 + 4) ---");
        // Control: MemWrite ON, RegWrite OFF, ALU uses Immediate (ALUSrcE=1), ALU op is ADD (000)
        MemWriteE = 1'b1;  // Need to write to memory
        RegWriteE = 1'b0;  // No register write
        ALUSrcE = 1'b1;    // ALU Source B is Imm_Ext_E (offset)
        
        // Data: x1=100 (Base), offset=4, x5=42 (Data to Write)
        RD1_E = 32'd100;
        Imm_Ext_E = 32'd4;
        RD2_E = 32'd42; // Data to be stored (WriteDataM should be 42)
        
        #10;
        $display("ALU Result (Address): %h (Expected: 68)", ALU_ResultM); // 68 hex is 104 dec
        $display("Write Data: %h (Expected: 2a)", WriteDataM); // 2a hex is 42 dec

        // --- Test 4: Branch Equal (BEQ) - Taken ---
        // BEQ x1, x2, offset=8 (Assume x1=10, x2=10, PC=100, PCPlus4=104)
        // Expected: PCSrcE = 1 (Branch is taken), PCTargetE = 100 + 8 = 108
        #10;
        $display("--- Starting Test 4: BEQ (Taken) ---");
        // Control: Branch ON, ALU op is SUB (to compare x1 and x2)
        BranchE = 1'b1;    // This is a branch instruction
        RegWriteE = 1'b0; MemWriteE = 1'b0;
        ALUSrcE = 1'b0;    // ALU Source B is RD2_E (for SUB)
        ALUControlE = 3'b001; // SUB operation (assuming ALU.v uses 001 for SUB)
        
        // Data: x1=10, x2=10, PC=100, Immediate=8
        RD1_E = 32'd10;
        RD2_E = 32'd10;
        PCE = 32'd100; 
        Imm_Ext_E = 32'd8; // Branch target offset 
        
        #10;
        $display("PCSrcE (Branch Taken): %b (Expected: 1)", PCSrcE);
        $display("PCTargetE (Address): %h (Expected: 6c)", PCTargetE); // 6c hex is 108 dec
        
        // --- End Simulation ---
        #20 $finish;
    end
    
endmodule

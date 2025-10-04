module tb();

  //Declare I/O
  reg clk=1, rst, PCSrcE;
  reg[31:0] PCTargetE;
  wire[31:0] InstrD, PCD, PCPlus4D;
  
  //Declare the DUT
  fetch_cycle_dut (
    .clk(clk),
    .rst(rst),
    .PCSrcE(PCSrcE),
    .PCTargetE(PCTargetE),
    .PCD(PCD),
    .PCPlus4D(PCPlus4D
    );

    //Generation of clock
    always begin
      clk= ~clk;
      #50;
    end

    //Provide the stimulus
    initial begin
      rst<=1'b0;
      #200;
      rst<=1'b1;
      PCSrcE<= 1'b0;
      PCTargetE<= 32'b00000000;
      #500;
      $finish;
    end

    //Generation of VCD file
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0);
    end
    endmodule
      
    
    

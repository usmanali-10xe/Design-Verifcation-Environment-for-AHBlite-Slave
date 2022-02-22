//Top most file which connets DUT, interface and the test

//-------------------------[NOTE]---------------------------------
//Particular testcase can be run by uncommenting, and commenting the rest
//`include "test1.sv"
//`include "test2.sv"
//`include "test3.sv"
//----------------------------------------------------------------
`include "amba_ahb_defines.v"
`include "interface.sv"
`include "test.sv"
module testbench_top;
  timeunit 1ns;
	timeprecision 1ns;

  //declare clock and reset signal
	logic clk;
  //clock generation
	always #10 clk = ~clk;
  //reset generation
	initial begin
		clk <= 0;
		_intf.hresetn <= 0;
      @(posedge clk);
		_intf.hresetn <= 1;
	end
	
  //interface instance, inorder to connect DUT and testcase
	intf _intf( .hclk(clk));
  //testcase instance, interface handle is passed to test as an argument
  test _test(_intf); // simulation cycle regions
  //DUT instance, interface signals are connected to the DUT ports
  amba_ahb_slave _dut(_intf.hclk, _intf.hresetn, _intf.hsel, _intf.haddr, _intf.htrans, _intf.hwrite, _intf.hsize, _intf.hburst, _intf.hprot, _intf.hwdata, _intf.hrdata, _intf.hready, _intf.hresp, _intf.error );
  
endmodule
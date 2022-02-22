//Interface groups the design signals, specifies the direction (Modport) and Synchronize the signals(Clocking Block)

interface intf #(parameter AW = `AW , DW = `DW, RW = `RW)
(
		input logic hclk, hresetn
);
	// AMBA AHB system signals
	//logic          hclk;     // Bus clock
	//logic          hresetn;  // Reset (active low)

	// AMBA AHB decoder signal
	logic          hsel;     // Slave select
	// AMBA AHB master signals
	logic [AW-1:0] haddr;    // Address bus
	logic    [1:0] htrans;   // Transfer type
	logic          hwrite;   // Transfer direction
	logic    [2:0] hsize;    // Transfer size
	logic    [2:0] hburst;   // Burst type
	logic    [3:0] hprot;    // Protection control
	logic [DW-1:0] hwdata;   // Write data bus
	// AMBA AHB slave signals
	logic [DW-1:0] hrdata;   // Read data bus
	logic          hready;   // Transfer done
	logic [RW-1:0] hresp;    // Transfer response
	// slave control signal
	logic          error;     // request an error response

	//Master Clocking block - used for Drivers
	clocking driver_cb @(posedge hclk);
		default input #1 output #1;
		output hsel, haddr, htrans, hwrite, hsize, hburst, hprot, hwdata, error; // inputs to DUT(AHBlite Slave)
		input  hrdata, hready, hresp; 																					 // ouputs from DUT
	endclocking
	//Monitor Clocking block - For sampling by monitor components
	clocking monitor_cb @(posedge hclk);
		default input #1 output #1;
		input  hsel, haddr, htrans, hwrite, hsize, hburst, hprot, hwdata, error; // inputs to DUT(AHBlite Slave)
		input hrdata, hready, hresp;																						 // ouputs from DUT
	endclocking
	//Add modports here
	modport test_if(input hrdata, hready, hresp,output hsel, haddr, htrans, hwrite, hsize, hburst, hprot, hwdata, error, input hclk, hresetn); // for test programm
	modport dut_if(output hrdata, hready, hresp, input hsel, haddr, htrans, hwrite, hsize, hburst, hprot, hwdata, error, input hclk, hresetn); // for dut module
	modport drv_if(clocking driver_cb,  input hclk, hresetn); // for driver to dut 
	modport mnt_if(clocking monitor_cb, input hclk, hresetn); // for dut to monitor

endinterface
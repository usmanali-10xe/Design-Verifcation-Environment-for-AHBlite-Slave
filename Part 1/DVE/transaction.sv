//Fields required to generate the stimulus are declared in the transaction class

class transaction;
	// hresetn;
  //declare transaction items
  // AMBA AHB decoder signal
  rand bit          hsel;     // Slave select
  // AMBA AHB master signals
  rand bit [`AW-1:0]haddr;    // Address bus
  rand bit    [1:0] htrans;   // Transfer type
  rand bit          hwrite;   // Transfer direction
  rand bit    [2:0] hsize;    // Transfer size
  rand bit    [2:0] hburst;   // Burst type
  rand bit    [3:0] hprot;    // Protection control
  rand bit [`DW-1:0]hwdata;   // Write data bus
  // AMBA AHB slave signals
	   bit [`DW-1:0]hrdata;   // Read data bus
  	   bit          hready;   // Transfer done
  	   bit [`RW-1:0]hresp;    // Transfer response
  // slave control signal
  rand bit          error;     // request an error response
 	
  //Add Constraints
  constraint burst { 
    hburst inside{`H_SINGLE};
  } // no burst
  constraint transfer { 
    htrans dist  {`H_IDLE :=1, `H_BUSY :=1, `H_NONSEQ:=8};
  } 						// distributed transfer modes
  constraint size { 
    hsize inside {`H_SIZE_8,`H_SIZE_16,`H_SIZE_32};
  }							// for bytes, half words and words only
  constraint addr { 
    hsize == `H_SIZE_16 -> haddr[0] == '0;
    hsize == `H_SIZE_32 -> haddr[1:0] == '0;
    haddr inside{[0:1023]};
    solve hsize before haddr;
  }							// addr aligned with size
  constraint prot { 
    1 -> hprot == 1;
  }							// Data Access only
  function new(input int seed=0);
    srandom(seed);
  endfunction
  //Add print transaction method(optional)
  function void print_trans(string trid = "", bit debug=0);
  	if(debug)
      $display("%2s| hsel=%0x, haddr=%3x, htrans=%0x, hwrite=%0x, hsize=%0x, hburst=%0x, hprot=%0b, hwdata=%8x, hrdata=%8x, hready=%0x, hresp=%0x, error=%0x\n", trid, hsel, haddr, htrans, hwrite, hsize, hburst, hprot, hwdata, hrdata, hready, hresp, error);
  endfunction
  
endclass
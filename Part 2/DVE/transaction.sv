//Fields required to generate the stimulus are declared in the transaction class

class transaction;

  //declare transaction items
  // AMBA AHB decoder signal
       bit          hresetn;  // Reset (active low)
  rand bit          hsel;     // Slave select
  // AMBA AHB master signals
  rand bit [`AW-1:0]haddr;    // Address bus
  rand bit    [1:0] htrans;   // Transfer type
  rand bit          hwrite;   // Transfer direction
  rand bit    [2:0] hsize;    // Transfer size
  rand bit    [2:0] hburst;   // Burst type
  rand bit    [3:0] hprot;    // Protection control
  rand logic [`DW-1:0]hwdata;   // Write data bus
  // AMBA AHB slave signals
	   logic [`DW-1:0]hrdata;   // Read data bus
  	   bit          hready;   // Transfer done
  	   bit [`RW-1:0]hresp;    // Transfer response
  // slave control signal
  rand bit          error;     // request an error response
 	
  //Add Constraints
  constraint burst { 
    hburst inside{[`H_SINGLE:`H_INCR16]};
  } // no burst
  constraint transfer { 
    htrans dist  {`H_IDLE:=1,`H_BUSY:=1,`H_NONSEQ:=4};
  } 						// distributed transfer modes
  constraint size { 
    hsize inside {[`H_SIZE_8:$clog2(`AW/8)]}; // depends on bus/beat size of protocol - hardware dependent
  }						
  constraint addr { 
    hsize == `H_SIZE_16  -> haddr[0] == '0;
    hsize == `H_SIZE_32  -> haddr[1:0] == '0;
    hsize == `H_SIZE_64  -> haddr[2:0] == '0;
    hsize == `H_SIZE_128 -> haddr[3:0] == '0;
    hsize == `H_SIZE_256 -> haddr[4:0] == '0;
    hsize == `H_SIZE_512 -> haddr[5:0] == '0;
    hsize == `H_SIZE_1024-> haddr[6:0] == '0;
    solve hsize before haddr;// addr aligned with size
    haddr inside{[0:1023]};  // peripheral memory size constraints
  }							
  constraint prot { 
    1 -> hprot == 4'b0011;
  }// the master sets HPROT to non-cacheable,non-bufferable, privileged, data access
  
  function new(input int seed=1);
    srandom(seed);
  endfunction
  //Add print transaction method(optional)
  function void print_trans(string trid = "", bit debug=0);
  	if(debug)
      $display($time,": %2s| hresetn=%0x, hsel=%0x, haddr=%3x, htrans=%0x, hwrite=%0x, hsize=%0x, hburst=%0x, hprot=%0b, hwdata=%8x, hrdata=%8x, hready=%0x, hresp=%0x, error=%0x\n", trid, hresetn, hsel, haddr, htrans, hwrite, hsize, hburst, hprot, hwdata, hrdata, hready, hresp, error);
  endfunction
  
endclass
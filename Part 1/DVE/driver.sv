//Gets the packet from generator and drive the transaction packet items into interface (interface is connected to DUT, so the items driven into interface signal will get driven in to DUT) 

`define DRIVER_cb vif.drv_if.driver_cb
class driver;
  //virtual interface handle
	virtual intf vif;
  //create mailbox handle
	mailbox dmb;
	//used to count the number of transactions
  int trans_count=0;  
  //constructor
  function new(virtual intf vif, input mailbox mbx);
  	this.dmb = mbx;
  	this.vif = vif;
  endfunction
  //reset methods
	task reset;
      wait(!vif.hresetn);
      $display("[ DRIVER ] ----- Reset Started -----");
      `DRIVER_cb.hsel 		<= '0;
      `DRIVER_cb.haddr 	<= '0;
      `DRIVER_cb.htrans	<= `H_IDLE;
      `DRIVER_cb.hwrite	<= '0;
      `DRIVER_cb.hsize	<= `H_SIZE_32;
      `DRIVER_cb.hburst	<= `H_SINGLE;
      `DRIVER_cb.hprot	<= '0;
      `DRIVER_cb.hwdata 	<= '0;
      `DRIVER_cb.error 	<= '0;
      wait(vif.hresetn);
      $display("[ DRIVER ] ----- Reset Ended   -----");
	endtask
  //drive methods
	task drive;
      transaction trans;
      dmb.get(trans);
     // @(`DRIVER_cb);
      `DRIVER_cb.hsel  <= trans.hsel;
      `DRIVER_cb.haddr <= trans.haddr;
      `DRIVER_cb.htrans<= trans.htrans;
      `DRIVER_cb.hwrite<= trans.hwrite;
      `DRIVER_cb.hsize <= trans.hsize;
      `DRIVER_cb.hburst<= trans.hburst;
      `DRIVER_cb.hprot <= trans.hprot;
      `DRIVER_cb.error <= trans.error;
      `DRIVER_cb.htrans<= trans.htrans;
      `DRIVER_cb.haddr <= trans.haddr;
      @(`DRIVER_cb);
      `DRIVER_cb.hwdata<= trans.hwdata;
	  //@(`DRIVER_cb);
      trans.print_trans("[Driver    ]", '0);
      //wait(`DRIVER_cb.hready);
      trans_count++;
  endtask
  //main methods
  task main;
      fork
        //Thread-1: Waiting for reset
        begin
          wait(!vif.hresetn);
        end
        //Thread-2: Calling drive task
        begin
          forever
            drive();
        end
      join_any
      //disable fork;
  endtask
  
endclass

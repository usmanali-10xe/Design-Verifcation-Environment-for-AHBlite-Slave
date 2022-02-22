//Samples the interface signals, captures into transaction packet and sends the packet to scoreboard.
`define MONITOR_cb vif.mnt_if.monitor_cb
class monitor;
  
  //virtual interface handle
	virtual intf vif;
  //create mailbox handle
	mailbox mmb;
  // debug to monitor
  	bit debug;
  //constructor
  function new(virtual intf vif, input mailbox mbx, bit debug=0);
		this.mmb = mbx;
		this.vif = vif;
    	this.debug = debug;
	endfunction
  //main method
	task main;
    @(`MONITOR_cb);
    forever begin
      transaction trans;
      trans = new();
      //@(`MONITOR_cb);
        trans.hresetn = vif.hresetn;
        trans.hsel  = `MONITOR_cb.hsel;
        trans.haddr = `MONITOR_cb.haddr;
        trans.htrans= `MONITOR_cb.htrans;
        trans.hwrite= `MONITOR_cb.hwrite;
        trans.hsize = `MONITOR_cb.hsize;
        trans.hburst= `MONITOR_cb.hburst;
        trans.hprot = `MONITOR_cb.hprot;
        trans.error = `MONITOR_cb.error;
        trans.hwdata= `MONITOR_cb.hwdata;
      @(`MONITOR_cb);
      	//wait(`MONITOR_cb.hready);
        trans.hwdata = `MONITOR_cb.hwdata;
	 			trans.hrdata = `MONITOR_cb.hrdata;
      	trans.hready = `MONITOR_cb.hready;
      	trans.hresp  = `MONITOR_cb.hresp;
     // wait(`MONITOR_cb.hready);
      @(`MONITOR_cb);
      	mmb.put(trans);
        trans.print_trans("[Monitor   ]", debug);
    end
  endtask
endclass

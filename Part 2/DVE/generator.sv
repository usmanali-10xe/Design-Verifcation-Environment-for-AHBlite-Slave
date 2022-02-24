//Generates randomized transaction packets and put them in the mailbox to send the packets to driver 

class generator;
  
  //declare transaction class
  transaction trans;
  //repeat count, to specify number of items to generate
  int  repeat_count=0;
  //create mailbox handle
  mailbox gmb;
  //declare an event
  event gdone; 
  // debug to monitor
  bit debug=1;
  int seed;
  //constructor
  function new(input mailbox mbx, bit debug=0);
  	this.gmb = mbx;
    this.debug = debug;
  endfunction
  //main methods
  task count_transaction;
    trans.print_trans("[Generator ]", debug);
    gmb.put(trans);
    repeat_count++;
  endtask
  task reset;
    trans = new(seed++);
    if(!trans.randomize())
       $fatal($time,": [Generator]| randomization failed...");
    trans.hsel = 1;
    trans.hresetn=1; // reset assertion
    trans.error=0; // error disassertion
    trans.htrans = 0; // making sure transfer is idle for first cycle of pipeline
    count_transaction(); //since our data and address phases are pipelined we are generating two transaction for reset sequence
    trans = new(seed++);
    if(!trans.randomize())
       $fatal($time,": [Generator]| randomization failed...");
    trans.hsel = 1;
    trans.hresetn=0; // reset assertion
    trans.error=0; // error disassertion
    trans.hwrite = 0; //trying to read while reset
    trans.htrans = 2; // non-sequential read
    count_transaction();
  endtask
  task error; // assert error to observe response
    trans = new(seed++);
    if(!trans.randomize())
       $fatal($time,": [Generator]| randomization failed...");
    trans.hsel = 1;
    trans.hresetn=1;
	trans.error = 1;  // error assertion
    count_transaction();
  endtask
  task automatic normal(); // normal transfer
    trans = new(seed++);
    if(!trans.randomize())
       $fatal($time,": [Generator]| randomization failed...");
    trans.hsel = 1; 
    trans.hresetn=1;
    trans.error = 0;
  endtask
  task r_wdata(bit write); // size=0,1,2,3 corresponding to byte,halfword, word and random
    normal();
    trans.hwrite = write;
    trans.hburst = `H_SINGLE;
    count_transaction();
  endtask 
  task automatic incr(bit write=0, int beats=2); //by default read of 2 beats
    logic [2:0] size;
    logic [`AW-1]addr;
    normal(); 
    trans.htrans = 2; //first non-seq transfer
    trans.hwrite = write; // depends on Read/write command
    trans.hburst = `H_INCR;
    count_transaction();
    size = trans.hsize;
    addr = trans.haddr; // to contain first transfer parameters
    repeat(beats-1) begin
      normal();
      trans.hsize = size;
      trans.htrans = 3; //ramining seq transfer
      trans.hwrite = write; // depends on Read/write command
      trans.hburst = `H_INCR;
      trans.haddr = addr+2**(size); // increment by transfer sizes
      addr = trans.haddr; // update addr var
      count_transaction();	
    end
  endtask
  task automatic incr4(bit write=0); //by default read of 2 beats
    logic [2:0] size;
    logic [`AW-1]addr;
    normal();
    trans.htrans = 2; //first non-seq transfer
    trans.hwrite = write; // depends on Read/write command
    trans.hburst = `H_INCR4;
    count_transaction();
    size = trans.hsize;
    addr = trans.haddr; // to contain first transfer parameters
    repeat(3) begin
      normal(); 
      trans.hsize = size;
      trans.htrans = 3; //ramining seq transfer
      trans.hwrite = write; // depends on Read/write command
      trans.hburst = `H_INCR4;
      trans.haddr = addr+2**(size); // increment by transfer sizes
      addr = trans.haddr; // update addr var
      count_transaction();	
    end
  endtask
  task automatic wrap8(bit write=0); //by default read
    logic [2:0] size;
    logic [`AW-1]addr;
    normal(); 
    trans.htrans = 2; //first non-seq transfer
    trans.hburst = `H_WRAP8;
    trans.hwrite = write; // depends on Read/write command
    count_transaction();
    size = trans.hsize;
    addr = trans.haddr; // to contain first transfer parameters
    repeat(7) begin
      normal(); 
      trans.hsize=size;// random size
      trans.htrans = 3; //ramining seq transfer
      trans.hwrite = write; // depends on Read/write command
      trans.hburst = `H_WRAP8;
      addr = addr+ 2**size; // update addr var
      case(size)
        0:trans.haddr[2:0] = addr&3'b111; // increment by transfer sizes
        1:trans.haddr[3:0] = addr&3'b1111; // increment by transfer sizes
        2:trans.haddr[4:0] = addr&3'b11111; // increment by transfer sizes
      endcase
      count_transaction();	
    end
  endtask

  task main;
    $display("--------------------------------------------------------------------------------------------");
   // seed = 1;
    $display($time,": [Generator ]| Writing bytes, halfwords and words randomly.......");
    repeat(400) r_wdata(1);// simple single burst write: BYTES, HALFS, WORDS
    //seed = 1;
    $display($time,": [Generator ]| Reading bytes, halfwords and words randomly.......");
    repeat(400) r_wdata(0);// simple single burst read: BYTES, HALFS, WORDS
    $display($time,": [Generator ]| Resetting DUT.....................................");
    repeat(1) reset(); // reset and read bus data
    seed = 1;
    $display($time,": [Generator ]| Incrementing burst, INCR 3-beats length: WRITE ...");
    repeat(10) incr(1,3); // writing
    seed = 1;
    $display($time,": [Generator ]| Incrementing burst, INCR 3-beats length: READ ....");
    repeat(10) incr(0,3); // reading
    seed = 10;
    $display($time,": [Generator ]| Eight-beat wrapping burst, WRAP8: WRITE...........");
    repeat(4) wrap8(1); // writing
    seed = 10;    
    $display($time,": [Generator ]| Eight-beat wrapping burst, WRAP8: READ............");
    repeat(4) wrap8(0); // reading
    $display($time,": [Generator ]| Error Signal asserted to check the response.......");
    repeat(1) error(); // rerror assertion
    $display($time,": [Generator ]| Reading byte randomly.............................");
    repeat(1) r_wdata(0); //must show an error as it is being asserted in second cycle of error
    $display($time,": [Generator ]| Resetting DUT.....................................");
    repeat(1) reset(); // reset and read bus data
	$display("--------------------------------------------------------------------------------------------");
    ->gdone; //triggering indicatesthe end of generation 
  endtask
  
endclass

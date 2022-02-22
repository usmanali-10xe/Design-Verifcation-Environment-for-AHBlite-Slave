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
    trans.hresetn=0; // reset assertion
    if(trans.htrans<2) // must be non-seq or seq read
      trans.htrans =2;
    trans.hwrite = 0; // to read bus data
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
  task automatic normal(int size); // normal transfer
    trans = new(seed++);
    if(!trans.randomize())
       $fatal($time,": [Generator]| randomization failed...");
    trans.hsel = 1; 
    trans.hresetn=1;
    trans.error = 0;
    if(size!=3)
    	trans.hsize = size; // if not random, assign byte, half or word
  endtask
  task wdata(int size=0); // size=0,1,2,3 corresponding to byte,halfword, word and random
    normal(size);
    trans.hwrite = 1;
    if(trans.htrans==3) // if sequential
    	trans.htrans = 2;// make it nonseq
    count_transaction();
  endtask 
  task rdata(int size=0); // size=0,1,2,3 corresponding to byte,halfword, word and random
    normal(size);
    trans.hwrite = 1;
    if(trans.htrans==3) // if sequential
    	trans.htrans = 2; // make it nonseq
    count_transaction();
  endtask
  task automatic incr(bit write=0, int beats=2); //by default read of 2 beats
    logic [2:0] size;
    logic [`AW-1]addr;
    normal(3); // random size
    trans.htrans = 2; //first non-seq transfer
    trans.hwrite = write; // depends on Read/write command
    trans.hburst = `H_INCR;
    count_transaction();
    size = trans.hsize;
    addr = trans.haddr; // to contain first transfer parameters
    repeat(beats-1) begin
      normal(size); // random size
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
    normal(3); // random size
    trans.htrans = 2; //first non-seq transfer
    trans.hwrite = write; // depends on Read/write command
    trans.hburst = `H_INCR4;
    count_transaction();
    size = trans.hsize;
    addr = trans.haddr; // to contain first transfer parameters
    repeat(3) begin
      normal(size); // random size
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
    normal(3); // random size
    trans.htrans = 2; //first non-seq transfer
    trans.hburst = `H_WRAP8;
    trans.hwrite = write; // depends on Read/write command
    count_transaction();
    size = trans.hsize;
    addr = trans.haddr; // to contain first transfer parameters
    repeat(7) begin
      normal(size); // random size
      trans.htrans = 3; //ramining seq transfer
      trans.hwrite = write; // depends on Read/write command
      trans.hburst = `H_WRAP8;
      addr = addr+ 2**size; // update addr var
      trans.haddr[2:0] = addr&3'b111; // increment by transfer sizes
      count_transaction();	
    end
  endtask

  task main;
    seed=1;
    $display($time,": [Generator ]| Writing bytes randomly..........");
    repeat(10) wdata(0); // simple single burst write: BYTES
    seed = 1;
    $display($time,": [Generator ]| Reading bytes with same writing sequence..........");
    repeat(10) rdata(0);// simple single burst read: BYTES
    seed = 1;
    $display($time,": [Generator ]| Writing halfwords randomly..........");
    repeat(10) wdata(1);// simple single burst write: HALFS
    seed = 1;
    $display($time,": [Generator ]| Reading halfwords with same writing sequence..........");
    repeat(10) rdata(1);// simple single burst read: HALFS
    seed = 1;
    $display($time,": [Generator ]| Writing words randomly..........");
    repeat(10) wdata(2);// simple single burst write: WORDS
    seed = 1;
    $display($time,": [Generator ]| Reading words with same writing sequence..........");
    repeat(10) rdata(2);// simple single burst read: WORDS
    seed = 1;
    $display($time,": [Generator ]| Writing bytes, halfwords and words randomly..........");
    repeat(10) wdata(3);// simple single burst write: BYTES, HALFS, WORDS
    seed = 1;
    $display($time,": [Generator ]| Reading bytes, halfwords and words randomly..........");
    repeat(10) rdata(3);// simple single burst read: BYTES, HALFS, WORDS
    seed = 1;
    $display($time,": [Generator ]| Resetting DUT..........");
    repeat(1) reset(); // reset and read bus data
    seed = 5;
    $display($time,": [Generator ]| Undefined length incrementing burst, INCR 4-beats length: WRITE ..........");
    repeat(1) incr(1,3); // writing
    seed = 5;
    $display($time,": [Generator ]| Undefined length incrementing burst, INCR 4-beats length: READ ..........");
    repeat(1) incr(0,3); // reading
    seed = 10;
    $display($time,": [Generator ]| Eight-beat wrapping burst, WRAP8: WRITE..........");
    repeat(1) wrap8(1); // writing
    seed = 10;    
    $display($time,": [Generator ]| Eight-beat wrapping burst, WRAP8: READ..........");
    repeat(1) wrap8(0); // reading
    ->gdone; //triggering indicatesthe end of generation 
  endtask
  
endclass
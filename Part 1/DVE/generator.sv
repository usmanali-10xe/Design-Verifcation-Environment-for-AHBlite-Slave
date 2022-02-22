//Generates randomized transaction packets and put them in the mailbox to send the packets to driver 

class generator;
  
  //declare transaction class
  transaction trans;
  //repeat count, to specify number of items to generate
  int  repeat_count;
  //create mailbox handle
  mailbox gmb;
  //declare an event
  event gdone; 
  //constructor
  function new(input mailbox mbx);
  	this.gmb = mbx;
  endfunction
  
  //main methods
  task main;
    int count=0;
    $display("[Generator ]| Writing bytes randomly..........");
    repeat(repeat_count/6) begin
      trans = new(count++);
      if(!trans.randomize())
        $fatal("T=%0t:\t [Generator]| randomization failed...",$time);
      else begin
        trans.hsel = 1;
        trans.error = 0;
        trans.hwrite = 1;
        trans.hrdata = 'z;
        trans.hsize = 0;
        trans.print_trans("[Generator ]", '0);
        gmb.put(trans);
      end
    end
    count = 0;
    $display("[Generator ]| Reading bytes with same writing sequence..........");
    repeat(repeat_count/6) begin
      trans = new(count++);
      if(!trans.randomize())
        $fatal("T=%0t:\t [Generator]| randomization failed...",$time);
      else begin
        trans.hsel = 1;
        trans.error = 0;
        trans.hwrite = 0;
        trans.hwdata = 'x;
        trans.hsize = 0;
        trans.print_trans("[Generator ]", '0);
        gmb.put(trans);
      end
    end
    count = 0;
    $display("[Generator ]| Writing halfwords randomly..........");
    repeat(repeat_count/6) begin
      trans = new(count++);
      if(!trans.randomize())
        $fatal("T=%0t:\t [Generator]| randomization failed...",$time);
      else begin
        trans.hsel = 1;
        trans.error = 0;
        trans.hwrite = 1;
        trans.hrdata = 'z;
        trans.hsize = 1;
        trans.print_trans("[Generator ]", '0);
        gmb.put(trans);
      end
    end
    count = 0;
    $display("[Generator ]| Reading halfwords with same writing sequence..........");
    repeat(repeat_count/6) begin
      trans = new(count++);
      if(!trans.randomize())
        $fatal("T=%0t:\t [Generator]| randomization failed...",$time);
      else begin
        trans.hsel = 1;
        trans.error = 0;
        trans.hwrite = 0;
        trans.hwdata = 'x;
        trans.hsize = 1;
        trans.print_trans("[Generator ]", '0);
        gmb.put(trans);
      end
    end
    count = 0;
    $display("[Generator ]| Writing bytes, halfwords and words randomly..........");
    repeat(repeat_count/6) begin
      trans = new(count++);
      if(!trans.randomize())
        $fatal("T=%0t:\t [Generator]| randomization failed...",$time);
      else begin
        trans.hsel = 1;
        trans.error = 0;
        trans.hwrite = 1;
        trans.hrdata = 'z;
        trans.print_trans("[Generator ]", '0);
        gmb.put(trans);
      end
    end
   // count = 0;
    $display("[Generator ]| Reading bytes, halfwords and words randomly..........");
    repeat(repeat_count/6) begin
      trans = new(count++);
      if(!trans.randomize())
        $fatal("T=%0t:\t [Generator]| randomization failed...",$time);
      else begin
        trans.hsel = 1;
        trans.error = 0;
        trans.hwrite = 0;
        trans.hwdata = 'x;
        trans.print_trans("[Generator ]", '0);
        gmb.put(trans);
      end
    end 
    ->gdone; //triggering indicatesthe end of generation 
  endtask
  
endclass
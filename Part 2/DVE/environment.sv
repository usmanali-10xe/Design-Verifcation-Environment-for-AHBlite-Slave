//A container class that contains Mailbox, Generator, Driver, Monitor and Scoreboard
//Connects all the components of the verification environment
`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
class environment;
  
  //handles of all components
  generator gen;
  driver drv;
  monitor mnt;
  scoreboard scb;
  
  //mailbox handles
  mailbox gen2drv;
  mailbox mnt2scb;
  
  //declare an event
  event envdone;
  //virtual interface handle
  virtual intf vif;
  //constructor
  function new(virtual intf vif);
  	this.vif = vif;
  	gen2drv = new();
  	mnt2scb = new();
    drv = new(vif,gen2drv,0); // to debug pass third argument 1 otherwise 0
    mnt = new(vif,mnt2scb,0); // to debug pass third argument 1 otherwise 0
    gen = new(gen2drv,0);// to debug pass third argument 1 otherwise 0
    scb = new(mnt2scb,0);// to debug pass third argument 1 otherwise 0
  endfunction
  
  //pre_test methods
  task pre_test;
  	drv.reset();
  endtask
  
  //test methods
  task test();
    fork 
      gen.main();
      drv.main();
      mnt.main();
      scb.main();
    join_any
  endtask
  
  //post_test methods
  task post_test();
    wait(gen.gdone.triggered);
    wait(gen.repeat_count == drv.trans_count); //Optional
    wait(gen.repeat_count == scb.trans_count);
    $display("--------------------------------------------------------------------------------------------");
    $display($time,": [Environment] Total number of Transfers:   %3d",scb.trans_count);
    $display($time,": [Environment] Total Success R/W Transfers: %3d",scb.trans_success);
    $display($time,": [Environment] Total Failed R/W Transfers:  %3d",scb.trans_failed);
    $display($time,": [Environment] Total IDLE Trans Transfers:  %3d",scb.trans_idle);
    $display($time,": [Environment] Total BUSY Trans Transfers:  %3d",scb.trans_busy);
    $display("--------------------------------------------------------------------------------------------");
  endtask
  
  //run methods
  task run();
    pre_test();
    test();
    post_test();
    $finish;
  endtask
endclass


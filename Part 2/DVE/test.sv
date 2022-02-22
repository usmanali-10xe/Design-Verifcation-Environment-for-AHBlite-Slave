//A program block that creates the environment and initiate the stimulus
`include "environment.sv"
program test(intf test_if);
  
  //declare environment handle
  environment env;
  initial begin
    //create environment
    env = new(test_if);
    //initiate the stimulus by calling run of env
	env.run();
  end

  initial
    begin
      $dumpfile("dump.vcd"); $dumpvars;
    end
endprogram
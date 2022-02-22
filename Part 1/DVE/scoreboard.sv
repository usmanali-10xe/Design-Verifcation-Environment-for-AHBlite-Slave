//Gets the packet from monitor, generates the expected result and compares with the actual result received from the Monitor
`include "coverage.sv"
class scoreboard;
    coverage cg;
  //create mailbox handle
	mailbox smb;
	int trans_count=0;
  	int check_success=0;
  //array to use as local memory
  logic [7:0]  mem [1023];
  //constructor
  function new(input mailbox mbx);
		this.smb = mbx;
  endfunction
  //main method
    task main;
    transaction trans;
    cg  = new(0);
    for(int j=0;j<1023;j=j+1) 
    	mem[j]=j;
    forever begin
      smb.get(trans); 
      if(trans.htrans == `H_NONSEQ && trans.hwrite == 1) //If Write, Store Data
        begin
          case (trans.hsize)
            `H_SIZE_32: {mem[trans.haddr+3],mem[trans.haddr+2],mem[trans.haddr+1],mem[trans.haddr]} = trans.hwdata;
            `H_SIZE_16: 
              case(trans.haddr[1])
                0: {mem[trans.haddr+1],mem[trans.haddr]} = trans.hwdata[15:0];
                1: {mem[trans.haddr+3],mem[trans.haddr+2]} = trans.hwdata[31:16];
              endcase
            `H_SIZE_8:
              case(trans.haddr[1:0])
                0:mem[trans.haddr]= trans.hwdata[7:0]; 
                1:mem[trans.haddr]= trans.hwdata[15:8];
                2:mem[trans.haddr]= trans.hwdata[23:16];
                3:mem[trans.haddr]= trans.hwdata[31:24];
              endcase
          endcase
        end
      else if(trans.htrans == `H_NONSEQ &&  trans.hwrite == 0) //If Read, compare with local memory
        begin
          case (trans.hsize)
            `H_SIZE_32: begin
              if({mem[trans.haddr+3],mem[trans.haddr+2],mem[trans.haddr+1],mem[trans.haddr]} == trans.hrdata)
               //$display($time,"	The Data is Correct, Address : %0h , Data : %0h",trans.haddr,trans.hrdata);
                check_success++;
              else 
                $display($time,"	Failed at Address : %0h , Data : %0h",trans.haddr,trans.hrdata);
            end
            `H_SIZE_16: begin
              bit condtrue;
              case(trans.haddr[1])
                0: condtrue = {mem[trans.haddr+1],mem[trans.haddr]} == trans.hrdata[15:0];
                1: condtrue = {mem[trans.haddr+3],mem[trans.haddr+2]} == trans.hrdata[31:16];
              endcase
              if(condtrue)
              //$display($time,"	The Data is Correct, Address : %0h , Data : %0h",trans.haddr,trans.hrdata);
                check_success++;
             else 
               $display($time,"	Failed at Address : %0d , Data : %0h",trans.haddr,trans.hrdata);
            end
            `H_SIZE_8: begin
              bit condtrue;
              case(trans.haddr[1:0])
                0: condtrue = mem[trans.haddr]== trans.hrdata[7:0];
                1: condtrue = mem[trans.haddr]== trans.hrdata[15:8];
                2: condtrue = mem[trans.haddr]== trans.hrdata[23:16];
                3: condtrue = mem[trans.haddr]== trans.hrdata[31:24];
              endcase
              if(condtrue)
              //$display($time,"	The Data is Correct, Address : %0h , Data : %0h",trans.haddr,trans.hrdata);
                check_success++;
             else 
                $display($time,"	Failed at Address : %0h , Data : %0h, Expected Data:%0h",trans.haddr,trans.hrdata, mem[trans.haddr]);
            end
          endcase
        end
      cg.sample(trans);
      trans.print_trans("[ScoreBoard]", '0);
      trans_count++;
    end
  endtask
endclass
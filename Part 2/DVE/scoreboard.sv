//Gets the packet from monitor, generates the expected result and compares with the actual result received from the Monitor
`include "coverage.sv"
class scoreboard;
	coverage cg;
  //create mailbox handle
	mailbox smb;
  // transaction track count
	int trans_count=0;
  // debug to monitor
  	bit debug;
  //array to use as local memory
  logic [7:0]  mem [1023];
  //constructor
  function new(input mailbox mbx, bit debug=0);
		this.smb = mbx;
    	this.debug = debug;
  endfunction
  //main method
    task main;
    transaction trans;
    cg  = new(1);
    for(int j=0;j<1023;j=j+1) 
    	mem[j]=j;
    forever begin: continous
      smb.get(trans); 
      if(trans.hsel) begin: selected
        if(trans.hresetn) begin: active
          if(trans.error) begin: error
            case({trans.hresp, trans.hready})
              2'b00: $display($time,": [ScoreBoard]| error could not be asserted, Transfer pending");
              2'b01: $display($time,": [ScoreBoard]| error could not be asserted, Successful transfer completed");
              2'b10: $display($time,": [ScoreBoard]| ERROR response, first cycle");
              2'b10: $display($time,": [ScoreBoard]| ERROR response, second cycle");
            endcase
          end: error
          else begin: normal
            case({trans.hresp, trans.hready})
              2'b00: if (debug) $display($time,": [ScoreBoard]| Transfer pending");
              2'b01: if (debug) $display($time,": [ScoreBoard]| Successful transfer completed");
              2'b10: if (debug) $display($time,": [ScoreBoard]| ERROR response, first cycle");
              2'b10: if (debug) $display($time,": [ScoreBoard]| ERROR response, second cycle");
            endcase
          end: normal
          if((trans.htrans == `H_NONSEQ || trans.htrans == `H_SEQ)&& trans.hwrite == 1) begin: write
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
          end: write

          else if((trans.htrans == `H_NONSEQ || trans.htrans == `H_SEQ)&& trans.hwrite == 1) begin: read
            case (trans.hsize)
              `H_SIZE_32: begin
                if({mem[trans.haddr+3],mem[trans.haddr+2],mem[trans.haddr+1],mem[trans.haddr]} == trans.hrdata)begin 
                  if (debug) $display($time,": [ScoreBoard]| The Data is Correct, Address : %0h , Data : %0h",trans.haddr,trans.hrdata); 
                end
                else 
                  $display($time,": [ScoreBoard]| Failed at Address : %0h , Data : %0h, Expected data: %0h",trans.haddr,trans.hrdata,{mem[trans.haddr+3],mem[trans.haddr+2],mem[trans.haddr+1],mem[trans.haddr]});
              end
              `H_SIZE_16: begin
                bit condtrue;
                case(trans.haddr[1])
                  0: condtrue = {mem[trans.haddr+1],mem[trans.haddr]} == trans.hrdata[15:0];
                  1: condtrue = {mem[trans.haddr+3],mem[trans.haddr+2]} == trans.hrdata[31:16];
                endcase
                if(condtrue)begin 
                  if (debug) $display($time,": [ScoreBoard]| The Data is Correct, Address : %0h , Data : %0h",trans.haddr,trans.hrdata); 
                end
                else 
                  $display($time,": [ScoreBoard]| Failed at Address : %0d , Data : %0h, Expected Data: %0h",trans.haddr,trans.hrdata, (trans.haddr[1]? {mem[trans.haddr+3],mem[trans.haddr+2]}: {mem[trans.haddr+1],mem[trans.haddr]}));
              end
              `H_SIZE_8: begin
                bit condtrue;
                case(trans.haddr[1:0])
                  0: condtrue = mem[trans.haddr]== trans.hrdata[7:0];
                  1: condtrue = mem[trans.haddr]== trans.hrdata[15:8];
                  2: condtrue = mem[trans.haddr]== trans.hrdata[23:16];
                  3: condtrue = mem[trans.haddr]== trans.hrdata[31:24];
                endcase
                if(condtrue) begin
                  if (debug) $display($time,": [ScoreBoard]| The Data is Correct, Address : %0h , Data : %0h",trans.haddr,trans.hrdata);
                end
                else 
                  $display($time,": [ScoreBoard]| Failed at Address : %0h , Data : %0h, Expected Data:%0h",trans.haddr,trans.hrdata, mem[trans.haddr]);
              end
            endcase
          end: read
        end: active
        else begin: reset
          $display($time,": [ScoreBoard]| Reset is asserted.......");
          for(int j=0;j<1023;j=j+1) 
    		mem[j]=j;
          if(~trans.hwrite & trans.htrans>1 )
            $display($time,": [ScoreBoard]| Reset is Successfull: %0s",((trans.hrdata==='x)? "TRUE": "FALSE"));
          else 
            $display($time,": [ScoreBoard]| Next read with same transaction must show reset memory.......");
        end: reset
      end: selected
      cg.sample(trans);
      trans.print_trans("[ScoreBoard]", debug);
      trans_count++;
    end: continous
  endtask
endclass

//Gets the packet from monitor, generates the expected result and compares with the actual result received from the Monitor
`include "coverage.sv"
class scoreboard;
	coverage cg;
  //create mailbox handle
	mailbox smb;
  // transaction track count
	int trans_count=0;
  	int trans_success=0;
  	int trans_failed=0;
  	int trans_idle=0;
  	int trans_busy=0;
  int count=0;
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
          if(trans.error) begin: error
            case({trans.hresp, trans.hready})
              2'b00: $display("[ScoreBoard]| error could not be asserted, Transfer pending");
              2'b01: $display("[ScoreBoard]| error could not be asserted, Successful transfer completed");
              2'b10: $display("[ScoreBoard]| ERROR response, first cycle"); 
              2'b11: $display("[ScoreBoard]| ERROR response, second cycle");
            endcase
          end: error
          else begin: normal
            case({trans.hresp, trans.hready})
              2'b00: if (debug) $display("[ScoreBoard]| Transfer pending");
              2'b01: if (debug) $display("[ScoreBoard]| Successful transfer completed");
              2'b10: if (debug) $display("[ScoreBoard]| ERROR response, first cycle");
              2'b11: if (debug) $display("[ScoreBoard]| ERROR response, second cycle");
            endcase
          end: normal
          if(trans.htrans== `H_IDLE) begin: idle
            trans_idle++;
            if(trans.hresp== `H_OKAY) begin
              if(debug) $display("[ScoreBoard]| Slave response is OKAY to an IDLE trans: LEGAL");
            end
            else 
              $display("[ScoreBoard]| Slave response is ERROR to an IDLE trans: ILLEGAL");
          end:idle
          if(trans.htrans== `H_BUSY) begin: busy
            trans_busy++;
            if(trans.hresp== `H_OKAY) begin
              if(debug) $display("[ScoreBoard]| Slave response is OKAY to an BUSY trans: LEGAL");
            end
            else 
              $display("[ScoreBoard]| Slave response is ERROR to an BUSY trans: ILLEGAL");
          end:busy
          
          if((trans.htrans == `H_NONSEQ || trans.htrans == `H_SEQ)&& trans.hresp== `H_OKAY && trans.hwrite == 1) begin: write
            if(trans.hready) trans_success++; else trans_failed++;
            case (trans.hsize)
              `H_SIZE_32: {mem[trans.haddr+3],mem[trans.haddr+2],mem[trans.haddr+1],mem[trans.haddr]} = trans.hwdata;
              `H_SIZE_16: 
                case(trans.haddr[1])
                  0: {mem[trans.haddr+1],mem[trans.haddr]} = trans.hwdata[15:0];
                  1: {mem[trans.haddr+1],mem[trans.haddr]} = trans.hwdata[31:16];
                endcase
              `H_SIZE_8:
                case(trans.haddr[1:0])
                  2'b00:mem[trans.haddr]= trans.hwdata[7:0]; 
                  2'b01:mem[trans.haddr]= trans.hwdata[15:8];
                  2'b10:mem[trans.haddr]= trans.hwdata[23:16];
                  2'b11:mem[trans.haddr]= trans.hwdata[31:24];
                endcase
            endcase
          end: write

          if((trans.htrans == `H_NONSEQ || trans.htrans == `H_SEQ)&& trans.hresp== `H_OKAY && trans.hwrite == 0) begin: read
            case (trans.hsize)
              `H_SIZE_32: begin
                if({mem[trans.haddr+3],mem[trans.haddr+2],mem[trans.haddr+1],mem[trans.haddr]} == trans.hrdata)begin
                  trans_success++;
                  if (debug) $display("[ScoreBoard]| The Data is Correct, Address : %0h , Data : %0h",trans.haddr,trans.hrdata); 
                end
                else begin
                  trans_failed++;
                  $display("[ScoreBoard]| Failed at Address : %0h , Data : %0h, Expected data: %0h",trans.haddr,trans.hrdata,{mem[trans.haddr+3],mem[trans.haddr+2],mem[trans.haddr+1],mem[trans.haddr]});
                end
              end
              `H_SIZE_16: begin
                bit condtrue;
                case(trans.haddr[1])
                  0: condtrue = {mem[trans.haddr+1],mem[trans.haddr]} == trans.hrdata[15:0];
                  1: condtrue = {mem[trans.haddr+1],mem[trans.haddr]} == trans.hrdata[31:16];
                endcase
                if(condtrue)begin
                  trans_success++;
                  if (debug) $display("[ScoreBoard]| The Data is Correct, Address : %0h , Data : %0h",trans.haddr,trans.hrdata); 
                end
                else begin
                  trans_failed++;
                  $display("[ScoreBoard]| Failed at Address : %0h , Data : %0h, Expected Data: %0h",trans.haddr,trans.hrdata,{mem[trans.haddr+1],mem[trans.haddr]}); 
                end
              end
              `H_SIZE_8: begin
                bit condtrue;
                case(trans.haddr[1:0])
                  2'b00: condtrue = mem[trans.haddr]== trans.hrdata[7:0];
                  2'b01: condtrue = mem[trans.haddr]== trans.hrdata[15:8];
                  2'b10: condtrue = mem[trans.haddr]== trans.hrdata[23:16];
                  2'b11: condtrue = mem[trans.haddr]== trans.hrdata[31:24];
                endcase
                if(condtrue) begin
                  trans_success++;
                  if (debug) $display("[ScoreBoard]| The Data is Correct, Address : %0h , Data : %0h",trans.haddr,trans.hrdata);
                end
                else begin
                  trans_failed++;
                  $display("[ScoreBoard]| Failed at Address : %0h , Data : %0h, Expected Data:%0h",trans.haddr,trans.hrdata, mem[trans.haddr]);
                end
              end
            endcase
          end: read
      end: selected
      cg.sample(trans);
      trans.print_trans("[ScoreBoard]", 0);
      trans_count++;
    end: continous
  endtask
endclass

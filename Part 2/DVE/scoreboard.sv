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
  // debug to monitor
  	bit debug;
  //array to use as local memory
  bit [7:0]  mem [1023];
  //constructor
  function new(input mailbox mbx, bit debug=0);
		this.smb = mbx;
    	this.debug = debug;
  endfunction
  //main method
  task main;
    transaction trans;
    cg  = new(1);
    for(int j=0;j<256;j=j+1) 
      mem[j]=j;
    forever begin: continous
      smb.get(trans); 
      if(trans.hsel) begin: selected
        if(trans.hresetn) begin: active
          
          if(trans.error) begin: error
            case({trans.hresp, trans.hready})
              2'b00: $error($time,": [ScoreBoard]| error could not be asserted, Transfer pending");
              2'b01: $error($time,": [ScoreBoard]| error could not be asserted, Successful transfer completed");
              2'b10: $display($time,": [ScoreBoard]| ERROR response, first cycle"); 
              2'b11: $display($time,": [ScoreBoard]| ERROR response, second cycle");
            endcase
          end: error
          else begin: normal
            case({trans.hresp, trans.hready})
              2'b00: if (debug) $display($time,": [ScoreBoard]| Transfer pending");
              2'b01: if (debug) $display($time,": [ScoreBoard]| Successful transfer completed");
              2'b10: if (debug) $display($time,": [ScoreBoard]| ERROR response, first cycle");
              2'b11: if (debug) $display($time,": [ScoreBoard]| ERROR response, second cycle");
            endcase
          end: normal
          
          if(trans.htrans== `H_IDLE) begin: idle
            trans_idle++;
            if(trans.hresp== `H_OKAY) begin
              if(debug) $display($time,": [ScoreBoard]| Slave response is OKAY to an IDLE trans: LEGAL");
            end
            else 
              $error($time,": [ScoreBoard]| Slave response is ERROR to an IDLE trans: ILLEGAL");
          end:idle
          
          if(trans.htrans== `H_BUSY) begin: busy
            trans_busy++;
            if(trans.hresp== `H_OKAY) begin
              if(debug) $display($time,": [ScoreBoard]| Slave response is OKAY to an BUSY trans: LEGAL");
            end
            else 
              $error($time,": [ScoreBoard]| Slave response is ERROR to an BUSY trans: ILLEGAL");
          end:busy
          
          if((trans.htrans == `H_NONSEQ || trans.htrans == `H_SEQ) && (trans.hresp==`H_OKAY) && (trans.hwrite==1)) begin: write
            if(trans.hready) 
            	trans_success++;
            else 
            	trans_failed++;
            unique case (trans.hsize)
              `H_SIZE_32: {mem[trans.haddr+3],mem[trans.haddr+2],mem[trans.haddr+1],mem[trans.haddr]} = trans.hwdata;
              `H_SIZE_16: begin
                unique case(trans.haddr[1])
                  0: {mem[trans.haddr+1],mem[trans.haddr]} = trans.hwdata[15:0]; 
                  1: {mem[trans.haddr+3],mem[trans.haddr+2]} = trans.hwdata[31:16];
                endcase
              end
              `H_SIZE_8: begin
                unique case(trans.haddr[1:0])
                  0:mem[trans.haddr]= trans.hwdata[7:0]; 
                  1:mem[trans.haddr]= trans.hwdata[15:8];
                  2:mem[trans.haddr]= trans.hwdata[23:16];
                  3:mem[trans.haddr]= trans.hwdata[31:24];
                endcase
              end
            endcase
          end: write

          if((trans.htrans == `H_NONSEQ || trans.htrans == `H_SEQ)&& (trans.hresp== `H_OKAY) && (trans.hwrite==0)) begin: read
            bit [`DW-1:0] expdata;
            unique case (trans.hsize)
              `H_SIZE_32: expdata = {mem[trans.haddr+3],mem[trans.haddr+2],mem[trans.haddr+1],mem[trans.haddr]};  
              `H_SIZE_16: begin
				unique case(trans.haddr[1])
                  0: expdata = {8'bx, 8'bx,   mem[trans.haddr+1], mem[trans.haddr]};
                  1: expdata = {mem[trans.haddr+3], mem[trans.haddr+2], 8'bx, 8'bx};
                endcase
              end
              `H_SIZE_8: begin
                unique case(trans.haddr[1:0])
                  0: expdata = {8'bx, 8'bx, 8'bx, mem[trans.haddr]};
                  1: expdata = {8'bx, 8'bx, mem[trans.haddr], 8'bx};
                  2: expdata = {8'bx, mem[trans.haddr], 8'bx, 8'bx};
                  3: expdata = {mem[trans.haddr], 8'bx, 8'bx, 8'bx};
                endcase
              end
            endcase
            if(expdata===trans.hrdata)begin
              trans_success++;
              if (debug) $display($time,": [ScoreBoard]| Passed at Address: %3h , Data : %8h",trans.haddr,trans.hrdata); 
            end
           	else begin
              trans_failed++;
              $error($time,": [ScoreBoard]| Failed at Address : %3h , Data : %8h, Expected data: %8h",trans.haddr,trans.hrdata,expdata);
            end
          end: read
        end: active
        else begin: reset
          $display($time,": [ScoreBoard]| Reset is asserted.......");
          for(int j=0;j<256;j=j+1) 
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

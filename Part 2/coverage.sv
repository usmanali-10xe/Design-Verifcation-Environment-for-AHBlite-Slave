class coverage;
  transaction trans;
  bit sel_cov;

  covergroup combinational_coverage;
    option.per_instance = 1;
    option.name = "combinational";
    select: coverpoint trans.hsel;
    addr:	coverpoint trans.haddr {
      illegal_bins	addr1 = {[(2**10):(2**20)-1]};
      illegal_bins	addr2 = {[(2**20):(2**31)-1]};
      bins 			addr[10]= {[0:(2**10)-1]};
    }
    transf: coverpoint trans.htrans {
      bins			transf[] = {`H_IDLE, `H_BUSY, `H_NONSEQ, `H_SEQ};
    }
    write:	coverpoint trans.hwrite;
    size:	coverpoint trans.hsize {
      bins			size[] = {[`H_SIZE_8:`H_SIZE_1024]};
    }
    burst:	coverpoint trans.hburst {
      bins			burst[]={[`H_SINGLE:`H_INCR16]};
    }
    prot:	coverpoint trans.hprot;
   	tresp:	coverpoint trans.hresp;
    tready: coverpoint trans.hready;
    all_cross: cross addr,transf,write,size,burst,prot,tresp,tready;
  endgroup

  covergroup transition_coverage;
  	option.per_instance = 1;
    option.name = "transitional";
    
    transf: coverpoint trans.htrans {
      bins			i2all[] = (`H_IDLE => `H_BUSY, `H_NONSEQ, `H_SEQ);
      bins			b2all[] = (`H_BUSY => `H_IDLE, `H_NONSEQ, `H_SEQ);
      bins			n2all[] = (`H_NONSEQ => `H_BUSY, `H_IDLE, `H_SEQ);
      bins			s2all[] = (`H_SEQ => `H_BUSY, `H_NONSEQ, `H_IDLE);
    }
    burst:	coverpoint trans.hburst {
      bins			single2burst[] = (`H_SINGLE=>[`H_INCR:`H_INCR16]);
      bins			burst2single[] = ([`H_INCR:`H_INCR16]=>`H_SINGLE);                       
    }
    slave_signalling:	coverpoint {trans.hresp,trans.hready}{
      bins 	error_cycels1 = (2'b01=>2'b10);
      bins  error_cycels2 = (2'b10 => 2'b11);
      bins  pending_to_success = (2'b00 => 2'b01);
    }
                    
  endgroup
  
  function new(input bit sel_cov=0);
    this.sel_cov = sel_cov;
    if(sel_cov) transition_coverage = new();
    combinational_coverage = new();      
  endfunction : new

  task sample(transaction trans);
	this.trans = trans;
    if(sel_cov) transition_coverage.sample();
    combinational_coverage.sample();
  endtask:sample

endclass

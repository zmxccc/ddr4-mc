module AXI2DDR #(
    parameter DATAWIDTH = 128,
    parameter IDWIDTH   = 3,
    parameter ADDRSIZE  = 34
) (
    //---------------- aw channel------------
    input                            awvalid,
    input   [IDWIDTH-1   :0]         awid,
    input   [ADDRWIDTH-1 :0]         awaddr,
    input   [7:0]                    awlen,
    input   [2:0]                    awsize,
    input   [1:0]                    awburst,
    output                           awready,
    //-----------------w channel--------------
    input                            wvalid,
    input   [DATAWIDTH-1    :0]      wdata,
    input   [DATA_WIDTH/8 -1:0]      wstrb,
    input                            wlast,
    output                           wready,

    //----------------B channel-------------
    input                            bready,
    output                           bvalid,
    output  [IDWIDTH-1   :0]         bid,
    output  [2:0]                    bresp,
    //---------------ar channel-----------
    input                            awvalid,
    input   [IDWIDTH-1   :0]         arid,
    input   [ADDRWIDTH-1 :0]         araddr,
    input   [7:0]                    arlen,
    input   [2:0]                    arsize,
    input   [1:0]                    arburst,
    output                           arready,
    //--------------r channel---------------
    input                            rvalid,
    output  [DATAWIDTH-1    :0]      rdata,
    output                           rlast,
    output                           rready,
    output  [IDWIDTH-1   :0]         rid,
    output  [2:0]                    rresp,

    //-----------
    input aclk,rst_n

);
    wire [7:0] number_bytes;
    wire [ADDRSIZE-1 :0] awaddr_r;
    wire [ADDRSIZE-1 :0] awaddr_N;


    fifo #( 
        .WIDTH(ADDRSIZE+IDWIDTH+8+3+2),
        .DEPTH(8)) 
    write_buffer(
		.clk(aclk), 
		.rst_n(rst_n),
		.winc(awvalid && awready),
		.rinc()	,
		.wdata({awid,awaddr,awlen,awsize,awburst}),
		.wfull(~awready),
		.rempty(),
		.rdata({awid_r,awaddr_r,awlen_r,awsize_r,awburst_r})
    )

	// Implement axi_awaddr latching

	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	      axi_awlen_cntr <= 0;
	      axi_awburst <= 0;
	      axi_awlen <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && ~axi_awv_awr_flag)
	        begin
	          // address latching 
	          axi_awaddr <= S_AXI_AWADDR[C_S_AXI_ADDR_WIDTH - 1:0];  
	           axi_awburst <= S_AXI_AWBURST; 
	           axi_awlen <= S_AXI_AWLEN;     
	          // start address of transfer
	          axi_awlen_cntr <= 0;
	        end   
	      else if((axi_awlen_cntr <= axi_awlen) && axi_wready && S_AXI_WVALID)        
	        begin

	          axi_awlen_cntr <= axi_awlen_cntr + 1;

	          case (axi_awburst)
	            2'b00: // fixed burst
	            // The write address for all the beats in the transaction are fixed
	              begin
	                axi_awaddr <= axi_awaddr;          
	                //for awsize = 4 bytes (010)
	              end   
	            2'b01: //incremental burst
	            // The write address for all the beats in the transaction are increments by awsize
	              begin
	                axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                //awaddr aligned to 4 byte boundary
	                axi_awaddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
	                //for awsize = 4 bytes (010)
	              end   
	            2'b10: //Wrapping burst
	            // The write address wraps when the address reaches wrap boundary 
	              if (aw_wrap_en)
	                begin
	                  axi_awaddr <= (axi_awaddr - aw_wrap_size); 
	                end
	              else 
	                begin
	                  axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                  axi_awaddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}}; 
	                end                      
	            default: //reserved (incremental burst for example)
	              begin
	                axi_awaddr <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;
	                //for awsize = 4 bytes (010)
	              end
	          endcase              
	        end
	    end 
	end 

endmodule
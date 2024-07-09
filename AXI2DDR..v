module AXI2DDR #(
    parameter DATAWIDTH = 128,
    parameter IDWIDTH   = 3,
    parameter ADDRSIZE  = 41,
	 
	parameter integer C_S_AXI_ID_WIDTH		= 2		,
		
	parameter integer C_S_AXI_DATA_WIDTH	= 128	,
	parameter integer C_S_AXI_ADDR_WIDTH	= 41		,
	
	parameter integer C_S_AXI_AWUSER_WIDTH	= 0		,
	parameter integer C_S_AXI_ARUSER_WIDTH	= 0		,
	parameter integer C_S_AXI_WUSER_WIDTH	= 0		,
	parameter integer C_S_AXI_RUSER_WIDTH	= 0		,
	parameter integer C_S_AXI_BUSER_WIDTH	= 0	
) 


	(
		input wire  S_AXI_ACLK,
		input wire  S_AXI_ARESETN,
		
		input 	wire [C_S_AXI_ID_WIDTH-1 : 0] 		S_AXI_AWID,
		input 	wire [C_S_AXI_ADDR_WIDTH-1 : 0] 	S_AXI_AWADDR,
		input 	wire [7 : 0] 						S_AXI_AWLEN,
		input 	wire [2 : 0] 						S_AXI_AWSIZE,
		input 	wire [1 : 0] 						S_AXI_AWBURST,
		input 	wire  								S_AXI_AWLOCK,
		input 	wire [3 : 0] 						S_AXI_AWCACHE,
		input 	wire [2 : 0] 						S_AXI_AWPROT,
		input 	wire [3 : 0] 						S_AXI_AWQOS,
		input 	wire [3 : 0] 						S_AXI_AWREGION,
		input 	wire [C_S_AXI_AWUSER_WIDTH-1 : 0] 	S_AXI_AWUSER,
		input 	wire  								S_AXI_AWVALID,
		output 	wire  								S_AXI_AWREADY,
		
		input 	wire [C_S_AXI_DATA_WIDTH-1 : 0] 	S_AXI_WDATA,
		input 	wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
		input 	wire  								S_AXI_WLAST,
		input 	wire [C_S_AXI_WUSER_WIDTH-1 : 0] 	S_AXI_WUSER,
		input 	wire  								S_AXI_WVALID,
		output 	wire  								S_AXI_WREADY,
		
		output 	wire [C_S_AXI_ID_WIDTH-1 : 0] 		S_AXI_BID,
		output 	wire [1 : 0] 						S_AXI_BRESP,
		output 	wire [C_S_AXI_BUSER_WIDTH-1 : 0] 	S_AXI_BUSER,
		output 	wire  								S_AXI_BVALID,
		input 	wire  								S_AXI_BREADY,
		
		input 	wire [C_S_AXI_ID_WIDTH-1 : 0] 		S_AXI_ARID,
		input 	wire [C_S_AXI_ADDR_WIDTH-1 : 0] 	S_AXI_ARADDR,
		input 	wire [7 : 0] 						S_AXI_ARLEN,
		input 	wire [2 : 0] 						S_AXI_ARSIZE,
		input 	wire [1 : 0] 						S_AXI_ARBURST,
		input 	wire  								S_AXI_ARLOCK,
		input 	wire [3 : 0] 						S_AXI_ARCACHE,
		input 	wire [2 : 0] 						S_AXI_ARPROT,
		input 	wire [3 : 0] 						S_AXI_ARQOS,
		input 	wire [3 : 0] 						S_AXI_ARREGION,
		input 	wire [C_S_AXI_ARUSER_WIDTH-1 : 0] 	S_AXI_ARUSER,
		input 	wire  								S_AXI_ARVALID,
		output 	wire  								S_AXI_ARREADY,
		
		output 	wire [C_S_AXI_ID_WIDTH-1 : 0] 		S_AXI_RID,
		output 	wire [C_S_AXI_DATA_WIDTH-1 : 0] 	S_AXI_RDATA,
		output 	wire [1 : 0] 						S_AXI_RRESP,	
		output 	wire  								S_AXI_RLAST,
		output 	wire [C_S_AXI_RUSER_WIDTH-1 : 0] 	S_AXI_RUSER,	
		output 	wire  								S_AXI_RVALID,
		input 	wire  								S_AXI_RREADY,

		//================     MC        ===============
		output 	wire								mc_wcmd_empty,
		output	wire [C_S_AXI_ADDR_WIDTH+2-1 : 0]	mc_wcmd_data,
		input	wire								mc_wcmd_req
	);

		// AXI4FULL signals
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	wire  							axi_awready;
	wire  							axi_wready;


	wire [1 : 0] 					axi_bresp;
	wire [C_S_AXI_BUSER_WIDTH-1 : 0]	axi_buser;
	wire  							axi_bvalid;
	wire [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	wire  							axi_arready;
	wire [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	wire [1 : 0] 					axi_rresp;
	wire  							axi_rlast;
	wire [C_S_AXI_RUSER_WIDTH-1 : 0]	axi_ruser;
	wire  							axi_rvalid;
	wire 							aw_wrap_en;
	wire 							ar_wrap_en;
	wire [31:0]  					aw_wrap_size ; 
	wire [31:0]  					ar_wrap_size ; 
	wire 							axi_awv_awr_flag;	// 拉高表示处于写过程
	wire 							axi_arv_arr_flag; 	// 拉高表示处于读过程
	
	// The axi_awlen_cntr internal write address counter to keep track of beats in a burst transaction
	wire [7:0] axi_awlen_cntr;	// 对 单次突发写 的个数计数
	wire [7:0] axi_arlen_cntr;	// 对 单次突发读 的个数计数
	wire [1:0] axi_arburst;
	wire [1:0] axi_awburst;
	wire [7:0] axi_arlen;
	wire [7:0] axi_awlen;
	wire [2:0] axi_awsize;
	wire [2:0] axi_arsize;
	wire [1:0] axi_awid;
	wire [1:0] axi_arid;
	wire [1:0] axi_bid;
	wire [1:0] axi_rid;



	//localparam integer ADDR_LSB = C_S_AXI_DATA_WIDTH/32;		// 低位地址的位宽，数据位宽32是4个BYTE，所以位宽为2；64则是8个BYTE，所以位宽为3
	//localparam integer OPT_MEM_ADDR_BITS = 3;						// 32位下的地址，总为6位减2后为4，这里取3是因为mem_address定义没减一
	//localparam integer USER_NUM_MEM = 1;
	//----------------------------------------------
	//-- Signals for intern signals
	//------------------------------------------------
	
	
	//aw cmdfifo



	//---------------------------------------
	//------output signals
	//---------------------------------
	// I/O Connections assignments
	assign S_AXI_AWREADY = axi_awready;
	assign S_AXI_WREADY	 = axi_wready;
	assign S_AXI_BRESP	 = axi_bresp;
	assign S_AXI_BUSER	 = axi_buser;
	assign S_AXI_BVALID	 = axi_bvalid;
	assign S_AXI_ARREADY = axi_arready;
	assign S_AXI_RDATA	 = axi_rdata;
	assign S_AXI_RRESP	 = axi_rresp;
	assign S_AXI_RLAST	 = axi_rlast;
	assign S_AXI_RUSER	 = axi_ruser;
	assign S_AXI_RVALID	 = axi_rvalid;


	//assign S_AXI_BID     = S_AXI_AWID;
	//assign S_AXI_RID     = S_AXI_ARID;
	
	assign aw_wrap_size  = (C_S_AXI_DATA_WIDTH/8 * (axi_awlen)); 
	assign ar_wrap_size  = (C_S_AXI_DATA_WIDTH/8 * (axi_arlen)); 
	assign aw_wrap_en    = ((axi_awaddr & aw_wrap_size) == aw_wrap_size)? 1'b1: 1'b0;
	assign ar_wrap_en    = ((axi_araddr & ar_wrap_size) == ar_wrap_size)? 1'b1: 1'b0;


	//--------------------------------------------------
	//------------------write address channel-----------
	//--------------------------------------------------




	//-----------awready--------
/*	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if (!S_AXI_ARESETN) begin
			axi_awready 		<= 1'b0;
			axi_awv_awr_flag 	<= 1'b0;
		end 
		else 
		begin
			if(~axi_awready && S_AXI_AWVALID && ~axi_awv_awr_flag && ~awcmd_full//??????????axi_arv_arr_flag?
			) begin
				axi_awready 		<= 1'b1;
				axi_awv_awr_flag	<= 1'b1;
		end
			else if(aw_wr)
				axi_awready			<= 1'b0;

			else if(S_AXI_WLAST && axi_wready )begin
				axi_awv_awr_flag	<= 1'b0;
		end 
			else 
				axi_awready			<= 1'b0;
		end
	end
	
*/
	//=========================
	//-------awaddr------------
	//=========================

	wire 			aw_done;
	wire			aw_done_r;
	wire 			axi_awvalid;
	wire [56-1 : 0] aw_data;
	wire [56-1 : 0] aw_data_r;
// 	size =addr 41+	2 +8 +3 +2 =56
	wire			aw_fifo_winc;



	assign aw_data 		=	{S_AXI_AWADDR,S_AXI_AWBURST,S_AXI_AWLEN,S_AXI_AWSIZE,S_AXI_AWID};
	assign axi_awready 	= 	((!( count_flag || aw_last_transfer)) || (axi_awlen == 8'b0) )&& ( !awcmd_full);
	//assign aw_fifo_winc =	 axi_awvalid & awwr_done;


	dffre awvalid_reg 
	(
		.clk(S_AXI_ACLK),
		.rst_n(S_AXI_ARESETN),
		.d(S_AXI_AWVALID),
		.en(axi_awready),
		.q(axi_awvalid)
	);
wire [55:0] aw_data_real;
//assign aw_data_real = aw_data & {56{last_transfer}};
	dffre #(
		.WIDTH ( 56)
	)awdata_reg
	(
		.clk(S_AXI_ACLK),
		.rst_n(S_AXI_ARESETN),
		.d(aw_data),
		.en(S_AXI_AWVALID && axi_awready),
		.q(aw_data_r)
	);
	
	assign	axi_awaddr	= aw_data_r[55 :15];
	assign	axi_awburst = aw_data_r[14 :13];
	assign	axi_awlen 	= aw_data_r[12 : 5];
	assign	axi_awsize 	= aw_data_r[4  : 2];
	assign	axi_awid 	= aw_data_r[1  : 0];

	wire count_flag;
	wire [7:0] axi_awlen_cntr_next;
	wire aw_start;
	dffre  #(
		. WIDTH ( 8)
	)
	axi_awlen_cntrreg
	(
		.clk(S_AXI_ACLK),
		.rst_n(S_AXI_ARESETN),
		.d(axi_awlen_cntr_next),
		.en((count_flag || aw_last_transfer) && (!awcmd_full) ),
		.q(axi_awlen_cntr)
	);
	assign aw_start = S_AXI_AWVALID && axi_awready;
	/*
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if ( S_AXI_ARESETN == 1'b0 ) begin
			aw_start <= 1'b0;
	    end 
		else 
			aw_start <= S_AXI_AWVALID && axi_awready;
	end*/
/*
	dffre1  #(
		.WIDTH (1)
	)
	aw_donereg
	(
		.clk(S_AXI_ACLK),
		.rst_n(S_AXI_ARESETN),
		.d(aw_done),
		.en(last_transfer ),
		.q(aw_done_r)
	);*/
	//assign aw_done = !(S_AXI_AWVALID && axi_awready);
	assign count_flag 		= (axi_awlen_cntr < axi_awlen );
	assign last_transfer 	= (axi_awlen_cntr == axi_awlen);

	assign axi_awlen_cntr_next = count_flag ? axi_awlen_cntr + 1'b1 : 8'h0 ;
	//assign aw_done =  last_transfer ? 1'b1: 1'b0;
	reg aw_last_transfer;
	always @(posedge S_AXI_ACLK or negedge S_AXI_ARESETN) begin
		if ( S_AXI_ARESETN == 1'b0 ) begin
			aw_last_transfer <= 1'b0;
	    end 
		else if ((axi_awlen != 8'b0 ) && (axi_awlen_cntr_next == axi_awlen))
		begin
			aw_last_transfer <= 1'b1;

		end
		else 
			aw_last_transfer <= 1'b0;
end

    wire [7:0] number_bytes;
	wire [41-1:0] Aligned_Address;
    //wire [ADDRSIZE-1 :0] awaddr_r;
    //wire [ADDRSIZE-1 :0] awaddr_N;
	reg [ADDRSIZE-1 :0] axi_awaddr_r;
	assign number_bytes = 8'b1 << axi_awsize; 
	//assign offset = ~(Number_Bytes - 1);
    assign Aligned_Address = { {axi_awaddr[41-1:8]},{axi_awaddr[7:0] & (~(number_bytes-1'b1))    } } ;

//??????????????????????????????????????????????????????????????????

	always @( posedge S_AXI_ACLK or negedge S_AXI_ARESETN )
	
		if ( S_AXI_ARESETN == 1'b0 ) begin
			axi_awaddr_r<= 'd0;
	    end 
		else if((count_flag || aw_start || aw_last_transfer) &&  ~awcmd_full)  begin	
			
				// 写握手完成，且 写入的个数小于最大值 
				if (aw_start) begin
					axi_awaddr_r <= Aligned_Address;
				end
		//		axi_awlen_cntr <= axi_awlen_cntr + 1;		// 则对写入个数+1
				else 
				begin
					case (axi_awburst)			// 地址要根据突发模式而定
					2'b00: 					// fixed 模式，地址不变
						begin
							axi_awaddr_r <= axi_awaddr_r;   //for awsize = 4 bytes        	                
						end   
					2'b01: 					// incremental模式，地址递增（awsize(010)），即地址递增4
						begin
							//axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;	// 高位+1						
							//axi_awaddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};
							axi_awaddr_r <=  axi_awaddr_r	+   number_bytes;														
						end   
					2'b10: 					// Wrapping模式，过界了就从头开始				
						if (aw_wrap_en)
							begin
								axi_awaddr_r <= (axi_awaddr_r - aw_wrap_size); 	// 过界了就从头开始
							end
							else begin
								//axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;// 高位+1		
								//axi_awaddr[ADDR_LSB - 1:0]  <= {ADDR_LSB{1'b0}};                                               // 低位保持不变
								axi_awaddr_r <=  Aligned_Address	+   number_bytes;														
														
															
							end                      
					default: 				// 保留模式，实际上是不使用的
						begin
							axi_awaddr_r <=  Aligned_Address	+   number_bytes;									
						end
				endcase
				end              
	        end
	//    end 
	asynfifo #(
		.DSIZE(43),
        .ASIZE(4)
	) wcmd_fifo
	(
		.winc(aw_last_transfer || count_flag ),.wclk(S_AXI_ACLK),.wrst_n(S_AXI_ARESETN),
		.rinc(mc_rcmd_req),.rclk(mc_clk),.rrst_n(S_AXI_ARESETN),
		.wfull(awcmd_full),
		.wdata({axi_awid,axi_awaddr_r}),
		.rdata(mc_wcmd_data),
		.rempty(mc_wcmd_empty)

	);


	//=========================
	//-------aw data------------
	//=========================
/*


	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 )
	    	begin
	      		axi_wready <= 1'b0;
	    	end 
	  	else
	    	begin    
	      		if ( ~axi_wready && S_AXI_WVALID && axi_awv_awr_flag)
	        		begin
	          // slave can accept the write data
	          			axi_wready <= 1'b1;
	        		end
	      //else if (~axi_awv_awr_flag)
	      		else if (S_AXI_WLAST && axi_wready)
	        		begin
	          			axi_wready <= 1'b0;
	        		end
	    	end 
		end       */



endmodule
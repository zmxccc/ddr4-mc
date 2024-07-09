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
		input wire 	mc_clk,

		
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
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  							axi_awready;
	reg  							axi_wready;
	reg [1 : 0] 					axi_bresp;
	reg [C_S_AXI_BUSER_WIDTH-1 : 0]	axi_buser;
	reg  							axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  							axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 					axi_rresp;
	reg  							axi_rlast;
	reg [C_S_AXI_RUSER_WIDTH-1 : 0]	axi_ruser;
	reg  							axi_rvalid;
	wire 							aw_wrap_en;
	wire 							ar_wrap_en;
	wire [31:0]  					aw_wrap_size ; 
	wire [31:0]  					ar_wrap_size ; 
	reg 							axi_awv_awr_flag;	// 拉高表示处于写过程
	reg 							axi_arv_arr_flag; 	// 拉高表示处于读过程
	
	// The axi_awlen_cntr internal write address counter to keep track of beats in a burst transaction
	reg [7:0] axi_awlen_cntr;	// 对 单次突发写 的个数计数
	reg [7:0] axi_arlen_cntr;	// 对 单次突发读 的个数计数
	reg [1:0] axi_arburst;
	reg [1:0] axi_awburst;
	reg [7:0] axi_arlen;
	reg [7:0] axi_awlen;
	reg [C_S_AXI_ID_WIDTH-1 :0] axi_awid;
	reg [C_S_AXI_ID_WIDTH-1 :0] axi_arid;

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
//	assign S_AXI_BID     = S_AXI_AWID;
//	assign S_AXI_RID     = S_AXI_ARID;
	
	assign aw_wrap_size  = (C_S_AXI_DATA_WIDTH/8 * (axi_awlen)); 
	assign ar_wrap_size  = (C_S_AXI_DATA_WIDTH/8 * (axi_arlen)); 
	assign aw_wrap_en    = ((axi_awaddr & aw_wrap_size) == aw_wrap_size)? 1'b1: 1'b0;
	assign ar_wrap_en    = ((axi_araddr & ar_wrap_size) == ar_wrap_size)? 1'b1: 1'b0;


	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;	
	//=========================
	//-------awaddr------------
	//=========================




	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 ) begin
			axi_awready <= 1'b0;
			axi_awv_awr_flag <= 1'b0;
	    end 
		else begin    
			if (~axi_awready && S_AXI_AWVALID && ~axi_awv_awr_flag ) begin
				axi_awready <= 1'b1;
				axi_awv_awr_flag  <= 1'b1; 
	        end
			else if (S_AXI_WLAST && axi_wready) begin
				axi_awv_awr_flag  <= 1'b0;
	        end
			else begin
				axi_awready <= 1'b0;
	        end
	    end 
	end


	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 ) begin
			axi_awaddr <= 0;
			axi_awlen_cntr <= 0;
			axi_awburst <= 0;
			axi_awlen <= 0;
	    end 
	  else begin    
			if (~axi_awready && S_AXI_AWVALID && ~axi_awv_awr_flag) begin	// 下个周期会握手完成，同时也把主机发过来的地址等信息锁存起来
				axi_awaddr <= S_AXI_AWADDR[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB]; 
				axi_awburst <= S_AXI_AWBURST; 
				axi_awlen <= S_AXI_AWLEN;     
				axi_awlen_cntr <= 0;
				axi_awid <= S_AXI_AWID;
	        end   
			else if((axi_awlen_cntr <= axi_awlen) && axi_wready && S_AXI_WVALID)  begin		// 写握手完成，且 写入的个数小于最大值 
				axi_awlen_cntr <= axi_awlen_cntr + 1;										// 则对写入个数+1

				case (axi_awburst)			// 地址要根据突发模式而定
					2'b00: 					// fixed 模式，地址不变
						begin
							axi_awaddr <= axi_awaddr;   //for awsize = 4 bytes        	                
						end   
					2'b01: 					// incremental模式，地址递增（awsize(010)），即地址递增4
						begin
							axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;	// 高位+1						
							axi_awaddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   												// 低位保持不变							
						end   
					2'b10: 					// Wrapping模式，过界了就从头开始				
						if (aw_wrap_en)
							begin
								axi_awaddr <= (axi_awaddr - aw_wrap_size); 	// 过界了就从头开始
							end
							else begin
								axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;// 高位+1		
								axi_awaddr[ADDR_LSB - 1:0]  <= {ADDR_LSB{1'b0}};                                               // 低位保持不变
							end                      
					default: 				// 保留模式，实际上是不使用的
						begin
							axi_awaddr <= axi_awaddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1;//for awsize = 4 bytes (010) 									
						end
				endcase              
	        end
	    end 
	end 

	asynfifo #(
		.DSIZE(43),
        .ASIZE(4)
	) wcmd_fifo
	(
		.winc(axi_wready && S_AXI_WVALID ),.wclk(S_AXI_ACLK),.wrst_n(S_AXI_ARESETN),
		.rinc(mc_rcmd_req),.rclk(mc_clk),.rrst_n(S_AXI_ARESETN),
		.wfull(awcmd_full),
		.wdata({axi_awid,axi_awaddr}),
		.rdata(mc_wcmd_data),
		.rempty(mc_wcmd_empty)

	);

	//=========================
	//-------awdata------------
	//=========================


	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 ) begin
			axi_wready <= 1'b0;
	    end 
		else begin    
			if ( ~axi_wready && S_AXI_WVALID && axi_awv_awr_flag) begin	// 当主机发送 S_AXI_WVALID，且axi_wready无效，且处于 写过程时，拉高 axi_wready
				axi_wready <= 1'b1;
	        end
			else if (S_AXI_WLAST && axi_wready) begin					// 当写完最后一个数后，拉低 axi_wready
				axi_wready <= 1'b0;
	        end
	    end 
	end 


	wire wdata_full;


	asynfifo #(
		.DSIZE(128),
        .ASIZE(4)
	) wdata_fifo
	(
		.winc(axi_wready && S_AXI_WVALID ),.wclk(S_AXI_ACLK),.wrst_n(S_AXI_ARESETN),
		.rinc(mc_wdata_req),.rclk(mc_clk),.rrst_n(S_AXI_ARESETN),
		.wfull(wdata_full),
		.wdata(S_AXI_WDATA),
		.rdata(mc_wdata),
		.rempty(mc_wdata_empty)

	);
	//=========================
	//-------wresp------------
	//=========================

	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 ) begin
			axi_bvalid <= 0;
			axi_bresp <= 2'b0;
			axi_buser <= 0;
	    end 
		else begin
			// 处于写过程中的写最后一个数是即可提前拉高 axi_bvalid
			if (axi_awv_awr_flag && axi_wready && S_AXI_WVALID && ~axi_bvalid && S_AXI_WLAST ) begin
				axi_bvalid <= 1'b1;
				axi_bresp  <= 2'b0; 	// 'OKAY' response 
				
	        end                   
			else begin
				if (S_AXI_BREADY && axi_bvalid) begin	// 写响应握手完成后就拉低 axi_bvalid 
					axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end 


	//=========================
	//------------araddr
	//=========================

	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 ) begin
			axi_arready <= 1'b0;
			axi_arv_arr_flag <= 1'b0;
	    end 
		else begin    
			if (~axi_arready && S_AXI_ARVALID && ~axi_awv_awr_flag && ~axi_arv_arr_flag) begin
				axi_arready <= 1'b1;
				axi_arv_arr_flag <= 1'b1;
	        end
			else if (axi_rvalid && S_AXI_RREADY && axi_arlen_cntr == axi_arlen) begin
				axi_arv_arr_flag  <= 1'b0;
	        end
			else begin
				axi_arready <= 1'b0;
	        end
	    end 
	end


	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 ) begin
			axi_araddr <= 0;
			axi_arlen_cntr <= 0;
			axi_arburst <= 0;
			axi_arlen <= 0;
			axi_rlast <= 1'b0;
			axi_ruser <= 0;
	    end 
		else begin    
			if (~axi_arready && S_AXI_ARVALID && ~axi_arv_arr_flag) begin	// 下个周期会握手完成，同时也把主机发过来的地址等信息锁存起来
				axi_araddr <= S_AXI_ARADDR[C_S_AXI_ADDR_WIDTH - 1:0]; 
				axi_arburst <= S_AXI_ARBURST; 
				axi_arlen <= S_AXI_ARLEN;     
				axi_arlen_cntr <= 0;
				axi_rlast <= 1'b0;
				axi_arid <=S_AXI_ARID;
	        end   
			else if((axi_arlen_cntr <= axi_arlen) && axi_rvalid && S_AXI_RREADY) begin	      // 读握手完成，且 读出的个数小于最大值    
				axi_arlen_cntr <= axi_arlen_cntr + 1;                                         // 则对读出个数+1
				axi_rlast <= 1'b0;	        
				case (axi_arburst)
					2'b00: 
						begin
							axi_araddr <= axi_araddr;        
						end   
					2'b01: 
						begin
							axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1; 
							axi_araddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
						end   
					2'b10: 
						if (ar_wrap_en) begin
							axi_araddr <= (axi_araddr - ar_wrap_size); 
						end
						else begin
							axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB] + 1; 
							axi_araddr[ADDR_LSB-1:0]  <= {ADDR_LSB{1'b0}};   
	                end                      
					default: 
						begin
							axi_araddr <= axi_araddr[C_S_AXI_ADDR_WIDTH - 1:ADDR_LSB]+1;
						end
				endcase              
	        end
			else if((axi_arlen_cntr == axi_arlen) && ~axi_rlast && axi_arv_arr_flag ) begin	// 拉高 axi_rlast 表明是读出的最后一个数据
				axi_rlast <= 1'b1;
	        end          
			else if (S_AXI_RREADY) begin													// 等到主机响应后拉低 axi_rlast
				axi_rlast <= 1'b0;
	        end          
	    end 
	end 	
wire arcmd_full;
	asynfifo #(
		.DSIZE(43),
        .ASIZE(4)
	) rcmd_fifo
	(
		.winc(axi_arready && S_AXI_ARVALID ),.wclk(S_AXI_ACLK),.wrst_n(S_AXI_ARESETN),
		.rinc(mc_rcmd_req),.rclk(mc_clk),.rrst_n(S_AXI_ARESETN),
		.wfull(arcmd_full),
		.wdata({axi_arid,axi_araddr}),
		.rdata(mc_rcmd_data),
		.rempty(mc_rcmd_empty)

	);
	//=========================
	//------------r data
	//=========================

	always @( posedge S_AXI_ACLK )
	begin
		if ( S_AXI_ARESETN == 1'b0 ) begin
			axi_rvalid <= 0;
			axi_rresp  <= 0;
	    end 
		else begin  	
			if (axi_arv_arr_flag && ~axi_rvalid) begin	// 处于读过程且自身不为高就拉高 axi_rvalid
				axi_rvalid <= 1'b1;
				axi_rresp  <= 2'b0; 					// 'OKAY' response	          
	        end   
			else if (axi_rvalid && S_AXI_RREADY) begin	// 握手完成后拉低 axi_rvalid
				axi_rvalid <= 1'b0;
	        end            
	    end
	end

endmodule
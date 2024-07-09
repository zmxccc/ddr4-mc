`timescale 1ns / 1ps 
/*------------------------------------------------
Testbench file made by VerilogTestbenchGen.py
------------------------------------------------*/


module tb();
    parameter DATAWIDTH = 128;
    parameter IDWIDTH   = 3;
    parameter ADDRSIZE  = 41;
	 
	parameter integer C_S_AXI_ID_WIDTH		= 2		;
		
	parameter integer C_S_AXI_DATA_WIDTH	= 128	;
	parameter integer C_S_AXI_ADDR_WIDTH	= 41		;
	
	parameter integer C_S_AXI_AWUSER_WIDTH	= 0		;
	parameter integer C_S_AXI_ARUSER_WIDTH	= 0		;
	parameter integer C_S_AXI_WUSER_WIDTH	= 0		;
	parameter integer C_S_AXI_RUSER_WIDTH	= 0		;
	parameter integer C_S_AXI_BUSER_WIDTH	= 0	;
reg                 S_AXI_ACLK;
reg                 S_AXI_ARESETN;
reg  [C_S_AXI_ID_WIDTH-1 : 0]S_AXI_AWID;
reg  [C_S_AXI_ADDR_WIDTH-1 : 0]S_AXI_AWADDR;
reg  [7 : 0]        S_AXI_AWLEN;
reg  [2 : 0]        S_AXI_AWSIZE;
reg  [1 : 0]        S_AXI_AWBURST;
reg                 S_AXI_AWLOCK;
reg  [3 : 0]        S_AXI_AWCACHE;
reg  [2 : 0]        S_AXI_AWPROT;
reg  [3 : 0]        S_AXI_AWQOS;
reg  [3 : 0]        S_AXI_AWREGION;
reg  [C_S_AXI_AWUSER_WIDTH-1 : 0]S_AXI_AWUSER;
reg                 S_AXI_AWVALID;
wire                S_AXI_AWREADY;
reg  [C_S_AXI_DATA_WIDTH-1 : 0]S_AXI_WDATA;
reg  [(C_S_AXI_DATA_WIDTH/8)-1 : 0]S_AXI_WSTRB;
reg                 S_AXI_WLAST;
reg  [C_S_AXI_WUSER_WIDTH-1 : 0]S_AXI_WUSER;
reg                 S_AXI_WVALID;
wire                S_AXI_WREADY;
wire [C_S_AXI_ID_WIDTH-1 : 0]S_AXI_BID;
wire [1 : 0]        S_AXI_BRESP;
wire [C_S_AXI_BUSER_WIDTH-1 : 0]S_AXI_BUSER;
wire                S_AXI_BVALID;
reg                 S_AXI_BREADY;
reg  [C_S_AXI_ID_WIDTH-1 : 0]S_AXI_ARID;
reg  [C_S_AXI_ADDR_WIDTH-1 : 0]S_AXI_ARADDR;
reg  [7 : 0]        S_AXI_ARLEN;
reg  [2 : 0]        S_AXI_ARSIZE;
reg  [1 : 0]        S_AXI_ARBURST;
reg                 S_AXI_ARLOCK;
reg  [3 : 0]        S_AXI_ARCACHE;
reg  [2 : 0]        S_AXI_ARPROT;
reg  [3 : 0]        S_AXI_ARQOS;
reg  [3 : 0]        S_AXI_ARREGION;
reg  [C_S_AXI_ARUSER_WIDTH-1 : 0]S_AXI_ARUSER;
reg                 S_AXI_ARVALID;
wire                S_AXI_ARREADY;
wire [C_S_AXI_ID_WIDTH-1 : 0]S_AXI_RID;
wire [C_S_AXI_DATA_WIDTH-1 : 0]S_AXI_RDATA;
wire [1 : 0]        S_AXI_RRESP;
wire                S_AXI_RLAST;
wire [C_S_AXI_RUSER_WIDTH-1 : 0]S_AXI_RUSER;
wire                S_AXI_RVALID;
reg                 S_AXI_RREADY;
wire                mc_wcmd_empty;
wire [C_S_AXI_ADDR_WIDTH+2-1 : 0]mc_wcmd_data;
reg                 mc_wcmd_req;


initial
begin
	S_AXI_ACLK    ='d0;
	S_AXI_ARESETN ='d0;
	S_AXI_AWID    ='d0;
	S_AXI_AWADDR  ='d0;
	S_AXI_AWLEN   ='d0;
	S_AXI_AWSIZE  ='d0;
	S_AXI_AWBURST ='d0;
	S_AXI_AWLOCK  ='d0;
	S_AXI_AWCACHE ='d0;
	S_AXI_AWPROT  ='d0;
	S_AXI_AWQOS   ='d0;
	S_AXI_AWREGION='d0;
	S_AXI_AWUSER  ='d0;
	S_AXI_AWVALID ='d0;
	S_AXI_WDATA   ='d0;
	S_AXI_WSTRB   ='d0;
	S_AXI_WLAST   ='d0;
	S_AXI_WUSER   ='d0;
	S_AXI_WVALID  ='d0;
	S_AXI_BREADY  ='d0;
	S_AXI_ARID    ='d0;
	S_AXI_ARADDR  ='d0;
	S_AXI_ARLEN   ='d0;
	S_AXI_ARSIZE  ='d0;
	S_AXI_ARBURST ='d0;
	S_AXI_ARLOCK  ='d0;
	S_AXI_ARCACHE ='d0;
	S_AXI_ARPROT  ='d0;
	S_AXI_ARQOS   ='d0;
	S_AXI_ARREGION='d0;
	S_AXI_ARUSER  ='d0;
	S_AXI_ARVALID ='d0;
	S_AXI_RREADY  ='d0;
	mc_wcmd_req   ='d0;
end


AXI2DDR inst_AXI2DDR
(
	.S_AXI_ACLK(S_AXI_ACLK),     // input
	.S_AXI_ARESETN(S_AXI_ARESETN),// input
	.S_AXI_AWID(S_AXI_AWID),     // input [C_S_AXI_ID_WIDTH-1 : 0]
	.S_AXI_AWADDR(S_AXI_AWADDR), // input [C_S_AXI_ADDR_WIDTH-1 : 0]
	.S_AXI_AWLEN(S_AXI_AWLEN),   // input [7 : 0]
	.S_AXI_AWSIZE(S_AXI_AWSIZE), // input [2 : 0]
	.S_AXI_AWBURST(S_AXI_AWBURST),// input [1 : 0]
	.S_AXI_AWLOCK(S_AXI_AWLOCK), // input
	.S_AXI_AWCACHE(S_AXI_AWCACHE),// input [3 : 0]
	.S_AXI_AWPROT(S_AXI_AWPROT), // input [2 : 0]
	.S_AXI_AWQOS(S_AXI_AWQOS),   // input [3 : 0]
	.S_AXI_AWREGION(S_AXI_AWREGION),// input [3 : 0]
	.S_AXI_AWUSER(S_AXI_AWUSER), // input [C_S_AXI_AWUSER_WIDTH-1 : 0]
	.S_AXI_AWVALID(S_AXI_AWVALID),// input
	.S_AXI_AWREADY(S_AXI_AWREADY),// output
	.S_AXI_WDATA(S_AXI_WDATA),   // input [C_S_AXI_DATA_WIDTH-1 : 0]
	.S_AXI_WSTRB(S_AXI_WSTRB),   // input [(C_S_AXI_DATA_WIDTH/8)-1 : 0]
	.S_AXI_WLAST(S_AXI_WLAST),   // input
	.S_AXI_WUSER(S_AXI_WUSER),   // input [C_S_AXI_WUSER_WIDTH-1 : 0]
	.S_AXI_WVALID(S_AXI_WVALID), // input
	.S_AXI_WREADY(S_AXI_WREADY), // output
	.S_AXI_BID(S_AXI_BID),       // output [C_S_AXI_ID_WIDTH-1 : 0]
	.S_AXI_BRESP(S_AXI_BRESP),   // output [1 : 0]
	.S_AXI_BUSER(S_AXI_BUSER),   // output [C_S_AXI_BUSER_WIDTH-1 : 0]
	.S_AXI_BVALID(S_AXI_BVALID), // output
	.S_AXI_BREADY(S_AXI_BREADY), // input
	.S_AXI_ARID(S_AXI_ARID),     // input [C_S_AXI_ID_WIDTH-1 : 0]
	.S_AXI_ARADDR(S_AXI_ARADDR), // input [C_S_AXI_ADDR_WIDTH-1 : 0]
	.S_AXI_ARLEN(S_AXI_ARLEN),   // input [7 : 0]
	.S_AXI_ARSIZE(S_AXI_ARSIZE), // input [2 : 0]
	.S_AXI_ARBURST(S_AXI_ARBURST),// input [1 : 0]
	.S_AXI_ARLOCK(S_AXI_ARLOCK), // input
	.S_AXI_ARCACHE(S_AXI_ARCACHE),// input [3 : 0]
	.S_AXI_ARPROT(S_AXI_ARPROT), // input [2 : 0]
	.S_AXI_ARQOS(S_AXI_ARQOS),   // input [3 : 0]
	.S_AXI_ARREGION(S_AXI_ARREGION),// input [3 : 0]
	.S_AXI_ARUSER(S_AXI_ARUSER), // input [C_S_AXI_ARUSER_WIDTH-1 : 0]
	.S_AXI_ARVALID(S_AXI_ARVALID),// input
	.S_AXI_ARREADY(S_AXI_ARREADY),// output
	.S_AXI_RID(S_AXI_RID),       // output [C_S_AXI_ID_WIDTH-1 : 0]
	.S_AXI_RDATA(S_AXI_RDATA),   // output [C_S_AXI_DATA_WIDTH-1 : 0]
	.S_AXI_RRESP(S_AXI_RRESP),   // output [1 : 0]
	.S_AXI_RLAST(S_AXI_RLAST),   // output
	.S_AXI_RUSER(S_AXI_RUSER),   // output [C_S_AXI_RUSER_WIDTH-1 : 0]
	.S_AXI_RVALID(S_AXI_RVALID), // output
	.S_AXI_RREADY(S_AXI_RREADY) , // input
	.mc_wcmd_empty(),// output
	.mc_wcmd_data(), // output [C_S_AXI_ADDR_WIDTH+2-1 : 0]
	.mc_wcmd_req()    // input
);
initial begin

	#10
	S_AXI_ARESETN = 1'b1;
@(negedge S_AXI_ACLK)begin		
			S_AXI_AWVALID = 1'b1;
			S_AXI_AWADDR  = 'd0;
			S_AXI_AWLEN = 3'b011;
			S_AXI_AWSIZE = 3'b100;
			S_AXI_AWBURST = 2'b01;
		//	data_in <= $random;	//生成8位随机数
		end
@(negedge S_AXI_ACLK)begin	
			S_AXI_AWVALID = 1'b0;

end
	end

//------------<设置时钟>----------------------------------------------
always #10 S_AXI_ACLK = ~S_AXI_ACLK;			//读时钟周期20ns
 
initial
begin
$dumpfile("wave.vcd");
$dumpvars(0, tb);
#1000 $finish();
end


endmodule
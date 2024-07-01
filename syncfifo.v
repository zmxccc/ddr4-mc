module fifo#(
	parameter	WIDTH = 8,
	parameter 	DEPTH = 16
)(
	input 					clk		, 
	input 					rst_n	,
	input 					winc	,
	input 			 		rinc	,
	input 		[WIDTH-1:0]	wdata	,

	output reg				wfull	,
	output reg				rempty	,
	output wire [WIDTH-1:0]	rdata
);

localparam DP_WD = $clog2(DEPTH);

reg  [DP_WD   :0]waddr;
wire             wenc;
wire             waddr_d_h;
wire [DP_WD -1:0]waddr_d_l;
assign wenc = winc & (!wfull);
assign waddr_d_h = (waddr[DP_WD-1:0] == DEPTH-1) ? ~waddr[DP_WD] : waddr[DP_WD];
assign waddr_d_l = (waddr[DP_WD-1:0] == DEPTH-1) ? 0 : waddr[DP_WD-1:0] + 1;
always @(posedge clk or negedge rst_n)begin
	if(~rst_n)    waddr <= 0;
	else if(wenc) waddr <= {waddr_d_h, waddr_d_l};
end

reg  [DP_WD   :0]raddr;
wire             renc;
wire             raddr_d_h;
wire [DP_WD -1:0]raddr_d_l;
assign renc = rinc & (!rempty);
assign raddr_d_h = (raddr[DP_WD-1:0] == DEPTH-1) ? ~raddr[DP_WD] : raddr[DP_WD];
assign raddr_d_l = (raddr[DP_WD-1:0] == DEPTH-1) ? 0 : raddr[DP_WD-1:0] + 1;
always @(posedge clk or negedge rst_n)begin
	if(~rst_n)    raddr <= 0;
	else if(renc) raddr <= {raddr_d_h, raddr_d_l};
end

wire [DP_WD :0]fifo_cnt = (waddr[DP_WD] == raddr[DP_WD]) ? waddr[DP_WD-1:0] - raddr[DP_WD-1:0]:
				          (waddr[DP_WD-1:0] + DEPTH - raddr[DP_WD-1:0]);

wire [DP_WD :0]fifo_cnt_d = (waddr_d_h == raddr_d_h) ? waddr_d_l[DP_WD-1:0] - raddr_d_l[DP_WD-1:0]:
				            (waddr_d_l[DP_WD-1:0] + DEPTH - raddr_d_l[DP_WD-1:0]);

wire rempty = (fifo_cnt == 0);
always @(posedge clk or negedge rst_n)begin
	if(~rst_n)    rempty <= 0;
	else if(rinc) rempty <= rempty_d;
end

wire wfull = (fifo_cnt == DEPTH);
always @(posedge clk or negedge rst_n)begin
	if(~rst_n)    wfull <= 0;
	else if(winc) wfull <= wfull_d;
end

dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH))
u_ram (
	.wclk	(clk),
	.wenc	(wenc),
	.waddr	(waddr),
	.wdata	(wdata),
	.rclk	(clk),
	.renc	(renc),
	.raddr	(raddr),
	.rdata	(rdata)
);

endmodule
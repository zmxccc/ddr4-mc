module hand_fifo #(
	parameter DEPTH = 2,
	parameter WIDTH = 128
)(
	input 				clk,
	input 				rst_n,
	
	input  			    in_valid,
	input  [WIDTH -1:0] in_data,
	output 			    in_ready,
	
	output			    out_valid,
	output [WIDTH -1:0] out_data,
	input  			    out_ready
);

localparam DP_WD = DEPTH == 1 ? 1 : $clog2(DEPTH);

//==================================================================
//写入计数器
//==================================================================
reg  [DP_WD   :0]waddr;
wire             wenc;
wire             waddr_d_h;
wire [DP_WD -1:0]waddr_d_l;
assign wenc = in_valid && in_ready;
assign waddr_d_h = (waddr[DP_WD-1:0] == DEPTH-1) ? ~waddr[DP_WD] : waddr[DP_WD];
assign waddr_d_l = (waddr[DP_WD-1:0] == DEPTH-1) ? 0 : waddr[DP_WD-1:0] + 1;
always @(posedge clk or negedge rst_n)begin
	if(~rst_n)    waddr <= 0;
	else if(wenc) waddr <= {waddr_d_h, waddr_d_l};
end

//==================================================================
//读出计数器
//==================================================================
reg  [DP_WD   :0]raddr;
wire             renc;
wire             raddr_d_h;
wire [DP_WD -1:0]raddr_d_l;
assign renc = out_valid && out_ready;
assign raddr_d_h = (raddr[DP_WD-1:0] == DEPTH-1) ? ~raddr[DP_WD] : raddr[DP_WD];
assign raddr_d_l = (raddr[DP_WD-1:0] == DEPTH-1) ? 0 : raddr[DP_WD-1:0] + 1;
always @(posedge clk or negedge rst_n)begin
	if(~rst_n)    raddr <= 0;
	else if(renc) raddr <= {raddr_d_h, raddr_d_l};
end

//==================================================================
//深度计数器
//==================================================================
reg  [DP_WD :0]fifo_cnt_q;
wire [DP_WD :0]waddr_d = wenc ? {waddr_d_h, waddr_d_l} : waddr;
wire [DP_WD :0]raddr_d = renc ? {raddr_d_h, raddr_d_l} : raddr;
wire [DP_WD :0]fifo_cnt_d = (waddr_d[DP_WD] == raddr_d[DP_WD]) ? (waddr_d[DP_WD-1:0] - raddr_d[DP_WD-1:0]):
															     (waddr_d[DP_WD-1:0] + DEPTH - raddr_d[DP_WD-1:0]);
wire fifo_cnt_en = (wenc ^ renc);
always @(posedge clk or negedge rst_n)begin
	if(~rst_n)    fifo_cnt_q <= 0;
	else if(fifo_cnt_en) fifo_cnt_q <= fifo_cnt_d;
end

//==================================================================
//数据寄存
//==================================================================
reg [WIDTH -1:0]data[DEPTH -1:0];
always @(posedge clk)begin
	if(wenc) data[waddr[DP_WD-1:0]] <= in_data;
end
assign out_data = data[raddr[DP_WD-1:0]];

//==================================================================
//对外逻辑
//==================================================================
//assign in_ready  = (fifo_cnt_q < DEPTH);
//assign out_valid = (fifo_cnt_q > {DP_WD{1'b0}});

wire in_ready_en;
wire in_ready_d;
reg  in_ready_q;
assign in_ready_en = (out_valid && out_ready) || in_ready;
assign in_ready_d  = (fifo_cnt_d < DEPTH);
always @(posedge clk or negedge rst_n)begin
	if(~rst_n)          in_ready_q <= 1;
	else if(in_ready_en)in_ready_q <= in_ready_d;
end


wire out_valid_en;
wire out_valid_d;
reg  out_valid_q;
assign out_valid_en = (in_valid && in_ready) || out_valid;
assign out_valid_d  = (fifo_cnt_d > {DP_WD{1'b0}});
always @(posedge clk or negedge rst_n)begin
	if(~rst_n)           out_valid_q <= 0;
	else if(out_valid_en)out_valid_q <= out_valid_d;
end

assign in_ready  = in_ready_q;
assign out_valid = out_valid_q;

endmodule
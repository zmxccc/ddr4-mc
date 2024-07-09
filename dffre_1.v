module dffre1#(
	parameter WIDTH = 1
)(
	input 					clk,
	input 					rst_n,
	input  	[WIDTH -1:0]	d,
	input					en,
	output reg[WIDTH -1:0]	q
);
always @(posedge clk or negedge rst_n)begin
	if(~rst_n)  q <= {WIDTH{1'b1}};
	else if(en) q <= d;
end
endmodule

`timescale 1ns/1ns	//时间单位/精度
 
//------------<模块及端口声明>----------------------------------------
module tb();
 
parameter   DATA_WIDTH = 8  ;		//FIFO位宽
parameter   DATA_DEPTH = 3 ;		//FIFO深度
 
reg							wr_clk		;				//写时钟
reg							wr_rst_n	;       		//低电平有效的写复位信号
reg							wr_en		;       		//写使能信号，高电平有效	
reg	[DATA_WIDTH-1:0]		data_in		;       		//写入的数据
 
reg							rd_clk		;				//读时钟
reg							rd_rst_n	;       		//低电平有效的读复位信号
reg							rd_en		;				//读使能信号，高电平有效						                                        
wire[DATA_WIDTH-1:0]		data_out	;				//输出的数据					
wire						empty		;				//空标志，高电平表示当前FIFO已被写满
wire						full		;               //满标志，高电平表示当前FIFO已被读空
 
//------------<例化被测试模块>----------------------------------------
fifo
#(
	.DSIZE	(DATA_WIDTH),			//FIFO位宽
    .ASIZE	(3)			//FIFO深度
)
async_fifo_inst(
	.wclk		(wr_clk		),
	.wrst_n 	(wr_rst_n	),
	.winc		(wr_en		),
	.wdata	    (data_in	),	
	.rclk		(rd_clk		),               
	.rrst_n	    (rd_rst_n	),	
	.rinc		(rd_en		),	
	.rdata	    (data_out	),
	
	.rempty		(empty		),		
	.wfull		(full		)
);

//------------<设置初始测试条件>----------------------------------------
initial begin
	rd_clk = 1'b0;					//初始时钟为0
	wr_clk = 1'b0;					//初始时钟为0
	wr_rst_n <= 1'b0;				//初始复位
	rd_rst_n <= 1'b0;				//初始复位
	wr_en <= 1'b0;
	rd_en <= 1'b0;	
	data_in <= 'd0;
	#5
	wr_rst_n <= 1'b1;				
	rd_rst_n <= 1'b1;					
//重复8次写操作，让FIFO写满 	
	repeat(8) begin
		@(negedge wr_clk)begin		
			wr_en <= 1'b1;
			data_in <= $random;	//生成8位随机数
		end
	end
//拉低写使能	
	@(negedge wr_clk)	wr_en <= 1'b0;
	
//重复8次读操作，让FIFO读空 	
	repeat(8) begin
		@(negedge rd_clk)rd_en <= 1'd1;		
	end
//拉低读使能
	@(negedge rd_clk)rd_en <= 1'd0;		
//重复4次写操作，写入4个随机数据	
	repeat(4) begin
		@(negedge wr_clk)begin		
			wr_en <= 1'b1;
			data_in <= $random;	//生成8位随机数
		end
	end
//持续同时对FIFO读
	@(negedge rd_clk)rd_en <= 1'b1;
//持续同时对FIFO写，写入数据为随机数据	
	forever begin
		@(negedge wr_clk)begin		
			wr_en <= 1'b1;
			data_in <= $random;	//生成8位随机数
		end
	end	
 
end
 
//------------<设置时钟>----------------------------------------------
always #10 rd_clk = ~rd_clk;			//读时钟周期20ns
always #20 wr_clk = ~wr_clk;			//写时钟周期40ns
 
initial
begin
$dumpfile("wave.vcd");
$dumpvars(0, tb);
#2000 $finish();
end



endmodule

module asynfifo #(parameter DSIZE = 8,// FIFO 内数据位宽
               parameter ASIZE = 4) // FIFO 地址宽度
  (output  [DSIZE-1 : 0]  rdata,    // 输出数据线
    output                 wfull,    // 队满信号
    output                 rempty,   // 队空信号
    input   [DSIZE-1 : 0]  wdata,    // 输入信号线
    input                  winc, wclk, wrst_n, //写使能、时钟、复位
    input                  rinc, rclk, rrst_n); //读使能、时钟、复位
   
    wire  [ASIZE-1 : 0]  waddr, raddr; //由时钟域逻辑电路生成的二进制地址
    wire  [ASIZE : 0]    wptr, rptr, wq2_rptr, rq2_wptr; //本地读写指针、同步读写指针
 
    // 同步模块，r2w 即 read to write ，会把读指针同步到写时钟域 
    sync_r2w #(ASIZE)  sync_r2w (.wq2_rptr(wq2_rptr), .rptr(rptr),
                         .wclk(wclk), .wrst_n(wrst_n));
 
    // 同步模块，w2r 即 write to read ，会把写指针同步到读时钟域
    sync_w2r  #(ASIZE) sync_w2r (.rq2_wptr(rq2_wptr), .wptr(wptr),
                         .rclk(rclk), .rrst_n(rrst_n));
 
    // 存储模块，伪双口 ram 或寄存器模拟的伪双口 ram
    fifomem #(DSIZE, ASIZE)  fifomem
                             (.rdata(rdata), .wdata(wdata),
                              .waddr(waddr), .raddr(raddr),
                              .wclken(winc), .wfull(wfull),
                              .wclk(wclk));
 
    // 读时钟域逻辑电路，生成格雷码指针、地址和队空信号
    rptr_empty #(ASIZE)  rptr_empty
                         (.rempty(rempty),
                          .raddr(raddr),
                          .rptr(rptr), .rq2_wptr(rq2_wptr),
                          .rinc(rinc), .rclk(rclk),
                          .rrst_n(rrst_n));
 
    // 写时钟域逻辑电路，生成格雷码指针、地址和队满信号
    wptr_full #(ASIZE)  wptr_full
                        (.wfull(wfull), .waddr(waddr),
                         .wptr(wptr), .wq2_rptr(wq2_rptr),
                         .winc(winc), .wclk(wclk),
                         .wrst_n(wrst_n));
endmodule


/* 存储器模块 */ 
module fifomem # (parameter DATASIZE = 8, // 数据位宽
                  parameter ADDRSIZE = 4) // 地址宽度
   (output  [DATASIZE-1 : 0]  rdata,
    input   [DATASIZE-1 : 0]  wdata,
    input   [ADDRSIZE-1 : 0]  waddr, raddr,
    input                     wclken, wfull, wclk);
    

      // RTL 模型模拟   
      localparam DEPTH = 1<<ADDRSIZE;          // FIFO深度是2^4
      reg  [DATASIZE-1 : 0] mem [0 : DEPTH-1]; // 定义16个8位寄存器
      assign  rdata = mem[raddr];
      always @(posedge wclk)
         if (wclken && !wfull) 
            mem[waddr] <= wdata; //使能有效且不满，则写
endmodule


module sync_r2w # (parameter ADDRSIZE = 4) 
   (output reg  [ADDRSIZE : 0]  wq2_rptr, // 同步指针，注意是 n+1 位
    input       [ADDRSIZE : 0]  rptr,     // n+1 位格雷码指针
    input                       wclk, wrst_n);

    reg         [ADDRSIZE : 0]  wq1_rptr; // 二级同步器的第一级输出
 
    always @(posedge wclk or negedge wrst_n)
        if (!wrst_n) {wq2_rptr,wq1_rptr} <= 0;
        else         {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr}; //二级同步器移位
endmodule

module sync_w2r # (parameter ADDRSIZE = 4)
   (output reg  [ADDRSIZE : 0]  rq2_wptr,  // 同步指针，注意是 n+1 位
    input       [ADDRSIZE : 0]  wptr,      // n+1 位格雷码指针
    input                       rclk, rrst_n);

    reg  [ADDRSIZE : 0]  rq1_wptr; // 二级同步器的第一级输出
    
    always @(posedge rclk or negedge rrst_n)
       if (!rrst_n) {rq2_wptr,rq1_wptr} <= 0;
       else         {rq2_wptr,rq1_wptr} <= {rq1_wptr,wptr}; // 二级同步器移位
endmodule


/* 读时钟域逻辑电路 */
module rptr_empty # (parameter ADDRSIZE = 4)// FIFO 深度 16
   (output reg                    rempty,   //队空
    output      [ADDRSIZE-1 : 0]  raddr,    // n 位地址
    output reg  [ADDRSIZE : 0]    rptr,     // n+1 本地读指针
    input       [ADDRSIZE : 0]    rq2_wptr, //同步过来的写指针
    input                         rinc, rclk, rrst_n);

    reg         [ADDRSIZE : 0]    rbin; //二进制码
    wire        [ADDRSIZE : 0]    rgraynext, rbinnext; 
    wire rempty_val;
   //--------------------------------------------------------
   // 地址、格雷码指针生成逻辑，使用 6.4 节中更优风格的电路
   //--------------------------------------------------------
   always @(posedge rclk or negedge rrst_n)
       if (!rrst_n) {rbin, rptr} <= 0;
       else         {rbin, rptr} <= {rbinnext, rgraynext};

   assign raddr     = rbin[ADDRSIZE-1:0]; //n+1二进制码的低n位可以直接用来寻址
   assign rbinnext  = rbin + (rinc & ~rempty); //使能且不空时，地址递增
   assign rgraynext = (rbinnext>>1) ^ rbinnext; //二进制码转格雷码
   //--------------------------------------------------------------
   // 队空信号生成，若同步写指针和本地读指针全部n+1位相等，则队空
   //--------------------------------------------------------------
   assign rempty_val = (rgraynext == rq2_wptr);
   always @(posedge rclk or negedge rrst_n)
      if (!rrst_n) rempty <= 1'b1;
      else         rempty <= rempty_val;
endmodule
/* 写时钟域逻辑电路 */
module wptr_full # (parameter ADDRSIZE = 4) // FIFO 深度 16
   (output reg                    wfull, // 队满
    output      [ADDRSIZE-1 : 0]  waddr, // n 位写地址
    output reg  [ADDRSIZE : 0]    wptr,  // n+1 位格雷码写指针 
    input       [ADDRSIZE : 0]    wq2_rptr, // 同步读指针
    input                         winc, wclk, wrst_n);
   
    reg  [ADDRSIZE : 0]  wbin;
    wire [ADDRSIZE : 0]  wgraynext, wbinnext;
    //--------------------------------------------------------
    // 地址、格雷码指针生成逻辑，使用 6.4 节中更优风格的电路
    //--------------------------------------------------------
    always @(posedge wclk or negedge wrst_n)
       if (!wrst_n) {wbin, wptr} <= 0;
       else         {wbin, wptr} <= {wbinnext, wgraynext};

    assign waddr     =   wbin[ADDRSIZE-1:0];      // n+1 位二进制码的低 n 位可以直接寻址
    assign wbinnext  =   wbin + (winc & ~wfull);  // 使能有效且不满时，地址递增
    assign wgraynext =  (wbinnext>>1) ^ wbinnext; // 二进制码转格雷码模块
    //------------------------------------------------------
    // 队满信息生成，比较逻辑：MSB和2nd MSB相反，其余位相等
    //------------------------------------------------------
    assign wfull_val = (wgraynext == {~wq2_rptr[ADDRSIZE:ADDRSIZE-1],
                                       wq2_rptr[ADDRSIZE-2:0]});
    always @(posedge wclk or negedge wrst_n)
       if (!wrst_n) wfull <= 1'b0;
       else         wfull <= wfull_val;
endmodule
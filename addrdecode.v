module addrdecode #(
    parameters
) (
    input   [IDWIDTH-1   :0]         awid,
    input   [ADDRWIDTH-1 :0]         awaddr,
    input   [7:0]                    awlen,
    input   [2:0]                    awsize,
    input   [1:0]                    awburst,
    output                           de_ready,
    output  [addr]
);
    
endmodule
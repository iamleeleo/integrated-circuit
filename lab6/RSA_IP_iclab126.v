//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : RSA_IP.v
//   Module Name : RSA_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module RSA_IP #(parameter WIDTH = 3) (
    // Input signals
    IN_P, IN_Q, IN_E,
    // Output signals
    OUT_N, OUT_D
);

// ===============================================================
// Declaration
// ===============================================================
input  [WIDTH-1  :0] IN_P, IN_Q;
input  [WIDTH*2-1:0] IN_E;
output [WIDTH*2-1:0] OUT_N, OUT_D;

// ===============================================================
// Soft IP DESIGN
// ===============================================================
genvar g;
integer i;

wire signed[WIDTH*2:0]n[0:(WIDTH*3)*3+9];
reg  signed[WIDTH*2:0]ans;
wire [(WIDTH*3):0]cond;
wire [WIDTH*2-1:0]a  = (IN_P-1)*(IN_Q-1);
wire [WIDTH*2-1:0]b  = IN_E;


assign n[0] = a / b;
assign n[1] = a % b;
assign n[2] = -n[0];

assign n[3] = b / n[1];
assign n[4] = b % n[1];
assign n[5] = (1 - n[2] * n[3]);


generate 
	if(WIDTH==4)begin:if1
		for(g=0;g < 4;g=g+1)begin : eud
			assign n[6+g*3] = n[1+g*3] / n[4+g*3];
			assign n[7+g*3] = n[1+g*3] % n[4+g*3];
			assign n[8+g*3] = n[2+g*3] - n[5+g*3] * n[6+g*3];
		end
	end
	else begin:else1
		for(g=0;g < (WIDTH*3);g=g+1)begin : eud
			assign n[6+g*3] = n[1+g*3] / n[4+g*3];
			assign n[7+g*3] = n[1+g*3] % n[4+g*3];
			assign n[8+g*3] = n[2+g*3] - n[5+g*3] * n[6+g*3];
		end
	end
endgenerate


generate
	assign cond[0] = 0;
	for (g = 0; g < (WIDTH*3); g = g + 1) begin : U
		assign cond[g + 1] = (n[1+g*3]==1) & ~|cond[g:0];
	end
endgenerate



always@* begin
	ans = n[(WIDTH*3)*3+2];
	for(i=0;i< (WIDTH*3);i=i+1)begin
		if(cond[i+1]==1)ans = n[2+i*3];
	end
end

assign OUT_D = (ans > 0) ? (ans) : (a + ans);
assign OUT_N = a + IN_P + IN_Q - 1;

endmodule
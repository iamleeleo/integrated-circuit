`include "AFIFO.v"

module CDC #(parameter DSIZE = 8,
			   parameter ASIZE = 4)(
	//Input Port
	rst_n,
	clk1,
    clk2,
	in_valid,
	in_account,
	in_A,
	in_T,

    //Output Port
	ready,
    out_valid,
	out_account
); 
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
integer i;

input 				rst_n, clk1, clk2, in_valid;
input [DSIZE-1:0] 	in_account,in_A,in_T;

output reg				out_valid;
output wire ready;
output reg [DSIZE-1:0] 	out_account;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------


//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------

wire rinc,winc;
wire rempty_A  ,wfull_A;
wire rempty_T  ,wfull_T;
wire rempty_acc,wfull_acc;

wire [DSIZE-1:0]out_data_A;
wire [DSIZE-1:0]out_data_T;
wire [DSIZE-1:0]out_data_acc;
AFIFO u_AFIFO_A(
    .rclk(clk2),
    .rinc(rinc),
    .rempty(rempty_A),
	.wclk(clk1),
    .winc(winc),
    .wfull(wfull_A),
    .rst_n(rst_n),
    .rdata(out_data_A),
    .wdata(in_A)
    );

AFIFO u_AFIFO_T(
    .rclk(clk2),
    .rinc(rinc),
    .rempty(rempty_T),
	.wclk(clk1),
    .winc(winc),
    .wfull(wfull_T),
    .rst_n(rst_n),
    .rdata(out_data_T),
    .wdata(in_T)
    );
	
AFIFO u_AFIFO_acc(
    .rclk(clk2),
    .rinc(rinc),
    .rempty(rempty_acc),
	.wclk(clk1),
    .winc(winc),
    .wfull(wfull_acc),
    .rst_n(rst_n),
    .rdata(out_data_acc),
    .wdata(in_account)
    );


wire [7:0]next_processing_acc;
wire [2:0]big[0:2];

reg [DSIZE-1:0]processing_acc[0:4];
reg [2*DSIZE-1:0]mul_reuslt[0:4];	
reg [11:0]out_cnt;


assign winc = in_valid;
assign rinc = !rempty_A;
assign ready= !wfull_A && rst_n;


assign big[0] = (mul_reuslt[0] <= mul_reuslt[1] ? 0 : 1);
assign big[1] = (mul_reuslt[2] <= mul_reuslt[3] ? 2 : 3);
assign big[2] = (mul_reuslt[big[0]] <= mul_reuslt[big[1]] ? big[0] : big[1]);
assign next_processing_acc= (mul_reuslt[big[2]] <= mul_reuslt[4] ? processing_acc[big[2]] : processing_acc[4]);


always@(posedge clk2 or negedge rst_n)begin
	if(!rst_n)
	begin
		for(i=0;i<5;i=i+1)mul_reuslt[i]<=0;
		for(i=0;i<5;i=i+1)processing_acc[i]<=0;
	end
	else
	begin
		if(rinc)begin
			mul_reuslt[0]<=out_data_A*out_data_T;
			processing_acc[0]<=out_data_acc;
			for(i=1;i<5;i=i+1)begin
				mul_reuslt[i]<=mul_reuslt[i-1];
				processing_acc[i]<=processing_acc[i-1];
			end
		end
	end
end
always@(posedge clk2 or negedge rst_n)begin
	if(!rst_n)
	begin
		out_cnt<=0;
	end
	else
	begin
		if(rinc)
			out_cnt<=out_cnt+1;
		else if(out_cnt==4000)
			out_cnt<= 0;
	end
end


always@(posedge clk2 or negedge rst_n)begin
	if(!rst_n)
	begin
		out_valid<=0;
		out_account<=0;
	end
	else
	begin
		if(out_cnt>4 && rinc || out_cnt==4000)
		begin
			out_valid<=1;
			out_account<=next_processing_acc;
		end
		else
		begin
			out_valid<=0;
			out_account<=0;
		end		
	end
end


endmodule
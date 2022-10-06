//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : RSA_TOP.v
//   Module Name : RSA_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "RSA_IP.v"
//synopsys translate_on

module RSA_TOP (
    // Input signals
    clk, rst_n, in_valid,
    in_p, in_q, in_e, in_c,
    // Output signals
    out_valid, out_m
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [3:0] in_p, in_q;
input [7:0] in_e, in_c;
output reg out_valid;
output reg [7:0] out_m;

// ===============================================================
// Parameter & Integer Declaration
// ===============================================================
wire [7:0] OUT_N, OUT_D;
wire [7:0]N,D; 


reg [3:0]reg_in_p,reg_in_q;
reg [7:0]reg_in_e,reg_in_c;

reg first;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		first<=0;
	end
	else begin
		if(in_valid)
			first<=1;
		else 
			first<=0;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		reg_in_p<=0;
		reg_in_q<=0;
		reg_in_e<=0;
		reg_in_c<=0;
	end
	else 
	begin
		if(!first && in_valid)begin
			reg_in_p<=in_p;
			reg_in_q<=in_q;
			reg_in_e<=in_e;
			reg_in_c<=in_c;
		end
		else begin
			reg_in_c<=in_c;
		end
	end
end


RSA_IP #(.WIDTH(4)) KEY(.IN_P(reg_in_p),.IN_Q(reg_in_q),.IN_E(reg_in_e),.OUT_N(N),.OUT_D(D));





//pipeline stage 0 //
reg [7:0]N_0,D_0,C_0;
wire [16:0]pow_of2_tmp;
wire [7:0]pow_of2;
reg [7:0]ans_0;
wire [7:0]next_ans_1;
wire [7:0]next_ans_1_tmp;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		N_0<=0;
		D_0<=0;
		C_0<=0;
		ans_0<=1;
	end
	else 
	begin
		N_0<=N;
		D_0<=D;
		C_0<=reg_in_c;
		ans_0<=1;
	end
end
assign pow_of2_tmp = ((C_0*C_0));
assign pow_of2 = pow_of2_tmp % N_0;

assign next_ans_1_tmp = (C_0 * ans_0);
assign next_ans_1 = (D_0[0] ? (next_ans_1_tmp)%N_0 : ans_0);


//pipeline stage 1 //
reg [7:0]N_1,D_1,C_1;
reg [7:0]ans_1;
wire [7:0]next_ans_2;
wire [15:0]next_ans_2_tmp;
wire [15:0]pow_of4_tmp;
wire [7:0]pow_of4;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		N_1<=0;
		D_1<=0;
		C_1<=0;
		ans_1<=0;
	end
	else begin
		N_1<=N_0;
		D_1<=D_0;
		C_1<=pow_of2;
		ans_1<=next_ans_1;
	end
end
assign pow_of4_tmp = C_1*C_1;
assign pow_of4     = pow_of4_tmp%N_1;
assign next_ans_2_tmp = (C_1 * ans_1);
assign next_ans_2 = (D_1[1] ? (next_ans_2_tmp)%N_1 : ans_1);


//pipeline stage 2 //
reg [7:0]N_2,D_2,C_2;
reg [7:0]ans_2;
wire [7:0]next_ans_3;
wire [15:0]next_ans_3_tmp;
wire [7:0]pow_of8;
wire [15:0]pow_of8_tmp;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		N_2<=0;
		D_2<=0;
		C_2<=0;
		ans_2<=0;
	end
	else begin
		N_2<=N_1;
		D_2<=D_1;
		C_2<=pow_of4;
		ans_2<=next_ans_2;
	end
end
assign pow_of8_tmp = C_2*C_2;
assign pow_of8     = pow_of8_tmp%N_2;
assign next_ans_3_tmp = (C_2 * ans_2);
assign next_ans_3 = (D_2[2] ? (next_ans_3_tmp)%N_2 : ans_2);



//pipeline stage 3 //
reg [7:0]N_3,D_3,C_3;
reg [7:0]ans_3;
wire [7:0]next_ans_4;
wire [15:0]next_ans_4_tmp;
wire [7:0]pow_of16;
wire [15:0]pow_of16_tmp;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		N_3<=0;
		D_3<=0;
		C_3<=0;
		ans_3<=0;
	end
	else begin
		N_3<=N_2;
		D_3<=D_2;
		C_3<=pow_of8;
		ans_3<=next_ans_3;
	end
end
assign pow_of16_tmp = C_3*C_3;
assign pow_of16     = pow_of16_tmp%N_3;
assign next_ans_4_tmp = (C_3 * ans_3);
assign next_ans_4 = (D_3[3] ?next_ans_4_tmp%N_3 : ans_3);


//pipeline stage 4 //
reg [7:0]N_4,D_4,C_4;
reg [7:0]ans_4;
wire [7:0]next_ans_5;
wire [15:0]next_ans_5_tmp;
wire [7:0]pow_of32;
wire [15:0]pow_of32_tmp;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		N_4<=0;
		D_4<=0;
		C_4<=0;
		ans_4<=0;
	end
	else begin
		N_4<=N_3;
		D_4<=D_3;
		C_4<=pow_of16;
		ans_4<=next_ans_4;
	end
end
assign pow_of32_tmp = (C_4*C_4);
assign pow_of32     = (pow_of32_tmp)%N_4;
assign next_ans_5_tmp = C_4 * ans_4;
assign next_ans_5 = (D_4[4] ? (next_ans_5_tmp)%N_4 : ans_4);


//pipeline stage 5 //
reg [7:0]N_5,D_5,C_5;
reg [7:0]ans_5;
wire [7:0]next_ans_6;
wire [15:0]next_ans_6_tmp;
wire [15:0]pow_of64_tmp;
wire [7:0]pow_of64;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		N_5<=0;
		D_5<=0;
		C_5<=0;
		ans_5<=0;
	end
	else begin
		N_5<=N_4;
		D_5<=D_4;
		C_5<=pow_of32;
		ans_5<=next_ans_5;
	end
end
assign pow_of64_tmp = (C_5*C_5);
assign pow_of64 = (pow_of64_tmp)%N_5;
assign next_ans_6_tmp = (C_5 * ans_5);
assign next_ans_6 = (D_5[5] ? (next_ans_6_tmp)%N_5 : ans_5);

//pipeline stage 6 //
reg [7:0]N_6,D_6,C_6;
reg [7:0]ans_6;
reg [7:0]out_buf;
wire [7:0]next_ans_7;
wire [15:0]next_ans_7_tmp;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		N_6<=0;
		D_6<=0;
		C_6<=0;
		ans_6<=0;
	end
	else begin
		N_6<=N_5;
		D_6<=D_5;
		C_6<=pow_of64;
		ans_6<=next_ans_6;
	end
end
assign next_ans_7_tmp = (C_6 * ans_6);
assign next_ans_7 = (D_6[6] ? (next_ans_7_tmp)%N_6 : ans_6);


//pipeline stage 7 //
reg [4:0]out_cnt;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_cnt<=0;
	end
	else begin
		if(in_valid && out_cnt<7)
			out_cnt<=out_cnt+1;
		else if(!in_valid &&out_cnt>0)
			out_cnt<=out_cnt-1;
	end
end


reg out_ok;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_ok<=0;
	end
	else begin
		if(!out_ok)begin
			if(out_cnt==7)out_ok<=1;
		end
		else begin
			if(out_cnt==0)out_ok<=0;
		end
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_valid<=0;
	end
	else begin
		if(out_ok)begin
			out_valid<=1;
		end
		else begin
			out_valid<=0;
		end
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_m<=0;
	end
	else begin
		if(out_ok)begin
			out_m<=next_ans_7;
		end
		else begin
			out_m<=0;
		end
	end
end


//================================================================
// Wire & Reg Declaration
//================================================================


//================================================================
// DESIGN
//================================================================



endmodule


module NN(
	// Input signals
	clk,
	rst_n,
	in_valid_i,
	in_valid_k,
	in_valid_o,
	Image1,
	Image2,
	Image3,
	Kernel1,
	Kernel2,
	Kernel3,
	Opt,
	// Output signals
	out_valid,
	out
);
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 1;
parameter inst_arch = 2;
parameter img_size=4;

parameter IDLE    = 2'd0;
parameter INPUT = 2'd1;
parameter CALCULATE = 2'd2;
parameter OUTPUT = 2'd3;

integer i,j;
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input  clk, rst_n, in_valid_i, in_valid_k, in_valid_o;
input [inst_sig_width+inst_exp_width:0] Image1, Image2, Image3;
input [inst_sig_width+inst_exp_width:0] Kernel1, Kernel2, Kernel3;
input [1:0] Opt;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//////////for input/////////
reg [1:0]op;//store input opt
reg [inst_sig_width+inst_exp_width:0]img1[3:0][3:0],img2[3:0][3:0],img3[3:0][3:0];//store input image
reg [inst_sig_width+inst_exp_width:0]kl[2:0][35:0]; //store input kernel
reg [1:0]img_input_idx1;
reg [1:0]img_input_idx2;
reg [6:0]kernel_input_idx;


///////////for control//////////////
wire [1:0]cmr;//current middle row;
wire [1:0]cmc;//current middle column;
wire pad_str = op[1];//padding strategy 0 is dupicate,1 is zero;
wire [inst_sig_width+inst_exp_width:0]sw1_0,sw1_1,sw1_2,sw1_3,sw1_4,sw1_5,sw1_6,sw1_7,sw1_8; //value of each slide windows
wire [inst_sig_width+inst_exp_width:0]sw2_0,sw2_1,sw2_2,sw2_3,sw2_4,sw2_5,sw2_6,sw2_7,sw2_8; //value of each slide windows
wire [inst_sig_width+inst_exp_width:0]sw3_0,sw3_1,sw3_2,sw3_3,sw3_4,sw3_5,sw3_6,sw3_7,sw3_8; //value of each slide windows
wire [1:0] sw_0r,sw_0c,sw_1r,sw_1c,sw_2r,sw_2c,sw_3r,sw_3c,sw_4r,sw_4c,sw_5r,sw_5c,sw_6r,sw_6c,sw_7r,sw_7c,sw_8r,sw_8c;
wire [4:0]dis;
wire [5:0]k0,k1,k2,k3,k4,k5,k6,k7,k8;
wire gt;//wheather x is >0
reg [1:0]ks;//kernel select
reg [2:0]pp_cnt;


//////////for calculation///////////
wire [2:0]round=3'b000;
wire [inst_sig_width+inst_exp_width:0]add_tmp0,add_tmp1,mul_out,x,div_out,exp_out; 
wire [inst_sig_width+inst_exp_width:0]add_tmp2,add_tmp3,add_tmp4,add_tmp5,mul_out0,mul_out1,mul_out2,u9_out,u10_out,u11_out,u12_out,sum0_out,sum1_out;
wire [inst_sig_width+inst_exp_width:0]mul_in0,mul_in1,sum_in0,sum_in1,sum_in2,sum_in3; 
reg [1:0]kernel_idx[3:0][1:0];//k[0][0] is row of kernel 1,k[0][1] is column of kernel 1
wire cond_0,cond_1,cond_2,cond_3,cond_4,cond_5,cond_6,cond_7,cond_8;
////////////FSM////////////////////
reg [1:0]next_state, current_state;



/****************************************/
//control 
/***************************************/

assign dis = ks*9;
assign k0 = dis;
assign k1 = dis+1;
assign k2 = dis+2;
assign k3 = dis+3;
assign k4 = dis+4;
assign k5 = dis+5;
assign k6 = dis+6;
assign k7 = dis+7;
assign k8 = dis+8;

assign cmc = kernel_idx[ks][1];
assign cmr = kernel_idx[ks][0];

assign sw_0r = (cmr==0 ?(0):(cmr-1));
assign sw_0c = (cmc==0 ?(0):(cmc-1));
assign sw_1r = (cmr==0 ?(0):(cmr-1));
assign sw_1c = cmc;
assign sw_2r = (cmr==0 ?(0):(cmr-1));
assign sw_2c = (cmc==img_size-1 ?cmc:cmc+1);
assign sw_3r = cmr;
assign sw_3c = (cmc==0 ?(0):(cmc-1));
assign sw_4r = cmr;
assign sw_4c = cmc;
assign sw_5r = cmr;
assign sw_5c = (cmc==img_size-1 ?cmc:cmc+1);
assign sw_6r = (cmr==img_size-1 ?cmr:cmr+1);
assign sw_6c = (cmc==0) ?0:cmc-1;
assign sw_7r = (cmr==img_size-1 ?cmr:cmr+1);
assign sw_7c = cmc;
assign sw_8r = (cmr==img_size-1 ?cmr:cmr+1);
assign sw_8c = (cmc==img_size-1 ?cmc:cmc+1);

assign cond_0 = (cmr==0||cmc==0)&&(pad_str==1);
assign cond_1 = (cmr==0)&&(pad_str==1);
assign cond_2 = (cmr==0||cmc==img_size-1)&&(pad_str==1);
assign cond_3 = (cmc==0)&&(pad_str==1);
assign cond_4 = (cmc==img_size-1)&&(pad_str==1);
assign cond_5 = (cmr==img_size-1||cmc==0)&&(pad_str==1);
assign cond_6 = (cmr==img_size-1)&&(pad_str==1);
assign cond_7 = (cmr==img_size-1||cmc==img_size-1)&&(pad_str==1);

assign sw1_0 = ((cond_0)?(0):(img1[sw_0r][sw_0c]));
assign sw1_1 = ((cond_1)?(0):(img1[sw_1r][sw_1c]));
assign sw1_2 = ((cond_2)?(0):(img1[sw_2r][sw_2c]));
assign sw1_3 = ((cond_3)?(0):(img1[sw_3r][sw_3c]));
assign sw1_4 = img1[sw_4r][sw_4c];
assign sw1_5 = ((cond_4)?(0):(img1[sw_5r][sw_5c]));
assign sw1_6 = ((cond_5)?(0):(img1[sw_6r][sw_6c]));
assign sw1_7 = ((cond_6)?(0):(img1[sw_7r][sw_7c]));
assign sw1_8 = ((cond_7)?(0):(img1[sw_8r][sw_8c]));

assign sw2_0 = ((cond_0)?(0):(img2[sw_0r][sw_0c]));
assign sw2_1 = ((cond_1)?(0):(img2[sw_1r][sw_1c]));
assign sw2_2 = ((cond_2)?(0):(img2[sw_2r][sw_2c]));
assign sw2_3 = ((cond_3)?(0):(img2[sw_3r][sw_3c]));
assign sw2_4 = img2[sw_4r][sw_4c];
assign sw2_5 = ((cond_4)?(0):(img2[sw_5r][sw_5c]));
assign sw2_6 = ((cond_5)?(0):(img2[sw_6r][sw_6c]));
assign sw2_7 = ((cond_6)?(0):(img2[sw_7r][sw_7c]));
assign sw2_8 = ((cond_7)?(0):(img2[sw_8r][sw_8c]));

assign sw3_0 = ((cond_0)?(0):(img3[sw_0r][sw_0c]));
assign sw3_1 = ((cond_1)?(0):(img3[sw_1r][sw_1c]));
assign sw3_2 = ((cond_2)?(0):(img3[sw_2r][sw_2c]));
assign sw3_3 = ((cond_3)?(0):(img3[sw_3r][sw_3c]));
assign sw3_4 = 				img3[sw_4r][sw_4c];
assign sw3_5 = ((cond_4)?(0):(img3[sw_5r][sw_5c]));
assign sw3_6 = ((cond_5)?(0):(img3[sw_6r][sw_6c]));
assign sw3_7 = ((cond_6)?(0):(img3[sw_7r][sw_7c]));
assign sw3_8 = ((cond_7)?(0):(img3[sw_8r][sw_8c]));

/****************************************/
//control end
/***************************************/




/*******************************/
//input start
/*********************************/
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		op<=0;
	end
	else begin
		if(in_valid_o)
			op<=Opt;
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		img_input_idx1<=0;
		img_input_idx2<=0;
		for(i=0;i<4;i=i+1)
			for(j=0;j<4;j=j+1)begin
				img1[img_input_idx2][img_input_idx1] <= 0;
				img2[img_input_idx2][img_input_idx1] <= 0;
				img3[img_input_idx2][img_input_idx1] <= 0;		
			end
	end
	else begin
		if(in_valid_i)begin
			img_input_idx1<=img_input_idx1+1;
			if(img_input_idx1==3)img_input_idx2<=img_input_idx2+1;
			img1[img_input_idx2][img_input_idx1] <= Image1;
			img2[img_input_idx2][img_input_idx1] <= Image2;
			img3[img_input_idx2][img_input_idx1] <= Image3;
		end
		else begin
			img_input_idx1<=0;
			img_input_idx2<=0;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<36;i=i+1)begin
			kl[0][i]<=0;
			kl[1][i]<=0;
			kl[2][i]<=0;
		end
		kernel_input_idx<=0;
	end
	else begin
		if(in_valid_k)begin
			kl[0][kernel_input_idx]<=Kernel1;
			kl[1][kernel_input_idx]<=Kernel2;
			kl[2][kernel_input_idx]<=Kernel3;
			kernel_input_idx<=kernel_input_idx+1;
			if(kernel_input_idx==35)kernel_input_idx<=0;	
		end
	end
end
/**********************/
//input end
/***************************/

/******************************************/
///////FSM
//***************************************/

// Current State
always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) current_state <= IDLE;
    else        current_state <= next_state;
end

// Next State
reg started;
always @(*) 
begin
    if (!rst_n) next_state = IDLE;
    else begin
        case (current_state)
            IDLE: 
                if (in_valid_k) next_state = INPUT;
                else next_state = current_state;
			INPUT:
				if (pp_cnt==5) next_state = OUTPUT;
                else next_state = current_state;
			OUTPUT:
				if (pp_cnt==0) next_state = IDLE; 
                else next_state = current_state;
			default: next_state = current_state;
        endcase
    end
end

/**********************************************/
//FSM end 
//**********************************************/

/***********************************************/
//main control
/***********************************************/
reg start_cal;
reg [2:0]out_count;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		start_cal<=0;
	end
	else begin
		if(kernel_idx[3][0]== 3&& kernel_idx[3][1]== 3)begin
			start_cal<=0;
		end
		else if(kernel_input_idx>29)begin
			start_cal<=1;
		end

	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		ks<=0;
		out_count<=0;
	end
	else begin
		if(current_state==IDLE)begin
			ks<=0;
			out_count<=0;		
		end
		else if(start_cal)
		begin
			out_count<=out_count+1;
			ks[0]<=~ks[0];
			if(out_count==7)ks[1]<=~ks[1];
		end
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<4;i=i+1)begin
			kernel_idx[i][0]<=0;
			kernel_idx[i][1]<=0;
		end
	end
	else begin
		if(start_cal)
		begin
			kernel_idx[ks][1]<=kernel_idx[ks][1]+1;
			if(kernel_idx[ks][1]==3)kernel_idx[ks][0]<=kernel_idx[ks][0]+1;
		end
		else 
		begin
			kernel_idx[3][0]<= 0;
			kernel_idx[3][1]<= 0;
		end
	end
end



always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		pp_cnt<=1;
	end
	else begin
		if(start_cal && pp_cnt!=5)
		begin
			pp_cnt<=pp_cnt+1;
		end
		else if(current_state==IDLE)
			pp_cnt<=1;
		else if(!start_cal&& current_state==OUTPUT)
			pp_cnt<=pp_cnt-1;
	end
end
/***********************************************/
//main control end
/***********************************************/


/********************************************/
//design ware/// 
/*******************************************/

//****************************1//
reg [inst_sig_width+inst_exp_width:0]reg_sw1_0,reg_sw1_1,reg_sw1_2,reg_sw1_3,reg_sw1_4,reg_sw1_5,reg_sw1_6,reg_sw1_7,reg_sw1_8;
reg [inst_sig_width+inst_exp_width:0]reg_sw2_0,reg_sw2_1,reg_sw2_2,reg_sw2_3,reg_sw2_4,reg_sw2_5,reg_sw2_6,reg_sw2_7,reg_sw2_8;
reg [inst_sig_width+inst_exp_width:0]reg_sw3_0,reg_sw3_1,reg_sw3_2,reg_sw3_3,reg_sw3_4,reg_sw3_5,reg_sw3_6,reg_sw3_7,reg_sw3_8;
reg [inst_sig_width+inst_exp_width:0]kl0_0,kl0_1,kl0_2,kl0_3,kl0_4,kl0_5,kl0_6,kl0_7,kl0_8;
reg [inst_sig_width+inst_exp_width:0]kl1_0,kl1_1,kl1_2,kl1_3,kl1_4,kl1_5,kl1_6,kl1_7,kl1_8;
reg [inst_sig_width+inst_exp_width:0]kl2_0,kl2_1,kl2_2,kl2_3,kl2_4,kl2_5,kl2_6,kl2_7,kl2_8;
reg [1:0]reg_op;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		reg_sw1_0 <= 0;
		reg_sw1_1 <= 0;
		reg_sw1_2 <= 0;
		reg_sw1_3 <= 0;
		reg_sw1_4 <= 0;
		reg_sw1_5 <= 0;
		reg_sw1_6 <= 0;
		reg_sw1_7 <= 0;
		reg_sw1_8 <= 0;
		kl0_0<=0;
		kl0_1<=0;
		kl0_2<=0;
		kl0_3<=0;
		kl0_4<=0;
		kl0_5<=0;
		kl0_6<=0;
		kl0_7<=0;
		kl0_8<=0;
	end
	else
	begin
		reg_sw1_0 <= sw1_0;
		reg_sw1_1 <= sw1_1;
		reg_sw1_2 <= sw1_2;
		reg_sw1_3 <= sw1_3;
		reg_sw1_4 <= sw1_4;
		reg_sw1_5 <= sw1_5;
		reg_sw1_6 <= sw1_6;
		reg_sw1_7 <= sw1_7;
		reg_sw1_8 <= sw1_8;
		kl0_0<=kl[0][k0];
		kl0_1<=kl[0][k1];
		kl0_2<=kl[0][k2];
		kl0_3<=kl[0][k3];
		kl0_4<=kl[0][k4];
		kl0_5<=kl[0][k5];
		kl0_6<=kl[0][k6];
		kl0_7<=kl[0][k7];
		kl0_8<=kl[0][k8];
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		reg_sw2_0 <= 0;
		reg_sw2_1 <= 0;
		reg_sw2_2 <= 0;
		reg_sw2_3 <= 0;
		reg_sw2_4 <= 0;
		reg_sw2_5 <= 0;
		reg_sw2_6 <= 0;
		reg_sw2_7 <= 0;
		reg_sw2_8 <= 0;
		kl1_0<=0;
		kl1_1<=0;
		kl1_2<=0;
		kl1_3<=0;
		kl1_4<=0;
		kl1_5<=0;
		kl1_6<=0;
		kl1_7<=0;
		kl1_8<=0;
	end
	else
	begin
		reg_sw2_0 <= sw2_0;
		reg_sw2_1 <= sw2_1;
		reg_sw2_2 <= sw2_2;
		reg_sw2_3 <= sw2_3;
		reg_sw2_4 <= sw2_4;
		reg_sw2_5 <= sw2_5;
		reg_sw2_6 <= sw2_6;
		reg_sw2_7 <= sw2_7;
		reg_sw2_8 <= sw2_8;
		kl1_0<=kl[1][k0];
		kl1_1<=kl[1][k1];
		kl1_2<=kl[1][k2];
		kl1_3<=kl[1][k3];
		kl1_4<=kl[1][k4];
		kl1_5<=kl[1][k5];
		kl1_6<=kl[1][k6];
		kl1_7<=kl[1][k7];
		kl1_8<=kl[1][k8];
	end
end
always@(posedge clk or negedge rst_n)begin

	if(!rst_n)begin
		reg_sw3_0 <= 0;
		reg_sw3_1 <= 0;
		reg_sw3_2 <= 0;
		reg_sw3_3 <= 0;
		reg_sw3_4 <= 0;
		reg_sw3_5 <= 0;
		reg_sw3_6 <= 0;
		reg_sw3_7 <= 0;
		reg_sw3_8 <= 0;
		kl2_0<=0;
		kl2_1<=0;
		kl2_2<=0;
		kl2_3<=0;
		kl2_4<=0;
		kl2_5<=0;
		kl2_6<=0;
		kl2_7<=0;
		kl2_8<=0;
	end
	else
	begin
		reg_sw3_0 <= sw3_0;
		reg_sw3_1 <= sw3_1;
		reg_sw3_2 <= sw3_2;
		reg_sw3_3 <= sw3_3;
		reg_sw3_4 <= sw3_4;
		reg_sw3_5 <= sw3_5;
		reg_sw3_6 <= sw3_6;
		reg_sw3_7 <= sw3_7;
		reg_sw3_8 <= sw3_8;
		kl2_0<=kl[2][k0];
		kl2_1<=kl[2][k1];
		kl2_2<=kl[2][k2];
		kl2_3<=kl[2][k3];
		kl2_4<=kl[2][k4];
		kl2_5<=kl[2][k5];
		kl2_6<=kl[2][k6];
		kl2_7<=kl[2][k7];
		kl2_8<=kl[2][k8];
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		reg_op  <= 0;
	end
	else
	begin
		reg_op  <= op;
	end
end
DW_fp_dp4_inst u0(reg_sw1_0,reg_sw1_1,reg_sw1_2,reg_sw1_3,kl0_0,kl0_1,kl0_2,kl0_3,round,add_tmp0);
DW_fp_dp4_inst u1(reg_sw1_4,reg_sw1_5,reg_sw1_6,reg_sw1_7,kl0_4,kl0_5,kl0_6,kl0_7,round,add_tmp1);
DW_fp_mult_inst u2(reg_sw1_8,kl0_8,round,mul_out0);

DW_fp_dp4_inst u3(reg_sw2_0,reg_sw2_1,reg_sw2_2,reg_sw2_3,kl1_0,kl1_1,kl1_2,kl1_3,round,add_tmp2);
DW_fp_dp4_inst u4(reg_sw2_4,reg_sw2_5,reg_sw2_6,reg_sw2_7,kl1_4,kl1_5,kl1_6,kl1_7,round,add_tmp3);
DW_fp_mult_inst u5(reg_sw2_8,kl1_8,round,mul_out1);

DW_fp_dp4_inst u6(reg_sw3_0,reg_sw3_1,reg_sw3_2,reg_sw3_3,kl2_0,kl2_1,kl2_2,kl2_3,round,add_tmp4);
DW_fp_dp4_inst u7(reg_sw3_4,reg_sw3_5,reg_sw3_6,reg_sw3_7,kl2_4,kl2_5,kl2_6,kl2_7,round,add_tmp5);
DW_fp_mult_inst u8(reg_sw3_8,kl2_8,round,mul_out2);

//****************************2//
reg [inst_sig_width+inst_exp_width:0]reg_add_tmp0,reg_add_tmp1,reg_add_tmp2,reg_add_tmp3,
		reg_add_tmp4,reg_add_tmp5,reg_mul_out0,reg_mul_out1,reg_mul_out2;
reg [1:0]reg_op2;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		reg_op2  <= 0;
	end
	else
	begin
		reg_op2  <= reg_op;
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		reg_add_tmp0 <= 0;
		reg_add_tmp1 <= 0;
		reg_add_tmp2 <= 0;
		reg_add_tmp3 <= 0;
		reg_add_tmp4 <= 0;
		reg_add_tmp5 <= 0;
		reg_mul_out0 <= 0;
		reg_mul_out1 <= 0;
		reg_mul_out2 <= 0;
	end
	else
	begin
		reg_add_tmp0 <= add_tmp0;
		reg_add_tmp1 <= add_tmp1;
		reg_add_tmp2 <= add_tmp2;
		reg_add_tmp3 <= add_tmp3;
		reg_add_tmp4 <= add_tmp4;
		reg_add_tmp5 <= add_tmp5;
		reg_mul_out0 <= mul_out0;
		reg_mul_out1 <= mul_out1;
		reg_mul_out2 <= mul_out2;
	end
end
DW_fp_sum3_inst u9(reg_add_tmp0,reg_add_tmp1,reg_mul_out0,round,u9_out);
DW_fp_sum3_inst u10(reg_add_tmp2,reg_add_tmp3,reg_mul_out1,round,u10_out);
DW_fp_sum3_inst u11(reg_add_tmp4,reg_add_tmp5,reg_mul_out2,round,u11_out);
DW_fp_sum3_inst u12(u9_out,u10_out,u11_out,round,u12_out);
//****************************3//

reg [1:0]reg_op3;
reg [inst_sig_width+inst_exp_width:0]reg_u12_out;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		reg_op3  <= 0;
		reg_u12_out  <= 0;
	end
	else
	begin
		reg_op3  <= reg_op2;
		reg_u12_out  <= u12_out;
	end
end


DW_fp_mult_inst mul(reg_u12_out,32'h3DCCCCCC,round,mul_out);

//****************************4//




reg [1:0]reg_op4;
reg [inst_sig_width+inst_exp_width:0]reg_u12_out2,reg_mul_out;
wire [inst_sig_width+inst_exp_width:0]exp2_out;
wire [inst_sig_width+inst_exp_width:0]neg_reg_u12_out;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		reg_op4  <= 0;
		reg_u12_out2  <= 0;
		reg_mul_out<=0;
	end
	else
	begin
		reg_op4  <= reg_op3;
		reg_u12_out2  <= reg_u12_out;
		reg_mul_out<=mul_out;
	end
end
assign neg_reg_u12_out = {~reg_u12_out2[31],reg_u12_out2[30:0]};
DW_fp_exp_inst u13(reg_u12_out2,exp_out);    //exp(x)
DW_fp_exp_inst exp2(neg_reg_u12_out,exp2_out);//exp(-x)
//**************************************5//
reg [1:0]reg_op5;
reg [inst_sig_width+inst_exp_width:0]reg_mul_out2_2,reg_exp_out,reg_exp2_out,reg_u12_out3;
always@(posedge clk or negedge rst_n)begin
if(!rst_n)begin
		reg_op5  <= 0;
		reg_exp_out<=0;
		reg_exp2_out<=0;
		reg_mul_out2_2<=0;
		reg_u12_out3<=0;
	end
	else 
	begin
		reg_op5  <= reg_op4;
		reg_exp_out<=exp_out;
		reg_exp2_out<=exp2_out;
		reg_mul_out2_2<=reg_mul_out;
		reg_u12_out3<=reg_u12_out2;
	end
end
assign sum_in0 = (reg_op5==2 ?32'h3F800000:reg_exp_out);//1
assign sum_in1 = reg_exp2_out;
assign sum_in2 = (reg_op5==2 ?32'h3F800000:{~reg_exp2_out[31],reg_exp2_out[30:0]});
assign sum_in3 = (reg_op5==2 ?0:reg_exp_out);

DW_fp_add_inst sum0(sum_in0,sum_in1,round,sum0_out);
DW_fp_add_inst sum1(sum_in2,sum_in3,round,sum1_out);

DW_fp_div_inst u14(sum1_out,sum0_out,round,div_out);


/********************************************/
//design ware end
/*******************************************/







/*********************************************/
//output
/**********************************************/
assign gt = ~reg_u12_out3[31];
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_valid<=0;
		out<=0;
		started<=0;
	end
	else begin
		if(current_state==OUTPUT)begin
			if(kernel_idx[0][0]==3)started<=1;
			out_valid<=1;
			if(reg_op5==0)begin
				if(gt)out<=reg_u12_out3;
				else out<=0;
			end
			else if(reg_op5==1)begin
				if(gt)out<=reg_u12_out3;
				else out<=reg_mul_out2_2;
			end
			else
				out<=div_out;
		end
		else begin
			out_valid<=0;
			out<=0;
			started<=0;
		end
	end
end


/*********************************************/
//output end
/**********************************************/


endmodule









module DW_fp_dp4_inst( inst_a, inst_b, inst_c, inst_d, inst_e,
inst_f, inst_g, inst_h, inst_rnd,z_inst
);
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 1;
parameter inst_arch_type = 1;

input [inst_sig_width+inst_exp_width : 0] inst_a;
input [inst_sig_width+inst_exp_width : 0] inst_b;
input [inst_sig_width+inst_exp_width : 0] inst_c;
input [inst_sig_width+inst_exp_width : 0] inst_d;
input [inst_sig_width+inst_exp_width : 0] inst_e;
input [inst_sig_width+inst_exp_width : 0] inst_f;
input [inst_sig_width+inst_exp_width : 0] inst_g;
input [inst_sig_width+inst_exp_width : 0] inst_h;
input [2 : 0] inst_rnd;
output [inst_sig_width+inst_exp_width : 0] z_inst;
// Instance of DW_fp_dp4
wire[7:0]status_inst;
DW_fp_dp4 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
U1 (
.a(inst_a),
.b(inst_e),
.c(inst_b),
.d(inst_f),
.e(inst_c),
.f(inst_g),
.g(inst_d),
.h(inst_h),
.rnd(inst_rnd),
.z(z_inst),
.status(status_inst));
endmodule


module DW_fp_mult_inst( inst_a, inst_b, inst_rnd ,z_inst);
parameter sig_width = 23;
parameter exp_width = 8;
parameter ieee_compliance = 1;
input [sig_width+exp_width : 0] inst_a;
input [sig_width+exp_width : 0] inst_b;
input [2 : 0] inst_rnd;
output [sig_width+exp_width : 0] z_inst;
 // Instance of DW_fp_mult
 DW_fp_mult #(sig_width, exp_width, ieee_compliance)
 U1 ( .a(inst_a), .b(inst_b), .rnd(inst_rnd), .z(z_inst) );
endmodule





module DW_fp_add_inst( inst_a, inst_b, inst_rnd, z_inst);
parameter sig_width = 23;
parameter exp_width = 8;
parameter ieee_compliance = 1;
input [sig_width+exp_width : 0] inst_a;
input [sig_width+exp_width : 0] inst_b;
input [2 : 0] inst_rnd;
output [sig_width+exp_width : 0] z_inst;
wire [7 : 0] status_inst;
 // Instance of DW_fp_add
 DW_fp_add #(sig_width, exp_width, ieee_compliance)
 U1 ( .a(inst_a), .b(inst_b), .rnd(inst_rnd), .z(z_inst), .status(status_inst) );
endmodule


module DW_fp_div_inst( inst_a, inst_b, inst_rnd, z_inst );
parameter sig_width = 23;
parameter exp_width = 8;
parameter ieee_compliance = 1;
parameter faithful_round = 0;
input [sig_width+exp_width : 0] inst_a;
input [sig_width+exp_width : 0] inst_b;
input [2 : 0] inst_rnd;
output [sig_width+exp_width : 0] z_inst;
wire [7 : 0] status_inst;
 // Instance of DW_fp_div
DW_fp_div #(sig_width, exp_width, ieee_compliance, faithful_round) U1
( .a(inst_a), .b(inst_b), .rnd(inst_rnd), .z(z_inst), .status(status_inst)
);
endmodule


module DW_fp_exp_inst( inst_a, z_inst );
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 1;
parameter inst_arch = 2;
input [inst_sig_width+inst_exp_width : 0] inst_a;
output [inst_sig_width+inst_exp_width : 0] z_inst;
wire [7 : 0] status_inst;
 // Instance of DW_fp_exp
 DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) U1 (
.a(inst_a),
.z(z_inst),
.status(status_inst) );
endmodule



module DW_fp_sum3_inst( inst_a, inst_b, inst_c, inst_rnd, z_inst);
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 1;
parameter inst_arch_type = 0;
input [inst_sig_width+inst_exp_width : 0] inst_a;
input [inst_sig_width+inst_exp_width : 0] inst_b;
input [inst_sig_width+inst_exp_width : 0] inst_c;
input [2 : 0] inst_rnd;
output [inst_sig_width+inst_exp_width : 0] z_inst;
wire [7 : 0] status_inst;
 // Instance of DW_fp_sum3
 DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch_type)
U1 (
.a(inst_a),
.b(inst_b),
.c(inst_c),
.rnd(inst_rnd),
.z(z_inst),
.status(status_inst) );
endmodule
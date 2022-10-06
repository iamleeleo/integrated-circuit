//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : WD.v
//   Module Name : WD
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module WD(
    // Input signals
    clk,
    rst_n,
    in_valid,
    keyboard,
    answer,
    weight,
    match_target,
    // Output signals
    out_valid,
    result,
    out_value
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [4:0] keyboard, answer;
input [3:0] weight;
input [2:0] match_target;
output reg out_valid;
output reg [4:0]  result;
output reg [10:0] out_value;

// ===============================================================
// Parameters & Integer Declaration
// ===============================================================

parameter IDLE    = 3'd0;
parameter INPUT = 3'd1;
parameter PRE_CALCULATE = 3'd2;
parameter CALCULATE = 3'd3;
parameter OUTPUT = 3'd4;


// ===============================================================
// Wire & Reg Declaration
// ===============================================================
reg [3:0]next_state, current_state;
reg [4:0] key[7:0];
reg [4:0] ans[4:0];
reg [3:0] weg[4:0];
reg [2:0] tar[1:0];

reg [2:0]key_idx; 
reg [2:0]weg_idx;
reg [1:0]tar_idx;


//prepare for calculte
reg [4:0]input_data[7:0];

reg [2:0]input_data_idx0;
reg [2:0]sorted_idx0;
reg [2:0]key_idx1;



reg [4:0]guess[4:0];


reg [2:0]max_result_idx;

wire over;
// ===============================================================
// DESIGN
// ===============================================================


// ===============================================================
// Finite State Machine
// ===============================================================

// Current State
always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) current_state <= IDLE;
    else        current_state <= next_state;
end

// Next State
always @(*) 
begin
    if (!rst_n) next_state = IDLE;
    else begin
        case (current_state)
            IDLE: begin
                if (in_valid) next_state = INPUT;
                else next_state = current_state;
            end
            INPUT:
				if(key_idx==0)next_state = PRE_CALCULATE;
				else next_state = current_state;
			PRE_CALCULATE:
				if(!input_data_idx0)next_state = CALCULATE;
				else next_state = current_state;
			CALCULATE:
				if(over)next_state = OUTPUT;
				else next_state = current_state;
			OUTPUT:
				if(max_result_idx==4)next_state = IDLE;
				else next_state = current_state;
            default: next_state = current_state;
        endcase
    end
end


//Reading

integer i;
always @(posedge clk, negedge rst_n)
begin
	if(!rst_n)begin
		key_idx <=0;
		tar_idx <=0;
		weg_idx <=0;
		for(i=0;i<5;i=i+1)begin
			weg[i]<=0;
			ans[i]<=0;
			key[i]<=0;
		end
		for(i=5;i<8;i=i+1)begin
			key[i]<=0;
		end
		tar[0]<=0;
		tar[1]<=0;
	end
	else
	begin
		if(in_valid)
		begin
			key_idx<=key_idx+1;
			key[key_idx] <= keyboard;
			if(weg_idx<5)begin
				weg_idx<=weg_idx+1;
				weg[weg_idx] <= weight;
				ans[weg_idx] <= answer;
			end
			
			if(tar_idx<2)begin
				tar_idx<=tar_idx+1;
				tar[tar_idx] <= match_target;
			end
			
		end
		else begin
			key_idx<=0;
			weg_idx<=0;
			tar_idx<=0;
			for(i=0;i<8;i=i+1)
				key[key_idx] <= key[key_idx];
			for(i=0;i<5;i=i+1)begin
				weg[weg_idx] <= weg[weg_idx]; 
				ans[weg_idx] <= ans[weg_idx];
			end
			
		end
	end
end

//output with 
/*
reg [4:0] key[7:0];
reg [4:0] ans[4:0];
reg [3:0] weg[4:0];
reg [2:0] tar[1:0];
*/

//prepare for calculte




wire [4:0]node00,node01,node02,node03,	
	node10,node11,node12,node13,node14,
	node21,node22,node23,node24;
	
wire [4:0]sorted[4:0];

cmp cmp0 (.A(ans[0]),.B(ans[1]),.node0(node00 ),.node1(node01) ); //sort n0,n1
cmp cmp1 (.A(ans[2]),.B(ans[3]),.node0(node02 ),.node1(node03) ); //sort n2,n3
cmp cmp3 (.A(node00),.B(node02),.node0(node10 ),.node1(node12) ); //sort n0,n2
cmp cmp4 (.A(node10),.B(ans[4]),.node0(sorted[0]),.node1(node14) ); //sort n0,n4
cmp cmp5 (.A(node01),.B(node14),.node0(node11 ),.node1(node24) ); //sort n1,n4
cmp cmp6 (.A(node03),.B(node24),.node0(node13 ),.node1(sorted[4])); //sort n3,n4
cmp cmp7 (.A(node11),.B(node12),.node0(node21 ),.node1(node22) ); //sort n1,n2
cmp cmp9 (.A(node21),.B(node13),.node0(sorted[1]),.node1(node23) ); //sort n1,n3
cmp cmp11(.A(node22),.B(node23),.node0(sorted[2]),.node1(sorted[3])); //sort n2,n3

//store ans at input_data 0~4


		
//store key that not in ans at input_data 5~7
always @(posedge clk or negedge rst_n) begin
	if (!rst_n)   
	begin
		sorted_idx0<=4;
		key_idx1<=7;
		input_data_idx0<=5;
	end
	else
	begin
	    if(current_state == PRE_CALCULATE)begin
			for(i=0;i<5;i=i+1)
				input_data[i]<=ans[i];
			if(input_data_idx0!=0&&(sorted[sorted_idx0]!=key[key_idx1] ||sorted_idx0==7))begin
				input_data[input_data_idx0] <= key[key_idx1];
				input_data_idx0 <= input_data_idx0+1;
			end
			else begin
				input_data[input_data_idx0] <= input_data[input_data_idx0];
				sorted_idx0 <=sorted_idx0 -1;
			end
			key_idx1 <= key_idx1 -1;
		end
		else begin
			sorted_idx0<=4;
			key_idx1<=7;
			input_data_idx0<=5;	
		end
	end
end

//output with [4:0]input_data[7:0]


//start calculating
reg [9:0]inspect_vector;
reg [10:0]max_value;
reg [4:0]max_result[4:0];
reg [10:0]max_corner_case ;

wire [4:0]tmp_guess[4:0];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   
	begin
		for(i=0; i<5; i = i + 1)
			guess[i]<=0;
	end
	else
	begin
		for(i=0; i<5; i = i + 1)
			guess[i]<=tmp_guess[i];
	end
end


//use inspect_vector to deside which permutations to compare with.
//"input_data" is original data, and map "input_data" to "tmp_guess" with different permutations.
//once try all the permutations that tar[1:0] can have, "over" become high to start output.
guess_selector g1(
	inspect_vector,
	input_data[0],input_data[1],
	input_data[2],input_data[3],
	input_data[4],input_data[5],
	input_data[6],input_data[7],
	tar[0],tar[1],
	tmp_guess[0],tmp_guess[1],tmp_guess[2],tmp_guess[3],tmp_guess[4],over
);


//"current_value" store the current permutation that is now compare,so do current_corner_case.
wire [10:0]current_value = (guess[0]*weg[0]+guess[1]*weg[1])+(guess[2]*weg[2]+	guess[3]*weg[3])+guess[4]*weg[4];
wire [10:0]current_corner_case = (16*guess[0]+8*guess[1])+(4*guess[2]+2*guess[3]) + guess[4];


//sml and eql compute the relation between current permutation and max case,is used when corner case occur.
wire sml[4:0];
wire eql[4:0];
assign sml[0] = guess[0]< max_result[0];
assign sml[1] = guess[1]< max_result[1];
assign sml[2] = guess[2]< max_result[2];
assign sml[3] = guess[3]< max_result[3];
assign sml[4] = guess[4]< max_result[4];
assign eql[0] = guess[0]==max_result[0];
assign eql[1] = guess[1]==max_result[1];
assign eql[2] = guess[2]==max_result[2];
assign eql[3] = guess[3]==max_result[3];
assign eql[4] = guess[4]==max_result[4];

//control the inspect_vector and max case;
//first compare with current "weight" * "guess",then if the they equal,try two different corner case value.
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   
	begin
		inspect_vector<=0;
		for(i=0; i<5; i = i + 1)
			max_result[i]<=0;
		max_value<=0;
		max_corner_case<=0;
	end
	else
	begin
		if(current_state == CALCULATE)
		begin
			inspect_vector<=inspect_vector+1;

			if(current_value>max_value)begin
				max_value <= current_value;
				max_corner_case <= current_corner_case;
				for(i=0;i<5;i=i+1)
					max_result[i]<=guess[i];
			end
			else if(current_value == max_value && current_corner_case > max_corner_case)begin
				max_value <= max_value;
				max_corner_case <= current_corner_case;
				for(i=0;i<5;i=i+1)
					max_result[i]<=guess[i];
			end
			else if(current_value == max_value && current_corner_case == max_corner_case)begin
				casez({sml[0],sml[1],sml[2],sml[3],sml[4],eql[0],eql[1],eql[2],eql[3],eql[4]})
					10'b1????_?????:
					for(i=0;i<5;i=i+1)
						max_result[i]<=guess[i];
					10'b?1???_1????:
					for(i=0;i<5;i=i+1)
						max_result[i]<=guess[i];
					10'b??1??_11???: 
					for(i=0;i<5;i=i+1)
						max_result[i]<=guess[i];
					10'b???1?_111??:
					for(i=0;i<5;i=i+1)
						max_result[i]<=guess[i];
					10'b????1_1111?:
					for(i=0;i<5;i=i+1)
						max_result[i]<=guess[i];
					default:
						for(i=0;i<5;i=i+1)
							max_result[i]<=max_result[i];
				endcase
			end
			else 
			begin
				max_value <= max_value;
				max_corner_case <= max_corner_case;
				for(i=0;i<5;i=i+1)
					max_result[i]<=max_result[i];
			end
		end
		else if(current_state == INPUT)begin
			inspect_vector<=0;
			for(i=0; i<5; i = i + 1)
				max_result[i]<=0;
			max_value<=0;
			max_corner_case<=0;
		end
	end
end





// Output Logic

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)   
		begin 
			out_valid<=0; 
			result<=0;
			out_value<=0;
			max_result_idx<=0;
		end
	else
	begin
		if(current_state == OUTPUT)begin
			out_valid<=1;
			out_value <= max_value;
			result<=max_result[max_result_idx];
			max_result_idx<=max_result_idx+1;
		end
		else begin
			out_valid<=0;
			out_value <= 10'b0;
			result<=5'b0;
			max_result_idx<=0;
		end		
	end
end


endmodule


module cmp(
	A,
	B,
	node0,
	node1
);
	input [4:0]B;
	input [4:0]A;
	output wire [4:0] node0;
	output wire [4:0] node1;

	
	assign node0 = (A<B ? A : B);
	assign node1 = (A<B ? B : A);
	

endmodule


module guess_selector(
	input wire [9:0]inspect_vector,
	input wire [4:0]i0,
	input wire [4:0]i1,
	input wire [4:0]i2,
	input wire [4:0]i3,
	input wire [4:0]i4,
	input wire [4:0]i5,
	input wire [4:0]i6,
	input wire [4:0]i7,
	input wire [2:0]tar0,
	input wire [2:0]tar1,
	output wire [4:0]g0,
	output wire [4:0]g1,
	output wire [4:0]g2,
	output wire [4:0]g3,
	output wire [4:0]g4,
	
	output reg over
 );

 reg [2:0]g0_idx,g1_idx,g2_idx,g3_idx,g4_idx;
 wire [4:0]input_value[7:0];
 assign input_value[0] = i0;
 assign input_value[1] = i1;
 assign input_value[2] = i2;
 assign input_value[3] = i3;
 assign input_value[4] = i4;
 assign input_value[5] = i5;
 assign input_value[6] = i6;
 assign input_value[7] = i7;
 
 assign g0 = input_value[g0_idx];
 assign g1 = input_value[g1_idx];
 assign g2 = input_value[g2_idx];
 assign g3 = input_value[g3_idx];
 assign g4 = input_value[g4_idx];
 
 
 always@*
	case({tar0,tar1})
		6'o02:
			case(inspect_vector)
				0:begin  g0_idx=1;g1_idx=0;g2_idx=5;g3_idx=6;g4_idx=7;over=0; end
				1:begin  g0_idx=5;g1_idx=0;g2_idx=1;g3_idx=6;g4_idx=7;over=0; end
				2:begin  g0_idx=1;g1_idx=5;g2_idx=0;g3_idx=6;g4_idx=7;over=0; end
				3:begin  g0_idx=1;g1_idx=0;g2_idx=6;g3_idx=5;g4_idx=7;over=0; end
				4:begin  g0_idx=6;g1_idx=0;g2_idx=1;g3_idx=5;g4_idx=7;over=0; end
				5:begin  g0_idx=1;g1_idx=6;g2_idx=0;g3_idx=5;g4_idx=7;over=0; end
				6:begin  g0_idx=5;g1_idx=0;g2_idx=6;g3_idx=1;g4_idx=7;over=0; end
				7:begin  g0_idx=6;g1_idx=0;g2_idx=5;g3_idx=1;g4_idx=7;over=0; end
				8:begin  g0_idx=5;g1_idx=6;g2_idx=0;g3_idx=1;g4_idx=7;over=0; end
				9:begin  g0_idx=6;g1_idx=5;g2_idx=0;g3_idx=1;g4_idx=7;over=0; end
				10:begin g0_idx=1;g1_idx=5;g2_idx=6;g3_idx=0;g4_idx=7;over=0; end
				11:begin g0_idx=1;g1_idx=6;g2_idx=5;g3_idx=0;g4_idx=7;over=0; end
				12:begin g0_idx=5;g1_idx=6;g2_idx=1;g3_idx=0;g4_idx=7;over=0; end
				13:begin g0_idx=6;g1_idx=5;g2_idx=1;g3_idx=0;g4_idx=7;over=0; end
				14:begin g0_idx=1;g1_idx=0;g2_idx=5;g3_idx=7;g4_idx=6;over=0; end
				15:begin g0_idx=5;g1_idx=0;g2_idx=1;g3_idx=7;g4_idx=6;over=0; end
				16:begin g0_idx=1;g1_idx=5;g2_idx=0;g3_idx=7;g4_idx=6;over=0; end
				17:begin g0_idx=1;g1_idx=0;g2_idx=7;g3_idx=5;g4_idx=6;over=0; end
				18:begin g0_idx=7;g1_idx=0;g2_idx=1;g3_idx=5;g4_idx=6;over=0; end
				19:begin g0_idx=1;g1_idx=7;g2_idx=0;g3_idx=5;g4_idx=6;over=0; end
				20:begin g0_idx=5;g1_idx=0;g2_idx=7;g3_idx=1;g4_idx=6;over=0; end
				21:begin g0_idx=7;g1_idx=0;g2_idx=5;g3_idx=1;g4_idx=6;over=0; end
				22:begin g0_idx=5;g1_idx=7;g2_idx=0;g3_idx=1;g4_idx=6;over=0; end
				23:begin g0_idx=7;g1_idx=5;g2_idx=0;g3_idx=1;g4_idx=6;over=0; end
				24:begin g0_idx=1;g1_idx=5;g2_idx=7;g3_idx=0;g4_idx=6;over=0; end
				25:begin g0_idx=1;g1_idx=7;g2_idx=5;g3_idx=0;g4_idx=6;over=0; end
				26:begin g0_idx=5;g1_idx=7;g2_idx=1;g3_idx=0;g4_idx=6;over=0; end
				27:begin g0_idx=7;g1_idx=5;g2_idx=1;g3_idx=0;g4_idx=6;over=0; end
				28:begin g0_idx=1;g1_idx=0;g2_idx=6;g3_idx=7;g4_idx=5;over=0; end
				29:begin g0_idx=6;g1_idx=0;g2_idx=1;g3_idx=7;g4_idx=5;over=0; end
				30:begin g0_idx=1;g1_idx=6;g2_idx=0;g3_idx=7;g4_idx=5;over=0; end
				31:begin g0_idx=1;g1_idx=0;g2_idx=7;g3_idx=6;g4_idx=5;over=0; end
				32:begin g0_idx=7;g1_idx=0;g2_idx=1;g3_idx=6;g4_idx=5;over=0; end
				33:begin g0_idx=1;g1_idx=7;g2_idx=0;g3_idx=6;g4_idx=5;over=0; end
				34:begin g0_idx=6;g1_idx=0;g2_idx=7;g3_idx=1;g4_idx=5;over=0; end
				35:begin g0_idx=7;g1_idx=0;g2_idx=6;g3_idx=1;g4_idx=5;over=0; end
				36:begin g0_idx=6;g1_idx=7;g2_idx=0;g3_idx=1;g4_idx=5;over=0; end
				37:begin g0_idx=7;g1_idx=6;g2_idx=0;g3_idx=1;g4_idx=5;over=0; end
				38:begin g0_idx=1;g1_idx=6;g2_idx=7;g3_idx=0;g4_idx=5;over=0; end
				39:begin g0_idx=1;g1_idx=7;g2_idx=6;g3_idx=0;g4_idx=5;over=0; end
				40:begin g0_idx=6;g1_idx=7;g2_idx=1;g3_idx=0;g4_idx=5;over=0; end
				41:begin g0_idx=7;g1_idx=6;g2_idx=1;g3_idx=0;g4_idx=5;over=0; end
				42:begin g0_idx=5;g1_idx=0;g2_idx=6;g3_idx=7;g4_idx=1;over=0; end
				43:begin g0_idx=6;g1_idx=0;g2_idx=5;g3_idx=7;g4_idx=1;over=0; end
				44:begin g0_idx=5;g1_idx=6;g2_idx=0;g3_idx=7;g4_idx=1;over=0; end
				45:begin g0_idx=6;g1_idx=5;g2_idx=0;g3_idx=7;g4_idx=1;over=0; end
				46:begin g0_idx=5;g1_idx=0;g2_idx=7;g3_idx=6;g4_idx=1;over=0; end
				47:begin g0_idx=7;g1_idx=0;g2_idx=5;g3_idx=6;g4_idx=1;over=0; end
				48:begin g0_idx=5;g1_idx=7;g2_idx=0;g3_idx=6;g4_idx=1;over=0; end
				49:begin g0_idx=7;g1_idx=5;g2_idx=0;g3_idx=6;g4_idx=1;over=0; end
				50:begin g0_idx=6;g1_idx=0;g2_idx=7;g3_idx=5;g4_idx=1;over=0; end
				51:begin g0_idx=7;g1_idx=0;g2_idx=6;g3_idx=5;g4_idx=1;over=0; end
				52:begin g0_idx=6;g1_idx=7;g2_idx=0;g3_idx=5;g4_idx=1;over=0; end
				53:begin g0_idx=7;g1_idx=6;g2_idx=0;g3_idx=5;g4_idx=1;over=0; end
				54:begin g0_idx=5;g1_idx=6;g2_idx=7;g3_idx=0;g4_idx=1;over=0; end
				55:begin g0_idx=6;g1_idx=5;g2_idx=7;g3_idx=0;g4_idx=1;over=0; end
				56:begin g0_idx=5;g1_idx=7;g2_idx=6;g3_idx=0;g4_idx=1;over=0; end
				57:begin g0_idx=7;g1_idx=5;g2_idx=6;g3_idx=0;g4_idx=1;over=0; end
				58:begin g0_idx=6;g1_idx=7;g2_idx=5;g3_idx=0;g4_idx=1;over=0; end
				59:begin g0_idx=7;g1_idx=6;g2_idx=5;g3_idx=0;g4_idx=1;over=0; end
				60:begin g0_idx=1;g1_idx=5;g2_idx=6;g3_idx=7;g4_idx=0;over=0; end
				61:begin g0_idx=1;g1_idx=6;g2_idx=5;g3_idx=7;g4_idx=0;over=0; end
				62:begin g0_idx=5;g1_idx=6;g2_idx=1;g3_idx=7;g4_idx=0;over=0; end
				63:begin g0_idx=6;g1_idx=5;g2_idx=1;g3_idx=7;g4_idx=0;over=0; end
				64:begin g0_idx=1;g1_idx=5;g2_idx=7;g3_idx=6;g4_idx=0;over=0; end
				65:begin g0_idx=1;g1_idx=7;g2_idx=5;g3_idx=6;g4_idx=0;over=0; end
				66:begin g0_idx=5;g1_idx=7;g2_idx=1;g3_idx=6;g4_idx=0;over=0; end
				67:begin g0_idx=7;g1_idx=5;g2_idx=1;g3_idx=6;g4_idx=0;over=0; end
				68:begin g0_idx=1;g1_idx=6;g2_idx=7;g3_idx=5;g4_idx=0;over=0; end
				69:begin g0_idx=1;g1_idx=7;g2_idx=6;g3_idx=5;g4_idx=0;over=0; end
				70:begin g0_idx=6;g1_idx=7;g2_idx=1;g3_idx=5;g4_idx=0;over=0; end
				71:begin g0_idx=7;g1_idx=6;g2_idx=1;g3_idx=5;g4_idx=0;over=0; end
				72:begin g0_idx=5;g1_idx=6;g2_idx=7;g3_idx=1;g4_idx=0;over=0; end
				73:begin g0_idx=6;g1_idx=5;g2_idx=7;g3_idx=1;g4_idx=0;over=0; end
				74:begin g0_idx=5;g1_idx=7;g2_idx=6;g3_idx=1;g4_idx=0;over=0; end
				75:begin g0_idx=7;g1_idx=5;g2_idx=6;g3_idx=1;g4_idx=0;over=0; end
				76:begin g0_idx=6;g1_idx=7;g2_idx=5;g3_idx=1;g4_idx=0;over=0; end
				77:begin g0_idx=7;g1_idx=6;g2_idx=5;g3_idx=1;g4_idx=0;over=0; end
				78:begin g0_idx=2;g1_idx=0;g2_idx=5;g3_idx=6;g4_idx=7;over=0; end
				79:begin g0_idx=2;g1_idx=5;g2_idx=0;g3_idx=6;g4_idx=7;over=0; end
				80:begin g0_idx=5;g1_idx=2;g2_idx=0;g3_idx=6;g4_idx=7;over=0; end
				81:begin g0_idx=2;g1_idx=0;g2_idx=6;g3_idx=5;g4_idx=7;over=0; end
				82:begin g0_idx=2;g1_idx=6;g2_idx=0;g3_idx=5;g4_idx=7;over=0; end
				83:begin g0_idx=6;g1_idx=2;g2_idx=0;g3_idx=5;g4_idx=7;over=0; end
				84:begin g0_idx=5;g1_idx=0;g2_idx=6;g3_idx=2;g4_idx=7;over=0; end
				85:begin g0_idx=6;g1_idx=0;g2_idx=5;g3_idx=2;g4_idx=7;over=0; end
				86:begin g0_idx=5;g1_idx=6;g2_idx=0;g3_idx=2;g4_idx=7;over=0; end
				87:begin g0_idx=6;g1_idx=5;g2_idx=0;g3_idx=2;g4_idx=7;over=0; end
				88:begin g0_idx=2;g1_idx=5;g2_idx=6;g3_idx=0;g4_idx=7;over=0; end
				89:begin g0_idx=5;g1_idx=2;g2_idx=6;g3_idx=0;g4_idx=7;over=0; end
				90:begin g0_idx=2;g1_idx=6;g2_idx=5;g3_idx=0;g4_idx=7;over=0; end
				91:begin g0_idx=6;g1_idx=2;g2_idx=5;g3_idx=0;g4_idx=7;over=0; end
				92:begin g0_idx=2;g1_idx=0;g2_idx=5;g3_idx=7;g4_idx=6;over=0; end
				93:begin g0_idx=2;g1_idx=5;g2_idx=0;g3_idx=7;g4_idx=6;over=0; end
				94:begin g0_idx=5;g1_idx=2;g2_idx=0;g3_idx=7;g4_idx=6;over=0; end
				95:begin g0_idx=2;g1_idx=0;g2_idx=7;g3_idx=5;g4_idx=6;over=0; end
				96:begin g0_idx=2;g1_idx=7;g2_idx=0;g3_idx=5;g4_idx=6;over=0; end
				97:begin g0_idx=7;g1_idx=2;g2_idx=0;g3_idx=5;g4_idx=6;over=0; end
				98:begin g0_idx=5;g1_idx=0;g2_idx=7;g3_idx=2;g4_idx=6;over=0; end
				99:begin g0_idx=7;g1_idx=0;g2_idx=5;g3_idx=2;g4_idx=6;over=0; end
				100:begin g0_idx=5;g1_idx=7;g2_idx=0;g3_idx=2;g4_idx=6;over=0; end
				101:begin g0_idx=7;g1_idx=5;g2_idx=0;g3_idx=2;g4_idx=6;over=0; end
				102:begin g0_idx=2;g1_idx=5;g2_idx=7;g3_idx=0;g4_idx=6;over=0; end
				103:begin g0_idx=5;g1_idx=2;g2_idx=7;g3_idx=0;g4_idx=6;over=0; end
				104:begin g0_idx=2;g1_idx=7;g2_idx=5;g3_idx=0;g4_idx=6;over=0; end
				105:begin g0_idx=7;g1_idx=2;g2_idx=5;g3_idx=0;g4_idx=6;over=0; end
				106:begin g0_idx=2;g1_idx=0;g2_idx=6;g3_idx=7;g4_idx=5;over=0; end
				107:begin g0_idx=2;g1_idx=6;g2_idx=0;g3_idx=7;g4_idx=5;over=0; end
				108:begin g0_idx=6;g1_idx=2;g2_idx=0;g3_idx=7;g4_idx=5;over=0; end
				109:begin g0_idx=2;g1_idx=0;g2_idx=7;g3_idx=6;g4_idx=5;over=0; end
				110:begin g0_idx=2;g1_idx=7;g2_idx=0;g3_idx=6;g4_idx=5;over=0; end
				111:begin g0_idx=7;g1_idx=2;g2_idx=0;g3_idx=6;g4_idx=5;over=0; end
				112:begin g0_idx=6;g1_idx=0;g2_idx=7;g3_idx=2;g4_idx=5;over=0; end
				113:begin g0_idx=7;g1_idx=0;g2_idx=6;g3_idx=2;g4_idx=5;over=0; end
				114:begin g0_idx=6;g1_idx=7;g2_idx=0;g3_idx=2;g4_idx=5;over=0; end
				115:begin g0_idx=7;g1_idx=6;g2_idx=0;g3_idx=2;g4_idx=5;over=0; end
				116:begin g0_idx=2;g1_idx=6;g2_idx=7;g3_idx=0;g4_idx=5;over=0; end
				117:begin g0_idx=6;g1_idx=2;g2_idx=7;g3_idx=0;g4_idx=5;over=0; end
				118:begin g0_idx=2;g1_idx=7;g2_idx=6;g3_idx=0;g4_idx=5;over=0; end
				119:begin g0_idx=7;g1_idx=2;g2_idx=6;g3_idx=0;g4_idx=5;over=0; end
				120:begin g0_idx=5;g1_idx=0;g2_idx=6;g3_idx=7;g4_idx=2;over=0; end
				121:begin g0_idx=6;g1_idx=0;g2_idx=5;g3_idx=7;g4_idx=2;over=0; end
				122:begin g0_idx=5;g1_idx=6;g2_idx=0;g3_idx=7;g4_idx=2;over=0; end
				123:begin g0_idx=6;g1_idx=5;g2_idx=0;g3_idx=7;g4_idx=2;over=0; end
				124:begin g0_idx=5;g1_idx=0;g2_idx=7;g3_idx=6;g4_idx=2;over=0; end
				125:begin g0_idx=7;g1_idx=0;g2_idx=5;g3_idx=6;g4_idx=2;over=0; end
				126:begin g0_idx=5;g1_idx=7;g2_idx=0;g3_idx=6;g4_idx=2;over=0; end
				127:begin g0_idx=7;g1_idx=5;g2_idx=0;g3_idx=6;g4_idx=2;over=0; end
				128:begin g0_idx=6;g1_idx=0;g2_idx=7;g3_idx=5;g4_idx=2;over=0; end
				129:begin g0_idx=7;g1_idx=0;g2_idx=6;g3_idx=5;g4_idx=2;over=0; end
				130:begin g0_idx=6;g1_idx=7;g2_idx=0;g3_idx=5;g4_idx=2;over=0; end
				131:begin g0_idx=7;g1_idx=6;g2_idx=0;g3_idx=5;g4_idx=2;over=0; end
				132:begin g0_idx=5;g1_idx=6;g2_idx=7;g3_idx=0;g4_idx=2;over=0; end
				133:begin g0_idx=6;g1_idx=5;g2_idx=7;g3_idx=0;g4_idx=2;over=0; end
				134:begin g0_idx=5;g1_idx=7;g2_idx=6;g3_idx=0;g4_idx=2;over=0; end
				135:begin g0_idx=7;g1_idx=5;g2_idx=6;g3_idx=0;g4_idx=2;over=0; end
				136:begin g0_idx=6;g1_idx=7;g2_idx=5;g3_idx=0;g4_idx=2;over=0; end
				137:begin g0_idx=7;g1_idx=6;g2_idx=5;g3_idx=0;g4_idx=2;over=0; end
				138:begin g0_idx=2;g1_idx=5;g2_idx=6;g3_idx=7;g4_idx=0;over=0; end
				139:begin g0_idx=5;g1_idx=2;g2_idx=6;g3_idx=7;g4_idx=0;over=0; end
				140:begin g0_idx=2;g1_idx=6;g2_idx=5;g3_idx=7;g4_idx=0;over=0; end
				141:begin g0_idx=6;g1_idx=2;g2_idx=5;g3_idx=7;g4_idx=0;over=0; end
				142:begin g0_idx=2;g1_idx=5;g2_idx=7;g3_idx=6;g4_idx=0;over=0; end
				143:begin g0_idx=5;g1_idx=2;g2_idx=7;g3_idx=6;g4_idx=0;over=0; end
				144:begin g0_idx=2;g1_idx=7;g2_idx=5;g3_idx=6;g4_idx=0;over=0; end
				145:begin g0_idx=7;g1_idx=2;g2_idx=5;g3_idx=6;g4_idx=0;over=0; end
				146:begin g0_idx=2;g1_idx=6;g2_idx=7;g3_idx=5;g4_idx=0;over=0; end
				147:begin g0_idx=6;g1_idx=2;g2_idx=7;g3_idx=5;g4_idx=0;over=0; end
				148:begin g0_idx=2;g1_idx=7;g2_idx=6;g3_idx=5;g4_idx=0;over=0; end
				149:begin g0_idx=7;g1_idx=2;g2_idx=6;g3_idx=5;g4_idx=0;over=0; end
				150:begin g0_idx=5;g1_idx=6;g2_idx=7;g3_idx=2;g4_idx=0;over=0; end
				151:begin g0_idx=6;g1_idx=5;g2_idx=7;g3_idx=2;g4_idx=0;over=0; end
				152:begin g0_idx=5;g1_idx=7;g2_idx=6;g3_idx=2;g4_idx=0;over=0; end
				153:begin g0_idx=7;g1_idx=5;g2_idx=6;g3_idx=2;g4_idx=0;over=0; end
				154:begin g0_idx=6;g1_idx=7;g2_idx=5;g3_idx=2;g4_idx=0;over=0; end
				155:begin g0_idx=7;g1_idx=6;g2_idx=5;g3_idx=2;g4_idx=0;over=0; end
				156:begin g0_idx=1;g1_idx=2;g2_idx=5;g3_idx=6;g4_idx=7;over=0; end
				157:begin g0_idx=2;g1_idx=5;g2_idx=1;g3_idx=6;g4_idx=7;over=0; end
				158:begin g0_idx=5;g1_idx=2;g2_idx=1;g3_idx=6;g4_idx=7;over=0; end
				159:begin g0_idx=1;g1_idx=2;g2_idx=6;g3_idx=5;g4_idx=7;over=0; end
				160:begin g0_idx=2;g1_idx=6;g2_idx=1;g3_idx=5;g4_idx=7;over=0; end
				161:begin g0_idx=6;g1_idx=2;g2_idx=1;g3_idx=5;g4_idx=7;over=0; end
				162:begin g0_idx=1;g1_idx=5;g2_idx=6;g3_idx=2;g4_idx=7;over=0; end
				163:begin g0_idx=1;g1_idx=6;g2_idx=5;g3_idx=2;g4_idx=7;over=0; end
				164:begin g0_idx=5;g1_idx=6;g2_idx=1;g3_idx=2;g4_idx=7;over=0; end
				165:begin g0_idx=6;g1_idx=5;g2_idx=1;g3_idx=2;g4_idx=7;over=0; end
				166:begin g0_idx=2;g1_idx=5;g2_idx=6;g3_idx=1;g4_idx=7;over=0; end
				167:begin g0_idx=5;g1_idx=2;g2_idx=6;g3_idx=1;g4_idx=7;over=0; end
				168:begin g0_idx=2;g1_idx=6;g2_idx=5;g3_idx=1;g4_idx=7;over=0; end
				169:begin g0_idx=6;g1_idx=2;g2_idx=5;g3_idx=1;g4_idx=7;over=0; end
				170:begin g0_idx=1;g1_idx=2;g2_idx=5;g3_idx=7;g4_idx=6;over=0; end
				171:begin g0_idx=2;g1_idx=5;g2_idx=1;g3_idx=7;g4_idx=6;over=0; end
				172:begin g0_idx=5;g1_idx=2;g2_idx=1;g3_idx=7;g4_idx=6;over=0; end
				173:begin g0_idx=1;g1_idx=2;g2_idx=7;g3_idx=5;g4_idx=6;over=0; end
				174:begin g0_idx=2;g1_idx=7;g2_idx=1;g3_idx=5;g4_idx=6;over=0; end
				175:begin g0_idx=7;g1_idx=2;g2_idx=1;g3_idx=5;g4_idx=6;over=0; end
				176:begin g0_idx=1;g1_idx=5;g2_idx=7;g3_idx=2;g4_idx=6;over=0; end
				177:begin g0_idx=1;g1_idx=7;g2_idx=5;g3_idx=2;g4_idx=6;over=0; end
				178:begin g0_idx=5;g1_idx=7;g2_idx=1;g3_idx=2;g4_idx=6;over=0; end
				179:begin g0_idx=7;g1_idx=5;g2_idx=1;g3_idx=2;g4_idx=6;over=0; end
				180:begin g0_idx=2;g1_idx=5;g2_idx=7;g3_idx=1;g4_idx=6;over=0; end
				181:begin g0_idx=5;g1_idx=2;g2_idx=7;g3_idx=1;g4_idx=6;over=0; end
				182:begin g0_idx=2;g1_idx=7;g2_idx=5;g3_idx=1;g4_idx=6;over=0; end
				183:begin g0_idx=7;g1_idx=2;g2_idx=5;g3_idx=1;g4_idx=6;over=0; end
				184:begin g0_idx=1;g1_idx=2;g2_idx=6;g3_idx=7;g4_idx=5;over=0; end
				185:begin g0_idx=2;g1_idx=6;g2_idx=1;g3_idx=7;g4_idx=5;over=0; end
				186:begin g0_idx=6;g1_idx=2;g2_idx=1;g3_idx=7;g4_idx=5;over=0; end
				187:begin g0_idx=1;g1_idx=2;g2_idx=7;g3_idx=6;g4_idx=5;over=0; end
				188:begin g0_idx=2;g1_idx=7;g2_idx=1;g3_idx=6;g4_idx=5;over=0; end
				189:begin g0_idx=7;g1_idx=2;g2_idx=1;g3_idx=6;g4_idx=5;over=0; end
				190:begin g0_idx=1;g1_idx=6;g2_idx=7;g3_idx=2;g4_idx=5;over=0; end
				191:begin g0_idx=1;g1_idx=7;g2_idx=6;g3_idx=2;g4_idx=5;over=0; end
				192:begin g0_idx=6;g1_idx=7;g2_idx=1;g3_idx=2;g4_idx=5;over=0; end
				193:begin g0_idx=7;g1_idx=6;g2_idx=1;g3_idx=2;g4_idx=5;over=0; end
				194:begin g0_idx=2;g1_idx=6;g2_idx=7;g3_idx=1;g4_idx=5;over=0; end
				195:begin g0_idx=6;g1_idx=2;g2_idx=7;g3_idx=1;g4_idx=5;over=0; end
				196:begin g0_idx=2;g1_idx=7;g2_idx=6;g3_idx=1;g4_idx=5;over=0; end
				197:begin g0_idx=7;g1_idx=2;g2_idx=6;g3_idx=1;g4_idx=5;over=0; end
				198:begin g0_idx=1;g1_idx=5;g2_idx=6;g3_idx=7;g4_idx=2;over=0; end
				199:begin g0_idx=1;g1_idx=6;g2_idx=5;g3_idx=7;g4_idx=2;over=0; end
				200:begin g0_idx=5;g1_idx=6;g2_idx=1;g3_idx=7;g4_idx=2;over=0; end
				201:begin g0_idx=6;g1_idx=5;g2_idx=1;g3_idx=7;g4_idx=2;over=0; end
				202:begin g0_idx=1;g1_idx=5;g2_idx=7;g3_idx=6;g4_idx=2;over=0; end
				203:begin g0_idx=1;g1_idx=7;g2_idx=5;g3_idx=6;g4_idx=2;over=0; end
				204:begin g0_idx=5;g1_idx=7;g2_idx=1;g3_idx=6;g4_idx=2;over=0; end
				205:begin g0_idx=7;g1_idx=5;g2_idx=1;g3_idx=6;g4_idx=2;over=0; end
				206:begin g0_idx=1;g1_idx=6;g2_idx=7;g3_idx=5;g4_idx=2;over=0; end
				207:begin g0_idx=1;g1_idx=7;g2_idx=6;g3_idx=5;g4_idx=2;over=0; end
				208:begin g0_idx=6;g1_idx=7;g2_idx=1;g3_idx=5;g4_idx=2;over=0; end
				209:begin g0_idx=7;g1_idx=6;g2_idx=1;g3_idx=5;g4_idx=2;over=0; end
				210:begin g0_idx=5;g1_idx=6;g2_idx=7;g3_idx=1;g4_idx=2;over=0; end
				211:begin g0_idx=6;g1_idx=5;g2_idx=7;g3_idx=1;g4_idx=2;over=0; end
				212:begin g0_idx=5;g1_idx=7;g2_idx=6;g3_idx=1;g4_idx=2;over=0; end
				213:begin g0_idx=7;g1_idx=5;g2_idx=6;g3_idx=1;g4_idx=2;over=0; end
				214:begin g0_idx=6;g1_idx=7;g2_idx=5;g3_idx=1;g4_idx=2;over=0; end
				215:begin g0_idx=7;g1_idx=6;g2_idx=5;g3_idx=1;g4_idx=2;over=0; end
				216:begin g0_idx=2;g1_idx=5;g2_idx=6;g3_idx=7;g4_idx=1;over=0; end
				217:begin g0_idx=5;g1_idx=2;g2_idx=6;g3_idx=7;g4_idx=1;over=0; end
				218:begin g0_idx=2;g1_idx=6;g2_idx=5;g3_idx=7;g4_idx=1;over=0; end
				219:begin g0_idx=6;g1_idx=2;g2_idx=5;g3_idx=7;g4_idx=1;over=0; end
				220:begin g0_idx=2;g1_idx=5;g2_idx=7;g3_idx=6;g4_idx=1;over=0; end
				221:begin g0_idx=5;g1_idx=2;g2_idx=7;g3_idx=6;g4_idx=1;over=0; end
				222:begin g0_idx=2;g1_idx=7;g2_idx=5;g3_idx=6;g4_idx=1;over=0; end
				223:begin g0_idx=7;g1_idx=2;g2_idx=5;g3_idx=6;g4_idx=1;over=0; end
				224:begin g0_idx=2;g1_idx=6;g2_idx=7;g3_idx=5;g4_idx=1;over=0; end
				225:begin g0_idx=6;g1_idx=2;g2_idx=7;g3_idx=5;g4_idx=1;over=0; end
				226:begin g0_idx=2;g1_idx=7;g2_idx=6;g3_idx=5;g4_idx=1;over=0; end
				227:begin g0_idx=7;g1_idx=2;g2_idx=6;g3_idx=5;g4_idx=1;over=0; end
				228:begin g0_idx=5;g1_idx=6;g2_idx=7;g3_idx=2;g4_idx=1;over=0; end
				229:begin g0_idx=6;g1_idx=5;g2_idx=7;g3_idx=2;g4_idx=1;over=0; end
				230:begin g0_idx=5;g1_idx=7;g2_idx=6;g3_idx=2;g4_idx=1;over=0; end
				231:begin g0_idx=7;g1_idx=5;g2_idx=6;g3_idx=2;g4_idx=1;over=0; end
				232:begin g0_idx=6;g1_idx=7;g2_idx=5;g3_idx=2;g4_idx=1;over=0; end
				233:begin g0_idx=7;g1_idx=6;g2_idx=5;g3_idx=2;g4_idx=1;over=0; end
				234:begin g0_idx=3;g1_idx=0;g2_idx=5;g3_idx=6;g4_idx=7;over=0; end
				235:begin g0_idx=5;g1_idx=0;g2_idx=3;g3_idx=6;g4_idx=7;over=0; end
				236:begin g0_idx=3;g1_idx=5;g2_idx=0;g3_idx=6;g4_idx=7;over=0; end
				237:begin g0_idx=5;g1_idx=3;g2_idx=0;g3_idx=6;g4_idx=7;over=0; end
				238:begin g0_idx=3;g1_idx=0;g2_idx=6;g3_idx=5;g4_idx=7;over=0; end
				239:begin g0_idx=6;g1_idx=0;g2_idx=3;g3_idx=5;g4_idx=7;over=0; end
				240:begin g0_idx=3;g1_idx=6;g2_idx=0;g3_idx=5;g4_idx=7;over=0; end
				241:begin g0_idx=6;g1_idx=3;g2_idx=0;g3_idx=5;g4_idx=7;over=0; end
				242:begin g0_idx=3;g1_idx=5;g2_idx=6;g3_idx=0;g4_idx=7;over=0; end
				243:begin g0_idx=5;g1_idx=3;g2_idx=6;g3_idx=0;g4_idx=7;over=0; end
				244:begin g0_idx=3;g1_idx=6;g2_idx=5;g3_idx=0;g4_idx=7;over=0; end
				245:begin g0_idx=6;g1_idx=3;g2_idx=5;g3_idx=0;g4_idx=7;over=0; end
				246:begin g0_idx=5;g1_idx=6;g2_idx=3;g3_idx=0;g4_idx=7;over=0; end
				247:begin g0_idx=6;g1_idx=5;g2_idx=3;g3_idx=0;g4_idx=7;over=0; end
				248:begin g0_idx=3;g1_idx=0;g2_idx=5;g3_idx=7;g4_idx=6;over=0; end
				249:begin g0_idx=5;g1_idx=0;g2_idx=3;g3_idx=7;g4_idx=6;over=0; end
				250:begin g0_idx=3;g1_idx=5;g2_idx=0;g3_idx=7;g4_idx=6;over=0; end
				251:begin g0_idx=5;g1_idx=3;g2_idx=0;g3_idx=7;g4_idx=6;over=0; end
				252:begin g0_idx=3;g1_idx=0;g2_idx=7;g3_idx=5;g4_idx=6;over=0; end
				253:begin g0_idx=7;g1_idx=0;g2_idx=3;g3_idx=5;g4_idx=6;over=0; end
				254:begin g0_idx=3;g1_idx=7;g2_idx=0;g3_idx=5;g4_idx=6;over=0; end
				255:begin g0_idx=7;g1_idx=3;g2_idx=0;g3_idx=5;g4_idx=6;over=0; end
				256:begin g0_idx=3;g1_idx=5;g2_idx=7;g3_idx=0;g4_idx=6;over=0; end
				257:begin g0_idx=5;g1_idx=3;g2_idx=7;g3_idx=0;g4_idx=6;over=0; end
				258:begin g0_idx=3;g1_idx=7;g2_idx=5;g3_idx=0;g4_idx=6;over=0; end
				259:begin g0_idx=7;g1_idx=3;g2_idx=5;g3_idx=0;g4_idx=6;over=0; end
				260:begin g0_idx=5;g1_idx=7;g2_idx=3;g3_idx=0;g4_idx=6;over=0; end
				261:begin g0_idx=7;g1_idx=5;g2_idx=3;g3_idx=0;g4_idx=6;over=0; end
				262:begin g0_idx=3;g1_idx=0;g2_idx=6;g3_idx=7;g4_idx=5;over=0; end
				263:begin g0_idx=6;g1_idx=0;g2_idx=3;g3_idx=7;g4_idx=5;over=0; end
				264:begin g0_idx=3;g1_idx=6;g2_idx=0;g3_idx=7;g4_idx=5;over=0; end
				265:begin g0_idx=6;g1_idx=3;g2_idx=0;g3_idx=7;g4_idx=5;over=0; end
				266:begin g0_idx=3;g1_idx=0;g2_idx=7;g3_idx=6;g4_idx=5;over=0; end
				267:begin g0_idx=7;g1_idx=0;g2_idx=3;g3_idx=6;g4_idx=5;over=0; end
				268:begin g0_idx=3;g1_idx=7;g2_idx=0;g3_idx=6;g4_idx=5;over=0; end
				269:begin g0_idx=7;g1_idx=3;g2_idx=0;g3_idx=6;g4_idx=5;over=0; end
				270:begin g0_idx=3;g1_idx=6;g2_idx=7;g3_idx=0;g4_idx=5;over=0; end
				271:begin g0_idx=6;g1_idx=3;g2_idx=7;g3_idx=0;g4_idx=5;over=0; end
				272:begin g0_idx=3;g1_idx=7;g2_idx=6;g3_idx=0;g4_idx=5;over=0; end
				273:begin g0_idx=7;g1_idx=3;g2_idx=6;g3_idx=0;g4_idx=5;over=0; end
				274:begin g0_idx=6;g1_idx=7;g2_idx=3;g3_idx=0;g4_idx=5;over=0; end
				275:begin g0_idx=7;g1_idx=6;g2_idx=3;g3_idx=0;g4_idx=5;over=0; end
				276:begin g0_idx=5;g1_idx=0;g2_idx=6;g3_idx=7;g4_idx=3;over=0; end
				277:begin g0_idx=6;g1_idx=0;g2_idx=5;g3_idx=7;g4_idx=3;over=0; end
				278:begin g0_idx=5;g1_idx=6;g2_idx=0;g3_idx=7;g4_idx=3;over=0; end
				279:begin g0_idx=6;g1_idx=5;g2_idx=0;g3_idx=7;g4_idx=3;over=0; end
				280:begin g0_idx=5;g1_idx=0;g2_idx=7;g3_idx=6;g4_idx=3;over=0; end
				281:begin g0_idx=7;g1_idx=0;g2_idx=5;g3_idx=6;g4_idx=3;over=0; end
				282:begin g0_idx=5;g1_idx=7;g2_idx=0;g3_idx=6;g4_idx=3;over=0; end
				283:begin g0_idx=7;g1_idx=5;g2_idx=0;g3_idx=6;g4_idx=3;over=0; end
				284:begin g0_idx=6;g1_idx=0;g2_idx=7;g3_idx=5;g4_idx=3;over=0; end
				285:begin g0_idx=7;g1_idx=0;g2_idx=6;g3_idx=5;g4_idx=3;over=0; end
				286:begin g0_idx=6;g1_idx=7;g2_idx=0;g3_idx=5;g4_idx=3;over=0; end
				287:begin g0_idx=7;g1_idx=6;g2_idx=0;g3_idx=5;g4_idx=3;over=0; end
				288:begin g0_idx=5;g1_idx=6;g2_idx=7;g3_idx=0;g4_idx=3;over=0; end
				289:begin g0_idx=6;g1_idx=5;g2_idx=7;g3_idx=0;g4_idx=3;over=0; end
				290:begin g0_idx=5;g1_idx=7;g2_idx=6;g3_idx=0;g4_idx=3;over=0; end
				291:begin g0_idx=7;g1_idx=5;g2_idx=6;g3_idx=0;g4_idx=3;over=0; end
				292:begin g0_idx=6;g1_idx=7;g2_idx=5;g3_idx=0;g4_idx=3;over=0; end
				293:begin g0_idx=7;g1_idx=6;g2_idx=5;g3_idx=0;g4_idx=3;over=0; end
				294:begin g0_idx=3;g1_idx=5;g2_idx=6;g3_idx=7;g4_idx=0;over=0; end
				295:begin g0_idx=5;g1_idx=3;g2_idx=6;g3_idx=7;g4_idx=0;over=0; end
				296:begin g0_idx=3;g1_idx=6;g2_idx=5;g3_idx=7;g4_idx=0;over=0; end
				297:begin g0_idx=6;g1_idx=3;g2_idx=5;g3_idx=7;g4_idx=0;over=0; end
				298:begin g0_idx=5;g1_idx=6;g2_idx=3;g3_idx=7;g4_idx=0;over=0; end
				299:begin g0_idx=6;g1_idx=5;g2_idx=3;g3_idx=7;g4_idx=0;over=0; end
				300:begin g0_idx=3;g1_idx=5;g2_idx=7;g3_idx=6;g4_idx=0;over=0; end
				301:begin g0_idx=5;g1_idx=3;g2_idx=7;g3_idx=6;g4_idx=0;over=0; end
				302:begin g0_idx=3;g1_idx=7;g2_idx=5;g3_idx=6;g4_idx=0;over=0; end
				303:begin g0_idx=7;g1_idx=3;g2_idx=5;g3_idx=6;g4_idx=0;over=0; end
				304:begin g0_idx=5;g1_idx=7;g2_idx=3;g3_idx=6;g4_idx=0;over=0; end
				305:begin g0_idx=7;g1_idx=5;g2_idx=3;g3_idx=6;g4_idx=0;over=0; end
				306:begin g0_idx=3;g1_idx=6;g2_idx=7;g3_idx=5;g4_idx=0;over=0; end
				307:begin g0_idx=6;g1_idx=3;g2_idx=7;g3_idx=5;g4_idx=0;over=0; end
				308:begin g0_idx=3;g1_idx=7;g2_idx=6;g3_idx=5;g4_idx=0;over=0; end
				309:begin g0_idx=7;g1_idx=3;g2_idx=6;g3_idx=5;g4_idx=0;over=0; end
				310:begin g0_idx=6;g1_idx=7;g2_idx=3;g3_idx=5;g4_idx=0;over=0; end
				311:begin g0_idx=7;g1_idx=6;g2_idx=3;g3_idx=5;g4_idx=0;over=0; end
				312:begin g0_idx=1;g1_idx=3;g2_idx=5;g3_idx=6;g4_idx=7;over=0; end
				313:begin g0_idx=1;g1_idx=5;g2_idx=3;g3_idx=6;g4_idx=7;over=0; end
				314:begin g0_idx=3;g1_idx=5;g2_idx=1;g3_idx=6;g4_idx=7;over=0; end
				315:begin g0_idx=5;g1_idx=3;g2_idx=1;g3_idx=6;g4_idx=7;over=0; end
				316:begin g0_idx=1;g1_idx=3;g2_idx=6;g3_idx=5;g4_idx=7;over=0; end
				317:begin g0_idx=1;g1_idx=6;g2_idx=3;g3_idx=5;g4_idx=7;over=0; end
				318:begin g0_idx=3;g1_idx=6;g2_idx=1;g3_idx=5;g4_idx=7;over=0; end
				319:begin g0_idx=6;g1_idx=3;g2_idx=1;g3_idx=5;g4_idx=7;over=0; end
				320:begin g0_idx=3;g1_idx=5;g2_idx=6;g3_idx=1;g4_idx=7;over=0; end
				321:begin g0_idx=5;g1_idx=3;g2_idx=6;g3_idx=1;g4_idx=7;over=0; end
				322:begin g0_idx=3;g1_idx=6;g2_idx=5;g3_idx=1;g4_idx=7;over=0; end
				323:begin g0_idx=6;g1_idx=3;g2_idx=5;g3_idx=1;g4_idx=7;over=0; end
				324:begin g0_idx=5;g1_idx=6;g2_idx=3;g3_idx=1;g4_idx=7;over=0; end
				325:begin g0_idx=6;g1_idx=5;g2_idx=3;g3_idx=1;g4_idx=7;over=0; end
				326:begin g0_idx=1;g1_idx=3;g2_idx=5;g3_idx=7;g4_idx=6;over=0; end
				327:begin g0_idx=1;g1_idx=5;g2_idx=3;g3_idx=7;g4_idx=6;over=0; end
				328:begin g0_idx=3;g1_idx=5;g2_idx=1;g3_idx=7;g4_idx=6;over=0; end
				329:begin g0_idx=5;g1_idx=3;g2_idx=1;g3_idx=7;g4_idx=6;over=0; end
				330:begin g0_idx=1;g1_idx=3;g2_idx=7;g3_idx=5;g4_idx=6;over=0; end
				331:begin g0_idx=1;g1_idx=7;g2_idx=3;g3_idx=5;g4_idx=6;over=0; end
				332:begin g0_idx=3;g1_idx=7;g2_idx=1;g3_idx=5;g4_idx=6;over=0; end
				333:begin g0_idx=7;g1_idx=3;g2_idx=1;g3_idx=5;g4_idx=6;over=0; end
				334:begin g0_idx=3;g1_idx=5;g2_idx=7;g3_idx=1;g4_idx=6;over=0; end
				335:begin g0_idx=5;g1_idx=3;g2_idx=7;g3_idx=1;g4_idx=6;over=0; end
				336:begin g0_idx=3;g1_idx=7;g2_idx=5;g3_idx=1;g4_idx=6;over=0; end
				337:begin g0_idx=7;g1_idx=3;g2_idx=5;g3_idx=1;g4_idx=6;over=0; end
				338:begin g0_idx=5;g1_idx=7;g2_idx=3;g3_idx=1;g4_idx=6;over=0; end
				339:begin g0_idx=7;g1_idx=5;g2_idx=3;g3_idx=1;g4_idx=6;over=0; end
				340:begin g0_idx=1;g1_idx=3;g2_idx=6;g3_idx=7;g4_idx=5;over=0; end
				341:begin g0_idx=1;g1_idx=6;g2_idx=3;g3_idx=7;g4_idx=5;over=0; end
				342:begin g0_idx=3;g1_idx=6;g2_idx=1;g3_idx=7;g4_idx=5;over=0; end
				343:begin g0_idx=6;g1_idx=3;g2_idx=1;g3_idx=7;g4_idx=5;over=0; end
				344:begin g0_idx=1;g1_idx=3;g2_idx=7;g3_idx=6;g4_idx=5;over=0; end
				345:begin g0_idx=1;g1_idx=7;g2_idx=3;g3_idx=6;g4_idx=5;over=0; end
				346:begin g0_idx=3;g1_idx=7;g2_idx=1;g3_idx=6;g4_idx=5;over=0; end
				347:begin g0_idx=7;g1_idx=3;g2_idx=1;g3_idx=6;g4_idx=5;over=0; end
				348:begin g0_idx=3;g1_idx=6;g2_idx=7;g3_idx=1;g4_idx=5;over=0; end
				349:begin g0_idx=6;g1_idx=3;g2_idx=7;g3_idx=1;g4_idx=5;over=0; end
				350:begin g0_idx=3;g1_idx=7;g2_idx=6;g3_idx=1;g4_idx=5;over=0; end
				351:begin g0_idx=7;g1_idx=3;g2_idx=6;g3_idx=1;g4_idx=5;over=0; end
				352:begin g0_idx=6;g1_idx=7;g2_idx=3;g3_idx=1;g4_idx=5;over=0; end
				353:begin g0_idx=7;g1_idx=6;g2_idx=3;g3_idx=1;g4_idx=5;over=0; end
				354:begin g0_idx=1;g1_idx=5;g2_idx=6;g3_idx=7;g4_idx=3;over=0; end
				355:begin g0_idx=1;g1_idx=6;g2_idx=5;g3_idx=7;g4_idx=3;over=0; end
				356:begin g0_idx=5;g1_idx=6;g2_idx=1;g3_idx=7;g4_idx=3;over=0; end
				357:begin g0_idx=6;g1_idx=5;g2_idx=1;g3_idx=7;g4_idx=3;over=0; end
				358:begin g0_idx=1;g1_idx=5;g2_idx=7;g3_idx=6;g4_idx=3;over=0; end
				359:begin g0_idx=1;g1_idx=7;g2_idx=5;g3_idx=6;g4_idx=3;over=0; end
				360:begin g0_idx=5;g1_idx=7;g2_idx=1;g3_idx=6;g4_idx=3;over=0; end
				361:begin g0_idx=7;g1_idx=5;g2_idx=1;g3_idx=6;g4_idx=3;over=0; end
				362:begin g0_idx=1;g1_idx=6;g2_idx=7;g3_idx=5;g4_idx=3;over=0; end
				363:begin g0_idx=1;g1_idx=7;g2_idx=6;g3_idx=5;g4_idx=3;over=0; end
				364:begin g0_idx=6;g1_idx=7;g2_idx=1;g3_idx=5;g4_idx=3;over=0; end
				365:begin g0_idx=7;g1_idx=6;g2_idx=1;g3_idx=5;g4_idx=3;over=0; end
				366:begin g0_idx=5;g1_idx=6;g2_idx=7;g3_idx=1;g4_idx=3;over=0; end
				367:begin g0_idx=6;g1_idx=5;g2_idx=7;g3_idx=1;g4_idx=3;over=0; end
				368:begin g0_idx=5;g1_idx=7;g2_idx=6;g3_idx=1;g4_idx=3;over=0; end
				369:begin g0_idx=7;g1_idx=5;g2_idx=6;g3_idx=1;g4_idx=3;over=0; end
				370:begin g0_idx=6;g1_idx=7;g2_idx=5;g3_idx=1;g4_idx=3;over=0; end
				371:begin g0_idx=7;g1_idx=6;g2_idx=5;g3_idx=1;g4_idx=3;over=0; end
				372:begin g0_idx=3;g1_idx=5;g2_idx=6;g3_idx=7;g4_idx=1;over=0; end
				373:begin g0_idx=5;g1_idx=3;g2_idx=6;g3_idx=7;g4_idx=1;over=0; end
				374:begin g0_idx=3;g1_idx=6;g2_idx=5;g3_idx=7;g4_idx=1;over=0; end
				375:begin g0_idx=6;g1_idx=3;g2_idx=5;g3_idx=7;g4_idx=1;over=0; end
				376:begin g0_idx=5;g1_idx=6;g2_idx=3;g3_idx=7;g4_idx=1;over=0; end
				377:begin g0_idx=6;g1_idx=5;g2_idx=3;g3_idx=7;g4_idx=1;over=0; end
				378:begin g0_idx=3;g1_idx=5;g2_idx=7;g3_idx=6;g4_idx=1;over=0; end
				379:begin g0_idx=5;g1_idx=3;g2_idx=7;g3_idx=6;g4_idx=1;over=0; end
				380:begin g0_idx=3;g1_idx=7;g2_idx=5;g3_idx=6;g4_idx=1;over=0; end
				381:begin g0_idx=7;g1_idx=3;g2_idx=5;g3_idx=6;g4_idx=1;over=0; end
				382:begin g0_idx=5;g1_idx=7;g2_idx=3;g3_idx=6;g4_idx=1;over=0; end
				383:begin g0_idx=7;g1_idx=5;g2_idx=3;g3_idx=6;g4_idx=1;over=0; end
				384:begin g0_idx=3;g1_idx=6;g2_idx=7;g3_idx=5;g4_idx=1;over=0; end
				385:begin g0_idx=6;g1_idx=3;g2_idx=7;g3_idx=5;g4_idx=1;over=0; end
				386:begin g0_idx=3;g1_idx=7;g2_idx=6;g3_idx=5;g4_idx=1;over=0; end
				387:begin g0_idx=7;g1_idx=3;g2_idx=6;g3_idx=5;g4_idx=1;over=0; end
				388:begin g0_idx=6;g1_idx=7;g2_idx=3;g3_idx=5;g4_idx=1;over=0; end
				389:begin g0_idx=7;g1_idx=6;g2_idx=3;g3_idx=5;g4_idx=1;over=0; end
				390:begin g0_idx=2;g1_idx=3;g2_idx=5;g3_idx=6;g4_idx=7;over=0; end
				391:begin g0_idx=3;g1_idx=2;g2_idx=5;g3_idx=6;g4_idx=7;over=0; end
				392:begin g0_idx=2;g1_idx=5;g2_idx=3;g3_idx=6;g4_idx=7;over=0; end
				393:begin g0_idx=5;g1_idx=2;g2_idx=3;g3_idx=6;g4_idx=7;over=0; end
				394:begin g0_idx=2;g1_idx=3;g2_idx=6;g3_idx=5;g4_idx=7;over=0; end
				395:begin g0_idx=3;g1_idx=2;g2_idx=6;g3_idx=5;g4_idx=7;over=0; end
				396:begin g0_idx=2;g1_idx=6;g2_idx=3;g3_idx=5;g4_idx=7;over=0; end
				397:begin g0_idx=6;g1_idx=2;g2_idx=3;g3_idx=5;g4_idx=7;over=0; end
				398:begin g0_idx=3;g1_idx=5;g2_idx=6;g3_idx=2;g4_idx=7;over=0; end
				399:begin g0_idx=5;g1_idx=3;g2_idx=6;g3_idx=2;g4_idx=7;over=0; end
				400:begin g0_idx=3;g1_idx=6;g2_idx=5;g3_idx=2;g4_idx=7;over=0; end
				401:begin g0_idx=6;g1_idx=3;g2_idx=5;g3_idx=2;g4_idx=7;over=0; end
				402:begin g0_idx=5;g1_idx=6;g2_idx=3;g3_idx=2;g4_idx=7;over=0; end
				403:begin g0_idx=6;g1_idx=5;g2_idx=3;g3_idx=2;g4_idx=7;over=0; end
				404:begin g0_idx=2;g1_idx=3;g2_idx=5;g3_idx=7;g4_idx=6;over=0; end
				405:begin g0_idx=3;g1_idx=2;g2_idx=5;g3_idx=7;g4_idx=6;over=0; end
				406:begin g0_idx=2;g1_idx=5;g2_idx=3;g3_idx=7;g4_idx=6;over=0; end
				407:begin g0_idx=5;g1_idx=2;g2_idx=3;g3_idx=7;g4_idx=6;over=0; end
				408:begin g0_idx=2;g1_idx=3;g2_idx=7;g3_idx=5;g4_idx=6;over=0; end
				409:begin g0_idx=3;g1_idx=2;g2_idx=7;g3_idx=5;g4_idx=6;over=0; end
				410:begin g0_idx=2;g1_idx=7;g2_idx=3;g3_idx=5;g4_idx=6;over=0; end
				411:begin g0_idx=7;g1_idx=2;g2_idx=3;g3_idx=5;g4_idx=6;over=0; end
				412:begin g0_idx=3;g1_idx=5;g2_idx=7;g3_idx=2;g4_idx=6;over=0; end
				413:begin g0_idx=5;g1_idx=3;g2_idx=7;g3_idx=2;g4_idx=6;over=0; end
				414:begin g0_idx=3;g1_idx=7;g2_idx=5;g3_idx=2;g4_idx=6;over=0; end
				415:begin g0_idx=7;g1_idx=3;g2_idx=5;g3_idx=2;g4_idx=6;over=0; end
				416:begin g0_idx=5;g1_idx=7;g2_idx=3;g3_idx=2;g4_idx=6;over=0; end
				417:begin g0_idx=7;g1_idx=5;g2_idx=3;g3_idx=2;g4_idx=6;over=0; end
				418:begin g0_idx=2;g1_idx=3;g2_idx=6;g3_idx=7;g4_idx=5;over=0; end
				419:begin g0_idx=3;g1_idx=2;g2_idx=6;g3_idx=7;g4_idx=5;over=0; end
				420:begin g0_idx=2;g1_idx=6;g2_idx=3;g3_idx=7;g4_idx=5;over=0; end
				421:begin g0_idx=6;g1_idx=2;g2_idx=3;g3_idx=7;g4_idx=5;over=0; end
				422:begin g0_idx=2;g1_idx=3;g2_idx=7;g3_idx=6;g4_idx=5;over=0; end
				423:begin g0_idx=3;g1_idx=2;g2_idx=7;g3_idx=6;g4_idx=5;over=0; end
				424:begin g0_idx=2;g1_idx=7;g2_idx=3;g3_idx=6;g4_idx=5;over=0; end
				425:begin g0_idx=7;g1_idx=2;g2_idx=3;g3_idx=6;g4_idx=5;over=0; end
				426:begin g0_idx=3;g1_idx=6;g2_idx=7;g3_idx=2;g4_idx=5;over=0; end
				427:begin g0_idx=6;g1_idx=3;g2_idx=7;g3_idx=2;g4_idx=5;over=0; end
				428:begin g0_idx=3;g1_idx=7;g2_idx=6;g3_idx=2;g4_idx=5;over=0; end
				429:begin g0_idx=7;g1_idx=3;g2_idx=6;g3_idx=2;g4_idx=5;over=0; end
				430:begin g0_idx=6;g1_idx=7;g2_idx=3;g3_idx=2;g4_idx=5;over=0; end
				431:begin g0_idx=7;g1_idx=6;g2_idx=3;g3_idx=2;g4_idx=5;over=0; end
				432:begin g0_idx=2;g1_idx=5;g2_idx=6;g3_idx=7;g4_idx=3;over=0; end
				433:begin g0_idx=5;g1_idx=2;g2_idx=6;g3_idx=7;g4_idx=3;over=0; end
				434:begin g0_idx=2;g1_idx=6;g2_idx=5;g3_idx=7;g4_idx=3;over=0; end
				435:begin g0_idx=6;g1_idx=2;g2_idx=5;g3_idx=7;g4_idx=3;over=0; end
				436:begin g0_idx=2;g1_idx=5;g2_idx=7;g3_idx=6;g4_idx=3;over=0; end
				437:begin g0_idx=5;g1_idx=2;g2_idx=7;g3_idx=6;g4_idx=3;over=0; end
				438:begin g0_idx=2;g1_idx=7;g2_idx=5;g3_idx=6;g4_idx=3;over=0; end
				439:begin g0_idx=7;g1_idx=2;g2_idx=5;g3_idx=6;g4_idx=3;over=0; end
				440:begin g0_idx=2;g1_idx=6;g2_idx=7;g3_idx=5;g4_idx=3;over=0; end
				441:begin g0_idx=6;g1_idx=2;g2_idx=7;g3_idx=5;g4_idx=3;over=0; end
				442:begin g0_idx=2;g1_idx=7;g2_idx=6;g3_idx=5;g4_idx=3;over=0; end
				443:begin g0_idx=7;g1_idx=2;g2_idx=6;g3_idx=5;g4_idx=3;over=0; end
				444:begin g0_idx=5;g1_idx=6;g2_idx=7;g3_idx=2;g4_idx=3;over=0; end
				445:begin g0_idx=6;g1_idx=5;g2_idx=7;g3_idx=2;g4_idx=3;over=0; end
				446:begin g0_idx=5;g1_idx=7;g2_idx=6;g3_idx=2;g4_idx=3;over=0; end
				447:begin g0_idx=7;g1_idx=5;g2_idx=6;g3_idx=2;g4_idx=3;over=0; end
				448:begin g0_idx=6;g1_idx=7;g2_idx=5;g3_idx=2;g4_idx=3;over=0; end
				449:begin g0_idx=7;g1_idx=6;g2_idx=5;g3_idx=2;g4_idx=3;over=0; end
				450:begin g0_idx=3;g1_idx=5;g2_idx=6;g3_idx=7;g4_idx=2;over=0; end
				451:begin g0_idx=5;g1_idx=3;g2_idx=6;g3_idx=7;g4_idx=2;over=0; end
				452:begin g0_idx=3;g1_idx=6;g2_idx=5;g3_idx=7;g4_idx=2;over=0; end
				453:begin g0_idx=6;g1_idx=3;g2_idx=5;g3_idx=7;g4_idx=2;over=0; end
				454:begin g0_idx=5;g1_idx=6;g2_idx=3;g3_idx=7;g4_idx=2;over=0; end
				455:begin g0_idx=6;g1_idx=5;g2_idx=3;g3_idx=7;g4_idx=2;over=0; end
				456:begin g0_idx=3;g1_idx=5;g2_idx=7;g3_idx=6;g4_idx=2;over=0; end
				457:begin g0_idx=5;g1_idx=3;g2_idx=7;g3_idx=6;g4_idx=2;over=0; end
				458:begin g0_idx=3;g1_idx=7;g2_idx=5;g3_idx=6;g4_idx=2;over=0; end
				459:begin g0_idx=7;g1_idx=3;g2_idx=5;g3_idx=6;g4_idx=2;over=0; end
				460:begin g0_idx=5;g1_idx=7;g2_idx=3;g3_idx=6;g4_idx=2;over=0; end
				461:begin g0_idx=7;g1_idx=5;g2_idx=3;g3_idx=6;g4_idx=2;over=0; end
				462:begin g0_idx=3;g1_idx=6;g2_idx=7;g3_idx=5;g4_idx=2;over=0; end
				463:begin g0_idx=6;g1_idx=3;g2_idx=7;g3_idx=5;g4_idx=2;over=0; end
				464:begin g0_idx=3;g1_idx=7;g2_idx=6;g3_idx=5;g4_idx=2;over=0; end
				465:begin g0_idx=7;g1_idx=3;g2_idx=6;g3_idx=5;g4_idx=2;over=0; end
				466:begin g0_idx=6;g1_idx=7;g2_idx=3;g3_idx=5;g4_idx=2;over=0; end
				467:begin g0_idx=7;g1_idx=6;g2_idx=3;g3_idx=5;g4_idx=2;over=0; end
				468:begin g0_idx=4;g1_idx=0;g2_idx=5;g3_idx=6;g4_idx=7;over=0; end
				469:begin g0_idx=5;g1_idx=0;g2_idx=4;g3_idx=6;g4_idx=7;over=0; end
				470:begin g0_idx=4;g1_idx=5;g2_idx=0;g3_idx=6;g4_idx=7;over=0; end
				471:begin g0_idx=5;g1_idx=4;g2_idx=0;g3_idx=6;g4_idx=7;over=0; end
				472:begin g0_idx=4;g1_idx=0;g2_idx=6;g3_idx=5;g4_idx=7;over=0; end
				473:begin g0_idx=6;g1_idx=0;g2_idx=4;g3_idx=5;g4_idx=7;over=0; end
				474:begin g0_idx=4;g1_idx=6;g2_idx=0;g3_idx=5;g4_idx=7;over=0; end
				475:begin g0_idx=6;g1_idx=4;g2_idx=0;g3_idx=5;g4_idx=7;over=0; end
				476:begin g0_idx=5;g1_idx=0;g2_idx=6;g3_idx=4;g4_idx=7;over=0; end
				477:begin g0_idx=6;g1_idx=0;g2_idx=5;g3_idx=4;g4_idx=7;over=0; end
				478:begin g0_idx=5;g1_idx=6;g2_idx=0;g3_idx=4;g4_idx=7;over=0; end
				479:begin g0_idx=6;g1_idx=5;g2_idx=0;g3_idx=4;g4_idx=7;over=0; end
				480:begin g0_idx=4;g1_idx=5;g2_idx=6;g3_idx=0;g4_idx=7;over=0; end
				481:begin g0_idx=5;g1_idx=4;g2_idx=6;g3_idx=0;g4_idx=7;over=0; end
				482:begin g0_idx=4;g1_idx=6;g2_idx=5;g3_idx=0;g4_idx=7;over=0; end
				483:begin g0_idx=6;g1_idx=4;g2_idx=5;g3_idx=0;g4_idx=7;over=0; end
				484:begin g0_idx=5;g1_idx=6;g2_idx=4;g3_idx=0;g4_idx=7;over=0; end
				485:begin g0_idx=6;g1_idx=5;g2_idx=4;g3_idx=0;g4_idx=7;over=0; end
				486:begin g0_idx=4;g1_idx=0;g2_idx=5;g3_idx=7;g4_idx=6;over=0; end
				487:begin g0_idx=5;g1_idx=0;g2_idx=4;g3_idx=7;g4_idx=6;over=0; end
				488:begin g0_idx=4;g1_idx=5;g2_idx=0;g3_idx=7;g4_idx=6;over=0; end
				489:begin g0_idx=5;g1_idx=4;g2_idx=0;g3_idx=7;g4_idx=6;over=0; end
				490:begin g0_idx=4;g1_idx=0;g2_idx=7;g3_idx=5;g4_idx=6;over=0; end
				491:begin g0_idx=7;g1_idx=0;g2_idx=4;g3_idx=5;g4_idx=6;over=0; end
				492:begin g0_idx=4;g1_idx=7;g2_idx=0;g3_idx=5;g4_idx=6;over=0; end
				493:begin g0_idx=7;g1_idx=4;g2_idx=0;g3_idx=5;g4_idx=6;over=0; end
				494:begin g0_idx=5;g1_idx=0;g2_idx=7;g3_idx=4;g4_idx=6;over=0; end
				495:begin g0_idx=7;g1_idx=0;g2_idx=5;g3_idx=4;g4_idx=6;over=0; end
				496:begin g0_idx=5;g1_idx=7;g2_idx=0;g3_idx=4;g4_idx=6;over=0; end
				497:begin g0_idx=7;g1_idx=5;g2_idx=0;g3_idx=4;g4_idx=6;over=0; end
				498:begin g0_idx=4;g1_idx=5;g2_idx=7;g3_idx=0;g4_idx=6;over=0; end
				499:begin g0_idx=5;g1_idx=4;g2_idx=7;g3_idx=0;g4_idx=6;over=0; end
				500:begin g0_idx=4;g1_idx=7;g2_idx=5;g3_idx=0;g4_idx=6;over=0; end
				501:begin g0_idx=7;g1_idx=4;g2_idx=5;g3_idx=0;g4_idx=6;over=0; end
				502:begin g0_idx=5;g1_idx=7;g2_idx=4;g3_idx=0;g4_idx=6;over=0; end
				503:begin g0_idx=7;g1_idx=5;g2_idx=4;g3_idx=0;g4_idx=6;over=0; end
				504:begin g0_idx=4;g1_idx=0;g2_idx=6;g3_idx=7;g4_idx=5;over=0; end
				505:begin g0_idx=6;g1_idx=0;g2_idx=4;g3_idx=7;g4_idx=5;over=0; end
				506:begin g0_idx=4;g1_idx=6;g2_idx=0;g3_idx=7;g4_idx=5;over=0; end
				507:begin g0_idx=6;g1_idx=4;g2_idx=0;g3_idx=7;g4_idx=5;over=0; end
				508:begin g0_idx=4;g1_idx=0;g2_idx=7;g3_idx=6;g4_idx=5;over=0; end
				509:begin g0_idx=7;g1_idx=0;g2_idx=4;g3_idx=6;g4_idx=5;over=0; end
				510:begin g0_idx=4;g1_idx=7;g2_idx=0;g3_idx=6;g4_idx=5;over=0; end
				511:begin g0_idx=7;g1_idx=4;g2_idx=0;g3_idx=6;g4_idx=5;over=0; end
				512:begin g0_idx=6;g1_idx=0;g2_idx=7;g3_idx=4;g4_idx=5;over=0; end
				513:begin g0_idx=7;g1_idx=0;g2_idx=6;g3_idx=4;g4_idx=5;over=0; end
				514:begin g0_idx=6;g1_idx=7;g2_idx=0;g3_idx=4;g4_idx=5;over=0; end
				515:begin g0_idx=7;g1_idx=6;g2_idx=0;g3_idx=4;g4_idx=5;over=0; end
				516:begin g0_idx=4;g1_idx=6;g2_idx=7;g3_idx=0;g4_idx=5;over=0; end
				517:begin g0_idx=6;g1_idx=4;g2_idx=7;g3_idx=0;g4_idx=5;over=0; end
				518:begin g0_idx=4;g1_idx=7;g2_idx=6;g3_idx=0;g4_idx=5;over=0; end
				519:begin g0_idx=7;g1_idx=4;g2_idx=6;g3_idx=0;g4_idx=5;over=0; end
				520:begin g0_idx=6;g1_idx=7;g2_idx=4;g3_idx=0;g4_idx=5;over=0; end
				521:begin g0_idx=7;g1_idx=6;g2_idx=4;g3_idx=0;g4_idx=5;over=0; end
				522:begin g0_idx=4;g1_idx=5;g2_idx=6;g3_idx=7;g4_idx=0;over=0; end
				523:begin g0_idx=5;g1_idx=4;g2_idx=6;g3_idx=7;g4_idx=0;over=0; end
				524:begin g0_idx=4;g1_idx=6;g2_idx=5;g3_idx=7;g4_idx=0;over=0; end
				525:begin g0_idx=6;g1_idx=4;g2_idx=5;g3_idx=7;g4_idx=0;over=0; end
				526:begin g0_idx=5;g1_idx=6;g2_idx=4;g3_idx=7;g4_idx=0;over=0; end
				527:begin g0_idx=6;g1_idx=5;g2_idx=4;g3_idx=7;g4_idx=0;over=0; end
				528:begin g0_idx=4;g1_idx=5;g2_idx=7;g3_idx=6;g4_idx=0;over=0; end
				529:begin g0_idx=5;g1_idx=4;g2_idx=7;g3_idx=6;g4_idx=0;over=0; end
				530:begin g0_idx=4;g1_idx=7;g2_idx=5;g3_idx=6;g4_idx=0;over=0; end
				531:begin g0_idx=7;g1_idx=4;g2_idx=5;g3_idx=6;g4_idx=0;over=0; end
				532:begin g0_idx=5;g1_idx=7;g2_idx=4;g3_idx=6;g4_idx=0;over=0; end
				533:begin g0_idx=7;g1_idx=5;g2_idx=4;g3_idx=6;g4_idx=0;over=0; end
				534:begin g0_idx=4;g1_idx=6;g2_idx=7;g3_idx=5;g4_idx=0;over=0; end
				535:begin g0_idx=6;g1_idx=4;g2_idx=7;g3_idx=5;g4_idx=0;over=0; end
				536:begin g0_idx=4;g1_idx=7;g2_idx=6;g3_idx=5;g4_idx=0;over=0; end
				537:begin g0_idx=7;g1_idx=4;g2_idx=6;g3_idx=5;g4_idx=0;over=0; end
				538:begin g0_idx=6;g1_idx=7;g2_idx=4;g3_idx=5;g4_idx=0;over=0; end
				539:begin g0_idx=7;g1_idx=6;g2_idx=4;g3_idx=5;g4_idx=0;over=0; end
				540:begin g0_idx=5;g1_idx=6;g2_idx=7;g3_idx=4;g4_idx=0;over=0; end
				541:begin g0_idx=6;g1_idx=5;g2_idx=7;g3_idx=4;g4_idx=0;over=0; end
				542:begin g0_idx=5;g1_idx=7;g2_idx=6;g3_idx=4;g4_idx=0;over=0; end
				543:begin g0_idx=7;g1_idx=5;g2_idx=6;g3_idx=4;g4_idx=0;over=0; end
				544:begin g0_idx=6;g1_idx=7;g2_idx=5;g3_idx=4;g4_idx=0;over=0; end
				545:begin g0_idx=7;g1_idx=6;g2_idx=5;g3_idx=4;g4_idx=0;over=0; end
				546:begin g0_idx=1;g1_idx=4;g2_idx=5;g3_idx=6;g4_idx=7;over=0; end
				547:begin g0_idx=1;g1_idx=5;g2_idx=4;g3_idx=6;g4_idx=7;over=0; end
				548:begin g0_idx=4;g1_idx=5;g2_idx=1;g3_idx=6;g4_idx=7;over=0; end
				549:begin g0_idx=5;g1_idx=4;g2_idx=1;g3_idx=6;g4_idx=7;over=0; end
				550:begin g0_idx=1;g1_idx=4;g2_idx=6;g3_idx=5;g4_idx=7;over=0; end
				551:begin g0_idx=1;g1_idx=6;g2_idx=4;g3_idx=5;g4_idx=7;over=0; end
				552:begin g0_idx=4;g1_idx=6;g2_idx=1;g3_idx=5;g4_idx=7;over=0; end
				553:begin g0_idx=6;g1_idx=4;g2_idx=1;g3_idx=5;g4_idx=7;over=0; end
				554:begin g0_idx=1;g1_idx=5;g2_idx=6;g3_idx=4;g4_idx=7;over=0; end
				555:begin g0_idx=1;g1_idx=6;g2_idx=5;g3_idx=4;g4_idx=7;over=0; end
				556:begin g0_idx=5;g1_idx=6;g2_idx=1;g3_idx=4;g4_idx=7;over=0; end
				557:begin g0_idx=6;g1_idx=5;g2_idx=1;g3_idx=4;g4_idx=7;over=0; end
				558:begin g0_idx=4;g1_idx=5;g2_idx=6;g3_idx=1;g4_idx=7;over=0; end
				559:begin g0_idx=5;g1_idx=4;g2_idx=6;g3_idx=1;g4_idx=7;over=0; end
				560:begin g0_idx=4;g1_idx=6;g2_idx=5;g3_idx=1;g4_idx=7;over=0; end
				561:begin g0_idx=6;g1_idx=4;g2_idx=5;g3_idx=1;g4_idx=7;over=0; end
				562:begin g0_idx=5;g1_idx=6;g2_idx=4;g3_idx=1;g4_idx=7;over=0; end
				563:begin g0_idx=6;g1_idx=5;g2_idx=4;g3_idx=1;g4_idx=7;over=0; end
				564:begin g0_idx=1;g1_idx=4;g2_idx=5;g3_idx=7;g4_idx=6;over=0; end
				565:begin g0_idx=1;g1_idx=5;g2_idx=4;g3_idx=7;g4_idx=6;over=0; end
				566:begin g0_idx=4;g1_idx=5;g2_idx=1;g3_idx=7;g4_idx=6;over=0; end
				567:begin g0_idx=5;g1_idx=4;g2_idx=1;g3_idx=7;g4_idx=6;over=0; end
				568:begin g0_idx=1;g1_idx=4;g2_idx=7;g3_idx=5;g4_idx=6;over=0; end
				569:begin g0_idx=1;g1_idx=7;g2_idx=4;g3_idx=5;g4_idx=6;over=0; end
				570:begin g0_idx=4;g1_idx=7;g2_idx=1;g3_idx=5;g4_idx=6;over=0; end
				571:begin g0_idx=7;g1_idx=4;g2_idx=1;g3_idx=5;g4_idx=6;over=0; end
				572:begin g0_idx=1;g1_idx=5;g2_idx=7;g3_idx=4;g4_idx=6;over=0; end
				573:begin g0_idx=1;g1_idx=7;g2_idx=5;g3_idx=4;g4_idx=6;over=0; end
				574:begin g0_idx=5;g1_idx=7;g2_idx=1;g3_idx=4;g4_idx=6;over=0; end
				575:begin g0_idx=7;g1_idx=5;g2_idx=1;g3_idx=4;g4_idx=6;over=0; end
				576:begin g0_idx=4;g1_idx=5;g2_idx=7;g3_idx=1;g4_idx=6;over=0; end
				577:begin g0_idx=5;g1_idx=4;g2_idx=7;g3_idx=1;g4_idx=6;over=0; end
				578:begin g0_idx=4;g1_idx=7;g2_idx=5;g3_idx=1;g4_idx=6;over=0; end
				579:begin g0_idx=7;g1_idx=4;g2_idx=5;g3_idx=1;g4_idx=6;over=0; end
				580:begin g0_idx=5;g1_idx=7;g2_idx=4;g3_idx=1;g4_idx=6;over=0; end
				581:begin g0_idx=7;g1_idx=5;g2_idx=4;g3_idx=1;g4_idx=6;over=0; end
				582:begin g0_idx=1;g1_idx=4;g2_idx=6;g3_idx=7;g4_idx=5;over=0; end
				583:begin g0_idx=1;g1_idx=6;g2_idx=4;g3_idx=7;g4_idx=5;over=0; end
				584:begin g0_idx=4;g1_idx=6;g2_idx=1;g3_idx=7;g4_idx=5;over=0; end
				585:begin g0_idx=6;g1_idx=4;g2_idx=1;g3_idx=7;g4_idx=5;over=0; end
				586:begin g0_idx=1;g1_idx=4;g2_idx=7;g3_idx=6;g4_idx=5;over=0; end
				587:begin g0_idx=1;g1_idx=7;g2_idx=4;g3_idx=6;g4_idx=5;over=0; end
				588:begin g0_idx=4;g1_idx=7;g2_idx=1;g3_idx=6;g4_idx=5;over=0; end
				589:begin g0_idx=7;g1_idx=4;g2_idx=1;g3_idx=6;g4_idx=5;over=0; end
				590:begin g0_idx=1;g1_idx=6;g2_idx=7;g3_idx=4;g4_idx=5;over=0; end
				591:begin g0_idx=1;g1_idx=7;g2_idx=6;g3_idx=4;g4_idx=5;over=0; end
				592:begin g0_idx=6;g1_idx=7;g2_idx=1;g3_idx=4;g4_idx=5;over=0; end
				593:begin g0_idx=7;g1_idx=6;g2_idx=1;g3_idx=4;g4_idx=5;over=0; end
				594:begin g0_idx=4;g1_idx=6;g2_idx=7;g3_idx=1;g4_idx=5;over=0; end
				595:begin g0_idx=6;g1_idx=4;g2_idx=7;g3_idx=1;g4_idx=5;over=0; end
				596:begin g0_idx=4;g1_idx=7;g2_idx=6;g3_idx=1;g4_idx=5;over=0; end
				597:begin g0_idx=7;g1_idx=4;g2_idx=6;g3_idx=1;g4_idx=5;over=0; end
				598:begin g0_idx=6;g1_idx=7;g2_idx=4;g3_idx=1;g4_idx=5;over=0; end
				599:begin g0_idx=7;g1_idx=6;g2_idx=4;g3_idx=1;g4_idx=5;over=0; end
				600:begin g0_idx=4;g1_idx=5;g2_idx=6;g3_idx=7;g4_idx=1;over=0; end
				601:begin g0_idx=5;g1_idx=4;g2_idx=6;g3_idx=7;g4_idx=1;over=0; end
				602:begin g0_idx=4;g1_idx=6;g2_idx=5;g3_idx=7;g4_idx=1;over=0; end
				603:begin g0_idx=6;g1_idx=4;g2_idx=5;g3_idx=7;g4_idx=1;over=0; end
				604:begin g0_idx=5;g1_idx=6;g2_idx=4;g3_idx=7;g4_idx=1;over=0; end
				605:begin g0_idx=6;g1_idx=5;g2_idx=4;g3_idx=7;g4_idx=1;over=0; end
				606:begin g0_idx=4;g1_idx=5;g2_idx=7;g3_idx=6;g4_idx=1;over=0; end
				607:begin g0_idx=5;g1_idx=4;g2_idx=7;g3_idx=6;g4_idx=1;over=0; end
				608:begin g0_idx=4;g1_idx=7;g2_idx=5;g3_idx=6;g4_idx=1;over=0; end
				609:begin g0_idx=7;g1_idx=4;g2_idx=5;g3_idx=6;g4_idx=1;over=0; end
				610:begin g0_idx=5;g1_idx=7;g2_idx=4;g3_idx=6;g4_idx=1;over=0; end
				611:begin g0_idx=7;g1_idx=5;g2_idx=4;g3_idx=6;g4_idx=1;over=0; end
				612:begin g0_idx=4;g1_idx=6;g2_idx=7;g3_idx=5;g4_idx=1;over=0; end
				613:begin g0_idx=6;g1_idx=4;g2_idx=7;g3_idx=5;g4_idx=1;over=0; end
				614:begin g0_idx=4;g1_idx=7;g2_idx=6;g3_idx=5;g4_idx=1;over=0; end
				615:begin g0_idx=7;g1_idx=4;g2_idx=6;g3_idx=5;g4_idx=1;over=0; end
				616:begin g0_idx=6;g1_idx=7;g2_idx=4;g3_idx=5;g4_idx=1;over=0; end
				617:begin g0_idx=7;g1_idx=6;g2_idx=4;g3_idx=5;g4_idx=1;over=0; end
				618:begin g0_idx=5;g1_idx=6;g2_idx=7;g3_idx=4;g4_idx=1;over=0; end
				619:begin g0_idx=6;g1_idx=5;g2_idx=7;g3_idx=4;g4_idx=1;over=0; end
				620:begin g0_idx=5;g1_idx=7;g2_idx=6;g3_idx=4;g4_idx=1;over=0; end
				621:begin g0_idx=7;g1_idx=5;g2_idx=6;g3_idx=4;g4_idx=1;over=0; end
				622:begin g0_idx=6;g1_idx=7;g2_idx=5;g3_idx=4;g4_idx=1;over=0; end
				623:begin g0_idx=7;g1_idx=6;g2_idx=5;g3_idx=4;g4_idx=1;over=0; end
				624:begin g0_idx=2;g1_idx=4;g2_idx=5;g3_idx=6;g4_idx=7;over=0; end
				625:begin g0_idx=4;g1_idx=2;g2_idx=5;g3_idx=6;g4_idx=7;over=0; end
				626:begin g0_idx=2;g1_idx=5;g2_idx=4;g3_idx=6;g4_idx=7;over=0; end
				627:begin g0_idx=5;g1_idx=2;g2_idx=4;g3_idx=6;g4_idx=7;over=0; end
				628:begin g0_idx=2;g1_idx=4;g2_idx=6;g3_idx=5;g4_idx=7;over=0; end
				629:begin g0_idx=4;g1_idx=2;g2_idx=6;g3_idx=5;g4_idx=7;over=0; end
				630:begin g0_idx=2;g1_idx=6;g2_idx=4;g3_idx=5;g4_idx=7;over=0; end
				631:begin g0_idx=6;g1_idx=2;g2_idx=4;g3_idx=5;g4_idx=7;over=0; end
				632:begin g0_idx=2;g1_idx=5;g2_idx=6;g3_idx=4;g4_idx=7;over=0; end
				633:begin g0_idx=5;g1_idx=2;g2_idx=6;g3_idx=4;g4_idx=7;over=0; end
				634:begin g0_idx=2;g1_idx=6;g2_idx=5;g3_idx=4;g4_idx=7;over=0; end
				635:begin g0_idx=6;g1_idx=2;g2_idx=5;g3_idx=4;g4_idx=7;over=0; end
				636:begin g0_idx=4;g1_idx=5;g2_idx=6;g3_idx=2;g4_idx=7;over=0; end
				637:begin g0_idx=5;g1_idx=4;g2_idx=6;g3_idx=2;g4_idx=7;over=0; end
				638:begin g0_idx=4;g1_idx=6;g2_idx=5;g3_idx=2;g4_idx=7;over=0; end
				639:begin g0_idx=6;g1_idx=4;g2_idx=5;g3_idx=2;g4_idx=7;over=0; end
				640:begin g0_idx=5;g1_idx=6;g2_idx=4;g3_idx=2;g4_idx=7;over=0; end
				641:begin g0_idx=6;g1_idx=5;g2_idx=4;g3_idx=2;g4_idx=7;over=0; end
				642:begin g0_idx=2;g1_idx=4;g2_idx=5;g3_idx=7;g4_idx=6;over=0; end
				643:begin g0_idx=4;g1_idx=2;g2_idx=5;g3_idx=7;g4_idx=6;over=0; end
				644:begin g0_idx=2;g1_idx=5;g2_idx=4;g3_idx=7;g4_idx=6;over=0; end
				645:begin g0_idx=5;g1_idx=2;g2_idx=4;g3_idx=7;g4_idx=6;over=0; end
				646:begin g0_idx=2;g1_idx=4;g2_idx=7;g3_idx=5;g4_idx=6;over=0; end
				647:begin g0_idx=4;g1_idx=2;g2_idx=7;g3_idx=5;g4_idx=6;over=0; end
				648:begin g0_idx=2;g1_idx=7;g2_idx=4;g3_idx=5;g4_idx=6;over=0; end
				649:begin g0_idx=7;g1_idx=2;g2_idx=4;g3_idx=5;g4_idx=6;over=0; end
				650:begin g0_idx=2;g1_idx=5;g2_idx=7;g3_idx=4;g4_idx=6;over=0; end
				651:begin g0_idx=5;g1_idx=2;g2_idx=7;g3_idx=4;g4_idx=6;over=0; end
				652:begin g0_idx=2;g1_idx=7;g2_idx=5;g3_idx=4;g4_idx=6;over=0; end
				653:begin g0_idx=7;g1_idx=2;g2_idx=5;g3_idx=4;g4_idx=6;over=0; end
				654:begin g0_idx=4;g1_idx=5;g2_idx=7;g3_idx=2;g4_idx=6;over=0; end
				655:begin g0_idx=5;g1_idx=4;g2_idx=7;g3_idx=2;g4_idx=6;over=0; end
				656:begin g0_idx=4;g1_idx=7;g2_idx=5;g3_idx=2;g4_idx=6;over=0; end
				657:begin g0_idx=7;g1_idx=4;g2_idx=5;g3_idx=2;g4_idx=6;over=0; end
				658:begin g0_idx=5;g1_idx=7;g2_idx=4;g3_idx=2;g4_idx=6;over=0; end
				659:begin g0_idx=7;g1_idx=5;g2_idx=4;g3_idx=2;g4_idx=6;over=0; end
				660:begin g0_idx=2;g1_idx=4;g2_idx=6;g3_idx=7;g4_idx=5;over=0; end
				661:begin g0_idx=4;g1_idx=2;g2_idx=6;g3_idx=7;g4_idx=5;over=0; end
				662:begin g0_idx=2;g1_idx=6;g2_idx=4;g3_idx=7;g4_idx=5;over=0; end
				663:begin g0_idx=6;g1_idx=2;g2_idx=4;g3_idx=7;g4_idx=5;over=0; end
				664:begin g0_idx=2;g1_idx=4;g2_idx=7;g3_idx=6;g4_idx=5;over=0; end
				665:begin g0_idx=4;g1_idx=2;g2_idx=7;g3_idx=6;g4_idx=5;over=0; end
				666:begin g0_idx=2;g1_idx=7;g2_idx=4;g3_idx=6;g4_idx=5;over=0; end
				667:begin g0_idx=7;g1_idx=2;g2_idx=4;g3_idx=6;g4_idx=5;over=0; end
				668:begin g0_idx=2;g1_idx=6;g2_idx=7;g3_idx=4;g4_idx=5;over=0; end
				669:begin g0_idx=6;g1_idx=2;g2_idx=7;g3_idx=4;g4_idx=5;over=0; end
				670:begin g0_idx=2;g1_idx=7;g2_idx=6;g3_idx=4;g4_idx=5;over=0; end
				671:begin g0_idx=7;g1_idx=2;g2_idx=6;g3_idx=4;g4_idx=5;over=0; end
				672:begin g0_idx=4;g1_idx=6;g2_idx=7;g3_idx=2;g4_idx=5;over=0; end
				673:begin g0_idx=6;g1_idx=4;g2_idx=7;g3_idx=2;g4_idx=5;over=0; end
				674:begin g0_idx=4;g1_idx=7;g2_idx=6;g3_idx=2;g4_idx=5;over=0; end
				675:begin g0_idx=7;g1_idx=4;g2_idx=6;g3_idx=2;g4_idx=5;over=0; end
				676:begin g0_idx=6;g1_idx=7;g2_idx=4;g3_idx=2;g4_idx=5;over=0; end
				677:begin g0_idx=7;g1_idx=6;g2_idx=4;g3_idx=2;g4_idx=5;over=0; end
				678:begin g0_idx=4;g1_idx=5;g2_idx=6;g3_idx=7;g4_idx=2;over=0; end
				679:begin g0_idx=5;g1_idx=4;g2_idx=6;g3_idx=7;g4_idx=2;over=0; end
				680:begin g0_idx=4;g1_idx=6;g2_idx=5;g3_idx=7;g4_idx=2;over=0; end
				681:begin g0_idx=6;g1_idx=4;g2_idx=5;g3_idx=7;g4_idx=2;over=0; end
				682:begin g0_idx=5;g1_idx=6;g2_idx=4;g3_idx=7;g4_idx=2;over=0; end
				683:begin g0_idx=6;g1_idx=5;g2_idx=4;g3_idx=7;g4_idx=2;over=0; end
				684:begin g0_idx=4;g1_idx=5;g2_idx=7;g3_idx=6;g4_idx=2;over=0; end
				685:begin g0_idx=5;g1_idx=4;g2_idx=7;g3_idx=6;g4_idx=2;over=0; end
				686:begin g0_idx=4;g1_idx=7;g2_idx=5;g3_idx=6;g4_idx=2;over=0; end
				687:begin g0_idx=7;g1_idx=4;g2_idx=5;g3_idx=6;g4_idx=2;over=0; end
				688:begin g0_idx=5;g1_idx=7;g2_idx=4;g3_idx=6;g4_idx=2;over=0; end
				689:begin g0_idx=7;g1_idx=5;g2_idx=4;g3_idx=6;g4_idx=2;over=0; end
				690:begin g0_idx=4;g1_idx=6;g2_idx=7;g3_idx=5;g4_idx=2;over=0; end
				691:begin g0_idx=6;g1_idx=4;g2_idx=7;g3_idx=5;g4_idx=2;over=0; end
				692:begin g0_idx=4;g1_idx=7;g2_idx=6;g3_idx=5;g4_idx=2;over=0; end
				693:begin g0_idx=7;g1_idx=4;g2_idx=6;g3_idx=5;g4_idx=2;over=0; end
				694:begin g0_idx=6;g1_idx=7;g2_idx=4;g3_idx=5;g4_idx=2;over=0; end
				695:begin g0_idx=7;g1_idx=6;g2_idx=4;g3_idx=5;g4_idx=2;over=0; end
				696:begin g0_idx=5;g1_idx=6;g2_idx=7;g3_idx=4;g4_idx=2;over=0; end
				697:begin g0_idx=6;g1_idx=5;g2_idx=7;g3_idx=4;g4_idx=2;over=0; end
				698:begin g0_idx=5;g1_idx=7;g2_idx=6;g3_idx=4;g4_idx=2;over=0; end
				699:begin g0_idx=7;g1_idx=5;g2_idx=6;g3_idx=4;g4_idx=2;over=0; end
				700:begin g0_idx=6;g1_idx=7;g2_idx=5;g3_idx=4;g4_idx=2;over=0; end
				701:begin g0_idx=7;g1_idx=6;g2_idx=5;g3_idx=4;g4_idx=2;over=0; end
				702:begin g0_idx=3;g1_idx=4;g2_idx=5;g3_idx=6;g4_idx=7;over=0; end
				703:begin g0_idx=4;g1_idx=3;g2_idx=5;g3_idx=6;g4_idx=7;over=0; end
				704:begin g0_idx=3;g1_idx=5;g2_idx=4;g3_idx=6;g4_idx=7;over=0; end
				705:begin g0_idx=5;g1_idx=3;g2_idx=4;g3_idx=6;g4_idx=7;over=0; end
				706:begin g0_idx=4;g1_idx=5;g2_idx=3;g3_idx=6;g4_idx=7;over=0; end
				707:begin g0_idx=5;g1_idx=4;g2_idx=3;g3_idx=6;g4_idx=7;over=0; end
				708:begin g0_idx=3;g1_idx=4;g2_idx=6;g3_idx=5;g4_idx=7;over=0; end
				709:begin g0_idx=4;g1_idx=3;g2_idx=6;g3_idx=5;g4_idx=7;over=0; end
				710:begin g0_idx=3;g1_idx=6;g2_idx=4;g3_idx=5;g4_idx=7;over=0; end
				711:begin g0_idx=6;g1_idx=3;g2_idx=4;g3_idx=5;g4_idx=7;over=0; end
				712:begin g0_idx=4;g1_idx=6;g2_idx=3;g3_idx=5;g4_idx=7;over=0; end
				713:begin g0_idx=6;g1_idx=4;g2_idx=3;g3_idx=5;g4_idx=7;over=0; end
				714:begin g0_idx=3;g1_idx=5;g2_idx=6;g3_idx=4;g4_idx=7;over=0; end
				715:begin g0_idx=5;g1_idx=3;g2_idx=6;g3_idx=4;g4_idx=7;over=0; end
				716:begin g0_idx=3;g1_idx=6;g2_idx=5;g3_idx=4;g4_idx=7;over=0; end
				717:begin g0_idx=6;g1_idx=3;g2_idx=5;g3_idx=4;g4_idx=7;over=0; end
				718:begin g0_idx=5;g1_idx=6;g2_idx=3;g3_idx=4;g4_idx=7;over=0; end
				719:begin g0_idx=6;g1_idx=5;g2_idx=3;g3_idx=4;g4_idx=7;over=0; end
				720:begin g0_idx=3;g1_idx=4;g2_idx=5;g3_idx=7;g4_idx=6;over=0; end
				721:begin g0_idx=4;g1_idx=3;g2_idx=5;g3_idx=7;g4_idx=6;over=0; end
				722:begin g0_idx=3;g1_idx=5;g2_idx=4;g3_idx=7;g4_idx=6;over=0; end
				723:begin g0_idx=5;g1_idx=3;g2_idx=4;g3_idx=7;g4_idx=6;over=0; end
				724:begin g0_idx=4;g1_idx=5;g2_idx=3;g3_idx=7;g4_idx=6;over=0; end
				725:begin g0_idx=5;g1_idx=4;g2_idx=3;g3_idx=7;g4_idx=6;over=0; end
				726:begin g0_idx=3;g1_idx=4;g2_idx=7;g3_idx=5;g4_idx=6;over=0; end
				727:begin g0_idx=4;g1_idx=3;g2_idx=7;g3_idx=5;g4_idx=6;over=0; end
				728:begin g0_idx=3;g1_idx=7;g2_idx=4;g3_idx=5;g4_idx=6;over=0; end
				729:begin g0_idx=7;g1_idx=3;g2_idx=4;g3_idx=5;g4_idx=6;over=0; end
				730:begin g0_idx=4;g1_idx=7;g2_idx=3;g3_idx=5;g4_idx=6;over=0; end
				731:begin g0_idx=7;g1_idx=4;g2_idx=3;g3_idx=5;g4_idx=6;over=0; end
				732:begin g0_idx=3;g1_idx=5;g2_idx=7;g3_idx=4;g4_idx=6;over=0; end
				733:begin g0_idx=5;g1_idx=3;g2_idx=7;g3_idx=4;g4_idx=6;over=0; end
				734:begin g0_idx=3;g1_idx=7;g2_idx=5;g3_idx=4;g4_idx=6;over=0; end
				735:begin g0_idx=7;g1_idx=3;g2_idx=5;g3_idx=4;g4_idx=6;over=0; end
				736:begin g0_idx=5;g1_idx=7;g2_idx=3;g3_idx=4;g4_idx=6;over=0; end
				737:begin g0_idx=7;g1_idx=5;g2_idx=3;g3_idx=4;g4_idx=6;over=0; end
				738:begin g0_idx=3;g1_idx=4;g2_idx=6;g3_idx=7;g4_idx=5;over=0; end
				739:begin g0_idx=4;g1_idx=3;g2_idx=6;g3_idx=7;g4_idx=5;over=0; end
				740:begin g0_idx=3;g1_idx=6;g2_idx=4;g3_idx=7;g4_idx=5;over=0; end
				741:begin g0_idx=6;g1_idx=3;g2_idx=4;g3_idx=7;g4_idx=5;over=0; end
				742:begin g0_idx=4;g1_idx=6;g2_idx=3;g3_idx=7;g4_idx=5;over=0; end
				743:begin g0_idx=6;g1_idx=4;g2_idx=3;g3_idx=7;g4_idx=5;over=0; end
				744:begin g0_idx=3;g1_idx=4;g2_idx=7;g3_idx=6;g4_idx=5;over=0; end
				745:begin g0_idx=4;g1_idx=3;g2_idx=7;g3_idx=6;g4_idx=5;over=0; end
				746:begin g0_idx=3;g1_idx=7;g2_idx=4;g3_idx=6;g4_idx=5;over=0; end
				747:begin g0_idx=7;g1_idx=3;g2_idx=4;g3_idx=6;g4_idx=5;over=0; end
				748:begin g0_idx=4;g1_idx=7;g2_idx=3;g3_idx=6;g4_idx=5;over=0; end
				749:begin g0_idx=7;g1_idx=4;g2_idx=3;g3_idx=6;g4_idx=5;over=0; end
				750:begin g0_idx=3;g1_idx=6;g2_idx=7;g3_idx=4;g4_idx=5;over=0; end
				751:begin g0_idx=6;g1_idx=3;g2_idx=7;g3_idx=4;g4_idx=5;over=0; end
				752:begin g0_idx=3;g1_idx=7;g2_idx=6;g3_idx=4;g4_idx=5;over=0; end
				753:begin g0_idx=7;g1_idx=3;g2_idx=6;g3_idx=4;g4_idx=5;over=0; end
				754:begin g0_idx=6;g1_idx=7;g2_idx=3;g3_idx=4;g4_idx=5;over=0; end
				755:begin g0_idx=7;g1_idx=6;g2_idx=3;g3_idx=4;g4_idx=5;over=0; end
				756:begin g0_idx=4;g1_idx=5;g2_idx=6;g3_idx=7;g4_idx=3;over=0; end
				757:begin g0_idx=5;g1_idx=4;g2_idx=6;g3_idx=7;g4_idx=3;over=0; end
				758:begin g0_idx=4;g1_idx=6;g2_idx=5;g3_idx=7;g4_idx=3;over=0; end
				759:begin g0_idx=6;g1_idx=4;g2_idx=5;g3_idx=7;g4_idx=3;over=0; end
				760:begin g0_idx=5;g1_idx=6;g2_idx=4;g3_idx=7;g4_idx=3;over=0; end
				761:begin g0_idx=6;g1_idx=5;g2_idx=4;g3_idx=7;g4_idx=3;over=0; end
				762:begin g0_idx=4;g1_idx=5;g2_idx=7;g3_idx=6;g4_idx=3;over=0; end
				763:begin g0_idx=5;g1_idx=4;g2_idx=7;g3_idx=6;g4_idx=3;over=0; end
				764:begin g0_idx=4;g1_idx=7;g2_idx=5;g3_idx=6;g4_idx=3;over=0; end
				765:begin g0_idx=7;g1_idx=4;g2_idx=5;g3_idx=6;g4_idx=3;over=0; end
				766:begin g0_idx=5;g1_idx=7;g2_idx=4;g3_idx=6;g4_idx=3;over=0; end
				767:begin g0_idx=7;g1_idx=5;g2_idx=4;g3_idx=6;g4_idx=3;over=0; end
				768:begin g0_idx=4;g1_idx=6;g2_idx=7;g3_idx=5;g4_idx=3;over=0; end
				769:begin g0_idx=6;g1_idx=4;g2_idx=7;g3_idx=5;g4_idx=3;over=0; end
				770:begin g0_idx=4;g1_idx=7;g2_idx=6;g3_idx=5;g4_idx=3;over=0; end
				771:begin g0_idx=7;g1_idx=4;g2_idx=6;g3_idx=5;g4_idx=3;over=0; end
				772:begin g0_idx=6;g1_idx=7;g2_idx=4;g3_idx=5;g4_idx=3;over=0; end
				773:begin g0_idx=7;g1_idx=6;g2_idx=4;g3_idx=5;g4_idx=3;over=0; end
				774:begin g0_idx=5;g1_idx=6;g2_idx=7;g3_idx=4;g4_idx=3;over=0; end
				775:begin g0_idx=6;g1_idx=5;g2_idx=7;g3_idx=4;g4_idx=3;over=0; end
				776:begin g0_idx=5;g1_idx=7;g2_idx=6;g3_idx=4;g4_idx=3;over=0; end
				777:begin g0_idx=7;g1_idx=5;g2_idx=6;g3_idx=4;g4_idx=3;over=0; end
				778:begin g0_idx=6;g1_idx=7;g2_idx=5;g3_idx=4;g4_idx=3;over=0; end
				779:begin g0_idx=7;g1_idx=6;g2_idx=5;g3_idx=4;g4_idx=3;over=0; end
				default :begin
					g0_idx=3'bx;    g1_idx=3'bx;    g2_idx=3'bx;    g3_idx=3'bx;    g4_idx=3'bx; over=1;
				end
				endcase
		6'o03:
				case(inspect_vector)
					0:begin g0_idx=2;g1_idx=0;g2_idx=1;g3_idx=5;g4_idx=6;over=0; end
					1:begin g0_idx=1;g1_idx=2;g2_idx=0;g3_idx=5;g4_idx=6;over=0; end
					2:begin g0_idx=1;g1_idx=0;g2_idx=5;g3_idx=2;g4_idx=6;over=0; end
					3:begin g0_idx=5;g1_idx=0;g2_idx=1;g3_idx=2;g4_idx=6;over=0; end
					4:begin g0_idx=1;g1_idx=5;g2_idx=0;g3_idx=2;g4_idx=6;over=0; end
					5:begin g0_idx=2;g1_idx=0;g2_idx=5;g3_idx=1;g4_idx=6;over=0; end
					6:begin g0_idx=2;g1_idx=5;g2_idx=0;g3_idx=1;g4_idx=6;over=0; end
					7:begin g0_idx=5;g1_idx=2;g2_idx=0;g3_idx=1;g4_idx=6;over=0; end
					8:begin g0_idx=1;g1_idx=2;g2_idx=5;g3_idx=0;g4_idx=6;over=0; end
					9:begin g0_idx=2;g1_idx=5;g2_idx=1;g3_idx=0;g4_idx=6;over=0; end
					10:begin g0_idx=5;g1_idx=2;g2_idx=1;g3_idx=0;g4_idx=6;over=0; end
					11:begin g0_idx=2;g1_idx=0;g2_idx=1;g3_idx=6;g4_idx=5;over=0; end
					12:begin g0_idx=1;g1_idx=2;g2_idx=0;g3_idx=6;g4_idx=5;over=0; end
					13:begin g0_idx=1;g1_idx=0;g2_idx=6;g3_idx=2;g4_idx=5;over=0; end
					14:begin g0_idx=6;g1_idx=0;g2_idx=1;g3_idx=2;g4_idx=5;over=0; end
					15:begin g0_idx=1;g1_idx=6;g2_idx=0;g3_idx=2;g4_idx=5;over=0; end
					16:begin g0_idx=2;g1_idx=0;g2_idx=6;g3_idx=1;g4_idx=5;over=0; end
					17:begin g0_idx=2;g1_idx=6;g2_idx=0;g3_idx=1;g4_idx=5;over=0; end
					18:begin g0_idx=6;g1_idx=2;g2_idx=0;g3_idx=1;g4_idx=5;over=0; end
					19:begin g0_idx=1;g1_idx=2;g2_idx=6;g3_idx=0;g4_idx=5;over=0; end
					20:begin g0_idx=2;g1_idx=6;g2_idx=1;g3_idx=0;g4_idx=5;over=0; end
					21:begin g0_idx=6;g1_idx=2;g2_idx=1;g3_idx=0;g4_idx=5;over=0; end
					22:begin g0_idx=1;g1_idx=0;g2_idx=5;g3_idx=6;g4_idx=2;over=0; end
					23:begin g0_idx=5;g1_idx=0;g2_idx=1;g3_idx=6;g4_idx=2;over=0; end
					24:begin g0_idx=1;g1_idx=5;g2_idx=0;g3_idx=6;g4_idx=2;over=0; end
					25:begin g0_idx=1;g1_idx=0;g2_idx=6;g3_idx=5;g4_idx=2;over=0; end
					26:begin g0_idx=6;g1_idx=0;g2_idx=1;g3_idx=5;g4_idx=2;over=0; end
					27:begin g0_idx=1;g1_idx=6;g2_idx=0;g3_idx=5;g4_idx=2;over=0; end
					28:begin g0_idx=5;g1_idx=0;g2_idx=6;g3_idx=1;g4_idx=2;over=0; end
					29:begin g0_idx=6;g1_idx=0;g2_idx=5;g3_idx=1;g4_idx=2;over=0; end
					30:begin g0_idx=5;g1_idx=6;g2_idx=0;g3_idx=1;g4_idx=2;over=0; end
					31:begin g0_idx=6;g1_idx=5;g2_idx=0;g3_idx=1;g4_idx=2;over=0; end
					32:begin g0_idx=1;g1_idx=5;g2_idx=6;g3_idx=0;g4_idx=2;over=0; end
					33:begin g0_idx=1;g1_idx=6;g2_idx=5;g3_idx=0;g4_idx=2;over=0; end
					34:begin g0_idx=5;g1_idx=6;g2_idx=1;g3_idx=0;g4_idx=2;over=0; end
					35:begin g0_idx=6;g1_idx=5;g2_idx=1;g3_idx=0;g4_idx=2;over=0; end
					36:begin g0_idx=2;g1_idx=0;g2_idx=5;g3_idx=6;g4_idx=1;over=0; end
					37:begin g0_idx=2;g1_idx=5;g2_idx=0;g3_idx=6;g4_idx=1;over=0; end
					38:begin g0_idx=5;g1_idx=2;g2_idx=0;g3_idx=6;g4_idx=1;over=0; end
					39:begin g0_idx=2;g1_idx=0;g2_idx=6;g3_idx=5;g4_idx=1;over=0; end
					40:begin g0_idx=2;g1_idx=6;g2_idx=0;g3_idx=5;g4_idx=1;over=0; end
					41:begin g0_idx=6;g1_idx=2;g2_idx=0;g3_idx=5;g4_idx=1;over=0; end
					42:begin g0_idx=5;g1_idx=0;g2_idx=6;g3_idx=2;g4_idx=1;over=0; end
					43:begin g0_idx=6;g1_idx=0;g2_idx=5;g3_idx=2;g4_idx=1;over=0; end
					44:begin g0_idx=5;g1_idx=6;g2_idx=0;g3_idx=2;g4_idx=1;over=0; end
					45:begin g0_idx=6;g1_idx=5;g2_idx=0;g3_idx=2;g4_idx=1;over=0; end
					46:begin g0_idx=2;g1_idx=5;g2_idx=6;g3_idx=0;g4_idx=1;over=0; end
					47:begin g0_idx=5;g1_idx=2;g2_idx=6;g3_idx=0;g4_idx=1;over=0; end
					48:begin g0_idx=2;g1_idx=6;g2_idx=5;g3_idx=0;g4_idx=1;over=0; end
					49:begin g0_idx=6;g1_idx=2;g2_idx=5;g3_idx=0;g4_idx=1;over=0; end
					50:begin g0_idx=1;g1_idx=2;g2_idx=5;g3_idx=6;g4_idx=0;over=0; end
					51:begin g0_idx=2;g1_idx=5;g2_idx=1;g3_idx=6;g4_idx=0;over=0; end
					52:begin g0_idx=5;g1_idx=2;g2_idx=1;g3_idx=6;g4_idx=0;over=0; end
					53:begin g0_idx=1;g1_idx=2;g2_idx=6;g3_idx=5;g4_idx=0;over=0; end
					54:begin g0_idx=2;g1_idx=6;g2_idx=1;g3_idx=5;g4_idx=0;over=0; end
					55:begin g0_idx=6;g1_idx=2;g2_idx=1;g3_idx=5;g4_idx=0;over=0; end
					56:begin g0_idx=1;g1_idx=5;g2_idx=6;g3_idx=2;g4_idx=0;over=0; end
					57:begin g0_idx=1;g1_idx=6;g2_idx=5;g3_idx=2;g4_idx=0;over=0; end
					58:begin g0_idx=5;g1_idx=6;g2_idx=1;g3_idx=2;g4_idx=0;over=0; end
					59:begin g0_idx=6;g1_idx=5;g2_idx=1;g3_idx=2;g4_idx=0;over=0; end
					60:begin g0_idx=2;g1_idx=5;g2_idx=6;g3_idx=1;g4_idx=0;over=0; end
					61:begin g0_idx=5;g1_idx=2;g2_idx=6;g3_idx=1;g4_idx=0;over=0; end
					62:begin g0_idx=2;g1_idx=6;g2_idx=5;g3_idx=1;g4_idx=0;over=0; end
					63:begin g0_idx=6;g1_idx=2;g2_idx=5;g3_idx=1;g4_idx=0;over=0; end
					64:begin g0_idx=1;g1_idx=0;g2_idx=3;g3_idx=5;g4_idx=6;over=0; end
					65:begin g0_idx=3;g1_idx=0;g2_idx=1;g3_idx=5;g4_idx=6;over=0; end
					66:begin g0_idx=1;g1_idx=3;g2_idx=0;g3_idx=5;g4_idx=6;over=0; end
					67:begin g0_idx=3;g1_idx=0;g2_idx=5;g3_idx=1;g4_idx=6;over=0; end
					68:begin g0_idx=5;g1_idx=0;g2_idx=3;g3_idx=1;g4_idx=6;over=0; end
					69:begin g0_idx=3;g1_idx=5;g2_idx=0;g3_idx=1;g4_idx=6;over=0; end
					70:begin g0_idx=5;g1_idx=3;g2_idx=0;g3_idx=1;g4_idx=6;over=0; end
					71:begin g0_idx=1;g1_idx=3;g2_idx=5;g3_idx=0;g4_idx=6;over=0; end
					72:begin g0_idx=1;g1_idx=5;g2_idx=3;g3_idx=0;g4_idx=6;over=0; end
					73:begin g0_idx=3;g1_idx=5;g2_idx=1;g3_idx=0;g4_idx=6;over=0; end
					74:begin g0_idx=5;g1_idx=3;g2_idx=1;g3_idx=0;g4_idx=6;over=0; end
					75:begin g0_idx=1;g1_idx=0;g2_idx=3;g3_idx=6;g4_idx=5;over=0; end
					76:begin g0_idx=3;g1_idx=0;g2_idx=1;g3_idx=6;g4_idx=5;over=0; end
					77:begin g0_idx=1;g1_idx=3;g2_idx=0;g3_idx=6;g4_idx=5;over=0; end
					78:begin g0_idx=3;g1_idx=0;g2_idx=6;g3_idx=1;g4_idx=5;over=0; end
					79:begin g0_idx=6;g1_idx=0;g2_idx=3;g3_idx=1;g4_idx=5;over=0; end
					80:begin g0_idx=3;g1_idx=6;g2_idx=0;g3_idx=1;g4_idx=5;over=0; end
					81:begin g0_idx=6;g1_idx=3;g2_idx=0;g3_idx=1;g4_idx=5;over=0; end
					82:begin g0_idx=1;g1_idx=3;g2_idx=6;g3_idx=0;g4_idx=5;over=0; end
					83:begin g0_idx=1;g1_idx=6;g2_idx=3;g3_idx=0;g4_idx=5;over=0; end
					84:begin g0_idx=3;g1_idx=6;g2_idx=1;g3_idx=0;g4_idx=5;over=0; end
					85:begin g0_idx=6;g1_idx=3;g2_idx=1;g3_idx=0;g4_idx=5;over=0; end
					86:begin g0_idx=1;g1_idx=0;g2_idx=5;g3_idx=6;g4_idx=3;over=0; end
					87:begin g0_idx=5;g1_idx=0;g2_idx=1;g3_idx=6;g4_idx=3;over=0; end
					88:begin g0_idx=1;g1_idx=5;g2_idx=0;g3_idx=6;g4_idx=3;over=0; end
					89:begin g0_idx=1;g1_idx=0;g2_idx=6;g3_idx=5;g4_idx=3;over=0; end
					90:begin g0_idx=6;g1_idx=0;g2_idx=1;g3_idx=5;g4_idx=3;over=0; end
					91:begin g0_idx=1;g1_idx=6;g2_idx=0;g3_idx=5;g4_idx=3;over=0; end
					92:begin g0_idx=5;g1_idx=0;g2_idx=6;g3_idx=1;g4_idx=3;over=0; end
					93:begin g0_idx=6;g1_idx=0;g2_idx=5;g3_idx=1;g4_idx=3;over=0; end
					94:begin g0_idx=5;g1_idx=6;g2_idx=0;g3_idx=1;g4_idx=3;over=0; end
					95:begin g0_idx=6;g1_idx=5;g2_idx=0;g3_idx=1;g4_idx=3;over=0; end
					96:begin g0_idx=1;g1_idx=5;g2_idx=6;g3_idx=0;g4_idx=3;over=0; end
					97:begin g0_idx=1;g1_idx=6;g2_idx=5;g3_idx=0;g4_idx=3;over=0; end
					98:begin g0_idx=5;g1_idx=6;g2_idx=1;g3_idx=0;g4_idx=3;over=0; end
					99:begin g0_idx=6;g1_idx=5;g2_idx=1;g3_idx=0;g4_idx=3;over=0; end
					100:begin g0_idx=3;g1_idx=0;g2_idx=5;g3_idx=6;g4_idx=1;over=0; end
					101:begin g0_idx=5;g1_idx=0;g2_idx=3;g3_idx=6;g4_idx=1;over=0; end
					102:begin g0_idx=3;g1_idx=5;g2_idx=0;g3_idx=6;g4_idx=1;over=0; end
					103:begin g0_idx=5;g1_idx=3;g2_idx=0;g3_idx=6;g4_idx=1;over=0; end
					104:begin g0_idx=3;g1_idx=0;g2_idx=6;g3_idx=5;g4_idx=1;over=0; end
					105:begin g0_idx=6;g1_idx=0;g2_idx=3;g3_idx=5;g4_idx=1;over=0; end
					106:begin g0_idx=3;g1_idx=6;g2_idx=0;g3_idx=5;g4_idx=1;over=0; end
					107:begin g0_idx=6;g1_idx=3;g2_idx=0;g3_idx=5;g4_idx=1;over=0; end
					108:begin g0_idx=3;g1_idx=5;g2_idx=6;g3_idx=0;g4_idx=1;over=0; end
					109:begin g0_idx=5;g1_idx=3;g2_idx=6;g3_idx=0;g4_idx=1;over=0; end
					110:begin g0_idx=3;g1_idx=6;g2_idx=5;g3_idx=0;g4_idx=1;over=0; end
					111:begin g0_idx=6;g1_idx=3;g2_idx=5;g3_idx=0;g4_idx=1;over=0; end
					112:begin g0_idx=5;g1_idx=6;g2_idx=3;g3_idx=0;g4_idx=1;over=0; end
					113:begin g0_idx=6;g1_idx=5;g2_idx=3;g3_idx=0;g4_idx=1;over=0; end
					114:begin g0_idx=1;g1_idx=3;g2_idx=5;g3_idx=6;g4_idx=0;over=0; end
					115:begin g0_idx=1;g1_idx=5;g2_idx=3;g3_idx=6;g4_idx=0;over=0; end
					116:begin g0_idx=3;g1_idx=5;g2_idx=1;g3_idx=6;g4_idx=0;over=0; end
					117:begin g0_idx=5;g1_idx=3;g2_idx=1;g3_idx=6;g4_idx=0;over=0; end
					118:begin g0_idx=1;g1_idx=3;g2_idx=6;g3_idx=5;g4_idx=0;over=0; end
					119:begin g0_idx=1;g1_idx=6;g2_idx=3;g3_idx=5;g4_idx=0;over=0; end
					120:begin g0_idx=3;g1_idx=6;g2_idx=1;g3_idx=5;g4_idx=0;over=0; end
					121:begin g0_idx=6;g1_idx=3;g2_idx=1;g3_idx=5;g4_idx=0;over=0; end
					122:begin g0_idx=3;g1_idx=5;g2_idx=6;g3_idx=1;g4_idx=0;over=0; end
					123:begin g0_idx=5;g1_idx=3;g2_idx=6;g3_idx=1;g4_idx=0;over=0; end
					124:begin g0_idx=3;g1_idx=6;g2_idx=5;g3_idx=1;g4_idx=0;over=0; end
					125:begin g0_idx=6;g1_idx=3;g2_idx=5;g3_idx=1;g4_idx=0;over=0; end
					126:begin g0_idx=5;g1_idx=6;g2_idx=3;g3_idx=1;g4_idx=0;over=0; end
					127:begin g0_idx=6;g1_idx=5;g2_idx=3;g3_idx=1;g4_idx=0;over=0; end
					128:begin g0_idx=2;g1_idx=0;g2_idx=3;g3_idx=5;g4_idx=6;over=0; end
					129:begin g0_idx=2;g1_idx=3;g2_idx=0;g3_idx=5;g4_idx=6;over=0; end
					130:begin g0_idx=3;g1_idx=2;g2_idx=0;g3_idx=5;g4_idx=6;over=0; end
					131:begin g0_idx=3;g1_idx=0;g2_idx=5;g3_idx=2;g4_idx=6;over=0; end
					132:begin g0_idx=5;g1_idx=0;g2_idx=3;g3_idx=2;g4_idx=6;over=0; end
					133:begin g0_idx=3;g1_idx=5;g2_idx=0;g3_idx=2;g4_idx=6;over=0; end
					134:begin g0_idx=5;g1_idx=3;g2_idx=0;g3_idx=2;g4_idx=6;over=0; end
					135:begin g0_idx=2;g1_idx=3;g2_idx=5;g3_idx=0;g4_idx=6;over=0; end
					136:begin g0_idx=3;g1_idx=2;g2_idx=5;g3_idx=0;g4_idx=6;over=0; end
					137:begin g0_idx=2;g1_idx=5;g2_idx=3;g3_idx=0;g4_idx=6;over=0; end
					138:begin g0_idx=5;g1_idx=2;g2_idx=3;g3_idx=0;g4_idx=6;over=0; end
					139:begin g0_idx=2;g1_idx=0;g2_idx=3;g3_idx=6;g4_idx=5;over=0; end
					140:begin g0_idx=2;g1_idx=3;g2_idx=0;g3_idx=6;g4_idx=5;over=0; end
					141:begin g0_idx=3;g1_idx=2;g2_idx=0;g3_idx=6;g4_idx=5;over=0; end
					142:begin g0_idx=3;g1_idx=0;g2_idx=6;g3_idx=2;g4_idx=5;over=0; end
					143:begin g0_idx=6;g1_idx=0;g2_idx=3;g3_idx=2;g4_idx=5;over=0; end
					144:begin g0_idx=3;g1_idx=6;g2_idx=0;g3_idx=2;g4_idx=5;over=0; end
					145:begin g0_idx=6;g1_idx=3;g2_idx=0;g3_idx=2;g4_idx=5;over=0; end
					146:begin g0_idx=2;g1_idx=3;g2_idx=6;g3_idx=0;g4_idx=5;over=0; end
					147:begin g0_idx=3;g1_idx=2;g2_idx=6;g3_idx=0;g4_idx=5;over=0; end
					148:begin g0_idx=2;g1_idx=6;g2_idx=3;g3_idx=0;g4_idx=5;over=0; end
					149:begin g0_idx=6;g1_idx=2;g2_idx=3;g3_idx=0;g4_idx=5;over=0; end
					150:begin g0_idx=2;g1_idx=0;g2_idx=5;g3_idx=6;g4_idx=3;over=0; end
					151:begin g0_idx=2;g1_idx=5;g2_idx=0;g3_idx=6;g4_idx=3;over=0; end
					152:begin g0_idx=5;g1_idx=2;g2_idx=0;g3_idx=6;g4_idx=3;over=0; end
					153:begin g0_idx=2;g1_idx=0;g2_idx=6;g3_idx=5;g4_idx=3;over=0; end
					154:begin g0_idx=2;g1_idx=6;g2_idx=0;g3_idx=5;g4_idx=3;over=0; end
					155:begin g0_idx=6;g1_idx=2;g2_idx=0;g3_idx=5;g4_idx=3;over=0; end
					156:begin g0_idx=5;g1_idx=0;g2_idx=6;g3_idx=2;g4_idx=3;over=0; end
					157:begin g0_idx=6;g1_idx=0;g2_idx=5;g3_idx=2;g4_idx=3;over=0; end
					158:begin g0_idx=5;g1_idx=6;g2_idx=0;g3_idx=2;g4_idx=3;over=0; end
					159:begin g0_idx=6;g1_idx=5;g2_idx=0;g3_idx=2;g4_idx=3;over=0; end
					160:begin g0_idx=2;g1_idx=5;g2_idx=6;g3_idx=0;g4_idx=3;over=0; end
					161:begin g0_idx=5;g1_idx=2;g2_idx=6;g3_idx=0;g4_idx=3;over=0; end
					162:begin g0_idx=2;g1_idx=6;g2_idx=5;g3_idx=0;g4_idx=3;over=0; end
					163:begin g0_idx=6;g1_idx=2;g2_idx=5;g3_idx=0;g4_idx=3;over=0; end
					164:begin g0_idx=3;g1_idx=0;g2_idx=5;g3_idx=6;g4_idx=2;over=0; end
					165:begin g0_idx=5;g1_idx=0;g2_idx=3;g3_idx=6;g4_idx=2;over=0; end
					166:begin g0_idx=3;g1_idx=5;g2_idx=0;g3_idx=6;g4_idx=2;over=0; end
					167:begin g0_idx=5;g1_idx=3;g2_idx=0;g3_idx=6;g4_idx=2;over=0; end
					168:begin g0_idx=3;g1_idx=0;g2_idx=6;g3_idx=5;g4_idx=2;over=0; end
					169:begin g0_idx=6;g1_idx=0;g2_idx=3;g3_idx=5;g4_idx=2;over=0; end
					170:begin g0_idx=3;g1_idx=6;g2_idx=0;g3_idx=5;g4_idx=2;over=0; end
					171:begin g0_idx=6;g1_idx=3;g2_idx=0;g3_idx=5;g4_idx=2;over=0; end
					172:begin g0_idx=3;g1_idx=5;g2_idx=6;g3_idx=0;g4_idx=2;over=0; end
					173:begin g0_idx=5;g1_idx=3;g2_idx=6;g3_idx=0;g4_idx=2;over=0; end
					174:begin g0_idx=3;g1_idx=6;g2_idx=5;g3_idx=0;g4_idx=2;over=0; end
					175:begin g0_idx=6;g1_idx=3;g2_idx=5;g3_idx=0;g4_idx=2;over=0; end
					176:begin g0_idx=5;g1_idx=6;g2_idx=3;g3_idx=0;g4_idx=2;over=0; end
					177:begin g0_idx=6;g1_idx=5;g2_idx=3;g3_idx=0;g4_idx=2;over=0; end
					178:begin g0_idx=2;g1_idx=3;g2_idx=5;g3_idx=6;g4_idx=0;over=0; end
					179:begin g0_idx=3;g1_idx=2;g2_idx=5;g3_idx=6;g4_idx=0;over=0; end
					180:begin g0_idx=2;g1_idx=5;g2_idx=3;g3_idx=6;g4_idx=0;over=0; end
					181:begin g0_idx=5;g1_idx=2;g2_idx=3;g3_idx=6;g4_idx=0;over=0; end
					182:begin g0_idx=2;g1_idx=3;g2_idx=6;g3_idx=5;g4_idx=0;over=0; end
					183:begin g0_idx=3;g1_idx=2;g2_idx=6;g3_idx=5;g4_idx=0;over=0; end
					184:begin g0_idx=2;g1_idx=6;g2_idx=3;g3_idx=5;g4_idx=0;over=0; end
					185:begin g0_idx=6;g1_idx=2;g2_idx=3;g3_idx=5;g4_idx=0;over=0; end
					186:begin g0_idx=3;g1_idx=5;g2_idx=6;g3_idx=2;g4_idx=0;over=0; end
					187:begin g0_idx=5;g1_idx=3;g2_idx=6;g3_idx=2;g4_idx=0;over=0; end
					188:begin g0_idx=3;g1_idx=6;g2_idx=5;g3_idx=2;g4_idx=0;over=0; end
					189:begin g0_idx=6;g1_idx=3;g2_idx=5;g3_idx=2;g4_idx=0;over=0; end
					190:begin g0_idx=5;g1_idx=6;g2_idx=3;g3_idx=2;g4_idx=0;over=0; end
					191:begin g0_idx=6;g1_idx=5;g2_idx=3;g3_idx=2;g4_idx=0;over=0; end
					192:begin g0_idx=1;g1_idx=2;g2_idx=3;g3_idx=5;g4_idx=6;over=0; end
					193:begin g0_idx=2;g1_idx=3;g2_idx=1;g3_idx=5;g4_idx=6;over=0; end
					194:begin g0_idx=3;g1_idx=2;g2_idx=1;g3_idx=5;g4_idx=6;over=0; end
					195:begin g0_idx=1;g1_idx=3;g2_idx=5;g3_idx=2;g4_idx=6;over=0; end
					196:begin g0_idx=1;g1_idx=5;g2_idx=3;g3_idx=2;g4_idx=6;over=0; end
					197:begin g0_idx=3;g1_idx=5;g2_idx=1;g3_idx=2;g4_idx=6;over=0; end
					198:begin g0_idx=5;g1_idx=3;g2_idx=1;g3_idx=2;g4_idx=6;over=0; end
					199:begin g0_idx=2;g1_idx=3;g2_idx=5;g3_idx=1;g4_idx=6;over=0; end
					200:begin g0_idx=3;g1_idx=2;g2_idx=5;g3_idx=1;g4_idx=6;over=0; end
					201:begin g0_idx=2;g1_idx=5;g2_idx=3;g3_idx=1;g4_idx=6;over=0; end
					202:begin g0_idx=5;g1_idx=2;g2_idx=3;g3_idx=1;g4_idx=6;over=0; end
					203:begin g0_idx=1;g1_idx=2;g2_idx=3;g3_idx=6;g4_idx=5;over=0; end
					204:begin g0_idx=2;g1_idx=3;g2_idx=1;g3_idx=6;g4_idx=5;over=0; end
					205:begin g0_idx=3;g1_idx=2;g2_idx=1;g3_idx=6;g4_idx=5;over=0; end
					206:begin g0_idx=1;g1_idx=3;g2_idx=6;g3_idx=2;g4_idx=5;over=0; end
					207:begin g0_idx=1;g1_idx=6;g2_idx=3;g3_idx=2;g4_idx=5;over=0; end
					208:begin g0_idx=3;g1_idx=6;g2_idx=1;g3_idx=2;g4_idx=5;over=0; end
					209:begin g0_idx=6;g1_idx=3;g2_idx=1;g3_idx=2;g4_idx=5;over=0; end
					210:begin g0_idx=2;g1_idx=3;g2_idx=6;g3_idx=1;g4_idx=5;over=0; end
					211:begin g0_idx=3;g1_idx=2;g2_idx=6;g3_idx=1;g4_idx=5;over=0; end
					212:begin g0_idx=2;g1_idx=6;g2_idx=3;g3_idx=1;g4_idx=5;over=0; end
					213:begin g0_idx=6;g1_idx=2;g2_idx=3;g3_idx=1;g4_idx=5;over=0; end
					214:begin g0_idx=1;g1_idx=2;g2_idx=5;g3_idx=6;g4_idx=3;over=0; end
					215:begin g0_idx=2;g1_idx=5;g2_idx=1;g3_idx=6;g4_idx=3;over=0; end
					216:begin g0_idx=5;g1_idx=2;g2_idx=1;g3_idx=6;g4_idx=3;over=0; end
					217:begin g0_idx=1;g1_idx=2;g2_idx=6;g3_idx=5;g4_idx=3;over=0; end
					218:begin g0_idx=2;g1_idx=6;g2_idx=1;g3_idx=5;g4_idx=3;over=0; end
					219:begin g0_idx=6;g1_idx=2;g2_idx=1;g3_idx=5;g4_idx=3;over=0; end
					220:begin g0_idx=1;g1_idx=5;g2_idx=6;g3_idx=2;g4_idx=3;over=0; end
					221:begin g0_idx=1;g1_idx=6;g2_idx=5;g3_idx=2;g4_idx=3;over=0; end
					222:begin g0_idx=5;g1_idx=6;g2_idx=1;g3_idx=2;g4_idx=3;over=0; end
					223:begin g0_idx=6;g1_idx=5;g2_idx=1;g3_idx=2;g4_idx=3;over=0; end
					224:begin g0_idx=2;g1_idx=5;g2_idx=6;g3_idx=1;g4_idx=3;over=0; end
					225:begin g0_idx=5;g1_idx=2;g2_idx=6;g3_idx=1;g4_idx=3;over=0; end
					226:begin g0_idx=2;g1_idx=6;g2_idx=5;g3_idx=1;g4_idx=3;over=0; end
					227:begin g0_idx=6;g1_idx=2;g2_idx=5;g3_idx=1;g4_idx=3;over=0; end
					228:begin g0_idx=1;g1_idx=3;g2_idx=5;g3_idx=6;g4_idx=2;over=0; end
					229:begin g0_idx=1;g1_idx=5;g2_idx=3;g3_idx=6;g4_idx=2;over=0; end
					230:begin g0_idx=3;g1_idx=5;g2_idx=1;g3_idx=6;g4_idx=2;over=0; end
					231:begin g0_idx=5;g1_idx=3;g2_idx=1;g3_idx=6;g4_idx=2;over=0; end
					232:begin g0_idx=1;g1_idx=3;g2_idx=6;g3_idx=5;g4_idx=2;over=0; end
					233:begin g0_idx=1;g1_idx=6;g2_idx=3;g3_idx=5;g4_idx=2;over=0; end
					234:begin g0_idx=3;g1_idx=6;g2_idx=1;g3_idx=5;g4_idx=2;over=0; end
					235:begin g0_idx=6;g1_idx=3;g2_idx=1;g3_idx=5;g4_idx=2;over=0; end
					236:begin g0_idx=3;g1_idx=5;g2_idx=6;g3_idx=1;g4_idx=2;over=0; end
					237:begin g0_idx=5;g1_idx=3;g2_idx=6;g3_idx=1;g4_idx=2;over=0; end
					238:begin g0_idx=3;g1_idx=6;g2_idx=5;g3_idx=1;g4_idx=2;over=0; end
					239:begin g0_idx=6;g1_idx=3;g2_idx=5;g3_idx=1;g4_idx=2;over=0; end
					240:begin g0_idx=5;g1_idx=6;g2_idx=3;g3_idx=1;g4_idx=2;over=0; end
					241:begin g0_idx=6;g1_idx=5;g2_idx=3;g3_idx=1;g4_idx=2;over=0; end
					242:begin g0_idx=2;g1_idx=3;g2_idx=5;g3_idx=6;g4_idx=1;over=0; end
					243:begin g0_idx=3;g1_idx=2;g2_idx=5;g3_idx=6;g4_idx=1;over=0; end
					244:begin g0_idx=2;g1_idx=5;g2_idx=3;g3_idx=6;g4_idx=1;over=0; end
					245:begin g0_idx=5;g1_idx=2;g2_idx=3;g3_idx=6;g4_idx=1;over=0; end
					246:begin g0_idx=2;g1_idx=3;g2_idx=6;g3_idx=5;g4_idx=1;over=0; end
					247:begin g0_idx=3;g1_idx=2;g2_idx=6;g3_idx=5;g4_idx=1;over=0; end
					248:begin g0_idx=2;g1_idx=6;g2_idx=3;g3_idx=5;g4_idx=1;over=0; end
					249:begin g0_idx=6;g1_idx=2;g2_idx=3;g3_idx=5;g4_idx=1;over=0; end
					250:begin g0_idx=3;g1_idx=5;g2_idx=6;g3_idx=2;g4_idx=1;over=0; end
					251:begin g0_idx=5;g1_idx=3;g2_idx=6;g3_idx=2;g4_idx=1;over=0; end
					252:begin g0_idx=3;g1_idx=6;g2_idx=5;g3_idx=2;g4_idx=1;over=0; end
					253:begin g0_idx=6;g1_idx=3;g2_idx=5;g3_idx=2;g4_idx=1;over=0; end
					254:begin g0_idx=5;g1_idx=6;g2_idx=3;g3_idx=2;g4_idx=1;over=0; end
					255:begin g0_idx=6;g1_idx=5;g2_idx=3;g3_idx=2;g4_idx=1;over=0; end
					256:begin g0_idx=1;g1_idx=0;g2_idx=4;g3_idx=5;g4_idx=6;over=0; end
					257:begin g0_idx=4;g1_idx=0;g2_idx=1;g3_idx=5;g4_idx=6;over=0; end
					258:begin g0_idx=1;g1_idx=4;g2_idx=0;g3_idx=5;g4_idx=6;over=0; end
					259:begin g0_idx=1;g1_idx=0;g2_idx=5;g3_idx=4;g4_idx=6;over=0; end
					260:begin g0_idx=5;g1_idx=0;g2_idx=1;g3_idx=4;g4_idx=6;over=0; end
					261:begin g0_idx=1;g1_idx=5;g2_idx=0;g3_idx=4;g4_idx=6;over=0; end
					262:begin g0_idx=4;g1_idx=0;g2_idx=5;g3_idx=1;g4_idx=6;over=0; end
					263:begin g0_idx=5;g1_idx=0;g2_idx=4;g3_idx=1;g4_idx=6;over=0; end
					264:begin g0_idx=4;g1_idx=5;g2_idx=0;g3_idx=1;g4_idx=6;over=0; end
					265:begin g0_idx=5;g1_idx=4;g2_idx=0;g3_idx=1;g4_idx=6;over=0; end
					266:begin g0_idx=1;g1_idx=4;g2_idx=5;g3_idx=0;g4_idx=6;over=0; end
					267:begin g0_idx=1;g1_idx=5;g2_idx=4;g3_idx=0;g4_idx=6;over=0; end
					268:begin g0_idx=4;g1_idx=5;g2_idx=1;g3_idx=0;g4_idx=6;over=0; end
					269:begin g0_idx=5;g1_idx=4;g2_idx=1;g3_idx=0;g4_idx=6;over=0; end
					270:begin g0_idx=1;g1_idx=0;g2_idx=4;g3_idx=6;g4_idx=5;over=0; end
					271:begin g0_idx=4;g1_idx=0;g2_idx=1;g3_idx=6;g4_idx=5;over=0; end
					272:begin g0_idx=1;g1_idx=4;g2_idx=0;g3_idx=6;g4_idx=5;over=0; end
					273:begin g0_idx=1;g1_idx=0;g2_idx=6;g3_idx=4;g4_idx=5;over=0; end
					274:begin g0_idx=6;g1_idx=0;g2_idx=1;g3_idx=4;g4_idx=5;over=0; end
					275:begin g0_idx=1;g1_idx=6;g2_idx=0;g3_idx=4;g4_idx=5;over=0; end
					276:begin g0_idx=4;g1_idx=0;g2_idx=6;g3_idx=1;g4_idx=5;over=0; end
					277:begin g0_idx=6;g1_idx=0;g2_idx=4;g3_idx=1;g4_idx=5;over=0; end
					278:begin g0_idx=4;g1_idx=6;g2_idx=0;g3_idx=1;g4_idx=5;over=0; end
					279:begin g0_idx=6;g1_idx=4;g2_idx=0;g3_idx=1;g4_idx=5;over=0; end
					280:begin g0_idx=1;g1_idx=4;g2_idx=6;g3_idx=0;g4_idx=5;over=0; end
					281:begin g0_idx=1;g1_idx=6;g2_idx=4;g3_idx=0;g4_idx=5;over=0; end
					282:begin g0_idx=4;g1_idx=6;g2_idx=1;g3_idx=0;g4_idx=5;over=0; end
					283:begin g0_idx=6;g1_idx=4;g2_idx=1;g3_idx=0;g4_idx=5;over=0; end
					284:begin g0_idx=4;g1_idx=0;g2_idx=5;g3_idx=6;g4_idx=1;over=0; end
					285:begin g0_idx=5;g1_idx=0;g2_idx=4;g3_idx=6;g4_idx=1;over=0; end
					286:begin g0_idx=4;g1_idx=5;g2_idx=0;g3_idx=6;g4_idx=1;over=0; end
					287:begin g0_idx=5;g1_idx=4;g2_idx=0;g3_idx=6;g4_idx=1;over=0; end
					288:begin g0_idx=4;g1_idx=0;g2_idx=6;g3_idx=5;g4_idx=1;over=0; end
					289:begin g0_idx=6;g1_idx=0;g2_idx=4;g3_idx=5;g4_idx=1;over=0; end
					290:begin g0_idx=4;g1_idx=6;g2_idx=0;g3_idx=5;g4_idx=1;over=0; end
					291:begin g0_idx=6;g1_idx=4;g2_idx=0;g3_idx=5;g4_idx=1;over=0; end
					292:begin g0_idx=5;g1_idx=0;g2_idx=6;g3_idx=4;g4_idx=1;over=0; end
					293:begin g0_idx=6;g1_idx=0;g2_idx=5;g3_idx=4;g4_idx=1;over=0; end
					294:begin g0_idx=5;g1_idx=6;g2_idx=0;g3_idx=4;g4_idx=1;over=0; end
					295:begin g0_idx=6;g1_idx=5;g2_idx=0;g3_idx=4;g4_idx=1;over=0; end
					296:begin g0_idx=4;g1_idx=5;g2_idx=6;g3_idx=0;g4_idx=1;over=0; end
					297:begin g0_idx=5;g1_idx=4;g2_idx=6;g3_idx=0;g4_idx=1;over=0; end
					298:begin g0_idx=4;g1_idx=6;g2_idx=5;g3_idx=0;g4_idx=1;over=0; end
					299:begin g0_idx=6;g1_idx=4;g2_idx=5;g3_idx=0;g4_idx=1;over=0; end
					300:begin g0_idx=5;g1_idx=6;g2_idx=4;g3_idx=0;g4_idx=1;over=0; end
					301:begin g0_idx=6;g1_idx=5;g2_idx=4;g3_idx=0;g4_idx=1;over=0; end
					302:begin g0_idx=1;g1_idx=4;g2_idx=5;g3_idx=6;g4_idx=0;over=0; end
					303:begin g0_idx=1;g1_idx=5;g2_idx=4;g3_idx=6;g4_idx=0;over=0; end
					304:begin g0_idx=4;g1_idx=5;g2_idx=1;g3_idx=6;g4_idx=0;over=0; end
					305:begin g0_idx=5;g1_idx=4;g2_idx=1;g3_idx=6;g4_idx=0;over=0; end
					306:begin g0_idx=1;g1_idx=4;g2_idx=6;g3_idx=5;g4_idx=0;over=0; end
					307:begin g0_idx=1;g1_idx=6;g2_idx=4;g3_idx=5;g4_idx=0;over=0; end
					308:begin g0_idx=4;g1_idx=6;g2_idx=1;g3_idx=5;g4_idx=0;over=0; end
					309:begin g0_idx=6;g1_idx=4;g2_idx=1;g3_idx=5;g4_idx=0;over=0; end
					310:begin g0_idx=1;g1_idx=5;g2_idx=6;g3_idx=4;g4_idx=0;over=0; end
					311:begin g0_idx=1;g1_idx=6;g2_idx=5;g3_idx=4;g4_idx=0;over=0; end
					312:begin g0_idx=5;g1_idx=6;g2_idx=1;g3_idx=4;g4_idx=0;over=0; end
					313:begin g0_idx=6;g1_idx=5;g2_idx=1;g3_idx=4;g4_idx=0;over=0; end
					314:begin g0_idx=4;g1_idx=5;g2_idx=6;g3_idx=1;g4_idx=0;over=0; end
					315:begin g0_idx=5;g1_idx=4;g2_idx=6;g3_idx=1;g4_idx=0;over=0; end
					316:begin g0_idx=4;g1_idx=6;g2_idx=5;g3_idx=1;g4_idx=0;over=0; end
					317:begin g0_idx=6;g1_idx=4;g2_idx=5;g3_idx=1;g4_idx=0;over=0; end
					318:begin g0_idx=5;g1_idx=6;g2_idx=4;g3_idx=1;g4_idx=0;over=0; end
					319:begin g0_idx=6;g1_idx=5;g2_idx=4;g3_idx=1;g4_idx=0;over=0; end
					320:begin g0_idx=2;g1_idx=0;g2_idx=4;g3_idx=5;g4_idx=6;over=0; end
					321:begin g0_idx=2;g1_idx=4;g2_idx=0;g3_idx=5;g4_idx=6;over=0; end
					322:begin g0_idx=4;g1_idx=2;g2_idx=0;g3_idx=5;g4_idx=6;over=0; end
					323:begin g0_idx=2;g1_idx=0;g2_idx=5;g3_idx=4;g4_idx=6;over=0; end
					324:begin g0_idx=2;g1_idx=5;g2_idx=0;g3_idx=4;g4_idx=6;over=0; end
					325:begin g0_idx=5;g1_idx=2;g2_idx=0;g3_idx=4;g4_idx=6;over=0; end
					326:begin g0_idx=4;g1_idx=0;g2_idx=5;g3_idx=2;g4_idx=6;over=0; end
					327:begin g0_idx=5;g1_idx=0;g2_idx=4;g3_idx=2;g4_idx=6;over=0; end
					328:begin g0_idx=4;g1_idx=5;g2_idx=0;g3_idx=2;g4_idx=6;over=0; end
					329:begin g0_idx=5;g1_idx=4;g2_idx=0;g3_idx=2;g4_idx=6;over=0; end
					330:begin g0_idx=2;g1_idx=4;g2_idx=5;g3_idx=0;g4_idx=6;over=0; end
					331:begin g0_idx=4;g1_idx=2;g2_idx=5;g3_idx=0;g4_idx=6;over=0; end
					332:begin g0_idx=2;g1_idx=5;g2_idx=4;g3_idx=0;g4_idx=6;over=0; end
					333:begin g0_idx=5;g1_idx=2;g2_idx=4;g3_idx=0;g4_idx=6;over=0; end
					334:begin g0_idx=2;g1_idx=0;g2_idx=4;g3_idx=6;g4_idx=5;over=0; end
					335:begin g0_idx=2;g1_idx=4;g2_idx=0;g3_idx=6;g4_idx=5;over=0; end
					336:begin g0_idx=4;g1_idx=2;g2_idx=0;g3_idx=6;g4_idx=5;over=0; end
					337:begin g0_idx=2;g1_idx=0;g2_idx=6;g3_idx=4;g4_idx=5;over=0; end
					338:begin g0_idx=2;g1_idx=6;g2_idx=0;g3_idx=4;g4_idx=5;over=0; end
					339:begin g0_idx=6;g1_idx=2;g2_idx=0;g3_idx=4;g4_idx=5;over=0; end
					340:begin g0_idx=4;g1_idx=0;g2_idx=6;g3_idx=2;g4_idx=5;over=0; end
					341:begin g0_idx=6;g1_idx=0;g2_idx=4;g3_idx=2;g4_idx=5;over=0; end
					342:begin g0_idx=4;g1_idx=6;g2_idx=0;g3_idx=2;g4_idx=5;over=0; end
					343:begin g0_idx=6;g1_idx=4;g2_idx=0;g3_idx=2;g4_idx=5;over=0; end
					344:begin g0_idx=2;g1_idx=4;g2_idx=6;g3_idx=0;g4_idx=5;over=0; end
					345:begin g0_idx=4;g1_idx=2;g2_idx=6;g3_idx=0;g4_idx=5;over=0; end
					346:begin g0_idx=2;g1_idx=6;g2_idx=4;g3_idx=0;g4_idx=5;over=0; end
					347:begin g0_idx=6;g1_idx=2;g2_idx=4;g3_idx=0;g4_idx=5;over=0; end
					348:begin g0_idx=4;g1_idx=0;g2_idx=5;g3_idx=6;g4_idx=2;over=0; end
					349:begin g0_idx=5;g1_idx=0;g2_idx=4;g3_idx=6;g4_idx=2;over=0; end
					350:begin g0_idx=4;g1_idx=5;g2_idx=0;g3_idx=6;g4_idx=2;over=0; end
					351:begin g0_idx=5;g1_idx=4;g2_idx=0;g3_idx=6;g4_idx=2;over=0; end
					352:begin g0_idx=4;g1_idx=0;g2_idx=6;g3_idx=5;g4_idx=2;over=0; end
					353:begin g0_idx=6;g1_idx=0;g2_idx=4;g3_idx=5;g4_idx=2;over=0; end
					354:begin g0_idx=4;g1_idx=6;g2_idx=0;g3_idx=5;g4_idx=2;over=0; end
					355:begin g0_idx=6;g1_idx=4;g2_idx=0;g3_idx=5;g4_idx=2;over=0; end
					356:begin g0_idx=5;g1_idx=0;g2_idx=6;g3_idx=4;g4_idx=2;over=0; end
					357:begin g0_idx=6;g1_idx=0;g2_idx=5;g3_idx=4;g4_idx=2;over=0; end
					358:begin g0_idx=5;g1_idx=6;g2_idx=0;g3_idx=4;g4_idx=2;over=0; end
					359:begin g0_idx=6;g1_idx=5;g2_idx=0;g3_idx=4;g4_idx=2;over=0; end
					360:begin g0_idx=4;g1_idx=5;g2_idx=6;g3_idx=0;g4_idx=2;over=0; end
					361:begin g0_idx=5;g1_idx=4;g2_idx=6;g3_idx=0;g4_idx=2;over=0; end
					362:begin g0_idx=4;g1_idx=6;g2_idx=5;g3_idx=0;g4_idx=2;over=0; end
					363:begin g0_idx=6;g1_idx=4;g2_idx=5;g3_idx=0;g4_idx=2;over=0; end
					364:begin g0_idx=5;g1_idx=6;g2_idx=4;g3_idx=0;g4_idx=2;over=0; end
					365:begin g0_idx=6;g1_idx=5;g2_idx=4;g3_idx=0;g4_idx=2;over=0; end
					366:begin g0_idx=2;g1_idx=4;g2_idx=5;g3_idx=6;g4_idx=0;over=0; end
					367:begin g0_idx=4;g1_idx=2;g2_idx=5;g3_idx=6;g4_idx=0;over=0; end
					368:begin g0_idx=2;g1_idx=5;g2_idx=4;g3_idx=6;g4_idx=0;over=0; end
					369:begin g0_idx=5;g1_idx=2;g2_idx=4;g3_idx=6;g4_idx=0;over=0; end
					370:begin g0_idx=2;g1_idx=4;g2_idx=6;g3_idx=5;g4_idx=0;over=0; end
					371:begin g0_idx=4;g1_idx=2;g2_idx=6;g3_idx=5;g4_idx=0;over=0; end
					372:begin g0_idx=2;g1_idx=6;g2_idx=4;g3_idx=5;g4_idx=0;over=0; end
					373:begin g0_idx=6;g1_idx=2;g2_idx=4;g3_idx=5;g4_idx=0;over=0; end
					374:begin g0_idx=2;g1_idx=5;g2_idx=6;g3_idx=4;g4_idx=0;over=0; end
					375:begin g0_idx=5;g1_idx=2;g2_idx=6;g3_idx=4;g4_idx=0;over=0; end
					376:begin g0_idx=2;g1_idx=6;g2_idx=5;g3_idx=4;g4_idx=0;over=0; end
					377:begin g0_idx=6;g1_idx=2;g2_idx=5;g3_idx=4;g4_idx=0;over=0; end
					378:begin g0_idx=4;g1_idx=5;g2_idx=6;g3_idx=2;g4_idx=0;over=0; end
					379:begin g0_idx=5;g1_idx=4;g2_idx=6;g3_idx=2;g4_idx=0;over=0; end
					380:begin g0_idx=4;g1_idx=6;g2_idx=5;g3_idx=2;g4_idx=0;over=0; end
					381:begin g0_idx=6;g1_idx=4;g2_idx=5;g3_idx=2;g4_idx=0;over=0; end
					382:begin g0_idx=5;g1_idx=6;g2_idx=4;g3_idx=2;g4_idx=0;over=0; end
					383:begin g0_idx=6;g1_idx=5;g2_idx=4;g3_idx=2;g4_idx=0;over=0; end
					384:begin g0_idx=1;g1_idx=2;g2_idx=4;g3_idx=5;g4_idx=6;over=0; end
					385:begin g0_idx=2;g1_idx=4;g2_idx=1;g3_idx=5;g4_idx=6;over=0; end
					386:begin g0_idx=4;g1_idx=2;g2_idx=1;g3_idx=5;g4_idx=6;over=0; end
					387:begin g0_idx=1;g1_idx=2;g2_idx=5;g3_idx=4;g4_idx=6;over=0; end
					388:begin g0_idx=2;g1_idx=5;g2_idx=1;g3_idx=4;g4_idx=6;over=0; end
					389:begin g0_idx=5;g1_idx=2;g2_idx=1;g3_idx=4;g4_idx=6;over=0; end
					390:begin g0_idx=1;g1_idx=4;g2_idx=5;g3_idx=2;g4_idx=6;over=0; end
					391:begin g0_idx=1;g1_idx=5;g2_idx=4;g3_idx=2;g4_idx=6;over=0; end
					392:begin g0_idx=4;g1_idx=5;g2_idx=1;g3_idx=2;g4_idx=6;over=0; end
					393:begin g0_idx=5;g1_idx=4;g2_idx=1;g3_idx=2;g4_idx=6;over=0; end
					394:begin g0_idx=2;g1_idx=4;g2_idx=5;g3_idx=1;g4_idx=6;over=0; end
					395:begin g0_idx=4;g1_idx=2;g2_idx=5;g3_idx=1;g4_idx=6;over=0; end
					396:begin g0_idx=2;g1_idx=5;g2_idx=4;g3_idx=1;g4_idx=6;over=0; end
					397:begin g0_idx=5;g1_idx=2;g2_idx=4;g3_idx=1;g4_idx=6;over=0; end
					398:begin g0_idx=1;g1_idx=2;g2_idx=4;g3_idx=6;g4_idx=5;over=0; end
					399:begin g0_idx=2;g1_idx=4;g2_idx=1;g3_idx=6;g4_idx=5;over=0; end
					400:begin g0_idx=4;g1_idx=2;g2_idx=1;g3_idx=6;g4_idx=5;over=0; end
					401:begin g0_idx=1;g1_idx=2;g2_idx=6;g3_idx=4;g4_idx=5;over=0; end
					402:begin g0_idx=2;g1_idx=6;g2_idx=1;g3_idx=4;g4_idx=5;over=0; end
					403:begin g0_idx=6;g1_idx=2;g2_idx=1;g3_idx=4;g4_idx=5;over=0; end
					404:begin g0_idx=1;g1_idx=4;g2_idx=6;g3_idx=2;g4_idx=5;over=0; end
					405:begin g0_idx=1;g1_idx=6;g2_idx=4;g3_idx=2;g4_idx=5;over=0; end
					406:begin g0_idx=4;g1_idx=6;g2_idx=1;g3_idx=2;g4_idx=5;over=0; end
					407:begin g0_idx=6;g1_idx=4;g2_idx=1;g3_idx=2;g4_idx=5;over=0; end
					408:begin g0_idx=2;g1_idx=4;g2_idx=6;g3_idx=1;g4_idx=5;over=0; end
					409:begin g0_idx=4;g1_idx=2;g2_idx=6;g3_idx=1;g4_idx=5;over=0; end
					410:begin g0_idx=2;g1_idx=6;g2_idx=4;g3_idx=1;g4_idx=5;over=0; end
					411:begin g0_idx=6;g1_idx=2;g2_idx=4;g3_idx=1;g4_idx=5;over=0; end
					412:begin g0_idx=1;g1_idx=4;g2_idx=5;g3_idx=6;g4_idx=2;over=0; end
					413:begin g0_idx=1;g1_idx=5;g2_idx=4;g3_idx=6;g4_idx=2;over=0; end
					414:begin g0_idx=4;g1_idx=5;g2_idx=1;g3_idx=6;g4_idx=2;over=0; end
					415:begin g0_idx=5;g1_idx=4;g2_idx=1;g3_idx=6;g4_idx=2;over=0; end
					416:begin g0_idx=1;g1_idx=4;g2_idx=6;g3_idx=5;g4_idx=2;over=0; end
					417:begin g0_idx=1;g1_idx=6;g2_idx=4;g3_idx=5;g4_idx=2;over=0; end
					418:begin g0_idx=4;g1_idx=6;g2_idx=1;g3_idx=5;g4_idx=2;over=0; end
					419:begin g0_idx=6;g1_idx=4;g2_idx=1;g3_idx=5;g4_idx=2;over=0; end
					420:begin g0_idx=1;g1_idx=5;g2_idx=6;g3_idx=4;g4_idx=2;over=0; end
					421:begin g0_idx=1;g1_idx=6;g2_idx=5;g3_idx=4;g4_idx=2;over=0; end
					422:begin g0_idx=5;g1_idx=6;g2_idx=1;g3_idx=4;g4_idx=2;over=0; end
					423:begin g0_idx=6;g1_idx=5;g2_idx=1;g3_idx=4;g4_idx=2;over=0; end
					424:begin g0_idx=4;g1_idx=5;g2_idx=6;g3_idx=1;g4_idx=2;over=0; end
					425:begin g0_idx=5;g1_idx=4;g2_idx=6;g3_idx=1;g4_idx=2;over=0; end
					426:begin g0_idx=4;g1_idx=6;g2_idx=5;g3_idx=1;g4_idx=2;over=0; end
					427:begin g0_idx=6;g1_idx=4;g2_idx=5;g3_idx=1;g4_idx=2;over=0; end
					428:begin g0_idx=5;g1_idx=6;g2_idx=4;g3_idx=1;g4_idx=2;over=0; end
					429:begin g0_idx=6;g1_idx=5;g2_idx=4;g3_idx=1;g4_idx=2;over=0; end
					430:begin g0_idx=2;g1_idx=4;g2_idx=5;g3_idx=6;g4_idx=1;over=0; end
					431:begin g0_idx=4;g1_idx=2;g2_idx=5;g3_idx=6;g4_idx=1;over=0; end
					432:begin g0_idx=2;g1_idx=5;g2_idx=4;g3_idx=6;g4_idx=1;over=0; end
					433:begin g0_idx=5;g1_idx=2;g2_idx=4;g3_idx=6;g4_idx=1;over=0; end
					434:begin g0_idx=2;g1_idx=4;g2_idx=6;g3_idx=5;g4_idx=1;over=0; end
					435:begin g0_idx=4;g1_idx=2;g2_idx=6;g3_idx=5;g4_idx=1;over=0; end
					436:begin g0_idx=2;g1_idx=6;g2_idx=4;g3_idx=5;g4_idx=1;over=0; end
					437:begin g0_idx=6;g1_idx=2;g2_idx=4;g3_idx=5;g4_idx=1;over=0; end
					438:begin g0_idx=2;g1_idx=5;g2_idx=6;g3_idx=4;g4_idx=1;over=0; end
					439:begin g0_idx=5;g1_idx=2;g2_idx=6;g3_idx=4;g4_idx=1;over=0; end
					440:begin g0_idx=2;g1_idx=6;g2_idx=5;g3_idx=4;g4_idx=1;over=0; end
					441:begin g0_idx=6;g1_idx=2;g2_idx=5;g3_idx=4;g4_idx=1;over=0; end
					442:begin g0_idx=4;g1_idx=5;g2_idx=6;g3_idx=2;g4_idx=1;over=0; end
					443:begin g0_idx=5;g1_idx=4;g2_idx=6;g3_idx=2;g4_idx=1;over=0; end
					444:begin g0_idx=4;g1_idx=6;g2_idx=5;g3_idx=2;g4_idx=1;over=0; end
					445:begin g0_idx=6;g1_idx=4;g2_idx=5;g3_idx=2;g4_idx=1;over=0; end
					446:begin g0_idx=5;g1_idx=6;g2_idx=4;g3_idx=2;g4_idx=1;over=0; end
					447:begin g0_idx=6;g1_idx=5;g2_idx=4;g3_idx=2;g4_idx=1;over=0; end
					448:begin g0_idx=3;g1_idx=0;g2_idx=4;g3_idx=5;g4_idx=6;over=0; end
					449:begin g0_idx=4;g1_idx=0;g2_idx=3;g3_idx=5;g4_idx=6;over=0; end
					450:begin g0_idx=3;g1_idx=4;g2_idx=0;g3_idx=5;g4_idx=6;over=0; end
					451:begin g0_idx=4;g1_idx=3;g2_idx=0;g3_idx=5;g4_idx=6;over=0; end
					452:begin g0_idx=3;g1_idx=0;g2_idx=5;g3_idx=4;g4_idx=6;over=0; end
					453:begin g0_idx=5;g1_idx=0;g2_idx=3;g3_idx=4;g4_idx=6;over=0; end
					454:begin g0_idx=3;g1_idx=5;g2_idx=0;g3_idx=4;g4_idx=6;over=0; end
					455:begin g0_idx=5;g1_idx=3;g2_idx=0;g3_idx=4;g4_idx=6;over=0; end
					456:begin g0_idx=3;g1_idx=4;g2_idx=5;g3_idx=0;g4_idx=6;over=0; end
					457:begin g0_idx=4;g1_idx=3;g2_idx=5;g3_idx=0;g4_idx=6;over=0; end
					458:begin g0_idx=3;g1_idx=5;g2_idx=4;g3_idx=0;g4_idx=6;over=0; end
					459:begin g0_idx=5;g1_idx=3;g2_idx=4;g3_idx=0;g4_idx=6;over=0; end
					460:begin g0_idx=4;g1_idx=5;g2_idx=3;g3_idx=0;g4_idx=6;over=0; end
					461:begin g0_idx=5;g1_idx=4;g2_idx=3;g3_idx=0;g4_idx=6;over=0; end
					462:begin g0_idx=3;g1_idx=0;g2_idx=4;g3_idx=6;g4_idx=5;over=0; end
					463:begin g0_idx=4;g1_idx=0;g2_idx=3;g3_idx=6;g4_idx=5;over=0; end
					464:begin g0_idx=3;g1_idx=4;g2_idx=0;g3_idx=6;g4_idx=5;over=0; end
					465:begin g0_idx=4;g1_idx=3;g2_idx=0;g3_idx=6;g4_idx=5;over=0; end
					466:begin g0_idx=3;g1_idx=0;g2_idx=6;g3_idx=4;g4_idx=5;over=0; end
					467:begin g0_idx=6;g1_idx=0;g2_idx=3;g3_idx=4;g4_idx=5;over=0; end
					468:begin g0_idx=3;g1_idx=6;g2_idx=0;g3_idx=4;g4_idx=5;over=0; end
					469:begin g0_idx=6;g1_idx=3;g2_idx=0;g3_idx=4;g4_idx=5;over=0; end
					470:begin g0_idx=3;g1_idx=4;g2_idx=6;g3_idx=0;g4_idx=5;over=0; end
					471:begin g0_idx=4;g1_idx=3;g2_idx=6;g3_idx=0;g4_idx=5;over=0; end
					472:begin g0_idx=3;g1_idx=6;g2_idx=4;g3_idx=0;g4_idx=5;over=0; end
					473:begin g0_idx=6;g1_idx=3;g2_idx=4;g3_idx=0;g4_idx=5;over=0; end
					474:begin g0_idx=4;g1_idx=6;g2_idx=3;g3_idx=0;g4_idx=5;over=0; end
					475:begin g0_idx=6;g1_idx=4;g2_idx=3;g3_idx=0;g4_idx=5;over=0; end
					476:begin g0_idx=4;g1_idx=0;g2_idx=5;g3_idx=6;g4_idx=3;over=0; end
					477:begin g0_idx=5;g1_idx=0;g2_idx=4;g3_idx=6;g4_idx=3;over=0; end
					478:begin g0_idx=4;g1_idx=5;g2_idx=0;g3_idx=6;g4_idx=3;over=0; end
					479:begin g0_idx=5;g1_idx=4;g2_idx=0;g3_idx=6;g4_idx=3;over=0; end
					480:begin g0_idx=4;g1_idx=0;g2_idx=6;g3_idx=5;g4_idx=3;over=0; end
					481:begin g0_idx=6;g1_idx=0;g2_idx=4;g3_idx=5;g4_idx=3;over=0; end
					482:begin g0_idx=4;g1_idx=6;g2_idx=0;g3_idx=5;g4_idx=3;over=0; end
					483:begin g0_idx=6;g1_idx=4;g2_idx=0;g3_idx=5;g4_idx=3;over=0; end
					484:begin g0_idx=5;g1_idx=0;g2_idx=6;g3_idx=4;g4_idx=3;over=0; end
					485:begin g0_idx=6;g1_idx=0;g2_idx=5;g3_idx=4;g4_idx=3;over=0; end
					486:begin g0_idx=5;g1_idx=6;g2_idx=0;g3_idx=4;g4_idx=3;over=0; end
					487:begin g0_idx=6;g1_idx=5;g2_idx=0;g3_idx=4;g4_idx=3;over=0; end
					488:begin g0_idx=4;g1_idx=5;g2_idx=6;g3_idx=0;g4_idx=3;over=0; end
					489:begin g0_idx=5;g1_idx=4;g2_idx=6;g3_idx=0;g4_idx=3;over=0; end
					490:begin g0_idx=4;g1_idx=6;g2_idx=5;g3_idx=0;g4_idx=3;over=0; end
					491:begin g0_idx=6;g1_idx=4;g2_idx=5;g3_idx=0;g4_idx=3;over=0; end
					492:begin g0_idx=5;g1_idx=6;g2_idx=4;g3_idx=0;g4_idx=3;over=0; end
					493:begin g0_idx=6;g1_idx=5;g2_idx=4;g3_idx=0;g4_idx=3;over=0; end
					494:begin g0_idx=3;g1_idx=4;g2_idx=5;g3_idx=6;g4_idx=0;over=0; end
					495:begin g0_idx=4;g1_idx=3;g2_idx=5;g3_idx=6;g4_idx=0;over=0; end
					496:begin g0_idx=3;g1_idx=5;g2_idx=4;g3_idx=6;g4_idx=0;over=0; end
					497:begin g0_idx=5;g1_idx=3;g2_idx=4;g3_idx=6;g4_idx=0;over=0; end
					498:begin g0_idx=4;g1_idx=5;g2_idx=3;g3_idx=6;g4_idx=0;over=0; end
					499:begin g0_idx=5;g1_idx=4;g2_idx=3;g3_idx=6;g4_idx=0;over=0; end
					500:begin g0_idx=3;g1_idx=4;g2_idx=6;g3_idx=5;g4_idx=0;over=0; end
					501:begin g0_idx=4;g1_idx=3;g2_idx=6;g3_idx=5;g4_idx=0;over=0; end
					502:begin g0_idx=3;g1_idx=6;g2_idx=4;g3_idx=5;g4_idx=0;over=0; end
					503:begin g0_idx=6;g1_idx=3;g2_idx=4;g3_idx=5;g4_idx=0;over=0; end
					504:begin g0_idx=4;g1_idx=6;g2_idx=3;g3_idx=5;g4_idx=0;over=0; end
					505:begin g0_idx=6;g1_idx=4;g2_idx=3;g3_idx=5;g4_idx=0;over=0; end
					506:begin g0_idx=3;g1_idx=5;g2_idx=6;g3_idx=4;g4_idx=0;over=0; end
					507:begin g0_idx=5;g1_idx=3;g2_idx=6;g3_idx=4;g4_idx=0;over=0; end
					508:begin g0_idx=3;g1_idx=6;g2_idx=5;g3_idx=4;g4_idx=0;over=0; end
					509:begin g0_idx=6;g1_idx=3;g2_idx=5;g3_idx=4;g4_idx=0;over=0; end
					510:begin g0_idx=5;g1_idx=6;g2_idx=3;g3_idx=4;g4_idx=0;over=0; end
					511:begin g0_idx=6;g1_idx=5;g2_idx=3;g3_idx=4;g4_idx=0;over=0; end
					512:begin g0_idx=1;g1_idx=3;g2_idx=4;g3_idx=5;g4_idx=6;over=0; end
					513:begin g0_idx=1;g1_idx=4;g2_idx=3;g3_idx=5;g4_idx=6;over=0; end
					514:begin g0_idx=3;g1_idx=4;g2_idx=1;g3_idx=5;g4_idx=6;over=0; end
					515:begin g0_idx=4;g1_idx=3;g2_idx=1;g3_idx=5;g4_idx=6;over=0; end
					516:begin g0_idx=1;g1_idx=3;g2_idx=5;g3_idx=4;g4_idx=6;over=0; end
					517:begin g0_idx=1;g1_idx=5;g2_idx=3;g3_idx=4;g4_idx=6;over=0; end
					518:begin g0_idx=3;g1_idx=5;g2_idx=1;g3_idx=4;g4_idx=6;over=0; end
					519:begin g0_idx=5;g1_idx=3;g2_idx=1;g3_idx=4;g4_idx=6;over=0; end
					520:begin g0_idx=3;g1_idx=4;g2_idx=5;g3_idx=1;g4_idx=6;over=0; end
					521:begin g0_idx=4;g1_idx=3;g2_idx=5;g3_idx=1;g4_idx=6;over=0; end
					522:begin g0_idx=3;g1_idx=5;g2_idx=4;g3_idx=1;g4_idx=6;over=0; end
					523:begin g0_idx=5;g1_idx=3;g2_idx=4;g3_idx=1;g4_idx=6;over=0; end
					524:begin g0_idx=4;g1_idx=5;g2_idx=3;g3_idx=1;g4_idx=6;over=0; end
					525:begin g0_idx=5;g1_idx=4;g2_idx=3;g3_idx=1;g4_idx=6;over=0; end
					526:begin g0_idx=1;g1_idx=3;g2_idx=4;g3_idx=6;g4_idx=5;over=0; end
					527:begin g0_idx=1;g1_idx=4;g2_idx=3;g3_idx=6;g4_idx=5;over=0; end
					528:begin g0_idx=3;g1_idx=4;g2_idx=1;g3_idx=6;g4_idx=5;over=0; end
					529:begin g0_idx=4;g1_idx=3;g2_idx=1;g3_idx=6;g4_idx=5;over=0; end
					530:begin g0_idx=1;g1_idx=3;g2_idx=6;g3_idx=4;g4_idx=5;over=0; end
					531:begin g0_idx=1;g1_idx=6;g2_idx=3;g3_idx=4;g4_idx=5;over=0; end
					532:begin g0_idx=3;g1_idx=6;g2_idx=1;g3_idx=4;g4_idx=5;over=0; end
					533:begin g0_idx=6;g1_idx=3;g2_idx=1;g3_idx=4;g4_idx=5;over=0; end
					534:begin g0_idx=3;g1_idx=4;g2_idx=6;g3_idx=1;g4_idx=5;over=0; end
					535:begin g0_idx=4;g1_idx=3;g2_idx=6;g3_idx=1;g4_idx=5;over=0; end
					536:begin g0_idx=3;g1_idx=6;g2_idx=4;g3_idx=1;g4_idx=5;over=0; end
					537:begin g0_idx=6;g1_idx=3;g2_idx=4;g3_idx=1;g4_idx=5;over=0; end
					538:begin g0_idx=4;g1_idx=6;g2_idx=3;g3_idx=1;g4_idx=5;over=0; end
					539:begin g0_idx=6;g1_idx=4;g2_idx=3;g3_idx=1;g4_idx=5;over=0; end
					540:begin g0_idx=1;g1_idx=4;g2_idx=5;g3_idx=6;g4_idx=3;over=0; end
					541:begin g0_idx=1;g1_idx=5;g2_idx=4;g3_idx=6;g4_idx=3;over=0; end
					542:begin g0_idx=4;g1_idx=5;g2_idx=1;g3_idx=6;g4_idx=3;over=0; end
					543:begin g0_idx=5;g1_idx=4;g2_idx=1;g3_idx=6;g4_idx=3;over=0; end
					544:begin g0_idx=1;g1_idx=4;g2_idx=6;g3_idx=5;g4_idx=3;over=0; end
					545:begin g0_idx=1;g1_idx=6;g2_idx=4;g3_idx=5;g4_idx=3;over=0; end
					546:begin g0_idx=4;g1_idx=6;g2_idx=1;g3_idx=5;g4_idx=3;over=0; end
					547:begin g0_idx=6;g1_idx=4;g2_idx=1;g3_idx=5;g4_idx=3;over=0; end
					548:begin g0_idx=1;g1_idx=5;g2_idx=6;g3_idx=4;g4_idx=3;over=0; end
					549:begin g0_idx=1;g1_idx=6;g2_idx=5;g3_idx=4;g4_idx=3;over=0; end
					550:begin g0_idx=5;g1_idx=6;g2_idx=1;g3_idx=4;g4_idx=3;over=0; end
					551:begin g0_idx=6;g1_idx=5;g2_idx=1;g3_idx=4;g4_idx=3;over=0; end
					552:begin g0_idx=4;g1_idx=5;g2_idx=6;g3_idx=1;g4_idx=3;over=0; end
					553:begin g0_idx=5;g1_idx=4;g2_idx=6;g3_idx=1;g4_idx=3;over=0; end
					554:begin g0_idx=4;g1_idx=6;g2_idx=5;g3_idx=1;g4_idx=3;over=0; end
					555:begin g0_idx=6;g1_idx=4;g2_idx=5;g3_idx=1;g4_idx=3;over=0; end
					556:begin g0_idx=5;g1_idx=6;g2_idx=4;g3_idx=1;g4_idx=3;over=0; end
					557:begin g0_idx=6;g1_idx=5;g2_idx=4;g3_idx=1;g4_idx=3;over=0; end
					558:begin g0_idx=3;g1_idx=4;g2_idx=5;g3_idx=6;g4_idx=1;over=0; end
					559:begin g0_idx=4;g1_idx=3;g2_idx=5;g3_idx=6;g4_idx=1;over=0; end
					560:begin g0_idx=3;g1_idx=5;g2_idx=4;g3_idx=6;g4_idx=1;over=0; end
					561:begin g0_idx=5;g1_idx=3;g2_idx=4;g3_idx=6;g4_idx=1;over=0; end
					562:begin g0_idx=4;g1_idx=5;g2_idx=3;g3_idx=6;g4_idx=1;over=0; end
					563:begin g0_idx=5;g1_idx=4;g2_idx=3;g3_idx=6;g4_idx=1;over=0; end
					564:begin g0_idx=3;g1_idx=4;g2_idx=6;g3_idx=5;g4_idx=1;over=0; end
					565:begin g0_idx=4;g1_idx=3;g2_idx=6;g3_idx=5;g4_idx=1;over=0; end
					566:begin g0_idx=3;g1_idx=6;g2_idx=4;g3_idx=5;g4_idx=1;over=0; end
					567:begin g0_idx=6;g1_idx=3;g2_idx=4;g3_idx=5;g4_idx=1;over=0; end
					568:begin g0_idx=4;g1_idx=6;g2_idx=3;g3_idx=5;g4_idx=1;over=0; end
					569:begin g0_idx=6;g1_idx=4;g2_idx=3;g3_idx=5;g4_idx=1;over=0; end
					570:begin g0_idx=3;g1_idx=5;g2_idx=6;g3_idx=4;g4_idx=1;over=0; end
					571:begin g0_idx=5;g1_idx=3;g2_idx=6;g3_idx=4;g4_idx=1;over=0; end
					572:begin g0_idx=3;g1_idx=6;g2_idx=5;g3_idx=4;g4_idx=1;over=0; end
					573:begin g0_idx=6;g1_idx=3;g2_idx=5;g3_idx=4;g4_idx=1;over=0; end
					574:begin g0_idx=5;g1_idx=6;g2_idx=3;g3_idx=4;g4_idx=1;over=0; end
					575:begin g0_idx=6;g1_idx=5;g2_idx=3;g3_idx=4;g4_idx=1;over=0; end
					576:begin g0_idx=2;g1_idx=3;g2_idx=4;g3_idx=5;g4_idx=6;over=0; end
					577:begin g0_idx=3;g1_idx=2;g2_idx=4;g3_idx=5;g4_idx=6;over=0; end
					578:begin g0_idx=2;g1_idx=4;g2_idx=3;g3_idx=5;g4_idx=6;over=0; end
					579:begin g0_idx=4;g1_idx=2;g2_idx=3;g3_idx=5;g4_idx=6;over=0; end
					580:begin g0_idx=2;g1_idx=3;g2_idx=5;g3_idx=4;g4_idx=6;over=0; end
					581:begin g0_idx=3;g1_idx=2;g2_idx=5;g3_idx=4;g4_idx=6;over=0; end
					582:begin g0_idx=2;g1_idx=5;g2_idx=3;g3_idx=4;g4_idx=6;over=0; end
					583:begin g0_idx=5;g1_idx=2;g2_idx=3;g3_idx=4;g4_idx=6;over=0; end
					584:begin g0_idx=3;g1_idx=4;g2_idx=5;g3_idx=2;g4_idx=6;over=0; end
					585:begin g0_idx=4;g1_idx=3;g2_idx=5;g3_idx=2;g4_idx=6;over=0; end
					586:begin g0_idx=3;g1_idx=5;g2_idx=4;g3_idx=2;g4_idx=6;over=0; end
					587:begin g0_idx=5;g1_idx=3;g2_idx=4;g3_idx=2;g4_idx=6;over=0; end
					588:begin g0_idx=4;g1_idx=5;g2_idx=3;g3_idx=2;g4_idx=6;over=0; end
					589:begin g0_idx=5;g1_idx=4;g2_idx=3;g3_idx=2;g4_idx=6;over=0; end
					590:begin g0_idx=2;g1_idx=3;g2_idx=4;g3_idx=6;g4_idx=5;over=0; end
					591:begin g0_idx=3;g1_idx=2;g2_idx=4;g3_idx=6;g4_idx=5;over=0; end
					592:begin g0_idx=2;g1_idx=4;g2_idx=3;g3_idx=6;g4_idx=5;over=0; end
					593:begin g0_idx=4;g1_idx=2;g2_idx=3;g3_idx=6;g4_idx=5;over=0; end
					594:begin g0_idx=2;g1_idx=3;g2_idx=6;g3_idx=4;g4_idx=5;over=0; end
					595:begin g0_idx=3;g1_idx=2;g2_idx=6;g3_idx=4;g4_idx=5;over=0; end
					596:begin g0_idx=2;g1_idx=6;g2_idx=3;g3_idx=4;g4_idx=5;over=0; end
					597:begin g0_idx=6;g1_idx=2;g2_idx=3;g3_idx=4;g4_idx=5;over=0; end
					598:begin g0_idx=3;g1_idx=4;g2_idx=6;g3_idx=2;g4_idx=5;over=0; end
					599:begin g0_idx=4;g1_idx=3;g2_idx=6;g3_idx=2;g4_idx=5;over=0; end
					600:begin g0_idx=3;g1_idx=6;g2_idx=4;g3_idx=2;g4_idx=5;over=0; end
					601:begin g0_idx=6;g1_idx=3;g2_idx=4;g3_idx=2;g4_idx=5;over=0; end
					602:begin g0_idx=4;g1_idx=6;g2_idx=3;g3_idx=2;g4_idx=5;over=0; end
					603:begin g0_idx=6;g1_idx=4;g2_idx=3;g3_idx=2;g4_idx=5;over=0; end
					604:begin g0_idx=2;g1_idx=4;g2_idx=5;g3_idx=6;g4_idx=3;over=0; end
					605:begin g0_idx=4;g1_idx=2;g2_idx=5;g3_idx=6;g4_idx=3;over=0; end
					606:begin g0_idx=2;g1_idx=5;g2_idx=4;g3_idx=6;g4_idx=3;over=0; end
					607:begin g0_idx=5;g1_idx=2;g2_idx=4;g3_idx=6;g4_idx=3;over=0; end
					608:begin g0_idx=2;g1_idx=4;g2_idx=6;g3_idx=5;g4_idx=3;over=0; end
					609:begin g0_idx=4;g1_idx=2;g2_idx=6;g3_idx=5;g4_idx=3;over=0; end
					610:begin g0_idx=2;g1_idx=6;g2_idx=4;g3_idx=5;g4_idx=3;over=0; end
					611:begin g0_idx=6;g1_idx=2;g2_idx=4;g3_idx=5;g4_idx=3;over=0; end
					612:begin g0_idx=2;g1_idx=5;g2_idx=6;g3_idx=4;g4_idx=3;over=0; end
					613:begin g0_idx=5;g1_idx=2;g2_idx=6;g3_idx=4;g4_idx=3;over=0; end
					614:begin g0_idx=2;g1_idx=6;g2_idx=5;g3_idx=4;g4_idx=3;over=0; end
					615:begin g0_idx=6;g1_idx=2;g2_idx=5;g3_idx=4;g4_idx=3;over=0; end
					616:begin g0_idx=4;g1_idx=5;g2_idx=6;g3_idx=2;g4_idx=3;over=0; end
					617:begin g0_idx=5;g1_idx=4;g2_idx=6;g3_idx=2;g4_idx=3;over=0; end
					618:begin g0_idx=4;g1_idx=6;g2_idx=5;g3_idx=2;g4_idx=3;over=0; end
					619:begin g0_idx=6;g1_idx=4;g2_idx=5;g3_idx=2;g4_idx=3;over=0; end
					620:begin g0_idx=5;g1_idx=6;g2_idx=4;g3_idx=2;g4_idx=3;over=0; end
					621:begin g0_idx=6;g1_idx=5;g2_idx=4;g3_idx=2;g4_idx=3;over=0; end
					622:begin g0_idx=3;g1_idx=4;g2_idx=5;g3_idx=6;g4_idx=2;over=0; end
					623:begin g0_idx=4;g1_idx=3;g2_idx=5;g3_idx=6;g4_idx=2;over=0; end
					624:begin g0_idx=3;g1_idx=5;g2_idx=4;g3_idx=6;g4_idx=2;over=0; end
					625:begin g0_idx=5;g1_idx=3;g2_idx=4;g3_idx=6;g4_idx=2;over=0; end
					626:begin g0_idx=4;g1_idx=5;g2_idx=3;g3_idx=6;g4_idx=2;over=0; end
					627:begin g0_idx=5;g1_idx=4;g2_idx=3;g3_idx=6;g4_idx=2;over=0; end
					628:begin g0_idx=3;g1_idx=4;g2_idx=6;g3_idx=5;g4_idx=2;over=0; end
					629:begin g0_idx=4;g1_idx=3;g2_idx=6;g3_idx=5;g4_idx=2;over=0; end
					630:begin g0_idx=3;g1_idx=6;g2_idx=4;g3_idx=5;g4_idx=2;over=0; end
					631:begin g0_idx=6;g1_idx=3;g2_idx=4;g3_idx=5;g4_idx=2;over=0; end
					632:begin g0_idx=4;g1_idx=6;g2_idx=3;g3_idx=5;g4_idx=2;over=0; end
					633:begin g0_idx=6;g1_idx=4;g2_idx=3;g3_idx=5;g4_idx=2;over=0; end
					634:begin g0_idx=3;g1_idx=5;g2_idx=6;g3_idx=4;g4_idx=2;over=0; end
					635:begin g0_idx=5;g1_idx=3;g2_idx=6;g3_idx=4;g4_idx=2;over=0; end
					636:begin g0_idx=3;g1_idx=6;g2_idx=5;g3_idx=4;g4_idx=2;over=0; end
					637:begin g0_idx=6;g1_idx=3;g2_idx=5;g3_idx=4;g4_idx=2;over=0; end
					638:begin g0_idx=5;g1_idx=6;g2_idx=3;g3_idx=4;g4_idx=2;over=0; end
					639:begin g0_idx=6;g1_idx=5;g2_idx=3;g3_idx=4;g4_idx=2;over=0; end
				default :begin
					g0_idx=3'bx;    g1_idx=3'bx;    g2_idx=3'bx;    g3_idx=3'bx;    g4_idx=3'bx; over=1;
				end	
			endcase
		6'o04:
			case(inspect_vector)
				0:begin g0_idx=1;g1_idx=0;g2_idx=3;g3_idx=2;g4_idx=5;over=0; end
				1:begin g0_idx=3;g1_idx=0;g2_idx=1;g3_idx=2;g4_idx=5;over=0; end
				2:begin g0_idx=1;g1_idx=3;g2_idx=0;g3_idx=2;g4_idx=5;over=0; end
				3:begin g0_idx=2;g1_idx=0;g2_idx=3;g3_idx=1;g4_idx=5;over=0; end
				4:begin g0_idx=2;g1_idx=3;g2_idx=0;g3_idx=1;g4_idx=5;over=0; end
				5:begin g0_idx=3;g1_idx=2;g2_idx=0;g3_idx=1;g4_idx=5;over=0; end
				6:begin g0_idx=1;g1_idx=2;g2_idx=3;g3_idx=0;g4_idx=5;over=0; end
				7:begin g0_idx=2;g1_idx=3;g2_idx=1;g3_idx=0;g4_idx=5;over=0; end
				8:begin g0_idx=3;g1_idx=2;g2_idx=1;g3_idx=0;g4_idx=5;over=0; end
				9:begin g0_idx=2;g1_idx=0;g2_idx=1;g3_idx=5;g4_idx=3;over=0; end
				10:begin g0_idx=1;g1_idx=2;g2_idx=0;g3_idx=5;g4_idx=3;over=0; end
				11:begin g0_idx=1;g1_idx=0;g2_idx=5;g3_idx=2;g4_idx=3;over=0; end
				12:begin g0_idx=5;g1_idx=0;g2_idx=1;g3_idx=2;g4_idx=3;over=0; end
				13:begin g0_idx=1;g1_idx=5;g2_idx=0;g3_idx=2;g4_idx=3;over=0; end
				14:begin g0_idx=2;g1_idx=0;g2_idx=5;g3_idx=1;g4_idx=3;over=0; end
				15:begin g0_idx=2;g1_idx=5;g2_idx=0;g3_idx=1;g4_idx=3;over=0; end
				16:begin g0_idx=5;g1_idx=2;g2_idx=0;g3_idx=1;g4_idx=3;over=0; end
				17:begin g0_idx=1;g1_idx=2;g2_idx=5;g3_idx=0;g4_idx=3;over=0; end
				18:begin g0_idx=2;g1_idx=5;g2_idx=1;g3_idx=0;g4_idx=3;over=0; end
				19:begin g0_idx=5;g1_idx=2;g2_idx=1;g3_idx=0;g4_idx=3;over=0; end
				20:begin g0_idx=1;g1_idx=0;g2_idx=3;g3_idx=5;g4_idx=2;over=0; end
				21:begin g0_idx=3;g1_idx=0;g2_idx=1;g3_idx=5;g4_idx=2;over=0; end
				22:begin g0_idx=1;g1_idx=3;g2_idx=0;g3_idx=5;g4_idx=2;over=0; end
				23:begin g0_idx=3;g1_idx=0;g2_idx=5;g3_idx=1;g4_idx=2;over=0; end
				24:begin g0_idx=5;g1_idx=0;g2_idx=3;g3_idx=1;g4_idx=2;over=0; end
				25:begin g0_idx=3;g1_idx=5;g2_idx=0;g3_idx=1;g4_idx=2;over=0; end
				26:begin g0_idx=5;g1_idx=3;g2_idx=0;g3_idx=1;g4_idx=2;over=0; end
				27:begin g0_idx=1;g1_idx=3;g2_idx=5;g3_idx=0;g4_idx=2;over=0; end
				28:begin g0_idx=1;g1_idx=5;g2_idx=3;g3_idx=0;g4_idx=2;over=0; end
				29:begin g0_idx=3;g1_idx=5;g2_idx=1;g3_idx=0;g4_idx=2;over=0; end
				30:begin g0_idx=5;g1_idx=3;g2_idx=1;g3_idx=0;g4_idx=2;over=0; end
				31:begin g0_idx=2;g1_idx=0;g2_idx=3;g3_idx=5;g4_idx=1;over=0; end
				32:begin g0_idx=2;g1_idx=3;g2_idx=0;g3_idx=5;g4_idx=1;over=0; end
				33:begin g0_idx=3;g1_idx=2;g2_idx=0;g3_idx=5;g4_idx=1;over=0; end
				34:begin g0_idx=3;g1_idx=0;g2_idx=5;g3_idx=2;g4_idx=1;over=0; end
				35:begin g0_idx=5;g1_idx=0;g2_idx=3;g3_idx=2;g4_idx=1;over=0; end
				36:begin g0_idx=3;g1_idx=5;g2_idx=0;g3_idx=2;g4_idx=1;over=0; end
				37:begin g0_idx=5;g1_idx=3;g2_idx=0;g3_idx=2;g4_idx=1;over=0; end
				38:begin g0_idx=2;g1_idx=3;g2_idx=5;g3_idx=0;g4_idx=1;over=0; end
				39:begin g0_idx=3;g1_idx=2;g2_idx=5;g3_idx=0;g4_idx=1;over=0; end
				40:begin g0_idx=2;g1_idx=5;g2_idx=3;g3_idx=0;g4_idx=1;over=0; end
				41:begin g0_idx=5;g1_idx=2;g2_idx=3;g3_idx=0;g4_idx=1;over=0; end
				42:begin g0_idx=1;g1_idx=2;g2_idx=3;g3_idx=5;g4_idx=0;over=0; end
				43:begin g0_idx=2;g1_idx=3;g2_idx=1;g3_idx=5;g4_idx=0;over=0; end
				44:begin g0_idx=3;g1_idx=2;g2_idx=1;g3_idx=5;g4_idx=0;over=0; end
				45:begin g0_idx=1;g1_idx=3;g2_idx=5;g3_idx=2;g4_idx=0;over=0; end
				46:begin g0_idx=1;g1_idx=5;g2_idx=3;g3_idx=2;g4_idx=0;over=0; end
				47:begin g0_idx=3;g1_idx=5;g2_idx=1;g3_idx=2;g4_idx=0;over=0; end
				48:begin g0_idx=5;g1_idx=3;g2_idx=1;g3_idx=2;g4_idx=0;over=0; end
				49:begin g0_idx=2;g1_idx=3;g2_idx=5;g3_idx=1;g4_idx=0;over=0; end
				50:begin g0_idx=3;g1_idx=2;g2_idx=5;g3_idx=1;g4_idx=0;over=0; end
				51:begin g0_idx=2;g1_idx=5;g2_idx=3;g3_idx=1;g4_idx=0;over=0; end
				52:begin g0_idx=5;g1_idx=2;g2_idx=3;g3_idx=1;g4_idx=0;over=0; end
				53:begin g0_idx=2;g1_idx=0;g2_idx=1;g3_idx=4;g4_idx=5;over=0; end
				54:begin g0_idx=1;g1_idx=2;g2_idx=0;g3_idx=4;g4_idx=5;over=0; end
				55:begin g0_idx=1;g1_idx=0;g2_idx=4;g3_idx=2;g4_idx=5;over=0; end
				56:begin g0_idx=4;g1_idx=0;g2_idx=1;g3_idx=2;g4_idx=5;over=0; end
				57:begin g0_idx=1;g1_idx=4;g2_idx=0;g3_idx=2;g4_idx=5;over=0; end
				58:begin g0_idx=2;g1_idx=0;g2_idx=4;g3_idx=1;g4_idx=5;over=0; end
				59:begin g0_idx=2;g1_idx=4;g2_idx=0;g3_idx=1;g4_idx=5;over=0; end
				60:begin g0_idx=4;g1_idx=2;g2_idx=0;g3_idx=1;g4_idx=5;over=0; end
				61:begin g0_idx=1;g1_idx=2;g2_idx=4;g3_idx=0;g4_idx=5;over=0; end
				62:begin g0_idx=2;g1_idx=4;g2_idx=1;g3_idx=0;g4_idx=5;over=0; end
				63:begin g0_idx=4;g1_idx=2;g2_idx=1;g3_idx=0;g4_idx=5;over=0; end
				64:begin g0_idx=1;g1_idx=0;g2_idx=4;g3_idx=5;g4_idx=2;over=0; end
				65:begin g0_idx=4;g1_idx=0;g2_idx=1;g3_idx=5;g4_idx=2;over=0; end
				66:begin g0_idx=1;g1_idx=4;g2_idx=0;g3_idx=5;g4_idx=2;over=0; end
				67:begin g0_idx=1;g1_idx=0;g2_idx=5;g3_idx=4;g4_idx=2;over=0; end
				68:begin g0_idx=5;g1_idx=0;g2_idx=1;g3_idx=4;g4_idx=2;over=0; end
				69:begin g0_idx=1;g1_idx=5;g2_idx=0;g3_idx=4;g4_idx=2;over=0; end
				70:begin g0_idx=4;g1_idx=0;g2_idx=5;g3_idx=1;g4_idx=2;over=0; end
				71:begin g0_idx=5;g1_idx=0;g2_idx=4;g3_idx=1;g4_idx=2;over=0; end
				72:begin g0_idx=4;g1_idx=5;g2_idx=0;g3_idx=1;g4_idx=2;over=0; end
				73:begin g0_idx=5;g1_idx=4;g2_idx=0;g3_idx=1;g4_idx=2;over=0; end
				74:begin g0_idx=1;g1_idx=4;g2_idx=5;g3_idx=0;g4_idx=2;over=0; end
				75:begin g0_idx=1;g1_idx=5;g2_idx=4;g3_idx=0;g4_idx=2;over=0; end
				76:begin g0_idx=4;g1_idx=5;g2_idx=1;g3_idx=0;g4_idx=2;over=0; end
				77:begin g0_idx=5;g1_idx=4;g2_idx=1;g3_idx=0;g4_idx=2;over=0; end
				78:begin g0_idx=2;g1_idx=0;g2_idx=4;g3_idx=5;g4_idx=1;over=0; end
				79:begin g0_idx=2;g1_idx=4;g2_idx=0;g3_idx=5;g4_idx=1;over=0; end
				80:begin g0_idx=4;g1_idx=2;g2_idx=0;g3_idx=5;g4_idx=1;over=0; end
				81:begin g0_idx=2;g1_idx=0;g2_idx=5;g3_idx=4;g4_idx=1;over=0; end
				82:begin g0_idx=2;g1_idx=5;g2_idx=0;g3_idx=4;g4_idx=1;over=0; end
				83:begin g0_idx=5;g1_idx=2;g2_idx=0;g3_idx=4;g4_idx=1;over=0; end
				84:begin g0_idx=4;g1_idx=0;g2_idx=5;g3_idx=2;g4_idx=1;over=0; end
				85:begin g0_idx=5;g1_idx=0;g2_idx=4;g3_idx=2;g4_idx=1;over=0; end
				86:begin g0_idx=4;g1_idx=5;g2_idx=0;g3_idx=2;g4_idx=1;over=0; end
				87:begin g0_idx=5;g1_idx=4;g2_idx=0;g3_idx=2;g4_idx=1;over=0; end
				88:begin g0_idx=2;g1_idx=4;g2_idx=5;g3_idx=0;g4_idx=1;over=0; end
				89:begin g0_idx=4;g1_idx=2;g2_idx=5;g3_idx=0;g4_idx=1;over=0; end
				90:begin g0_idx=2;g1_idx=5;g2_idx=4;g3_idx=0;g4_idx=1;over=0; end
				91:begin g0_idx=5;g1_idx=2;g2_idx=4;g3_idx=0;g4_idx=1;over=0; end
				92:begin g0_idx=1;g1_idx=2;g2_idx=4;g3_idx=5;g4_idx=0;over=0; end
				93:begin g0_idx=2;g1_idx=4;g2_idx=1;g3_idx=5;g4_idx=0;over=0; end
				94:begin g0_idx=4;g1_idx=2;g2_idx=1;g3_idx=5;g4_idx=0;over=0; end
				95:begin g0_idx=1;g1_idx=2;g2_idx=5;g3_idx=4;g4_idx=0;over=0; end
				96:begin g0_idx=2;g1_idx=5;g2_idx=1;g3_idx=4;g4_idx=0;over=0; end
				97:begin g0_idx=5;g1_idx=2;g2_idx=1;g3_idx=4;g4_idx=0;over=0; end
				98:begin g0_idx=1;g1_idx=4;g2_idx=5;g3_idx=2;g4_idx=0;over=0; end
				99:begin g0_idx=1;g1_idx=5;g2_idx=4;g3_idx=2;g4_idx=0;over=0; end
				100:begin g0_idx=4;g1_idx=5;g2_idx=1;g3_idx=2;g4_idx=0;over=0; end
				101:begin g0_idx=5;g1_idx=4;g2_idx=1;g3_idx=2;g4_idx=0;over=0; end
				102:begin g0_idx=2;g1_idx=4;g2_idx=5;g3_idx=1;g4_idx=0;over=0; end
				103:begin g0_idx=4;g1_idx=2;g2_idx=5;g3_idx=1;g4_idx=0;over=0; end
				104:begin g0_idx=2;g1_idx=5;g2_idx=4;g3_idx=1;g4_idx=0;over=0; end
				105:begin g0_idx=5;g1_idx=2;g2_idx=4;g3_idx=1;g4_idx=0;over=0; end
				106:begin g0_idx=1;g1_idx=0;g2_idx=3;g3_idx=4;g4_idx=5;over=0; end
				107:begin g0_idx=3;g1_idx=0;g2_idx=1;g3_idx=4;g4_idx=5;over=0; end
				108:begin g0_idx=1;g1_idx=3;g2_idx=0;g3_idx=4;g4_idx=5;over=0; end
				109:begin g0_idx=3;g1_idx=0;g2_idx=4;g3_idx=1;g4_idx=5;over=0; end
				110:begin g0_idx=4;g1_idx=0;g2_idx=3;g3_idx=1;g4_idx=5;over=0; end
				111:begin g0_idx=3;g1_idx=4;g2_idx=0;g3_idx=1;g4_idx=5;over=0; end
				112:begin g0_idx=4;g1_idx=3;g2_idx=0;g3_idx=1;g4_idx=5;over=0; end
				113:begin g0_idx=1;g1_idx=3;g2_idx=4;g3_idx=0;g4_idx=5;over=0; end
				114:begin g0_idx=1;g1_idx=4;g2_idx=3;g3_idx=0;g4_idx=5;over=0; end
				115:begin g0_idx=3;g1_idx=4;g2_idx=1;g3_idx=0;g4_idx=5;over=0; end
				116:begin g0_idx=4;g1_idx=3;g2_idx=1;g3_idx=0;g4_idx=5;over=0; end
				117:begin g0_idx=1;g1_idx=0;g2_idx=4;g3_idx=5;g4_idx=3;over=0; end
				118:begin g0_idx=4;g1_idx=0;g2_idx=1;g3_idx=5;g4_idx=3;over=0; end
				119:begin g0_idx=1;g1_idx=4;g2_idx=0;g3_idx=5;g4_idx=3;over=0; end
				120:begin g0_idx=1;g1_idx=0;g2_idx=5;g3_idx=4;g4_idx=3;over=0; end
				121:begin g0_idx=5;g1_idx=0;g2_idx=1;g3_idx=4;g4_idx=3;over=0; end
				122:begin g0_idx=1;g1_idx=5;g2_idx=0;g3_idx=4;g4_idx=3;over=0; end
				123:begin g0_idx=4;g1_idx=0;g2_idx=5;g3_idx=1;g4_idx=3;over=0; end
				124:begin g0_idx=5;g1_idx=0;g2_idx=4;g3_idx=1;g4_idx=3;over=0; end
				125:begin g0_idx=4;g1_idx=5;g2_idx=0;g3_idx=1;g4_idx=3;over=0; end
				126:begin g0_idx=5;g1_idx=4;g2_idx=0;g3_idx=1;g4_idx=3;over=0; end
				127:begin g0_idx=1;g1_idx=4;g2_idx=5;g3_idx=0;g4_idx=3;over=0; end
				128:begin g0_idx=1;g1_idx=5;g2_idx=4;g3_idx=0;g4_idx=3;over=0; end
				129:begin g0_idx=4;g1_idx=5;g2_idx=1;g3_idx=0;g4_idx=3;over=0; end
				130:begin g0_idx=5;g1_idx=4;g2_idx=1;g3_idx=0;g4_idx=3;over=0; end
				131:begin g0_idx=3;g1_idx=0;g2_idx=4;g3_idx=5;g4_idx=1;over=0; end
				132:begin g0_idx=4;g1_idx=0;g2_idx=3;g3_idx=5;g4_idx=1;over=0; end
				133:begin g0_idx=3;g1_idx=4;g2_idx=0;g3_idx=5;g4_idx=1;over=0; end
				134:begin g0_idx=4;g1_idx=3;g2_idx=0;g3_idx=5;g4_idx=1;over=0; end
				135:begin g0_idx=3;g1_idx=0;g2_idx=5;g3_idx=4;g4_idx=1;over=0; end
				136:begin g0_idx=5;g1_idx=0;g2_idx=3;g3_idx=4;g4_idx=1;over=0; end
				137:begin g0_idx=3;g1_idx=5;g2_idx=0;g3_idx=4;g4_idx=1;over=0; end
				138:begin g0_idx=5;g1_idx=3;g2_idx=0;g3_idx=4;g4_idx=1;over=0; end
				139:begin g0_idx=3;g1_idx=4;g2_idx=5;g3_idx=0;g4_idx=1;over=0; end
				140:begin g0_idx=4;g1_idx=3;g2_idx=5;g3_idx=0;g4_idx=1;over=0; end
				141:begin g0_idx=3;g1_idx=5;g2_idx=4;g3_idx=0;g4_idx=1;over=0; end
				142:begin g0_idx=5;g1_idx=3;g2_idx=4;g3_idx=0;g4_idx=1;over=0; end
				143:begin g0_idx=4;g1_idx=5;g2_idx=3;g3_idx=0;g4_idx=1;over=0; end
				144:begin g0_idx=5;g1_idx=4;g2_idx=3;g3_idx=0;g4_idx=1;over=0; end
				145:begin g0_idx=1;g1_idx=3;g2_idx=4;g3_idx=5;g4_idx=0;over=0; end
				146:begin g0_idx=1;g1_idx=4;g2_idx=3;g3_idx=5;g4_idx=0;over=0; end
				147:begin g0_idx=3;g1_idx=4;g2_idx=1;g3_idx=5;g4_idx=0;over=0; end
				148:begin g0_idx=4;g1_idx=3;g2_idx=1;g3_idx=5;g4_idx=0;over=0; end
				149:begin g0_idx=1;g1_idx=3;g2_idx=5;g3_idx=4;g4_idx=0;over=0; end
				150:begin g0_idx=1;g1_idx=5;g2_idx=3;g3_idx=4;g4_idx=0;over=0; end
				151:begin g0_idx=3;g1_idx=5;g2_idx=1;g3_idx=4;g4_idx=0;over=0; end
				152:begin g0_idx=5;g1_idx=3;g2_idx=1;g3_idx=4;g4_idx=0;over=0; end
				153:begin g0_idx=3;g1_idx=4;g2_idx=5;g3_idx=1;g4_idx=0;over=0; end
				154:begin g0_idx=4;g1_idx=3;g2_idx=5;g3_idx=1;g4_idx=0;over=0; end
				155:begin g0_idx=3;g1_idx=5;g2_idx=4;g3_idx=1;g4_idx=0;over=0; end
				156:begin g0_idx=5;g1_idx=3;g2_idx=4;g3_idx=1;g4_idx=0;over=0; end
				157:begin g0_idx=4;g1_idx=5;g2_idx=3;g3_idx=1;g4_idx=0;over=0; end
				158:begin g0_idx=5;g1_idx=4;g2_idx=3;g3_idx=1;g4_idx=0;over=0; end
				159:begin g0_idx=2;g1_idx=0;g2_idx=3;g3_idx=4;g4_idx=5;over=0; end
				160:begin g0_idx=2;g1_idx=3;g2_idx=0;g3_idx=4;g4_idx=5;over=0; end
				161:begin g0_idx=3;g1_idx=2;g2_idx=0;g3_idx=4;g4_idx=5;over=0; end
				162:begin g0_idx=3;g1_idx=0;g2_idx=4;g3_idx=2;g4_idx=5;over=0; end
				163:begin g0_idx=4;g1_idx=0;g2_idx=3;g3_idx=2;g4_idx=5;over=0; end
				164:begin g0_idx=3;g1_idx=4;g2_idx=0;g3_idx=2;g4_idx=5;over=0; end
				165:begin g0_idx=4;g1_idx=3;g2_idx=0;g3_idx=2;g4_idx=5;over=0; end
				166:begin g0_idx=2;g1_idx=3;g2_idx=4;g3_idx=0;g4_idx=5;over=0; end
				167:begin g0_idx=3;g1_idx=2;g2_idx=4;g3_idx=0;g4_idx=5;over=0; end
				168:begin g0_idx=2;g1_idx=4;g2_idx=3;g3_idx=0;g4_idx=5;over=0; end
				169:begin g0_idx=4;g1_idx=2;g2_idx=3;g3_idx=0;g4_idx=5;over=0; end
				170:begin g0_idx=2;g1_idx=0;g2_idx=4;g3_idx=5;g4_idx=3;over=0; end
				171:begin g0_idx=2;g1_idx=4;g2_idx=0;g3_idx=5;g4_idx=3;over=0; end
				172:begin g0_idx=4;g1_idx=2;g2_idx=0;g3_idx=5;g4_idx=3;over=0; end
				173:begin g0_idx=2;g1_idx=0;g2_idx=5;g3_idx=4;g4_idx=3;over=0; end
				174:begin g0_idx=2;g1_idx=5;g2_idx=0;g3_idx=4;g4_idx=3;over=0; end
				175:begin g0_idx=5;g1_idx=2;g2_idx=0;g3_idx=4;g4_idx=3;over=0; end
				176:begin g0_idx=4;g1_idx=0;g2_idx=5;g3_idx=2;g4_idx=3;over=0; end
				177:begin g0_idx=5;g1_idx=0;g2_idx=4;g3_idx=2;g4_idx=3;over=0; end
				178:begin g0_idx=4;g1_idx=5;g2_idx=0;g3_idx=2;g4_idx=3;over=0; end
				179:begin g0_idx=5;g1_idx=4;g2_idx=0;g3_idx=2;g4_idx=3;over=0; end
				180:begin g0_idx=2;g1_idx=4;g2_idx=5;g3_idx=0;g4_idx=3;over=0; end
				181:begin g0_idx=4;g1_idx=2;g2_idx=5;g3_idx=0;g4_idx=3;over=0; end
				182:begin g0_idx=2;g1_idx=5;g2_idx=4;g3_idx=0;g4_idx=3;over=0; end
				183:begin g0_idx=5;g1_idx=2;g2_idx=4;g3_idx=0;g4_idx=3;over=0; end
				184:begin g0_idx=3;g1_idx=0;g2_idx=4;g3_idx=5;g4_idx=2;over=0; end
				185:begin g0_idx=4;g1_idx=0;g2_idx=3;g3_idx=5;g4_idx=2;over=0; end
				186:begin g0_idx=3;g1_idx=4;g2_idx=0;g3_idx=5;g4_idx=2;over=0; end
				187:begin g0_idx=4;g1_idx=3;g2_idx=0;g3_idx=5;g4_idx=2;over=0; end
				188:begin g0_idx=3;g1_idx=0;g2_idx=5;g3_idx=4;g4_idx=2;over=0; end
				189:begin g0_idx=5;g1_idx=0;g2_idx=3;g3_idx=4;g4_idx=2;over=0; end
				190:begin g0_idx=3;g1_idx=5;g2_idx=0;g3_idx=4;g4_idx=2;over=0; end
				191:begin g0_idx=5;g1_idx=3;g2_idx=0;g3_idx=4;g4_idx=2;over=0; end
				192:begin g0_idx=3;g1_idx=4;g2_idx=5;g3_idx=0;g4_idx=2;over=0; end
				193:begin g0_idx=4;g1_idx=3;g2_idx=5;g3_idx=0;g4_idx=2;over=0; end
				194:begin g0_idx=3;g1_idx=5;g2_idx=4;g3_idx=0;g4_idx=2;over=0; end
				195:begin g0_idx=5;g1_idx=3;g2_idx=4;g3_idx=0;g4_idx=2;over=0; end
				196:begin g0_idx=4;g1_idx=5;g2_idx=3;g3_idx=0;g4_idx=2;over=0; end
				197:begin g0_idx=5;g1_idx=4;g2_idx=3;g3_idx=0;g4_idx=2;over=0; end
				198:begin g0_idx=2;g1_idx=3;g2_idx=4;g3_idx=5;g4_idx=0;over=0; end
				199:begin g0_idx=3;g1_idx=2;g2_idx=4;g3_idx=5;g4_idx=0;over=0; end
				200:begin g0_idx=2;g1_idx=4;g2_idx=3;g3_idx=5;g4_idx=0;over=0; end
				201:begin g0_idx=4;g1_idx=2;g2_idx=3;g3_idx=5;g4_idx=0;over=0; end
				202:begin g0_idx=2;g1_idx=3;g2_idx=5;g3_idx=4;g4_idx=0;over=0; end
				203:begin g0_idx=3;g1_idx=2;g2_idx=5;g3_idx=4;g4_idx=0;over=0; end
				204:begin g0_idx=2;g1_idx=5;g2_idx=3;g3_idx=4;g4_idx=0;over=0; end
				205:begin g0_idx=5;g1_idx=2;g2_idx=3;g3_idx=4;g4_idx=0;over=0; end
				206:begin g0_idx=3;g1_idx=4;g2_idx=5;g3_idx=2;g4_idx=0;over=0; end
				207:begin g0_idx=4;g1_idx=3;g2_idx=5;g3_idx=2;g4_idx=0;over=0; end
				208:begin g0_idx=3;g1_idx=5;g2_idx=4;g3_idx=2;g4_idx=0;over=0; end
				209:begin g0_idx=5;g1_idx=3;g2_idx=4;g3_idx=2;g4_idx=0;over=0; end
				210:begin g0_idx=4;g1_idx=5;g2_idx=3;g3_idx=2;g4_idx=0;over=0; end
				211:begin g0_idx=5;g1_idx=4;g2_idx=3;g3_idx=2;g4_idx=0;over=0; end
				212:begin g0_idx=1;g1_idx=2;g2_idx=3;g3_idx=4;g4_idx=5;over=0; end
				213:begin g0_idx=2;g1_idx=3;g2_idx=1;g3_idx=4;g4_idx=5;over=0; end
				214:begin g0_idx=3;g1_idx=2;g2_idx=1;g3_idx=4;g4_idx=5;over=0; end
				215:begin g0_idx=1;g1_idx=3;g2_idx=4;g3_idx=2;g4_idx=5;over=0; end
				216:begin g0_idx=1;g1_idx=4;g2_idx=3;g3_idx=2;g4_idx=5;over=0; end
				217:begin g0_idx=3;g1_idx=4;g2_idx=1;g3_idx=2;g4_idx=5;over=0; end
				218:begin g0_idx=4;g1_idx=3;g2_idx=1;g3_idx=2;g4_idx=5;over=0; end
				219:begin g0_idx=2;g1_idx=3;g2_idx=4;g3_idx=1;g4_idx=5;over=0; end
				220:begin g0_idx=3;g1_idx=2;g2_idx=4;g3_idx=1;g4_idx=5;over=0; end
				221:begin g0_idx=2;g1_idx=4;g2_idx=3;g3_idx=1;g4_idx=5;over=0; end
				222:begin g0_idx=4;g1_idx=2;g2_idx=3;g3_idx=1;g4_idx=5;over=0; end
				223:begin g0_idx=1;g1_idx=2;g2_idx=4;g3_idx=5;g4_idx=3;over=0; end
				224:begin g0_idx=2;g1_idx=4;g2_idx=1;g3_idx=5;g4_idx=3;over=0; end
				225:begin g0_idx=4;g1_idx=2;g2_idx=1;g3_idx=5;g4_idx=3;over=0; end
				226:begin g0_idx=1;g1_idx=2;g2_idx=5;g3_idx=4;g4_idx=3;over=0; end
				227:begin g0_idx=2;g1_idx=5;g2_idx=1;g3_idx=4;g4_idx=3;over=0; end
				228:begin g0_idx=5;g1_idx=2;g2_idx=1;g3_idx=4;g4_idx=3;over=0; end
				229:begin g0_idx=1;g1_idx=4;g2_idx=5;g3_idx=2;g4_idx=3;over=0; end
				230:begin g0_idx=1;g1_idx=5;g2_idx=4;g3_idx=2;g4_idx=3;over=0; end
				231:begin g0_idx=4;g1_idx=5;g2_idx=1;g3_idx=2;g4_idx=3;over=0; end
				232:begin g0_idx=5;g1_idx=4;g2_idx=1;g3_idx=2;g4_idx=3;over=0; end
				233:begin g0_idx=2;g1_idx=4;g2_idx=5;g3_idx=1;g4_idx=3;over=0; end
				234:begin g0_idx=4;g1_idx=2;g2_idx=5;g3_idx=1;g4_idx=3;over=0; end
				235:begin g0_idx=2;g1_idx=5;g2_idx=4;g3_idx=1;g4_idx=3;over=0; end
				236:begin g0_idx=5;g1_idx=2;g2_idx=4;g3_idx=1;g4_idx=3;over=0; end
				237:begin g0_idx=1;g1_idx=3;g2_idx=4;g3_idx=5;g4_idx=2;over=0; end
				238:begin g0_idx=1;g1_idx=4;g2_idx=3;g3_idx=5;g4_idx=2;over=0; end
				239:begin g0_idx=3;g1_idx=4;g2_idx=1;g3_idx=5;g4_idx=2;over=0; end
				240:begin g0_idx=4;g1_idx=3;g2_idx=1;g3_idx=5;g4_idx=2;over=0; end
				241:begin g0_idx=1;g1_idx=3;g2_idx=5;g3_idx=4;g4_idx=2;over=0; end
				242:begin g0_idx=1;g1_idx=5;g2_idx=3;g3_idx=4;g4_idx=2;over=0; end
				243:begin g0_idx=3;g1_idx=5;g2_idx=1;g3_idx=4;g4_idx=2;over=0; end
				244:begin g0_idx=5;g1_idx=3;g2_idx=1;g3_idx=4;g4_idx=2;over=0; end
				245:begin g0_idx=3;g1_idx=4;g2_idx=5;g3_idx=1;g4_idx=2;over=0; end
				246:begin g0_idx=4;g1_idx=3;g2_idx=5;g3_idx=1;g4_idx=2;over=0; end
				247:begin g0_idx=3;g1_idx=5;g2_idx=4;g3_idx=1;g4_idx=2;over=0; end
				248:begin g0_idx=5;g1_idx=3;g2_idx=4;g3_idx=1;g4_idx=2;over=0; end
				249:begin g0_idx=4;g1_idx=5;g2_idx=3;g3_idx=1;g4_idx=2;over=0; end
				250:begin g0_idx=5;g1_idx=4;g2_idx=3;g3_idx=1;g4_idx=2;over=0; end
				251:begin g0_idx=2;g1_idx=3;g2_idx=4;g3_idx=5;g4_idx=1;over=0; end
				252:begin g0_idx=3;g1_idx=2;g2_idx=4;g3_idx=5;g4_idx=1;over=0; end
				253:begin g0_idx=2;g1_idx=4;g2_idx=3;g3_idx=5;g4_idx=1;over=0; end
				254:begin g0_idx=4;g1_idx=2;g2_idx=3;g3_idx=5;g4_idx=1;over=0; end
				255:begin g0_idx=2;g1_idx=3;g2_idx=5;g3_idx=4;g4_idx=1;over=0; end
				256:begin g0_idx=3;g1_idx=2;g2_idx=5;g3_idx=4;g4_idx=1;over=0; end
				257:begin g0_idx=2;g1_idx=5;g2_idx=3;g3_idx=4;g4_idx=1;over=0; end
				258:begin g0_idx=5;g1_idx=2;g2_idx=3;g3_idx=4;g4_idx=1;over=0; end
				259:begin g0_idx=3;g1_idx=4;g2_idx=5;g3_idx=2;g4_idx=1;over=0; end
				260:begin g0_idx=4;g1_idx=3;g2_idx=5;g3_idx=2;g4_idx=1;over=0; end
				261:begin g0_idx=3;g1_idx=5;g2_idx=4;g3_idx=2;g4_idx=1;over=0; end
				262:begin g0_idx=5;g1_idx=3;g2_idx=4;g3_idx=2;g4_idx=1;over=0; end
				263:begin g0_idx=4;g1_idx=5;g2_idx=3;g3_idx=2;g4_idx=1;over=0; end
				264:begin g0_idx=5;g1_idx=4;g2_idx=3;g3_idx=2;g4_idx=1;over=0; end
			
				default :begin
					g0_idx=3'bx;    g1_idx=3'bx;    g2_idx=3'bx;    g3_idx=3'bx;    g4_idx=3'bx; over=1;
				end	
			endcase
		6'o05:
			case(inspect_vector)
				0:begin g0_idx=2;g1_idx=0;g2_idx=1;g3_idx=4;g4_idx=3;over=0; end
				1:begin g0_idx=1;g1_idx=2;g2_idx=0;g3_idx=4;g4_idx=3;over=0; end
				2:begin g0_idx=1;g1_idx=0;g2_idx=4;g3_idx=2;g4_idx=3;over=0; end
				3:begin g0_idx=4;g1_idx=0;g2_idx=1;g3_idx=2;g4_idx=3;over=0; end
				4:begin g0_idx=1;g1_idx=4;g2_idx=0;g3_idx=2;g4_idx=3;over=0; end
				5:begin g0_idx=2;g1_idx=0;g2_idx=4;g3_idx=1;g4_idx=3;over=0; end
				6:begin g0_idx=2;g1_idx=4;g2_idx=0;g3_idx=1;g4_idx=3;over=0; end
				7:begin g0_idx=4;g1_idx=2;g2_idx=0;g3_idx=1;g4_idx=3;over=0; end
				8:begin g0_idx=1;g1_idx=2;g2_idx=4;g3_idx=0;g4_idx=3;over=0; end
				9:begin g0_idx=2;g1_idx=4;g2_idx=1;g3_idx=0;g4_idx=3;over=0; end
				10:begin g0_idx=4;g1_idx=2;g2_idx=1;g3_idx=0;g4_idx=3;over=0; end
				11:begin g0_idx=1;g1_idx=0;g2_idx=3;g3_idx=4;g4_idx=2;over=0; end
				12:begin g0_idx=3;g1_idx=0;g2_idx=1;g3_idx=4;g4_idx=2;over=0; end
				13:begin g0_idx=1;g1_idx=3;g2_idx=0;g3_idx=4;g4_idx=2;over=0; end
				14:begin g0_idx=3;g1_idx=0;g2_idx=4;g3_idx=1;g4_idx=2;over=0; end
				15:begin g0_idx=4;g1_idx=0;g2_idx=3;g3_idx=1;g4_idx=2;over=0; end
				16:begin g0_idx=3;g1_idx=4;g2_idx=0;g3_idx=1;g4_idx=2;over=0; end
				17:begin g0_idx=4;g1_idx=3;g2_idx=0;g3_idx=1;g4_idx=2;over=0; end
				18:begin g0_idx=1;g1_idx=3;g2_idx=4;g3_idx=0;g4_idx=2;over=0; end
				19:begin g0_idx=1;g1_idx=4;g2_idx=3;g3_idx=0;g4_idx=2;over=0; end
				20:begin g0_idx=3;g1_idx=4;g2_idx=1;g3_idx=0;g4_idx=2;over=0; end
				21:begin g0_idx=4;g1_idx=3;g2_idx=1;g3_idx=0;g4_idx=2;over=0; end
				22:begin g0_idx=2;g1_idx=0;g2_idx=3;g3_idx=4;g4_idx=1;over=0; end
				23:begin g0_idx=2;g1_idx=3;g2_idx=0;g3_idx=4;g4_idx=1;over=0; end
				24:begin g0_idx=3;g1_idx=2;g2_idx=0;g3_idx=4;g4_idx=1;over=0; end
				25:begin g0_idx=3;g1_idx=0;g2_idx=4;g3_idx=2;g4_idx=1;over=0; end
				26:begin g0_idx=4;g1_idx=0;g2_idx=3;g3_idx=2;g4_idx=1;over=0; end
				27:begin g0_idx=3;g1_idx=4;g2_idx=0;g3_idx=2;g4_idx=1;over=0; end
				28:begin g0_idx=4;g1_idx=3;g2_idx=0;g3_idx=2;g4_idx=1;over=0; end
				29:begin g0_idx=2;g1_idx=3;g2_idx=4;g3_idx=0;g4_idx=1;over=0; end
				30:begin g0_idx=3;g1_idx=2;g2_idx=4;g3_idx=0;g4_idx=1;over=0; end
				31:begin g0_idx=2;g1_idx=4;g2_idx=3;g3_idx=0;g4_idx=1;over=0; end
				32:begin g0_idx=4;g1_idx=2;g2_idx=3;g3_idx=0;g4_idx=1;over=0; end
				33:begin g0_idx=1;g1_idx=2;g2_idx=3;g3_idx=4;g4_idx=0;over=0; end
				34:begin g0_idx=2;g1_idx=3;g2_idx=1;g3_idx=4;g4_idx=0;over=0; end
				35:begin g0_idx=3;g1_idx=2;g2_idx=1;g3_idx=4;g4_idx=0;over=0; end
				36:begin g0_idx=1;g1_idx=3;g2_idx=4;g3_idx=2;g4_idx=0;over=0; end
				37:begin g0_idx=1;g1_idx=4;g2_idx=3;g3_idx=2;g4_idx=0;over=0; end
				38:begin g0_idx=3;g1_idx=4;g2_idx=1;g3_idx=2;g4_idx=0;over=0; end
				39:begin g0_idx=4;g1_idx=3;g2_idx=1;g3_idx=2;g4_idx=0;over=0; end
				40:begin g0_idx=2;g1_idx=3;g2_idx=4;g3_idx=1;g4_idx=0;over=0; end
				41:begin g0_idx=3;g1_idx=2;g2_idx=4;g3_idx=1;g4_idx=0;over=0; end
				42:begin g0_idx=2;g1_idx=4;g2_idx=3;g3_idx=1;g4_idx=0;over=0; end
				43:begin g0_idx=4;g1_idx=2;g2_idx=3;g3_idx=1;g4_idx=0;over=0; end
				default :begin
					g0_idx=3'bx;    g1_idx=3'bx;    g2_idx=3'bx;    g3_idx=3'bx;    g4_idx=3'bx; over=1;
				end	
			endcase
		6'o11:
			case(inspect_vector)
				0:begin g0_idx=0;g1_idx=5;g2_idx=1;g3_idx=6;g4_idx=7;over=0; end
				1:begin g0_idx=5;g1_idx=1;g2_idx=0;g3_idx=6;g4_idx=7;over=0; end
				2:begin g0_idx=0;g1_idx=6;g2_idx=1;g3_idx=5;g4_idx=7;over=0; end
				3:begin g0_idx=6;g1_idx=1;g2_idx=0;g3_idx=5;g4_idx=7;over=0; end
				4:begin g0_idx=0;g1_idx=5;g2_idx=6;g3_idx=1;g4_idx=7;over=0; end
				5:begin g0_idx=0;g1_idx=6;g2_idx=5;g3_idx=1;g4_idx=7;over=0; end
				6:begin g0_idx=5;g1_idx=1;g2_idx=6;g3_idx=0;g4_idx=7;over=0; end
				7:begin g0_idx=6;g1_idx=1;g2_idx=5;g3_idx=0;g4_idx=7;over=0; end
				8:begin g0_idx=0;g1_idx=5;g2_idx=1;g3_idx=7;g4_idx=6;over=0; end
				9:begin g0_idx=5;g1_idx=1;g2_idx=0;g3_idx=7;g4_idx=6;over=0; end
				10:begin g0_idx=0;g1_idx=7;g2_idx=1;g3_idx=5;g4_idx=6;over=0; end
				11:begin g0_idx=7;g1_idx=1;g2_idx=0;g3_idx=5;g4_idx=6;over=0; end
				12:begin g0_idx=0;g1_idx=5;g2_idx=7;g3_idx=1;g4_idx=6;over=0; end
				13:begin g0_idx=0;g1_idx=7;g2_idx=5;g3_idx=1;g4_idx=6;over=0; end
				14:begin g0_idx=5;g1_idx=1;g2_idx=7;g3_idx=0;g4_idx=6;over=0; end
				15:begin g0_idx=7;g1_idx=1;g2_idx=5;g3_idx=0;g4_idx=6;over=0; end
				16:begin g0_idx=0;g1_idx=6;g2_idx=1;g3_idx=7;g4_idx=5;over=0; end
				17:begin g0_idx=6;g1_idx=1;g2_idx=0;g3_idx=7;g4_idx=5;over=0; end
				18:begin g0_idx=0;g1_idx=7;g2_idx=1;g3_idx=6;g4_idx=5;over=0; end
				19:begin g0_idx=7;g1_idx=1;g2_idx=0;g3_idx=6;g4_idx=5;over=0; end
				20:begin g0_idx=0;g1_idx=6;g2_idx=7;g3_idx=1;g4_idx=5;over=0; end
				21:begin g0_idx=0;g1_idx=7;g2_idx=6;g3_idx=1;g4_idx=5;over=0; end
				22:begin g0_idx=6;g1_idx=1;g2_idx=7;g3_idx=0;g4_idx=5;over=0; end
				23:begin g0_idx=7;g1_idx=1;g2_idx=6;g3_idx=0;g4_idx=5;over=0; end
				24:begin g0_idx=0;g1_idx=5;g2_idx=6;g3_idx=7;g4_idx=1;over=0; end
				25:begin g0_idx=0;g1_idx=6;g2_idx=5;g3_idx=7;g4_idx=1;over=0; end
				26:begin g0_idx=0;g1_idx=5;g2_idx=7;g3_idx=6;g4_idx=1;over=0; end
				27:begin g0_idx=0;g1_idx=7;g2_idx=5;g3_idx=6;g4_idx=1;over=0; end
				28:begin g0_idx=0;g1_idx=6;g2_idx=7;g3_idx=5;g4_idx=1;over=0; end
				29:begin g0_idx=0;g1_idx=7;g2_idx=6;g3_idx=5;g4_idx=1;over=0; end
				30:begin g0_idx=5;g1_idx=1;g2_idx=6;g3_idx=7;g4_idx=0;over=0; end
				31:begin g0_idx=6;g1_idx=1;g2_idx=5;g3_idx=7;g4_idx=0;over=0; end
				32:begin g0_idx=5;g1_idx=1;g2_idx=7;g3_idx=6;g4_idx=0;over=0; end
				33:begin g0_idx=7;g1_idx=1;g2_idx=5;g3_idx=6;g4_idx=0;over=0; end
				34:begin g0_idx=6;g1_idx=1;g2_idx=7;g3_idx=5;g4_idx=0;over=0; end
				35:begin g0_idx=7;g1_idx=1;g2_idx=6;g3_idx=5;g4_idx=0;over=0; end
				36:begin g0_idx=0;g1_idx=2;g2_idx=5;g3_idx=6;g4_idx=7;over=0; end
				37:begin g0_idx=5;g1_idx=0;g2_idx=2;g3_idx=6;g4_idx=7;over=0; end
				38:begin g0_idx=0;g1_idx=2;g2_idx=6;g3_idx=5;g4_idx=7;over=0; end
				39:begin g0_idx=6;g1_idx=0;g2_idx=2;g3_idx=5;g4_idx=7;over=0; end
				40:begin g0_idx=0;g1_idx=5;g2_idx=6;g3_idx=2;g4_idx=7;over=0; end
				41:begin g0_idx=0;g1_idx=6;g2_idx=5;g3_idx=2;g4_idx=7;over=0; end
				42:begin g0_idx=5;g1_idx=6;g2_idx=2;g3_idx=0;g4_idx=7;over=0; end
				43:begin g0_idx=6;g1_idx=5;g2_idx=2;g3_idx=0;g4_idx=7;over=0; end
				44:begin g0_idx=0;g1_idx=2;g2_idx=5;g3_idx=7;g4_idx=6;over=0; end
				45:begin g0_idx=5;g1_idx=0;g2_idx=2;g3_idx=7;g4_idx=6;over=0; end
				46:begin g0_idx=0;g1_idx=2;g2_idx=7;g3_idx=5;g4_idx=6;over=0; end
				47:begin g0_idx=7;g1_idx=0;g2_idx=2;g3_idx=5;g4_idx=6;over=0; end
				48:begin g0_idx=0;g1_idx=5;g2_idx=7;g3_idx=2;g4_idx=6;over=0; end
				49:begin g0_idx=0;g1_idx=7;g2_idx=5;g3_idx=2;g4_idx=6;over=0; end
				50:begin g0_idx=5;g1_idx=7;g2_idx=2;g3_idx=0;g4_idx=6;over=0; end
				51:begin g0_idx=7;g1_idx=5;g2_idx=2;g3_idx=0;g4_idx=6;over=0; end
				52:begin g0_idx=0;g1_idx=2;g2_idx=6;g3_idx=7;g4_idx=5;over=0; end
				53:begin g0_idx=6;g1_idx=0;g2_idx=2;g3_idx=7;g4_idx=5;over=0; end
				54:begin g0_idx=0;g1_idx=2;g2_idx=7;g3_idx=6;g4_idx=5;over=0; end
				55:begin g0_idx=7;g1_idx=0;g2_idx=2;g3_idx=6;g4_idx=5;over=0; end
				56:begin g0_idx=0;g1_idx=6;g2_idx=7;g3_idx=2;g4_idx=5;over=0; end
				57:begin g0_idx=0;g1_idx=7;g2_idx=6;g3_idx=2;g4_idx=5;over=0; end
				58:begin g0_idx=6;g1_idx=7;g2_idx=2;g3_idx=0;g4_idx=5;over=0; end
				59:begin g0_idx=7;g1_idx=6;g2_idx=2;g3_idx=0;g4_idx=5;over=0; end
				60:begin g0_idx=0;g1_idx=5;g2_idx=6;g3_idx=7;g4_idx=2;over=0; end
				61:begin g0_idx=0;g1_idx=6;g2_idx=5;g3_idx=7;g4_idx=2;over=0; end
				62:begin g0_idx=0;g1_idx=5;g2_idx=7;g3_idx=6;g4_idx=2;over=0; end
				63:begin g0_idx=0;g1_idx=7;g2_idx=5;g3_idx=6;g4_idx=2;over=0; end
				64:begin g0_idx=0;g1_idx=6;g2_idx=7;g3_idx=5;g4_idx=2;over=0; end
				65:begin g0_idx=0;g1_idx=7;g2_idx=6;g3_idx=5;g4_idx=2;over=0; end
				66:begin g0_idx=5;g1_idx=6;g2_idx=2;g3_idx=7;g4_idx=0;over=0; end
				67:begin g0_idx=6;g1_idx=5;g2_idx=2;g3_idx=7;g4_idx=0;over=0; end
				68:begin g0_idx=5;g1_idx=7;g2_idx=2;g3_idx=6;g4_idx=0;over=0; end
				69:begin g0_idx=7;g1_idx=5;g2_idx=2;g3_idx=6;g4_idx=0;over=0; end
				70:begin g0_idx=6;g1_idx=7;g2_idx=2;g3_idx=5;g4_idx=0;over=0; end
				71:begin g0_idx=7;g1_idx=6;g2_idx=2;g3_idx=5;g4_idx=0;over=0; end
				72:begin g0_idx=2;g1_idx=1;g2_idx=5;g3_idx=6;g4_idx=7;over=0; end
				73:begin g0_idx=1;g1_idx=5;g2_idx=2;g3_idx=6;g4_idx=7;over=0; end
				74:begin g0_idx=2;g1_idx=1;g2_idx=6;g3_idx=5;g4_idx=7;over=0; end
				75:begin g0_idx=1;g1_idx=6;g2_idx=2;g3_idx=5;g4_idx=7;over=0; end
				76:begin g0_idx=5;g1_idx=1;g2_idx=6;g3_idx=2;g4_idx=7;over=0; end
				77:begin g0_idx=6;g1_idx=1;g2_idx=5;g3_idx=2;g4_idx=7;over=0; end
				78:begin g0_idx=5;g1_idx=6;g2_idx=2;g3_idx=1;g4_idx=7;over=0; end
				79:begin g0_idx=6;g1_idx=5;g2_idx=2;g3_idx=1;g4_idx=7;over=0; end
				80:begin g0_idx=2;g1_idx=1;g2_idx=5;g3_idx=7;g4_idx=6;over=0; end
				81:begin g0_idx=1;g1_idx=5;g2_idx=2;g3_idx=7;g4_idx=6;over=0; end
				82:begin g0_idx=2;g1_idx=1;g2_idx=7;g3_idx=5;g4_idx=6;over=0; end
				83:begin g0_idx=1;g1_idx=7;g2_idx=2;g3_idx=5;g4_idx=6;over=0; end
				84:begin g0_idx=5;g1_idx=1;g2_idx=7;g3_idx=2;g4_idx=6;over=0; end
				85:begin g0_idx=7;g1_idx=1;g2_idx=5;g3_idx=2;g4_idx=6;over=0; end
				86:begin g0_idx=5;g1_idx=7;g2_idx=2;g3_idx=1;g4_idx=6;over=0; end
				87:begin g0_idx=7;g1_idx=5;g2_idx=2;g3_idx=1;g4_idx=6;over=0; end
				88:begin g0_idx=2;g1_idx=1;g2_idx=6;g3_idx=7;g4_idx=5;over=0; end
				89:begin g0_idx=1;g1_idx=6;g2_idx=2;g3_idx=7;g4_idx=5;over=0; end
				90:begin g0_idx=2;g1_idx=1;g2_idx=7;g3_idx=6;g4_idx=5;over=0; end
				91:begin g0_idx=1;g1_idx=7;g2_idx=2;g3_idx=6;g4_idx=5;over=0; end
				92:begin g0_idx=6;g1_idx=1;g2_idx=7;g3_idx=2;g4_idx=5;over=0; end
				93:begin g0_idx=7;g1_idx=1;g2_idx=6;g3_idx=2;g4_idx=5;over=0; end
				94:begin g0_idx=6;g1_idx=7;g2_idx=2;g3_idx=1;g4_idx=5;over=0; end
				95:begin g0_idx=7;g1_idx=6;g2_idx=2;g3_idx=1;g4_idx=5;over=0; end
				96:begin g0_idx=5;g1_idx=1;g2_idx=6;g3_idx=7;g4_idx=2;over=0; end
				97:begin g0_idx=6;g1_idx=1;g2_idx=5;g3_idx=7;g4_idx=2;over=0; end
				98:begin g0_idx=5;g1_idx=1;g2_idx=7;g3_idx=6;g4_idx=2;over=0; end
				99:begin g0_idx=7;g1_idx=1;g2_idx=5;g3_idx=6;g4_idx=2;over=0; end
				100:begin g0_idx=6;g1_idx=1;g2_idx=7;g3_idx=5;g4_idx=2;over=0; end
				101:begin g0_idx=7;g1_idx=1;g2_idx=6;g3_idx=5;g4_idx=2;over=0; end
				102:begin g0_idx=5;g1_idx=6;g2_idx=2;g3_idx=7;g4_idx=1;over=0; end
				103:begin g0_idx=6;g1_idx=5;g2_idx=2;g3_idx=7;g4_idx=1;over=0; end
				104:begin g0_idx=5;g1_idx=7;g2_idx=2;g3_idx=6;g4_idx=1;over=0; end
				105:begin g0_idx=7;g1_idx=5;g2_idx=2;g3_idx=6;g4_idx=1;over=0; end
				106:begin g0_idx=6;g1_idx=7;g2_idx=2;g3_idx=5;g4_idx=1;over=0; end
				107:begin g0_idx=7;g1_idx=6;g2_idx=2;g3_idx=5;g4_idx=1;over=0; end
				108:begin g0_idx=0;g1_idx=3;g2_idx=5;g3_idx=6;g4_idx=7;over=0; end
				109:begin g0_idx=0;g1_idx=5;g2_idx=3;g3_idx=6;g4_idx=7;over=0; end
				110:begin g0_idx=0;g1_idx=3;g2_idx=6;g3_idx=5;g4_idx=7;over=0; end
				111:begin g0_idx=0;g1_idx=6;g2_idx=3;g3_idx=5;g4_idx=7;over=0; end
				112:begin g0_idx=5;g1_idx=0;g2_idx=6;g3_idx=3;g4_idx=7;over=0; end
				113:begin g0_idx=6;g1_idx=0;g2_idx=5;g3_idx=3;g4_idx=7;over=0; end
				114:begin g0_idx=5;g1_idx=6;g2_idx=0;g3_idx=3;g4_idx=7;over=0; end
				115:begin g0_idx=6;g1_idx=5;g2_idx=0;g3_idx=3;g4_idx=7;over=0; end
				116:begin g0_idx=0;g1_idx=3;g2_idx=5;g3_idx=7;g4_idx=6;over=0; end
				117:begin g0_idx=0;g1_idx=5;g2_idx=3;g3_idx=7;g4_idx=6;over=0; end
				118:begin g0_idx=0;g1_idx=3;g2_idx=7;g3_idx=5;g4_idx=6;over=0; end
				119:begin g0_idx=0;g1_idx=7;g2_idx=3;g3_idx=5;g4_idx=6;over=0; end
				120:begin g0_idx=5;g1_idx=0;g2_idx=7;g3_idx=3;g4_idx=6;over=0; end
				121:begin g0_idx=7;g1_idx=0;g2_idx=5;g3_idx=3;g4_idx=6;over=0; end
				122:begin g0_idx=5;g1_idx=7;g2_idx=0;g3_idx=3;g4_idx=6;over=0; end
				123:begin g0_idx=7;g1_idx=5;g2_idx=0;g3_idx=3;g4_idx=6;over=0; end
				124:begin g0_idx=0;g1_idx=3;g2_idx=6;g3_idx=7;g4_idx=5;over=0; end
				125:begin g0_idx=0;g1_idx=6;g2_idx=3;g3_idx=7;g4_idx=5;over=0; end
				126:begin g0_idx=0;g1_idx=3;g2_idx=7;g3_idx=6;g4_idx=5;over=0; end
				127:begin g0_idx=0;g1_idx=7;g2_idx=3;g3_idx=6;g4_idx=5;over=0; end
				128:begin g0_idx=6;g1_idx=0;g2_idx=7;g3_idx=3;g4_idx=5;over=0; end
				129:begin g0_idx=7;g1_idx=0;g2_idx=6;g3_idx=3;g4_idx=5;over=0; end
				130:begin g0_idx=6;g1_idx=7;g2_idx=0;g3_idx=3;g4_idx=5;over=0; end
				131:begin g0_idx=7;g1_idx=6;g2_idx=0;g3_idx=3;g4_idx=5;over=0; end
				132:begin g0_idx=0;g1_idx=5;g2_idx=6;g3_idx=7;g4_idx=3;over=0; end
				133:begin g0_idx=0;g1_idx=6;g2_idx=5;g3_idx=7;g4_idx=3;over=0; end
				134:begin g0_idx=0;g1_idx=5;g2_idx=7;g3_idx=6;g4_idx=3;over=0; end
				135:begin g0_idx=0;g1_idx=7;g2_idx=5;g3_idx=6;g4_idx=3;over=0; end
				136:begin g0_idx=0;g1_idx=6;g2_idx=7;g3_idx=5;g4_idx=3;over=0; end
				137:begin g0_idx=0;g1_idx=7;g2_idx=6;g3_idx=5;g4_idx=3;over=0; end
				138:begin g0_idx=5;g1_idx=6;g2_idx=7;g3_idx=3;g4_idx=0;over=0; end
				139:begin g0_idx=6;g1_idx=5;g2_idx=7;g3_idx=3;g4_idx=0;over=0; end
				140:begin g0_idx=5;g1_idx=7;g2_idx=6;g3_idx=3;g4_idx=0;over=0; end
				141:begin g0_idx=7;g1_idx=5;g2_idx=6;g3_idx=3;g4_idx=0;over=0; end
				142:begin g0_idx=6;g1_idx=7;g2_idx=5;g3_idx=3;g4_idx=0;over=0; end
				143:begin g0_idx=7;g1_idx=6;g2_idx=5;g3_idx=3;g4_idx=0;over=0; end
				144:begin g0_idx=3;g1_idx=1;g2_idx=5;g3_idx=6;g4_idx=7;over=0; end
				145:begin g0_idx=5;g1_idx=1;g2_idx=3;g3_idx=6;g4_idx=7;over=0; end
				146:begin g0_idx=3;g1_idx=1;g2_idx=6;g3_idx=5;g4_idx=7;over=0; end
				147:begin g0_idx=6;g1_idx=1;g2_idx=3;g3_idx=5;g4_idx=7;over=0; end
				148:begin g0_idx=1;g1_idx=5;g2_idx=6;g3_idx=3;g4_idx=7;over=0; end
				149:begin g0_idx=1;g1_idx=6;g2_idx=5;g3_idx=3;g4_idx=7;over=0; end
				150:begin g0_idx=5;g1_idx=6;g2_idx=1;g3_idx=3;g4_idx=7;over=0; end
				151:begin g0_idx=6;g1_idx=5;g2_idx=1;g3_idx=3;g4_idx=7;over=0; end
				152:begin g0_idx=3;g1_idx=1;g2_idx=5;g3_idx=7;g4_idx=6;over=0; end
				153:begin g0_idx=5;g1_idx=1;g2_idx=3;g3_idx=7;g4_idx=6;over=0; end
				154:begin g0_idx=3;g1_idx=1;g2_idx=7;g3_idx=5;g4_idx=6;over=0; end
				155:begin g0_idx=7;g1_idx=1;g2_idx=3;g3_idx=5;g4_idx=6;over=0; end
				156:begin g0_idx=1;g1_idx=5;g2_idx=7;g3_idx=3;g4_idx=6;over=0; end
				157:begin g0_idx=1;g1_idx=7;g2_idx=5;g3_idx=3;g4_idx=6;over=0; end
				158:begin g0_idx=5;g1_idx=7;g2_idx=1;g3_idx=3;g4_idx=6;over=0; end
				159:begin g0_idx=7;g1_idx=5;g2_idx=1;g3_idx=3;g4_idx=6;over=0; end
				160:begin g0_idx=3;g1_idx=1;g2_idx=6;g3_idx=7;g4_idx=5;over=0; end
				161:begin g0_idx=6;g1_idx=1;g2_idx=3;g3_idx=7;g4_idx=5;over=0; end
				162:begin g0_idx=3;g1_idx=1;g2_idx=7;g3_idx=6;g4_idx=5;over=0; end
				163:begin g0_idx=7;g1_idx=1;g2_idx=3;g3_idx=6;g4_idx=5;over=0; end
				164:begin g0_idx=1;g1_idx=6;g2_idx=7;g3_idx=3;g4_idx=5;over=0; end
				165:begin g0_idx=1;g1_idx=7;g2_idx=6;g3_idx=3;g4_idx=5;over=0; end
				166:begin g0_idx=6;g1_idx=7;g2_idx=1;g3_idx=3;g4_idx=5;over=0; end
				167:begin g0_idx=7;g1_idx=6;g2_idx=1;g3_idx=3;g4_idx=5;over=0; end
				168:begin g0_idx=5;g1_idx=1;g2_idx=6;g3_idx=7;g4_idx=3;over=0; end
				169:begin g0_idx=6;g1_idx=1;g2_idx=5;g3_idx=7;g4_idx=3;over=0; end
				170:begin g0_idx=5;g1_idx=1;g2_idx=7;g3_idx=6;g4_idx=3;over=0; end
				171:begin g0_idx=7;g1_idx=1;g2_idx=5;g3_idx=6;g4_idx=3;over=0; end
				172:begin g0_idx=6;g1_idx=1;g2_idx=7;g3_idx=5;g4_idx=3;over=0; end
				173:begin g0_idx=7;g1_idx=1;g2_idx=6;g3_idx=5;g4_idx=3;over=0; end
				174:begin g0_idx=5;g1_idx=6;g2_idx=7;g3_idx=3;g4_idx=1;over=0; end
				175:begin g0_idx=6;g1_idx=5;g2_idx=7;g3_idx=3;g4_idx=1;over=0; end
				176:begin g0_idx=5;g1_idx=7;g2_idx=6;g3_idx=3;g4_idx=1;over=0; end
				177:begin g0_idx=7;g1_idx=5;g2_idx=6;g3_idx=3;g4_idx=1;over=0; end
				178:begin g0_idx=6;g1_idx=7;g2_idx=5;g3_idx=3;g4_idx=1;over=0; end
				179:begin g0_idx=7;g1_idx=6;g2_idx=5;g3_idx=3;g4_idx=1;over=0; end
				180:begin g0_idx=3;g1_idx=5;g2_idx=2;g3_idx=6;g4_idx=7;over=0; end
				181:begin g0_idx=5;g1_idx=3;g2_idx=2;g3_idx=6;g4_idx=7;over=0; end
				182:begin g0_idx=3;g1_idx=6;g2_idx=2;g3_idx=5;g4_idx=7;over=0; end
				183:begin g0_idx=6;g1_idx=3;g2_idx=2;g3_idx=5;g4_idx=7;over=0; end
				184:begin g0_idx=2;g1_idx=5;g2_idx=6;g3_idx=3;g4_idx=7;over=0; end
				185:begin g0_idx=5;g1_idx=2;g2_idx=6;g3_idx=3;g4_idx=7;over=0; end
				186:begin g0_idx=2;g1_idx=6;g2_idx=5;g3_idx=3;g4_idx=7;over=0; end
				187:begin g0_idx=6;g1_idx=2;g2_idx=5;g3_idx=3;g4_idx=7;over=0; end
				188:begin g0_idx=3;g1_idx=5;g2_idx=2;g3_idx=7;g4_idx=6;over=0; end
				189:begin g0_idx=5;g1_idx=3;g2_idx=2;g3_idx=7;g4_idx=6;over=0; end
				190:begin g0_idx=3;g1_idx=7;g2_idx=2;g3_idx=5;g4_idx=6;over=0; end
				191:begin g0_idx=7;g1_idx=3;g2_idx=2;g3_idx=5;g4_idx=6;over=0; end
				192:begin g0_idx=2;g1_idx=5;g2_idx=7;g3_idx=3;g4_idx=6;over=0; end
				193:begin g0_idx=5;g1_idx=2;g2_idx=7;g3_idx=3;g4_idx=6;over=0; end
				194:begin g0_idx=2;g1_idx=7;g2_idx=5;g3_idx=3;g4_idx=6;over=0; end
				195:begin g0_idx=7;g1_idx=2;g2_idx=5;g3_idx=3;g4_idx=6;over=0; end
				196:begin g0_idx=3;g1_idx=6;g2_idx=2;g3_idx=7;g4_idx=5;over=0; end
				197:begin g0_idx=6;g1_idx=3;g2_idx=2;g3_idx=7;g4_idx=5;over=0; end
				198:begin g0_idx=3;g1_idx=7;g2_idx=2;g3_idx=6;g4_idx=5;over=0; end
				199:begin g0_idx=7;g1_idx=3;g2_idx=2;g3_idx=6;g4_idx=5;over=0; end
				200:begin g0_idx=2;g1_idx=6;g2_idx=7;g3_idx=3;g4_idx=5;over=0; end
				201:begin g0_idx=6;g1_idx=2;g2_idx=7;g3_idx=3;g4_idx=5;over=0; end
				202:begin g0_idx=2;g1_idx=7;g2_idx=6;g3_idx=3;g4_idx=5;over=0; end
				203:begin g0_idx=7;g1_idx=2;g2_idx=6;g3_idx=3;g4_idx=5;over=0; end
				204:begin g0_idx=5;g1_idx=6;g2_idx=2;g3_idx=7;g4_idx=3;over=0; end
				205:begin g0_idx=6;g1_idx=5;g2_idx=2;g3_idx=7;g4_idx=3;over=0; end
				206:begin g0_idx=5;g1_idx=7;g2_idx=2;g3_idx=6;g4_idx=3;over=0; end
				207:begin g0_idx=7;g1_idx=5;g2_idx=2;g3_idx=6;g4_idx=3;over=0; end
				208:begin g0_idx=6;g1_idx=7;g2_idx=2;g3_idx=5;g4_idx=3;over=0; end
				209:begin g0_idx=7;g1_idx=6;g2_idx=2;g3_idx=5;g4_idx=3;over=0; end
				210:begin g0_idx=5;g1_idx=6;g2_idx=7;g3_idx=3;g4_idx=2;over=0; end
				211:begin g0_idx=6;g1_idx=5;g2_idx=7;g3_idx=3;g4_idx=2;over=0; end
				212:begin g0_idx=5;g1_idx=7;g2_idx=6;g3_idx=3;g4_idx=2;over=0; end
				213:begin g0_idx=7;g1_idx=5;g2_idx=6;g3_idx=3;g4_idx=2;over=0; end
				214:begin g0_idx=6;g1_idx=7;g2_idx=5;g3_idx=3;g4_idx=2;over=0; end
				215:begin g0_idx=7;g1_idx=6;g2_idx=5;g3_idx=3;g4_idx=2;over=0; end
				216:begin g0_idx=0;g1_idx=4;g2_idx=5;g3_idx=6;g4_idx=7;over=0; end
				217:begin g0_idx=0;g1_idx=5;g2_idx=4;g3_idx=6;g4_idx=7;over=0; end
				218:begin g0_idx=0;g1_idx=4;g2_idx=6;g3_idx=5;g4_idx=7;over=0; end
				219:begin g0_idx=0;g1_idx=6;g2_idx=4;g3_idx=5;g4_idx=7;over=0; end
				220:begin g0_idx=0;g1_idx=5;g2_idx=6;g3_idx=4;g4_idx=7;over=0; end
				221:begin g0_idx=0;g1_idx=6;g2_idx=5;g3_idx=4;g4_idx=7;over=0; end
				222:begin g0_idx=0;g1_idx=4;g2_idx=5;g3_idx=7;g4_idx=6;over=0; end
				223:begin g0_idx=0;g1_idx=5;g2_idx=4;g3_idx=7;g4_idx=6;over=0; end
				224:begin g0_idx=0;g1_idx=4;g2_idx=7;g3_idx=5;g4_idx=6;over=0; end
				225:begin g0_idx=0;g1_idx=7;g2_idx=4;g3_idx=5;g4_idx=6;over=0; end
				226:begin g0_idx=0;g1_idx=5;g2_idx=7;g3_idx=4;g4_idx=6;over=0; end
				227:begin g0_idx=0;g1_idx=7;g2_idx=5;g3_idx=4;g4_idx=6;over=0; end
				228:begin g0_idx=0;g1_idx=4;g2_idx=6;g3_idx=7;g4_idx=5;over=0; end
				229:begin g0_idx=0;g1_idx=6;g2_idx=4;g3_idx=7;g4_idx=5;over=0; end
				230:begin g0_idx=0;g1_idx=4;g2_idx=7;g3_idx=6;g4_idx=5;over=0; end
				231:begin g0_idx=0;g1_idx=7;g2_idx=4;g3_idx=6;g4_idx=5;over=0; end
				232:begin g0_idx=0;g1_idx=6;g2_idx=7;g3_idx=4;g4_idx=5;over=0; end
				233:begin g0_idx=0;g1_idx=7;g2_idx=6;g3_idx=4;g4_idx=5;over=0; end
				234:begin g0_idx=5;g1_idx=0;g2_idx=6;g3_idx=7;g4_idx=4;over=0; end
				235:begin g0_idx=6;g1_idx=0;g2_idx=5;g3_idx=7;g4_idx=4;over=0; end
				236:begin g0_idx=5;g1_idx=6;g2_idx=0;g3_idx=7;g4_idx=4;over=0; end
				237:begin g0_idx=6;g1_idx=5;g2_idx=0;g3_idx=7;g4_idx=4;over=0; end
				238:begin g0_idx=5;g1_idx=0;g2_idx=7;g3_idx=6;g4_idx=4;over=0; end
				239:begin g0_idx=7;g1_idx=0;g2_idx=5;g3_idx=6;g4_idx=4;over=0; end
				240:begin g0_idx=5;g1_idx=7;g2_idx=0;g3_idx=6;g4_idx=4;over=0; end
				241:begin g0_idx=7;g1_idx=5;g2_idx=0;g3_idx=6;g4_idx=4;over=0; end
				242:begin g0_idx=6;g1_idx=0;g2_idx=7;g3_idx=5;g4_idx=4;over=0; end
				243:begin g0_idx=7;g1_idx=0;g2_idx=6;g3_idx=5;g4_idx=4;over=0; end
				244:begin g0_idx=6;g1_idx=7;g2_idx=0;g3_idx=5;g4_idx=4;over=0; end
				245:begin g0_idx=7;g1_idx=6;g2_idx=0;g3_idx=5;g4_idx=4;over=0; end
				246:begin g0_idx=5;g1_idx=6;g2_idx=7;g3_idx=0;g4_idx=4;over=0; end
				247:begin g0_idx=6;g1_idx=5;g2_idx=7;g3_idx=0;g4_idx=4;over=0; end
				248:begin g0_idx=5;g1_idx=7;g2_idx=6;g3_idx=0;g4_idx=4;over=0; end
				249:begin g0_idx=7;g1_idx=5;g2_idx=6;g3_idx=0;g4_idx=4;over=0; end
				250:begin g0_idx=6;g1_idx=7;g2_idx=5;g3_idx=0;g4_idx=4;over=0; end
				251:begin g0_idx=7;g1_idx=6;g2_idx=5;g3_idx=0;g4_idx=4;over=0; end
				252:begin g0_idx=4;g1_idx=1;g2_idx=5;g3_idx=6;g4_idx=7;over=0; end
				253:begin g0_idx=5;g1_idx=1;g2_idx=4;g3_idx=6;g4_idx=7;over=0; end
				254:begin g0_idx=4;g1_idx=1;g2_idx=6;g3_idx=5;g4_idx=7;over=0; end
				255:begin g0_idx=6;g1_idx=1;g2_idx=4;g3_idx=5;g4_idx=7;over=0; end
				256:begin g0_idx=5;g1_idx=1;g2_idx=6;g3_idx=4;g4_idx=7;over=0; end
				257:begin g0_idx=6;g1_idx=1;g2_idx=5;g3_idx=4;g4_idx=7;over=0; end
				258:begin g0_idx=4;g1_idx=1;g2_idx=5;g3_idx=7;g4_idx=6;over=0; end
				259:begin g0_idx=5;g1_idx=1;g2_idx=4;g3_idx=7;g4_idx=6;over=0; end
				260:begin g0_idx=4;g1_idx=1;g2_idx=7;g3_idx=5;g4_idx=6;over=0; end
				261:begin g0_idx=7;g1_idx=1;g2_idx=4;g3_idx=5;g4_idx=6;over=0; end
				262:begin g0_idx=5;g1_idx=1;g2_idx=7;g3_idx=4;g4_idx=6;over=0; end
				263:begin g0_idx=7;g1_idx=1;g2_idx=5;g3_idx=4;g4_idx=6;over=0; end
				264:begin g0_idx=4;g1_idx=1;g2_idx=6;g3_idx=7;g4_idx=5;over=0; end
				265:begin g0_idx=6;g1_idx=1;g2_idx=4;g3_idx=7;g4_idx=5;over=0; end
				266:begin g0_idx=4;g1_idx=1;g2_idx=7;g3_idx=6;g4_idx=5;over=0; end
				267:begin g0_idx=7;g1_idx=1;g2_idx=4;g3_idx=6;g4_idx=5;over=0; end
				268:begin g0_idx=6;g1_idx=1;g2_idx=7;g3_idx=4;g4_idx=5;over=0; end
				269:begin g0_idx=7;g1_idx=1;g2_idx=6;g3_idx=4;g4_idx=5;over=0; end
				270:begin g0_idx=1;g1_idx=5;g2_idx=6;g3_idx=7;g4_idx=4;over=0; end
				271:begin g0_idx=1;g1_idx=6;g2_idx=5;g3_idx=7;g4_idx=4;over=0; end
				272:begin g0_idx=5;g1_idx=6;g2_idx=1;g3_idx=7;g4_idx=4;over=0; end
				273:begin g0_idx=6;g1_idx=5;g2_idx=1;g3_idx=7;g4_idx=4;over=0; end
				274:begin g0_idx=1;g1_idx=5;g2_idx=7;g3_idx=6;g4_idx=4;over=0; end
				275:begin g0_idx=1;g1_idx=7;g2_idx=5;g3_idx=6;g4_idx=4;over=0; end
				276:begin g0_idx=5;g1_idx=7;g2_idx=1;g3_idx=6;g4_idx=4;over=0; end
				277:begin g0_idx=7;g1_idx=5;g2_idx=1;g3_idx=6;g4_idx=4;over=0; end
				278:begin g0_idx=1;g1_idx=6;g2_idx=7;g3_idx=5;g4_idx=4;over=0; end
				279:begin g0_idx=1;g1_idx=7;g2_idx=6;g3_idx=5;g4_idx=4;over=0; end
				280:begin g0_idx=6;g1_idx=7;g2_idx=1;g3_idx=5;g4_idx=4;over=0; end
				281:begin g0_idx=7;g1_idx=6;g2_idx=1;g3_idx=5;g4_idx=4;over=0; end
				282:begin g0_idx=5;g1_idx=6;g2_idx=7;g3_idx=1;g4_idx=4;over=0; end
				283:begin g0_idx=6;g1_idx=5;g2_idx=7;g3_idx=1;g4_idx=4;over=0; end
				284:begin g0_idx=5;g1_idx=7;g2_idx=6;g3_idx=1;g4_idx=4;over=0; end
				285:begin g0_idx=7;g1_idx=5;g2_idx=6;g3_idx=1;g4_idx=4;over=0; end
				286:begin g0_idx=6;g1_idx=7;g2_idx=5;g3_idx=1;g4_idx=4;over=0; end
				287:begin g0_idx=7;g1_idx=6;g2_idx=5;g3_idx=1;g4_idx=4;over=0; end
				288:begin g0_idx=4;g1_idx=5;g2_idx=2;g3_idx=6;g4_idx=7;over=0; end
				289:begin g0_idx=5;g1_idx=4;g2_idx=2;g3_idx=6;g4_idx=7;over=0; end
				290:begin g0_idx=4;g1_idx=6;g2_idx=2;g3_idx=5;g4_idx=7;over=0; end
				291:begin g0_idx=6;g1_idx=4;g2_idx=2;g3_idx=5;g4_idx=7;over=0; end
				292:begin g0_idx=5;g1_idx=6;g2_idx=2;g3_idx=4;g4_idx=7;over=0; end
				293:begin g0_idx=6;g1_idx=5;g2_idx=2;g3_idx=4;g4_idx=7;over=0; end
				294:begin g0_idx=4;g1_idx=5;g2_idx=2;g3_idx=7;g4_idx=6;over=0; end
				295:begin g0_idx=5;g1_idx=4;g2_idx=2;g3_idx=7;g4_idx=6;over=0; end
				296:begin g0_idx=4;g1_idx=7;g2_idx=2;g3_idx=5;g4_idx=6;over=0; end
				297:begin g0_idx=7;g1_idx=4;g2_idx=2;g3_idx=5;g4_idx=6;over=0; end
				298:begin g0_idx=5;g1_idx=7;g2_idx=2;g3_idx=4;g4_idx=6;over=0; end
				299:begin g0_idx=7;g1_idx=5;g2_idx=2;g3_idx=4;g4_idx=6;over=0; end
				300:begin g0_idx=4;g1_idx=6;g2_idx=2;g3_idx=7;g4_idx=5;over=0; end
				301:begin g0_idx=6;g1_idx=4;g2_idx=2;g3_idx=7;g4_idx=5;over=0; end
				302:begin g0_idx=4;g1_idx=7;g2_idx=2;g3_idx=6;g4_idx=5;over=0; end
				303:begin g0_idx=7;g1_idx=4;g2_idx=2;g3_idx=6;g4_idx=5;over=0; end
				304:begin g0_idx=6;g1_idx=7;g2_idx=2;g3_idx=4;g4_idx=5;over=0; end
				305:begin g0_idx=7;g1_idx=6;g2_idx=2;g3_idx=4;g4_idx=5;over=0; end
				306:begin g0_idx=2;g1_idx=5;g2_idx=6;g3_idx=7;g4_idx=4;over=0; end
				307:begin g0_idx=5;g1_idx=2;g2_idx=6;g3_idx=7;g4_idx=4;over=0; end
				308:begin g0_idx=2;g1_idx=6;g2_idx=5;g3_idx=7;g4_idx=4;over=0; end
				309:begin g0_idx=6;g1_idx=2;g2_idx=5;g3_idx=7;g4_idx=4;over=0; end
				310:begin g0_idx=2;g1_idx=5;g2_idx=7;g3_idx=6;g4_idx=4;over=0; end
				311:begin g0_idx=5;g1_idx=2;g2_idx=7;g3_idx=6;g4_idx=4;over=0; end
				312:begin g0_idx=2;g1_idx=7;g2_idx=5;g3_idx=6;g4_idx=4;over=0; end
				313:begin g0_idx=7;g1_idx=2;g2_idx=5;g3_idx=6;g4_idx=4;over=0; end
				314:begin g0_idx=2;g1_idx=6;g2_idx=7;g3_idx=5;g4_idx=4;over=0; end
				315:begin g0_idx=6;g1_idx=2;g2_idx=7;g3_idx=5;g4_idx=4;over=0; end
				316:begin g0_idx=2;g1_idx=7;g2_idx=6;g3_idx=5;g4_idx=4;over=0; end
				317:begin g0_idx=7;g1_idx=2;g2_idx=6;g3_idx=5;g4_idx=4;over=0; end
				318:begin g0_idx=5;g1_idx=6;g2_idx=7;g3_idx=2;g4_idx=4;over=0; end
				319:begin g0_idx=6;g1_idx=5;g2_idx=7;g3_idx=2;g4_idx=4;over=0; end
				320:begin g0_idx=5;g1_idx=7;g2_idx=6;g3_idx=2;g4_idx=4;over=0; end
				321:begin g0_idx=7;g1_idx=5;g2_idx=6;g3_idx=2;g4_idx=4;over=0; end
				322:begin g0_idx=6;g1_idx=7;g2_idx=5;g3_idx=2;g4_idx=4;over=0; end
				323:begin g0_idx=7;g1_idx=6;g2_idx=5;g3_idx=2;g4_idx=4;over=0; end
				324:begin g0_idx=4;g1_idx=5;g2_idx=6;g3_idx=3;g4_idx=7;over=0; end
				325:begin g0_idx=5;g1_idx=4;g2_idx=6;g3_idx=3;g4_idx=7;over=0; end
				326:begin g0_idx=4;g1_idx=6;g2_idx=5;g3_idx=3;g4_idx=7;over=0; end
				327:begin g0_idx=6;g1_idx=4;g2_idx=5;g3_idx=3;g4_idx=7;over=0; end
				328:begin g0_idx=5;g1_idx=6;g2_idx=4;g3_idx=3;g4_idx=7;over=0; end
				329:begin g0_idx=6;g1_idx=5;g2_idx=4;g3_idx=3;g4_idx=7;over=0; end
				330:begin g0_idx=4;g1_idx=5;g2_idx=7;g3_idx=3;g4_idx=6;over=0; end
				331:begin g0_idx=5;g1_idx=4;g2_idx=7;g3_idx=3;g4_idx=6;over=0; end
				332:begin g0_idx=4;g1_idx=7;g2_idx=5;g3_idx=3;g4_idx=6;over=0; end
				333:begin g0_idx=7;g1_idx=4;g2_idx=5;g3_idx=3;g4_idx=6;over=0; end
				334:begin g0_idx=5;g1_idx=7;g2_idx=4;g3_idx=3;g4_idx=6;over=0; end
				335:begin g0_idx=7;g1_idx=5;g2_idx=4;g3_idx=3;g4_idx=6;over=0; end
				336:begin g0_idx=4;g1_idx=6;g2_idx=7;g3_idx=3;g4_idx=5;over=0; end
				337:begin g0_idx=6;g1_idx=4;g2_idx=7;g3_idx=3;g4_idx=5;over=0; end
				338:begin g0_idx=4;g1_idx=7;g2_idx=6;g3_idx=3;g4_idx=5;over=0; end
				339:begin g0_idx=7;g1_idx=4;g2_idx=6;g3_idx=3;g4_idx=5;over=0; end
				340:begin g0_idx=6;g1_idx=7;g2_idx=4;g3_idx=3;g4_idx=5;over=0; end
				341:begin g0_idx=7;g1_idx=6;g2_idx=4;g3_idx=3;g4_idx=5;over=0; end
				342:begin g0_idx=3;g1_idx=5;g2_idx=6;g3_idx=7;g4_idx=4;over=0; end
				343:begin g0_idx=5;g1_idx=3;g2_idx=6;g3_idx=7;g4_idx=4;over=0; end
				344:begin g0_idx=3;g1_idx=6;g2_idx=5;g3_idx=7;g4_idx=4;over=0; end
				345:begin g0_idx=6;g1_idx=3;g2_idx=5;g3_idx=7;g4_idx=4;over=0; end
				346:begin g0_idx=5;g1_idx=6;g2_idx=3;g3_idx=7;g4_idx=4;over=0; end
				347:begin g0_idx=6;g1_idx=5;g2_idx=3;g3_idx=7;g4_idx=4;over=0; end
				348:begin g0_idx=3;g1_idx=5;g2_idx=7;g3_idx=6;g4_idx=4;over=0; end
				349:begin g0_idx=5;g1_idx=3;g2_idx=7;g3_idx=6;g4_idx=4;over=0; end
				350:begin g0_idx=3;g1_idx=7;g2_idx=5;g3_idx=6;g4_idx=4;over=0; end
				351:begin g0_idx=7;g1_idx=3;g2_idx=5;g3_idx=6;g4_idx=4;over=0; end
				352:begin g0_idx=5;g1_idx=7;g2_idx=3;g3_idx=6;g4_idx=4;over=0; end
				353:begin g0_idx=7;g1_idx=5;g2_idx=3;g3_idx=6;g4_idx=4;over=0; end
				354:begin g0_idx=3;g1_idx=6;g2_idx=7;g3_idx=5;g4_idx=4;over=0; end
				355:begin g0_idx=6;g1_idx=3;g2_idx=7;g3_idx=5;g4_idx=4;over=0; end
				356:begin g0_idx=3;g1_idx=7;g2_idx=6;g3_idx=5;g4_idx=4;over=0; end
				357:begin g0_idx=7;g1_idx=3;g2_idx=6;g3_idx=5;g4_idx=4;over=0; end
				358:begin g0_idx=6;g1_idx=7;g2_idx=3;g3_idx=5;g4_idx=4;over=0; end
				359:begin g0_idx=7;g1_idx=6;g2_idx=3;g3_idx=5;g4_idx=4;over=0; end
				default :begin
					g0_idx=3'bx;    g1_idx=3'bx;    g2_idx=3'bx;    g3_idx=3'bx;    g4_idx=3'bx; over=1;
				end	
			endcase				
		6'o12:
			case(inspect_vector)
				0:begin g0_idx=1;g1_idx=0;g2_idx=2;g3_idx=5;g4_idx=6;over=0; end
				1:begin g0_idx=0;g1_idx=2;g2_idx=1;g3_idx=5;g4_idx=6;over=0; end
				2:begin g0_idx=2;g1_idx=1;g2_idx=0;g3_idx=5;g4_idx=6;over=0; end
				3:begin g0_idx=0;g1_idx=5;g2_idx=1;g3_idx=2;g4_idx=6;over=0; end
				4:begin g0_idx=5;g1_idx=1;g2_idx=0;g3_idx=2;g4_idx=6;over=0; end
				5:begin g0_idx=0;g1_idx=2;g2_idx=5;g3_idx=1;g4_idx=6;over=0; end
				6:begin g0_idx=5;g1_idx=0;g2_idx=2;g3_idx=1;g4_idx=6;over=0; end
				7:begin g0_idx=2;g1_idx=1;g2_idx=5;g3_idx=0;g4_idx=6;over=0; end
				8:begin g0_idx=1;g1_idx=5;g2_idx=2;g3_idx=0;g4_idx=6;over=0; end
				9:begin g0_idx=1;g1_idx=0;g2_idx=2;g3_idx=6;g4_idx=5;over=0; end
				10:begin g0_idx=0;g1_idx=2;g2_idx=1;g3_idx=6;g4_idx=5;over=0; end
				11:begin g0_idx=2;g1_idx=1;g2_idx=0;g3_idx=6;g4_idx=5;over=0; end
				12:begin g0_idx=0;g1_idx=6;g2_idx=1;g3_idx=2;g4_idx=5;over=0; end
				13:begin g0_idx=6;g1_idx=1;g2_idx=0;g3_idx=2;g4_idx=5;over=0; end
				14:begin g0_idx=0;g1_idx=2;g2_idx=6;g3_idx=1;g4_idx=5;over=0; end
				15:begin g0_idx=6;g1_idx=0;g2_idx=2;g3_idx=1;g4_idx=5;over=0; end
				16:begin g0_idx=2;g1_idx=1;g2_idx=6;g3_idx=0;g4_idx=5;over=0; end
				17:begin g0_idx=1;g1_idx=6;g2_idx=2;g3_idx=0;g4_idx=5;over=0; end
				18:begin g0_idx=0;g1_idx=5;g2_idx=1;g3_idx=6;g4_idx=2;over=0; end
				19:begin g0_idx=5;g1_idx=1;g2_idx=0;g3_idx=6;g4_idx=2;over=0; end
				20:begin g0_idx=0;g1_idx=6;g2_idx=1;g3_idx=5;g4_idx=2;over=0; end
				21:begin g0_idx=6;g1_idx=1;g2_idx=0;g3_idx=5;g4_idx=2;over=0; end
				22:begin g0_idx=0;g1_idx=5;g2_idx=6;g3_idx=1;g4_idx=2;over=0; end
				23:begin g0_idx=0;g1_idx=6;g2_idx=5;g3_idx=1;g4_idx=2;over=0; end
				24:begin g0_idx=5;g1_idx=1;g2_idx=6;g3_idx=0;g4_idx=2;over=0; end
				25:begin g0_idx=6;g1_idx=1;g2_idx=5;g3_idx=0;g4_idx=2;over=0; end
				26:begin g0_idx=0;g1_idx=2;g2_idx=5;g3_idx=6;g4_idx=1;over=0; end
				27:begin g0_idx=5;g1_idx=0;g2_idx=2;g3_idx=6;g4_idx=1;over=0; end
				28:begin g0_idx=0;g1_idx=2;g2_idx=6;g3_idx=5;g4_idx=1;over=0; end
				29:begin g0_idx=6;g1_idx=0;g2_idx=2;g3_idx=5;g4_idx=1;over=0; end
				30:begin g0_idx=0;g1_idx=5;g2_idx=6;g3_idx=2;g4_idx=1;over=0; end
				31:begin g0_idx=0;g1_idx=6;g2_idx=5;g3_idx=2;g4_idx=1;over=0; end
				32:begin g0_idx=5;g1_idx=6;g2_idx=2;g3_idx=0;g4_idx=1;over=0; end
				33:begin g0_idx=6;g1_idx=5;g2_idx=2;g3_idx=0;g4_idx=1;over=0; end
				34:begin g0_idx=2;g1_idx=1;g2_idx=5;g3_idx=6;g4_idx=0;over=0; end
				35:begin g0_idx=1;g1_idx=5;g2_idx=2;g3_idx=6;g4_idx=0;over=0; end
				36:begin g0_idx=2;g1_idx=1;g2_idx=6;g3_idx=5;g4_idx=0;over=0; end
				37:begin g0_idx=1;g1_idx=6;g2_idx=2;g3_idx=5;g4_idx=0;over=0; end
				38:begin g0_idx=5;g1_idx=1;g2_idx=6;g3_idx=2;g4_idx=0;over=0; end
				39:begin g0_idx=6;g1_idx=1;g2_idx=5;g3_idx=2;g4_idx=0;over=0; end
				40:begin g0_idx=5;g1_idx=6;g2_idx=2;g3_idx=1;g4_idx=0;over=0; end
				41:begin g0_idx=6;g1_idx=5;g2_idx=2;g3_idx=1;g4_idx=0;over=0; end
				42:begin g0_idx=0;g1_idx=3;g2_idx=1;g3_idx=5;g4_idx=6;over=0; end
				43:begin g0_idx=3;g1_idx=1;g2_idx=0;g3_idx=5;g4_idx=6;over=0; end
				44:begin g0_idx=1;g1_idx=0;g2_idx=5;g3_idx=3;g4_idx=6;over=0; end
				45:begin g0_idx=5;g1_idx=0;g2_idx=1;g3_idx=3;g4_idx=6;over=0; end
				46:begin g0_idx=1;g1_idx=5;g2_idx=0;g3_idx=3;g4_idx=6;over=0; end
				47:begin g0_idx=0;g1_idx=3;g2_idx=5;g3_idx=1;g4_idx=6;over=0; end
				48:begin g0_idx=0;g1_idx=5;g2_idx=3;g3_idx=1;g4_idx=6;over=0; end
				49:begin g0_idx=3;g1_idx=1;g2_idx=5;g3_idx=0;g4_idx=6;over=0; end
				50:begin g0_idx=5;g1_idx=1;g2_idx=3;g3_idx=0;g4_idx=6;over=0; end
				51:begin g0_idx=0;g1_idx=3;g2_idx=1;g3_idx=6;g4_idx=5;over=0; end
				52:begin g0_idx=3;g1_idx=1;g2_idx=0;g3_idx=6;g4_idx=5;over=0; end
				53:begin g0_idx=1;g1_idx=0;g2_idx=6;g3_idx=3;g4_idx=5;over=0; end
				54:begin g0_idx=6;g1_idx=0;g2_idx=1;g3_idx=3;g4_idx=5;over=0; end
				55:begin g0_idx=1;g1_idx=6;g2_idx=0;g3_idx=3;g4_idx=5;over=0; end
				56:begin g0_idx=0;g1_idx=3;g2_idx=6;g3_idx=1;g4_idx=5;over=0; end
				57:begin g0_idx=0;g1_idx=6;g2_idx=3;g3_idx=1;g4_idx=5;over=0; end
				58:begin g0_idx=3;g1_idx=1;g2_idx=6;g3_idx=0;g4_idx=5;over=0; end
				59:begin g0_idx=6;g1_idx=1;g2_idx=3;g3_idx=0;g4_idx=5;over=0; end
				60:begin g0_idx=0;g1_idx=5;g2_idx=1;g3_idx=6;g4_idx=3;over=0; end
				61:begin g0_idx=5;g1_idx=1;g2_idx=0;g3_idx=6;g4_idx=3;over=0; end
				62:begin g0_idx=0;g1_idx=6;g2_idx=1;g3_idx=5;g4_idx=3;over=0; end
				63:begin g0_idx=6;g1_idx=1;g2_idx=0;g3_idx=5;g4_idx=3;over=0; end
				64:begin g0_idx=0;g1_idx=5;g2_idx=6;g3_idx=1;g4_idx=3;over=0; end
				65:begin g0_idx=0;g1_idx=6;g2_idx=5;g3_idx=1;g4_idx=3;over=0; end
				66:begin g0_idx=5;g1_idx=1;g2_idx=6;g3_idx=0;g4_idx=3;over=0; end
				67:begin g0_idx=6;g1_idx=1;g2_idx=5;g3_idx=0;g4_idx=3;over=0; end
				68:begin g0_idx=0;g1_idx=3;g2_idx=5;g3_idx=6;g4_idx=1;over=0; end
				69:begin g0_idx=0;g1_idx=5;g2_idx=3;g3_idx=6;g4_idx=1;over=0; end
				70:begin g0_idx=0;g1_idx=3;g2_idx=6;g3_idx=5;g4_idx=1;over=0; end
				71:begin g0_idx=0;g1_idx=6;g2_idx=3;g3_idx=5;g4_idx=1;over=0; end
				72:begin g0_idx=5;g1_idx=0;g2_idx=6;g3_idx=3;g4_idx=1;over=0; end
				73:begin g0_idx=6;g1_idx=0;g2_idx=5;g3_idx=3;g4_idx=1;over=0; end
				74:begin g0_idx=5;g1_idx=6;g2_idx=0;g3_idx=3;g4_idx=1;over=0; end
				75:begin g0_idx=6;g1_idx=5;g2_idx=0;g3_idx=3;g4_idx=1;over=0; end
				76:begin g0_idx=3;g1_idx=1;g2_idx=5;g3_idx=6;g4_idx=0;over=0; end
				77:begin g0_idx=5;g1_idx=1;g2_idx=3;g3_idx=6;g4_idx=0;over=0; end
				78:begin g0_idx=3;g1_idx=1;g2_idx=6;g3_idx=5;g4_idx=0;over=0; end
				79:begin g0_idx=6;g1_idx=1;g2_idx=3;g3_idx=5;g4_idx=0;over=0; end
				80:begin g0_idx=1;g1_idx=5;g2_idx=6;g3_idx=3;g4_idx=0;over=0; end
				81:begin g0_idx=1;g1_idx=6;g2_idx=5;g3_idx=3;g4_idx=0;over=0; end
				82:begin g0_idx=5;g1_idx=6;g2_idx=1;g3_idx=3;g4_idx=0;over=0; end
				83:begin g0_idx=6;g1_idx=5;g2_idx=1;g3_idx=3;g4_idx=0;over=0; end
				84:begin g0_idx=0;g1_idx=2;g2_idx=3;g3_idx=5;g4_idx=6;over=0; end
				85:begin g0_idx=3;g1_idx=0;g2_idx=2;g3_idx=5;g4_idx=6;over=0; end
				86:begin g0_idx=2;g1_idx=0;g2_idx=5;g3_idx=3;g4_idx=6;over=0; end
				87:begin g0_idx=2;g1_idx=5;g2_idx=0;g3_idx=3;g4_idx=6;over=0; end
				88:begin g0_idx=5;g1_idx=2;g2_idx=0;g3_idx=3;g4_idx=6;over=0; end
				89:begin g0_idx=0;g1_idx=3;g2_idx=5;g3_idx=2;g4_idx=6;over=0; end
				90:begin g0_idx=0;g1_idx=5;g2_idx=3;g3_idx=2;g4_idx=6;over=0; end
				91:begin g0_idx=3;g1_idx=5;g2_idx=2;g3_idx=0;g4_idx=6;over=0; end
				92:begin g0_idx=5;g1_idx=3;g2_idx=2;g3_idx=0;g4_idx=6;over=0; end
				93:begin g0_idx=0;g1_idx=2;g2_idx=3;g3_idx=6;g4_idx=5;over=0; end
				94:begin g0_idx=3;g1_idx=0;g2_idx=2;g3_idx=6;g4_idx=5;over=0; end
				95:begin g0_idx=2;g1_idx=0;g2_idx=6;g3_idx=3;g4_idx=5;over=0; end
				96:begin g0_idx=2;g1_idx=6;g2_idx=0;g3_idx=3;g4_idx=5;over=0; end
				97:begin g0_idx=6;g1_idx=2;g2_idx=0;g3_idx=3;g4_idx=5;over=0; end
				98:begin g0_idx=0;g1_idx=3;g2_idx=6;g3_idx=2;g4_idx=5;over=0; end
				99:begin g0_idx=0;g1_idx=6;g2_idx=3;g3_idx=2;g4_idx=5;over=0; end
				100:begin g0_idx=3;g1_idx=6;g2_idx=2;g3_idx=0;g4_idx=5;over=0; end
				101:begin g0_idx=6;g1_idx=3;g2_idx=2;g3_idx=0;g4_idx=5;over=0; end
				102:begin g0_idx=0;g1_idx=2;g2_idx=5;g3_idx=6;g4_idx=3;over=0; end
				103:begin g0_idx=5;g1_idx=0;g2_idx=2;g3_idx=6;g4_idx=3;over=0; end
				104:begin g0_idx=0;g1_idx=2;g2_idx=6;g3_idx=5;g4_idx=3;over=0; end
				105:begin g0_idx=6;g1_idx=0;g2_idx=2;g3_idx=5;g4_idx=3;over=0; end
				106:begin g0_idx=0;g1_idx=5;g2_idx=6;g3_idx=2;g4_idx=3;over=0; end
				107:begin g0_idx=0;g1_idx=6;g2_idx=5;g3_idx=2;g4_idx=3;over=0; end
				108:begin g0_idx=5;g1_idx=6;g2_idx=2;g3_idx=0;g4_idx=3;over=0; end
				109:begin g0_idx=6;g1_idx=5;g2_idx=2;g3_idx=0;g4_idx=3;over=0; end
				110:begin g0_idx=0;g1_idx=3;g2_idx=5;g3_idx=6;g4_idx=2;over=0; end
				111:begin g0_idx=0;g1_idx=5;g2_idx=3;g3_idx=6;g4_idx=2;over=0; end
				112:begin g0_idx=0;g1_idx=3;g2_idx=6;g3_idx=5;g4_idx=2;over=0; end
				113:begin g0_idx=0;g1_idx=6;g2_idx=3;g3_idx=5;g4_idx=2;over=0; end
				114:begin g0_idx=5;g1_idx=0;g2_idx=6;g3_idx=3;g4_idx=2;over=0; end
				115:begin g0_idx=6;g1_idx=0;g2_idx=5;g3_idx=3;g4_idx=2;over=0; end
				116:begin g0_idx=5;g1_idx=6;g2_idx=0;g3_idx=3;g4_idx=2;over=0; end
				117:begin g0_idx=6;g1_idx=5;g2_idx=0;g3_idx=3;g4_idx=2;over=0; end
				118:begin g0_idx=3;g1_idx=5;g2_idx=2;g3_idx=6;g4_idx=0;over=0; end
				119:begin g0_idx=5;g1_idx=3;g2_idx=2;g3_idx=6;g4_idx=0;over=0; end
				120:begin g0_idx=3;g1_idx=6;g2_idx=2;g3_idx=5;g4_idx=0;over=0; end
				121:begin g0_idx=6;g1_idx=3;g2_idx=2;g3_idx=5;g4_idx=0;over=0; end
				122:begin g0_idx=2;g1_idx=5;g2_idx=6;g3_idx=3;g4_idx=0;over=0; end
				123:begin g0_idx=5;g1_idx=2;g2_idx=6;g3_idx=3;g4_idx=0;over=0; end
				124:begin g0_idx=2;g1_idx=6;g2_idx=5;g3_idx=3;g4_idx=0;over=0; end
				125:begin g0_idx=6;g1_idx=2;g2_idx=5;g3_idx=3;g4_idx=0;over=0; end
				126:begin g0_idx=2;g1_idx=1;g2_idx=3;g3_idx=5;g4_idx=6;over=0; end
				127:begin g0_idx=1;g1_idx=3;g2_idx=2;g3_idx=5;g4_idx=6;over=0; end
				128:begin g0_idx=1;g1_idx=2;g2_idx=5;g3_idx=3;g4_idx=6;over=0; end
				129:begin g0_idx=2;g1_idx=5;g2_idx=1;g3_idx=3;g4_idx=6;over=0; end
				130:begin g0_idx=5;g1_idx=2;g2_idx=1;g3_idx=3;g4_idx=6;over=0; end
				131:begin g0_idx=3;g1_idx=1;g2_idx=5;g3_idx=2;g4_idx=6;over=0; end
				132:begin g0_idx=5;g1_idx=1;g2_idx=3;g3_idx=2;g4_idx=6;over=0; end
				133:begin g0_idx=3;g1_idx=5;g2_idx=2;g3_idx=1;g4_idx=6;over=0; end
				134:begin g0_idx=5;g1_idx=3;g2_idx=2;g3_idx=1;g4_idx=6;over=0; end
				135:begin g0_idx=2;g1_idx=1;g2_idx=3;g3_idx=6;g4_idx=5;over=0; end
				136:begin g0_idx=1;g1_idx=3;g2_idx=2;g3_idx=6;g4_idx=5;over=0; end
				137:begin g0_idx=1;g1_idx=2;g2_idx=6;g3_idx=3;g4_idx=5;over=0; end
				138:begin g0_idx=2;g1_idx=6;g2_idx=1;g3_idx=3;g4_idx=5;over=0; end
				139:begin g0_idx=6;g1_idx=2;g2_idx=1;g3_idx=3;g4_idx=5;over=0; end
				140:begin g0_idx=3;g1_idx=1;g2_idx=6;g3_idx=2;g4_idx=5;over=0; end
				141:begin g0_idx=6;g1_idx=1;g2_idx=3;g3_idx=2;g4_idx=5;over=0; end
				142:begin g0_idx=3;g1_idx=6;g2_idx=2;g3_idx=1;g4_idx=5;over=0; end
				143:begin g0_idx=6;g1_idx=3;g2_idx=2;g3_idx=1;g4_idx=5;over=0; end
				144:begin g0_idx=2;g1_idx=1;g2_idx=5;g3_idx=6;g4_idx=3;over=0; end
				145:begin g0_idx=1;g1_idx=5;g2_idx=2;g3_idx=6;g4_idx=3;over=0; end
				146:begin g0_idx=2;g1_idx=1;g2_idx=6;g3_idx=5;g4_idx=3;over=0; end
				147:begin g0_idx=1;g1_idx=6;g2_idx=2;g3_idx=5;g4_idx=3;over=0; end
				148:begin g0_idx=5;g1_idx=1;g2_idx=6;g3_idx=2;g4_idx=3;over=0; end
				149:begin g0_idx=6;g1_idx=1;g2_idx=5;g3_idx=2;g4_idx=3;over=0; end
				150:begin g0_idx=5;g1_idx=6;g2_idx=2;g3_idx=1;g4_idx=3;over=0; end
				151:begin g0_idx=6;g1_idx=5;g2_idx=2;g3_idx=1;g4_idx=3;over=0; end
				152:begin g0_idx=3;g1_idx=1;g2_idx=5;g3_idx=6;g4_idx=2;over=0; end
				153:begin g0_idx=5;g1_idx=1;g2_idx=3;g3_idx=6;g4_idx=2;over=0; end
				154:begin g0_idx=3;g1_idx=1;g2_idx=6;g3_idx=5;g4_idx=2;over=0; end
				155:begin g0_idx=6;g1_idx=1;g2_idx=3;g3_idx=5;g4_idx=2;over=0; end
				156:begin g0_idx=1;g1_idx=5;g2_idx=6;g3_idx=3;g4_idx=2;over=0; end
				157:begin g0_idx=1;g1_idx=6;g2_idx=5;g3_idx=3;g4_idx=2;over=0; end
				158:begin g0_idx=5;g1_idx=6;g2_idx=1;g3_idx=3;g4_idx=2;over=0; end
				159:begin g0_idx=6;g1_idx=5;g2_idx=1;g3_idx=3;g4_idx=2;over=0; end
				160:begin g0_idx=3;g1_idx=5;g2_idx=2;g3_idx=6;g4_idx=1;over=0; end
				161:begin g0_idx=5;g1_idx=3;g2_idx=2;g3_idx=6;g4_idx=1;over=0; end
				162:begin g0_idx=3;g1_idx=6;g2_idx=2;g3_idx=5;g4_idx=1;over=0; end
				163:begin g0_idx=6;g1_idx=3;g2_idx=2;g3_idx=5;g4_idx=1;over=0; end
				164:begin g0_idx=2;g1_idx=5;g2_idx=6;g3_idx=3;g4_idx=1;over=0; end
				165:begin g0_idx=5;g1_idx=2;g2_idx=6;g3_idx=3;g4_idx=1;over=0; end
				166:begin g0_idx=2;g1_idx=6;g2_idx=5;g3_idx=3;g4_idx=1;over=0; end
				167:begin g0_idx=6;g1_idx=2;g2_idx=5;g3_idx=3;g4_idx=1;over=0; end
				168:begin g0_idx=0;g1_idx=4;g2_idx=1;g3_idx=5;g4_idx=6;over=0; end
				169:begin g0_idx=4;g1_idx=1;g2_idx=0;g3_idx=5;g4_idx=6;over=0; end
				170:begin g0_idx=0;g1_idx=5;g2_idx=1;g3_idx=4;g4_idx=6;over=0; end
				171:begin g0_idx=5;g1_idx=1;g2_idx=0;g3_idx=4;g4_idx=6;over=0; end
				172:begin g0_idx=0;g1_idx=4;g2_idx=5;g3_idx=1;g4_idx=6;over=0; end
				173:begin g0_idx=0;g1_idx=5;g2_idx=4;g3_idx=1;g4_idx=6;over=0; end
				174:begin g0_idx=4;g1_idx=1;g2_idx=5;g3_idx=0;g4_idx=6;over=0; end
				175:begin g0_idx=5;g1_idx=1;g2_idx=4;g3_idx=0;g4_idx=6;over=0; end
				176:begin g0_idx=0;g1_idx=4;g2_idx=1;g3_idx=6;g4_idx=5;over=0; end
				177:begin g0_idx=4;g1_idx=1;g2_idx=0;g3_idx=6;g4_idx=5;over=0; end
				178:begin g0_idx=0;g1_idx=6;g2_idx=1;g3_idx=4;g4_idx=5;over=0; end
				179:begin g0_idx=6;g1_idx=1;g2_idx=0;g3_idx=4;g4_idx=5;over=0; end
				180:begin g0_idx=0;g1_idx=4;g2_idx=6;g3_idx=1;g4_idx=5;over=0; end
				181:begin g0_idx=0;g1_idx=6;g2_idx=4;g3_idx=1;g4_idx=5;over=0; end
				182:begin g0_idx=4;g1_idx=1;g2_idx=6;g3_idx=0;g4_idx=5;over=0; end
				183:begin g0_idx=6;g1_idx=1;g2_idx=4;g3_idx=0;g4_idx=5;over=0; end
				184:begin g0_idx=1;g1_idx=0;g2_idx=5;g3_idx=6;g4_idx=4;over=0; end
				185:begin g0_idx=5;g1_idx=0;g2_idx=1;g3_idx=6;g4_idx=4;over=0; end
				186:begin g0_idx=1;g1_idx=5;g2_idx=0;g3_idx=6;g4_idx=4;over=0; end
				187:begin g0_idx=1;g1_idx=0;g2_idx=6;g3_idx=5;g4_idx=4;over=0; end
				188:begin g0_idx=6;g1_idx=0;g2_idx=1;g3_idx=5;g4_idx=4;over=0; end
				189:begin g0_idx=1;g1_idx=6;g2_idx=0;g3_idx=5;g4_idx=4;over=0; end
				190:begin g0_idx=5;g1_idx=0;g2_idx=6;g3_idx=1;g4_idx=4;over=0; end
				191:begin g0_idx=6;g1_idx=0;g2_idx=5;g3_idx=1;g4_idx=4;over=0; end
				192:begin g0_idx=5;g1_idx=6;g2_idx=0;g3_idx=1;g4_idx=4;over=0; end
				193:begin g0_idx=6;g1_idx=5;g2_idx=0;g3_idx=1;g4_idx=4;over=0; end
				194:begin g0_idx=1;g1_idx=5;g2_idx=6;g3_idx=0;g4_idx=4;over=0; end
				195:begin g0_idx=1;g1_idx=6;g2_idx=5;g3_idx=0;g4_idx=4;over=0; end
				196:begin g0_idx=5;g1_idx=6;g2_idx=1;g3_idx=0;g4_idx=4;over=0; end
				197:begin g0_idx=6;g1_idx=5;g2_idx=1;g3_idx=0;g4_idx=4;over=0; end
				198:begin g0_idx=0;g1_idx=4;g2_idx=5;g3_idx=6;g4_idx=1;over=0; end
				199:begin g0_idx=0;g1_idx=5;g2_idx=4;g3_idx=6;g4_idx=1;over=0; end
				200:begin g0_idx=0;g1_idx=4;g2_idx=6;g3_idx=5;g4_idx=1;over=0; end
				201:begin g0_idx=0;g1_idx=6;g2_idx=4;g3_idx=5;g4_idx=1;over=0; end
				202:begin g0_idx=0;g1_idx=5;g2_idx=6;g3_idx=4;g4_idx=1;over=0; end
				203:begin g0_idx=0;g1_idx=6;g2_idx=5;g3_idx=4;g4_idx=1;over=0; end
				204:begin g0_idx=4;g1_idx=1;g2_idx=5;g3_idx=6;g4_idx=0;over=0; end
				205:begin g0_idx=5;g1_idx=1;g2_idx=4;g3_idx=6;g4_idx=0;over=0; end
				206:begin g0_idx=4;g1_idx=1;g2_idx=6;g3_idx=5;g4_idx=0;over=0; end
				207:begin g0_idx=6;g1_idx=1;g2_idx=4;g3_idx=5;g4_idx=0;over=0; end
				208:begin g0_idx=5;g1_idx=1;g2_idx=6;g3_idx=4;g4_idx=0;over=0; end
				209:begin g0_idx=6;g1_idx=1;g2_idx=5;g3_idx=4;g4_idx=0;over=0; end
				210:begin g0_idx=0;g1_idx=2;g2_idx=4;g3_idx=5;g4_idx=6;over=0; end
				211:begin g0_idx=4;g1_idx=0;g2_idx=2;g3_idx=5;g4_idx=6;over=0; end
				212:begin g0_idx=0;g1_idx=2;g2_idx=5;g3_idx=4;g4_idx=6;over=0; end
				213:begin g0_idx=5;g1_idx=0;g2_idx=2;g3_idx=4;g4_idx=6;over=0; end
				214:begin g0_idx=0;g1_idx=4;g2_idx=5;g3_idx=2;g4_idx=6;over=0; end
				215:begin g0_idx=0;g1_idx=5;g2_idx=4;g3_idx=2;g4_idx=6;over=0; end
				216:begin g0_idx=4;g1_idx=5;g2_idx=2;g3_idx=0;g4_idx=6;over=0; end
				217:begin g0_idx=5;g1_idx=4;g2_idx=2;g3_idx=0;g4_idx=6;over=0; end
				218:begin g0_idx=0;g1_idx=2;g2_idx=4;g3_idx=6;g4_idx=5;over=0; end
				219:begin g0_idx=4;g1_idx=0;g2_idx=2;g3_idx=6;g4_idx=5;over=0; end
				220:begin g0_idx=0;g1_idx=2;g2_idx=6;g3_idx=4;g4_idx=5;over=0; end
				221:begin g0_idx=6;g1_idx=0;g2_idx=2;g3_idx=4;g4_idx=5;over=0; end
				222:begin g0_idx=0;g1_idx=4;g2_idx=6;g3_idx=2;g4_idx=5;over=0; end
				223:begin g0_idx=0;g1_idx=6;g2_idx=4;g3_idx=2;g4_idx=5;over=0; end
				224:begin g0_idx=4;g1_idx=6;g2_idx=2;g3_idx=0;g4_idx=5;over=0; end
				225:begin g0_idx=6;g1_idx=4;g2_idx=2;g3_idx=0;g4_idx=5;over=0; end
				226:begin g0_idx=2;g1_idx=0;g2_idx=5;g3_idx=6;g4_idx=4;over=0; end
				227:begin g0_idx=2;g1_idx=5;g2_idx=0;g3_idx=6;g4_idx=4;over=0; end
				228:begin g0_idx=5;g1_idx=2;g2_idx=0;g3_idx=6;g4_idx=4;over=0; end
				229:begin g0_idx=2;g1_idx=0;g2_idx=6;g3_idx=5;g4_idx=4;over=0; end
				230:begin g0_idx=2;g1_idx=6;g2_idx=0;g3_idx=5;g4_idx=4;over=0; end
				231:begin g0_idx=6;g1_idx=2;g2_idx=0;g3_idx=5;g4_idx=4;over=0; end
				232:begin g0_idx=5;g1_idx=0;g2_idx=6;g3_idx=2;g4_idx=4;over=0; end
				233:begin g0_idx=6;g1_idx=0;g2_idx=5;g3_idx=2;g4_idx=4;over=0; end
				234:begin g0_idx=5;g1_idx=6;g2_idx=0;g3_idx=2;g4_idx=4;over=0; end
				235:begin g0_idx=6;g1_idx=5;g2_idx=0;g3_idx=2;g4_idx=4;over=0; end
				236:begin g0_idx=2;g1_idx=5;g2_idx=6;g3_idx=0;g4_idx=4;over=0; end
				237:begin g0_idx=5;g1_idx=2;g2_idx=6;g3_idx=0;g4_idx=4;over=0; end
				238:begin g0_idx=2;g1_idx=6;g2_idx=5;g3_idx=0;g4_idx=4;over=0; end
				239:begin g0_idx=6;g1_idx=2;g2_idx=5;g3_idx=0;g4_idx=4;over=0; end
				240:begin g0_idx=0;g1_idx=4;g2_idx=5;g3_idx=6;g4_idx=2;over=0; end
				241:begin g0_idx=0;g1_idx=5;g2_idx=4;g3_idx=6;g4_idx=2;over=0; end
				242:begin g0_idx=0;g1_idx=4;g2_idx=6;g3_idx=5;g4_idx=2;over=0; end
				243:begin g0_idx=0;g1_idx=6;g2_idx=4;g3_idx=5;g4_idx=2;over=0; end
				244:begin g0_idx=0;g1_idx=5;g2_idx=6;g3_idx=4;g4_idx=2;over=0; end
				245:begin g0_idx=0;g1_idx=6;g2_idx=5;g3_idx=4;g4_idx=2;over=0; end
				246:begin g0_idx=4;g1_idx=5;g2_idx=2;g3_idx=6;g4_idx=0;over=0; end
				247:begin g0_idx=5;g1_idx=4;g2_idx=2;g3_idx=6;g4_idx=0;over=0; end
				248:begin g0_idx=4;g1_idx=6;g2_idx=2;g3_idx=5;g4_idx=0;over=0; end
				249:begin g0_idx=6;g1_idx=4;g2_idx=2;g3_idx=5;g4_idx=0;over=0; end
				250:begin g0_idx=5;g1_idx=6;g2_idx=2;g3_idx=4;g4_idx=0;over=0; end
				251:begin g0_idx=6;g1_idx=5;g2_idx=2;g3_idx=4;g4_idx=0;over=0; end
				252:begin g0_idx=2;g1_idx=1;g2_idx=4;g3_idx=5;g4_idx=6;over=0; end
				253:begin g0_idx=1;g1_idx=4;g2_idx=2;g3_idx=5;g4_idx=6;over=0; end
				254:begin g0_idx=2;g1_idx=1;g2_idx=5;g3_idx=4;g4_idx=6;over=0; end
				255:begin g0_idx=1;g1_idx=5;g2_idx=2;g3_idx=4;g4_idx=6;over=0; end
				256:begin g0_idx=4;g1_idx=1;g2_idx=5;g3_idx=2;g4_idx=6;over=0; end
				257:begin g0_idx=5;g1_idx=1;g2_idx=4;g3_idx=2;g4_idx=6;over=0; end
				258:begin g0_idx=4;g1_idx=5;g2_idx=2;g3_idx=1;g4_idx=6;over=0; end
				259:begin g0_idx=5;g1_idx=4;g2_idx=2;g3_idx=1;g4_idx=6;over=0; end
				260:begin g0_idx=2;g1_idx=1;g2_idx=4;g3_idx=6;g4_idx=5;over=0; end
				261:begin g0_idx=1;g1_idx=4;g2_idx=2;g3_idx=6;g4_idx=5;over=0; end
				262:begin g0_idx=2;g1_idx=1;g2_idx=6;g3_idx=4;g4_idx=5;over=0; end
				263:begin g0_idx=1;g1_idx=6;g2_idx=2;g3_idx=4;g4_idx=5;over=0; end
				264:begin g0_idx=4;g1_idx=1;g2_idx=6;g3_idx=2;g4_idx=5;over=0; end
				265:begin g0_idx=6;g1_idx=1;g2_idx=4;g3_idx=2;g4_idx=5;over=0; end
				266:begin g0_idx=4;g1_idx=6;g2_idx=2;g3_idx=1;g4_idx=5;over=0; end
				267:begin g0_idx=6;g1_idx=4;g2_idx=2;g3_idx=1;g4_idx=5;over=0; end
				268:begin g0_idx=1;g1_idx=2;g2_idx=5;g3_idx=6;g4_idx=4;over=0; end
				269:begin g0_idx=2;g1_idx=5;g2_idx=1;g3_idx=6;g4_idx=4;over=0; end
				270:begin g0_idx=5;g1_idx=2;g2_idx=1;g3_idx=6;g4_idx=4;over=0; end
				271:begin g0_idx=1;g1_idx=2;g2_idx=6;g3_idx=5;g4_idx=4;over=0; end
				272:begin g0_idx=2;g1_idx=6;g2_idx=1;g3_idx=5;g4_idx=4;over=0; end
				273:begin g0_idx=6;g1_idx=2;g2_idx=1;g3_idx=5;g4_idx=4;over=0; end
				274:begin g0_idx=1;g1_idx=5;g2_idx=6;g3_idx=2;g4_idx=4;over=0; end
				275:begin g0_idx=1;g1_idx=6;g2_idx=5;g3_idx=2;g4_idx=4;over=0; end
				276:begin g0_idx=5;g1_idx=6;g2_idx=1;g3_idx=2;g4_idx=4;over=0; end
				277:begin g0_idx=6;g1_idx=5;g2_idx=1;g3_idx=2;g4_idx=4;over=0; end
				278:begin g0_idx=2;g1_idx=5;g2_idx=6;g3_idx=1;g4_idx=4;over=0; end
				279:begin g0_idx=5;g1_idx=2;g2_idx=6;g3_idx=1;g4_idx=4;over=0; end
				280:begin g0_idx=2;g1_idx=6;g2_idx=5;g3_idx=1;g4_idx=4;over=0; end
				281:begin g0_idx=6;g1_idx=2;g2_idx=5;g3_idx=1;g4_idx=4;over=0; end
				282:begin g0_idx=4;g1_idx=1;g2_idx=5;g3_idx=6;g4_idx=2;over=0; end
				283:begin g0_idx=5;g1_idx=1;g2_idx=4;g3_idx=6;g4_idx=2;over=0; end
				284:begin g0_idx=4;g1_idx=1;g2_idx=6;g3_idx=5;g4_idx=2;over=0; end
				285:begin g0_idx=6;g1_idx=1;g2_idx=4;g3_idx=5;g4_idx=2;over=0; end
				286:begin g0_idx=5;g1_idx=1;g2_idx=6;g3_idx=4;g4_idx=2;over=0; end
				287:begin g0_idx=6;g1_idx=1;g2_idx=5;g3_idx=4;g4_idx=2;over=0; end
				288:begin g0_idx=4;g1_idx=5;g2_idx=2;g3_idx=6;g4_idx=1;over=0; end
				289:begin g0_idx=5;g1_idx=4;g2_idx=2;g3_idx=6;g4_idx=1;over=0; end
				290:begin g0_idx=4;g1_idx=6;g2_idx=2;g3_idx=5;g4_idx=1;over=0; end
				291:begin g0_idx=6;g1_idx=4;g2_idx=2;g3_idx=5;g4_idx=1;over=0; end
				292:begin g0_idx=5;g1_idx=6;g2_idx=2;g3_idx=4;g4_idx=1;over=0; end
				293:begin g0_idx=6;g1_idx=5;g2_idx=2;g3_idx=4;g4_idx=1;over=0; end
				294:begin g0_idx=0;g1_idx=3;g2_idx=4;g3_idx=5;g4_idx=6;over=0; end
				295:begin g0_idx=0;g1_idx=4;g2_idx=3;g3_idx=5;g4_idx=6;over=0; end
				296:begin g0_idx=0;g1_idx=3;g2_idx=5;g3_idx=4;g4_idx=6;over=0; end
				297:begin g0_idx=0;g1_idx=5;g2_idx=3;g3_idx=4;g4_idx=6;over=0; end
				298:begin g0_idx=4;g1_idx=0;g2_idx=5;g3_idx=3;g4_idx=6;over=0; end
				299:begin g0_idx=5;g1_idx=0;g2_idx=4;g3_idx=3;g4_idx=6;over=0; end
				300:begin g0_idx=4;g1_idx=5;g2_idx=0;g3_idx=3;g4_idx=6;over=0; end
				301:begin g0_idx=5;g1_idx=4;g2_idx=0;g3_idx=3;g4_idx=6;over=0; end
				302:begin g0_idx=0;g1_idx=3;g2_idx=4;g3_idx=6;g4_idx=5;over=0; end
				303:begin g0_idx=0;g1_idx=4;g2_idx=3;g3_idx=6;g4_idx=5;over=0; end
				304:begin g0_idx=0;g1_idx=3;g2_idx=6;g3_idx=4;g4_idx=5;over=0; end
				305:begin g0_idx=0;g1_idx=6;g2_idx=3;g3_idx=4;g4_idx=5;over=0; end
				306:begin g0_idx=4;g1_idx=0;g2_idx=6;g3_idx=3;g4_idx=5;over=0; end
				307:begin g0_idx=6;g1_idx=0;g2_idx=4;g3_idx=3;g4_idx=5;over=0; end
				308:begin g0_idx=4;g1_idx=6;g2_idx=0;g3_idx=3;g4_idx=5;over=0; end
				309:begin g0_idx=6;g1_idx=4;g2_idx=0;g3_idx=3;g4_idx=5;over=0; end
				310:begin g0_idx=3;g1_idx=0;g2_idx=5;g3_idx=6;g4_idx=4;over=0; end
				311:begin g0_idx=5;g1_idx=0;g2_idx=3;g3_idx=6;g4_idx=4;over=0; end
				312:begin g0_idx=3;g1_idx=5;g2_idx=0;g3_idx=6;g4_idx=4;over=0; end
				313:begin g0_idx=5;g1_idx=3;g2_idx=0;g3_idx=6;g4_idx=4;over=0; end
				314:begin g0_idx=3;g1_idx=0;g2_idx=6;g3_idx=5;g4_idx=4;over=0; end
				315:begin g0_idx=6;g1_idx=0;g2_idx=3;g3_idx=5;g4_idx=4;over=0; end
				316:begin g0_idx=3;g1_idx=6;g2_idx=0;g3_idx=5;g4_idx=4;over=0; end
				317:begin g0_idx=6;g1_idx=3;g2_idx=0;g3_idx=5;g4_idx=4;over=0; end
				318:begin g0_idx=3;g1_idx=5;g2_idx=6;g3_idx=0;g4_idx=4;over=0; end
				319:begin g0_idx=5;g1_idx=3;g2_idx=6;g3_idx=0;g4_idx=4;over=0; end
				320:begin g0_idx=3;g1_idx=6;g2_idx=5;g3_idx=0;g4_idx=4;over=0; end
				321:begin g0_idx=6;g1_idx=3;g2_idx=5;g3_idx=0;g4_idx=4;over=0; end
				322:begin g0_idx=5;g1_idx=6;g2_idx=3;g3_idx=0;g4_idx=4;over=0; end
				323:begin g0_idx=6;g1_idx=5;g2_idx=3;g3_idx=0;g4_idx=4;over=0; end
				324:begin g0_idx=0;g1_idx=4;g2_idx=5;g3_idx=6;g4_idx=3;over=0; end
				325:begin g0_idx=0;g1_idx=5;g2_idx=4;g3_idx=6;g4_idx=3;over=0; end
				326:begin g0_idx=0;g1_idx=4;g2_idx=6;g3_idx=5;g4_idx=3;over=0; end
				327:begin g0_idx=0;g1_idx=6;g2_idx=4;g3_idx=5;g4_idx=3;over=0; end
				328:begin g0_idx=0;g1_idx=5;g2_idx=6;g3_idx=4;g4_idx=3;over=0; end
				329:begin g0_idx=0;g1_idx=6;g2_idx=5;g3_idx=4;g4_idx=3;over=0; end
				330:begin g0_idx=4;g1_idx=5;g2_idx=6;g3_idx=3;g4_idx=0;over=0; end
				331:begin g0_idx=5;g1_idx=4;g2_idx=6;g3_idx=3;g4_idx=0;over=0; end
				332:begin g0_idx=4;g1_idx=6;g2_idx=5;g3_idx=3;g4_idx=0;over=0; end
				333:begin g0_idx=6;g1_idx=4;g2_idx=5;g3_idx=3;g4_idx=0;over=0; end
				334:begin g0_idx=5;g1_idx=6;g2_idx=4;g3_idx=3;g4_idx=0;over=0; end
				335:begin g0_idx=6;g1_idx=5;g2_idx=4;g3_idx=3;g4_idx=0;over=0; end
				336:begin g0_idx=3;g1_idx=1;g2_idx=4;g3_idx=5;g4_idx=6;over=0; end
				337:begin g0_idx=4;g1_idx=1;g2_idx=3;g3_idx=5;g4_idx=6;over=0; end
				338:begin g0_idx=3;g1_idx=1;g2_idx=5;g3_idx=4;g4_idx=6;over=0; end
				339:begin g0_idx=5;g1_idx=1;g2_idx=3;g3_idx=4;g4_idx=6;over=0; end
				340:begin g0_idx=1;g1_idx=4;g2_idx=5;g3_idx=3;g4_idx=6;over=0; end
				341:begin g0_idx=1;g1_idx=5;g2_idx=4;g3_idx=3;g4_idx=6;over=0; end
				342:begin g0_idx=4;g1_idx=5;g2_idx=1;g3_idx=3;g4_idx=6;over=0; end
				343:begin g0_idx=5;g1_idx=4;g2_idx=1;g3_idx=3;g4_idx=6;over=0; end
				344:begin g0_idx=3;g1_idx=1;g2_idx=4;g3_idx=6;g4_idx=5;over=0; end
				345:begin g0_idx=4;g1_idx=1;g2_idx=3;g3_idx=6;g4_idx=5;over=0; end
				346:begin g0_idx=3;g1_idx=1;g2_idx=6;g3_idx=4;g4_idx=5;over=0; end
				347:begin g0_idx=6;g1_idx=1;g2_idx=3;g3_idx=4;g4_idx=5;over=0; end
				348:begin g0_idx=1;g1_idx=4;g2_idx=6;g3_idx=3;g4_idx=5;over=0; end
				349:begin g0_idx=1;g1_idx=6;g2_idx=4;g3_idx=3;g4_idx=5;over=0; end
				350:begin g0_idx=4;g1_idx=6;g2_idx=1;g3_idx=3;g4_idx=5;over=0; end
				351:begin g0_idx=6;g1_idx=4;g2_idx=1;g3_idx=3;g4_idx=5;over=0; end
				352:begin g0_idx=1;g1_idx=3;g2_idx=5;g3_idx=6;g4_idx=4;over=0; end
				353:begin g0_idx=1;g1_idx=5;g2_idx=3;g3_idx=6;g4_idx=4;over=0; end
				354:begin g0_idx=3;g1_idx=5;g2_idx=1;g3_idx=6;g4_idx=4;over=0; end
				355:begin g0_idx=5;g1_idx=3;g2_idx=1;g3_idx=6;g4_idx=4;over=0; end
				356:begin g0_idx=1;g1_idx=3;g2_idx=6;g3_idx=5;g4_idx=4;over=0; end
				357:begin g0_idx=1;g1_idx=6;g2_idx=3;g3_idx=5;g4_idx=4;over=0; end
				358:begin g0_idx=3;g1_idx=6;g2_idx=1;g3_idx=5;g4_idx=4;over=0; end
				359:begin g0_idx=6;g1_idx=3;g2_idx=1;g3_idx=5;g4_idx=4;over=0; end
				360:begin g0_idx=3;g1_idx=5;g2_idx=6;g3_idx=1;g4_idx=4;over=0; end
				361:begin g0_idx=5;g1_idx=3;g2_idx=6;g3_idx=1;g4_idx=4;over=0; end
				362:begin g0_idx=3;g1_idx=6;g2_idx=5;g3_idx=1;g4_idx=4;over=0; end
				363:begin g0_idx=6;g1_idx=3;g2_idx=5;g3_idx=1;g4_idx=4;over=0; end
				364:begin g0_idx=5;g1_idx=6;g2_idx=3;g3_idx=1;g4_idx=4;over=0; end
				365:begin g0_idx=6;g1_idx=5;g2_idx=3;g3_idx=1;g4_idx=4;over=0; end
				366:begin g0_idx=4;g1_idx=1;g2_idx=5;g3_idx=6;g4_idx=3;over=0; end
				367:begin g0_idx=5;g1_idx=1;g2_idx=4;g3_idx=6;g4_idx=3;over=0; end
				368:begin g0_idx=4;g1_idx=1;g2_idx=6;g3_idx=5;g4_idx=3;over=0; end
				369:begin g0_idx=6;g1_idx=1;g2_idx=4;g3_idx=5;g4_idx=3;over=0; end
				370:begin g0_idx=5;g1_idx=1;g2_idx=6;g3_idx=4;g4_idx=3;over=0; end
				371:begin g0_idx=6;g1_idx=1;g2_idx=5;g3_idx=4;g4_idx=3;over=0; end
				372:begin g0_idx=4;g1_idx=5;g2_idx=6;g3_idx=3;g4_idx=1;over=0; end
				373:begin g0_idx=5;g1_idx=4;g2_idx=6;g3_idx=3;g4_idx=1;over=0; end
				374:begin g0_idx=4;g1_idx=6;g2_idx=5;g3_idx=3;g4_idx=1;over=0; end
				375:begin g0_idx=6;g1_idx=4;g2_idx=5;g3_idx=3;g4_idx=1;over=0; end
				376:begin g0_idx=5;g1_idx=6;g2_idx=4;g3_idx=3;g4_idx=1;over=0; end
				377:begin g0_idx=6;g1_idx=5;g2_idx=4;g3_idx=3;g4_idx=1;over=0; end
				378:begin g0_idx=3;g1_idx=4;g2_idx=2;g3_idx=5;g4_idx=6;over=0; end
				379:begin g0_idx=4;g1_idx=3;g2_idx=2;g3_idx=5;g4_idx=6;over=0; end
				380:begin g0_idx=3;g1_idx=5;g2_idx=2;g3_idx=4;g4_idx=6;over=0; end
				381:begin g0_idx=5;g1_idx=3;g2_idx=2;g3_idx=4;g4_idx=6;over=0; end
				382:begin g0_idx=2;g1_idx=4;g2_idx=5;g3_idx=3;g4_idx=6;over=0; end
				383:begin g0_idx=4;g1_idx=2;g2_idx=5;g3_idx=3;g4_idx=6;over=0; end
				384:begin g0_idx=2;g1_idx=5;g2_idx=4;g3_idx=3;g4_idx=6;over=0; end
				385:begin g0_idx=5;g1_idx=2;g2_idx=4;g3_idx=3;g4_idx=6;over=0; end
				386:begin g0_idx=3;g1_idx=4;g2_idx=2;g3_idx=6;g4_idx=5;over=0; end
				387:begin g0_idx=4;g1_idx=3;g2_idx=2;g3_idx=6;g4_idx=5;over=0; end
				388:begin g0_idx=3;g1_idx=6;g2_idx=2;g3_idx=4;g4_idx=5;over=0; end
				389:begin g0_idx=6;g1_idx=3;g2_idx=2;g3_idx=4;g4_idx=5;over=0; end
				390:begin g0_idx=2;g1_idx=4;g2_idx=6;g3_idx=3;g4_idx=5;over=0; end
				391:begin g0_idx=4;g1_idx=2;g2_idx=6;g3_idx=3;g4_idx=5;over=0; end
				392:begin g0_idx=2;g1_idx=6;g2_idx=4;g3_idx=3;g4_idx=5;over=0; end
				393:begin g0_idx=6;g1_idx=2;g2_idx=4;g3_idx=3;g4_idx=5;over=0; end
				394:begin g0_idx=2;g1_idx=3;g2_idx=5;g3_idx=6;g4_idx=4;over=0; end
				395:begin g0_idx=3;g1_idx=2;g2_idx=5;g3_idx=6;g4_idx=4;over=0; end
				396:begin g0_idx=2;g1_idx=5;g2_idx=3;g3_idx=6;g4_idx=4;over=0; end
				397:begin g0_idx=5;g1_idx=2;g2_idx=3;g3_idx=6;g4_idx=4;over=0; end
				398:begin g0_idx=2;g1_idx=3;g2_idx=6;g3_idx=5;g4_idx=4;over=0; end
				399:begin g0_idx=3;g1_idx=2;g2_idx=6;g3_idx=5;g4_idx=4;over=0; end
				400:begin g0_idx=2;g1_idx=6;g2_idx=3;g3_idx=5;g4_idx=4;over=0; end
				401:begin g0_idx=6;g1_idx=2;g2_idx=3;g3_idx=5;g4_idx=4;over=0; end
				402:begin g0_idx=3;g1_idx=5;g2_idx=6;g3_idx=2;g4_idx=4;over=0; end
				403:begin g0_idx=5;g1_idx=3;g2_idx=6;g3_idx=2;g4_idx=4;over=0; end
				404:begin g0_idx=3;g1_idx=6;g2_idx=5;g3_idx=2;g4_idx=4;over=0; end
				405:begin g0_idx=6;g1_idx=3;g2_idx=5;g3_idx=2;g4_idx=4;over=0; end
				406:begin g0_idx=5;g1_idx=6;g2_idx=3;g3_idx=2;g4_idx=4;over=0; end
				407:begin g0_idx=6;g1_idx=5;g2_idx=3;g3_idx=2;g4_idx=4;over=0; end
				408:begin g0_idx=4;g1_idx=5;g2_idx=2;g3_idx=6;g4_idx=3;over=0; end
				409:begin g0_idx=5;g1_idx=4;g2_idx=2;g3_idx=6;g4_idx=3;over=0; end
				410:begin g0_idx=4;g1_idx=6;g2_idx=2;g3_idx=5;g4_idx=3;over=0; end
				411:begin g0_idx=6;g1_idx=4;g2_idx=2;g3_idx=5;g4_idx=3;over=0; end
				412:begin g0_idx=5;g1_idx=6;g2_idx=2;g3_idx=4;g4_idx=3;over=0; end
				413:begin g0_idx=6;g1_idx=5;g2_idx=2;g3_idx=4;g4_idx=3;over=0; end
				414:begin g0_idx=4;g1_idx=5;g2_idx=6;g3_idx=3;g4_idx=2;over=0; end
				415:begin g0_idx=5;g1_idx=4;g2_idx=6;g3_idx=3;g4_idx=2;over=0; end
				416:begin g0_idx=4;g1_idx=6;g2_idx=5;g3_idx=3;g4_idx=2;over=0; end
				417:begin g0_idx=6;g1_idx=4;g2_idx=5;g3_idx=3;g4_idx=2;over=0; end
				418:begin g0_idx=5;g1_idx=6;g2_idx=4;g3_idx=3;g4_idx=2;over=0; end
				419:begin g0_idx=6;g1_idx=5;g2_idx=4;g3_idx=3;g4_idx=2;over=0; end		
		
				default :begin
					g0_idx=3'bx;    g1_idx=3'bx;    g2_idx=3'bx;    g3_idx=3'bx;    g4_idx=3'bx; over=1;
				end
			endcase			
		6'o13:
			case(inspect_vector)
				0:begin g0_idx=2;g1_idx=0;g2_idx=1;g3_idx=3;g4_idx=5;over=0; end
				1:begin g0_idx=1;g1_idx=2;g2_idx=0;g3_idx=3;g4_idx=5;over=0; end
				2:begin g0_idx=0;g1_idx=3;g2_idx=1;g3_idx=2;g4_idx=5;over=0; end
				3:begin g0_idx=3;g1_idx=1;g2_idx=0;g3_idx=2;g4_idx=5;over=0; end
				4:begin g0_idx=0;g1_idx=2;g2_idx=3;g3_idx=1;g4_idx=5;over=0; end
				5:begin g0_idx=3;g1_idx=0;g2_idx=2;g3_idx=1;g4_idx=5;over=0; end
				6:begin g0_idx=2;g1_idx=1;g2_idx=3;g3_idx=0;g4_idx=5;over=0; end
				7:begin g0_idx=1;g1_idx=3;g2_idx=2;g3_idx=0;g4_idx=5;over=0; end
				8:begin g0_idx=1;g1_idx=0;g2_idx=2;g3_idx=5;g4_idx=3;over=0; end
				9:begin g0_idx=0;g1_idx=2;g2_idx=1;g3_idx=5;g4_idx=3;over=0; end
				10:begin g0_idx=2;g1_idx=1;g2_idx=0;g3_idx=5;g4_idx=3;over=0; end
				11:begin g0_idx=0;g1_idx=5;g2_idx=1;g3_idx=2;g4_idx=3;over=0; end
				12:begin g0_idx=5;g1_idx=1;g2_idx=0;g3_idx=2;g4_idx=3;over=0; end
				13:begin g0_idx=0;g1_idx=2;g2_idx=5;g3_idx=1;g4_idx=3;over=0; end
				14:begin g0_idx=5;g1_idx=0;g2_idx=2;g3_idx=1;g4_idx=3;over=0; end
				15:begin g0_idx=2;g1_idx=1;g2_idx=5;g3_idx=0;g4_idx=3;over=0; end
				16:begin g0_idx=1;g1_idx=5;g2_idx=2;g3_idx=0;g4_idx=3;over=0; end
				17:begin g0_idx=0;g1_idx=3;g2_idx=1;g3_idx=5;g4_idx=2;over=0; end
				18:begin g0_idx=3;g1_idx=1;g2_idx=0;g3_idx=5;g4_idx=2;over=0; end
				19:begin g0_idx=1;g1_idx=0;g2_idx=5;g3_idx=3;g4_idx=2;over=0; end
				20:begin g0_idx=5;g1_idx=0;g2_idx=1;g3_idx=3;g4_idx=2;over=0; end
				21:begin g0_idx=1;g1_idx=5;g2_idx=0;g3_idx=3;g4_idx=2;over=0; end
				22:begin g0_idx=0;g1_idx=3;g2_idx=5;g3_idx=1;g4_idx=2;over=0; end
				23:begin g0_idx=0;g1_idx=5;g2_idx=3;g3_idx=1;g4_idx=2;over=0; end
				24:begin g0_idx=3;g1_idx=1;g2_idx=5;g3_idx=0;g4_idx=2;over=0; end
				25:begin g0_idx=5;g1_idx=1;g2_idx=3;g3_idx=0;g4_idx=2;over=0; end
				26:begin g0_idx=0;g1_idx=2;g2_idx=3;g3_idx=5;g4_idx=1;over=0; end
				27:begin g0_idx=3;g1_idx=0;g2_idx=2;g3_idx=5;g4_idx=1;over=0; end
				28:begin g0_idx=2;g1_idx=0;g2_idx=5;g3_idx=3;g4_idx=1;over=0; end
				29:begin g0_idx=2;g1_idx=5;g2_idx=0;g3_idx=3;g4_idx=1;over=0; end
				30:begin g0_idx=5;g1_idx=2;g2_idx=0;g3_idx=3;g4_idx=1;over=0; end
				31:begin g0_idx=0;g1_idx=3;g2_idx=5;g3_idx=2;g4_idx=1;over=0; end
				32:begin g0_idx=0;g1_idx=5;g2_idx=3;g3_idx=2;g4_idx=1;over=0; end
				33:begin g0_idx=3;g1_idx=5;g2_idx=2;g3_idx=0;g4_idx=1;over=0; end
				34:begin g0_idx=5;g1_idx=3;g2_idx=2;g3_idx=0;g4_idx=1;over=0; end
				35:begin g0_idx=2;g1_idx=1;g2_idx=3;g3_idx=5;g4_idx=0;over=0; end
				36:begin g0_idx=1;g1_idx=3;g2_idx=2;g3_idx=5;g4_idx=0;over=0; end
				37:begin g0_idx=1;g1_idx=2;g2_idx=5;g3_idx=3;g4_idx=0;over=0; end
				38:begin g0_idx=2;g1_idx=5;g2_idx=1;g3_idx=3;g4_idx=0;over=0; end
				39:begin g0_idx=5;g1_idx=2;g2_idx=1;g3_idx=3;g4_idx=0;over=0; end
				40:begin g0_idx=3;g1_idx=1;g2_idx=5;g3_idx=2;g4_idx=0;over=0; end
				41:begin g0_idx=5;g1_idx=1;g2_idx=3;g3_idx=2;g4_idx=0;over=0; end
				42:begin g0_idx=3;g1_idx=5;g2_idx=2;g3_idx=1;g4_idx=0;over=0; end
				43:begin g0_idx=5;g1_idx=3;g2_idx=2;g3_idx=1;g4_idx=0;over=0; end
				44:begin g0_idx=1;g1_idx=0;g2_idx=2;g3_idx=4;g4_idx=5;over=0; end
				45:begin g0_idx=0;g1_idx=2;g2_idx=1;g3_idx=4;g4_idx=5;over=0; end
				46:begin g0_idx=2;g1_idx=1;g2_idx=0;g3_idx=4;g4_idx=5;over=0; end
				47:begin g0_idx=0;g1_idx=4;g2_idx=1;g3_idx=2;g4_idx=5;over=0; end
				48:begin g0_idx=4;g1_idx=1;g2_idx=0;g3_idx=2;g4_idx=5;over=0; end
				49:begin g0_idx=0;g1_idx=2;g2_idx=4;g3_idx=1;g4_idx=5;over=0; end
				50:begin g0_idx=4;g1_idx=0;g2_idx=2;g3_idx=1;g4_idx=5;over=0; end
				51:begin g0_idx=2;g1_idx=1;g2_idx=4;g3_idx=0;g4_idx=5;over=0; end
				52:begin g0_idx=1;g1_idx=4;g2_idx=2;g3_idx=0;g4_idx=5;over=0; end
				53:begin g0_idx=2;g1_idx=0;g2_idx=1;g3_idx=5;g4_idx=4;over=0; end
				54:begin g0_idx=1;g1_idx=2;g2_idx=0;g3_idx=5;g4_idx=4;over=0; end
				55:begin g0_idx=1;g1_idx=0;g2_idx=5;g3_idx=2;g4_idx=4;over=0; end
				56:begin g0_idx=5;g1_idx=0;g2_idx=1;g3_idx=2;g4_idx=4;over=0; end
				57:begin g0_idx=1;g1_idx=5;g2_idx=0;g3_idx=2;g4_idx=4;over=0; end
				58:begin g0_idx=2;g1_idx=0;g2_idx=5;g3_idx=1;g4_idx=4;over=0; end
				59:begin g0_idx=2;g1_idx=5;g2_idx=0;g3_idx=1;g4_idx=4;over=0; end
				60:begin g0_idx=5;g1_idx=2;g2_idx=0;g3_idx=1;g4_idx=4;over=0; end
				61:begin g0_idx=1;g1_idx=2;g2_idx=5;g3_idx=0;g4_idx=4;over=0; end
				62:begin g0_idx=2;g1_idx=5;g2_idx=1;g3_idx=0;g4_idx=4;over=0; end
				63:begin g0_idx=5;g1_idx=2;g2_idx=1;g3_idx=0;g4_idx=4;over=0; end
				64:begin g0_idx=0;g1_idx=4;g2_idx=1;g3_idx=5;g4_idx=2;over=0; end
				65:begin g0_idx=4;g1_idx=1;g2_idx=0;g3_idx=5;g4_idx=2;over=0; end
				66:begin g0_idx=0;g1_idx=5;g2_idx=1;g3_idx=4;g4_idx=2;over=0; end
				67:begin g0_idx=5;g1_idx=1;g2_idx=0;g3_idx=4;g4_idx=2;over=0; end
				68:begin g0_idx=0;g1_idx=4;g2_idx=5;g3_idx=1;g4_idx=2;over=0; end
				69:begin g0_idx=0;g1_idx=5;g2_idx=4;g3_idx=1;g4_idx=2;over=0; end
				70:begin g0_idx=4;g1_idx=1;g2_idx=5;g3_idx=0;g4_idx=2;over=0; end
				71:begin g0_idx=5;g1_idx=1;g2_idx=4;g3_idx=0;g4_idx=2;over=0; end
				72:begin g0_idx=0;g1_idx=2;g2_idx=4;g3_idx=5;g4_idx=1;over=0; end
				73:begin g0_idx=4;g1_idx=0;g2_idx=2;g3_idx=5;g4_idx=1;over=0; end
				74:begin g0_idx=0;g1_idx=2;g2_idx=5;g3_idx=4;g4_idx=1;over=0; end
				75:begin g0_idx=5;g1_idx=0;g2_idx=2;g3_idx=4;g4_idx=1;over=0; end
				76:begin g0_idx=0;g1_idx=4;g2_idx=5;g3_idx=2;g4_idx=1;over=0; end
				77:begin g0_idx=0;g1_idx=5;g2_idx=4;g3_idx=2;g4_idx=1;over=0; end
				78:begin g0_idx=4;g1_idx=5;g2_idx=2;g3_idx=0;g4_idx=1;over=0; end
				79:begin g0_idx=5;g1_idx=4;g2_idx=2;g3_idx=0;g4_idx=1;over=0; end
				80:begin g0_idx=2;g1_idx=1;g2_idx=4;g3_idx=5;g4_idx=0;over=0; end
				81:begin g0_idx=1;g1_idx=4;g2_idx=2;g3_idx=5;g4_idx=0;over=0; end
				82:begin g0_idx=2;g1_idx=1;g2_idx=5;g3_idx=4;g4_idx=0;over=0; end
				83:begin g0_idx=1;g1_idx=5;g2_idx=2;g3_idx=4;g4_idx=0;over=0; end
				84:begin g0_idx=4;g1_idx=1;g2_idx=5;g3_idx=2;g4_idx=0;over=0; end
				85:begin g0_idx=5;g1_idx=1;g2_idx=4;g3_idx=2;g4_idx=0;over=0; end
				86:begin g0_idx=4;g1_idx=5;g2_idx=2;g3_idx=1;g4_idx=0;over=0; end
				87:begin g0_idx=5;g1_idx=4;g2_idx=2;g3_idx=1;g4_idx=0;over=0; end
				88:begin g0_idx=0;g1_idx=3;g2_idx=1;g3_idx=4;g4_idx=5;over=0; end
				89:begin g0_idx=3;g1_idx=1;g2_idx=0;g3_idx=4;g4_idx=5;over=0; end
				90:begin g0_idx=1;g1_idx=0;g2_idx=4;g3_idx=3;g4_idx=5;over=0; end
				91:begin g0_idx=4;g1_idx=0;g2_idx=1;g3_idx=3;g4_idx=5;over=0; end
				92:begin g0_idx=1;g1_idx=4;g2_idx=0;g3_idx=3;g4_idx=5;over=0; end
				93:begin g0_idx=0;g1_idx=3;g2_idx=4;g3_idx=1;g4_idx=5;over=0; end
				94:begin g0_idx=0;g1_idx=4;g2_idx=3;g3_idx=1;g4_idx=5;over=0; end
				95:begin g0_idx=3;g1_idx=1;g2_idx=4;g3_idx=0;g4_idx=5;over=0; end
				96:begin g0_idx=4;g1_idx=1;g2_idx=3;g3_idx=0;g4_idx=5;over=0; end
				97:begin g0_idx=1;g1_idx=0;g2_idx=3;g3_idx=5;g4_idx=4;over=0; end
				98:begin g0_idx=3;g1_idx=0;g2_idx=1;g3_idx=5;g4_idx=4;over=0; end
				99:begin g0_idx=1;g1_idx=3;g2_idx=0;g3_idx=5;g4_idx=4;over=0; end
				100:begin g0_idx=3;g1_idx=0;g2_idx=5;g3_idx=1;g4_idx=4;over=0; end
				101:begin g0_idx=5;g1_idx=0;g2_idx=3;g3_idx=1;g4_idx=4;over=0; end
				102:begin g0_idx=3;g1_idx=5;g2_idx=0;g3_idx=1;g4_idx=4;over=0; end
				103:begin g0_idx=5;g1_idx=3;g2_idx=0;g3_idx=1;g4_idx=4;over=0; end
				104:begin g0_idx=1;g1_idx=3;g2_idx=5;g3_idx=0;g4_idx=4;over=0; end
				105:begin g0_idx=1;g1_idx=5;g2_idx=3;g3_idx=0;g4_idx=4;over=0; end
				106:begin g0_idx=3;g1_idx=5;g2_idx=1;g3_idx=0;g4_idx=4;over=0; end
				107:begin g0_idx=5;g1_idx=3;g2_idx=1;g3_idx=0;g4_idx=4;over=0; end
				108:begin g0_idx=0;g1_idx=4;g2_idx=1;g3_idx=5;g4_idx=3;over=0; end
				109:begin g0_idx=4;g1_idx=1;g2_idx=0;g3_idx=5;g4_idx=3;over=0; end
				110:begin g0_idx=0;g1_idx=5;g2_idx=1;g3_idx=4;g4_idx=3;over=0; end
				111:begin g0_idx=5;g1_idx=1;g2_idx=0;g3_idx=4;g4_idx=3;over=0; end
				112:begin g0_idx=0;g1_idx=4;g2_idx=5;g3_idx=1;g4_idx=3;over=0; end
				113:begin g0_idx=0;g1_idx=5;g2_idx=4;g3_idx=1;g4_idx=3;over=0; end
				114:begin g0_idx=4;g1_idx=1;g2_idx=5;g3_idx=0;g4_idx=3;over=0; end
				115:begin g0_idx=5;g1_idx=1;g2_idx=4;g3_idx=0;g4_idx=3;over=0; end
				116:begin g0_idx=0;g1_idx=3;g2_idx=4;g3_idx=5;g4_idx=1;over=0; end
				117:begin g0_idx=0;g1_idx=4;g2_idx=3;g3_idx=5;g4_idx=1;over=0; end
				118:begin g0_idx=0;g1_idx=3;g2_idx=5;g3_idx=4;g4_idx=1;over=0; end
				119:begin g0_idx=0;g1_idx=5;g2_idx=3;g3_idx=4;g4_idx=1;over=0; end
				120:begin g0_idx=4;g1_idx=0;g2_idx=5;g3_idx=3;g4_idx=1;over=0; end
				121:begin g0_idx=5;g1_idx=0;g2_idx=4;g3_idx=3;g4_idx=1;over=0; end
				122:begin g0_idx=4;g1_idx=5;g2_idx=0;g3_idx=3;g4_idx=1;over=0; end
				123:begin g0_idx=5;g1_idx=4;g2_idx=0;g3_idx=3;g4_idx=1;over=0; end
				124:begin g0_idx=3;g1_idx=1;g2_idx=4;g3_idx=5;g4_idx=0;over=0; end
				125:begin g0_idx=4;g1_idx=1;g2_idx=3;g3_idx=5;g4_idx=0;over=0; end
				126:begin g0_idx=3;g1_idx=1;g2_idx=5;g3_idx=4;g4_idx=0;over=0; end
				127:begin g0_idx=5;g1_idx=1;g2_idx=3;g3_idx=4;g4_idx=0;over=0; end
				128:begin g0_idx=1;g1_idx=4;g2_idx=5;g3_idx=3;g4_idx=0;over=0; end
				129:begin g0_idx=1;g1_idx=5;g2_idx=4;g3_idx=3;g4_idx=0;over=0; end
				130:begin g0_idx=4;g1_idx=5;g2_idx=1;g3_idx=3;g4_idx=0;over=0; end
				131:begin g0_idx=5;g1_idx=4;g2_idx=1;g3_idx=3;g4_idx=0;over=0; end
				132:begin g0_idx=0;g1_idx=2;g2_idx=3;g3_idx=4;g4_idx=5;over=0; end
				133:begin g0_idx=3;g1_idx=0;g2_idx=2;g3_idx=4;g4_idx=5;over=0; end
				134:begin g0_idx=2;g1_idx=0;g2_idx=4;g3_idx=3;g4_idx=5;over=0; end
				135:begin g0_idx=2;g1_idx=4;g2_idx=0;g3_idx=3;g4_idx=5;over=0; end
				136:begin g0_idx=4;g1_idx=2;g2_idx=0;g3_idx=3;g4_idx=5;over=0; end
				137:begin g0_idx=0;g1_idx=3;g2_idx=4;g3_idx=2;g4_idx=5;over=0; end
				138:begin g0_idx=0;g1_idx=4;g2_idx=3;g3_idx=2;g4_idx=5;over=0; end
				139:begin g0_idx=3;g1_idx=4;g2_idx=2;g3_idx=0;g4_idx=5;over=0; end
				140:begin g0_idx=4;g1_idx=3;g2_idx=2;g3_idx=0;g4_idx=5;over=0; end
				141:begin g0_idx=2;g1_idx=0;g2_idx=3;g3_idx=5;g4_idx=4;over=0; end
				142:begin g0_idx=2;g1_idx=3;g2_idx=0;g3_idx=5;g4_idx=4;over=0; end
				143:begin g0_idx=3;g1_idx=2;g2_idx=0;g3_idx=5;g4_idx=4;over=0; end
				144:begin g0_idx=3;g1_idx=0;g2_idx=5;g3_idx=2;g4_idx=4;over=0; end
				145:begin g0_idx=5;g1_idx=0;g2_idx=3;g3_idx=2;g4_idx=4;over=0; end
				146:begin g0_idx=3;g1_idx=5;g2_idx=0;g3_idx=2;g4_idx=4;over=0; end
				147:begin g0_idx=5;g1_idx=3;g2_idx=0;g3_idx=2;g4_idx=4;over=0; end
				148:begin g0_idx=2;g1_idx=3;g2_idx=5;g3_idx=0;g4_idx=4;over=0; end
				149:begin g0_idx=3;g1_idx=2;g2_idx=5;g3_idx=0;g4_idx=4;over=0; end
				150:begin g0_idx=2;g1_idx=5;g2_idx=3;g3_idx=0;g4_idx=4;over=0; end
				151:begin g0_idx=5;g1_idx=2;g2_idx=3;g3_idx=0;g4_idx=4;over=0; end
				152:begin g0_idx=0;g1_idx=2;g2_idx=4;g3_idx=5;g4_idx=3;over=0; end
				153:begin g0_idx=4;g1_idx=0;g2_idx=2;g3_idx=5;g4_idx=3;over=0; end
				154:begin g0_idx=0;g1_idx=2;g2_idx=5;g3_idx=4;g4_idx=3;over=0; end
				155:begin g0_idx=5;g1_idx=0;g2_idx=2;g3_idx=4;g4_idx=3;over=0; end
				156:begin g0_idx=0;g1_idx=4;g2_idx=5;g3_idx=2;g4_idx=3;over=0; end
				157:begin g0_idx=0;g1_idx=5;g2_idx=4;g3_idx=2;g4_idx=3;over=0; end
				158:begin g0_idx=4;g1_idx=5;g2_idx=2;g3_idx=0;g4_idx=3;over=0; end
				159:begin g0_idx=5;g1_idx=4;g2_idx=2;g3_idx=0;g4_idx=3;over=0; end
				160:begin g0_idx=0;g1_idx=3;g2_idx=4;g3_idx=5;g4_idx=2;over=0; end
				161:begin g0_idx=0;g1_idx=4;g2_idx=3;g3_idx=5;g4_idx=2;over=0; end
				162:begin g0_idx=0;g1_idx=3;g2_idx=5;g3_idx=4;g4_idx=2;over=0; end
				163:begin g0_idx=0;g1_idx=5;g2_idx=3;g3_idx=4;g4_idx=2;over=0; end
				164:begin g0_idx=4;g1_idx=0;g2_idx=5;g3_idx=3;g4_idx=2;over=0; end
				165:begin g0_idx=5;g1_idx=0;g2_idx=4;g3_idx=3;g4_idx=2;over=0; end
				166:begin g0_idx=4;g1_idx=5;g2_idx=0;g3_idx=3;g4_idx=2;over=0; end
				167:begin g0_idx=5;g1_idx=4;g2_idx=0;g3_idx=3;g4_idx=2;over=0; end
				168:begin g0_idx=3;g1_idx=4;g2_idx=2;g3_idx=5;g4_idx=0;over=0; end
				169:begin g0_idx=4;g1_idx=3;g2_idx=2;g3_idx=5;g4_idx=0;over=0; end
				170:begin g0_idx=3;g1_idx=5;g2_idx=2;g3_idx=4;g4_idx=0;over=0; end
				171:begin g0_idx=5;g1_idx=3;g2_idx=2;g3_idx=4;g4_idx=0;over=0; end
				172:begin g0_idx=2;g1_idx=4;g2_idx=5;g3_idx=3;g4_idx=0;over=0; end
				173:begin g0_idx=4;g1_idx=2;g2_idx=5;g3_idx=3;g4_idx=0;over=0; end
				174:begin g0_idx=2;g1_idx=5;g2_idx=4;g3_idx=3;g4_idx=0;over=0; end
				175:begin g0_idx=5;g1_idx=2;g2_idx=4;g3_idx=3;g4_idx=0;over=0; end
				176:begin g0_idx=2;g1_idx=1;g2_idx=3;g3_idx=4;g4_idx=5;over=0; end
				177:begin g0_idx=1;g1_idx=3;g2_idx=2;g3_idx=4;g4_idx=5;over=0; end
				178:begin g0_idx=1;g1_idx=2;g2_idx=4;g3_idx=3;g4_idx=5;over=0; end
				179:begin g0_idx=2;g1_idx=4;g2_idx=1;g3_idx=3;g4_idx=5;over=0; end
				180:begin g0_idx=4;g1_idx=2;g2_idx=1;g3_idx=3;g4_idx=5;over=0; end
				181:begin g0_idx=3;g1_idx=1;g2_idx=4;g3_idx=2;g4_idx=5;over=0; end
				182:begin g0_idx=4;g1_idx=1;g2_idx=3;g3_idx=2;g4_idx=5;over=0; end
				183:begin g0_idx=3;g1_idx=4;g2_idx=2;g3_idx=1;g4_idx=5;over=0; end
				184:begin g0_idx=4;g1_idx=3;g2_idx=2;g3_idx=1;g4_idx=5;over=0; end
				185:begin g0_idx=1;g1_idx=2;g2_idx=3;g3_idx=5;g4_idx=4;over=0; end
				186:begin g0_idx=2;g1_idx=3;g2_idx=1;g3_idx=5;g4_idx=4;over=0; end
				187:begin g0_idx=3;g1_idx=2;g2_idx=1;g3_idx=5;g4_idx=4;over=0; end
				188:begin g0_idx=1;g1_idx=3;g2_idx=5;g3_idx=2;g4_idx=4;over=0; end
				189:begin g0_idx=1;g1_idx=5;g2_idx=3;g3_idx=2;g4_idx=4;over=0; end
				190:begin g0_idx=3;g1_idx=5;g2_idx=1;g3_idx=2;g4_idx=4;over=0; end
				191:begin g0_idx=5;g1_idx=3;g2_idx=1;g3_idx=2;g4_idx=4;over=0; end
				192:begin g0_idx=2;g1_idx=3;g2_idx=5;g3_idx=1;g4_idx=4;over=0; end
				193:begin g0_idx=3;g1_idx=2;g2_idx=5;g3_idx=1;g4_idx=4;over=0; end
				194:begin g0_idx=2;g1_idx=5;g2_idx=3;g3_idx=1;g4_idx=4;over=0; end
				195:begin g0_idx=5;g1_idx=2;g2_idx=3;g3_idx=1;g4_idx=4;over=0; end
				196:begin g0_idx=2;g1_idx=1;g2_idx=4;g3_idx=5;g4_idx=3;over=0; end
				197:begin g0_idx=1;g1_idx=4;g2_idx=2;g3_idx=5;g4_idx=3;over=0; end
				198:begin g0_idx=2;g1_idx=1;g2_idx=5;g3_idx=4;g4_idx=3;over=0; end
				199:begin g0_idx=1;g1_idx=5;g2_idx=2;g3_idx=4;g4_idx=3;over=0; end
				200:begin g0_idx=4;g1_idx=1;g2_idx=5;g3_idx=2;g4_idx=3;over=0; end
				201:begin g0_idx=5;g1_idx=1;g2_idx=4;g3_idx=2;g4_idx=3;over=0; end
				202:begin g0_idx=4;g1_idx=5;g2_idx=2;g3_idx=1;g4_idx=3;over=0; end
				203:begin g0_idx=5;g1_idx=4;g2_idx=2;g3_idx=1;g4_idx=3;over=0; end
				204:begin g0_idx=3;g1_idx=1;g2_idx=4;g3_idx=5;g4_idx=2;over=0; end
				205:begin g0_idx=4;g1_idx=1;g2_idx=3;g3_idx=5;g4_idx=2;over=0; end
				206:begin g0_idx=3;g1_idx=1;g2_idx=5;g3_idx=4;g4_idx=2;over=0; end
				207:begin g0_idx=5;g1_idx=1;g2_idx=3;g3_idx=4;g4_idx=2;over=0; end
				208:begin g0_idx=1;g1_idx=4;g2_idx=5;g3_idx=3;g4_idx=2;over=0; end
				209:begin g0_idx=1;g1_idx=5;g2_idx=4;g3_idx=3;g4_idx=2;over=0; end
				210:begin g0_idx=4;g1_idx=5;g2_idx=1;g3_idx=3;g4_idx=2;over=0; end
				211:begin g0_idx=5;g1_idx=4;g2_idx=1;g3_idx=3;g4_idx=2;over=0; end
				212:begin g0_idx=3;g1_idx=4;g2_idx=2;g3_idx=5;g4_idx=1;over=0; end
				213:begin g0_idx=4;g1_idx=3;g2_idx=2;g3_idx=5;g4_idx=1;over=0; end
				214:begin g0_idx=3;g1_idx=5;g2_idx=2;g3_idx=4;g4_idx=1;over=0; end
				215:begin g0_idx=5;g1_idx=3;g2_idx=2;g3_idx=4;g4_idx=1;over=0; end
				216:begin g0_idx=2;g1_idx=4;g2_idx=5;g3_idx=3;g4_idx=1;over=0; end
				217:begin g0_idx=4;g1_idx=2;g2_idx=5;g3_idx=3;g4_idx=1;over=0; end
				218:begin g0_idx=2;g1_idx=5;g2_idx=4;g3_idx=3;g4_idx=1;over=0; end
				219:begin g0_idx=5;g1_idx=2;g2_idx=4;g3_idx=3;g4_idx=1;over=0; end
				default :begin
					g0_idx=3'bx;    g1_idx=3'bx;    g2_idx=3'bx;    g3_idx=3'bx;    g4_idx=3'bx; over=1;
				end	
			endcase
		6'o14:
			case(inspect_vector)
				0:begin g0_idx=1;g1_idx=0;g2_idx=3;g3_idx=2;g4_idx=4;over=0; end
				1:begin g0_idx=3;g1_idx=0;g2_idx=1;g3_idx=2;g4_idx=4;over=0; end
				2:begin g0_idx=1;g1_idx=3;g2_idx=0;g3_idx=2;g4_idx=4;over=0; end
				3:begin g0_idx=2;g1_idx=0;g2_idx=3;g3_idx=1;g4_idx=4;over=0; end
				4:begin g0_idx=2;g1_idx=3;g2_idx=0;g3_idx=1;g4_idx=4;over=0; end
				5:begin g0_idx=3;g1_idx=2;g2_idx=0;g3_idx=1;g4_idx=4;over=0; end
				6:begin g0_idx=1;g1_idx=2;g2_idx=3;g3_idx=0;g4_idx=4;over=0; end
				7:begin g0_idx=2;g1_idx=3;g2_idx=1;g3_idx=0;g4_idx=4;over=0; end
				8:begin g0_idx=3;g1_idx=2;g2_idx=1;g3_idx=0;g4_idx=4;over=0; end
				9:begin g0_idx=1;g1_idx=0;g2_idx=2;g3_idx=4;g4_idx=3;over=0; end
				10:begin g0_idx=0;g1_idx=2;g2_idx=1;g3_idx=4;g4_idx=3;over=0; end
				11:begin g0_idx=2;g1_idx=1;g2_idx=0;g3_idx=4;g4_idx=3;over=0; end
				12:begin g0_idx=0;g1_idx=4;g2_idx=1;g3_idx=2;g4_idx=3;over=0; end
				13:begin g0_idx=4;g1_idx=1;g2_idx=0;g3_idx=2;g4_idx=3;over=0; end
				14:begin g0_idx=0;g1_idx=2;g2_idx=4;g3_idx=1;g4_idx=3;over=0; end
				15:begin g0_idx=4;g1_idx=0;g2_idx=2;g3_idx=1;g4_idx=3;over=0; end
				16:begin g0_idx=2;g1_idx=1;g2_idx=4;g3_idx=0;g4_idx=3;over=0; end
				17:begin g0_idx=1;g1_idx=4;g2_idx=2;g3_idx=0;g4_idx=3;over=0; end
				18:begin g0_idx=0;g1_idx=3;g2_idx=1;g3_idx=4;g4_idx=2;over=0; end
				19:begin g0_idx=3;g1_idx=1;g2_idx=0;g3_idx=4;g4_idx=2;over=0; end
				20:begin g0_idx=1;g1_idx=0;g2_idx=4;g3_idx=3;g4_idx=2;over=0; end
				21:begin g0_idx=4;g1_idx=0;g2_idx=1;g3_idx=3;g4_idx=2;over=0; end
				22:begin g0_idx=1;g1_idx=4;g2_idx=0;g3_idx=3;g4_idx=2;over=0; end
				23:begin g0_idx=0;g1_idx=3;g2_idx=4;g3_idx=1;g4_idx=2;over=0; end
				24:begin g0_idx=0;g1_idx=4;g2_idx=3;g3_idx=1;g4_idx=2;over=0; end
				25:begin g0_idx=3;g1_idx=1;g2_idx=4;g3_idx=0;g4_idx=2;over=0; end
				26:begin g0_idx=4;g1_idx=1;g2_idx=3;g3_idx=0;g4_idx=2;over=0; end
				27:begin g0_idx=0;g1_idx=2;g2_idx=3;g3_idx=4;g4_idx=1;over=0; end
				28:begin g0_idx=3;g1_idx=0;g2_idx=2;g3_idx=4;g4_idx=1;over=0; end
				29:begin g0_idx=2;g1_idx=0;g2_idx=4;g3_idx=3;g4_idx=1;over=0; end
				30:begin g0_idx=2;g1_idx=4;g2_idx=0;g3_idx=3;g4_idx=1;over=0; end
				31:begin g0_idx=4;g1_idx=2;g2_idx=0;g3_idx=3;g4_idx=1;over=0; end
				32:begin g0_idx=0;g1_idx=3;g2_idx=4;g3_idx=2;g4_idx=1;over=0; end
				33:begin g0_idx=0;g1_idx=4;g2_idx=3;g3_idx=2;g4_idx=1;over=0; end
				34:begin g0_idx=3;g1_idx=4;g2_idx=2;g3_idx=0;g4_idx=1;over=0; end
				35:begin g0_idx=4;g1_idx=3;g2_idx=2;g3_idx=0;g4_idx=1;over=0; end
				36:begin g0_idx=2;g1_idx=1;g2_idx=3;g3_idx=4;g4_idx=0;over=0; end
				37:begin g0_idx=1;g1_idx=3;g2_idx=2;g3_idx=4;g4_idx=0;over=0; end
				38:begin g0_idx=1;g1_idx=2;g2_idx=4;g3_idx=3;g4_idx=0;over=0; end
				39:begin g0_idx=2;g1_idx=4;g2_idx=1;g3_idx=3;g4_idx=0;over=0; end
				40:begin g0_idx=4;g1_idx=2;g2_idx=1;g3_idx=3;g4_idx=0;over=0; end
				41:begin g0_idx=3;g1_idx=1;g2_idx=4;g3_idx=2;g4_idx=0;over=0; end
				42:begin g0_idx=4;g1_idx=1;g2_idx=3;g3_idx=2;g4_idx=0;over=0; end
				43:begin g0_idx=3;g1_idx=4;g2_idx=2;g3_idx=1;g4_idx=0;over=0; end
				44:begin g0_idx=4;g1_idx=3;g2_idx=2;g3_idx=1;g4_idx=0;over=0; end
		
				default :begin
					g0_idx=3'bx;    g1_idx=3'bx;    g2_idx=3'bx;    g3_idx=3'bx;    g4_idx=3'bx; over=1;
				end	
			endcase
		6'o20:
			case(inspect_vector)
				0:begin g0_idx=0;g1_idx=1;g2_idx=5;g3_idx=6;g4_idx=7;over=0; end
				1:begin g0_idx=0;g1_idx=1;g2_idx=6;g3_idx=5;g4_idx=7;over=0; end
				2:begin g0_idx=0;g1_idx=1;g2_idx=5;g3_idx=7;g4_idx=6;over=0; end
				3:begin g0_idx=0;g1_idx=1;g2_idx=7;g3_idx=5;g4_idx=6;over=0; end
				4:begin g0_idx=0;g1_idx=1;g2_idx=6;g3_idx=7;g4_idx=5;over=0; end
				5:begin g0_idx=0;g1_idx=1;g2_idx=7;g3_idx=6;g4_idx=5;over=0; end
				6:begin g0_idx=0;g1_idx=5;g2_idx=2;g3_idx=6;g4_idx=7;over=0; end
				7:begin g0_idx=0;g1_idx=6;g2_idx=2;g3_idx=5;g4_idx=7;over=0; end
				8:begin g0_idx=0;g1_idx=5;g2_idx=2;g3_idx=7;g4_idx=6;over=0; end
				9:begin g0_idx=0;g1_idx=7;g2_idx=2;g3_idx=5;g4_idx=6;over=0; end
				10:begin g0_idx=0;g1_idx=6;g2_idx=2;g3_idx=7;g4_idx=5;over=0; end
				11:begin g0_idx=0;g1_idx=7;g2_idx=2;g3_idx=6;g4_idx=5;over=0; end
				12:begin g0_idx=5;g1_idx=1;g2_idx=2;g3_idx=6;g4_idx=7;over=0; end
				13:begin g0_idx=6;g1_idx=1;g2_idx=2;g3_idx=5;g4_idx=7;over=0; end
				14:begin g0_idx=5;g1_idx=1;g2_idx=2;g3_idx=7;g4_idx=6;over=0; end
				15:begin g0_idx=7;g1_idx=1;g2_idx=2;g3_idx=5;g4_idx=6;over=0; end
				16:begin g0_idx=6;g1_idx=1;g2_idx=2;g3_idx=7;g4_idx=5;over=0; end
				17:begin g0_idx=7;g1_idx=1;g2_idx=2;g3_idx=6;g4_idx=5;over=0; end
				18:begin g0_idx=0;g1_idx=5;g2_idx=6;g3_idx=3;g4_idx=7;over=0; end
				19:begin g0_idx=0;g1_idx=6;g2_idx=5;g3_idx=3;g4_idx=7;over=0; end
				20:begin g0_idx=0;g1_idx=5;g2_idx=7;g3_idx=3;g4_idx=6;over=0; end
				21:begin g0_idx=0;g1_idx=7;g2_idx=5;g3_idx=3;g4_idx=6;over=0; end
				22:begin g0_idx=0;g1_idx=6;g2_idx=7;g3_idx=3;g4_idx=5;over=0; end
				23:begin g0_idx=0;g1_idx=7;g2_idx=6;g3_idx=3;g4_idx=5;over=0; end
				24:begin g0_idx=5;g1_idx=1;g2_idx=6;g3_idx=3;g4_idx=7;over=0; end
				25:begin g0_idx=6;g1_idx=1;g2_idx=5;g3_idx=3;g4_idx=7;over=0; end
				26:begin g0_idx=5;g1_idx=1;g2_idx=7;g3_idx=3;g4_idx=6;over=0; end
				27:begin g0_idx=7;g1_idx=1;g2_idx=5;g3_idx=3;g4_idx=6;over=0; end
				28:begin g0_idx=6;g1_idx=1;g2_idx=7;g3_idx=3;g4_idx=5;over=0; end
				29:begin g0_idx=7;g1_idx=1;g2_idx=6;g3_idx=3;g4_idx=5;over=0; end
				30:begin g0_idx=5;g1_idx=6;g2_idx=2;g3_idx=3;g4_idx=7;over=0; end
				31:begin g0_idx=6;g1_idx=5;g2_idx=2;g3_idx=3;g4_idx=7;over=0; end
				32:begin g0_idx=5;g1_idx=7;g2_idx=2;g3_idx=3;g4_idx=6;over=0; end
				33:begin g0_idx=7;g1_idx=5;g2_idx=2;g3_idx=3;g4_idx=6;over=0; end
				34:begin g0_idx=6;g1_idx=7;g2_idx=2;g3_idx=3;g4_idx=5;over=0; end
				35:begin g0_idx=7;g1_idx=6;g2_idx=2;g3_idx=3;g4_idx=5;over=0; end
				36:begin g0_idx=0;g1_idx=5;g2_idx=6;g3_idx=7;g4_idx=4;over=0; end
				37:begin g0_idx=0;g1_idx=6;g2_idx=5;g3_idx=7;g4_idx=4;over=0; end
				38:begin g0_idx=0;g1_idx=5;g2_idx=7;g3_idx=6;g4_idx=4;over=0; end
				39:begin g0_idx=0;g1_idx=7;g2_idx=5;g3_idx=6;g4_idx=4;over=0; end
				40:begin g0_idx=0;g1_idx=6;g2_idx=7;g3_idx=5;g4_idx=4;over=0; end
				41:begin g0_idx=0;g1_idx=7;g2_idx=6;g3_idx=5;g4_idx=4;over=0; end
				42:begin g0_idx=5;g1_idx=1;g2_idx=6;g3_idx=7;g4_idx=4;over=0; end
				43:begin g0_idx=6;g1_idx=1;g2_idx=5;g3_idx=7;g4_idx=4;over=0; end
				44:begin g0_idx=5;g1_idx=1;g2_idx=7;g3_idx=6;g4_idx=4;over=0; end
				45:begin g0_idx=7;g1_idx=1;g2_idx=5;g3_idx=6;g4_idx=4;over=0; end
				46:begin g0_idx=6;g1_idx=1;g2_idx=7;g3_idx=5;g4_idx=4;over=0; end
				47:begin g0_idx=7;g1_idx=1;g2_idx=6;g3_idx=5;g4_idx=4;over=0; end
				48:begin g0_idx=5;g1_idx=6;g2_idx=2;g3_idx=7;g4_idx=4;over=0; end
				49:begin g0_idx=6;g1_idx=5;g2_idx=2;g3_idx=7;g4_idx=4;over=0; end
				50:begin g0_idx=5;g1_idx=7;g2_idx=2;g3_idx=6;g4_idx=4;over=0; end
				51:begin g0_idx=7;g1_idx=5;g2_idx=2;g3_idx=6;g4_idx=4;over=0; end
				52:begin g0_idx=6;g1_idx=7;g2_idx=2;g3_idx=5;g4_idx=4;over=0; end
				53:begin g0_idx=7;g1_idx=6;g2_idx=2;g3_idx=5;g4_idx=4;over=0; end
				54:begin g0_idx=5;g1_idx=6;g2_idx=7;g3_idx=3;g4_idx=4;over=0; end
				55:begin g0_idx=6;g1_idx=5;g2_idx=7;g3_idx=3;g4_idx=4;over=0; end
				56:begin g0_idx=5;g1_idx=7;g2_idx=6;g3_idx=3;g4_idx=4;over=0; end
				57:begin g0_idx=7;g1_idx=5;g2_idx=6;g3_idx=3;g4_idx=4;over=0; end
				58:begin g0_idx=6;g1_idx=7;g2_idx=5;g3_idx=3;g4_idx=4;over=0; end
				59:begin g0_idx=7;g1_idx=6;g2_idx=5;g3_idx=3;g4_idx=4;over=0; end	
		
				default :begin
					g0_idx=3'bx;    g1_idx=3'bx;    g2_idx=3'bx;    g3_idx=3'bx;    g4_idx=3'bx; over=1;
				end	
			endcase
		6'o21:
			case(inspect_vector)
				0:begin g0_idx=0;g1_idx=1;g2_idx=5;g3_idx=2;g4_idx=6;over=0; end
				1:begin g0_idx=0;g1_idx=5;g2_idx=2;g3_idx=1;g4_idx=6;over=0; end
				2:begin g0_idx=5;g1_idx=1;g2_idx=2;g3_idx=0;g4_idx=6;over=0; end
				3:begin g0_idx=0;g1_idx=1;g2_idx=6;g3_idx=2;g4_idx=5;over=0; end
				4:begin g0_idx=0;g1_idx=6;g2_idx=2;g3_idx=1;g4_idx=5;over=0; end
				5:begin g0_idx=6;g1_idx=1;g2_idx=2;g3_idx=0;g4_idx=5;over=0; end
				6:begin g0_idx=0;g1_idx=1;g2_idx=5;g3_idx=6;g4_idx=2;over=0; end
				7:begin g0_idx=0;g1_idx=1;g2_idx=6;g3_idx=5;g4_idx=2;over=0; end
				8:begin g0_idx=0;g1_idx=5;g2_idx=2;g3_idx=6;g4_idx=1;over=0; end
				9:begin g0_idx=0;g1_idx=6;g2_idx=2;g3_idx=5;g4_idx=1;over=0; end
				10:begin g0_idx=5;g1_idx=1;g2_idx=2;g3_idx=6;g4_idx=0;over=0; end
				11:begin g0_idx=6;g1_idx=1;g2_idx=2;g3_idx=5;g4_idx=0;over=0; end
				12:begin g0_idx=0;g1_idx=1;g2_idx=3;g3_idx=5;g4_idx=6;over=0; end
				13:begin g0_idx=0;g1_idx=5;g2_idx=1;g3_idx=3;g4_idx=6;over=0; end
				14:begin g0_idx=5;g1_idx=1;g2_idx=0;g3_idx=3;g4_idx=6;over=0; end
				15:begin g0_idx=0;g1_idx=1;g2_idx=3;g3_idx=6;g4_idx=5;over=0; end
				16:begin g0_idx=0;g1_idx=6;g2_idx=1;g3_idx=3;g4_idx=5;over=0; end
				17:begin g0_idx=6;g1_idx=1;g2_idx=0;g3_idx=3;g4_idx=5;over=0; end
				18:begin g0_idx=0;g1_idx=1;g2_idx=5;g3_idx=6;g4_idx=3;over=0; end
				19:begin g0_idx=0;g1_idx=1;g2_idx=6;g3_idx=5;g4_idx=3;over=0; end
				20:begin g0_idx=0;g1_idx=5;g2_idx=6;g3_idx=3;g4_idx=1;over=0; end
				21:begin g0_idx=0;g1_idx=6;g2_idx=5;g3_idx=3;g4_idx=1;over=0; end
				22:begin g0_idx=5;g1_idx=1;g2_idx=6;g3_idx=3;g4_idx=0;over=0; end
				23:begin g0_idx=6;g1_idx=1;g2_idx=5;g3_idx=3;g4_idx=0;over=0; end
				24:begin g0_idx=0;g1_idx=3;g2_idx=2;g3_idx=5;g4_idx=6;over=0; end
				25:begin g0_idx=0;g1_idx=2;g2_idx=5;g3_idx=3;g4_idx=6;over=0; end
				26:begin g0_idx=5;g1_idx=0;g2_idx=2;g3_idx=3;g4_idx=6;over=0; end
				27:begin g0_idx=0;g1_idx=3;g2_idx=2;g3_idx=6;g4_idx=5;over=0; end
				28:begin g0_idx=0;g1_idx=2;g2_idx=6;g3_idx=3;g4_idx=5;over=0; end
				29:begin g0_idx=6;g1_idx=0;g2_idx=2;g3_idx=3;g4_idx=5;over=0; end
				30:begin g0_idx=0;g1_idx=5;g2_idx=2;g3_idx=6;g4_idx=3;over=0; end
				31:begin g0_idx=0;g1_idx=6;g2_idx=2;g3_idx=5;g4_idx=3;over=0; end
				32:begin g0_idx=0;g1_idx=5;g2_idx=6;g3_idx=3;g4_idx=2;over=0; end
				33:begin g0_idx=0;g1_idx=6;g2_idx=5;g3_idx=3;g4_idx=2;over=0; end
				34:begin g0_idx=5;g1_idx=6;g2_idx=2;g3_idx=3;g4_idx=0;over=0; end
				35:begin g0_idx=6;g1_idx=5;g2_idx=2;g3_idx=3;g4_idx=0;over=0; end
				36:begin g0_idx=3;g1_idx=1;g2_idx=2;g3_idx=5;g4_idx=6;over=0; end
				37:begin g0_idx=2;g1_idx=1;g2_idx=5;g3_idx=3;g4_idx=6;over=0; end
				38:begin g0_idx=1;g1_idx=5;g2_idx=2;g3_idx=3;g4_idx=6;over=0; end
				39:begin g0_idx=3;g1_idx=1;g2_idx=2;g3_idx=6;g4_idx=5;over=0; end
				40:begin g0_idx=2;g1_idx=1;g2_idx=6;g3_idx=3;g4_idx=5;over=0; end
				41:begin g0_idx=1;g1_idx=6;g2_idx=2;g3_idx=3;g4_idx=5;over=0; end
				42:begin g0_idx=5;g1_idx=1;g2_idx=2;g3_idx=6;g4_idx=3;over=0; end
				43:begin g0_idx=6;g1_idx=1;g2_idx=2;g3_idx=5;g4_idx=3;over=0; end
				44:begin g0_idx=5;g1_idx=1;g2_idx=6;g3_idx=3;g4_idx=2;over=0; end
				45:begin g0_idx=6;g1_idx=1;g2_idx=5;g3_idx=3;g4_idx=2;over=0; end
				46:begin g0_idx=5;g1_idx=6;g2_idx=2;g3_idx=3;g4_idx=1;over=0; end
				47:begin g0_idx=6;g1_idx=5;g2_idx=2;g3_idx=3;g4_idx=1;over=0; end
				48:begin g0_idx=0;g1_idx=1;g2_idx=4;g3_idx=5;g4_idx=6;over=0; end
				49:begin g0_idx=0;g1_idx=1;g2_idx=5;g3_idx=4;g4_idx=6;over=0; end
				50:begin g0_idx=0;g1_idx=1;g2_idx=4;g3_idx=6;g4_idx=5;over=0; end
				51:begin g0_idx=0;g1_idx=1;g2_idx=6;g3_idx=4;g4_idx=5;over=0; end
				52:begin g0_idx=0;g1_idx=5;g2_idx=1;g3_idx=6;g4_idx=4;over=0; end
				53:begin g0_idx=5;g1_idx=1;g2_idx=0;g3_idx=6;g4_idx=4;over=0; end
				54:begin g0_idx=0;g1_idx=6;g2_idx=1;g3_idx=5;g4_idx=4;over=0; end
				55:begin g0_idx=6;g1_idx=1;g2_idx=0;g3_idx=5;g4_idx=4;over=0; end
				56:begin g0_idx=0;g1_idx=5;g2_idx=6;g3_idx=1;g4_idx=4;over=0; end
				57:begin g0_idx=0;g1_idx=6;g2_idx=5;g3_idx=1;g4_idx=4;over=0; end
				58:begin g0_idx=5;g1_idx=1;g2_idx=6;g3_idx=0;g4_idx=4;over=0; end
				59:begin g0_idx=6;g1_idx=1;g2_idx=5;g3_idx=0;g4_idx=4;over=0; end
				60:begin g0_idx=0;g1_idx=4;g2_idx=2;g3_idx=5;g4_idx=6;over=0; end
				61:begin g0_idx=0;g1_idx=5;g2_idx=2;g3_idx=4;g4_idx=6;over=0; end
				62:begin g0_idx=0;g1_idx=4;g2_idx=2;g3_idx=6;g4_idx=5;over=0; end
				63:begin g0_idx=0;g1_idx=6;g2_idx=2;g3_idx=4;g4_idx=5;over=0; end
				64:begin g0_idx=0;g1_idx=2;g2_idx=5;g3_idx=6;g4_idx=4;over=0; end
				65:begin g0_idx=5;g1_idx=0;g2_idx=2;g3_idx=6;g4_idx=4;over=0; end
				66:begin g0_idx=0;g1_idx=2;g2_idx=6;g3_idx=5;g4_idx=4;over=0; end
				67:begin g0_idx=6;g1_idx=0;g2_idx=2;g3_idx=5;g4_idx=4;over=0; end
				68:begin g0_idx=0;g1_idx=5;g2_idx=6;g3_idx=2;g4_idx=4;over=0; end
				69:begin g0_idx=0;g1_idx=6;g2_idx=5;g3_idx=2;g4_idx=4;over=0; end
				70:begin g0_idx=5;g1_idx=6;g2_idx=2;g3_idx=0;g4_idx=4;over=0; end
				71:begin g0_idx=6;g1_idx=5;g2_idx=2;g3_idx=0;g4_idx=4;over=0; end
				72:begin g0_idx=4;g1_idx=1;g2_idx=2;g3_idx=5;g4_idx=6;over=0; end
				73:begin g0_idx=5;g1_idx=1;g2_idx=2;g3_idx=4;g4_idx=6;over=0; end
				74:begin g0_idx=4;g1_idx=1;g2_idx=2;g3_idx=6;g4_idx=5;over=0; end
				75:begin g0_idx=6;g1_idx=1;g2_idx=2;g3_idx=4;g4_idx=5;over=0; end
				76:begin g0_idx=2;g1_idx=1;g2_idx=5;g3_idx=6;g4_idx=4;over=0; end
				77:begin g0_idx=1;g1_idx=5;g2_idx=2;g3_idx=6;g4_idx=4;over=0; end
				78:begin g0_idx=2;g1_idx=1;g2_idx=6;g3_idx=5;g4_idx=4;over=0; end
				79:begin g0_idx=1;g1_idx=6;g2_idx=2;g3_idx=5;g4_idx=4;over=0; end
				80:begin g0_idx=5;g1_idx=1;g2_idx=6;g3_idx=2;g4_idx=4;over=0; end
				81:begin g0_idx=6;g1_idx=1;g2_idx=5;g3_idx=2;g4_idx=4;over=0; end
				82:begin g0_idx=5;g1_idx=6;g2_idx=2;g3_idx=1;g4_idx=4;over=0; end
				83:begin g0_idx=6;g1_idx=5;g2_idx=2;g3_idx=1;g4_idx=4;over=0; end
				84:begin g0_idx=0;g1_idx=4;g2_idx=5;g3_idx=3;g4_idx=6;over=0; end
				85:begin g0_idx=0;g1_idx=5;g2_idx=4;g3_idx=3;g4_idx=6;over=0; end
				86:begin g0_idx=0;g1_idx=4;g2_idx=6;g3_idx=3;g4_idx=5;over=0; end
				87:begin g0_idx=0;g1_idx=6;g2_idx=4;g3_idx=3;g4_idx=5;over=0; end
				88:begin g0_idx=0;g1_idx=3;g2_idx=5;g3_idx=6;g4_idx=4;over=0; end
				89:begin g0_idx=0;g1_idx=5;g2_idx=3;g3_idx=6;g4_idx=4;over=0; end
				90:begin g0_idx=0;g1_idx=3;g2_idx=6;g3_idx=5;g4_idx=4;over=0; end
				91:begin g0_idx=0;g1_idx=6;g2_idx=3;g3_idx=5;g4_idx=4;over=0; end
				92:begin g0_idx=5;g1_idx=0;g2_idx=6;g3_idx=3;g4_idx=4;over=0; end
				93:begin g0_idx=6;g1_idx=0;g2_idx=5;g3_idx=3;g4_idx=4;over=0; end
				94:begin g0_idx=5;g1_idx=6;g2_idx=0;g3_idx=3;g4_idx=4;over=0; end
				95:begin g0_idx=6;g1_idx=5;g2_idx=0;g3_idx=3;g4_idx=4;over=0; end
				96:begin g0_idx=4;g1_idx=1;g2_idx=5;g3_idx=3;g4_idx=6;over=0; end
				97:begin g0_idx=5;g1_idx=1;g2_idx=4;g3_idx=3;g4_idx=6;over=0; end
				98:begin g0_idx=4;g1_idx=1;g2_idx=6;g3_idx=3;g4_idx=5;over=0; end
				99:begin g0_idx=6;g1_idx=1;g2_idx=4;g3_idx=3;g4_idx=5;over=0; end
				100:begin g0_idx=3;g1_idx=1;g2_idx=5;g3_idx=6;g4_idx=4;over=0; end
				101:begin g0_idx=5;g1_idx=1;g2_idx=3;g3_idx=6;g4_idx=4;over=0; end
				102:begin g0_idx=3;g1_idx=1;g2_idx=6;g3_idx=5;g4_idx=4;over=0; end
				103:begin g0_idx=6;g1_idx=1;g2_idx=3;g3_idx=5;g4_idx=4;over=0; end
				104:begin g0_idx=1;g1_idx=5;g2_idx=6;g3_idx=3;g4_idx=4;over=0; end
				105:begin g0_idx=1;g1_idx=6;g2_idx=5;g3_idx=3;g4_idx=4;over=0; end
				106:begin g0_idx=5;g1_idx=6;g2_idx=1;g3_idx=3;g4_idx=4;over=0; end
				107:begin g0_idx=6;g1_idx=5;g2_idx=1;g3_idx=3;g4_idx=4;over=0; end
				108:begin g0_idx=4;g1_idx=5;g2_idx=2;g3_idx=3;g4_idx=6;over=0; end
				109:begin g0_idx=5;g1_idx=4;g2_idx=2;g3_idx=3;g4_idx=6;over=0; end
				110:begin g0_idx=4;g1_idx=6;g2_idx=2;g3_idx=3;g4_idx=5;over=0; end
				111:begin g0_idx=6;g1_idx=4;g2_idx=2;g3_idx=3;g4_idx=5;over=0; end
				112:begin g0_idx=3;g1_idx=5;g2_idx=2;g3_idx=6;g4_idx=4;over=0; end
				113:begin g0_idx=5;g1_idx=3;g2_idx=2;g3_idx=6;g4_idx=4;over=0; end
				114:begin g0_idx=3;g1_idx=6;g2_idx=2;g3_idx=5;g4_idx=4;over=0; end
				115:begin g0_idx=6;g1_idx=3;g2_idx=2;g3_idx=5;g4_idx=4;over=0; end
				116:begin g0_idx=2;g1_idx=5;g2_idx=6;g3_idx=3;g4_idx=4;over=0; end
				117:begin g0_idx=5;g1_idx=2;g2_idx=6;g3_idx=3;g4_idx=4;over=0; end
				118:begin g0_idx=2;g1_idx=6;g2_idx=5;g3_idx=3;g4_idx=4;over=0; end
				119:begin g0_idx=6;g1_idx=2;g2_idx=5;g3_idx=3;g4_idx=4;over=0; end
		
				default :begin
					g0_idx=3'bx;    g1_idx=3'bx;    g2_idx=3'bx;    g3_idx=3'bx;    g4_idx=3'bx; over=1;
				end	
			endcase
		6'o22:
			case(inspect_vector)
				0:begin g0_idx=1;g1_idx=0;g2_idx=2;g3_idx=3;g4_idx=5;over=0; end
				1:begin g0_idx=0;g1_idx=2;g2_idx=1;g3_idx=3;g4_idx=5;over=0; end
				2:begin g0_idx=2;g1_idx=1;g2_idx=0;g3_idx=3;g4_idx=5;over=0; end
				3:begin g0_idx=0;g1_idx=1;g2_idx=3;g3_idx=2;g4_idx=5;over=0; end
				4:begin g0_idx=0;g1_idx=3;g2_idx=2;g3_idx=1;g4_idx=5;over=0; end
				5:begin g0_idx=3;g1_idx=1;g2_idx=2;g3_idx=0;g4_idx=5;over=0; end
				6:begin g0_idx=0;g1_idx=1;g2_idx=5;g3_idx=2;g4_idx=3;over=0; end
				7:begin g0_idx=0;g1_idx=5;g2_idx=2;g3_idx=1;g4_idx=3;over=0; end
				8:begin g0_idx=5;g1_idx=1;g2_idx=2;g3_idx=0;g4_idx=3;over=0; end
				9:begin g0_idx=0;g1_idx=1;g2_idx=3;g3_idx=5;g4_idx=2;over=0; end
				10:begin g0_idx=0;g1_idx=5;g2_idx=1;g3_idx=3;g4_idx=2;over=0; end
				11:begin g0_idx=5;g1_idx=1;g2_idx=0;g3_idx=3;g4_idx=2;over=0; end
				12:begin g0_idx=0;g1_idx=3;g2_idx=2;g3_idx=5;g4_idx=1;over=0; end
				13:begin g0_idx=0;g1_idx=2;g2_idx=5;g3_idx=3;g4_idx=1;over=0; end
				14:begin g0_idx=5;g1_idx=0;g2_idx=2;g3_idx=3;g4_idx=1;over=0; end
				15:begin g0_idx=3;g1_idx=1;g2_idx=2;g3_idx=5;g4_idx=0;over=0; end
				16:begin g0_idx=2;g1_idx=1;g2_idx=5;g3_idx=3;g4_idx=0;over=0; end
				17:begin g0_idx=1;g1_idx=5;g2_idx=2;g3_idx=3;g4_idx=0;over=0; end
				18:begin g0_idx=0;g1_idx=1;g2_idx=4;g3_idx=2;g4_idx=5;over=0; end
				19:begin g0_idx=0;g1_idx=4;g2_idx=2;g3_idx=1;g4_idx=5;over=0; end
				20:begin g0_idx=4;g1_idx=1;g2_idx=2;g3_idx=0;g4_idx=5;over=0; end
				21:begin g0_idx=1;g1_idx=0;g2_idx=2;g3_idx=5;g4_idx=4;over=0; end
				22:begin g0_idx=0;g1_idx=2;g2_idx=1;g3_idx=5;g4_idx=4;over=0; end
				23:begin g0_idx=2;g1_idx=1;g2_idx=0;g3_idx=5;g4_idx=4;over=0; end
				24:begin g0_idx=0;g1_idx=5;g2_idx=1;g3_idx=2;g4_idx=4;over=0; end
				25:begin g0_idx=5;g1_idx=1;g2_idx=0;g3_idx=2;g4_idx=4;over=0; end
				26:begin g0_idx=0;g1_idx=2;g2_idx=5;g3_idx=1;g4_idx=4;over=0; end
				27:begin g0_idx=5;g1_idx=0;g2_idx=2;g3_idx=1;g4_idx=4;over=0; end
				28:begin g0_idx=2;g1_idx=1;g2_idx=5;g3_idx=0;g4_idx=4;over=0; end
				29:begin g0_idx=1;g1_idx=5;g2_idx=2;g3_idx=0;g4_idx=4;over=0; end
				30:begin g0_idx=0;g1_idx=1;g2_idx=4;g3_idx=5;g4_idx=2;over=0; end
				31:begin g0_idx=0;g1_idx=1;g2_idx=5;g3_idx=4;g4_idx=2;over=0; end
				32:begin g0_idx=0;g1_idx=4;g2_idx=2;g3_idx=5;g4_idx=1;over=0; end
				33:begin g0_idx=0;g1_idx=5;g2_idx=2;g3_idx=4;g4_idx=1;over=0; end
				34:begin g0_idx=4;g1_idx=1;g2_idx=2;g3_idx=5;g4_idx=0;over=0; end
				35:begin g0_idx=5;g1_idx=1;g2_idx=2;g3_idx=4;g4_idx=0;over=0; end
				36:begin g0_idx=0;g1_idx=1;g2_idx=3;g3_idx=4;g4_idx=5;over=0; end
				37:begin g0_idx=0;g1_idx=4;g2_idx=1;g3_idx=3;g4_idx=5;over=0; end
				38:begin g0_idx=4;g1_idx=1;g2_idx=0;g3_idx=3;g4_idx=5;over=0; end
				39:begin g0_idx=0;g1_idx=3;g2_idx=1;g3_idx=5;g4_idx=4;over=0; end
				40:begin g0_idx=3;g1_idx=1;g2_idx=0;g3_idx=5;g4_idx=4;over=0; end
				41:begin g0_idx=1;g1_idx=0;g2_idx=5;g3_idx=3;g4_idx=4;over=0; end
				42:begin g0_idx=5;g1_idx=0;g2_idx=1;g3_idx=3;g4_idx=4;over=0; end
				43:begin g0_idx=1;g1_idx=5;g2_idx=0;g3_idx=3;g4_idx=4;over=0; end
				44:begin g0_idx=0;g1_idx=3;g2_idx=5;g3_idx=1;g4_idx=4;over=0; end
				45:begin g0_idx=0;g1_idx=5;g2_idx=3;g3_idx=1;g4_idx=4;over=0; end
				46:begin g0_idx=3;g1_idx=1;g2_idx=5;g3_idx=0;g4_idx=4;over=0; end
				47:begin g0_idx=5;g1_idx=1;g2_idx=3;g3_idx=0;g4_idx=4;over=0; end
				48:begin g0_idx=0;g1_idx=1;g2_idx=4;g3_idx=5;g4_idx=3;over=0; end
				49:begin g0_idx=0;g1_idx=1;g2_idx=5;g3_idx=4;g4_idx=3;over=0; end
				50:begin g0_idx=0;g1_idx=4;g2_idx=5;g3_idx=3;g4_idx=1;over=0; end
				51:begin g0_idx=0;g1_idx=5;g2_idx=4;g3_idx=3;g4_idx=1;over=0; end
				52:begin g0_idx=4;g1_idx=1;g2_idx=5;g3_idx=3;g4_idx=0;over=0; end
				53:begin g0_idx=5;g1_idx=1;g2_idx=4;g3_idx=3;g4_idx=0;over=0; end
				54:begin g0_idx=0;g1_idx=3;g2_idx=2;g3_idx=4;g4_idx=5;over=0; end
				55:begin g0_idx=0;g1_idx=2;g2_idx=4;g3_idx=3;g4_idx=5;over=0; end
				56:begin g0_idx=4;g1_idx=0;g2_idx=2;g3_idx=3;g4_idx=5;over=0; end
				57:begin g0_idx=0;g1_idx=2;g2_idx=3;g3_idx=5;g4_idx=4;over=0; end
				58:begin g0_idx=3;g1_idx=0;g2_idx=2;g3_idx=5;g4_idx=4;over=0; end
				59:begin g0_idx=2;g1_idx=0;g2_idx=5;g3_idx=3;g4_idx=4;over=0; end
				60:begin g0_idx=2;g1_idx=5;g2_idx=0;g3_idx=3;g4_idx=4;over=0; end
				61:begin g0_idx=5;g1_idx=2;g2_idx=0;g3_idx=3;g4_idx=4;over=0; end
				62:begin g0_idx=0;g1_idx=3;g2_idx=5;g3_idx=2;g4_idx=4;over=0; end
				63:begin g0_idx=0;g1_idx=5;g2_idx=3;g3_idx=2;g4_idx=4;over=0; end
				64:begin g0_idx=3;g1_idx=5;g2_idx=2;g3_idx=0;g4_idx=4;over=0; end
				65:begin g0_idx=5;g1_idx=3;g2_idx=2;g3_idx=0;g4_idx=4;over=0; end
				66:begin g0_idx=0;g1_idx=4;g2_idx=2;g3_idx=5;g4_idx=3;over=0; end
				67:begin g0_idx=0;g1_idx=5;g2_idx=2;g3_idx=4;g4_idx=3;over=0; end
				68:begin g0_idx=0;g1_idx=4;g2_idx=5;g3_idx=3;g4_idx=2;over=0; end
				69:begin g0_idx=0;g1_idx=5;g2_idx=4;g3_idx=3;g4_idx=2;over=0; end
				70:begin g0_idx=4;g1_idx=5;g2_idx=2;g3_idx=3;g4_idx=0;over=0; end
				71:begin g0_idx=5;g1_idx=4;g2_idx=2;g3_idx=3;g4_idx=0;over=0; end
				72:begin g0_idx=3;g1_idx=1;g2_idx=2;g3_idx=4;g4_idx=5;over=0; end
				73:begin g0_idx=2;g1_idx=1;g2_idx=4;g3_idx=3;g4_idx=5;over=0; end
				74:begin g0_idx=1;g1_idx=4;g2_idx=2;g3_idx=3;g4_idx=5;over=0; end
				75:begin g0_idx=2;g1_idx=1;g2_idx=3;g3_idx=5;g4_idx=4;over=0; end
				76:begin g0_idx=1;g1_idx=3;g2_idx=2;g3_idx=5;g4_idx=4;over=0; end
				77:begin g0_idx=1;g1_idx=2;g2_idx=5;g3_idx=3;g4_idx=4;over=0; end
				78:begin g0_idx=2;g1_idx=5;g2_idx=1;g3_idx=3;g4_idx=4;over=0; end
				79:begin g0_idx=5;g1_idx=2;g2_idx=1;g3_idx=3;g4_idx=4;over=0; end
				80:begin g0_idx=3;g1_idx=1;g2_idx=5;g3_idx=2;g4_idx=4;over=0; end
				81:begin g0_idx=5;g1_idx=1;g2_idx=3;g3_idx=2;g4_idx=4;over=0; end
				82:begin g0_idx=3;g1_idx=5;g2_idx=2;g3_idx=1;g4_idx=4;over=0; end
				83:begin g0_idx=5;g1_idx=3;g2_idx=2;g3_idx=1;g4_idx=4;over=0; end
				84:begin g0_idx=4;g1_idx=1;g2_idx=2;g3_idx=5;g4_idx=3;over=0; end
				85:begin g0_idx=5;g1_idx=1;g2_idx=2;g3_idx=4;g4_idx=3;over=0; end
				86:begin g0_idx=4;g1_idx=1;g2_idx=5;g3_idx=3;g4_idx=2;over=0; end
				87:begin g0_idx=5;g1_idx=1;g2_idx=4;g3_idx=3;g4_idx=2;over=0; end
				88:begin g0_idx=4;g1_idx=5;g2_idx=2;g3_idx=3;g4_idx=1;over=0; end
				89:begin g0_idx=5;g1_idx=4;g2_idx=2;g3_idx=3;g4_idx=1;over=0; end
		
				default :begin
					g0_idx=3'bx;    g1_idx=3'bx;    g2_idx=3'bx;    g3_idx=3'bx;    g4_idx=3'bx; over=1;
				end	
			endcase				
		6'o23:
			case(inspect_vector)
				0:begin g0_idx=2;g1_idx=0;g2_idx=1;g3_idx=3;g4_idx=4;over=0; end
				1:begin g0_idx=1;g1_idx=2;g2_idx=0;g3_idx=3;g4_idx=4;over=0; end
				2:begin g0_idx=0;g1_idx=3;g2_idx=1;g3_idx=2;g4_idx=4;over=0; end
				3:begin g0_idx=3;g1_idx=1;g2_idx=0;g3_idx=2;g4_idx=4;over=0; end
				4:begin g0_idx=0;g1_idx=2;g2_idx=3;g3_idx=1;g4_idx=4;over=0; end
				5:begin g0_idx=3;g1_idx=0;g2_idx=2;g3_idx=1;g4_idx=4;over=0; end
				6:begin g0_idx=2;g1_idx=1;g2_idx=3;g3_idx=0;g4_idx=4;over=0; end
				7:begin g0_idx=1;g1_idx=3;g2_idx=2;g3_idx=0;g4_idx=4;over=0; end
				8:begin g0_idx=0;g1_idx=1;g2_idx=4;g3_idx=2;g4_idx=3;over=0; end
				9:begin g0_idx=0;g1_idx=4;g2_idx=2;g3_idx=1;g4_idx=3;over=0; end
				10:begin g0_idx=4;g1_idx=1;g2_idx=2;g3_idx=0;g4_idx=3;over=0; end
				11:begin g0_idx=0;g1_idx=1;g2_idx=3;g3_idx=4;g4_idx=2;over=0; end
				12:begin g0_idx=0;g1_idx=4;g2_idx=1;g3_idx=3;g4_idx=2;over=0; end
				13:begin g0_idx=4;g1_idx=1;g2_idx=0;g3_idx=3;g4_idx=2;over=0; end
				14:begin g0_idx=0;g1_idx=3;g2_idx=2;g3_idx=4;g4_idx=1;over=0; end
				15:begin g0_idx=0;g1_idx=2;g2_idx=4;g3_idx=3;g4_idx=1;over=0; end
				16:begin g0_idx=4;g1_idx=0;g2_idx=2;g3_idx=3;g4_idx=1;over=0; end
				17:begin g0_idx=3;g1_idx=1;g2_idx=2;g3_idx=4;g4_idx=0;over=0; end
				18:begin g0_idx=2;g1_idx=1;g2_idx=4;g3_idx=3;g4_idx=0;over=0; end
				19:begin g0_idx=1;g1_idx=4;g2_idx=2;g3_idx=3;g4_idx=0;over=0; end
				default :begin
					g0_idx=3'bx;    g1_idx=3'bx;    g2_idx=3'bx;    g3_idx=3'bx;    g4_idx=3'bx; over=1;
				end
			endcase
		6'o30:
			case(inspect_vector)
				0:begin g0_idx=0;g1_idx=1;g2_idx=2;g3_idx=5;g4_idx=6;over=0; end
				1:begin g0_idx=0;g1_idx=1;g2_idx=2;g3_idx=6;g4_idx=5;over=0; end
				2:begin g0_idx=0;g1_idx=1;g2_idx=5;g3_idx=3;g4_idx=6;over=0; end
				3:begin g0_idx=0;g1_idx=1;g2_idx=6;g3_idx=3;g4_idx=5;over=0; end
				4:begin g0_idx=0;g1_idx=5;g2_idx=2;g3_idx=3;g4_idx=6;over=0; end
				5:begin g0_idx=0;g1_idx=6;g2_idx=2;g3_idx=3;g4_idx=5;over=0; end
				6:begin g0_idx=5;g1_idx=1;g2_idx=2;g3_idx=3;g4_idx=6;over=0; end
				7:begin g0_idx=6;g1_idx=1;g2_idx=2;g3_idx=3;g4_idx=5;over=0; end
				8:begin g0_idx=0;g1_idx=1;g2_idx=5;g3_idx=6;g4_idx=4;over=0; end
				9:begin g0_idx=0;g1_idx=1;g2_idx=6;g3_idx=5;g4_idx=4;over=0; end
				10:begin g0_idx=0;g1_idx=5;g2_idx=2;g3_idx=6;g4_idx=4;over=0; end
				11:begin g0_idx=0;g1_idx=6;g2_idx=2;g3_idx=5;g4_idx=4;over=0; end
				12:begin g0_idx=5;g1_idx=1;g2_idx=2;g3_idx=6;g4_idx=4;over=0; end
				13:begin g0_idx=6;g1_idx=1;g2_idx=2;g3_idx=5;g4_idx=4;over=0; end
				14:begin g0_idx=0;g1_idx=5;g2_idx=6;g3_idx=3;g4_idx=4;over=0; end
				15:begin g0_idx=0;g1_idx=6;g2_idx=5;g3_idx=3;g4_idx=4;over=0; end
				16:begin g0_idx=5;g1_idx=1;g2_idx=6;g3_idx=3;g4_idx=4;over=0; end
				17:begin g0_idx=6;g1_idx=1;g2_idx=5;g3_idx=3;g4_idx=4;over=0; end
				18:begin g0_idx=5;g1_idx=6;g2_idx=2;g3_idx=3;g4_idx=4;over=0; end
				19:begin g0_idx=6;g1_idx=5;g2_idx=2;g3_idx=3;g4_idx=4;over=0; end		
				default :begin
					g0_idx=3'bx;    g1_idx=3'bx;    g2_idx=3'bx;    g3_idx=3'bx;    g4_idx=3'bx; over=1;
				end		
			endcase			
		6'o31:
			case(inspect_vector)
				0:begin g0_idx=0;g1_idx=1;g2_idx=2;g3_idx=5;g4_idx=3;over=0; end
				1:begin g0_idx=0;g1_idx=1;g2_idx=5;g3_idx=3;g4_idx=2;over=0; end
				2:begin g0_idx=0;g1_idx=5;g2_idx=2;g3_idx=3;g4_idx=1;over=0; end
				3:begin g0_idx=5;g1_idx=1;g2_idx=2;g3_idx=3;g4_idx=0;over=0; end
				4:begin g0_idx=0;g1_idx=1;g2_idx=2;g3_idx=4;g4_idx=5;over=0; end
				5:begin g0_idx=0;g1_idx=1;g2_idx=5;g3_idx=2;g4_idx=4;over=0; end
				6:begin g0_idx=0;g1_idx=5;g2_idx=2;g3_idx=1;g4_idx=4;over=0; end
				7:begin g0_idx=5;g1_idx=1;g2_idx=2;g3_idx=0;g4_idx=4;over=0; end
				8:begin g0_idx=0;g1_idx=1;g2_idx=4;g3_idx=3;g4_idx=5;over=0; end
				9:begin g0_idx=0;g1_idx=1;g2_idx=3;g3_idx=5;g4_idx=4;over=0; end
				10:begin g0_idx=0;g1_idx=5;g2_idx=1;g3_idx=3;g4_idx=4;over=0; end
				11:begin g0_idx=5;g1_idx=1;g2_idx=0;g3_idx=3;g4_idx=4;over=0; end
				12:begin g0_idx=0;g1_idx=4;g2_idx=2;g3_idx=3;g4_idx=5;over=0; end
				13:begin g0_idx=0;g1_idx=3;g2_idx=2;g3_idx=5;g4_idx=4;over=0; end
				14:begin g0_idx=0;g1_idx=2;g2_idx=5;g3_idx=3;g4_idx=4;over=0; end
				15:begin g0_idx=5;g1_idx=0;g2_idx=2;g3_idx=3;g4_idx=4;over=0; end
				16:begin g0_idx=4;g1_idx=1;g2_idx=2;g3_idx=3;g4_idx=5;over=0; end
				17:begin g0_idx=3;g1_idx=1;g2_idx=2;g3_idx=5;g4_idx=4;over=0; end
				18:begin g0_idx=2;g1_idx=1;g2_idx=5;g3_idx=3;g4_idx=4;over=0; end
				19:begin g0_idx=1;g1_idx=5;g2_idx=2;g3_idx=3;g4_idx=4;over=0; end
				default :begin
					g0_idx=3'bx;    g1_idx=3'bx;    g2_idx=3'bx;    g3_idx=3'bx;    g4_idx=3'bx; over=1;
				end
			endcase			
		6'o32:
			case(inspect_vector)
				0:begin g0_idx=1;g1_idx=0;g2_idx=2;g3_idx=3;g4_idx=4;over=0; end
				1:begin g0_idx=0;g1_idx=2;g2_idx=1;g3_idx=3;g4_idx=4;over=0; end
				2:begin g0_idx=2;g1_idx=1;g2_idx=0;g3_idx=3;g4_idx=4;over=0; end
				3:begin g0_idx=0;g1_idx=1;g2_idx=3;g3_idx=2;g4_idx=4;over=0; end
				4:begin g0_idx=0;g1_idx=3;g2_idx=2;g3_idx=1;g4_idx=4;over=0; end
				5:begin g0_idx=3;g1_idx=1;g2_idx=2;g3_idx=0;g4_idx=4;over=0; end
				6:begin g0_idx=0;g1_idx=1;g2_idx=2;g3_idx=4;g4_idx=3;over=0; end
				7:begin g0_idx=0;g1_idx=1;g2_idx=4;g3_idx=3;g4_idx=2;over=0; end
				8:begin g0_idx=0;g1_idx=4;g2_idx=2;g3_idx=3;g4_idx=1;over=0; end
				9:begin g0_idx=4;g1_idx=1;g2_idx=2;g3_idx=3;g4_idx=0;over=0; end		
				default :begin
					g0_idx=3'bx;    g1_idx=3'bx;    g2_idx=3'bx;    g3_idx=3'bx;    g4_idx=3'bx; over=1;
				end	
			endcase				
		6'o40:
			case(inspect_vector)
				0:begin g0_idx=0;g1_idx=1;g2_idx=2;g3_idx=3;g4_idx=5;over=0; end
				1:begin g0_idx=0;g1_idx=1;g2_idx=2;g3_idx=5;g4_idx=4;over=0; end
				2:begin g0_idx=0;g1_idx=1;g2_idx=5;g3_idx=3;g4_idx=4;over=0; end
				3:begin g0_idx=0;g1_idx=5;g2_idx=2;g3_idx=3;g4_idx=4;over=0; end
				4:begin g0_idx=5;g1_idx=1;g2_idx=2;g3_idx=3;g4_idx=4;over=0; end
				default :begin
					g0_idx=3'bx;    g1_idx=3'bx;    g2_idx=3'bx;    g3_idx=3'bx;    g4_idx=3'bx; over=1;
				end	
			endcase				
		6'o50:
			if(inspect_vector==0)begin g0_idx=0;g1_idx=1;g2_idx=2;g3_idx=3;g4_idx=4;over=0; end
			else begin	g0_idx=3'bx;    g1_idx=3'bx;    g2_idx=3'bx;    g3_idx=3'bx;    g4_idx=3'bx; over=1;end	
		default :begin
			g0_idx=3'bx;    g1_idx=3'bx;    g2_idx=3'bx;    g3_idx=3'bx;    g4_idx=3'bx; over=1;
		end	
	endcase

 
 endmodule
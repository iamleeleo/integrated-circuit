module	CORDIC (
	input	wire				clk, rst_n, in_valid,
	input	wire	signed	[11:0]	in_x, in_y,
	output	reg		[11:0]	out_mag,
	output	reg		[20:0]	out_phase,
	output	reg					out_valid

	);

// input_x and input_y -> 1'b sign , 3'b int , 8'b fraction
// out_mag -> 4b int , 8'b fraction
// output -> 1'b int , 20'b fraction 
wire	[20:0]	cordic_angle [0:17];
wire    [14:0]	Constant;

parameter IDLE = 0;
parameter INPUT = 1;
parameter SETUP = 2;
parameter CAL = 3;
parameter WB = 4;
parameter OUTPUT = 5;
parameter OUTPUT_SETUP = 7;
parameter CAL_SETUP = 6;
reg [2:0]next_state, current_state;
reg [9:0]INPUT_address_0,INPUT_address_1,CAL_address_0,CAL_address_1,OUTPUT_address_0,OUTPUT_address_1;

//cordic angle -> 1'b int, 20'b fraciton
assign   cordic_angle[ 0] = 21'h04_0000; //  45        deg
assign   cordic_angle[ 1] = 21'h02_5c81; //  26.565051 deg
assign   cordic_angle[ 2] = 21'h01_3f67; //  14.036243 deg
assign   cordic_angle[ 3] = 21'h00_a222; //   7.125016 deg
assign   cordic_angle[ 4] = 21'h00_5162; //   3.576334 deg
assign   cordic_angle[ 5] = 21'h00_28bb; //   1.789911 deg
assign   cordic_angle[ 6] = 21'h00_145f; //   0.895174 deg
assign   cordic_angle[ 7] = 21'h00_0a30; //   0.447614 deg
assign   cordic_angle[ 8] = 21'h00_0518; //   0.223811 deg
assign   cordic_angle[ 9] = 21'h00_028b; //   0.111906 deg
assign   cordic_angle[10] = 21'h00_0146; //   0.055953 deg
assign   cordic_angle[11] = 21'h00_00a3; //   0.027976 deg
assign   cordic_angle[12] = 21'h00_0051; //   0.013988 deg
assign   cordic_angle[13] = 21'h00_0029; //   0.006994 deg
assign   cordic_angle[14] = 21'h00_0014; //   0.003497 deg
assign   cordic_angle[15] = 21'h00_000a; //   0.001749 deg
assign   cordic_angle[16] = 21'h00_0005; //   0.000874 deg
assign   cordic_angle[17] = 21'h00_0003; //   0.000437 deg
   
//Constant-> 1'b int, 14'b fraction
assign  Constant = {1'b0,14'b10011011011101}; // 1/K = 0.6072387695

wire signed[11:0]readed_0_data;
wire signed[20:0]readed_1_data;
reg [11:0]write_0_data;
reg [20:0]write_1_data;
reg wen_0;
reg wen_1;

reg [11:0]tmp_out_msg;
reg [23:0]tmp_out_phase;
reg [9:0]address_0;
reg [9:0]address_1;
wire cal_end,all_done,out_end;
//12bits * 1024 SRAM
RA1SH_12 MEM_12(
   .Q(readed_0_data),
   .CLK(clk),
   .CEN(1'd0),
   .WEN(wen_0),
   .A(address_0),
   .D(write_0_data),
   .OEN(1'd0)
);
//21bits * 1024 SRAM
RA1SH_21 MEM_21(
   .Q(readed_1_data),
   .CLK(clk),
   .CEN(1'd0),
   .WEN(wen_1),
   .A(address_1),
   .D(write_1_data),
   .OEN(1'd0)
);


always@*begin
	if(in_valid || current_state==INPUT ||  current_state==WB)begin
		wen_0=0;
		wen_1=0;
	end
	else
	begin
		wen_0=1;
		wen_1=1;
	end
end


///////////////////////////////////////////////FSM

// Current State
always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) current_state <= IDLE;
    else        current_state <= next_state;
end

always @(*) 
begin
	case (current_state)
		IDLE: 
			if (in_valid) next_state = INPUT;
			else next_state = current_state;
		INPUT:
			if (!in_valid) next_state = SETUP;
			else next_state = current_state;
		SETUP:
			next_state = CAL;
		CAL:
			if (cal_end) next_state = WB;
			else next_state = current_state;
		WB:
			if(all_done)next_state = OUTPUT_SETUP;
			else next_state = SETUP;
		OUTPUT_SETUP:
			next_state = OUTPUT;
		OUTPUT:
			if (out_end) next_state = IDLE;
			else next_state = current_state;
		default:
		begin
			next_state = current_state;
		end
	endcase
end



always@*begin
	if(current_state==INPUT)begin
		address_0 = INPUT_address_0;
		address_1  = INPUT_address_1;
	end
	else if(current_state==OUTPUT || current_state==OUTPUT_SETUP)begin
		address_0 = OUTPUT_address_0;
		address_1  = OUTPUT_address_1;
	end
	else
	begin
		address_0 = CAL_address_0;
		address_1  = CAL_address_1;
	end
end


///////////////////////////////////////////////
reg signed[19:0]cal_x,cal_y;
reg [9:0]cal_addr;
reg [9:0]input_count;
reg first;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		input_count<=0;
		INPUT_address_0<=0;
		INPUT_address_1<=0;
	end
	else begin
		if(current_state == INPUT)begin
			input_count<=1+input_count;
			INPUT_address_0<=1+INPUT_address_0;
			INPUT_address_1<=1+INPUT_address_1;
		end
		else if(current_state == IDLE)begin
			input_count<=0;
			INPUT_address_0<=0;
			INPUT_address_1<=0;
		end
	end

end


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		CAL_address_0<=0;
		CAL_address_1<=0;
	end
	else begin
		if(current_state==WB)begin
			CAL_address_0<=CAL_address_0+1;
			CAL_address_1<=CAL_address_1+1;
		end
		else if(current_state == IDLE)begin
			CAL_address_0<=0;
			CAL_address_1<=0;
		end
	end

end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		OUTPUT_address_0<=0;
		OUTPUT_address_1<=0;
	end
	else begin
		if(current_state==OUTPUT || current_state==OUTPUT_SETUP)begin
			OUTPUT_address_0<=OUTPUT_address_0+1;
			OUTPUT_address_1<=OUTPUT_address_1+1;
		end
		else if(current_state == IDLE)begin
			OUTPUT_address_0<=0;
			OUTPUT_address_1<=0;
		end
	end

end
reg [4:0]cordic_cnt;
reg signed[6:0]power2;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		power2<=1;
	end
	else begin
		
		if(cordic_cnt==0)begin
			power2<=1;
		end
		else begin
			if(cordic_cnt<6)
				power2<=2*power2;
		end
 
	end

end




wire signed [36:0]adj2 = (cal_x) * (Constant);

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		write_0_data<=0;
		write_1_data<=0;
	end
	else begin
		if(in_valid)begin
			write_0_data<=in_x;
			write_1_data<=in_y;
		end
		else begin
			write_0_data<=adj2[31:20];
			write_1_data<=tmp_out_phase;
		end
	end
end
wire signed [22:0]add_ = 23'h200000 ;
wire signed [22:0]adj = add_ +  readed_1_data;

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_valid<=0;
		out_mag<=0;
		out_phase<=0;
	end
	else begin
		if(current_state == OUTPUT)begin
			out_valid<=1;
			out_mag<=readed_0_data;
			out_phase<=(readed_1_data[20] ? readed_1_data : adj);
		end
		else begin
			out_valid<=0;
			out_mag<=0;
			out_phase<=0;
		end
	end
end

assign cal_end = (cordic_cnt==17);
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		cordic_cnt<=0;
	end
	else begin
		if(current_state == CAL)begin
			cordic_cnt<=cordic_cnt+1;
		end
		else if(current_state==WB)begin
			cordic_cnt<=0;
		end
	end
end



wire signed[19:0]tmp1 = (cal_y>>(cordic_cnt-1));
wire signed[19:0]tmp2 = (cal_y/power2);
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		tmp_out_phase<=0;
		cal_x<=0;
		cal_y<=0;
	end
	else begin
		
		if(current_state == CAL && cordic_cnt==0)begin
			if(readed_0_data[11])begin
				cal_x<={(~readed_0_data+1),6'b0};
				cal_y<={(~readed_1_data+1),6'b0};
				tmp_out_phase<={{1'b1},20'b0};
			end
			else begin
				cal_x<={readed_0_data,6'b0};
				cal_y<={readed_1_data,6'b0};
				tmp_out_phase<=0;
			end
		end
		else if(current_state==CAL)begin
			if(cal_y>0)begin
				cal_x<=cal_x+(cal_y>>(cordic_cnt-1));
				cal_y<=cal_y-(cal_x>>(cordic_cnt-1));
				tmp_out_phase<=tmp_out_phase + cordic_angle[cordic_cnt-1];
			end
			else if(cal_y<0)
			begin
				tmp_out_phase<=tmp_out_phase - cordic_angle[cordic_cnt-1];
				cal_x<=cal_x-cal_y/power2;
				cal_y<=cal_y+(cal_x>>(cordic_cnt-1));
			end
		end
	end

end
assign all_done = (input_count<CAL_address_0);
assign out_end = (input_count==OUTPUT_address_0);

endmodule

module TMIP(
// input signals
    clk,
    rst_n,
    in_valid,
	in_valid_2,
    image,
	img_size,
    template, 
    action,
	
// output signals
    out_valid,
    out_x,
    out_y,
    out_img_pos,
    out_value
);

input        clk, rst_n, in_valid, in_valid_2;
input [15:0] image, template;
input [4:0]  img_size;
input [2:0]  action;

output reg        out_valid;
output reg [3:0]  out_x, out_y; 
output reg [7:0]  out_img_pos;
output reg signed[39:0] out_value;

////////////Parameter//////////////
integer i,j;

parameter Cross_Correlation = 0;
parameter Max_pooling = 1;
parameter Horizontal_flip = 2;
parameter Vertical_flip = 3;
parameter Left_diagonal_flip = 4;
parameter Righr_diagonal_flip = 5;
parameter Zoom_in = 6;
parameter Shortcut_Brightness_Adjustment = 7;
parameter IDLE  = 8;
parameter INPUT = 9;
parameter INPUT2 = 10;
parameter SETUP = 11;
parameter OUTPUT = 12;
parameter COPY = 13;
parameter OUTPUT_cal = 14;

////////////FSM////////////////////
reg [3:0]next_state, current_state;


///////////memory/////////////////
reg w_enable_buffer;
reg signed[39:0]w_data_buffer;


///////////template//////////////
reg signed[15:0]raw_template[8:0];

//////////img_size///////////////
reg [4:0]current_img_size;

//////////action/////////////////
reg [4:0]action_idx,current_action;
reg [2:0]action_list[0:15];
reg cal_end;


///////////output////////////////
reg [3:0]next_img_pos;
wire img_pos_valid[8:0];
reg  [7:0]img_pos_list[8:0];
reg  [3:0]img_pos_list_idx,img_pos_list_scan;


//////////////////////////////////////////
reg [3:0]max_x,max_y;
reg [3:0]nine_num;
reg signed[39:0]conv_max;

//wire [3:0]img_start,img_end;
reg [3:0]des_img_start,des_img_end;
reg [3:0]src_img_start,src_img_end;
wire [4:0]half_size;

assign half_size = current_img_size / 2;


//assign des_img_start = 8 - half_size;
//assign des_img_end   = 7 + half_size;
reg mem_select;
reg write_enable;
wire [7:0]addr0,addr1,des_addr,src_addr;
wire signed[39:0]r_data1;
wire signed[15:0]r_data0;
wire signed[15:0]written_data;


reg signed[4:0]src_x,des_x,src_y,des_y;
always@*begin
	if(action_list[current_action]==Max_pooling )begin
		des_img_start = 8 - current_img_size/4;
		des_img_end   = 7 + current_img_size/4;
		src_img_start = 8 - half_size;
		src_img_end   = 7 + half_size;
	end
	else if(action_list[current_action]==Zoom_in)begin
		des_img_start = 8 - current_img_size;
		des_img_end   = 7 + current_img_size;
		src_img_start = 8 - half_size;
		src_img_end   = 7 + half_size;
	end
	else if(action_list[current_action]==Shortcut_Brightness_Adjustment && current_img_size!=4)begin
		des_img_start = 8 - half_size/2;
		des_img_end   = 7 + half_size/2;
		src_img_start = 8 - half_size;
		src_img_end   = 7 + half_size;
	end
	else begin
		des_img_start = 8 - half_size;
		des_img_end   = 7 + half_size;
		src_img_start = 8 - half_size;
		src_img_end   = 7 + half_size;
	end
end

/******************************************************************/
////////////FSM
/******************************************************************/



// Current State
always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) current_state <= IDLE;
    else        current_state <= next_state;
end

reg started;
reg [8:0]out_counter;
wire MP_notDo = action_list[current_action]==Max_pooling&&current_img_size==4&&current_state==SETUP;
wire ZI_notDo = action_list[current_action]==Zoom_in&&current_img_size==16&&current_state==SETUP;
// Next State
always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) out_counter <= 0;
    else if(current_state==OUTPUT)       out_counter <= out_counter+1;
	else out_counter<=0;
end

wire [8:0]end_num = current_img_size*current_img_size;
always @(*) 
begin
	case (current_state)
		IDLE: 
			if (in_valid) next_state = INPUT;
			else next_state = current_state;
		INPUT:
			if (!in_valid) next_state = INPUT2;
			else next_state = current_state;
		INPUT2:
			if (!in_valid_2) next_state = SETUP;
			else next_state = current_state;
		SETUP:
			if(action_idx == 0)next_state = action;
			else if(current_action==action_idx)next_state=OUTPUT_cal;
			else if(MP_notDo||ZI_notDo)next_state = SETUP;
			else if(action_list[current_action]==0&&mem_select==0)next_state = COPY;
			else next_state = action_list[current_action];
		COPY:
		begin
			if(cal_end)next_state=SETUP;
			else next_state = COPY;
		end
		OUTPUT_cal:
		begin
			if(cal_end)next_state=OUTPUT;
			else next_state = current_state;
		end
		OUTPUT:begin
			if(out_counter>end_num)next_state=IDLE;
			else next_state=current_state;
		end
		default:
		begin
			if(cal_end)next_state=SETUP;
			else next_state = action_list[current_action];
		end
	endcase
end


/******************************************************************/
////////////FSM end
/******************************************************************/



/******************************************************************/
////////////Input data
/******************************************************************/

reg [7:0]input_cnt;

always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)begin
		input_cnt<=0;
	end
	else 
	begin
		if(in_valid)
			input_cnt<=input_cnt+1;
		else
			input_cnt<=0;
	end
end



always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)begin
		for(i=0;i<9;i=i+1)
			raw_template[i]<=0;
	end
	else 
	begin
		if(in_valid && input_cnt < 9)begin
			raw_template[input_cnt]<=template;
		end
	end
end




always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)begin
		for(i=0;i<16;i=i+1)
			action_list[i]<=0;
		action_idx<=0;
	end
	else if(current_state==IDLE)begin
		action_idx<=0;
	end
	else 
	begin
		if(in_valid_2)begin
			action_list[action_idx]<=action;
			action_idx<=action_idx+1;
		end
	end
end

/******************************************************************/
////////////Input end
/******************************************************************/


/******************************************************************/
///////////memory control
/******************************************************************/

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)
	begin
		mem_select<=1;
	end
	else
	begin
		if(current_state==SETUP && next_state!=SETUP)
			mem_select<=~mem_select;
	end
end


//select=0  ----> move from 0 to 1
//select=1  ----> move from 1 to 0
wire signed[39:0]read_data;
wire w_enable0,w_enable1;
 
reg [3:0]MEM_src_x,MEM_des_x,MEM_src_y,MEM_des_y; 
assign des_addr = MEM_des_x + 16 * MEM_des_y;
assign src_addr = src_x + 16 * src_y;
assign addr0   = (mem_select ? des_addr : src_addr);
assign addr1   = (mem_select ? src_addr : des_addr);

assign read_data = (mem_select==1 ? r_data1:r_data0);
assign w_enable0 = !mem_select || write_enable;
assign w_enable1 =  mem_select || write_enable;

MEM_256_16_8_200 memory0(.A(addr0),.D(w_data_buffer[15:0]),.CLK(clk),.CEN(1'd0),.WEN(w_enable0),.OEN(1'd0),.Q(r_data0));
MEM_256_40_8_200 memory1(.A(addr1),.D(w_data_buffer),.CLK(clk),.CEN(1'd0),.WEN(w_enable1),.OEN(1'd0),.Q(r_data1));


/*****************///only need to read data from read_data , write to w_data_buffer

/******************************************************************/
///////////memory control end
/******************************************************************/

/******************************************************************/
///////////main control
/******************************************************************/
reg signed[39:0]read_buffer;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		read_buffer<=0;
	end
	else
	begin
		read_buffer<=read_data;
	end
end
wire  valid_check = src_x>=src_img_start && src_y>=src_img_start && src_x<=src_img_end && src_y<=src_img_end;

/////////////pipeline stage0
reg [3:0]conv_cnt_0;
reg [3:0]des_x_0;
reg [3:0]des_y_0;
/////////////pipeline stage1
reg [3:0]conv_cnt_1;
reg [3:0]des_x_1;
reg [3:0]des_y_1;

/////////////pipeline stage2
reg [3:0]conv_cnt_2;
reg valid_check_2;
reg [3:0]des_x_2;
reg [3:0]des_y_2;

/////////////pipeline stage2
reg [3:0]conv_cnt_3;
reg valid_check_3;
reg signed[39:0]conv_tmp;
reg [3:0]des_x_3;
reg [3:0]des_y_3;

reg [1:0]four_counter;
/////////////pipeline stage0
always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		conv_cnt_0<=0;
	end
	else 
	begin
		
		if(current_state==SETUP)
			conv_cnt_0<=0;
		else if(current_state==Cross_Correlation)begin
			if(conv_cnt_0<8)conv_cnt_0<=conv_cnt_0+1;
			else conv_cnt_0<=0;
		end
		else if(current_state==Max_pooling)begin
			if(conv_cnt_0<3)conv_cnt_0<=conv_cnt_0+1;
			else conv_cnt_0<=0;
		end
		else if(current_state==Zoom_in)begin
			if(conv_cnt_0<3)conv_cnt_0<=conv_cnt_0+1;
			else conv_cnt_0<=0;
		end
		else if(current_state==OUTPUT)begin
			if(conv_cnt_0<2)conv_cnt_0<=conv_cnt_0+1;
		end        
	end
end
reg [2:0]pp_cnt;
always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		pp_cnt<=0;
	end
	else 
	begin
		if(current_state==SETUP)pp_cnt<=0;
		else if(pp_cnt<5)pp_cnt<=pp_cnt+1;
			
	end
end
always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		des_x_0<=0;
		des_y_0<=0;
	end
	else 
	begin
		
		if(current_state==SETUP)begin
			if(next_state==Horizontal_flip)begin
				des_x_0<=des_img_end;
				des_y_0<=des_img_start;	
			end
			else if(next_state==Vertical_flip)begin
				des_x_0<=des_img_start;
				des_y_0<=des_img_end;				
			end
			else if(next_state==Left_diagonal_flip)begin
				des_x_0<=des_img_end;
				des_y_0<=des_img_end;				
			end
			else begin
				des_x_0<=des_img_start;
				des_y_0<=des_img_start;
			end
		end
		else if(current_state==Cross_Correlation)
		begin
			if(conv_cnt_0==8)begin
				if(des_x_0==des_img_end)begin
					des_x_0<=des_img_start;
					des_y_0<=des_y_0+1;
				end 
				else
					des_x_0<=des_x_0+1;
			end
		end
		else if(current_state==Max_pooling)
		begin
			if(conv_cnt_0==3)begin
				if(des_x_0==des_img_end)begin
					des_x_0<=des_img_start;
					des_y_0<=des_y_0+1;
				end 
				else
					des_x_0<=des_x_0+1;
			end
		end
		else if(current_state==Horizontal_flip)begin
			if(des_x_0==des_img_start)begin
				des_x_0<=des_img_end;
				des_y_0<=des_y_0+1;
			end
			else des_x_0<=des_x_0-1;
		end
		else if(current_state==Vertical_flip)begin
			if(des_x_0==des_img_end)begin
				des_y_0<=des_y_0-1;
				des_x_0<=des_img_start;
			end
			else des_x_0<=des_x_0+1;
		end
		else if(current_state==Righr_diagonal_flip)begin
			if(des_y_0==des_img_end)begin
				des_x_0<=des_x_0+1;
				des_y_0<=des_img_start;
			end
			else des_y_0<=des_y_0+1;
		end
		else if(current_state==Left_diagonal_flip)begin
			if(des_y_0==des_img_start)begin
				des_x_0<=des_x_0-1;
				des_y_0<=des_img_end;
			end
			else des_y_0<=des_y_0-1;
		end
		else if(current_state == Zoom_in)begin
			if(four_counter==3)begin
				if(des_x_0<(des_img_end-1))
					des_x_0<=des_x_0+2;
				else begin
					des_x_0<=des_img_start;
					des_y_0<=des_y_0+2;
				end
			end
		end
		else if(current_state==Shortcut_Brightness_Adjustment)begin
			if(des_x_0==des_img_end)begin
				des_x_0<=des_img_start;
				des_y_0<=des_y_0+1;
			end
			else des_x_0<=des_x_0+1;
		end
		else if(current_state==COPY)begin
			if(des_x_0==des_img_end)begin
				des_x_0<=des_img_start;
				des_y_0<=des_y_0+1;
			end 
			else
				des_x_0<=des_x_0+1;
		end
	end
end


always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		src_x<=0;
		src_y<=0;
	end
	else 
	begin
		if(current_state==SETUP)begin
			if(next_state==Shortcut_Brightness_Adjustment)begin
				src_x<=des_img_start;
				src_y<=des_img_start;	
			end
			else if(next_state==Cross_Correlation)begin
				src_x<=src_img_start-1;
				src_y<=src_img_start-1;	
			end
			else begin
				src_x<=src_img_start;
				src_y<=src_img_start;
			end
		end 
		else if(current_state==Cross_Correlation )begin
			case(conv_cnt_0)
				0:begin src_x<=des_x_0-1;src_y<=des_y_0-1  ;end
				1:begin src_x<=des_x_0  ;src_y<=des_y_0-1  ;end
				2:begin src_x<=des_x_0+1;src_y<=des_y_0-1  ;end
				3:begin src_x<=des_x_0-1;src_y<=des_y_0    ;end
				4:begin src_x<=des_x_0  ;src_y<=des_y_0    ;end
				5:begin src_x<=des_x_0+1;src_y<=des_y_0    ;end
				6:begin src_x<=des_x_0-1;src_y<=des_y_0+1  ;end
				7:begin src_x<=des_x_0  ;src_y<=des_y_0+1  ;end
				8:begin src_x<=des_x_0+1;src_y<=des_y_0+1  ;end
			endcase
		end
		else if(current_state==Max_pooling )begin
			case(conv_cnt_0)
				0:begin src_x<=src_img_start + 2*(des_x_0 - des_img_start)  ;src_y<=src_img_start + 2*(des_y_0 -des_img_start)  ;end
				1:begin src_x<=src_img_start + 2*(des_x_0 - des_img_start)+1;src_y<=src_img_start + 2*(des_y_0 -des_img_start)  ;end
				2:begin src_x<=src_img_start + 2*(des_x_0 - des_img_start)+1;src_y<=src_img_start + 2*(des_y_0 -des_img_start)+1;end
				3:begin src_x<=src_img_start + 2*(des_x_0 - des_img_start)  ;src_y<=src_img_start + 2*(des_y_0 -des_img_start)+1;end
			endcase
		end
		else if(current_state==Zoom_in )begin
			if(conv_cnt_0==3)begin
				if(src_x == src_img_end)begin
					src_x<=src_img_start;
					src_y<=src_y+1;	
				end
				else src_x<=src_x+1;
			end
		end
		else if(current_state==OUTPUT_cal)begin
			src_x<=src_img_start;
			src_y<=src_img_start;	
		end
		else if(next_state==Shortcut_Brightness_Adjustment)begin
			if(src_x == des_img_end)begin
				src_x<=des_img_start;
				src_y<=src_y+1;	
			end
			else src_x<=src_x+1;
		end
		else begin
			if(src_x == src_img_end)begin
				src_x<=src_img_start;
				src_y<=src_y+1;	
			end
			else src_x<=src_x+1;
		end

	end
end


/////////////pipeline stage1
always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		conv_cnt_1<=0;
		des_x_1<=0;
		des_y_1<=0;
	end
	else 
	begin
		des_x_1<=des_x_0;
		des_y_1<=des_y_0;
		conv_cnt_1<=conv_cnt_0;
	end
end

/////////////pipeline stage2
always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		conv_cnt_2<=0;
		des_x_2<=0;
		des_y_2<=0;
		valid_check_2<=0;
	end
	else 
	begin
		des_x_2<=des_x_1;
		des_y_2<=des_y_1;
		conv_cnt_2<=conv_cnt_1;
		valid_check_2<=valid_check;
	end
end

/////////////pipeline stage3
always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		conv_cnt_3<=0;
		des_x_3<=0;
		des_y_3<=0;
		valid_check_3<=0;
	end
	else 
	begin
		des_x_3<=des_x_2;
		des_y_3<=des_y_2;
		conv_cnt_3<=conv_cnt_2;
		valid_check_3<=valid_check_2;
	end
end

always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		conv_tmp<=0;
	end
	else 
	begin
		if(current_state==Cross_Correlation)begin
			if(conv_cnt_3==0)begin
				if(valid_check_3)
					conv_tmp<=raw_template[0]*read_buffer;
				else
					conv_tmp<=0;
			end
			else begin
				if(valid_check_3)
					conv_tmp<=conv_tmp+raw_template[conv_cnt_3]*read_buffer;
			end
		end
		else if(current_state==Max_pooling)begin
			if(conv_cnt_3==0)conv_tmp<=read_buffer;
			else 
				if(conv_tmp<read_buffer)conv_tmp<=read_buffer;
		end
	end
end

reg [7:0]write_limit;
always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		four_counter<=0;
	end
	else 
	begin
		if(current_state==SETUP)		four_counter<=0;
		else 	four_counter<=four_counter+1;
	end
end
always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		write_limit<=0;
	end
	else 
	begin
		if(current_state==SETUP)write_limit<=0;
		else write_limit<=write_limit+1;
	end
end
always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		MEM_des_x<=0;
		MEM_des_y<=0;
	end
	else 
	begin
		if(current_state==IDLE)
		begin
			MEM_des_x<=8-img_size/2;
			MEM_des_y<=8-img_size/2;
		end
		if(current_state==INPUT)
		begin
			if(MEM_des_x==src_img_end)begin
				MEM_des_x<=src_img_start;
				MEM_des_y<=MEM_des_y+1;
			end
			else begin
				MEM_des_x<=MEM_des_x+1;
			end
		end
		else if(current_state==SETUP)begin
			if(next_state==Zoom_in)begin
				MEM_des_x<=des_img_start;
				MEM_des_y<=des_img_start;
			end
			else begin
				MEM_des_x<=7;
				MEM_des_y<=7; //a place nevwer incur end_cal
			end
		end
		else if(current_state==Cross_Correlation)begin
			if(conv_cnt_3==8)
			begin
				MEM_des_x<=des_x_3;
				MEM_des_y<=des_y_3;
			end
		end
		else if(current_state==Max_pooling)begin
			if(conv_cnt_3==3)
			begin
				MEM_des_x<=des_x_3;
				MEM_des_y<=des_y_3;
			end
		end
		else if(current_state==Horizontal_flip || current_state==Vertical_flip || current_state==Righr_diagonal_flip ||current_state==Left_diagonal_flip)begin
			MEM_des_x<=des_x_2;
			MEM_des_y<=des_y_2;
		end
		else if(current_state==Zoom_in)begin
			case(four_counter)
				0 : begin MEM_des_x <= des_x_2    ;MEM_des_y <= des_y_2    ; end
				1 : begin MEM_des_x <= des_x_2 + 1;MEM_des_y <= des_y_2    ; end
				2 : begin MEM_des_x <= des_x_2    ;MEM_des_y <= des_y_2 + 1; end
				3 : begin MEM_des_x <= des_x_2 + 1;MEM_des_y <= des_y_2 + 1; end
			endcase
		end
		else if(current_state==Shortcut_Brightness_Adjustment)begin
			MEM_des_x<=des_x_2;
			MEM_des_y<=des_y_2;
		end
		else if(current_state==COPY)begin
			MEM_des_x<=des_x_2;
			MEM_des_y<=des_y_2;
		end
	end
end
reg signed[7:0]op1,op2,op3;
reg signed [39:0]next_w_data_buffer;
always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		w_data_buffer<=0;
	end
	else 
	begin
		if(in_valid)
		begin
			w_data_buffer<=image;
		end 
		else if(current_state==Cross_Correlation && conv_cnt_3==8)begin
			if(valid_check_3)
				w_data_buffer<=conv_tmp + raw_template[conv_cnt_3]*read_buffer;
			else
				w_data_buffer<=conv_tmp;
		end
		else if(current_state==Max_pooling && conv_cnt_3==3)begin
			if(conv_tmp<read_buffer)
				w_data_buffer<=read_buffer;
			else
				w_data_buffer<=conv_tmp;
		end
		else if(current_state>=Horizontal_flip && current_state<=Righr_diagonal_flip)begin
			w_data_buffer<=read_buffer;
		end
		else if(current_state==Zoom_in)begin
			w_data_buffer<=next_w_data_buffer;
		end
		else if(current_state==Shortcut_Brightness_Adjustment)begin
			w_data_buffer<=next_w_data_buffer;//////////////may cause problem
		end
		else
			w_data_buffer<=read_buffer;
	end
end
always@*begin
	if(current_state==Zoom_in)
		case(four_counter)
			0:begin op1 = 1;op2 = 1;op3=0;end
			1:begin op1 = 1;op2 = 3;op3=0;end
			2:begin op1 = 2;op2 = 3;op3=20;end
			3:begin op1 = 1;op2 = 2;op3={40{read_buffer[39]&&read_buffer[0]}};end
		endcase
	else 
	begin
		op1=1;op2=2;op3=read_buffer[39]&&read_buffer[0] ? 49 : 50;
	end
	next_w_data_buffer = ((read_buffer*op1)/op2)+op3;
/*
	case(four_counter)
		0:next_w_data_buffer=read_buffer;
		1:next_w_data_buffer=(read_buffer/3);
		2:next_w_data_buffer=(2*read_buffer)/3+20;
		3:next_w_data_buffer=read_buffer/2;//////////////may cause problem
	endcase*/
end
always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
		write_enable<=1;
	else 
	begin
		if(!cal_end && 
		  (in_valid || current_state==Cross_Correlation && conv_cnt_3==8 ||
		   current_state==Max_pooling && conv_cnt_3==3 ||(current_state>=Horizontal_flip&&current_state<=Righr_diagonal_flip) ||
		   current_state ==COPY || current_state==Shortcut_Brightness_Adjustment|| current_state==Zoom_in))
		begin
			write_enable<=0;
		end 
		else 
		begin
			write_enable<=1;
		end
	end
end


always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		current_img_size<=0;
	end
	else 
	begin
		if(in_valid && input_cnt == 0)begin
			current_img_size<=img_size;
		end
		else if(current_state==Max_pooling && cal_end)begin
			current_img_size<=current_img_size/2;
		end
		else if(current_state == Zoom_in && cal_end)begin
			current_img_size<=current_img_size*2;
		end
		else if(current_state == Shortcut_Brightness_Adjustment &&cal_end)begin
			if(current_img_size!=4)
				current_img_size<=current_img_size/2;
		end
	end
end

always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
	begin
		current_action<=0;
	end
	else 
	begin
		if(current_state==IDLE)begin
			current_action<=0;
		end
		if((cal_end&&action_list[current_action]!=OUTPUT_cal&&current_state!=COPY)||(MP_notDo)||ZI_notDo) begin
			current_action<=current_action+1;
		end

	end
end
always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)
		cal_end<=0;
	else 
	begin
		if( !cal_end&&((current_state==Cross_Correlation && MEM_des_x==des_img_end&&MEM_des_y==des_img_end) ||
			(current_state ==Max_pooling&&MEM_des_x==des_img_end&&MEM_des_y==des_img_end)||
			(current_state ==Horizontal_flip&&MEM_des_x==des_img_start+1&&MEM_des_y==des_img_end)||
			(current_state ==Vertical_flip&&MEM_des_y==des_img_start&&MEM_des_x==des_img_end-1)||
			(current_state ==Righr_diagonal_flip&&MEM_des_y==des_img_end-1&&MEM_des_x==des_img_end)||
			(current_state ==Left_diagonal_flip&&des_x_2==des_img_start&&des_y_2==des_img_start &&started)||
			(current_state ==Zoom_in&&MEM_des_y==des_img_end-1&&MEM_des_x==des_img_end-1&&started)||
			(current_state ==Shortcut_Brightness_Adjustment&&MEM_des_y==des_img_end&&MEM_des_x+1==des_img_end)||
			(current_state ==COPY&&MEM_des_y==des_img_end&&MEM_des_x+1==des_img_end)||
			(current_state ==OUTPUT_cal && img_pos_list_scan==7)))
			cal_end<=1;
		else 
			cal_end<=0;
	end
end



always @(posedge clk or negedge rst_n) 
begin
	if(!rst_n)begin
		conv_max<={1'b1,39'b0};
		max_x<=0;
		max_y<=0;
	end
	else 
	begin
		if(current_state==IDLE)conv_max<={1'b1,39'b0};
		else if(current_state==Cross_Correlation && conv_cnt_0==3 && write_enable==0)begin
			if(conv_tmp>conv_max)begin
				conv_max<=conv_tmp;
				max_x<=MEM_des_x-des_img_start;
				max_y<=MEM_des_y-des_img_start;
			end
		end
	end
end

always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) started <= 0;
    else if(current_state==SETUP)started<=0;
	else if(des_x_0==6&&des_y_0==6)started<=1;
end
/******************************************************************/
///////////main control end
/******************************************************************/




/******************************************************************/
///////////Output
/******************************************************************/

assign img_pos_valid[0] = !(max_x==0||max_y==0);
assign img_pos_valid[1] = !(max_y==0);
assign img_pos_valid[2] = !(max_x==current_img_size-1||max_y==0);
assign img_pos_valid[3] = !(max_x==0);
assign img_pos_valid[4] = 1;
assign img_pos_valid[5] = !(max_x==current_img_size-1);
assign img_pos_valid[6] = !(max_x==0||max_y==current_img_size-1);
assign img_pos_valid[7] = !(max_y==current_img_size-1);
assign img_pos_valid[8] = !(max_x==current_img_size-1||max_y==current_img_size-1);



reg [5:0]img_pos_list_scan_x;
reg [5:0]img_pos_list_scan_y;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		img_pos_list_idx<=0;
		img_pos_list_scan<=0;
		for(i=0;i<9;i=i+1)
			img_pos_list[i]<=0;
		img_pos_list_scan_x<=0;
		img_pos_list_scan_y<=0;
	end
	else if(current_state==OUTPUT_cal)begin
		img_pos_list_scan_x<=img_pos_list_scan_x+1;
		if(img_pos_list_scan_x==max_x+1)begin
			img_pos_list_scan_y<=img_pos_list_scan_y+1;
			img_pos_list_scan_x<=max_x-1;
		end
		
		img_pos_list_scan<=img_pos_list_scan+1;
		if(img_pos_valid[img_pos_list_scan])begin
			img_pos_list_idx<=img_pos_list_idx+1;
			img_pos_list[img_pos_list_idx]<=img_pos_list_scan_x+img_pos_list_scan_y*current_img_size;
		end
	end
	else if(current_state==Cross_Correlation)begin
		img_pos_list_idx<=0;
		img_pos_list_scan<=0;
		img_pos_list_scan_x<=max_x-1;
		img_pos_list_scan_y<=max_y-1;
	end
end


reg [3:0]img_pos_out_idx;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid   <= 0;
		out_x       <= 0;
		out_y       <= 0;
		out_img_pos <= 0;
		out_value   <= 0;
		img_pos_out_idx   <= 0;
	end
	else if(current_state == OUTPUT && conv_cnt_0>1) begin 
		out_valid   <= 1;
		out_x       <= max_y;
		out_y       <= max_x;
		if(img_pos_out_idx<img_pos_list_idx)begin
			out_img_pos <= img_pos_list[img_pos_out_idx];
			img_pos_out_idx<=img_pos_out_idx+1;
		end
		else out_img_pos<=0;
		out_value   <= read_buffer;
	end 
	else if(current_state==IDLE)begin
		out_valid   <= 0;
		out_x       <= 0;
		out_y       <= 0;
		out_img_pos <= 0;
		out_value   <= 0;
		img_pos_out_idx   <= 0;
	end
end



/******************************************************************/
///////////Output end
/******************************************************************/

endmodule
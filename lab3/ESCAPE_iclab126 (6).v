module ESCAPE(
    //Input Port
    clk,
    rst_n,
    in_valid1,
    in_valid2,
    in,
    in_data,
    //Output Port
    out_valid1,
    out_valid2,
    out,
    out_data
);

//==================INPUT OUTPUT==================//
input clk, rst_n, in_valid1, in_valid2;
input [1:0] in;
input [8:0] in_data;    
output reg	out_valid1, out_valid2;
output reg [2:0] out;
output reg [8:0] out_data;
//==================PARAMETER==================//    
parameter IDLE    = 3'd0;
parameter INPUT = 3'd1;
parameter WALKING = 3'd2;
parameter WAITING = 3'd3;
parameter WALKING2 = 3'd4;
parameter OUTPUT = 3'd5;


parameter WALL = 0;
parameter PATH = 1;
parameter TRAP = 2;
parameter HOSTAGE = 3;
parameter VISITED_NORMAL = 4;
parameter VISITED_TRAP = 5;


parameter HEIGHT = 17;
parameter WIDTH = 17;


parameter RIGHT = 0;
parameter DOWN = 1;
parameter LEFT = 2;
parameter UP = 3;
parameter STALL = 4;
parameter BACKWARD = 5;
parameter STACK_SIZE=289;
integer i,j;
//==================Register==================//
reg [3:0]next_state, current_state;
reg [2:0]map[16:0][16:0];
reg [4:0]map_input_idx1;
reg [4:0]map_input_idx2;
reg signed[5:0]pos_x,pos_y;
reg [2:0]stack_1[0:STACK_SIZE-1];  //top of stack always valid unless no data
reg [7:0]stack_1_top_idx;
reg [2:0]max_host;
reg [2:0]host_count;
reg [2:0]password_idx;
reg signed[8:0]password[3:0];
reg cleaned;
reg [2:0]count;
reg saved;
reg [2:0]out_tmp_idx;

wire [2:0]current_up,current_down,current_left,current_right;
wire left_ok,up_ok,right_ok,down_ok;
wire [2:0]next_direction; 
wire [2:0]stack_top_value;
wire signed[1:0]next_x_displace,next_y_displace;
wire [1:0]next_direction_inverse;
wire no_new_road;
wire traped;
wire [2:0]current_pos_type;
wire next_is_host;
wire [4:0]next_pos_x,next_pos_y;
wire next_is_end;
wire [8:0]out_tmp[3:0];
wire find_all_hostage;
wire at_end;

//============================================//    
//==================Design==================//


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
            IDLE: 
                if (in_valid1) next_state = INPUT;
                else next_state = current_state;
			INPUT:
				if (!in_valid1) next_state = WALKING;
                else next_state = current_state;
			WALKING:
				if (next_is_host && !traped) next_state = WAITING;
				else if(find_all_hostage && next_is_end)next_state = OUTPUT;
                else next_state = current_state;
			WAITING:
				if (in_valid2) next_state = WALKING;
                else next_state = current_state;
			OUTPUT:
				if (count==3&&(out_tmp_idx==max_host-1||max_host==0)) next_state = IDLE;
                else next_state = current_state;
			default: next_state = current_state;
        endcase
    end
end


////////////////////////////////////////////////
//design////////////////////////////////////////


///////////////////////////////////////////////
////start input

assign at_end = (pos_x==16&&pos_y==16);
assign current_up=(pos_y==0?WALL:map[pos_y-1][pos_x]);
assign current_down=(pos_y==HEIGHT-1?WALL:map[pos_y+1][pos_x]);
assign current_left=(pos_x==0?WALL:map[pos_y][pos_x-1]);
assign current_right=(pos_x==WIDTH-1?WALL:map[pos_y][pos_x+1]);


assign left_ok = (current_left==PATH ||current_left==TRAP ||current_left==HOSTAGE);
assign up_ok   = (current_up==PATH||current_up==TRAP||current_up==HOSTAGE);
assign right_ok= (current_right==PATH||current_right==TRAP||current_right==HOSTAGE);
assign down_ok = (current_down==PATH||current_down==TRAP||current_down==HOSTAGE);

assign stack_top_value = stack_1[stack_1_top_idx-1];
assign next_direction = (find_all_hostage?
	(right_ok ? RIGHT : down_ok ? DOWN : left_ok ? LEFT : up_ok ? UP : stack_top_value):
	(left_ok ? LEFT : up_ok ? UP : right_ok ? RIGHT : down_ok ? DOWN : stack_top_value));

assign next_x_displace =  (next_direction==LEFT ?-1:next_direction==RIGHT ? 1:0);
assign next_y_displace =  (next_direction==UP   ?-1:next_direction==DOWN  ? 1:0);

assign next_pos_x = next_x_displace + pos_x;
assign next_pos_y = next_y_displace + pos_y;

assign no_new_road = (!(left_ok||right_ok||up_ok||down_ok));

assign next_direction_inverse = (next_direction==LEFT?RIGHT:next_direction==RIGHT?
				LEFT:next_direction==UP?DOWN:next_direction==DOWN?UP:3'bx);
assign current_pos_type = map[pos_y][pos_x];
assign next_is_host = map[next_pos_y][next_pos_x] == HOSTAGE;
assign traped = (current_pos_type == TRAP || current_pos_type == VISITED_TRAP)&&!saved;
assign find_all_hostage = max_host == host_count;
assign next_is_end = (pos_x == 16 && pos_y == 16);

wire test_t;
assign test_t =(current_pos_type == TRAP || current_pos_type == VISITED_TRAP);


always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)begin
		host_count<=0;
	end 
	else begin
		if(current_state==IDLE)begin
			host_count<=0;
		end
		else
		begin
			if(next_is_host && (!traped))
				host_count<=host_count+1;	
		end
	end
end	

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)begin
		map_input_idx1 <=0;
		map_input_idx2 <=0;
		for(i=0;i<17;i=i+1)begin
			for(j=0;j<17;j=j+1)begin
				map[i][j]<=0;
			end
		end
		max_host<=0;
		cleaned<=0;
	end
	else
	begin		
		if(in_valid1)
		begin
			if(map_input_idx1==16)begin
				map_input_idx1<=0;
				map_input_idx2<=map_input_idx2+1;
			end
			else begin
				map_input_idx1<=map_input_idx1+1;
			end
			map[map_input_idx2][map_input_idx1] <= in;
			if(in==HOSTAGE)max_host<=max_host+1;
		end
		else if(current_state==WALKING)begin
			if(find_all_hostage && !cleaned)begin
				cleaned<=1;
				for(i=0;i<17;i=i+1)
					for(j=0;j<17;j=j+1)
						if(map[i][j]==VISITED_TRAP)map[i][j]<=TRAP;
						else if(map[i][j]==VISITED_NORMAL||map[i][j]==HOSTAGE)map[i][j]<=PATH;
			end
			else begin
				if(current_pos_type==TRAP ||current_pos_type==VISITED_TRAP)
					map[pos_y][pos_x]<=VISITED_TRAP;
				else
					map[pos_y][pos_x]<=VISITED_NORMAL;
			end
		end
		else if(current_state==IDLE)begin
			map_input_idx1<=0;
			map_input_idx2<=0;
			max_host<=0;
			cleaned<=0;
		end
	end
end

//////////////////////////////////////////////////////////////
//output with map[17][17]
//start rescue
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)begin
		pos_x<=0;
		pos_y<=0;
		saved<=0;
	end
	else
	begin	
		
		if(traped)saved<=1;
		if(current_state==WALKING && (!traped||saved) &&!(at_end&&find_all_hostage))begin
			saved<=0;
			pos_x<=next_pos_x;
			pos_y<=next_pos_y;
		end
		if(current_state==IDLE)begin
			pos_x<=0;
			pos_y<=0;
		end
	end
end



always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)begin
		stack_1_top_idx<=0;
		for(i=0;i<STACK_SIZE;i=i+1)
			stack_1[i]<=0;
	end
	else
	begin	
		//print;
		if(current_state==IDLE)begin
			stack_1_top_idx<=0;
		end
		else if(current_state== WALKING &&!traped)begin
			if(no_new_road)begin
				stack_1_top_idx<=stack_1_top_idx-1;
			end
			else begin
				stack_1_top_idx<=stack_1_top_idx+1;
				stack_1[stack_1_top_idx]<=next_direction_inverse;			
			end	
		end
	end
end

always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)begin
		out<=0;
		out_valid2<=0;
	end
	else
	begin
		if(current_state==WALKING && !(find_all_hostage&&at_end))begin
			out_valid2<=1;
			if(traped)
				out<=STALL;
			else 
				out<=next_direction;
		end
		else begin 
			out<=0;
			out_valid2<=0;
		end
	end
end


always @(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_data<=0;
		out_tmp_idx<=0;
		out_valid1<=0;
		count<=0;
	end
	else
	begin
		if(current_state==OUTPUT && count==3)begin
			out_valid1<=1;
			out_data<=out_tmp[out_tmp_idx];
			out_tmp_idx<=out_tmp_idx+1;
			
		end
		else if(current_state==OUTPUT && count<3)begin
			count<=count+1;
		end
		else if(current_state==IDLE)begin
			out_tmp_idx<=0;
			out_valid1<=0;
			out_data<=0;
			count<=0;
		end
	end
end
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n)begin
		password_idx<=0;
		for(i=0;i<4;i=i+1)
			password[i]<=-256;
	end
	else
	begin
		if(in_valid2)begin
			password_idx<=password_idx+1;
			password[password_idx]<=in_data;
		end
		else if(current_state==IDLE)begin
			password_idx<=0;
			for(i=0;i<4;i=i+1)
				password[i]<=-256;
		end
	end
end

CC CC1(clk,rst_n,password[0],password[1],password[2],password[3],max_host,out_tmp[0],out_tmp[1],out_tmp[2],out_tmp[3]);

/*
task print;begin
	$display("/////////////////////////////////////////////////////");
	$display("DESIGN:");
	for(i=0;i<stack_1_top_idx;i=i+1)
		$write(stack_1[i]);
	$display("");
	for(i=0;i<17;i=i+1)begin
		for(j=0;j<17;j=j+1)begin
			if(i==pos_y && j==pos_x)$write(" *");
			else begin 
				$write(" ");
				$write(map[i][j]);
			end
		end
		$display("");
	end
	$display("\n\n");

end endtask
*/


//==========================================//  

endmodule




module CC(
clk,
rst_n,
	in_n0,
	in_n1, 
	in_n2, 
	in_n3, 
	opt,
	out_0,
	out_1,
	out_2,
	out_3
);
input wire clk;
input wire rst_n;
input wire signed [8:0]in_n0;
input wire signed [8:0]in_n1;
input wire signed [8:0]in_n2;
input wire signed [8:0]in_n3;
input wire [2:0] opt;
output reg signed[8:0] out_0,out_1,out_2,out_3;
//==================================================================
// reg & wire
//==================================================================
wire signed[8:0]node00,node01,node02,node03,node11,node12;
wire signed[8:0]knode00,knode01,knode02,knode03,knode11,knode12;
	
wire signed[8:0]sorted0,sorted1,sorted2,sorted3;	

reg signed[8:0] k[3:0];
wire signed[8:0] k_sort[3:0];

//==================================================================
// sorting in increasing order sorted0~sorted5
//==================================================================
cmp cmp0 (.A(in_n0 ),.B(in_n1 ),.node0(node00 ),.node1(node01) ); //sort n0,n1
cmp cmp1 (.A(in_n2 ),.B(in_n3 ),.node0(node02 ),.node1(node03) ); //sort n2,n3
cmp cmp3 (.A(node00),.B(node02),.node0(sorted0 ),.node1(node12) ); //sort n0,n2
cmp cmp7 (.A(node01),.B(node03),.node0(node11 ),.node1(sorted3) ); //sort n1,n2
cmp cmp11(.A(node11),.B(node12),.node0(sorted1),.node1(sorted2)); //sort n2,n3

//output sort0~sort3
cmp kcmp0 (.A(k[0] ),.B(k[1] ),.node0(knode00 ),.node1(knode01) ); //sort n0,n1
cmp kcmp1 (.A(k[2] ),.B(k[3] ),.node0(knode02 ),.node1(knode03) ); //sort n2,n3
cmp kcmp3 (.A(knode00),.B(knode02),.node0(k_sort[0] ),.node1(knode12) ); //sort n0,n2
cmp kcmp7 (.A(knode01),.B(knode03),.node0(knode11 ), .node1(k_sort[3]) ); //sort n1,n2
cmp kcmp11(.A(knode11),.B(knode12),.node0(k_sort[1]), .node1(k_sort[2])); //sort n2,n3

//output n0~n5
//==================================================================
// shifting and moving avg
//==================================================================


wire signed[8:0]mean = (k_sort[0]+k_sort[opt-1])/2;

wire signed[8:0]m0,m1,m2,m3;
assign m0=k[0]-mean;
assign m1=k[1]-mean;
assign m2=k[2]-mean;
assign m3=k[3]-mean;

wire signed[8:0]c0,c1,c2,c3;
assign c0=m0;
assign c1=(m0*2+m1)/3;
assign c2=(c1*2+m2)/3;
assign c3=(c2*2+m3)/3;
/*
wire signed[10:0]tmp_1 = m0*2+m1;
div_3 div_3_1(.in(tmp_1),.out(c1));

wire signed[10:0]tmp_2 = c1*2+m2;
div_3 div_3_2(.in(tmp_2),.out(c2));

wire signed[6:0]tmp_3 = c2*2+m3;
div_3 div_3_3(.in(tmp_3),.out(c3));
*/

always @*begin
	out_0='b0;out_1='b0;out_2='b0;out_3='b0;
	case(opt)
		0:out_0 = 0;
		1:out_0 = in_n0;
		2:begin out_0 = m0;out_1 = m1;end
		3:begin out_0 = c0;out_1 = c1;out_2 = c2;end
		4:begin out_0 = c0;out_1 = c1;out_2 = c2;out_3 = c3;end
	endcase
end
reg signed[8:0]tmp_k[3:0];
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		tmp_k[0]<=0;
		tmp_k[1]<=0;
		tmp_k[2]<=0;
		tmp_k[3]<=0;
	end
	else begin
		tmp_k[0]<=(opt[0]?sorted0:((sorted0[8]?-1:1)*((sorted0[7:4]-3)*10+sorted0[3:0]-3)));
		tmp_k[1]<=(opt[0]?sorted1:((sorted1[8]?-1:1)*((sorted1[7:4]-3)*10+sorted1[3:0]-3)));
		tmp_k[2]<=(opt[0]?sorted2:((sorted2[8]?-1:1)*((sorted2[7:4]-3)*10+sorted2[3:0]-3)));
		tmp_k[3]<=(opt[0]?sorted3:((sorted3[8]?-1:1)*((sorted3[7:4]-3)*10+sorted3[3:0]-3)));
	
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		k[0]<=0;
		k[1]<=0;
		k[2]<=0;
		k[3]<=0;
	end
	else begin
		if(opt==3)begin
			k[0]<=tmp_k[0];
			k[1]<=tmp_k[1];
			k[2]<=tmp_k[2];
			k[3]<=-256;
		end else if(opt==2)begin
			k[0]<=tmp_k[0];
			k[1]<=tmp_k[1];
			k[2]<=-256;
			k[3]<=-256;
		end
		else begin
			k[0]<=tmp_k[0];
			k[1]<=tmp_k[1];
			k[2]<=tmp_k[2];
			k[3]<=tmp_k[3];
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
	input signed[8:0]A;
	input signed[8:0]B;
	output wire signed [8:0] node0;
	output wire signed [8:0] node1;

	
	assign node0 = (A>B ? A : B);
	assign node1 = (A>B ? B : A);
	

endmodule
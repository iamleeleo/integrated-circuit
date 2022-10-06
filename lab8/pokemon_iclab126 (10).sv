module pokemon(input clk, INF.pokemon_inf inf);
import usertype::*;

//================================================================
// logic 
//================================================================
parameter WAIT_LIMIT = 10;
logic [4:0]cnt;
logic wait_over;
State current_state,next_state;
Action current_action;

Player_Info player0_inf;
Player_Info player1_inf;

Money_ext current_amnt;
DATA cal_data;
Item current_item;
PKM_Type current_type;
reg buy_pkm;
wire any_valid;
//*******table output********/
reg [6:0]player0_atk;
reg [6:0]player0_next_exp;
reg [6:0]player1_next_exp;
reg [7:0]player0_max_hp;
reg [8:0]player0_true_attack;
reg [5:0]player0_exp_get;
reg [5:0]player1_exp_get;
reg [6:0]player0_eva_atk;
reg [6:0]player1_eva_atk;
reg [7:0]player0_eva_hp;
reg [7:0]player1_eva_hp;
//================================================================
// design 
//================================================================
always@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		current_state<=IDLE;
	end
	else
	begin
		current_state<=next_state;
	end
end

always@(*)begin
	next_state = current_state;
	case(current_state)
		IDLE	 :begin
			if(inf.id_valid)next_state = WAIT0;
		end
		WAIT0	 :begin
			if(cnt==WAIT_LIMIT && wait_over)begin
				if(current_action==Attack)
					next_state = WAIT1;
				else 
					next_state = CALCULATE;
			end
		end
		WAIT1	 :begin
			if(cnt==WAIT_LIMIT && wait_over)next_state = CALCULATE;
		end
		CALCULATE:begin
			if(current_action==Attack)next_state = WAIT2;
			else next_state = WAIT_NEXT;
		end
		WAIT2	 :begin
			if(wait_over)next_state = WAIT_NEXT;
		end
        WAIT_NEXT:begin
			if(inf.id_valid)next_state = WAIT3;
			else if(inf.act_valid && inf.D.d_act==Attack)next_state = WAIT_ID;
			else if(inf.act_valid && inf.D.d_act!=Attack)next_state = WAIT_ID;
		end
		WAIT_ID:
			if(cnt==WAIT_LIMIT)next_state = WAIT1;
		WAIT3	 :begin
			if(wait_over)next_state = WAIT0;
		end
	endcase
end


Player_id player0_ID,player1_ID;

assign any_valid = (inf.id_valid||inf.act_valid||inf.item_valid||inf.type_valid||inf.amnt_valid);
always@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		player0_ID<=0;
		player1_ID<=0;
	end
	else
	begin
		if(inf.id_valid)
			if(current_state==WAIT0||current_state==WAIT1||current_state==WAIT3||current_state==WAIT_ID)
				player1_ID<=inf.D.d_id;
			else
				player0_ID<=inf.D.d_id;
	end
end
wire [31:0]tmp1 = inf.C_data_r[31:0];
wire [31:0]tmp2 = inf.C_data_r[63:32];
wire [31:0]bag_info_reorder = {tmp1[7:4],tmp1[3:0],tmp1[15:12],tmp1[11:8],tmp1[23:20],tmp1[19:16],tmp1[31:28],tmp1[27:24]};
wire [31:0]pkm_info_reorder = {tmp2[7:4],tmp2[3:0],tmp2[15:12],tmp2[11:8],tmp2[23:20],tmp2[19:16],tmp2[31:28],tmp2[27:24]};

wire [31:0]tmp3 = player0_inf.pkm_info;
wire [31:0]tmp4 = player1_inf.pkm_info;
wire [31:0]tmp5 = player0_inf.bag_info;
wire [31:0]tmp6 = player1_inf.bag_info;
wire [31:0]player0_pkm_info_dram_fmt = {tmp3[7:4],tmp3[3:0],1'b0	   ,player0_atk,tmp3[23:20],tmp3[19:16],tmp3[31:28],tmp3[27:24]};
wire [31:0]player1_pkm_info_dram_fmt = {tmp4[7:4],tmp4[3:0],tmp4[15:12],tmp4[11:8] ,tmp4[23:20],tmp4[19:16],tmp4[31:28],tmp4[27:24]};
wire [31:0]player0_bag_info_dram_fmt = {tmp5[7:4],tmp5[3:0],tmp5[15:12],tmp5[11:8] ,tmp5[23:20],tmp5[19:16],tmp5[31:28],tmp5[27:24]};
wire [31:0]player1_bag_info_dram_fmt = {tmp6[7:4],tmp6[3:0],tmp6[15:12],tmp6[11:8] ,tmp6[23:20],tmp6[19:16],tmp6[31:28],tmp6[27:24]};


wire no_pkm = player0_inf.pkm_info.pkm_type == No_type || player1_inf.pkm_info.pkm_type == No_type;
wire no_hp = player0_inf.pkm_info.hp == 0 ||player1_inf.pkm_info.hp == 0;
wire can_attack = (!no_pkm&&!no_hp);
//wire no_item = (player0_inf.bag_info.current_item==0);


reg player0_eva_flag;
reg player1_eva_flag;
reg bracer_flag;

always@(posedge clk or negedge inf.rst_n)begin//
	if(!inf.rst_n)begin
		player0_inf<=0;
		player1_inf<=0;
		bracer_flag<=0;
	end
	else begin//
		if(inf.C_out_valid)
			case(current_state)
				WAIT0:begin
					player0_inf.bag_info<=bag_info_reorder;
					player0_inf.pkm_info<=pkm_info_reorder;
				end
				WAIT1:begin
					player1_inf.bag_info<=bag_info_reorder;
					player1_inf.pkm_info<=pkm_info_reorder;
				end
			endcase
		else if(current_state==CALCULATE)begin
			case(current_action)
				Attack:begin
					if(can_attack)begin
						bracer_flag<=0;
						if(bracer_flag)player0_inf.pkm_info.atk<=player0_atk;
						//player 1 exp handle
						if(player1_inf.pkm_info.pkm_type==Normal)begin
							if((player1_inf.pkm_info.exp+player1_exp_get)>=29)player1_inf.pkm_info.exp<=29;
							else player1_inf.pkm_info.exp<=player1_inf.pkm_info.exp+player1_exp_get;
						end
						else if(player1_inf.pkm_info.exp+player1_exp_get>=player1_next_exp)begin
							if(player1_inf.pkm_info.stage==Middle)player1_inf.pkm_info.stage<=Highest;
							else player1_inf.pkm_info.stage<=Middle;
							player1_inf.pkm_info.atk<=player1_eva_atk;
							player1_inf.pkm_info.exp<=0;
							player1_inf.pkm_info.hp<=player1_eva_hp;
						end
						else begin
							player1_inf.pkm_info.exp<=player1_inf.pkm_info.exp+player1_exp_get;
						end
						
						
						//player 0 exp handle
						if(player0_inf.pkm_info.pkm_type==Normal)begin
							if(player0_inf.pkm_info.exp+player0_exp_get>=29)player0_inf.pkm_info.exp<=29;
							else player0_inf.pkm_info.exp<=player0_inf.pkm_info.exp+player0_exp_get;
						end						
						else if(player0_inf.pkm_info.exp+player0_exp_get>=player0_next_exp)begin
							if(player0_inf.pkm_info.stage==Middle)player0_inf.pkm_info.stage<=Highest;
							else player0_inf.pkm_info.stage<=Middle;
							player0_inf.pkm_info.atk<=player0_eva_atk;
							player0_inf.pkm_info.exp<=0;
							player0_inf.pkm_info.hp<=player0_eva_hp;
							bracer_flag<=0;
						end
						else begin
							player0_inf.pkm_info.exp<=player0_inf.pkm_info.exp+player0_exp_get;
						end


						//player 1 hp handle
						if(player1_inf.pkm_info.exp+player1_exp_get>=player1_next_exp && player1_inf.pkm_info.pkm_type!=Normal)
							player1_inf.pkm_info.hp<=player1_eva_hp;
						else if(player1_inf.pkm_info.hp>=player0_true_attack)
							player1_inf.pkm_info.hp<=player1_inf.pkm_info.hp-player0_true_attack;
						else
							player1_inf.pkm_info.hp<=0;
					end
				end
				Use_item:begin
					if(player0_inf.pkm_info.pkm_type != No_type)
						case(current_item)
							Berry	       :begin
								if(player0_inf.bag_info.berry_num>0)begin
									player0_inf.bag_info.berry_num<=player0_inf.bag_info.berry_num-1;
									if(player0_inf.pkm_info.hp+32>player0_max_hp)player0_inf.pkm_info.hp<=player0_max_hp;
									else player0_inf.pkm_info.hp<=player0_inf.pkm_info.hp+32;
								end
							end
							Medicine       :begin
								if(player0_inf.bag_info.medicine_num>0)begin
								
									player0_inf.bag_info.medicine_num<=player0_inf.bag_info.medicine_num-1;
									player0_inf.pkm_info.hp<=player0_max_hp;							
								end
							end
							Candy		   :begin
								if(player0_inf.bag_info.candy_num>0 )begin
								
									player0_inf.bag_info.candy_num<=player0_inf.bag_info.candy_num-1;
									if(player0_inf.pkm_info.stage!=Highest)
										if(player0_inf.pkm_info.pkm_type==Normal)begin
											if(player0_inf.pkm_info.exp+15>=29)player0_inf.pkm_info.exp<=29;
											else player0_inf.pkm_info.exp<=player0_inf.pkm_info.exp+15;
										end						
										else if(player0_inf.pkm_info.exp+15>=player0_next_exp)begin
											if(player0_inf.pkm_info.stage==Middle)player0_inf.pkm_info.stage<=Highest;
											else player0_inf.pkm_info.stage<=Middle;
											player0_inf.pkm_info.atk<=player0_eva_atk;
											player0_inf.pkm_info.exp<=0;
											player0_inf.pkm_info.hp<=player0_eva_hp;
											bracer_flag<=0;
										end
										else begin
											player0_inf.pkm_info.exp<=player0_inf.pkm_info.exp+15;
										end	
								end
							end
							Bracer	       :begin
								if(player0_inf.bag_info.bracer_num>0)begin
									player0_inf.bag_info.bracer_num<=player0_inf.bag_info.bracer_num-1;
									if(bracer_flag==0)player0_inf.pkm_info.atk<=player0_inf.pkm_info.atk+32;
									bracer_flag<=1;
								end
							end
							Water_stone	   :begin
								if(player0_inf.bag_info.stone==W_stone)begin
									player0_inf.bag_info.stone<=No_stone;
									if(player0_inf.pkm_info.pkm_type==Normal&&player0_inf.pkm_info.exp==29)begin
										player0_inf.pkm_info.stage <= Highest;
										player0_inf.pkm_info.pkm_type <= Water;
										player0_inf.pkm_info.hp <= 245;
										player0_inf.pkm_info.atk <= 113;
										player0_inf.pkm_info.exp <= 0;
										bracer_flag<=0;
									end
								end
							end
							Fire_stone	   :begin
								if(player0_inf.bag_info.stone==F_stone)begin
									player0_inf.bag_info.stone<=No_stone;
									if(player0_inf.pkm_info.pkm_type==Normal&&player0_inf.pkm_info.exp==29)begin
										player0_inf.pkm_info.stage <= Highest;
										player0_inf.pkm_info.pkm_type <= Fire;
										player0_inf.pkm_info.hp <= 225;
										player0_inf.pkm_info.atk <= 127;
										player0_inf.pkm_info.exp <= 0;
										bracer_flag<=0;
									end
								end
							end
							Thunder_stone  :begin
								if(player0_inf.bag_info.stone==T_stone)begin
									player0_inf.bag_info.stone<=No_stone;
									if(player0_inf.pkm_info.pkm_type==Normal&&player0_inf.pkm_info.exp==29)begin
										player0_inf.pkm_info.stage <= Highest;
										player0_inf.pkm_info.pkm_type <= Electric;
										player0_inf.pkm_info.hp <= 235;
										player0_inf.pkm_info.atk <= 124;
										player0_inf.pkm_info.exp <= 0;
										bracer_flag<=0;
									end
								end
							end
						endcase
				end
				Deposit:begin
					player0_inf.bag_info.money <= player0_inf.bag_info.money + current_amnt;
				end
				Buy:begin
					if(buy_pkm)begin
						if(player0_inf.pkm_info==No_type)begin

							case(current_type)
								Grass:begin
									if(player0_inf.bag_info.money>=100)begin
										player0_inf.pkm_info.pkm_type<=Grass;
										player0_inf.pkm_info.stage<=Lowest;									
										player0_inf.pkm_info.hp<=128;
										player0_inf.pkm_info.atk<=63;
										player0_inf.bag_info.money<=player0_inf.bag_info.money-100;
									end
								end
								Fire:begin
									if(player0_inf.bag_info.money>=90)begin
										player0_inf.pkm_info.pkm_type<=Fire;
										player0_inf.pkm_info.stage<=Lowest;									
										player0_inf.pkm_info.hp<=119;
										player0_inf.pkm_info.atk<=64;
										player0_inf.bag_info.money<=player0_inf.bag_info.money-90;
									end							
								end
								Water:begin
									if(player0_inf.bag_info.money>=110)begin
										player0_inf.pkm_info.pkm_type<=Water;
										player0_inf.pkm_info.stage<=Lowest;									
										player0_inf.pkm_info.hp<=125;
										player0_inf.pkm_info.atk<=60;
										player0_inf.bag_info.money<=player0_inf.bag_info.money-110;
									end								
								end
								Electric:begin
									if(player0_inf.bag_info.money>=120)begin
										player0_inf.pkm_info.pkm_type<=Electric;
										player0_inf.pkm_info.stage<=Lowest;									
										player0_inf.pkm_info.hp<=122;
										player0_inf.pkm_info.atk<=65;
										player0_inf.bag_info.money<=player0_inf.bag_info.money-120;
									end								
								end
								Normal:begin
									if(player0_inf.bag_info.money>=130)begin
										player0_inf.pkm_info.pkm_type<=Normal;
										player0_inf.pkm_info.stage<=Lowest;									
										player0_inf.pkm_info.hp<=124;
										player0_inf.pkm_info.atk<=62;
										player0_inf.bag_info.money<=player0_inf.bag_info.money-130;
									end								
								end
							endcase
						end
					end
					else begin //buy item
						case(current_item)
							Berry	       :begin
								if(player0_inf.bag_info.berry_num!=15 && player0_inf.bag_info.money>=16)begin
									player0_inf.bag_info.berry_num<=player0_inf.bag_info.berry_num+1;
									player0_inf.bag_info.money<=player0_inf.bag_info.money-16;
								end
							end
							Medicine       :begin
								if(player0_inf.bag_info.medicine_num!=15 && player0_inf.bag_info.money>=128)begin
									player0_inf.bag_info.medicine_num<=player0_inf.bag_info.medicine_num+1;
									player0_inf.bag_info.money<=player0_inf.bag_info.money-128;								
								end
							end
							Candy		   :begin
								if(player0_inf.bag_info.candy_num!=15 && player0_inf.bag_info.money>=300 )begin
									player0_inf.bag_info.candy_num<=player0_inf.bag_info.candy_num+1;
									player0_inf.bag_info.money<=player0_inf.bag_info.money-300;								
								end
							end
							Bracer	       :begin
								if(player0_inf.bag_info.bracer_num!=15 && player0_inf.bag_info.money>=64)begin
									player0_inf.bag_info.bracer_num<=player0_inf.bag_info.bracer_num+1;
									player0_inf.bag_info.money<=player0_inf.bag_info.money-64;								
								end
							end
							Water_stone:begin
								if(player0_inf.bag_info.stone==No_stone && player0_inf.bag_info.money>=800)begin
									player0_inf.bag_info.stone<=W_stone;
									player0_inf.bag_info.money<=player0_inf.bag_info.money-800;								
								end
							end
							Fire_stone:begin
								if(player0_inf.bag_info.stone==No_stone && player0_inf.bag_info.money>=800)begin
									player0_inf.bag_info.stone<=F_stone;
									player0_inf.bag_info.money<=player0_inf.bag_info.money-800;								
								end
							end
							Thunder_stone:begin
								if(player0_inf.bag_info.stone==No_stone && player0_inf.bag_info.money>=800)begin
									player0_inf.bag_info.stone<=T_stone;
									player0_inf.bag_info.money<=player0_inf.bag_info.money-800;								
								end
							end
						endcase					
					end
				end
				Sell:begin
					if(buy_pkm)begin //same as sell pkm 
						if(player0_inf.pkm_info.stage!=No_stage&&player0_inf.pkm_info.stage!=Lowest)begin
							player0_inf.pkm_info.stage<=No_stage;									
							player0_inf.pkm_info.pkm_type<=No_type;
							player0_inf.pkm_info.hp<=0;
							player0_inf.pkm_info.atk<=0;
							player0_inf.pkm_info.exp<=0;
							bracer_flag<=0;
							case(player0_inf.pkm_info.pkm_type)
								Grass:begin
									if(player0_inf.pkm_info.stage==Middle)player0_inf.bag_info.money<=player0_inf.bag_info.money+510;
									else player0_inf.bag_info.money<=player0_inf.bag_info.money+1100;
								end
								Fire:begin
									if(player0_inf.pkm_info.stage==Middle)player0_inf.bag_info.money<=player0_inf.bag_info.money+450;
									else player0_inf.bag_info.money<=player0_inf.bag_info.money+1000;					
								end
								Water:begin
									if(player0_inf.pkm_info.stage==Middle)player0_inf.bag_info.money<=player0_inf.bag_info.money+500;
									else player0_inf.bag_info.money<=player0_inf.bag_info.money+1200;							
								end
								Electric:begin
									if(player0_inf.pkm_info.stage==Middle)player0_inf.bag_info.money<=player0_inf.bag_info.money+550;
									else player0_inf.bag_info.money<=player0_inf.bag_info.money+1300;									
								end
							endcase
						end
					end
					else begin //sell item
						case(current_item)
							Berry	       :begin
								if(player0_inf.bag_info.berry_num!=0)begin
									player0_inf.bag_info.berry_num<=player0_inf.bag_info.berry_num-1;
									player0_inf.bag_info.money<=player0_inf.bag_info.money+12;
								end
							end
							Medicine       :begin
								if(player0_inf.bag_info.medicine_num!=0)begin
									player0_inf.bag_info.medicine_num<=player0_inf.bag_info.medicine_num-1;
									player0_inf.bag_info.money<=player0_inf.bag_info.money+96;								
								end
							end
							Candy		   :begin
								if(player0_inf.bag_info.candy_num!=0)begin
									player0_inf.bag_info.candy_num<=player0_inf.bag_info.candy_num-1;
									player0_inf.bag_info.money<=player0_inf.bag_info.money+225;								
								end
							end
							Bracer	       :begin
								if(player0_inf.bag_info.bracer_num!=0)begin
									player0_inf.bag_info.bracer_num<=player0_inf.bag_info.bracer_num-1;
									player0_inf.bag_info.money<=player0_inf.bag_info.money+48;								
								end
							end
							Water_stone:begin
								if(player0_inf.bag_info.stone==W_stone)begin
									player0_inf.bag_info.stone<=No_stone;
									player0_inf.bag_info.money<=player0_inf.bag_info.money+600;								
								end
							end
							Fire_stone:begin
								if(player0_inf.bag_info.stone==F_stone)begin
									player0_inf.bag_info.stone<=No_stone;
									player0_inf.bag_info.money<=player0_inf.bag_info.money+600;								
								end
							end
							Thunder_stone:begin
								if(player0_inf.bag_info.stone==T_stone)begin
									player0_inf.bag_info.stone<=No_stone;
									player0_inf.bag_info.money<=player0_inf.bag_info.money+600;								
								end
							end
						endcase					
					end					
				end
			endcase
		end	
		else if(current_state==WAIT3)begin //attack , sell 
			bracer_flag<=0;
		end
	end//
end//


/*****************************************************************/
//////tables
/*****************************************************************/

//table3

//table4

always@*begin
	player0_next_exp = 32;
	case({player0_inf.pkm_info.stage,player0_inf.pkm_info.pkm_type})
			{Lowest,Grass}:   begin player0_next_exp=32;end
			{Lowest,Fire}:    begin player0_next_exp=30;end
			{Lowest,Water}:   begin player0_next_exp=28;end
			{Lowest,Electric}:begin player0_next_exp=26;end
			{Lowest,Normal}:  begin player0_next_exp=29;end
			{Middle,Grass}:   begin player0_next_exp=63;end
			{Middle,Fire}:    begin player0_next_exp=59;end
			{Middle,Water}:   begin player0_next_exp=55;end
			{Middle,Electric}:begin player0_next_exp=51;end
	endcase
end

always@*begin
	player1_next_exp=32;
	case({player1_inf.pkm_info.stage,player1_inf.pkm_info.pkm_type})
		{Lowest,Grass}:   begin player1_next_exp=32;end
		{Lowest,Fire}:    begin player1_next_exp=30;end
		{Lowest,Water}:   begin player1_next_exp=28;end
		{Lowest,Electric}:begin player1_next_exp=26;end
		{Lowest,Normal}:  begin player1_next_exp=29;end
		{Middle,Grass}:   begin player1_next_exp=63;end
		{Middle,Fire}:    begin player1_next_exp=59;end
		{Middle,Water}:   begin player1_next_exp=55;end
		{Middle,Electric}:begin player1_next_exp=51;end
	endcase
end

always@*begin
	player0_atk = 0;
	case({player0_inf.pkm_info.stage,player0_inf.pkm_info.pkm_type})
			{Lowest,Grass}:    begin player0_atk=63;end
			{Lowest,Fire}:     begin player0_atk=64;end
			{Lowest,Water}:    begin player0_atk=60;end
			{Lowest,Electric}: begin player0_atk=65;end
			{Lowest,Normal}:   begin player0_atk=62;end
			{Middle,Grass}:    begin player0_atk=94;end
			{Middle,Fire}:     begin player0_atk=96;end
			{Middle,Water}:    begin player0_atk=89;end
			{Middle,Electric}: begin player0_atk=97;end
			{Highest,Grass}:   begin player0_atk=123;end
			{Highest,Fire}:    begin player0_atk=127;end
			{Highest,Water}:   begin player0_atk=113;end
			{Highest,Electric}:begin player0_atk=124;end
	endcase
end


always@*begin
	player0_eva_atk = 94;
	player1_eva_atk = 94;
	case({player0_inf.pkm_info.stage,player0_inf.pkm_info.pkm_type})
			{Lowest,Grass}:    begin player0_eva_atk=94;end
			{Lowest,Fire}:     begin player0_eva_atk=96;end
			{Lowest,Water}:    begin player0_eva_atk=89;end
			{Lowest,Electric}: begin player0_eva_atk=97;end
			{Middle,Grass}:    begin player0_eva_atk=123;end
			{Middle,Fire}:     begin player0_eva_atk=127;end
			{Middle,Water}:    begin player0_eva_atk=113;end
			{Middle,Electric}: begin player0_eva_atk=124;end
	endcase
	case({player1_inf.pkm_info.stage,player1_inf.pkm_info.pkm_type})
			{Lowest,Grass}:    begin player1_eva_atk=94;end
			{Lowest,Fire}:     begin player1_eva_atk=96;end
			{Lowest,Water}:    begin player1_eva_atk=89;end
			{Lowest,Electric}: begin player1_eva_atk=97;end
			{Middle,Grass}:    begin player1_eva_atk=123;end
			{Middle,Fire}:     begin player1_eva_atk=127;end
			{Middle,Water}:    begin player1_eva_atk=113;end
			{Middle,Electric}: begin player1_eva_atk=124;end
	endcase
end
always@*begin
	player0_eva_hp = 94;
	player1_eva_hp = 94;
	case({player0_inf.pkm_info.stage,player0_inf.pkm_info.pkm_type})
			{Lowest,Grass}:    begin player0_eva_hp=192;end
			{Lowest,Fire}:     begin player0_eva_hp=177;end
			{Lowest,Water}:    begin player0_eva_hp=187;end
			{Lowest,Electric}: begin player0_eva_hp=182;end
			{Middle,Grass}:    begin player0_eva_hp=254;end
			{Middle,Fire}:     begin player0_eva_hp=225;end
			{Middle,Water}:    begin player0_eva_hp=245;end
			{Middle,Electric}: begin player0_eva_hp=235;end
	endcase
	case({player1_inf.pkm_info.stage,player1_inf.pkm_info.pkm_type})
			{Lowest,Grass}:    begin player1_eva_hp=192;end
			{Lowest,Fire}:     begin player1_eva_hp=177;end
			{Lowest,Water}:    begin player1_eva_hp=187;end
			{Lowest,Electric}: begin player1_eva_hp=182;end
			{Middle,Grass}:    begin player1_eva_hp=254;end
			{Middle,Fire}:     begin player1_eva_hp=225;end
			{Middle,Water}:    begin player1_eva_hp=245;end
			{Middle,Electric}: begin player1_eva_hp=235;end
	endcase
end
always@*begin
	player0_max_hp = 128;
	case( {player0_inf.pkm_info.stage,player0_inf.pkm_info.pkm_type} )
			{Lowest,Grass}:    begin player0_max_hp=128;end
			{Lowest,Fire}:     begin player0_max_hp=119;end
			{Lowest,Water}:    begin player0_max_hp=125;end
			{Lowest,Electric}: begin player0_max_hp=122;end
			{Lowest,Normal}:   begin player0_max_hp=124;end
			{Middle,Grass}:    begin player0_max_hp=192;end
			{Middle,Fire}:     begin player0_max_hp=177;end
			{Middle,Water}:    begin player0_max_hp=187;end
			{Middle,Electric}: begin player0_max_hp=182;end
			{Highest,Grass}:   begin player0_max_hp=254;end
			{Highest,Fire}:    begin player0_max_hp=225;end
			{Highest,Water}:   begin player0_max_hp=245;end
			{Highest,Electric}:begin player0_max_hp=235;end
	endcase
end


/*****************************************************************/


//table6

always@*begin
	player0_true_attack = player0_atk;
	case({player0_inf.pkm_info.pkm_type,player1_inf.pkm_info.pkm_type})
			{Grass,Grass}:      begin player0_true_attack=(player0_inf.pkm_info.atk>>1);end
			{Grass,Fire}:       begin player0_true_attack=(player0_inf.pkm_info.atk>>1);end
			{Grass,Water}:      begin player0_true_attack=(player0_inf.pkm_info.atk<<1);end
			{Grass,Electric}:   begin player0_true_attack=(player0_inf.pkm_info.atk);end
			{Grass,Normal}:     begin player0_true_attack=(player0_inf.pkm_info.atk);end
			{Fire,Grass}:       begin player0_true_attack=(player0_inf.pkm_info.atk<<1);end
			{Fire,Fire}:        begin player0_true_attack=(player0_inf.pkm_info.atk>>1);end
			{Fire,Water}:       begin player0_true_attack=(player0_inf.pkm_info.atk>>1);end
			{Fire,Electric}:    begin player0_true_attack=(player0_inf.pkm_info.atk);end
			{Fire,Normal}:      begin player0_true_attack=(player0_inf.pkm_info.atk);end
			{Water,Grass}:      begin player0_true_attack=(player0_inf.pkm_info.atk>>1);end
			{Water,Fire}:       begin player0_true_attack=(player0_inf.pkm_info.atk<<1);end
			{Water,Water}:      begin player0_true_attack=(player0_inf.pkm_info.atk>>1);end
			{Water,Electric}:   begin player0_true_attack=(player0_inf.pkm_info.atk);end
			{Water,Normal}:     begin player0_true_attack=(player0_inf.pkm_info.atk);end
			{Electric,Grass}:   begin player0_true_attack=(player0_inf.pkm_info.atk>>1);end
			{Electric,Fire}:    begin player0_true_attack=(player0_inf.pkm_info.atk);end
			{Electric,Water}:   begin player0_true_attack=(player0_inf.pkm_info.atk<<1);end
			{Electric,Electric}:begin player0_true_attack=(player0_inf.pkm_info.atk>>1);end
			{Electric,Normal}:  begin player0_true_attack=(player0_inf.pkm_info.atk);end
			{Normal,Grass}:     begin player0_true_attack=(player0_inf.pkm_info.atk);end
			{Normal,Fire}:      begin player0_true_attack=(player0_inf.pkm_info.atk);end
			{Normal,Water}:     begin player0_true_attack=(player0_inf.pkm_info.atk);end
			{Normal,Electric}:  begin player0_true_attack=(player0_inf.pkm_info.atk);end
			{Normal,Normal}:    begin player0_true_attack=(player0_inf.pkm_info.atk);end
	endcase
end


//table7

always@*begin
	player0_exp_get = 16;
	case(player1_inf.pkm_info.stage)
		Lowest:player0_exp_get=16;
		Middle:player0_exp_get=24;
		Highest:player0_exp_get=32;
	endcase
	if(player0_inf.pkm_info.stage==Highest)player0_exp_get=0;
end
always@*begin
	player1_exp_get = 8;
	case(player0_inf.pkm_info.stage)
		Lowest:player1_exp_get=8;
		Middle:player1_exp_get=12;
		Highest:player1_exp_get=16;
	endcase
	if(player1_inf.pkm_info.stage==Highest)player1_exp_get=0;
end
/************************************************************************************/
//////table end
/***********************************************************************************/

always@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.err_msg<=No_Err;
		inf.complete<=0;
	end
	else
	begin
		if(current_state==CALCULATE)
			case(current_action)
				Attack:begin
					if(no_pkm)begin
						inf.complete<=0;
						inf.err_msg<=Not_Having_PKM;
					end
					else if(no_hp)begin
						inf.complete<=0;
						inf.err_msg<=HP_is_Zero;
					end
					else begin
						inf.complete<=1;
						inf.err_msg <=No_Err;
					end
				end
				Check,Deposit:begin
					inf.complete<=1;
					inf.err_msg <=No_Err;				
				end
				Use_item:begin

					if(player0_inf.pkm_info.pkm_type == No_type)begin
						inf.complete<=0;
						inf.err_msg <=Not_Having_PKM;						
					end	
					else if(
					(current_item==Berry        &&player0_inf.bag_info.berry_num==0)	    ||
					(current_item==Medicine		&&player0_inf.bag_info.medicine_num==0)     ||
					(current_item==Candy		&&player0_inf.bag_info.candy_num==0)	    ||
					(current_item==Bracer		&&player0_inf.bag_info.bracer_num==0)	    ||
					(current_item==Water_stone  &&player0_inf.bag_info.stone!=W_stone)  ||
					(current_item==Fire_stone   &&player0_inf.bag_info.stone!=F_stone)   ||
					(current_item==Thunder_stone&&player0_inf.bag_info.stone!=T_stone)					
					)begin
						inf.complete<=0;
						inf.err_msg <=Not_Having_Item;
					end
					else begin
						inf.complete<=1;
						inf.err_msg <=No_Err;					
					end
				end
				Buy:begin
					if(buy_pkm)begin
						case(current_type)
							Grass:begin
								if(player0_inf.bag_info.money>=100)begin
									if(player0_inf.pkm_info!=No_type)begin
										inf.complete<=0;
										inf.err_msg <=Already_Have_PKM;									
									end
									else begin
										inf.complete<=1;
										inf.err_msg <=No_Err;
									end
								end
								else begin
									inf.complete<=0;
									inf.err_msg <=Out_of_money;									
								end
							end
							Fire:begin
								if(player0_inf.bag_info.money>=90)begin
									if(player0_inf.pkm_info!=No_type)begin
										inf.complete<=0;
										inf.err_msg <=Already_Have_PKM;									
									end
									else begin
										inf.complete<=1;
										inf.err_msg <=No_Err;
									end
								end
								else begin
									inf.complete<=0;
									inf.err_msg <=Out_of_money;									
								end						
							end
							Water:begin
								if(player0_inf.bag_info.money>=110)begin
									if(player0_inf.pkm_info!=No_type)begin
										inf.complete<=0;
										inf.err_msg <=Already_Have_PKM;									
									end
									else begin
										inf.complete<=1;
										inf.err_msg <=No_Err;
									end
								end
								else begin
									inf.complete<=0;
									inf.err_msg <=Out_of_money;									
								end							
							end
							Electric:begin
								if(player0_inf.bag_info.money>=120)begin
									if(player0_inf.pkm_info!=No_type)begin
										inf.complete<=0;
										inf.err_msg <=Already_Have_PKM;									
									end
									else begin
										inf.complete<=1;
										inf.err_msg <=No_Err;
									end
								end
								else begin
									inf.complete<=0;
									inf.err_msg <=Out_of_money;									
								end						
							end
							Normal:begin
								if(player0_inf.bag_info.money>=130)begin
									if(player0_inf.pkm_info!=No_type)begin
										inf.complete<=0;
										inf.err_msg <=Already_Have_PKM;									
									end
									else begin
										inf.complete<=1;
										inf.err_msg <=No_Err;
									end
								end
								else begin
									inf.complete<=0;
									inf.err_msg <=Out_of_money;									
								end							
							end
						endcase
						
					end
					else begin //buy item
						case(current_item)
							Berry	       :begin
								if(player0_inf.bag_info.money<16)begin
									inf.complete<=0;
									inf.err_msg <=Out_of_money;	
								end
								else if(player0_inf.bag_info.berry_num==15)begin
									inf.complete<=0;
									inf.err_msg <=Bag_is_full;	
								end
								else begin
									inf.complete<=1;
									inf.err_msg <=No_Err;								
								end	
							end
							Medicine       :begin
								if(player0_inf.bag_info.money<128)begin
									inf.complete<=0;
									inf.err_msg <=Out_of_money;
									end
								else if(player0_inf.bag_info.medicine_num==15)begin
									inf.complete<=0;
									inf.err_msg <=Bag_is_full;	
								end
								else begin
									inf.complete<=1;
									inf.err_msg <=No_Err;								
								end	
							end
							Candy		   :begin
								if(player0_inf.bag_info.money<300)begin
									inf.complete<=0;
									inf.err_msg <=Out_of_money;	
								end
								else if(player0_inf.bag_info.candy_num==15)begin
									inf.complete<=0;
									inf.err_msg <=Bag_is_full;	
								end
								else begin
									inf.complete<=1;
									inf.err_msg <=No_Err;								
								end	
							end
							Bracer	       :begin
								if(player0_inf.bag_info.money<64)begin
									inf.complete<=0;
									inf.err_msg <=Out_of_money;	
								end
								else if(player0_inf.bag_info.bracer_num==15)begin
									inf.complete<=0;
									inf.err_msg <=Bag_is_full;	
								end
								else begin
									inf.complete<=1;
									inf.err_msg <=No_Err;								
								end	
							end
							Water_stone,Fire_stone,Thunder_stone:begin
								if(player0_inf.bag_info.money<800)begin
									inf.complete<=0;
									inf.err_msg <=Out_of_money;	
								end
								else if(player0_inf.bag_info.stone!=No_stone)begin
									inf.complete<=0;
									inf.err_msg <=Bag_is_full;	
								end
								else begin
									inf.complete<=1;
									inf.err_msg <=No_Err;								
								end	
							end
						endcase					
					end
				end
				Sell:begin
					if(buy_pkm)begin //same as sell pkm 
						if(player0_inf.pkm_info.stage==No_stage/*||player0_inf.pkm_info.stage!=Lowest*/)begin
							inf.complete<=0;
							inf.err_msg <=Not_Having_PKM;							
						end
						else if(player0_inf.pkm_info.stage==Lowest)begin
							inf.complete<=0;
							inf.err_msg <=Has_Not_Grown;							
						end
						else begin
							inf.complete<=1;
							inf.err_msg <=No_Err;							
						end
					end
					else begin //sell item
						case(current_item)
							Berry	       :begin
								if(player0_inf.bag_info.berry_num==0)begin
									inf.complete<=0;
									inf.err_msg <=Not_Having_Item;									
								end
								else begin
									inf.complete<=1;
									inf.err_msg <=No_Err;								
								end
							end
							Medicine       :begin
								if(player0_inf.bag_info.medicine_num==0)begin
									inf.complete<=0;
									inf.err_msg <=Not_Having_Item;									
								end
								else begin
									inf.complete<=1;
									inf.err_msg <=No_Err;								
								end
							end
							Candy		   :begin
								if(player0_inf.bag_info.candy_num==0)begin
									inf.complete<=0;
									inf.err_msg <=Not_Having_Item;									
								end
								else begin
									inf.complete<=1;
									inf.err_msg <=No_Err;								
								end
							end
							Bracer	       :begin
								if(player0_inf.bag_info.bracer_num==0)begin
									inf.complete<=0;
									inf.err_msg <=Not_Having_Item;									
								end
								else begin
									inf.complete<=1;
									inf.err_msg <=No_Err;								
								end
							end
							Water_stone:begin
								if(player0_inf.bag_info.stone!=W_stone)begin
									inf.complete<=0;
									inf.err_msg <=Not_Having_Item;									
								end
								else begin
									inf.complete<=1;
									inf.err_msg <=No_Err;								
								end
							end
							Fire_stone:begin
								if(player0_inf.bag_info.stone!=F_stone)begin
									inf.complete<=0;
									inf.err_msg <=Not_Having_Item;									
								end
								else begin
									inf.complete<=1;
									inf.err_msg <=No_Err;								
								end
							end
							Thunder_stone:begin
								if(player0_inf.bag_info.stone!=T_stone)begin
									inf.complete<=0;
									inf.err_msg <=Not_Having_Item;									
								end
								else begin
									inf.complete<=1;
									inf.err_msg <=No_Err;								
								end
							end
						endcase	
					end
				end
			endcase
	end
end
always@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.out_info<=0;
	end
	else
	begin
		if(inf.complete==0)begin
			inf.out_info<=0;
		end
		else begin
			case(current_action)
				Attack:begin
						inf.out_info<={player0_inf.pkm_info,player1_inf.pkm_info};						
					end
				default:
					inf.out_info<={player0_inf.bag_info,player0_inf.pkm_info};	
			endcase
		end
	end
end

always@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		cnt<=0;
	end
	else
	begin
		if(current_state!=next_state)
			cnt<=0;
		else if(cnt<WAIT_LIMIT)
			cnt<=cnt+1;
	end
end

reg [7:0]save_id;

always@(*)begin
	inf.C_in_valid=0;
	inf.C_r_wb = 0;
	inf.C_addr=save_id;
	inf.C_data_w=0;
	if(cnt==0)begin
		case(current_state)		
			WAIT0:begin
				inf.C_in_valid=1;
				inf.C_r_wb=1;
				inf.C_addr=player0_ID;
			end
			WAIT1:begin
				inf.C_in_valid=1;
				inf.C_r_wb=1;
				inf.C_addr=player1_ID;
			end
			WAIT2:begin
				inf.C_in_valid=1;
				inf.C_r_wb=0;	
				inf.C_addr=save_id;
				inf.C_data_w={player1_pkm_info_dram_fmt,player1_bag_info_dram_fmt};				
			end
			WAIT3:begin
				inf.C_in_valid=1;
				inf.C_r_wb=0;	
				inf.C_addr=save_id;				
				inf.C_data_w={player0_pkm_info_dram_fmt,player0_bag_info_dram_fmt};	
			end
		endcase
	end
end

always@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		save_id<=0;
	end
	else
	begin
		case(current_state)
			CALCULATE:save_id<=player1_ID;
			WAIT_NEXT:save_id<=player0_ID;
			WAIT0:save_id<=player0_ID;
			WAIT1:save_id<=player1_ID;
			WAIT2:save_id<=player1_ID;
			WAIT3:save_id<=player0_ID;
		endcase
	end
end

always@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		wait_over<=0;
	end
	else
	begin
		if(current_state!=next_state)
			wait_over<=0;
		else if(inf.C_out_valid)
			wait_over<=1;
	end
end

always@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		current_amnt<=0;
	end
	else
	begin
		if(inf.amnt_valid)
			current_amnt<=inf.D.d_money;
	end
end

always@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		current_action<=No_action;
	end
	else
	begin
		if(inf.act_valid)
			current_action<=Action'(inf.D.d_act);
	end
end
always@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		current_type<=No_type;
	end
	else
	begin
		if(inf.type_valid)
			current_type<=PKM_Type'(inf.D.d_type);
	end
end
always@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		current_item<=No_item;
	end
	else
	begin
		if(inf.item_valid)
			current_item<=Item'(inf.D.d_item);
	end
end


always@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		buy_pkm<=0;
	end
	else
	begin
		if(inf.type_valid)
			buy_pkm<=1;
		else if(inf.item_valid)
			buy_pkm<=0;
	end
end
always@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.out_valid<=0;

	end
	else
	begin
		
		if(current_state==WAIT_NEXT&&cnt==0)
			inf.out_valid<=1;
		else
			inf.out_valid<=0;
			
		
	end
end


endmodule
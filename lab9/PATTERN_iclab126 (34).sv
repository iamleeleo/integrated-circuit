`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_PKG.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================
//      PARAMETERS FOR PATTERN CONTROL
//================================================================
parameter OUT_NUM   = 1;
parameter PATNUM    = 400;
integer   SEED      = 2206;

//================================================================
//      pseudo_DRAM 
//================================================================
parameter DRAM_OFFSET = 'h10000; 
parameter DRAM_p_r    = "../00_TESTBED/DRAM/dram.dat"; 
logic [7:0] golden_DRAM[ (DRAM_OFFSET+0) : ((65536+2048)-1) ];
initial $readmemh( DRAM_p_r, golden_DRAM );

//================================================================
//      PARAMETERS & VARIABLES
//================================================================
parameter DELAY     = 1200;

integer       i;
integer       j;
integer       m;
integer       n;

integer     pat;
integer    size;

integer total_lat;
integer   exe_lat;
integer   out_lat;

reg [5:0] die;
//================================================================
//      CACULATION REGISTER AND INTEGER
//================================================================
Player_Info player0_info;
Player_Info player1_info;

// Data input
Player_id   player0_id;
Player_id   player1_id;
Player_id   tmp;
Money add_money;
Action      current_action;
Item current_item;
PKM_Type current_type;
// Check Output
logic       gold_complete;
Error_Msg   gold_err_msg;
logic[63:0] gold_info;
logic choice;
integer equal;
reg brace_flag;
ATK atk_plus;
reg start;

//======================================
//              MAIN
//======================================
reg verify_flag;
initial begin
    reset_task;
	verify_flag=0;
	equal=0;
	brace_flag=0;
    for ( pat=0 ; pat<PATNUM ; pat=pat+1 ) begin
        input_task;
        calculate;
        wait_out_valid;
        check_task;
        //$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Cycles: %3d\033[m", pat ,exe_lat);
    end
    pass_task;
end

//======================================
//              TASKS
//======================================

task reset_task; begin
	start=0;
    inf.rst_n      = 1;
    inf.id_valid   = 0;
    inf.act_valid  = 0;
    inf.item_valid = 0;
    inf.type_valid = 0;
    inf.amnt_valid = 0;
    inf.D          = 0;
    total_lat      = 0;
    #(3) inf.rst_n = 0;
    #(3) inf.rst_n = 1;
end endtask

task input_id_0;
	input Player_id id_in;
begin
	inf.id_valid=1;
	player0_id=id_in;
	inf.D = {8'b0,player0_id};
	@(negedge clk);
	inf.id_valid=0;
	inf.D='dx;
	@(negedge clk);//1cycle
end
endtask

task input_id_1;
	input Player_id id_in;
begin
	inf.id_valid=1;
	player1_id=id_in;
	inf.D = {8'b0,player1_id};
	@(negedge clk);
	inf.id_valid=0;
	inf.D='dx;
end
endtask

task input_act;
	input Action act_in;
begin
	inf.act_valid=1;
	current_action=act_in;
	inf.D={12'b0,act_in};
	@(negedge clk);
	inf.act_valid=0;
	inf.D='dx;
	if(current_action!=Check)
		@(negedge clk);//1cycle
end
endtask

task input_item;
	input Item item_in;
begin
	choice=0;
	inf.item_valid=1;
	current_item=item_in;
	inf.D={12'b0,item_in};
	@(negedge clk);
	inf.item_valid=0;
	inf.D='dx;
end
endtask

task input_type;
	input PKM_Type type_in;
begin
	choice=1;
	inf.type_valid=1;
	current_type=type_in;
	inf.D={12'b0,type_in};
	@(negedge clk);
	inf.type_valid=0;
	inf.D='dx;
end
endtask

task input_amt;
	input Money amt_in;
begin
	inf.amnt_valid=1;
	add_money=amt_in;
	inf.D={2'b0,add_money};
	@(negedge clk);
	inf.amnt_valid=0;
	inf.D='dx;
end
endtask

task input_task; begin	

	if(start==1)begin
		@(negedge clk);//2cycle
		@(negedge clk);//2cycle
	end
	start=1;
	
	//id 

	if(pat<256)begin
		brace_flag=0;
		input_id_0(pat);
	end
	
	//action
	
	case(pat)
		0 :input_act(Buy);
		1 :input_act(Buy);
		2 :input_act(Buy);
		3 :input_act(Buy);
		4 :input_act(Buy);
		5 :input_act(Buy);
		6 :input_act(Buy);
		7 :input_act(Buy);
		8 :input_act(Buy);
		9 :input_act(Buy);
		10:input_act(Buy);
		11:input_act(Sell);
		12:input_act(Buy);
		13:input_act(Deposit);
		14:input_act(Buy);
		15:input_act(Check);
		16:input_act(Buy);
		17:input_act(Use_item);
		18:input_act(Buy);
		19:input_act(Attack);
		20:input_act(Buy);
		21:input_act(Sell);
		22:input_act(Buy);
		23:input_act(Deposit);
		24:input_act(Buy);
		25:input_act(Check);
		26:input_act(Buy);
		27:input_act(Use_item);
		28:input_act(Buy);
		29:input_act(Attack);
		30:input_act(Buy);
		31:input_act(Sell);
		32:input_act(Buy);
		33:input_act(Deposit);
		34:input_act(Buy);
		35:input_act(Check);
		36:input_act(Buy);
		37:input_act(Use_item);
		38:input_act(Buy);
		39:input_act(Attack);
		40:input_act(Buy);
		41:input_act(Sell);
		42:input_act(Buy);
		43:input_act(Deposit);
		44:input_act(Buy);
		45:input_act(Check);
		46:input_act(Buy);
		47:input_act(Use_item);
		48:input_act(Buy);
		49:input_act(Attack);
		50:input_act(Buy);
		51:input_act(Sell);
		52:input_act(Buy);
		53:input_act(Deposit);
		54:input_act(Buy);
		55:input_act(Check);
		56:input_act(Buy);
		57:input_act(Use_item);
		58:input_act(Buy);
		59:input_act(Attack);
		60:input_act(Buy);
		61:input_act(Sell);
		62:input_act(Buy);
		63:input_act(Deposit);
		64:input_act(Buy);
		65:input_act(Check);
		66:input_act(Buy);
		67:input_act(Use_item);
		68:input_act(Buy);
		69:input_act(Attack);
		70:input_act(Buy);
		71:input_act(Sell);
		72:input_act(Buy);
		73:input_act(Deposit);
		74:input_act(Buy);
		75:input_act(Check);
		76:input_act(Buy);
		77:input_act(Use_item);
		78:input_act(Buy);
		79:input_act(Attack);
		80:input_act(Buy);
		81:input_act(Sell);
		82:input_act(Buy);
		83:input_act(Deposit);
		84:input_act(Buy);
		85:input_act(Check);
		86:input_act(Buy);
		87:input_act(Use_item);
		88:input_act(Buy);
		89:input_act(Attack);
		90:input_act(Buy);
		91:input_act(Sell);
		92:input_act(Buy);
		93:input_act(Deposit);
		94:input_act(Buy);
		95:input_act(Check);
		96:input_act(Buy);
		97:input_act(Use_item);
		98:input_act(Buy);
		99:input_act(Attack);
		100:input_act(Buy);
		101:input_act(Sell);
		102:input_act(Buy);
		103:input_act(Deposit);
		104:input_act(Buy);
		105:input_act(Check);
		106:input_act(Buy);
		107:input_act(Use_item);
		108:input_act(Buy);
		109:input_act(Attack);
		110:input_act(Buy);
		111:input_act(Sell);
		112:input_act(Sell);
		113:input_act(Sell);
		114:input_act(Sell);
		115:input_act(Sell);
		116:input_act(Sell);
		117:input_act(Sell);
		118:input_act(Sell);
		119:input_act(Sell);
		120:input_act(Sell);
		121:input_act(Sell);
		122:input_act(Deposit);
		123:input_act(Sell);
		124:input_act(Check);
		125:input_act(Sell);
		126:input_act(Use_item);
		127:input_act(Sell);
		128:input_act(Attack);
		129:input_act(Sell);
		130:input_act(Deposit);
		131:input_act(Sell);
		132:input_act(Check);
		133:input_act(Sell);
		134:input_act(Use_item);
		135:input_act(Sell);
		136:input_act(Attack);
		137:input_act(Sell);
		138:input_act(Deposit);
		139:input_act(Sell);
		140:input_act(Check);
		141:input_act(Sell);
		142:input_act(Use_item);
		143:input_act(Sell);
		144:input_act(Attack);
		145:input_act(Sell);
		146:input_act(Deposit);
		147:input_act(Sell);
		148:input_act(Check);
		149:input_act(Sell);
		150:input_act(Use_item);
		151:input_act(Sell);
		152:input_act(Attack);
		153:input_act(Sell);
		154:input_act(Deposit);
		155:input_act(Sell);
		156:input_act(Check);
		157:input_act(Sell);
		158:input_act(Use_item);
		159:input_act(Sell);
		160:input_act(Attack);
		161:input_act(Sell);
		162:input_act(Deposit);
		163:input_act(Sell);
		164:input_act(Check);
		165:input_act(Sell);
		166:input_act(Use_item);
		167:input_act(Sell);
		168:input_act(Attack);
		169:input_act(Sell);
		170:input_act(Deposit);
		171:input_act(Sell);
		172:input_act(Check);
		173:input_act(Sell);
		174:input_act(Use_item);
		175:input_act(Sell);
		176:input_act(Attack);
		177:input_act(Sell);
		178:input_act(Deposit);
		179:input_act(Sell);
		180:input_act(Check);
		181:input_act(Sell);
		182:input_act(Use_item);
		183:input_act(Sell);
		184:input_act(Attack);
		185:input_act(Sell);
		186:input_act(Deposit);
		187:input_act(Sell);
		188:input_act(Check);
		189:input_act(Sell);
		190:input_act(Use_item);
		191:input_act(Sell);
		192:input_act(Attack);
		193:input_act(Sell);
		194:input_act(Deposit);
		195:input_act(Sell);
		196:input_act(Check);
		197:input_act(Sell);
		198:input_act(Use_item);
		199:input_act(Sell);
		200:input_act(Attack);
		201:input_act(Sell);
		202:input_act(Deposit);
		203:input_act(Deposit);
		204:input_act(Deposit);
		205:input_act(Deposit);
		206:input_act(Deposit);
		207:input_act(Deposit);
		208:input_act(Deposit);
		209:input_act(Deposit);
		210:input_act(Deposit);
		211:input_act(Deposit);
		212:input_act(Deposit);
		213:input_act(Check);
		214:input_act(Deposit);
		215:input_act(Use_item);
		216:input_act(Deposit);
		217:input_act(Attack);
		218:input_act(Deposit);
		219:input_act(Check);
		220:input_act(Deposit);
		221:input_act(Use_item);
		222:input_act(Deposit);
		223:input_act(Attack);
		224:input_act(Deposit);
		225:input_act(Check);
		226:input_act(Deposit);
		227:input_act(Use_item);
		228:input_act(Deposit);
		229:input_act(Attack);
		230:input_act(Deposit);
		231:input_act(Check);
		232:input_act(Deposit);
		233:input_act(Use_item);
		234:input_act(Deposit);
		235:input_act(Attack);
		236:input_act(Deposit);
		237:input_act(Check);
		238:input_act(Deposit);
		239:input_act(Use_item);
		240:input_act(Deposit);
		241:input_act(Attack);
		242:input_act(Deposit);
		243:input_act(Check);
		244:input_act(Deposit);
		245:input_act(Use_item);
		246:input_act(Deposit);
		247:input_act(Attack);
		248:input_act(Deposit);
		249:input_act(Check);
		250:input_act(Deposit);
		251:input_act(Use_item);
		252:input_act(Deposit);
		253:input_act(Attack);
		254:input_act(Deposit);
		255:input_act(Check);
		256:input_act(Deposit);
		257:input_act(Use_item);
		258:input_act(Deposit);
		259:input_act(Attack);
		260:input_act(Deposit);
		261:input_act(Check);
		262:input_act(Deposit);
		263:input_act(Use_item);
		264:input_act(Deposit);
		265:input_act(Attack);
		266:input_act(Deposit);
		267:input_act(Check);
		268:input_act(Deposit);
		269:input_act(Use_item);
		270:input_act(Deposit);
		271:input_act(Attack);
		272:input_act(Deposit);
		273:input_act(Check);
		274:input_act(Check);
		275:input_act(Check);
		276:input_act(Check);
		277:input_act(Check);
		278:input_act(Check);
		279:input_act(Check);
		280:input_act(Check);
		281:input_act(Check);
		282:input_act(Check);
		283:input_act(Check);
		284:input_act(Use_item);
		285:input_act(Check);
		286:input_act(Attack);
		287:input_act(Check);
		288:input_act(Use_item);
		289:input_act(Check);
		290:input_act(Attack);
		291:input_act(Check);
		292:input_act(Use_item);
		293:input_act(Check);
		294:input_act(Attack);
		295:input_act(Check);
		296:input_act(Use_item);
		297:input_act(Check);
		298:input_act(Attack);
		299:input_act(Check);
		300:input_act(Use_item);
		301:input_act(Check);
		302:input_act(Attack);
		303:input_act(Check);
		304:input_act(Use_item);
		305:input_act(Check);
		306:input_act(Attack);
		307:input_act(Check);
		308:input_act(Use_item);
		309:input_act(Check);
		310:input_act(Attack);
		311:input_act(Check);
		312:input_act(Use_item);
		313:input_act(Check);
		314:input_act(Attack);
		315:input_act(Check);
		316:input_act(Use_item);
		317:input_act(Check);
		318:input_act(Attack);
		319:input_act(Check);
		320:input_act(Use_item);
		321:input_act(Check);
		322:input_act(Attack);
		323:input_act(Check);
		324:input_act(Use_item);
		325:input_act(Use_item);
		326:input_act(Use_item);
		327:input_act(Use_item);
		328:input_act(Use_item);
		329:input_act(Use_item);
		330:input_act(Use_item);
		331:input_act(Use_item);
		332:input_act(Use_item);
		333:input_act(Use_item);
		334:input_act(Use_item);
		335:input_act(Attack);
		336:input_act(Use_item);
		337:input_act(Attack);
		338:input_act(Use_item);
		339:input_act(Attack);
		340:input_act(Use_item);
		341:input_act(Attack);
		342:input_act(Use_item);
		343:input_act(Attack);
		344:input_act(Use_item);
		345:input_act(Attack);
		346:input_act(Use_item);
		347:input_act(Attack);
		348:input_act(Use_item);
		349:input_act(Attack);
		350:input_act(Use_item);
		351:input_act(Attack);
		352:input_act(Use_item);
		353:input_act(Attack);
		354:input_act(Use_item);
		355:input_act(Attack);
		356:input_act(Attack);
		357:input_act(Attack);
		358:input_act(Attack);
		359:input_act(Attack);
		360:input_act(Attack);
		361:input_act(Attack);
		362:input_act(Attack);
		363:input_act(Attack);
		364:input_act(Attack);
		365:input_act(Attack);
		366:input_act(Check);
		367:input_act(Check);
		368:input_act(Check);
		369:input_act(Check);
		370:input_act(Check);
		371:input_act(Check);
		372:input_act(Check);
		373:input_act(Check);
		374:input_act(Check);
		375:input_act(Check);
		376:input_act(Check);
		377:input_act(Check);
		378:input_act(Check);
		379:input_act(Check);
		380:input_act(Check);
		381:input_act(Check);
		382:input_act(Check);
		383:input_act(Check);
		384:input_act(Check);
		385:input_act(Check);
		386:input_act(Check);
		387:input_act(Check);
		388:input_act(Check);
		389:input_act(Check);
		390:input_act(Check);
		391:input_act(Check);
		392:input_act(Check);
		393:input_act(Check);
		394:input_act(Check);
		395:input_act(Check);
		396:input_act(Check);
		397:input_act(Check);
		398:input_act(Check);
		399:input_act(Check);
	endcase
		
	


	//input_data
	case(pat)
		0 :input_type(Grass);
		1 :input_type(Grass);
		2 :input_type(Grass);
		3 :input_type(Grass);
		4 :input_type(Grass);
		5 :input_type(Grass);
		6 :input_type(Grass);
		7 :input_type(Grass);
		8 :input_type(Grass);
		9 :input_type(Grass);
		10:input_type(Grass);
		11:input_type(No_type);
		12:input_type(Grass);
		14:input_type(Grass);
		16:input_type(Grass);
		18:input_type(Grass);
		19:input_id_1(255);
		20:input_type(Grass);
		21:input_type(No_type);
		22:input_type(Grass);
		24:input_type(Grass);
		26:input_type(Grass);
		28:input_type(Grass);
		29:input_id_1(255);
		30:input_type(Grass);
		31:input_type(No_type);
		32:input_type(Grass);
		34:input_type(Grass);
		36:input_type(Grass);
		38:input_type(Grass);
		39:input_id_1(255);
		40:input_type(Grass);
		41:input_type(No_type);
		42:input_type(Grass);
		44:input_type(Grass);
		46:input_type(Grass);
		48:input_type(Grass);
		49:input_id_1(255);
		50:input_type(Grass);
		51:input_type(No_type);
		52:input_type(Grass);
		54:input_type(Grass);
		56:input_type(Grass);
		58:input_type(Grass);
		59:input_id_1(255);
		60:input_type(Grass);
		61:input_type(No_type);
		62:input_type(Grass);
		64:input_type(Grass);
		66:input_type(Grass);
		68:input_type(Grass);
		69:input_id_1(255);
		70:input_item(Berry);
		71:input_type(No_type);
		72:input_item(Berry);
		74:input_item(Berry);
		76:input_item(Berry);
		78:input_item(Berry);
		79:input_id_1(255);
		80:input_item(Berry);
		81:input_type(No_type);
		82:input_item(Berry);
		84:input_item(Berry);
		86:input_item(Berry);
		88:input_item(Berry);
		89:input_id_1(255);
		90:input_item(Berry);
		91:input_type(No_type);
		92:input_item(Berry);
		94:input_item(Berry);
		96:input_item(Berry);
		98:input_item(Berry);
		99:input_id_1(255);
		100:input_item(Berry);
		101:input_type(No_type);
		102:input_item(Berry);
		104:input_item(Berry);
		106:input_item(Berry);
		108:input_item(Berry);
		109:input_id_1(255);
		111:input_type(No_type);
		112:input_type(No_type);
		113:input_type(No_type);
		114:input_type(No_type);
		115:input_type(No_type);
		116:input_type(No_type);
		117:input_type(No_type);
		118:input_type(No_type);
		119:input_type(No_type);
		120:input_type(No_type);
		121:input_item(Water_stone);
		123:input_item(Water_stone);
		125:input_item(Water_stone);
		127:input_item(Water_stone);
		128:input_id_1(255);
		129:input_item(Water_stone);
		131:input_item(Water_stone);
		133:input_item(Water_stone);
		135:input_item(Water_stone);
		136:input_id_1(255);
		137:input_item(Water_stone);
		139:input_item(Water_stone);
		141:input_item(Water_stone);
		143:input_item(Water_stone);
		144:input_id_1(255);
		145:input_item(Water_stone);
		147:input_item(Water_stone);
		149:input_item(Water_stone);
		151:input_item(Water_stone);
		152:input_id_1(255);
		153:input_item(Water_stone);
		155:input_item(Water_stone);
		157:input_item(Water_stone);
		159:input_item(Water_stone);
		160:input_id_1(255);
		168:input_id_1(255);
		176:input_id_1(255);
		184:input_id_1(255);
		192:input_id_1(255);
		200:input_id_1(255);	
		324:input_item(Bracer);
		325:input_item(Bracer);
		326:input_item(Bracer);
		327:input_item(Bracer);
		328:input_item(Bracer);
		329:input_item(Bracer);
		330:input_item(Bracer);
		331:input_item(Bracer);
		332:input_item(Bracer);
		333:input_item(Bracer);
		354:input_item(Bracer);
		default:begin
			case(current_action)
				Buy  : begin
					die = {$random(SEED)}%2;
					choice = die;
					if(die==0)begin  //buy item
						die = {$random(SEED)}%7;
						case(die)
							0:begin  //berry
								input_item(Berry);
							end
							1:begin  //Medicine
								input_item(Medicine);
							end
							2:begin  //Candy
								input_item(Candy);
							end
							3:begin //Bracer
								input_item(Bracer);
							end
							4:begin  //Water_stone
								input_item(Water_stone);
							end
							5:begin  //Fire_stone
								input_item(Fire_stone);
							end
							6:begin  //Thunder_stone
								input_item(Thunder_stone);
							end
						endcase
					end
					else begin  //buy pokemon
						die = {$random(SEED)}%5;		
						case(die)
							0:begin  //grass
								input_type(Grass);
							end
							1:begin //fire
								input_type(Fire);
							end
							2:begin //water
								input_type(Water);
							end
							3:begin  //Electric
								input_type(Electric);
							end
							4:begin //normal
								input_type(Normal);
							end
						endcase
					end
				end
				Sell : begin
					die = {$random(SEED)}%2;
					choice = die;
					if(die==0)begin  //buy item
						die = {$random(SEED)}%7;
						case(die)
							0:begin  //berry
								input_item(Berry);
							end
							1:begin  //Medicine
								input_item(Medicine);
							end
							2:begin  //Candy
								input_item(Candy);
							end
							3:begin //Bracer
								input_item(Bracer);
							end
							4:begin  //Water_stone
								input_item(Water_stone);
							end
							5:begin  //Fire_stone
								input_item(Fire_stone);
							end
							6:begin  //Thunder_stone
								input_item(Thunder_stone);
							end
						endcase
					end
					else begin  //buy pokemon
						input_type(No_type);
					end
				end
				Use_item  : begin
					die = {$random(SEED)}%7;
					case(die)
						0:begin  //berry
							input_item(Berry);
						end
						1:begin  //Medicine
							input_item(Medicine);
						end
						2:begin  //Candy
							input_item(Candy);
						end
						3:begin //Bracer
							input_item(Bracer);
						end
						4:begin  //Water_stone
							input_item(Water_stone);
						end
						5:begin  //Fire_stone
							input_item(Fire_stone);
						end
						6:begin  //Thunder_stone
							input_item(Thunder_stone);
						end
					endcase
				end
				Attack  : begin
					player1_id = {$random(SEED)}%256;
					while(player1_id==player0_id)begin
						player1_id = {$random(SEED)}%256;
					end
					input_id_1(player1_id);
				end
				Deposit  : begin
					add_money={$random(SEED)}%1024;
					input_amt(add_money);	
				end
			endcase		
		end
	endcase

end endtask

task fetch_data_task;
    input Player_id    in;
    output Player_Info out;
begin
    out.bag_info.bracer_num   = Item_num'( golden_DRAM[ (DRAM_OFFSET+in*8+1) ][3:0]);
    out.bag_info.money        =    Money'({golden_DRAM[ (DRAM_OFFSET+in*8+2) ][5:0], golden_DRAM[ (DRAM_OFFSET+in*8+3) ]});
    out.bag_info.berry_num    = Item_num'( golden_DRAM[ (DRAM_OFFSET+in*8)   ][7:4]);
    out.bag_info.medicine_num = Item_num'( golden_DRAM[ (DRAM_OFFSET+in*8)   ][3:0]);
    out.bag_info.stone        =    Stone'( golden_DRAM[ (DRAM_OFFSET+in*8+2) ][7:6]);
    out.bag_info.candy_num    = Item_num'( golden_DRAM[ (DRAM_OFFSET+in*8+1) ][7:4]);

    out.pkm_info.pkm_type     = PKM_Type'( golden_DRAM[ (DRAM_OFFSET+in*8+4) ][3:0]);
    out.pkm_info.exp          =      EXP'( golden_DRAM[ (DRAM_OFFSET+in*8+7) ]);
    out.pkm_info.hp           =       HP'( golden_DRAM[ (DRAM_OFFSET+in*8+5) ]);
    out.pkm_info.atk          =      ATK'( golden_DRAM[ (DRAM_OFFSET+in*8+6) ]);
    out.pkm_info.stage        =    Stage'( golden_DRAM[ (DRAM_OFFSET+in*8+4) ][7:4]);
end endtask

task write_back_task;
    input Player_id   in;
    input Player_Info info;
begin
    golden_DRAM[ (DRAM_OFFSET+in*8+1) ][3:0] = info.bag_info.bracer_num;
    golden_DRAM[ (DRAM_OFFSET+in*8+3) ]      = info.bag_info.money[7:0];
    golden_DRAM[ (DRAM_OFFSET+in*8)   ][7:4] = info.bag_info.berry_num;
    golden_DRAM[ (DRAM_OFFSET+in*8)   ][3:0] = info.bag_info.medicine_num;
    golden_DRAM[ (DRAM_OFFSET+in*8+2) ]      = {info.bag_info.stone, info.bag_info.money[13:8]};
    golden_DRAM[ (DRAM_OFFSET+in*8+1) ][7:4] = info.bag_info.candy_num;

    golden_DRAM[ (DRAM_OFFSET+in*8+4) ][3:0] = info.pkm_info.pkm_type;
    golden_DRAM[ (DRAM_OFFSET+in*8+5) ]      = info.pkm_info.hp;
    golden_DRAM[ (DRAM_OFFSET+in*8+7) ]      = info.pkm_info.exp;
    golden_DRAM[ (DRAM_OFFSET+in*8+6) ]      = info.pkm_info.atk;
    golden_DRAM[ (DRAM_OFFSET+in*8+4) ][7:4] = info.pkm_info.stage;
end endtask




reg [8:0]price,num;
reg [5:0]p0_exp_add,p1_exp_add;
reg [8:0]p0_eva_require,p1_eva_require;
task calculate; begin
	atk_plus = player0_info[15:8]+32;
	fetch_data_task(player0_id,player0_info);
	fetch_data_task(player1_id,player1_info);
	case(current_action)
	//current_action
        Buy:begin
			if(choice==0)begin //buy item
				case(current_item)
					Berry:        begin   
						if(player0_info.bag_info.money<16)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Out_of_money;				
						end
						else if(player0_info.bag_info.berry_num==15)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Bag_is_full;							
						end
						else begin
							player0_info.bag_info.berry_num=player0_info.bag_info.berry_num+1;
							player0_info.bag_info.money    =player0_info.bag_info.money-16;
							gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
							gold_complete=1;
							gold_err_msg=No_Err;						
						end
					end
					Medicine:     begin   
						if(player0_info.bag_info.money<128)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Out_of_money;				
						end
						else if(player0_info.bag_info.medicine_num==15)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Bag_is_full;							
						end
						else begin
							player0_info.bag_info.medicine_num=player0_info.bag_info.medicine_num+1;
							player0_info.bag_info.money    =player0_info.bag_info.money-128;
							gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
							gold_complete=1;
							gold_err_msg=No_Err;						
						end
					end
					Candy:        begin 
						if(player0_info.bag_info.money<300)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Out_of_money;				
						end
						else if(player0_info.bag_info.candy_num==15)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Bag_is_full;							
						end
						else begin
							player0_info.bag_info.candy_num=player0_info.bag_info.candy_num+1;
							player0_info.bag_info.money    =player0_info.bag_info.money-300;
							gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
							gold_complete=1;
							gold_err_msg=No_Err;						
						end
					end
					Bracer:       begin 
						if(player0_info.bag_info.money<64)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Out_of_money;				
						end
						else if(player0_info.bag_info.bracer_num==15)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Bag_is_full;							
						end
						else begin
							player0_info.bag_info.bracer_num=player0_info.bag_info.bracer_num+1;
							player0_info.bag_info.money    =player0_info.bag_info.money-64;
							gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
							gold_complete=1;
							gold_err_msg=No_Err;						
						end
					end
					Water_stone:  begin 
						if(player0_info.bag_info.money<800)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Out_of_money;				
						end
						else if(player0_info.bag_info.stone!=No_stone)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Bag_is_full;							
						end
						else begin
							player0_info.bag_info.stone=W_stone;
							player0_info.bag_info.money    =player0_info.bag_info.money-800;
							gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
							gold_complete=1;
							gold_err_msg=No_Err;						
						end
					end
					Fire_stone:  begin 
						if(player0_info.bag_info.money<800)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Out_of_money;				
						end
						else if(player0_info.bag_info.stone!=No_stone)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Bag_is_full;							
						end
						else begin
							player0_info.bag_info.stone=F_stone;
							player0_info.bag_info.money    =player0_info.bag_info.money-800;
							gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
							gold_complete=1;
							gold_err_msg=No_Err;						
						end
					end
					Thunder_stone:  begin 
						if(player0_info.bag_info.money<800)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Out_of_money;				
						end
						else if(player0_info.bag_info.stone!=No_stone)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Bag_is_full;							
						end
						else begin
							player0_info.bag_info.stone=T_stone;
							player0_info.bag_info.money    =player0_info.bag_info.money-800;
							gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
							gold_complete=1;
							gold_err_msg=No_Err;						
						end
					end
				endcase
			end
			else begin //buy pokemon
				case(current_type)
					Grass:        begin   
						if(player0_info.bag_info.money<100)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Out_of_money;				
						end
						else if(player0_info.pkm_info.pkm_type!=No_type)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Already_Have_PKM;							
						end
						else begin
							player0_info.bag_info.money=player0_info.bag_info.money-100;
							player0_info.pkm_info.pkm_type=Grass;
							player0_info.pkm_info.hp=128;
							player0_info.pkm_info.atk=63;
							player0_info.pkm_info.stage=Lowest;
							gold_info=player0_info;
							gold_complete=1;
							gold_err_msg=No_Err;
						end					
					end
					Fire:     begin   
						if(player0_info.bag_info.money<90)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Out_of_money;				
						end
						else if(player0_info.pkm_info.pkm_type!=No_type)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Already_Have_PKM;							
						end
						else begin
							player0_info.bag_info.money=player0_info.bag_info.money-90;
							player0_info.pkm_info.pkm_type=Fire;
							player0_info.pkm_info.hp=119;
							player0_info.pkm_info.atk=64;
							player0_info.pkm_info.stage=Lowest;
							gold_info=player0_info;
							gold_complete=1;
							gold_err_msg=No_Err;
						end						
					end
					Water:        begin 
						if(player0_info.bag_info.money<110)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Out_of_money;				
						end
						else if(player0_info.pkm_info.pkm_type!=No_type)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Already_Have_PKM;							
						end
						else begin
							player0_info.bag_info.money=player0_info.bag_info.money-110;
							player0_info.pkm_info.pkm_type=Water;
							player0_info.pkm_info.hp=125;
							player0_info.pkm_info.atk=60;
							player0_info.pkm_info.stage=Lowest;
							gold_info=player0_info;
							gold_complete=1;
							gold_err_msg=No_Err;
						end						
					end
					Electric:       begin 
						if(player0_info.bag_info.money<120)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Out_of_money;				
						end
						else if(player0_info.pkm_info.pkm_type!=No_type)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Already_Have_PKM;							
						end
						else begin
							player0_info.bag_info.money=player0_info.bag_info.money-120;
							player0_info.pkm_info.pkm_type=Electric;
							player0_info.pkm_info.hp=122;
							player0_info.pkm_info.atk=65;
							player0_info.pkm_info.stage=Lowest;
							gold_info=player0_info;
							gold_complete=1;
							gold_err_msg=No_Err;
						end
					end
					Normal:  begin 
						if(player0_info.bag_info.money<130)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Out_of_money;				
						end
						else if(player0_info.pkm_info.pkm_type!=No_type)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Already_Have_PKM;							
						end
						else begin
							player0_info.bag_info.money=player0_info.bag_info.money-130;
							player0_info.pkm_info.pkm_type=Normal;
							player0_info.pkm_info.hp=124;
							player0_info.pkm_info.atk=62;
							player0_info.pkm_info.stage=Lowest;
							gold_info=player0_info;
							gold_complete=1;
							gold_err_msg=No_Err;
						end
					end
				endcase				
			end
        end
        Sell: begin

			if(choice==0)begin //sell item
				case(current_item)
					Berry:        begin   
						if(player0_info.bag_info.berry_num==0)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Not_Having_Item;				
						end
						else begin
							player0_info.bag_info.berry_num=player0_info.bag_info.berry_num-1;
							player0_info.bag_info.money    =player0_info.bag_info.money+12;
							gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
							gold_complete=1;
							gold_err_msg=No_Err;						
						end
					end
					Medicine:     begin   
						if(player0_info.bag_info.medicine_num==0)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Not_Having_Item;				
						end
						else begin
							player0_info.bag_info.medicine_num=player0_info.bag_info.medicine_num-1;
							player0_info.bag_info.money    =player0_info.bag_info.money+96;
							gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
							gold_complete=1;
							gold_err_msg=No_Err;						
						end
					end
					Candy:        begin 
						if(player0_info.bag_info.candy_num==0)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Not_Having_Item;				
						end
						else begin
							player0_info.bag_info.candy_num=player0_info.bag_info.candy_num-1;
							player0_info.bag_info.money    =player0_info.bag_info.money+225;
							gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
							gold_complete=1;
							gold_err_msg=No_Err;						
						end
					end
					Bracer:       begin 
						if(player0_info.bag_info.bracer_num==0)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Not_Having_Item;				
						end
						else begin
							player0_info.bag_info.bracer_num=player0_info.bag_info.bracer_num-1;
							player0_info.bag_info.money    =player0_info.bag_info.money+48;
							gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
							gold_complete=1;
							gold_err_msg=No_Err;						
						end
					end
					Water_stone:  begin 
						if(player0_info.bag_info.stone!=W_stone)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Not_Having_Item;							
						end
						else begin
							player0_info.bag_info.stone=No_stone;
							player0_info.bag_info.money    =player0_info.bag_info.money+600;
							gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
							gold_complete=1;
							gold_err_msg=No_Err;						
						end
					end
					Fire_stone:  begin 
						if(player0_info.bag_info.stone!=F_stone)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Not_Having_Item;							
						end
						else begin
							player0_info.bag_info.stone=No_stone;
							player0_info.bag_info.money    =player0_info.bag_info.money+600;
							gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
							gold_complete=1;
							gold_err_msg=No_Err;						
						end
					end
					Thunder_stone:  begin 
						if(player0_info.bag_info.stone!=T_stone)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Not_Having_Item;							
						end
						else begin
							player0_info.bag_info.stone=No_stone;
							player0_info.bag_info.money    =player0_info.bag_info.money+600;
							gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
							gold_complete=1;
							gold_err_msg=No_Err;						
						end
					end
				endcase
			end
			else begin //sell pokemon
				
				if(player0_info.pkm_info.pkm_type==No_type)begin
					gold_info=0;
					gold_complete=0;
					gold_err_msg=Not_Having_PKM;							
				end
				else if(player0_info.pkm_info.stage==Lowest)begin
					gold_info=0;
					gold_complete=0;
					gold_err_msg=Has_Not_Grown;					
				end
				else begin
					brace_flag=0;
					case({player0_info.pkm_info.pkm_type,player0_info.pkm_info.stage})
						{Grass,Middle}:        begin   
							player0_info.bag_info.money=player0_info.bag_info.money+510;
						end
						{Fire,Middle}:     begin   
							player0_info.bag_info.money=player0_info.bag_info.money+450;
						end
						{Water,Middle}:        begin 
							player0_info.bag_info.money=player0_info.bag_info.money+500;
						end
						{Electric,Middle}:       begin 
							player0_info.bag_info.money=player0_info.bag_info.money+550;
						end
						{Grass,Highest}:        begin   
							player0_info.bag_info.money=player0_info.bag_info.money+1100;
						end
						{Fire,Highest}:     begin   
							player0_info.bag_info.money=player0_info.bag_info.money+1000;
						end
						{Water,Highest}:        begin 
							player0_info.bag_info.money=player0_info.bag_info.money+1200;
						end
						{Electric,Highest}:       begin 
							player0_info.bag_info.money=player0_info.bag_info.money+1300;
						end
					endcase
					player0_info.pkm_info.pkm_type=No_type;
					player0_info.pkm_info.hp=0;
					player0_info.pkm_info.atk=0;
					player0_info.pkm_info.stage=No_stage;
					player0_info.pkm_info.exp=0;
					gold_info=player0_info;
					gold_complete=1;
					gold_err_msg=No_Err;	
				end
			end
        end
        Use_item: begin
			if(player0_info.pkm_info.pkm_type==No_type)begin
				gold_info=0;
				gold_complete=0;
				gold_err_msg=Not_Having_PKM;							
			end
			else begin
				case(current_item)
					Berry:        begin   
						if(player0_info.bag_info.berry_num==0)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Not_Having_Item;				
						end
						else begin
							player0_info.bag_info.berry_num=player0_info.bag_info.berry_num-1;
							case({player0_info.pkm_info.pkm_type,player0_info.pkm_info.stage})
								{Grass,Lowest} :begin 
									if(player0_info.pkm_info.hp+32<=128)player0_info.pkm_info.hp=player0_info.pkm_info.hp+32;
									else player0_info.pkm_info.hp=128;
								end
								{Grass,Middle} :begin
									if(player0_info.pkm_info.hp+32<=192)player0_info.pkm_info.hp=player0_info.pkm_info.hp+32;
									else player0_info.pkm_info.hp=192;
								end
								{Grass,Highest}:begin 
									if(player0_info.pkm_info.hp+32<=254)player0_info.pkm_info.hp=player0_info.pkm_info.hp+32;
									else player0_info.pkm_info.hp=254;							
								end
								{Fire,Lowest} :begin 
									if(player0_info.pkm_info.hp+32<=119)player0_info.pkm_info.hp=player0_info.pkm_info.hp+32;
									else player0_info.pkm_info.hp=119;							
								end
								{Fire,Middle} :begin
									if(player0_info.pkm_info.hp+32<=177)player0_info.pkm_info.hp=player0_info.pkm_info.hp+32;
									else player0_info.pkm_info.hp=177;
								end
								{Fire,Highest}:begin 
									if(player0_info.pkm_info.hp+32<=225)player0_info.pkm_info.hp=player0_info.pkm_info.hp+32;
									else player0_info.pkm_info.hp=225;							
								end
								{Water,Lowest} :begin 
									if(player0_info.pkm_info.hp+32<=125)player0_info.pkm_info.hp=player0_info.pkm_info.hp+32;
									else player0_info.pkm_info.hp=125;							
								end
								{Water,Middle} :begin
									if(player0_info.pkm_info.hp+32<=187)player0_info.pkm_info.hp=player0_info.pkm_info.hp+32;
									else player0_info.pkm_info.hp=187;
								end
								{Water,Highest}:begin 
									if(player0_info.pkm_info.hp+32<=245)player0_info.pkm_info.hp=player0_info.pkm_info.hp+32;
									else player0_info.pkm_info.hp=245;							
								end	
								{Electric,Lowest} :begin 
									if(player0_info.pkm_info.hp+32<=122)player0_info.pkm_info.hp=player0_info.pkm_info.hp+32;
									else player0_info.pkm_info.hp=122;								
								end
								{Electric,Middle} :begin
									if(player0_info.pkm_info.hp+32<=182)player0_info.pkm_info.hp=player0_info.pkm_info.hp+32;
									else player0_info.pkm_info.hp=182;	
								end
								{Electric,Highest}:begin 
									if(player0_info.pkm_info.hp+32<=235)player0_info.pkm_info.hp=player0_info.pkm_info.hp+32;
									else player0_info.pkm_info.hp=235;								
								end	
								{Normal,Lowest} :begin 
									if(player0_info.pkm_info.hp+32<=124)player0_info.pkm_info.hp=player0_info.pkm_info.hp+32;
									else player0_info.pkm_info.hp=124;								
								end
							endcase
							gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
							gold_complete=1;
							gold_err_msg=No_Err;						
						end
					end
					Medicine:     begin   
						if(player0_info.bag_info.medicine_num==0)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Not_Having_Item;				
						end
						else begin
							player0_info.bag_info.medicine_num=player0_info.bag_info.medicine_num-1;
							case({player0_info.pkm_info.pkm_type,player0_info.pkm_info.stage})
								{Grass,Lowest} :begin 
									player0_info.pkm_info.hp=128;
								end
								{Grass,Middle} :begin
									player0_info.pkm_info.hp=192;
								end
								{Grass,Highest}:begin 
									player0_info.pkm_info.hp=254;						
								end
								{Fire,Lowest} :begin 
									player0_info.pkm_info.hp=119;							
								end
								{Fire,Middle} :begin
									player0_info.pkm_info.hp=177;	
								end
								{Fire,Highest}:begin 
									player0_info.pkm_info.hp=225;								
								end
								{Water,Lowest} :begin 
									player0_info.pkm_info.hp=125;								
								end
								{Water,Middle} :begin
									player0_info.pkm_info.hp=187;	
								end
								{Water,Highest}:begin 
									player0_info.pkm_info.hp=245;								
								end	
								{Electric,Lowest} :begin 
									player0_info.pkm_info.hp=122;									
								end
								{Electric,Middle} :begin
									player0_info.pkm_info.hp=182;		
								end
								{Electric,Highest}:begin 
									player0_info.pkm_info.hp=235;									
								end	
								{Normal,Lowest} :begin 
									player0_info.pkm_info.hp=124;									
								end
							endcase
							gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
							gold_complete=1;
							gold_err_msg=No_Err;						
						end
					end
					Candy:        begin 
						if(player0_info.bag_info.candy_num==0)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Not_Having_Item;				
						end
						else begin
							player0_info.bag_info.candy_num=player0_info.bag_info.candy_num-1;
							case({player0_info.pkm_info.pkm_type,player0_info.pkm_info.stage})
								{Grass,Lowest} :begin 
									if(player0_info.pkm_info.exp+15>=32)begin
										player0_info.pkm_info.hp=192;
										player0_info.pkm_info.atk=94;
										player0_info.pkm_info.stage=Middle;
										player0_info.pkm_info.exp=0;
										brace_flag=0;
									end
									else
									begin
										player0_info.pkm_info.exp=player0_info.pkm_info.exp+15;
									end
								end
								{Grass,Middle} :begin
									if(player0_info.pkm_info.exp+15>=63)begin
										player0_info.pkm_info.hp=254;
										player0_info.pkm_info.atk=123;
										player0_info.pkm_info.stage=Highest;
										player0_info.pkm_info.exp=0;
										brace_flag=0;
									end
									else
									begin
										player0_info.pkm_info.exp=player0_info.pkm_info.exp+15;
									end
								end
								{Fire,Lowest} :begin 
									if(player0_info.pkm_info.exp+15>=30)begin
										player0_info.pkm_info.hp=177;
										player0_info.pkm_info.atk=96;
										player0_info.pkm_info.stage=Middle;
										player0_info.pkm_info.exp=0;
										brace_flag=0;
									end
									else
									begin
										player0_info.pkm_info.exp=player0_info.pkm_info.exp+15;
									end						
								end
								{Fire,Middle} :begin
									if(player0_info.pkm_info.exp+15>=59)begin
										player0_info.pkm_info.hp=225;
										player0_info.pkm_info.atk=127;
										player0_info.pkm_info.stage=Highest;
										player0_info.pkm_info.exp=0;
										brace_flag=0;
									end
									else
									begin
										player0_info.pkm_info.exp=player0_info.pkm_info.exp+15;
									end
								end
								{Water,Lowest} :begin 
									if(player0_info.pkm_info.exp+15>=28)begin
										player0_info.pkm_info.hp=187;
										player0_info.pkm_info.atk=89;
										player0_info.pkm_info.stage=Middle;
										player0_info.pkm_info.exp=0;
										brace_flag=0;
									end
									else
									begin
										player0_info.pkm_info.exp=player0_info.pkm_info.exp+15;
									end								
								end
								{Water,Middle} :begin
									if(player0_info.pkm_info.exp+15>=55)begin
										player0_info.pkm_info.hp=245;
										player0_info.pkm_info.atk=113;
										player0_info.pkm_info.stage=Highest;
										player0_info.pkm_info.exp=0;
										brace_flag=0;
									end
									else
									begin
										player0_info.pkm_info.exp=player0_info.pkm_info.exp+15;
									end	
								end
								{Electric,Lowest} :begin 
									if(player0_info.pkm_info.exp+15>=26)begin
										player0_info.pkm_info.hp=182;
										player0_info.pkm_info.atk=97;
										player0_info.pkm_info.stage=Middle;
										player0_info.pkm_info.exp=0;
										brace_flag=0;
									end
									else
									begin
										player0_info.pkm_info.exp=player0_info.pkm_info.exp+15;
									end									
								end
								{Electric,Middle} :begin
									if(player0_info.pkm_info.exp+15>=51)begin
										player0_info.pkm_info.hp=235;
										player0_info.pkm_info.atk=124;
										player0_info.pkm_info.stage=Highest;
										player0_info.pkm_info.exp=0;
										brace_flag=0;
									end
									else
									begin
										player0_info.pkm_info.exp=player0_info.pkm_info.exp+15;
									end			
								end
								{Normal,Lowest} :begin 
									if(player0_info.pkm_info.exp+15>=29)begin
										player0_info.pkm_info.exp=29;
									end
									else begin
										player0_info.pkm_info.exp=player0_info.pkm_info.exp+15;
									end
								end
							endcase
							gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
							gold_complete=1;
							gold_err_msg=No_Err;						
						end
					end
					Bracer:       begin 
						if(player0_info.bag_info.bracer_num==0)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Not_Having_Item;				
						end
						else begin
							player0_info.bag_info.bracer_num=player0_info.bag_info.bracer_num-1;
							brace_flag=1;
							
							atk_plus = player0_info[15:8] + 32;
							gold_info={player0_info[63:16],atk_plus,player0_info[7:0]};
							gold_complete=1;
							gold_err_msg=No_Err;		
						end
					end
					Water_stone:  begin 
						if(player0_info.bag_info.stone!=W_stone)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Not_Having_Item;							
						end
						else begin
							player0_info.bag_info.stone=No_stone;
							if(player0_info.pkm_info.pkm_type==Normal&&player0_info.pkm_info.stage==Lowest&&player0_info.pkm_info.exp==29)begin
								player0_info.pkm_info.hp=245;
								player0_info.pkm_info.atk=113;
								player0_info.pkm_info.stage=Highest;
								player0_info.pkm_info.exp=0;
								player0_info.pkm_info.pkm_type=Water;
								brace_flag=0;							
							end
							gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
							gold_complete=1;
							gold_err_msg=No_Err;						
						end
					end
					Fire_stone:  begin 
						if(player0_info.bag_info.stone!=F_stone)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Not_Having_Item;							
						end
						else begin
							player0_info.bag_info.stone=No_stone;
							if(player0_info.pkm_info.pkm_type==Normal&&player0_info.pkm_info.stage==Lowest&&player0_info.pkm_info.exp==29)begin
								player0_info.pkm_info.hp=225;
								player0_info.pkm_info.atk=127;
								player0_info.pkm_info.stage=Highest;
								player0_info.pkm_info.exp=0;
								player0_info.pkm_info.pkm_type=Fire;
								brace_flag=0;							
							end
							gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
							gold_complete=1;
							gold_err_msg=No_Err;						
						end
					end
					Thunder_stone:  begin 
						if(player0_info.bag_info.stone!=T_stone)begin
							gold_info=0;
							gold_complete=0;
							gold_err_msg=Not_Having_Item;							
						end
						else begin
							player0_info.bag_info.stone=No_stone;
							if(player0_info.pkm_info.pkm_type==Normal&&player0_info.pkm_info.stage==Lowest&&player0_info.pkm_info.exp==29)begin
								player0_info.pkm_info.hp=235;
								player0_info.pkm_info.atk=124;
								player0_info.pkm_info.stage=Highest;
								player0_info.pkm_info.pkm_type=Electric;
								player0_info.pkm_info.exp=0;
								brace_flag=0;						
							end
							gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
							gold_complete=1;
							gold_err_msg=No_Err;						
						end
					end
				endcase
			end
        end
        Attack: begin
			if(player0_info.pkm_info.pkm_type==No_type||player1_info.pkm_info.pkm_type==No_type)begin
				gold_info=0;
				gold_complete=0;
				gold_err_msg=Not_Having_PKM;			
			end
			else if(player0_info.pkm_info.hp==0||player1_info.pkm_info.hp==0)begin
				gold_info=0;
				gold_complete=0;
				gold_err_msg=HP_is_Zero;				
			end
			else begin
				case(player1_info.pkm_info.stage)
					Lowest: p0_exp_add = 16;
					Middle: p0_exp_add = 24;
					Highest:p0_exp_add = 32;
				endcase
				case(player0_info.pkm_info.stage)
					Lowest: p1_exp_add = 8;
					Middle: p1_exp_add = 12;
					Highest:p1_exp_add = 16;
				endcase
				
				case({player0_info.pkm_info.pkm_type,player0_info.pkm_info.stage})
					{Grass,Lowest} :p0_eva_require=32;
					{Grass,Middle} :p0_eva_require=63;
					{Fire,Lowest} :p0_eva_require=30;
					{Fire,Middle} :p0_eva_require=59;
					{Water,Lowest} :p0_eva_require=28;
					{Water,Middle} :p0_eva_require=55;
					{Electric,Lowest} :p0_eva_require=26;
					{Electric,Middle} :p0_eva_require=51;
					default:p0_eva_require=200;
				endcase	
				case({player1_info.pkm_info.pkm_type,player1_info.pkm_info.stage})
					{Grass,Lowest} :p1_eva_require=32;
					{Grass,Middle} :p1_eva_require=63;
					{Fire,Lowest}  :p1_eva_require=30;
					{Fire,Middle}  :p1_eva_require=59;
					{Water,Lowest} :p1_eva_require=28;
					{Water,Middle} :p1_eva_require=55;
					{Electric,Lowest} :p1_eva_require=26;
					{Electric,Middle} :p1_eva_require=51;
					default:p1_eva_require=200;
				endcase		
				
				if(player1_info.pkm_info.exp+p1_exp_add>=p1_eva_require && player1_info.pkm_info.pkm_type!=Normal)begin
					case({player1_info.pkm_info.pkm_type,player1_info.pkm_info.stage})
						{Grass,Lowest} :begin 
							player1_info.pkm_info.hp=192;
							player1_info.pkm_info.atk=94;
							player1_info.pkm_info.stage=Middle;
							player1_info.pkm_info.exp=0;
							brace_flag=0;
						end
						{Grass,Middle} :begin
							player1_info.pkm_info.hp=254;
							player1_info.pkm_info.atk=123;
							player1_info.pkm_info.stage=Highest;
							player1_info.pkm_info.exp=0;
							brace_flag=0;
						end
						{Fire,Lowest} :begin 
							player1_info.pkm_info.hp=177;
							player1_info.pkm_info.atk=96;
							player1_info.pkm_info.stage=Middle;
							player1_info.pkm_info.exp=0;
							brace_flag=0;
						end
						{Fire,Middle} :begin
							player1_info.pkm_info.hp=225;
							player1_info.pkm_info.atk=127;
							player1_info.pkm_info.stage=Highest;
							player1_info.pkm_info.exp=0;
							brace_flag=0;
						end
						{Water,Lowest} :begin 
							player1_info.pkm_info.hp=187;
							player1_info.pkm_info.atk=89;
							player1_info.pkm_info.stage=Middle;
							player1_info.pkm_info.exp=0;
							brace_flag=0;
						end
						{Water,Middle} :begin
							player1_info.pkm_info.hp=245;
							player1_info.pkm_info.atk=113;
							player1_info.pkm_info.stage=Highest;
							player1_info.pkm_info.exp=0;
							brace_flag=0;
						end
						{Electric,Lowest} :begin 
							player1_info.pkm_info.hp=182;
							player1_info.pkm_info.atk=97;
							player1_info.pkm_info.stage=Middle;
							player1_info.pkm_info.exp=0;
							brace_flag=0;
						end
						{Electric,Middle} :begin
							player1_info.pkm_info.hp=235;
							player1_info.pkm_info.atk=124;
							player1_info.pkm_info.stage=Highest;
							player1_info.pkm_info.exp=0;
							brace_flag=0;
						end
						{Normal,Lowest} :begin 
							player1_info.pkm_info.exp=29;
						end
					endcase				
				end
				else begin
					if(player1_info.pkm_info.pkm_type!=Normal)begin
						if(player1_info.pkm_info.stage!=Highest)player1_info.pkm_info.exp=player1_info.pkm_info.exp+p1_exp_add;
					end
					else begin
						if(player1_info.pkm_info.exp+p1_exp_add<=29)player1_info.pkm_info.exp=player1_info.pkm_info.exp+p1_exp_add;
						else player1_info.pkm_info.exp=29;
					end
					case({player0_info.pkm_info.pkm_type,player1_info.pkm_info.pkm_type})
						{Grass,Grass}:
							if(brace_flag==1)begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk + 32)/2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk + 32)/2));
								end
							end
							else
							begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk)/2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk)/2));
								end							
							end
						{Grass,Fire}:
							if(brace_flag==1)begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk + 32)/2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk + 32)/2));
								end
							end
							else
							begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk)/2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk)/2));
								end							
							end
						{Grass,Water}:
							if(brace_flag==1)begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk + 32)*2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk + 32)*2));
								end
							end
							else
							begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk)*2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk)*2));
								end							
							end
						{Fire,Grass}:
							if(brace_flag==1)begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk + 32)*2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk + 32)*2));
								end
							end
							else
							begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk)*2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk)*2));
								end							
							end
						{Fire,Fire}:
							if(brace_flag==1)begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk + 32)/2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk + 32)/2));
								end
							end
							else
							begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk)/2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk)/2));
								end							
							end
						{Fire,Water}:
							if(brace_flag==1)begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk + 32)/2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk + 32)/2));
								end
							end
							else
							begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk)/2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk)/2));
								end							
							end
						{Water,Grass}:
							if(brace_flag==1)begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk + 32)/2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk + 32)/2));
								end
							end
							else
							begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk)/2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk)/2));
								end							
							end
						{Water,Fire}:
							if(brace_flag==1)begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk + 32)*2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk + 32)*2));
								end
							end
							else
							begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk)*2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk)*2));
								end							
							end
						{Water,Water}:
							if(brace_flag==1)begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk + 32)/2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk + 32)/2));
								end
							end
							else
							begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk)/2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk)/2));
								end							
							end
						{Electric,Grass}:
							if(brace_flag==1)begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk + 32)/2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk + 32)/2));
								end
							end
							else
							begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk)/2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk)/2));
								end							
							end
						{Electric,Water}:
							if(brace_flag==1)begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk + 32)*2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk + 32)*2));
								end
							end
							else
							begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk)*2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk)*2));
								end							
							end
						{Electric,Electric}:
							if(brace_flag==1)begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk + 32)/2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk + 32)/2));
								end
							end
							else
							begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk)/2))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk)/2));
								end							
							end
						default:begin
							if(brace_flag==1)begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk + 32)))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk + 32)));
								end
							end
							else
							begin
								if(player1_info.pkm_info.hp < ((player0_info.pkm_info.atk)))begin
									player1_info.pkm_info.hp=0;
								end
								else
								begin
									player1_info.pkm_info.hp = (player1_info.pkm_info.hp - ((player0_info.pkm_info.atk)));
								end							
							end
						end
					endcase
				end
			
				
				
				if(player0_info.pkm_info.exp+p0_exp_add>=p0_eva_require && player0_info.pkm_info.stage!=Normal)begin
					case({player0_info.pkm_info.pkm_type,player0_info.pkm_info.stage})
						{Grass,Lowest} :begin 
							player0_info.pkm_info.hp=192;
							player0_info.pkm_info.atk=94;
							player0_info.pkm_info.stage=Middle;
							player0_info.pkm_info.exp=0;
							brace_flag=0;
						end
						{Grass,Middle} :begin
							player0_info.pkm_info.hp=254;
							player0_info.pkm_info.atk=123;
							player0_info.pkm_info.stage=Highest;
							player0_info.pkm_info.exp=0;
							brace_flag=0;
						end
						{Fire,Lowest} :begin 
							player0_info.pkm_info.hp=177;
							player0_info.pkm_info.atk=96;
							player0_info.pkm_info.stage=Middle;
							player0_info.pkm_info.exp=0;
							brace_flag=0;
						end
						{Fire,Middle} :begin
							player0_info.pkm_info.hp=225;
							player0_info.pkm_info.atk=127;
							player0_info.pkm_info.stage=Highest;
							player0_info.pkm_info.exp=0;
							brace_flag=0;
						end
						{Water,Lowest} :begin 
							player0_info.pkm_info.hp=187;
							player0_info.pkm_info.atk=89;
							player0_info.pkm_info.stage=Middle;
							player0_info.pkm_info.exp=0;
							brace_flag=0;
						end
						{Water,Middle} :begin
							player0_info.pkm_info.hp=245;
							player0_info.pkm_info.atk=113;
							player0_info.pkm_info.stage=Highest;
							player0_info.pkm_info.exp=0;
							brace_flag=0;
						end
						{Electric,Lowest} :begin 
							player0_info.pkm_info.hp=182;
							player0_info.pkm_info.atk=97;
							player0_info.pkm_info.stage=Middle;
							player0_info.pkm_info.exp=0;
							brace_flag=0;
						end
						{Electric,Middle} :begin
							player0_info.pkm_info.hp=235;
							player0_info.pkm_info.atk=124;
							player0_info.pkm_info.stage=Highest;
							player0_info.pkm_info.exp=0;
							brace_flag=0;
						end
						{Normal,Lowest} :begin 
							player0_info.pkm_info.exp=29;
						end
					endcase				
				end
				else begin
					if(player0_info.pkm_info.pkm_type!=Normal)begin
						if(player0_info.pkm_info.stage!=Highest)player0_info.pkm_info.exp=player0_info.pkm_info.exp+p0_exp_add;
					end
					else begin
						if(player0_info.pkm_info.exp+p0_exp_add<=29)player0_info.pkm_info.exp=player0_info.pkm_info.exp+p0_exp_add;
						else player0_info.pkm_info.exp=29;
					end
				end
				
				gold_info={player0_info.pkm_info,player1_info.pkm_info};
				gold_err_msg=No_Err;
				gold_complete=1;
				brace_flag=0;
			end

			
        end
        Deposit: begin
			player0_info.bag_info.money=player0_info.bag_info.money + add_money;
			gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
			gold_err_msg=No_Err;
			gold_complete=1;
        end
        Check: begin
			gold_info=(brace_flag?{player0_info[63:16],atk_plus,player0_info[7:0]}:player0_info);
			gold_err_msg=No_Err;
			gold_complete=1;			
        end
	//case currenttion
    endcase
	write_back_task(player0_id,player0_info);
	if(current_action==Attack)
		write_back_task(player1_id,player1_info);
end endtask

task wait_out_valid; begin
    exe_lat = -1;
    while ( inf.out_valid === 0 ) begin
        exe_lat = exe_lat + 1;
        @(negedge clk);
    end
end endtask

task check_task; begin
	if ( inf.complete !== gold_complete || inf.out_info !== gold_info || inf.err_msg !== gold_err_msg ) begin
		$display("    Wrong Answer															      ",$time*1000);
		repeat(5) @(negedge clk);
		$finish;			
	end
	//@(negedge clk);
    total_lat = total_lat + exe_lat;
end endtask


task pass_task; begin
	//$display ("----------------------------------------------------------------------------------------------------------------------");
	//$display ("                                                  Congratulations!                						             ");
	//$display ("                                           You have passed all patterns!          						             ");
	//$display ("                                           Your execution cycles = %5d cycles   						                 ", total_lat);
	//$display ("----------------------------------------------------------------------------------------------------------------------");
    @(negedge clk);
    $finish;
end endtask

endprogram


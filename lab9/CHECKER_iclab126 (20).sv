//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//
//   File Name   : CHECKER.sv
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module Checker(input clk, INF.CHECKER inf);
import usertype::*;

covergroup spec1 @(negedge clk iff inf.out_valid);
    option.per_instance = 1;
	coverpoint inf.out_info[31:28] {
		option.at_least = 20;
		bins b1 = {No_stage};
		bins b2 = {Lowest};
		bins b3 = {Middle};
		bins b4 = {Highest};
	}

	coverpoint inf.out_info[27:24] {
		option.at_least = 20;
		bins b1 = {No_type};
		bins b2 = {Grass};
		bins b3 = {Fire};
		bins b4 = {Water};
        bins b5 = {Electric};
        bins b6 = {Normal};
	}
endgroup : spec1

covergroup spec2 @(posedge clk iff inf.id_valid);
    option.per_instance = 1;
	coverpoint inf.D.d_id[0] {
		option.at_least = 1;
        option.auto_bin_max = 256;
	}
endgroup : spec2

covergroup spec3 @(posedge clk iff inf.act_valid);
    option.per_instance = 1;
   	coverpoint inf.D.d_act[0] {
   		option.at_least = 10;
   		bins action[] = (Buy, Sell, Deposit, Check, Use_item, Attack => Buy, Sell, Deposit, Check, Use_item, Attack);
   	}
endgroup : spec3

covergroup spec4 @(negedge clk iff inf.out_valid);
    option.per_instance = 1;
   	coverpoint inf.complete {
   		option.at_least = 200;
		bins b1 = {0} ;
		bins b2 = {1} ;   
   	}
endgroup : spec4

covergroup spec5 @(negedge clk iff inf.out_valid);
    option.per_instance = 1;
   	coverpoint inf.err_msg {
   		option.at_least = 20;
		bins b1 = {Out_of_money};
        bins b2 = {Bag_is_full};
        bins b3 = {Already_Have_PKM};
        bins b4 = {Not_Having_PKM};
        bins b5 = {Has_Not_Grown};
        bins b6 = {Not_Having_Item};
        bins b7 = {HP_is_Zero};
   	}
endgroup : spec5

spec1 spec1_inst = new();
spec2 spec2_inst = new();
spec3 spec3_inst = new();
spec4 spec4_inst = new();
spec5 spec5_inst = new();
//************************************ below assertion is to check your pattern ***************************************** 

Action action;
always @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)action <= No_action;    
	else if(inf.act_valid)action <= inf.D.d_act[0];
	else if(inf.out_valid)action <= No_action;
end

assert1 : assert property (@(posedge inf.rst_n) inf.rst_n === 0 |-> (inf.out_valid === 0 && inf.out_info === 0 && inf.complete === 0 && inf.err_msg === 0 && inf.C_out_valid === 0 && inf.C_data_r === 0 && inf.AR_VALID === 0 && inf.AR_ADDR === 0 && inf.R_READY === 0 && inf.AW_VALID === 0 && inf.AW_ADDR === 0 && inf.W_VALID === 0 && inf.W_DATA === 0 && inf.B_READY === 0 &&inf.C_addr === 0 &&inf.C_data_w === 0 &&inf.C_in_valid === 0  &&inf.C_r_wb === 0))
else
begin
	$display("Assertion 1 is violated");
	$fatal;
end

assert2 : assert property (@(posedge clk) (inf.out_valid === 1 && inf.complete === 1)  |-> (inf.err_msg === No_Err))
else begin
	$display("Assertion 2 is violated");  
	$fatal;
end

assert3 : assert property (@(posedge clk) (inf.out_valid === 1 && inf.complete === 0)  |-> (inf.out_info === 0))
else begin
	$display("Assertion 3 is violated");  
	$fatal;
end

assert4_1 : assert property (@(posedge clk) (inf.id_valid === 1 && action == No_action)  |=> ( ##[1:5] (inf.act_valid === 1)))
else begin
	$display("Assertion 4 is violated");  
	$fatal;
end

assert4_2 : assert property (@(posedge clk) (inf.id_valid === 1 && action == No_action)  |=> ( inf.act_valid === 0))
else begin
	$display("Assertion 4 is violated");  
	$fatal;
end

assert4_3 : assert property (@(negedge clk) (inf.act_valid === 1 && action == Attack)  |=> ( ##[1:5] (inf.id_valid === 1)))
else begin
	$display("Assertion 4 is violated");  
	$fatal;
end

assert4_4 : assert property (@(negedge clk) (inf.act_valid === 1 && action == Attack)  |=> (inf.id_valid === 0))
else begin
	$display("Assertion 4 is violated");  
	$fatal;
end
	 
//buy sell deposit use_item
assert4_5 : assert property (@(negedge clk) (inf.act_valid === 1 && (action == Buy||action == Sell||action == Deposit||action == Use_item))  |=> ( ##[1:5] (inf.type_valid === 1 || inf.item_valid === 1||inf.amnt_valid === 1)))
else begin
	$display("Assertion 4 is violated");  
	$fatal;
end

assert4_6 : assert property (@(negedge clk) (inf.act_valid === 1 && (action == Buy||action == Sell||action == Deposit||action == Use_item))  |=> (inf.type_valid === 0 && inf.item_valid === 0 && inf.amnt_valid === 0))
else begin
	$display("Assertion 4 is violated");  
	$fatal;
end

assert5_1 : assert property (@(posedge clk) (inf.id_valid === 1)  |-> (inf.act_valid === 0 && inf.type_valid === 0 && inf.item_valid === 0 && inf.amnt_valid === 0))
else begin
	$display("Assertion 5 is violated");  
	$fatal;
end

assert5_2 : assert property (@(posedge clk) (inf.act_valid === 1)  |-> (inf.id_valid === 0 && inf.type_valid === 0 && inf.item_valid === 0 && inf.amnt_valid === 0))
else begin
	$display("Assertion 5 is violated");  
	$fatal;
end

assert5_3 : assert property (@(posedge clk) (inf.type_valid === 1)  |-> (inf.id_valid === 0 && inf.act_valid === 0 && inf.item_valid === 0 && inf.amnt_valid === 0))
else begin
	$display("Assertion 5 is violated");  
	$fatal;
end

assert5_4 : assert property (@(posedge clk) (inf.item_valid === 1)  |-> (inf.id_valid === 0 && inf.act_valid === 0 && inf.type_valid === 0 && inf.amnt_valid === 0))
else begin
	$display("Assertion 5 is violated");  
	$fatal;
end

assert5_5 : assert property (@(posedge clk) (inf.amnt_valid === 1)  |-> (inf.id_valid === 0 && inf.act_valid === 0 && inf.item_valid === 0 && inf.type_valid === 0))
else begin
	$display("Assertion 5 is violated");  
	$fatal;
end

assert6_1 : assert property (@(posedge clk) (inf.out_valid === 1)  |=> (inf.out_valid === 0))
else begin
	$display("Assertion 6 is violated");  
	$fatal;
end

assert7_1 : assert property (@(posedge clk)  (inf.out_valid===1) |-> ( ##[2:10] (inf.id_valid === 1 || inf.act_valid === 1)))
else begin
	$display("Assertion 7 is violated");  
	$fatal;
end

assert7_2 : assert property (@(posedge clk)  (inf.out_valid===1) |-> ( ##1 (inf.id_valid === 0 && inf.act_valid === 0)))
else begin
	$display("Assertion 7 is violated");  
	$fatal;
end

assert7_3 : assert property (@(posedge clk)  (inf.out_valid===1) |-> ( ##0 (inf.id_valid === 0 && inf.act_valid === 0)))
else begin
	$display("Assertion 7 is violated");  
	$fatal;
end

assert8_1 : assert property (@(posedge clk)  ((action == Buy) && (inf.type_valid === 1 || inf.item_valid === 1)) |-> ( ##[0:1200] (inf.out_valid === 1)))
else begin
	$display("Assertion 8 is violated");  
	$fatal;
end

assert8_2 : assert property (@(posedge clk)  (action == Sell&& (inf.type_valid === 1 || inf.item_valid === 1)) |-> ( ##[0:1200] (inf.out_valid === 1)))
else begin
	$display("Assertion 8 is violated");  
	$fatal;
end

assert8_3 : assert property (@(posedge clk)  (action == Deposit && inf.amnt_valid === 1) |-> ( ##[0:1200] (inf.out_valid === 1)))
else begin
	$display("Assertion 8 is violated");  
	$fatal;
end

assert8_4 : assert property (@(posedge clk)  (action == Check) |-> ( ##[0:1200] (inf.out_valid === 1)))
else begin
	$display("Assertion 8 is violated");  
	$fatal;
end

assert8_5 : assert property (@(posedge clk)  (action == Use_item && inf.item_valid === 1) |-> ( ##[0:1200] (inf.out_valid === 1)))
else begin
	$display("Assertion 8 is violated");  
	$fatal;
end

assert8_6 : assert property (@(posedge clk)  (action == Attack  && inf.id_valid === 1) |-> ( ##[0:1200] (inf.out_valid === 1)))
else begin
	$display("Assertion 8 is violated");  
	$fatal;
end

endmodule

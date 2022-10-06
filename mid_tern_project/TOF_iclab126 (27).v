//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NYCU ED430
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2022 SPRING
//   Midterm Proejct            : TOF  
//   Author                     : Wen-Yue, Lin
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TOF.v
//   Module Name : TOF
//   Release version : V1.0 (Release Date: 2022-3)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module TOF(
    // CHIP IO
    clk,
    rst_n,
    in_valid,
    start,
    stop,
    window,
    mode,
    frame_id,
    busy,

    // AXI4 IO
    arid_m_inf,
    araddr_m_inf,
    arlen_m_inf,
    arsize_m_inf,
    arburst_m_inf,
    arvalid_m_inf,
    arready_m_inf,
    
    rid_m_inf,
    rdata_m_inf,
    rresp_m_inf,
    rlast_m_inf,
    rvalid_m_inf,
    rready_m_inf,

    awid_m_inf,
    awaddr_m_inf,
    awsize_m_inf,
    awburst_m_inf,
    awlen_m_inf,
    awvalid_m_inf,
    awready_m_inf,

    wdata_m_inf,
    wlast_m_inf,
    wvalid_m_inf,
    wready_m_inf,
    
    bid_m_inf,
    bresp_m_inf,
    bvalid_m_inf,
    bready_m_inf 
);
// ===============================================================
//                      Parameter Declaration 
// ===============================================================
parameter ID_WIDTH=4, DATA_WIDTH=128, ADDR_WIDTH=32;    // DO NOT modify AXI4 Parameter


// ===============================================================
//                      Input / Output 
// ===============================================================

// << CHIP io port with system >>
input           clk, rst_n;
input           in_valid;
input           start;
input [15:0]    stop;     
input [1:0]     window; 
input           mode;
input [4:0]     frame_id;
output reg      busy;       

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
    Your AXI-4 interface could be designed as a bridge in submodule,
    therefore I declared output of AXI as wire.  
    Ex: AXI4_interface AXI4_INF(...);
*/

// ------------------------
// <<<<< AXI READ >>>>>
// ------------------------
// (1)    axi read address channel 
output wire [ID_WIDTH-1:0]      arid_m_inf;
output wire [1:0]            arburst_m_inf;
output wire [2:0]             arsize_m_inf;
output wire [7:0]              arlen_m_inf;
output wire                  arvalid_m_inf;
input  wire                  arready_m_inf;
output wire [ADDR_WIDTH-1:0]  araddr_m_inf;
// ------------------------
// (2)    axi read data channel 
input  wire [ID_WIDTH-1:0]       rid_m_inf;
input  wire                   rvalid_m_inf;
output wire                   rready_m_inf;
input  wire [DATA_WIDTH-1:0]   rdata_m_inf;
input  wire                    rlast_m_inf;
input  wire [1:0]              rresp_m_inf;
// ------------------------
// <<<<< AXI WRITE >>>>>
// ------------------------
// (1)     axi write address channel 
output wire [ID_WIDTH-1:0]      awid_m_inf;
output wire [1:0]            awburst_m_inf;
output wire [2:0]             awsize_m_inf;
output wire [7:0]              awlen_m_inf;
output wire                  awvalid_m_inf;
input  wire                  awready_m_inf;
output wire [ADDR_WIDTH-1:0]  awaddr_m_inf;
// -------------------------
// (2)    axi write data channel 
output wire                   wvalid_m_inf;
input  wire                   wready_m_inf;
output wire [DATA_WIDTH-1:0]   wdata_m_inf;
output wire                    wlast_m_inf;
// -------------------------
// (3)    axi write response channel 
input  wire  [ID_WIDTH-1:0]      bid_m_inf;
input  wire                   bvalid_m_inf;
output wire                   bready_m_inf;
input  wire  [1:0]             bresp_m_inf;
// -----------------------------

///////////////////////////////////////////////////////////
//********************reg/wire declare********************/
///////////////////////////////////////////////////////////
genvar g;
integer i;

//**********FSM**********//
reg [4:0]current_state,next_state;
//mode0
parameter IDLE = 0;
parameter wait_start = 1;
parameter phase_A = 2;
parameter phase_B = 3;
parameter wait_awready_0 = 4;
parameter wait_wready_0 = 7;
parameter write_dram_0 = 8;
parameter wait_bvalid = 9;
parameter wait_pipeline = 16;
parameter wait_pipeline2 = 17;
parameter wait_pipeline3 = 18;

//mode1
parameter wait_arready_1 = 10;
parameter wait_rvalid_1 = 11;
parameter calculate = 12;
parameter wait_awready_1 = 13;
parameter wait_wready_1 = 14;
parameter write_dram_1 = 15;
parameter BUSY = 19;


//**********input data************/
reg current_mode;
reg [1:0]current_windows;
reg [4:0]current_frame;


//mode0
//**********dram control************/
reg [127:0]dram_write_buf;
wire [127:0]dram_write_buf2;
reg [7:0]output_cnt;


//mode1
//**********dram control************/
wire hist_done,all_done;
reg [4:0]write_cnt2;
reg [8:0]read_cnt;
wire [8:0]tmp ;
reg [127:0]write_back[0:15];
reg [3:0]write_back_idx;
wire content_valid;
wire distance_valid;
wire [8:0]tmp2;
reg [3:0]out_write_back_idx;

//********store input bin***********//
reg [6:0]base;
reg f;
reg [3:0]starting_point;
reg [3:0]addrs[15:0];
reg [127:0]dram_data;
reg [55:0]pre_dram_data;


//********calculate max***********//
reg [10:0]current_max;
reg [7:0]current_max_idx;
wire [10:0]next_max;
wire [7:0]next_idx;
reg [7:0]idx_base;
reg [119:0]save_dram_data;
reg [119:0]save_dram_data2;

reg [2:0]dirty_bits[0:32];
/*************************************************************/
//********************reg/wire declare end********************/
/*************************************************************/



/*************************************************************/
//*************************FSM********************************/
/*************************************************************/

always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) current_state <= IDLE;
    else        current_state <= next_state;
end

always @(*) 
begin
	next_state=current_state;
	case (current_state)
		IDLE:	
			if(in_valid)
				if(mode)
					if(dirty_bits[frame_id]==window) next_state=BUSY;
					else next_state=wait_arready_1;
				else next_state=wait_start;
		//mode0 
		wait_start:
			if(start)next_state = phase_A;
		phase_A:
			if(!in_valid)next_state = wait_awready_0;
			else if(start)next_state = phase_B;
			else next_state = wait_start;
		phase_B:
			if(!in_valid)next_state = wait_awready_0;
			else if(start)next_state = phase_A;
			else next_state = wait_start;
		wait_awready_0:
			if(awready_m_inf)next_state = wait_wready_0;
		wait_wready_0 : 
			if(wready_m_inf)next_state =write_dram_0;
		wait_pipeline:
			next_state =wait_pipeline2;
		wait_pipeline2:
			next_state =wait_pipeline3;
		wait_pipeline3:
			next_state =write_dram_0;
		write_dram_0:
			if(wlast_m_inf)next_state =IDLE;
			else if(!wready_m_inf)next_state =wait_wready_0;
			else if(output_cnt[3:0]==14)next_state =wait_pipeline;
		
		//mode1
		wait_arready_1:
			if(arready_m_inf)next_state = wait_rvalid_1;
		wait_rvalid_1:
			if(rvalid_m_inf)next_state = calculate;
		calculate:
			if(rlast_m_inf)next_state = wait_awready_1;
		wait_awready_1:
			if(awready_m_inf)next_state = wait_wready_1;
		wait_wready_1:
			if(wready_m_inf)next_state = write_dram_1;
		write_dram_1:
			next_state = wait_bvalid;
		wait_bvalid:
			if(all_done)next_state = IDLE;
			else next_state =wait_awready_1;
		BUSY:
			next_state=IDLE;
	endcase
end


/*************************************************************/
/**************************dirty bit**************************/
/*************************************************************/
reg first_input_flag;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<32;i=i+1)dirty_bits[i]<=5;
	end
	else begin
		if(in_valid && first_input_flag)dirty_bits[frame_id]<=window;
	end

end

/*-----------------------------------------------------------*/


/*************************************************************/
//*************************FSM end****************************/
/*************************************************************/



/*************************************************************/
//*************************input******************************/
/*************************************************************/


always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) first_input_flag <= 1;
    else if(in_valid)first_input_flag <= 0;
	else first_input_flag<=1;
end

always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) current_mode <= 0;
    else if(in_valid && first_input_flag)current_mode <= mode;
end

always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) current_windows <= 0;
    else if(in_valid && first_input_flag)current_windows <= window;
end

always @(posedge clk or negedge rst_n) 
begin
    if (!rst_n) current_frame <= 0;
    else if(in_valid && first_input_flag)current_frame <= frame_id;
end


/*****************************************************************/
//*************************input end******************************/
/*****************************************************************/



/*****************************************************************/
//*************************AXI write******************************/
/*****************************************************************/

assign awid_m_inf = 0;
assign awburst_m_inf = 2'b01;
assign awsize_m_inf = 4;
assign awlen_m_inf = (current_mode ? 0 : 255);
assign awaddr_m_inf = 32'h00010000 + (current_frame<<12) + (current_mode ? ((write_cnt2<<8) + 240):0);
assign awvalid_m_inf = current_state == wait_awready_0 ||current_state == wait_awready_1;


assign wvalid_m_inf = (current_state == wait_wready_0 || current_state == write_dram_0 || current_state == wait_wready_1);
assign wdata_m_inf = (current_mode ? dram_write_buf2:dram_write_buf);
assign wlast_m_inf = (output_cnt == 255)|| (current_state == wait_wready_1);

/*****************************************************************/
//*************************AXI write end**************************/
/*****************************************************************/

/*****************************************************************/
//*************************AXI read******************************/
/*****************************************************************/

assign arid_m_inf = 0;
assign arburst_m_inf = 2'b01;
assign arsize_m_inf  = 4;
assign arlen_m_inf   = 255;
assign araddr_m_inf  = 32'h00010000 + (current_frame<<12);
assign arvalid_m_inf = (current_state == wait_arready_1);


assign rready_m_inf = (current_state==calculate);

/*****************************************************************/
//*************************AXI read end**************************/
/*****************************************************************/




/*----------------------------------------------------------------*/
/*-------------------------commmon--------------------------------*/
/*----------------------------------------------------------------*/
wire [127:0]in,pre_in;
calculator u0(.clk(clk),.rst_n(rst_n),.in(dram_data),.pre_in(pre_dram_data),.current_max(current_max),
			  .window_size(current_windows),.next_max(next_max),.next_idx(next_idx),.idx_base(idx_base));



/*----------------------------------------------------------------*/
/*-------------------------commmon-end----------------------------*/
/*----------------------------------------------------------------*/

//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**-*-*-*-*-*-*-*-*-*-*-*-*-*//
//************************mode 0**********************************//
//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**-*-*-*-*-*-*-*-*-*-*-*-*-*//


/*****************************************************************/
//******************************SRAM******************************/
/*****************************************************************/




//********sram control************//
reg [6:0]addr_A[15:0],addr_B[15:0];
reg [7:0]w_date_A[0:15],w_date_B[0:15];
wire w_en_A,w_en_B;
wire [7:0]r_date_A[0:15],r_date_B[0:15];
reg [15:0]add_value;
reg first_start;
reg [6:0]write_addr;
reg [6:0]read_addr;



/////////////////(1)store to sram //////////////////

//Phase_A
generate 
	for(g=0;g<16;g=g+1)
		MEM_128_8_8_200 SRAM_A(.A(addr_A[g]),.D(w_date_A[g]),.CLK(clk),.CEN(1'd0),.WEN(w_en_A),.OEN(1'd0),.Q(r_date_A[g]));
endgenerate


//Phase_B
generate 
	for(g=0;g<16;g=g+1)
		MEM_128_8_8_200 SRAM_B(.A(addr_B[g]),.D(w_date_B[g]),.CLK(clk),.CEN(1'd0),.WEN(w_en_B),.OEN(1'd0),.Q(r_date_B[g]));
endgenerate


assign w_en_A = (current_state!=phase_A);
assign w_en_B = (current_state!=phase_B);


always@*begin
	if (current_mode)
		begin 
			for(i=0;i<16;i=i+1)begin
				addr_A[i] = read_addr + i;
				addr_B[i] = read_addr + i;
			end
		end
	else
		if(current_state==phase_A||current_state==phase_B || current_state==wait_start)
		begin 
			for(i=0;i<16;i=i+1)begin
				addr_A[i] = write_addr + (current_state==phase_B);
				addr_B[i] = write_addr ;
			end
		end
		else 
		begin 
			for(i=0;i<16;i=i+1)begin
				addr_A[i] = addrs[i]+base;
				addr_B[i] = addrs[i]+base;
			end
		end
end


always@*begin
	for(i=0;i<16;i=i+1)addrs[i]<=starting_point-i ;
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		write_addr<=1;
	else
		if(!start)
			write_addr<=0;
		else if(current_state==phase_B)
			write_addr<=write_addr+1;
end


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		first_start<=1;
	else
		if(current_state==IDLE)
			first_start<=1;
		else if(write_addr==127)
			first_start<=0;
end


always@*begin
	for(i=0;i<16;i=i+1)begin 
		w_date_A[i] = add_value[(i+write_addr)%16] + (first_start ? 0:r_date_A[i]);
		w_date_B[i] = add_value[(i+write_addr)%16] + (first_start ? 0:r_date_B[i]);
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		starting_point<=0;
		f<=0;
		base<=0;
	end
	else
		if(current_state==IDLE)
		begin
			starting_point<=0;
			f<=0;
			base<=0;
		end
		else if(wvalid_m_inf&&wready_m_inf)begin
			f<=~f;
			if(!f)begin
				base<=base+16;
				if(base==112)starting_point<=starting_point+1;
			end
		end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		add_value<=0;
	else
		add_value<=stop;
end

//////////////////(2)write back to dram///////////////////


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		save_dram_data<=1;
		save_dram_data2<=1;
	end
	else begin
		save_dram_data<=dram_data;
		save_dram_data2<=save_dram_data;
	end
end

always@*begin
	if(current_state==wait_pipeline) //%16==15
		dram_write_buf = 
		{
			8'b0,r_date_A[addrs[0]],r_date_B[addrs[15]],r_date_A[addrs[15]],
			r_date_B[addrs[14]],r_date_A[addrs[14]],r_date_B[addrs[13]],r_date_A[addrs[13]],
			r_date_B[addrs[12]],r_date_A[addrs[12]],r_date_B[addrs[11]],r_date_A[addrs[11]],
			r_date_B[addrs[10]],r_date_A[addrs[10]],r_date_B[addrs[9 ]],r_date_A[addrs[9 ]]
		};
	else if(current_state==write_dram_0 && output_cnt[3:0]==15)
		dram_write_buf = 
		{
			current_max_idx,save_dram_data2
		};
	else
		if(f)begin
			dram_write_buf = 
			{
				r_date_B[addrs[15]],r_date_A[addrs[15]],r_date_B[addrs[14]],r_date_A[addrs[14]],
				r_date_B[addrs[13]],r_date_A[addrs[13]],r_date_B[addrs[12]],r_date_A[addrs[12]],
				r_date_B[addrs[11]],r_date_A[addrs[11]],r_date_B[addrs[10]],r_date_A[addrs[10]],
				r_date_B[addrs[9 ]],r_date_A[addrs[9 ]],r_date_B[addrs[8 ]],r_date_A[addrs[8 ]]
			};
		end
		else
		begin
			dram_write_buf = 
			{
				r_date_B[addrs[7]],r_date_A[addrs[7]],r_date_B[addrs[6]],r_date_A[addrs[6]],
				r_date_B[addrs[5]],r_date_A[addrs[5]],r_date_B[addrs[4]],r_date_A[addrs[4]],
				r_date_B[addrs[3]],r_date_A[addrs[3]],r_date_B[addrs[2]],r_date_A[addrs[2]],
				r_date_B[addrs[1]],r_date_A[addrs[1]],r_date_B[addrs[0]],r_date_A[addrs[0]]
			};
		end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		output_cnt<=0;
	end
	else if(current_state==IDLE)
			output_cnt<=0;
	else if(wvalid_m_inf&&wready_m_inf)begin
			output_cnt<=output_cnt+1;
		end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)
		busy<=0;
	else
		if(current_state==IDLE)
			busy<=0;
		else if(next_state==wait_awready_0 || next_state==wait_arready_1 || current_state == BUSY)
			busy<=1;
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		idx_base<=0;
	end
	else
		if(current_state==IDLE)begin
			idx_base<=0;
		end
		else if(current_state==write_dram_0 &&output_cnt[3:0]==0)
			idx_base<=0;
		else if(current_state == write_dram_0 || current_state == wait_pipeline )
			idx_base<=idx_base+16;
		else if(current_state == calculate && read_cnt!=0)
			idx_base<=idx_base+16;
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		current_max<=0;
		current_max_idx<=1;
	end
	else
		if(current_state==IDLE || &output_cnt[3:0] && current_state==write_dram_0)begin
			current_max<=0;
			current_max_idx<=1;
		end
		else if(current_state==write_dram_0 || current_state==wait_pipeline||current_state==wait_pipeline2)begin
			if(current_max<next_max)begin
				current_max<=next_max;
				current_max_idx<=next_idx;
			end
		end
		else
			if(distance_valid || current_max<next_max)begin
				current_max<=next_max;
				current_max_idx<=next_idx;			
			end
end


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		dram_data<=0;
		pre_dram_data<=0;
	end
	else begin
		if(current_state==IDLE|| current_state==wait_pipeline2)begin
			dram_data<=0;
			pre_dram_data<=0;
		end
		else if(wready_m_inf && wvalid_m_inf && !(output_cnt[3:0]==15) || current_state==wait_pipeline)begin
			dram_data<=dram_write_buf;
			pre_dram_data<=dram_data[127-:56];
		end
		else if(rvalid_m_inf)begin
			if(&read_cnt[3:0])begin
				dram_data<={8'b0,rdata_m_inf[0+:120]};
			end
			else begin
				dram_data<=rdata_m_inf;
			end
			if(content_valid)
				pre_dram_data<=0;
			else 
				pre_dram_data<=dram_data[127-:56];
		end
	end
end


//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**-*-*-*-*-*-*-*-*-*-*-*-*-*//
//************************mode 0 end******************************//
//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**-*-*-*-*-*-*-*-*-*-*-*-*-*//



//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**-*-*-*-*-*-*-*-*-*-*-*-*-*//
//************************mode 1**********************************//
//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**-*-*-*-*-*-*-*-*-*-*-*-*-*//

assign all_done = write_cnt2==16;
assign dram_write_buf2 = write_back[out_write_back_idx];
assign tmp    = read_cnt-3;
assign tmp2   = read_cnt-1;
assign distance_valid = &tmp[3:0] && read_cnt>3; 
assign content_valid  = &tmp2[3:0]; 


always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		out_write_back_idx<=0;
	end
	else
	begin
		if(current_state==IDLE)begin
			out_write_back_idx<=0;
		end
		else if(wready_m_inf)begin
			out_write_back_idx<=out_write_back_idx+1;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		write_back_idx<=0;
		for(i=0;i<16;i=i+1)write_back[i]<=0;
	end
	else
	begin
		if(current_state==IDLE)
			write_back_idx<=0;
		else if(content_valid)begin
			write_back[write_back_idx][0+:120]<=dram_data[0+:120];
		end
		else if(distance_valid)begin
			write_back_idx<=write_back_idx+1;
			write_back[write_back_idx][120+:8]<=current_max_idx;
		end
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		write_cnt2<=0;
	end
	else
	begin
		if(current_state == IDLE)begin
			write_cnt2<=0;
		end
		else if(current_state == write_dram_1)begin
			write_cnt2<=write_cnt2+1;
		end
	end
end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		read_cnt<=0;
	end
	else
	begin
		if(current_state==IDLE)begin
			read_cnt<=0;
		end
		else if(current_state > calculate)begin
			if(read_cnt<259)read_cnt<=read_cnt+1;
		end
		else if(current_state == calculate)
			read_cnt<=read_cnt+1;
	end
end



//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**-*-*-*-*-*-*-*-*-*-*-*-*-*//
//************************mode 1 end******************************//
//*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-**-*-*-*-*-*-*-*-*-*-*-*-*-*//
endmodule



module calculator(
	clk,
	rst_n,
	in,
	pre_in,
	window_size,
	current_max,
	next_max,
	next_idx,
	idx_base
);

input clk;
input rst_n;
input [127:0]in;
input [55:0]pre_in;
input [10:0]current_max;
input [1:0]window_size;
input [7:0]idx_base;
output [10:0]next_max;
output [7:0]next_idx;


integer i;
wire [7:0]in_0 = in[7  :0  ];
wire [7:0]in_1 = in[15 :8  ];
wire [7:0]in_2 = in[23 :16 ];
wire [7:0]in_3 = in[31 :24 ];
wire [7:0]in_4 = in[39 :32 ];
wire [7:0]in_5 = in[47 :40 ];
wire [7:0]in_6 = in[55 :48 ];
wire [7:0]in_7 = in[63 :56 ];
wire [7:0]in_8 = in[71 :64 ];
wire [7:0]in_9 = in[79 :72 ];
wire [7:0]in_10= in[87 :80 ];
wire [7:0]in_11= in[95 :88 ];
wire [7:0]in_12= in[103:96 ];
wire [7:0]in_13= in[111:104];
wire [7:0]in_14= in[119:112];
wire [7:0]in_15= in[127:120];

wire [7:0]pre_in_0 = pre_in[7  :0  ];
wire [7:0]pre_in_1 = pre_in[15 :8  ];
wire [7:0]pre_in_2 = pre_in[23 :16 ];
wire [7:0]pre_in_3 = pre_in[31 :24 ];
wire [7:0]pre_in_4 = pre_in[39 :32 ];
wire [7:0]pre_in_5 = pre_in[47 :40 ];
wire [7:0]pre_in_6 = pre_in[55 :48 ];


wire [7:0]w0[15:0];
assign w0[0 ] = in_0 ;
assign w0[1 ] = in_1 ;
assign w0[2 ] = in_2 ;
assign w0[3 ] = in_3 ;
assign w0[4 ] = in_4 ;
assign w0[5 ] = in_5 ;
assign w0[6 ] = in_6 ;
assign w0[7 ] = in_7 ;
assign w0[8 ] = in_8 ;
assign w0[9 ] = in_9 ;
assign w0[10] = in_10;
assign w0[11] = in_11;
assign w0[12] = in_12;
assign w0[13] = in_13;
assign w0[14] = in_14;
assign w0[15] = in_15;

wire [8:0]w1[15:0];
assign w1[0 ] = in_0  + pre_in_6 ;
assign w1[1 ] = in_1  + in_0 ;
assign w1[2 ] = in_2  + in_1 ;
assign w1[3 ] = in_3  + in_2 ;
assign w1[4 ] = in_4  + in_3 ;
assign w1[5 ] = in_5  + in_4 ;
assign w1[6 ] = in_6  + in_5 ;
assign w1[7 ] = in_7  + in_6 ;
assign w1[8 ] = in_8  + in_7 ;
assign w1[9 ] = in_9  + in_8;
assign w1[10] = in_10 + in_9;
assign w1[11] = in_11 + in_10;
assign w1[12] = in_12 + in_11;
assign w1[13] = in_13 + in_12;
assign w1[14] = in_14 + in_13;
assign w1[15] = in_15 + in_14	;


//-----------------------------//

wire [9:0]w2[15:0];
assign w2[0 ] = w1[0]     + pre_in_5 + pre_in_4;
assign w2[1 ] = w1[1]  	  + pre_in_6 + pre_in_5;
assign w2[2 ] = w1[2]     + w1[0];
assign w2[3 ] = w1[3]     + w1[1];
assign w2[4 ] = w1[4]     + w1[2];
assign w2[5 ] = w1[5]     + w1[3];
assign w2[6 ] = w1[6]     + w1[4] ;
assign w2[7 ] = w1[7]     + w1[5] ;
assign w2[8 ] = w1[8]     + w1[6] ;
assign w2[9 ] = w1[9]     + w1[7];
assign w2[10] = w1[10]    + w1[8];
assign w2[11] = w1[11]    + w1[9];
assign w2[12] = w1[12]    + w1[10];
assign w2[13] = w1[13]    + w1[11];
assign w2[14] = w1[14]    + w1[12];
assign w2[15] = w1[15]    + w1[13];

//--------------------------------//


wire [10:0]w3[15:0];
assign w3[0 ] = w2[0]     + pre_in_3 + pre_in_2 + pre_in_1 + pre_in_0;
assign w3[1 ] = w2[1]     + pre_in_4 + pre_in_3 + pre_in_2 + pre_in_1;
assign w3[2 ] = w2[2]     + pre_in_5 + pre_in_4 + pre_in_3 + pre_in_2;
assign w3[3 ] = w2[3]     + pre_in_6 + pre_in_5 + pre_in_4 + pre_in_3;
assign w3[4 ] = w2[4]     + w2[0];
assign w3[5 ] = w2[5]     + w2[1];
assign w3[6 ] = w2[6]     + w2[2];
assign w3[7 ] = w2[7]     + w2[3];
assign w3[8 ] = w2[8]     + w2[4];
assign w3[9 ] = w2[9]     + w2[5];
assign w3[10] = w2[10]    + w2[6];
assign w3[11] = w2[11]    + w2[7];
assign w3[12] = w2[12]    + w2[8];
assign w3[13] = w2[13]    + w2[9];
assign w3[14] = w2[14]    + w2[10];
assign w3[15] = w2[15]    + w2[11];

//--------------------------------//


reg [10:0]cmp[15:0];
reg [10:0]current_max_reg;
reg [7:0]idx_base_reg;
always@(posedge clk or negedge rst_n)begin
	if(!rst_n)begin
		for(i=0;i<16;i=i+1)cmp[i]<=0;
		current_max_reg<=0;
		idx_base_reg<=0;
	end
	else
	begin
		case(window_size)
			0:for(i=0;i<16;i=i+1)cmp[i]<=w0[i];
			1:for(i=0;i<16;i=i+1)cmp[i]<=w1[i];
			2:for(i=0;i<16;i=i+1)cmp[i]<=w2[i];
			3:for(i=0;i<16;i=i+1)cmp[i]<=w3[i];
		endcase
		current_max_reg<=current_max;
		idx_base_reg<=idx_base;
	end
end


wire [3:0]big0  = (cmp[0 ] >= cmp[1 ] ? 0  : 1  ); 
wire [3:0]big1  = (cmp[2 ] >= cmp[3 ] ? 2  : 3  ); 
wire [3:0]big2  = (cmp[4 ] >= cmp[5 ] ? 4  : 5  ); 
wire [3:0]big3  = (cmp[6 ] >= cmp[7 ] ? 6  : 7  );
wire [3:0]big4  = (cmp[8 ] >= cmp[9 ] ? 8  : 9  ); 
wire [3:0]big5  = (cmp[10] >= cmp[11] ? 10 : 11 ); 
wire [3:0]big6  = (cmp[12] >= cmp[13] ? 12 : 13 ); 
wire [3:0]big7  = (cmp[14] >= cmp[15] ? 14 : 15 );

//-----------------------------------------------//


wire [3:0]big8  = (cmp[big0] >= cmp[big1] ? big0 : big1 ); 
wire [3:0]big9  = (cmp[big2] >= cmp[big3] ? big2 : big3 ); 
wire [3:0]big10 = (cmp[big4] >= cmp[big5] ? big4 : big5 ); 
wire [3:0]big11 = (cmp[big6] >= cmp[big7] ? big6 : big7 ); 
					
//-----------------------------------------------//					
					
wire [3:0]big12 = (cmp[big8]  >= cmp[big9]  ? big8  : big9 ); 
wire [3:0]big13 = (cmp[big10] >= cmp[big11] ? big10 : big11); 

//-----------------------------------------------//
					
wire [3:0]big14 = (cmp[big12] >= cmp[big13] ? big12 : big13); 




///////////////////////////use big0_14,big1_14,big2_14,big3_14

wire [7:0]next_idxs[3:0];

//-----------------------------------------------//

assign next_idxs[0] = 	idx_base_reg + big14+1;
assign next_idxs[1] = ((idx_base_reg + big14==0)   ?1:(idx_base_reg + big14  ));
assign next_idxs[2] = ((idx_base_reg + big14<3 )   ?1:(idx_base_reg + big14-2));
assign next_idxs[3] = ((idx_base_reg + big14<7 )   ?1:(idx_base_reg + big14-6));

assign next_max = cmp[big14]; 
assign next_idx = next_idxs[window_size]; 
//-----------------------------------------------//



endmodule

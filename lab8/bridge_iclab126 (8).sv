module bridge(input clk, INF.bridge_inf inf);

//================================================================
// logic 
//================================================================

//================================================================
// design 
//================================================================
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.R_READY <= 0;
		inf.B_READY <= 0;
	end
	else
	begin
		inf.R_READY <= 1;
		inf.B_READY <= 1;
	end
end

always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.AW_VALID <= 0;
		inf.AW_ADDR <= 0;
		inf.W_DATA <= 0;
	end
	else
	begin
		if(inf.C_in_valid && !inf.C_r_wb)
		begin
			inf.AW_VALID <= 1;
			inf.AW_ADDR  <= 17'd65536 + (inf.C_addr << 3);
			inf.W_DATA <= inf.C_data_w;
		end
		else if(inf.AW_READY)
		begin
			inf.AW_VALID <= 0;
		end
	end
end

always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.W_VALID <= 0;
	end
	else
	begin
		if(inf.AW_READY)
		begin
			inf.W_VALID <= 1;
			
		end
		else if(inf.W_READY)
		begin
			inf.W_VALID <= 0;
		end
	end
end

always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.AR_VALID <= 0;
		inf.AR_ADDR <= 0;
	end
	else
	begin
		if(inf.C_in_valid && inf.C_r_wb)
		begin
			inf.AR_VALID<= 1;
			inf.AR_ADDR <= 17'd65536 + (inf.C_addr << 3);
		end
		else if(inf.AR_READY)
		begin
			inf.AR_VALID <= 0;
		end
	end
end

always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.C_data_r <= 0;
	end
	else
	begin
		if(inf.R_VALID)
		begin
			inf.C_data_r <= inf.R_DATA;
		end
	end
end


always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		inf.C_out_valid <= 0;
	end
	else
	begin
		if(inf.R_VALID || inf.B_VALID)
		begin
			inf.C_out_valid <= 1;
		end
		else 
		begin
			inf.C_out_valid <= 0;
		end
	end
end



endmodule

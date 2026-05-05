module apb_slave_wait_state (
	input 	wire 		pclk,
	input 	wire 		prst_n,
	input 	wire 		pwrite,
	input 	wire 		psel,
	input 	wire 		penable,
	input	wire 	[31:0]	pwdata,
	input 	wire	[11:0]	paddr,
	input 	wire	[3:0]	pstrb,
	
	input 	wire		timer_en,
	input	wire		div_en,
	input	wire	[3:0]	div_val,


	output	reg		wr_en,
	output	reg		rd_en,
	output 	wire 		pslverr,
	output 	wire 		pready
);
	//wr_en
	wire wr_en_prev;
	assign wr_en_prev = (pwrite & psel & penable & ~wr_en) ;

	always @(posedge pclk or negedge prst_n) begin
		if(!prst_n) 
			wr_en <= 1'b0;
		else	
			wr_en <= wr_en_prev;
	end

	//rd_en
	wire rd_en_prev;
	assign rd_en_prev = (~pwrite & psel & penable & ~rd_en);

	always @(posedge pclk or negedge prst_n) begin
		if(!prst_n) 
			rd_en <= 1'b0;
		else	
			rd_en <= rd_en_prev;
	end
	
	//pready
	assign pready = wr_en | rd_en;

	//pslverr
	wire tcr_wr_sel;
	assign tcr_wr_sel = wr_en & (paddr == 12'h00);

	wire invalid_div_val;
	assign invalid_div_val = (pwdata[11:8] > 8) & pstrb[1];

	wire div_val_violation;
	assign div_val_violation = (timer_en & pstrb[1] & (pwdata[11:8] != div_val));

	wire div_en_violation;
	assign div_en_violation = (timer_en & pstrb[0] & (pwdata[1] != div_en));

	assign pslverr = (invalid_div_val | div_val_violation | div_en_violation) & tcr_wr_sel;

endmodule

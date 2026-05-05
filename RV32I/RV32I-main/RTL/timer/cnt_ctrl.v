module cnt_ctrl (
	input  	wire		pclk,
	input	wire		prst_n,
	input 	wire 		timer_en,
	input	wire 		div_en,
	input	wire	[3:0]	div_val,
	input 	wire		halt_req,
	input 	wire		debug_mode,
	output 	wire		cnt_en
);
	reg 	[7:0]	int_cnt;

	wire	[7:0]	limit;
	assign	limit	= (1 << div_val) - 1;

	wire 	cnt_rst = (~timer_en | ~div_en | (limit == int_cnt));
	
	wire 	[7:0]	int_cnt_pre;
	assign 	int_cnt_pre = (halt_req & debug_mode) 		  ? int_cnt :
			      (cnt_rst)		      		  ? 8'h00   :
			      (timer_en & div_en & (div_val != 0)) ? int_cnt + 1 : 
			      					  int_cnt;

	always @(posedge pclk or negedge prst_n) begin
		if(!prst_n) 
			int_cnt <= 8'b0;
		else
			int_cnt <= int_cnt_pre;
	end

	assign cnt_en = ((~div_en & timer_en) | 
			   (timer_en & div_en & (div_val != 0) & (int_cnt == limit)) |
			   (timer_en & div_en & (div_val == 0))) & ~(halt_req & debug_mode);

endmodule

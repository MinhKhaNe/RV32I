module register_module (
	input 	wire 		pclk,
	input 	wire		prst_n,
	input 	wire 		wr_en,
	input 	wire		rd_en,
	input 	wire 	[11:0]	paddr,
	input 	wire 	[31:0]	pwdata,
	input	wire	[3:0]	pstrb,
	input	wire		debug_mode,
	input 	wire		pslverr,
	input 	wire		cnt_en,

	output	reg		div_en,
	output 	reg	[3:0]	div_val,
	output	reg		timer_en,
	output	reg		halt_req,

	output	wire 		tdr0_wr_sel,
	output 	wire		tdr1_wr_sel,
	output 	wire 	[63:0]	cnt,
	
	output	reg 		int_en,
	output 	reg		int_st,

	output	reg	[31:0]	prdata,
	output 	wire		tim_int
);

	parameter [11:0] ADDR_TCR = 12'h00;
	parameter [11:0] ADDR_TDR0 = 12'h04;
	parameter [11:0] ADDR_TDR1 = 12'h08;
	parameter [11:0] ADDR_TCMP0 = 12'h0C;
	parameter [11:0] ADDR_TCMP1 = 12'h10;
	parameter [11:0] ADDR_TIER = 12'h14;
	parameter [11:0] ADDR_TISR = 12'h18;
	parameter [11:0] ADDR_THCSR = 12'h1C;

	wire	wr_en_ok;
	assign 	wr_en_ok = wr_en & ~pslverr;

	//TCR
	wire		timer_en_prev;
	wire		div_en_prev;
	wire	[3:0]	div_val_prev;
	reg		timer_en_r;

	wire tcr_wr_sel;
	assign tcr_wr_sel = wr_en_ok & (paddr == ADDR_TCR);

	assign timer_en_prev = (pstrb[0] && tcr_wr_sel) ? pwdata[0] : timer_en;

	always @(posedge pclk or negedge prst_n) begin
		if(!prst_n) begin
			timer_en_r <= 1'b0;
		end
		else begin
			timer_en_r <= timer_en;
		end
	end

	always @(posedge pclk or negedge prst_n) begin
		if(!prst_n)
			timer_en <= 1'b0;
		else	
			timer_en <= timer_en_prev;
	end

	assign div_en_prev = (pstrb[0] && tcr_wr_sel) ? pwdata[1] : div_en;

	always @(posedge pclk or negedge prst_n) begin
		if(!prst_n)
			div_en <= 1'b0;
		else	
			div_en <= div_en_prev;
	end

	assign div_val_prev = (pstrb[1] && tcr_wr_sel && (pwdata[11:8] < 9)) ? pwdata[11:8] : div_val;

	always @(posedge pclk or negedge prst_n) begin
		if(!prst_n)
			div_val <= 4'b0001;
		else	
			div_val <= div_val_prev;
	end

	wire	[31:0]	tcr;
	assign	tcr = {20'h0,div_val,6'b0,div_en,timer_en};
	
	//tdr0/1
	reg	[31:0] 	tdr0;
	wire	[31:0]	tdr0_prev;
	reg 	[31:0]	tdr1;
	wire	[31:0]	tdr1_prev;

	assign 	cnt = cnt_en ? {tdr1,tdr0} + 1 : {tdr1,tdr0};
	
	assign tdr0_wr_sel = wr_en & (paddr == ADDR_TDR0);
	assign tdr0_prev[7:0] = (pstrb[0] & tdr0_wr_sel) ? pwdata[7:0] : cnt[7:0];
	assign tdr0_prev[15:8] = (pstrb[1] & tdr0_wr_sel) ? pwdata[15:8] : cnt[15:8];
	assign tdr0_prev[23:16] = (pstrb[2] & tdr0_wr_sel) ? pwdata[23:16] : cnt[23:16];
	assign tdr0_prev[31:24] = (pstrb[3] & tdr0_wr_sel) ? pwdata[31:24] : cnt[31:24];
	
	
	assign tdr1_wr_sel = wr_en & (paddr == ADDR_TDR1);
	
	assign tdr1_prev[7:0] = (pstrb[0] & tdr1_wr_sel) ? pwdata[7:0] : cnt[39:32];
	assign tdr1_prev[15:8] = (pstrb[1] & tdr1_wr_sel) ? pwdata[15:8] : cnt[47:40];
	assign tdr1_prev[23:16] = (pstrb[2] & tdr1_wr_sel) ? pwdata[23:16] : cnt[55:48];
	assign tdr1_prev[31:24] = (pstrb[3] & tdr1_wr_sel) ? pwdata[31:24] : cnt[63:56];
	
	always @(posedge pclk or negedge prst_n) begin
		if(!prst_n) begin
			tdr0 <= 32'b0;
			tdr1 <= 32'b0;
		end
		else if(timer_en_r && ~timer_en) begin
			tdr0 <= 32'b0;
			tdr1 <= 32'b0;
		end
		else begin
			tdr0 <= tdr0_prev;
			tdr1 <= tdr1_prev;
		end
	end		

	//tcmp0/1
	
	reg	[7:0]	tcmp0_byte0;
	reg	[7:0]	tcmp0_byte1;
	reg	[7:0]	tcmp0_byte2;
	reg	[7:0]	tcmp0_byte3;

	wire	[7:0]	tcmp0_byte0_prev;
	wire	[7:0]	tcmp0_byte1_prev;
	wire	[7:0]	tcmp0_byte2_prev;
	wire	[7:0]	tcmp0_byte3_prev;

	wire tcmp0_wr_sel;
	assign tcmp0_wr_sel = wr_en & (paddr == ADDR_TCMP0);
	
	assign tcmp0_byte0_prev = (pstrb[0] & tcmp0_wr_sel) ? pwdata[7:0] : tcmp0_byte0;
	assign tcmp0_byte1_prev = (pstrb[1] & tcmp0_wr_sel) ? pwdata[15:8] : tcmp0_byte1;
	assign tcmp0_byte2_prev = (pstrb[2] & tcmp0_wr_sel) ? pwdata[23:16] : tcmp0_byte2;
	assign tcmp0_byte3_prev = (pstrb[3] & tcmp0_wr_sel) ? pwdata[31:24] : tcmp0_byte3;

	always @(posedge pclk or negedge prst_n) begin
		if(!prst_n)
			tcmp0_byte0 <= 8'hFF;
		else
			tcmp0_byte0 <= tcmp0_byte0_prev;
	end

	always @(posedge pclk or negedge prst_n) begin
		if(!prst_n)
			tcmp0_byte1 <= 8'hFF;
		else
			tcmp0_byte1 <= tcmp0_byte1_prev;
	end

	always @(posedge pclk or negedge prst_n) begin
		if(!prst_n)
			tcmp0_byte2 <= 8'hFF;
		else
			tcmp0_byte2 <= tcmp0_byte2_prev;
	end

	always @(posedge pclk or negedge prst_n) begin
		if(!prst_n)
			tcmp0_byte3 <= 8'hFF;
		else
			tcmp0_byte3 <= tcmp0_byte3_prev;
	end

	wire	[31:0]	 tcmp0;
	assign 	tcmp0 = {tcmp0_byte3,tcmp0_byte2,tcmp0_byte1,tcmp0_byte0};
	
	reg	[7:0]	tcmp1_byte0;
	reg	[7:0]	tcmp1_byte1;
	reg	[7:0]	tcmp1_byte2;
	reg	[7:0]	tcmp1_byte3;

	wire	[7:0]	tcmp1_byte0_prev;
	wire	[7:0]	tcmp1_byte1_prev;
	wire	[7:0]	tcmp1_byte2_prev;
	wire	[7:0]	tcmp1_byte3_prev;

	wire tcmp1_wr_sel;
	assign tcmp1_wr_sel = wr_en & (paddr == ADDR_TCMP1);
	
	assign tcmp1_byte0_prev = (pstrb[0] & tcmp1_wr_sel) ? pwdata[7:0] : tcmp1_byte0;
	assign tcmp1_byte1_prev = (pstrb[1] & tcmp1_wr_sel) ? pwdata[15:8] : tcmp1_byte1;
	assign tcmp1_byte2_prev = (pstrb[2] & tcmp1_wr_sel) ? pwdata[23:16] : tcmp1_byte2;
	assign tcmp1_byte3_prev = (pstrb[3] & tcmp1_wr_sel) ? pwdata[31:24] : tcmp1_byte3;

	always @(posedge pclk or negedge prst_n) begin
		if(!prst_n)
			tcmp1_byte0 <= 8'hFF;
		else
			tcmp1_byte0 <= tcmp1_byte0_prev;
	end

	always @(posedge pclk or negedge prst_n) begin
		if(!prst_n)
			tcmp1_byte1 <= 8'hFF;
		else
			tcmp1_byte1 <= tcmp1_byte1_prev;
	end

	always @(posedge pclk or negedge prst_n) begin
		if(!prst_n)
			tcmp1_byte2 <= 8'hFF;
		else
			tcmp1_byte2 <= tcmp1_byte2_prev;
	end

	always @(posedge pclk or negedge prst_n) begin
		if(!prst_n)
			tcmp1_byte3 <= 8'hFF;
		else
			tcmp1_byte3 <= tcmp1_byte3_prev;
	end

	wire	[31:0]	 tcmp1;
	assign 	tcmp1 = {tcmp1_byte3,tcmp1_byte2,tcmp1_byte1,tcmp1_byte0};

	
	wire	[63:0] 	tcmp;
	assign 	tcmp = {tcmp1,tcmp0};

	//tier
	wire 	tier_wr_sel;
	assign 	tier_wr_sel = (wr_en & (paddr == ADDR_TIER));

	wire 	int_en_prev;
	assign 	int_en_prev = (pstrb[0] & tier_wr_sel) ? pwdata[0] : int_en;

	always @(posedge pclk or negedge prst_n) begin
		if(!prst_n)
			int_en <= 1'b0;
		else
			int_en <= int_en_prev;
	end

	wire	[31:0]	tier;
	assign	tier = {30'b0,int_en};

	//tisr
	wire 	tisr_wr_sel;
	assign 	tisr_wr_sel = (wr_en & (paddr == ADDR_TISR));
	
	wire 	int_set;
	assign	int_set = (cnt == tcmp);
	
	wire 	int_clr;
	assign 	int_clr = (pstrb[0] & tisr_wr_sel & (pwdata[0] == 1'b1));

	wire 	int_st_prev;
	assign 	int_st_prev = (int_clr) ? 1'b0 :
	       		      (int_set) ? 1'b1 : int_st;	

	always @(posedge pclk or negedge prst_n) begin
		if(!prst_n)
			int_st <= 1'b0;
		else
			int_st <= int_st_prev;
	end

	wire	[31:0]	tisr;
	assign	tisr = {31'b0,int_st};

	//thcsr
	wire 	thcsr_wr_sel;
	assign 	thcsr_wr_sel = (wr_en & (paddr == ADDR_THCSR));

	wire 	halt_req_prev;
	assign 	halt_req_prev = (pstrb[0] & thcsr_wr_sel) ? pwdata[0] : halt_req;

	always @(posedge pclk or negedge prst_n) begin
		if(!prst_n)
			halt_req <= 1'b0;
		else
			halt_req <= halt_req_prev;
	end
	
	wire	halt_ack;
	assign 	halt_ack = (halt_req & debug_mode);

	wire	[31:0]	thcsr;
	assign	thcsr = {29'b0,halt_ack,halt_req};

	assign tim_int = int_st & int_en;

	always @(*) begin
		if(rd_en == 1'b0) 
			prdata = 32'b0;
		else begin
			case(paddr)
				ADDR_TCR : prdata = tcr;
	 			ADDR_TDR0 : prdata = tdr0;
                                ADDR_TDR1 : prdata = tdr1;
                                ADDR_TCMP0 : prdata = tcmp0;
                                ADDR_TCMP1 : prdata = tcmp1;
                                ADDR_TIER : prdata = tier;
                                ADDR_TISR : prdata = tisr;
                                ADDR_THCSR : prdata = thcsr;
				default : prdata = 32'b0;
			endcase
		end
	end
endmodule

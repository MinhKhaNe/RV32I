module timer_top (
	input	wire 		sys_clk,
	input	wire		sys_rst_n,
	input	wire		tim_psel,
	input	wire		tim_pwrite,
	input	wire		tim_penable,
	input	wire	[11:0]	tim_paddr,
	input	wire	[31:0]	tim_pwdata,
	input	wire	[3:0]	tim_pstrb,
	input	wire		dbg_mode,
	output	wire	[31:0]	tim_prdata,
	output	wire		tim_pready,
	output	wire		tim_pslverr,
	output	wire		tim_int
);
	wire		wr_en;
	wire		rd_en;
	wire		timer_en;
	wire		div_en;
	wire	[3:0]	div_val;
	wire	[63:0]	cnt;
	wire		halt_req;
	wire		tdr0_wr_sel;
	wire		tdr1_wr_sel;
	wire		int_en;
	wire		int_st;
	wire		cnt_en;

	apb_slave_wait_state apb_slave (
		.pclk		(sys_clk	),
		.prst_n		(sys_rst_n	),
		.pwrite		(tim_pwrite	),
		.psel		(tim_psel	),
		.penable	(tim_penable	),
		.pwdata		(tim_pwdata	),
		.paddr		(tim_paddr	),
		.pstrb		(tim_pstrb	),
		.timer_en	(timer_en	),
		.div_en		(div_en		),
		.div_val	(div_val	),
		.wr_en		(wr_en		),
		.rd_en		(rd_en		),
		.pready		(tim_pready	),
		.pslverr	(tim_pslverr	)
	);

	register_module	register (
		.pclk		(sys_clk	),
		.prst_n		(sys_rst_n	),
		.wr_en		(wr_en		),
		.rd_en		(rd_en		),
		.paddr		(tim_paddr	),
		.pwdata		(tim_pwdata	),
		.pstrb		(tim_pstrb	),
		.debug_mode	(dbg_mode	),
		.pslverr	(tim_pslverr	),
		.cnt_en		(cnt_en		),
		.div_en		(div_en		),
		.div_val	(div_val	),
		.timer_en	(timer_en	),
		.halt_req	(halt_req	),
		.tdr0_wr_sel	(tdr0_wr_sel	),
		.tdr1_wr_sel	(tdr1_wr_sel	),
		.cnt		(cnt		),
		.int_en		(int_en		),
		.int_st		(int_st		),
		.prdata		(tim_prdata	),
		.tim_int	(tim_int	)
	);

	cnt_ctrl counter_control (
		.pclk		(sys_clk	),
		.prst_n		(sys_rst_n	),
		.timer_en	(timer_en	),
		.div_en		(div_en		),
		.div_val	(div_val	),
		.halt_req	(halt_req	),
		.debug_mode	(dbg_mode	),
		.cnt_en		(cnt_en		)
	);


endmodule

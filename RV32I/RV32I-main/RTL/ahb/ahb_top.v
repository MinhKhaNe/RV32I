module ahb_top(
    input   wire            HCLK,
    input   wire            HRESETn,

    input   wire    [31:0]  CPU_WDATA,
    input   wire    [31:0]  CPU_ADDR,
    input   wire            CPU_WRITE_REQ,
    input   wire            CPU_VALID,
    input   wire    [2:0]   CPU_BURST_REQ,
    input   wire    [2:0]   CPU_SIZE_REQ,
    input   wire            CPU_PRIVILEGED,
    input   wire            CPU_DATA,
    input   wire    [3:0]   CPU_HPROT,

    output  wire    [31:0]  CPU_RDATA,
    output  wire            CPU_READY 
);

    wire    [31:0]  hrdata_sram;
    wire    [31:0]  hrdata_timer;
    wire            hready_sram, hresp_sram;
    wire            hready_timer, hresp_timer;  
    wire            h_ready;
    wire            h_resp;

    wire    [31:0]  h_addr, h_wdata;
    wire    [3:0]   h_prot;
    wire    [2:0]   h_burst, h_size;
    wire    [1:0]   h_trans;
    wire            h_write, h_mastlock;
    wire            h_ready_slave;
    wire            hsel_sram, hsel_spi, hsel_i2c, hsel_timer, hsel_uart, hsel_invalid;
    wire    [31:0]  ram_rdata;       
    wire    [31:0]  data_to_sram;     
    wire    [31:0]  address_to_sram; 
    reg     [31:0]  address_reg;
    reg             hwr_en_d, hrd_en_d;
    wire            hwr_en, hrd_en;
    //Timer
    wire            tim_psel;
    wire            tim_penable;
    wire            tim_pwrite;
    wire    [11:0]  tim_paddr;
    wire    [31:0]  tim_pwdata;
    wire    [31:0]  tim_prdata;
    wire            tim_pready;
    wire            tim_pslverr;
    wire            tim_int;
    reg             hsel_sram_reg;
    reg             hsel_timer_reg;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            hsel_sram_reg  <= 1'b0;
            hsel_timer_reg <= 1'b0;
        end else if (h_ready) begin 
            hsel_sram_reg  <= hsel_sram;
            hsel_timer_reg <= hsel_timer;
        end
    end

    assign CPU_READY    =   h_ready;

    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            hwr_en_d    <= 1'b0;
            hrd_en_d    <= 1'b0;
            address_reg <= 32'b0;
        end 
        else begin
            hwr_en_d    <= hwr_en;
            address_reg <= address_to_sram;
            hrd_en_d    <= hrd_en;
        end 
    end

    ahb_manager u_manager (
        .HCLK           (HCLK),
        .HRESETn        (HRESETn),
        .HREADY         (h_ready),    
        .HRESP          (h_resp),
        .WDATA          (CPU_WDATA),
        .HWADDR         (CPU_ADDR),
        .HWRITE_REQ     (CPU_WRITE_REQ),
        .CPU_PRIVILEGED (1'b1),
        .CPU_DATA       (CPU_DATA),
        .CPU_HPROT      (CPU_HPROT),
        .HVALID         (CPU_VALID),
        .LOCK_REQ       (1'b0),
        .HBURST_REQ     (CPU_BURST_REQ),
        .HSIZE_REQ      (CPU_SIZE_REQ),
        .HADDR          (h_addr),
        .HBURST         (h_burst),
        .HMASTLOCK      (h_mastlock),
        .HPROT          (h_prot),
        .HSIZE          (h_size),
        .HTRANS         (h_trans),
        .HWRITE         (h_write),
        .HWDATA         (h_wdata)
    );

    ahb_subordinate_sram u_slave_sram (
        .HCLK           (HCLK),
        .HRESETn        (HRESETn),
        .HSEL           (hsel_sram),       
        .HADDR          (h_addr),
        .HTRANS         (h_trans),
        .HWRITE         (h_write),
        .HSIZE          (h_size),
        .HBURST         (h_burst),
        .HMASTLOCK      (h_mastlock),
        .HREADY         (hready_sram),   
        .HPROT          (h_prot),
        .HWDATA         (h_wdata),
        .SRAM_DATA      (ram_rdata),
        .HREADYOUT      (h_ready),    
        .HRESP          (hresp_sram),
        .HEXOKAY        (),
        .HRDATA         (hrdata_sram),
        .hwr_en         (hwr_en),
        .hrd_en         (hrd_en),
        .data_to_sram   (data_to_sram),
        .address_to_sram (address_to_sram)
    );

    ram_top #(
        .HOST_W(32),
        .HOST_ADDR_W(32),
        .SRAMA_ADR_W(10),
        .SRAMA_W(128),
        .SRAMB_ADR_W(10),
        .SRAMB_W(128),
        .SRAMC_ADR_W(10),
        .SRAMC_W(128),
        .SRAMC_MW(8)
    ) sram (
        .clk        (HCLK),
        .rst_n      (HRESETn),
        .sram_sel   (3'b100), 

        .hdata      (data_to_sram),
        .haddr      (address_reg),
        .hwmask     (4'b1111),
        .hrd_en     (hrd_en_d),
        .hwr_en     (hwr_en_d),
        .data_out   (ram_rdata),

        .srama_addr (10'd0),
        .srama_rd_en(1'b0),
        .srama_data (),

        .sramb_addr (10'd0),
        .sramb_rd_en(1'b0),
        .sramb_data (),

        .sramc_data_in (128'd0),
        .sramc_addr    (10'd0),
        .sramc_rd_en   (1'b0),
        .sramc_wr_en   (1'b0),
        .sramc_wmask   (8'd0),
        .sramc_data    ()
    );

    timer_top timer (
        .sys_clk(HCLK),
        .sys_rst_n(HRESETn),
        .tim_psel(tim_psel),
        .tim_pwrite(tim_pwrite),
        .tim_penable(tim_penable),
        .tim_paddr(tim_paddr),
        .tim_pwdata(tim_pwdata),
        .tim_pstrb(4'b1111),
        .dbg_mode(1'b0),
        .tim_prdata(tim_prdata),
        .tim_pready(tim_pready),
        .tim_pslverr(tim_pslverr),
        .tim_int(tim_int)
    );

    ahb_subordinate_timer u_slave_timer(
        .HCLK       (HCLK),
        .HRESETn    (HRESETn),
        .HSEL       (hsel_timer),       
        .HWDATA     (h_wdata),
        .HADDR      (h_addr),
        .HTRANS     (h_trans),
        .HWRITE     (h_write),
        .HSIZE      (h_size),
        .HBURST     (h_burst),
        .HMASTLOCK  (h_mastlock),
        .HREADY     (h_ready),   
        .HPROT      (h_prot),
        .HREADYOUT  (hready_timer),    
        .HRESP      (hresp_timer),
        .HEXOKAY    (),
        .HRDATA     (hrdata_timer),
        .PRDATA     (tim_prdata),
        .PREADY     (tim_pready),
        .PSEL       (tim_psel),
        .PENABLE    (tim_penable),
        .PWRITE     (tim_pwrite),
        .PADDR      (tim_paddr),
        .PWDATA     (tim_pwdata)
    );

    // ahb_subordinate u_slave_uart (
    //     .HCLK       (HCLK),
    //     .HRESETn    (HRESETn),
    //     .HSEL       (hsel_uart),       
    //     .HWDATA     (h_wdata),
    //     .HADDR      (h_addr),
    //     .HTRANS     (h_trans),
    //     .HWRITE     (h_write),
    //     .HSIZE      (h_size),
    //     .HBURST     (h_burst),
    //     .HMASTLOCK  (h_mastlock),
    //     .HREADY     (h_ready),   
    //     .HPROT      (h_prot),
    //     .HREADYOUT  (h_ready),    
    //     .HRESP      (h_resp),
    //     .HEXOKAY    (),
    //     //.HRDATA     (CPU_RDATA)
    // );

    // ahb_subordinate u_slave_spi (
    //     .HCLK       (HCLK),
    //     .HRESETn    (HRESETn),
    //     .HSEL       (hsel_spi),       
    //     .HWDATA     (h_wdata),
    //     .HADDR      (h_addr),
    //     .HTRANS     (h_trans),
    //     .HWRITE     (h_write),
    //     .HSIZE      (h_size),
    //     .HBURST     (h_burst),
    //     .HMASTLOCK  (h_mastlock),
    //     .HREADY     (h_ready),   
    //     .HPROT      (h_prot),
    //     .HREADYOUT  (h_ready),    
    //     .HRESP      (h_resp),
    //     .HEXOKAY    (),
    //     //.HRDATA     (CPU_RDATA)
    // );

    // ahb_subordinate u_slave_i2c (
    //     .HCLK       (HCLK),
    //     .HRESETn    (HRESETn),
    //     .HSEL       (hsel_i2c),       
    //     .HWDATA     (h_wdata),
    //     .HADDR      (h_addr),
    //     .HTRANS     (h_trans),
    //     .HWRITE     (h_write),
    //     .HSIZE      (h_size),
    //     .HBURST     (h_burst),
    //     .HMASTLOCK  (h_mastlock),
    //     .HREADY     (h_ready),   
    //     .HPROT      (h_prot),
    //     .HREADYOUT  (h_ready),    
    //     .HRESP      (h_resp),
    //     .HEXOKAY    (),
    //     //.HRDATA     (CPU_RDATA)
    // );

    ahb_decoder decoder (
        .HCLK           (HCLK),
        .HRESETn        (HRESETn),
        .HADDR          (h_addr),
        .HSEL_SRAM      (hsel_sram),
        .HSEL_TIMER     (hsel_timer),
        .HSEL_SPI       (hsel_spi),
        .HSEL_I2C       (hsel_i2c),
        .HSEL_UART      (hsel_uart),
        .HSEL_INVALID   (hsel_invalid)
    );

    ahb_multiplexor u_mux (
        .hsel_sram    (hsel_sram_reg),
        .hsel_timer   (hsel_timer_reg),
        .hrdata_sram  (hrdata_sram),
        .hrdata_timer (hrdata_timer),
        .hready_sram  (hready_sram),
        .hready_timer (hready_timer),
        .hresp_sram   (hresp_sram),
        .hresp_timer  (hresp_timer),
        .HRDATA       (CPU_RDATA), 
        .HREADY       (h_ready),   
        .HRESP        (h_resp)
    );

endmodule
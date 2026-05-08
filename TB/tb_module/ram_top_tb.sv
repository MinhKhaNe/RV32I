`timescale 1ns/1ps

module ram_top_tb;

    // Parameters
    parameter HOST_W      = 32;
    parameter HOST_ADDR_W = 32;
    parameter SRAMA_W     = 128;
    parameter SRAMA_ADR_W = 10;

    // Signals
    reg                     clk;
    reg                     rst_n;
    reg  [2:0]              sram_sel;
    reg  [HOST_W-1:0]       hdata;
    reg  [HOST_ADDR_W-1:0]  haddr;
    reg  [HOST_W/8-1:0]     hwmask;
    reg                     hrd_en;
    reg                     hwr_en;
    wire [HOST_W-1:0]       data_out;
    wire [SRAMA_W-1:0]      srama_data;

    // Instantiate Top Module
    ram_top #(
        .HOST_W(HOST_W),
        .SRAMA_W(SRAMA_W),
        .SRAMA_ADR_W(SRAMA_ADR_W)
    ) dut (
        .clk(clk), .rst_n(rst_n), .sram_sel(sram_sel),
        .hdata(hdata), .haddr(haddr), .hwmask(hwmask),
        .hrd_en(hrd_en), .hwr_en(hwr_en), .data_out(data_out),
        .srama_data(srama_data),
        .srama_addr(10'b0), .srama_rd_en(1'b0), // Lock ports không dùng
        .sramb_addr(10'b0), .sramb_rd_en(1'b0),
        .sramc_data_in(128'b0), .sramc_addr(10'b0), .sramc_rd_en(1'b0),
        .sramc_wr_en(1'b0), .sramc_wmask(8'b0)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // Macro để in nhanh giá trị trong Memory (truy cập phân cấp)
    // Lưu ý: Tên sram_0 có thể thay đổi tùy theo code ram_wrapper của bạn
    `define TARGET_MEM dut.srama.sram_0.mem[0]

    // MONITOR: In trạng thái chi tiết mỗi Clock
    initial begin
        $display("\n[TIME] | SEL | WR | RD | HADDR | DATA_IN  | MEM[0] (SRAMA)   | DATA_OUT");
        $display("--------------------------------------------------------------------------");
        forever @(posedge clk) begin
            #1; // Đợi signal ổn định sau cạnh clock
            $display("[%4t] | %b  | %b  | %b  | %h | %h | %h | %h", 
                     $time, sram_sel, hwr_en, hrd_en, haddr, hdata, `TARGET_MEM, data_out);
        end
    end

    // Test Procedure
    initial begin
        // 1. Reset
        rst_n = 0;
        sram_sel = 3'b001; // SRAM A selected cho Host
        hdata = 0; haddr = 0; hwmask = 0; hrd_en = 0; hwr_en = 0;
        #20 rst_n = 1;
        repeat(2) @(posedge clk);

        // 2. WRITE OPERATION (Ghi 32-bit vào hàng 128-bit đầu tiên)
        @(posedge clk);
        haddr  = 32'h0;
        hdata  = 32'hDEAD_BEEF;
        hwmask = 4'hF;
        hwr_en = 1; // Bật lệnh ghi
        
        @(posedge clk); // Sau cạnh clock này, mem[0] sẽ thay đổi
        hwr_en = 0;
        hdata  = 32'h0; // Xóa input để chắc chắn kết quả đọc là từ RAM
        
        repeat(2) @(posedge clk);

        // 3. READ OPERATION (Quan sát Latency)
        @(posedge clk);
        hrd_en = 1; // Nhịp 1: Gửi lệnh đọc
        
        @(posedge clk); 
        hrd_en = 0; // Nhịp 2: Lệnh đọc đã được RAM tiếp nhận
        
        @(posedge clk); // Nhịp 3: Dữ liệu đang ở ngõ ra wrapper, chờ chốt vào top
        
        @(posedge clk); // Nhịp 4: Dữ liệu xuất hiện tại data_out

        #50;
        $display("--------------------------------------------------------------------------");
        $finish;
    end

endmodule
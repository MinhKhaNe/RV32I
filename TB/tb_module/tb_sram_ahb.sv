`timescale 1ns/1ps

module tb_sram_ahb();

    // Signals
    reg         HCLK;
    reg         HRESETn;
    reg [31:0]  CPU_ADDR;
    reg [31:0]  CPU_WDATA;
    reg         CPU_WRITE_REQ;
    reg         CPU_VALID;
    reg [2:0]   CPU_SIZE_REQ;
    reg [2:0]   CPU_BURST_REQ;
    
    wire [31:0] CPU_RDATA;
    wire        CPU_READY;

    // Clock Generation
    initial HCLK = 0;
    always #5 HCLK = ~HCLK; // 100MHz

    // Instantiate Top Module
    ahb_top dut (
        .HCLK           (HCLK),
        .HRESETn        (HRESETn),
        .CPU_WDATA      (CPU_WDATA),
        .CPU_ADDR       (CPU_ADDR),
        .CPU_WRITE_REQ  (CPU_WRITE_REQ),
        .CPU_VALID      (CPU_VALID),
        .CPU_BURST_REQ  (3'b000), // SINGLE
        .CPU_SIZE_REQ   (3'b010), // WORD
        .CPU_PRIVILEGED (1'b1),
        .CPU_DATA       (1'b1),
        .CPU_HPROT      (4'b0011),
        .CPU_RDATA      (CPU_RDATA),
        .CPU_READY      (CPU_READY)
    );

    // Task Write theo phong cách cũ
    task ahb_write(input [31:0] addr, input [31:0] data);
    begin
        // --- Address Phase ---
        @(posedge HCLK);
        #1;
        CPU_ADDR      = addr;
        CPU_WRITE_REQ = 1'b1;
        CPU_VALID     = 1'b1;
        
        wait(CPU_READY); // Đợi Slave sẵn sàng nhận địa chỉ
        
        // --- Data Phase ---
        @(posedge HCLK);
        #1;
        CPU_WDATA     = data;   // Đưa dữ liệu ra
        CPU_VALID     = 1'b0;   // Kết thúc yêu cầu địa chỉ (Idle hoặc Nonseq tiếp theo)
        CPU_WRITE_REQ = 1'b0;
        
        wait(CPU_READY); // Đợi Slave ghi xong dữ liệu
    end
    endtask

    // Task Read theo phong cách cũ
    task ahb_read(input [31:0] addr);
    begin
        // --- Address Phase ---
        @(posedge HCLK);
        #1;
        CPU_ADDR      = addr;
        CPU_WRITE_REQ = 1'b0;
        CPU_VALID     = 1'b1;
        
        wait(CPU_READY); // Đợi Slave nhận địa chỉ đọc
        
        // --- Data Phase ---
        @(posedge HCLK);
        #1;
        CPU_VALID     = 1'b0; // Kết thúc chu kỳ địa chỉ
        
        wait(CPU_READY); // Đợi Slave trả dữ liệu về RDATA
        // Ngay sau dòng này, CPU_RDATA sẽ chứa giá trị đúng
    end
    endtask
    

    // Chỉ in khi Slave SRAM đang được chọn (HSEL từ decoder)
    always @(posedge HCLK) begin
        // Sử dụng đường dẫn phân cấp: dut.u_slave_sram.<tên_biến>
        if (dut.hsel_sram && dut.h_ready) begin
            if (dut.u_slave_sram.wait_state) 
                $display("[SLAVE INFO] Entering Wait State at time %t", $time);
            if (dut.u_slave_sram.error_flag) 
                $display("[SLAVE ERROR] Violation detected at ADDR: %h", dut.h_addr);
        end
    end

    // Stimulus
    initial begin
        // Reset
        HRESETn = 0;
        CPU_ADDR = 0; CPU_WDATA = 0; CPU_WRITE_REQ = 0; CPU_VALID = 0;
        #25;
        HRESETn = 1;
        #20;

        // Test Case 1: Ghi vào SRAM (Địa chỉ thuộc vùng SRAM, ví dụ 0x0004_0000)
        // Lưu ý: Đảm bảo ahb_decoder của bạn map vùng này cho SRAM
        $display("--- Start Write Transaction ---");
        ahb_write(32'h0004_0000, 32'hDEADBEEF);
        
        #50;

        // Test Case 2: Đọc lại từ SRAM
        $display("--- Start Read Transaction ---");
        ahb_read(32'h0004_0000);
        
        #100;
        $display("Read Data: %h", CPU_RDATA);
        
        $finish;
    end

    // Monitor for Waveform
    initial begin
        $dumpfile("ahb_sram_timing.vcd");
        $dumpvars(0, tb_sram_ahb);
    end

    // --- DEBUG MONITOR ---
    initial begin
        $display("\n[TIME] | ADDR     | TRANS | WRITE | WDATA    | RDATA    | READY | HSEL | RESP");
        $display("--------------------------------------------------------------------------------");
        forever begin
            @(posedge HCLK);
            // In trạng thái ngay sau cạnh lên clock để xem giá trị đã ổn định chưa
            #1; 
            if (dut.h_trans != 2'b00 || dut.h_ready == 1'b0) begin
                $display("[%5t] | %h |   %b   |   %b   | %h | %h |   %b   |  %b   |  %b", 
                         $time, dut.h_addr, dut.h_trans, dut.h_write, 
                         dut.h_wdata, dut.CPU_RDATA, dut.h_ready, 
                         dut.hsel_sram, dut.h_resp);
            end
        end
    end

    // --- TIMEOUT PROTECTION ---
    // Ngăn chặn việc mô phỏng chạy vô tận nếu HREADY bị kẹt ở 0
    initial begin
        #5000; 
        $display("\n[TIMEOUT] Simulation stopped after 5000ns. Check HREADY signal!");
        $finish;
    end

endmodule
`timescale 1ns/1ps

module tb_ahb_system();

    reg         HCLK;
    reg         HRESETn;
    reg [31:0]  cpu_wdata, cpu_addr;
    reg         cpu_write_req, cpu_valid;
    reg [2:0]   cpu_burst, cpu_size;
    wire [31:0] cpu_rdata;
    wire        cpu_ready;
    wire [31:0] h_addr, h_wdata;
    wire [1:0]  h_trans;
    wire        h_write;
    wire        h_ready;

    assign h_addr  = dut.h_addr;
    assign h_wdata = dut.h_wdata;
    assign h_trans = dut.h_trans;
    assign h_write = dut.h_write;
    assign h_ready = dut.h_ready;

    // Clock generation
    initial HCLK = 0;
    always #5 HCLK = ~HCLK;

    // Instantiate Top
    ahb_top dut (
        .HCLK           (HCLK),
        .HRESETn        (HRESETn),
        .CPU_WDATA      (cpu_wdata),
        .CPU_ADDR       (cpu_addr),
        .CPU_WRITE_REQ  (cpu_write_req),
        .CPU_VALID      (cpu_valid),
        .CPU_BURST_REQ  (cpu_burst),
        .CPU_SIZE_REQ   (cpu_size),
        .CPU_RDATA      (cpu_rdata),
        .CPU_READY      (cpu_ready)
    );

    task ahb_write(input [31:0] addr, input [31:0] data);
begin
    @(posedge HCLK);
    while(!cpu_ready) @(posedge HCLK);

    cpu_addr      = addr;
    cpu_wdata     = data;
    cpu_write_req = 1;
    cpu_valid     = 1;

    @(posedge HCLK);
    while(!cpu_ready) @(posedge HCLK); 
    // Không hạ cpu_valid ngay, hoặc đảm bảo Manager vẫn giữ HWDATA
    cpu_valid     = 0; 
    
    repeat(2) @(posedge HCLK); // Chờ thêm để Slave kịp ghi
end
endtask

    // always @(posedge HCLK) begin
    //     $display("[%0t] STATE=?, HTRANS=%b HADDR=%h",
    //         $time, h_trans, h_addr);
    // end

    // always @(posedge HCLK) begin
    //     if (h_ready && h_write && h_trans[1]) begin
    //         $display("[%0t] MEM WRITE: addr=%h data=%h",
    //             $time,
    //             h_addr,
    //             dut.u_slave.memory[h_addr[11:2]]
    //         );
    //     end
    // end

    task ahb_read(input [31:0] addr);
    begin
        @(posedge HCLK);
        while(!cpu_ready) @(posedge HCLK);

        cpu_addr      = addr;
        cpu_write_req = 0;
        cpu_valid     = 1;
        cpu_burst     = 3'b000;
        cpu_size      = 3'b010;

        @(posedge HCLK);
        while(!cpu_ready) @(posedge HCLK); 

        cpu_valid     = 0;

        wait(!cpu_ready);
        $display("\n[%0t] ===== READ addr=%h data=%h =====\n",
            $time, addr, cpu_rdata);
    end
    endtask

    task ahb_write_incr4(
        input [31:0] start_addr, 
        input [31:0] d0, input [31:0] d1, input [31:0] d2, input [31:0] d3
    );
        reg [31:0] d_list [0:3];
        integer i;
    begin
        d_list[0]=d0; d_list[1]=d1; d_list[2]=d2; d_list[3]=d3;

        @(posedge HCLK);
        while(!cpu_ready) @(posedge HCLK);

        cpu_addr      <= start_addr;
        cpu_wdata     <= d_list[0]; 
        cpu_write_req <= 1;
        cpu_valid     <= 1;
        cpu_burst     <= 3'b011; 

        for (i = 1; i <= 3; i = i + 1) begin
            @(posedge HCLK);
            while(!cpu_ready) @(posedge HCLK);
            cpu_wdata <= d_list[i];  
        end

        @(posedge HCLK);
        while(!cpu_ready) @(posedge HCLK);
        cpu_valid <= 0;
        
        @(posedge HCLK);
        while(!cpu_ready) @(posedge HCLK);
    end
    endtask

    task ahb_write_incr8(
        input [31:0] start_addr, 
        input [31:0] d0, input [31:0] d1, input [31:0] d2, input [31:0] d3,
        input [31:0] d4, input [31:0] d5, input [31:0] d6, input [31:0] d7
    );
        reg [31:0] data_queue [0:7];
        integer i;
    begin
        data_queue[0] = d0; data_queue[1] = d1;
        data_queue[2] = d2; data_queue[3] = d3;
        data_queue[4] = d4; data_queue[5] = d5;
        data_queue[6] = d6; data_queue[7] = d7;

        @(posedge HCLK);
        while(!cpu_ready) @(posedge HCLK);

        cpu_addr      <= start_addr;
        cpu_wdata     <= data_queue[0]; 
        cpu_write_req <= 1;
        cpu_valid     <= 1;
        cpu_burst     <= 3'b101; 
        cpu_size      <= 3'b010; // Word (32-bit)

        for (i = 1; i <= 7; i = i + 1) begin
            @(posedge HCLK);
            while(!cpu_ready) @(posedge HCLK);
            
            cpu_wdata <= data_queue[i]; 
        end

        @(posedge HCLK);
        while(!cpu_ready) @(posedge HCLK);
        cpu_valid <= 0; 

        @(posedge HCLK);
        while(!cpu_ready) @(posedge HCLK);
        
        $display("[%0t] INCR8 WRITE DONE", $time);
    end
    endtask

    // always @(posedge HCLK) begin
    //     $display("[%0t] AHB -> HADDR=%h HWDATA=%h HTRANS=%b HWRITE=%b HREADY=%b",
    //         $time, h_addr, h_wdata, h_trans, h_write, h_ready
    //     );
    // end

    // always @(posedge HCLK) begin
    //     if(cpu_valid && cpu_write_req) begin
    //         $display("[%0t] >>> WRITE REQUEST addr=%h data=%h",
    //             $time, cpu_addr, cpu_wdata);
    //     end

    //     if(cpu_valid && !cpu_write_req) begin
    //         $display("[%0t] >>> READ REQUEST addr=%h",
    //             $time, cpu_addr);
    //     end
    // end

    task ahb_write_incr4_with_busy(
        input [31:0] start_addr, 
        input [31:0] d0, input [31:0] d1, input [31:0] d2, input [31:0] d3
    );
    begin
        @(posedge HCLK);
        while(!cpu_ready) @(posedge HCLK);

        cpu_addr <= start_addr; cpu_wdata <= d0;
        cpu_write_req <= 1; cpu_valid <= 1; cpu_burst <= 3'b011;

        @(posedge HCLK); while(!cpu_ready) @(posedge HCLK);
        cpu_wdata <= d1;

        @(posedge HCLK); while(!cpu_ready) @(posedge HCLK);
        cpu_valid <= 0; 
        $display("[%0t] CPU BUSY inserted...", $time);
        
        repeat(2) @(posedge HCLK); 

        cpu_valid <= 1;
        cpu_wdata <= d2;
        $display("[%0t] CPU READY again, continuing SEQ...", $time);

        // Nhịp 4: SEQ
        @(posedge HCLK); while(!cpu_ready) @(posedge HCLK);
        cpu_wdata <= d3;

        @(posedge HCLK); while(!cpu_ready) @(posedge HCLK);
        cpu_valid <= 0;
        
        @(posedge HCLK); while(!cpu_ready) @(posedge HCLK);
        $display("[%0t] INCR4 WITH BUSY DONE", $time);
    end
    endtask

    task ahb_write_wrap4(input [31:0] start_addr);
        reg [31:0] random_data;
    begin
        @(posedge HCLK);
        while(!cpu_ready) @(posedge HCLK);

        cpu_addr <= start_addr; 
        cpu_write_req <= 1; cpu_valid <= 1;
        cpu_burst <= 3'b010; 
        cpu_size  <= 3'b010;

        repeat(4) begin
            random_data = $random;
            cpu_wdata <= random_data; 
            @(posedge HCLK);
            while(!cpu_ready) @(posedge HCLK);
        end
        
        cpu_valid <= 0;
        @(posedge HCLK);
        while(!cpu_ready) @(posedge HCLK);
    end
    endtask

    task ahb_incr_busy_terminate_test();
    begin
        reg [31:0] next_addr;
        reg [31:0] next_data;
        reg [2:0]  next_burst;

        @(posedge HCLK);
        while(!cpu_ready) @(posedge HCLK);

        cpu_addr      <= 32'h0000_0060;
        cpu_wdata     <= 32'hA1;
        cpu_write_req <= 1;
        cpu_valid     <= 1;
        cpu_burst     <= 3'b001; 

        @(posedge HCLK); while(!cpu_ready) @(posedge HCLK);
        cpu_wdata <= 32'hA2;

        @(posedge HCLK); while(!cpu_ready) @(posedge HCLK);
        cpu_valid <= 0; // BUSY
        $display("[%0t] >>> INSERT BUSY", $time);

        force dut.u_slave.HREADYOUT = 0;

        repeat(2) @(posedge HCLK);

        next_addr  = 32'h0000_0010;
        next_data  = 32'hB1;
        next_burst = 3'b011;

        $display("[%0t] >>> PREPARE NONSEQ (new burst @0x10)", $time);

        repeat(2) @(posedge HCLK);

        release dut.u_slave.HREADYOUT;
        $display("[%0t] >>> RELEASE HREADY", $time);

        @(posedge HCLK); 
        while(!cpu_ready) @(posedge HCLK);

        cpu_valid <= 1;
        cpu_addr  <= next_addr;
        cpu_wdata <= next_data;
        cpu_burst <= next_burst;

        @(posedge HCLK); while(!cpu_ready) @(posedge HCLK);
        cpu_wdata <= 32'hB2;

        @(posedge HCLK); while(!cpu_ready) @(posedge HCLK);
        cpu_wdata <= 32'hB3;

        @(posedge HCLK); while(!cpu_ready) @(posedge HCLK);
        cpu_wdata <= 32'hB4;

        @(posedge HCLK); while(!cpu_ready) @(posedge HCLK);
        cpu_valid <= 0;

        @(posedge HCLK); while(!cpu_ready) @(posedge HCLK);

        $display("[%0t] >>> INCR BUSY TERMINATE TEST DONE", $time);
    end
    endtask

    task ahb_error_recovery_test();
        begin
            $display("\n--- CASE 4: ERROR RESPONSE RECOVERY TEST ---");
            
            @(posedge HCLK);
            while(!cpu_ready) @(posedge HCLK);

            cpu_addr      <= 32'h0000_3000;
            cpu_wdata     <= 32'h1111_1111;
            cpu_write_req <= 1;
            cpu_valid     <= 1;
            cpu_burst     <= 3'b011; // INCR4
            
            @(posedge HCLK);
            while(!cpu_ready) @(posedge HCLK);
            cpu_wdata <= 32'h2222_2222;

            force dut.u_slave.HRESP     = 1'b1;
            force dut.u_slave.HREADYOUT = 1'b0;
            $display("[%0t] >>> SLAVE INSERTS ERROR (Cycle 1: HREADY=0)", $time);
            
            cpu_addr <= 32'h0000_4000; // Địa chỉ mới CPU muốn nhảy tới sau lỗi
            cpu_valid <= 0;            // CPU muốn dừng sau lỗi

            @(posedge HCLK);
            
            force dut.u_slave.HREADYOUT = 1'b1;
            $display("[%0t] >>> SLAVE INSERTS ERROR (Cycle 2: HREADY=1)", $time);
            
            @(posedge HCLK);
            release dut.u_slave.HRESP;
            release dut.u_slave.HREADYOUT;

            if (dut.u_manager.HTRANS == 2'b00) 
                $display("[%0t] SUCCESS: Manager returned to IDLE after ERROR", $time);
            else
                $display("[%0t] ERROR: Manager failed to return to IDLE", $time);

            repeat(3) @(posedge HCLK);
            $display("[%0t] >>> ERROR RECOVERY TEST DONE", $time);
        end
    endtask

    task ahb_error_flag_test();
        begin
            $display("\n--- BEGIN ERROR FLAG DETECTION TEST ---");
            
            // Đợi hệ thống sẵn sàng
            @(posedge HCLK);
            while(!cpu_ready) @(posedge HCLK);

            // --- TEST CASE A: Misalignment (error_2) ---
            // Thử ghi 32-bit (WORD) vào địa chỉ không chia hết cho 4 (0x11)
            $display("[%0t] Testing Error 2: Misalignment (WORD at 0x0000_0011)", $time);
            cpu_addr      <= 32'h0000_0011; 
            cpu_size      <= 3'b010; // WORD
            cpu_write_req <= 1;
            cpu_valid     <= 1;
            
            @(posedge HCLK);
            #1; // Đợi logic tổ hợp cập nhật
            if (dut.u_slave.error_2) 
                $display("[%0t] SUCCESS: error_2 (Misalignment) detected!", $time);
            else 
                $display("[%0t] FAILED: error_2 not detected!", $time);
            
            // Đợi 2 chu kỳ để hoàn thành chu trình phản hồi lỗi của AHB (Two-cycle response)
            repeat(2) @(posedge HCLK);
            cpu_valid <= 0;

            // --- TEST CASE B: Protected Region (error_3) ---
            // Truy cập địa chỉ < 0x40 với HPROT[1] = 0 (User access thay vì Privileged)
            $display("[%0t] Testing Error 3: Protected Access (Addr < 0x40, User Mode)", $time);
            cpu_addr      <= 32'h0000_0020;
            cpu_size      <= 3'b010;
            // Giả sử bạn có biến cpu_prot nối với HPROT
            // Nếu không có, bạn cần force: force dut.u_slave.HPROT = 4'b0000;
            cpu_valid     <= 1;

            @(posedge HCLK);
            #1;
            if (dut.u_slave.error_3)
                $display("[%0t] SUCCESS: error_3 (Protection) detected!", $time);
            else
                $display("[%0t] FAILED: error_3 not detected!", $time);

            repeat(2) @(posedge HCLK);
            cpu_valid <= 0;

            // --- TEST CASE C: Unsupported Size (error_4) ---
            // Thử truyền HSIZE = 3'b011 (Double Word) trong khi Slave chỉ hỗ trợ tối đa WORD
            $display("[%0t] Testing Error 4: Unsupported HSIZE (Double Word)", $time);
            cpu_addr      <= 32'h0000_0100;
            cpu_size      <= 3'b011; // DOUBLEWORD
            cpu_valid     <= 1;

            @(posedge HCLK);
            #1;
            if (dut.u_slave.error_4)
                $display("[%0t] SUCCESS: error_4 (Size) detected!", $time);
            else
                $display("[%0t] FAILED: error_4 not detected!", $time);

            repeat(2) @(posedge HCLK);
            cpu_valid <= 0;

            // Kết thúc
            $display("--- ERROR FLAG DETECTION TEST DONE ---\n");
        end
    endtask

    initial begin
        HRESETn = 0; 
        cpu_valid = 0; 
        cpu_write_req = 0;
        cpu_size = 3'b010; 
        cpu_burst = 3'b000; 
        #25 HRESETn = 1;
        #10;

        $display("\n--- CASE 1: BASIC SINGLE WRITE/READ ---");
        ahb_write(32'h0000_0010, 32'hAAAA_BBBB);
        ahb_read(32'h0000_0010);

        $display("\n--- CASE 2: INCR4 BURST (NORMAL) ---");
        ahb_write_incr4(32'h0000_0000, 32'h1, 32'h2, 32'h3, 32'h4);
        ahb_read(32'h0000_0000);
        ahb_read(32'h0000_0004);
        ahb_read(32'h0000_0008);
        ahb_read(32'h0000_000C);

        $display("\n--- CASE 3: WRAP4 ADDRESSING (Boundary Test) ---");
        ahb_write_wrap4(32'h0000_001C);
        ahb_read(32'h0000_001C);
        ahb_read(32'h0000_0010);
        ahb_read(32'h0000_0014);
        ahb_read(32'h0000_0018);

        $display("\n--- CASE 4: CPU BUSY MID-BURST (HTRANS BUSY Test) ---");
        ahb_write_incr4_with_busy(32'h0000_3000, 32'hD1, 32'hD2, 32'hD3, 32'hD4);
        ahb_read(32'h0000_0000);
        ahb_read(32'h0000_0004);
        ahb_read(32'h0000_0008);
        ahb_read(32'h0000_000C);

        $display("\n--- CASE 5: BACK-TO-BACK TRANSFERS ---");
        ahb_write(32'h0000_0040, 32'hCAFE_CAFE);
        ahb_read(32'h0000_0040);

        $display("\n--- CASE 6: INCR BUSY TERMINATE (SPEC TEST) ---");
        ahb_incr_busy_terminate_test();

        // verify data
        ahb_read(32'h0000_0010);
        ahb_read(32'h0000_0014);
        ahb_read(32'h0000_0018);
        ahb_read(32'h0000_001C);

        ahb_error_recovery_test();
        ahb_error_flag_test();

        #500;
        $display("\nALL TEST CASES FINISHED");
        $finish;
    end

endmodule
class packet;
    typedef enum {READ, WRITE} AHB_type;

    bit [31:0]  data;
    bit [31:0]  addr;

    AHB_type trans_type;

    function new();
    endfunction

endclass
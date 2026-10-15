module sh1106_spi_full (
    input  wire       char_valid,
    input  wire [7:0] char_data,
    input  wire clk,
    input  wire alarm_o,   
    input  wire button_pressed1,
    input  wire [3:0] pulse_cnt,
    input  wire data_cnt,
    input  wire [2:0]freq_group,
    input  wire [3:0]gain,
    input  wire gain_select,
    output reg  sclk,
    output reg  mosi,
    output reg  cs,
    output reg  dc,
    output reg  rst
);

    // =========================================================
    // PARAMETRIT
    // =========================================================
    parameter SPI_DIV = 4;
    parameter STARTUP_WAIT = 24_000;
    localparam CHAR_W = 5;
    localparam CHAR_H = 8;
    localparam SPACE  = 1;

    localparam X_START = 40; // keskitys
    localparam X_START_DB = 70;
    localparam X_START_DB_W = 90;
    localparam PAGE_TEXT = 4;
    localparam PAGE_TEXT_W = 2;
    

    integer char_index;
    integer char_col;

    // =========================================================
    // STATE
    // =========================================================
    parameter
        S_POWER      = 4'd0,
        S_LOAD_INIT  = 4'd1,
        S_SEND       = 4'd2,
        S_NEXT       = 4'd3,
        S_SET_PAGE   = 4'd4,
        S_SET_COL_L  = 4'd5,
        S_SET_COL_H  = 4'd6,
        S_SEND_DATA  = 4'd7;

    reg [3:0] state = S_POWER;

    // =========================================================
    // REKISTERIT
    // =========================================================
    reg [31:0] startup_cnt = 0;
    reg [15:0] spi_cnt = 0;
    reg [7:0]  tx_byte;
    reg [2:0]  bit_cnt;

    reg [2:0]  page = 0;   // 0..7
    reg [6:0]  col  = 0;   // 0..127

    reg [7:0]  cmd_index;

    reg [2:0] state_bit;
    reg [2:0] state_bit2;
    reg [2:0] state_bit3;

    reg [7:0] text_buf [0:19];
    reg [7:0] text_bufdb [0:3];
    reg [7:0] text_bufdbw [0:19];
    reg [7:0] text_buf71 [0:31];
    reg [5:0] wr_ptr = 0;
    reg [5:0] text_len = 0;
    reg [5:0] text_len2 = 0;
    reg [7:0] text_len145 = 0;
    reg [7:0] text_len71 = 0;
    reg alarm_ptr = 0;
    reg [2:0] pulse_cnt_reg;
    reg [31:0] alarm_cnt = 0;
    reg [3:0] gain_r = 0;

    //assign pulse_cnt_reg = pulse_cnt;
    

    


    // =========================================================
    // INIT KOMENNOT
    // =========================================================
    localparam INIT_COUNT = 14;

    reg [8*INIT_COUNT-1:0] init_cmds = {
        8'hAE,        // display OFF
        8'h81, 8'h7F, // contrast
        8'hA6,        // normal display
        8'hA1,        // segment remap
        8'hC8,        // COM scan direction
        8'hA8, 8'h3F, // mux ratio
        8'hD3, 8'h00, // display offset
        8'hD5, 8'h80, // clock
        8'hD9, 8'h22, // precharge
        8'hDB, 8'h20, // VCOM
        8'hA4,        // resume RAM
        8'hAF         // display ON
    };
    
    reg [3:0] freq_len [0:3];

    initial begin
        freq_len[0] = 7; // 145.750
        freq_len[1] = 7; // 071.250
        freq_len[2] = 7; // 433.920
        freq_len[3] = 7; // 433.920
    end

    reg [7:0] text_buffreq [0:7];
    reg [7:0] freq_table [0:489];

    initial begin

        // -------- Oulu 2m --------
        freq_table[0] = "1"; freq_table[1] = "4"; freq_table[2] = "5"; freq_table[3] = ".";
        freq_table[4] = "7"; freq_table[5] = "5"; freq_table[6] = "0";

        // -------- Ylivieska 2m --------
        freq_table[7] = "1"; freq_table[8] = "4"; freq_table[9] = "5"; freq_table[10] = ".";
        freq_table[11] = "6"; freq_table[12] = "7"; freq_table[13] = "5";

        // -------- Rovaniemi 2m --------
        freq_table[14] = "1"; freq_table[15] = "4"; freq_table[16] = "5"; freq_table[17] = ".";
        freq_table[18] = "7"; freq_table[19] = "0"; freq_table[20] = "0";

        // -------- Viitasaari 2m --------
        freq_table[21] = "1"; freq_table[22] = "4"; freq_table[23] = "5"; freq_table[24] = ".";
        freq_table[25] = "7"; freq_table[26] = "7"; freq_table[27] = "5";

        // -------- RhA Ch16 kutsu--------
        freq_table[28] = " "; freq_table[29] = "7"; freq_table[30] = "1"; freq_table[31] = ".";
        freq_table[32] = "1"; freq_table[33] = "0"; freq_table[34] = "0";

        // -------- RhA Ch1 Tiepalvelu --------
        freq_table[35] = " "; freq_table[36] = "6"; freq_table[37] = "8"; freq_table[38] = ".";
        freq_table[39] = "1"; freq_table[40] = "0"; freq_table[41] = "0";

        // -------- RhA Ch19 Har/Työ --------
        freq_table[42] = " "; freq_table[43] = "7"; freq_table[44] = "1"; freq_table[45] = ".";
        freq_table[46] = "1"; freq_table[47] = "7"; freq_table[48] = "5";

        // -------- RhA Ch3 Vapepa --------
        freq_table[49] = " "; freq_table[50] = "6"; freq_table[51] = "8"; freq_table[52] = ".";
        freq_table[53] = "4"; freq_table[54] = "2"; freq_table[55] = "5";

        // -------- La Ch7 kutsu --------
        freq_table[56] = " "; freq_table[57] = "2"; freq_table[58] = "7"; freq_table[59] = ".";
        freq_table[60] = "0"; freq_table[61] = "3"; freq_table[62] = "5";

        // -------- La Ch19 rekat am --------
        freq_table[63] = " "; freq_table[64] = "2"; freq_table[65] = "7"; freq_table[66] = ".";
        freq_table[67] = "1"; freq_table[68] = "8"; freq_table[69] = "5";

        // -------- La Ch6 --------
        freq_table[70] = " "; freq_table[71] = "2"; freq_table[72] = "7"; freq_table[73] = ".";
        freq_table[74] = "0"; freq_table[75] = "2"; freq_table[76] = "5";

        // -------- La Ch24 PakettiRadio --------
        freq_table[77] = " "; freq_table[78] = "2"; freq_table[79] = "7"; freq_table[80] = ".";
        freq_table[81] = "2"; freq_table[82] = "3"; freq_table[83] = "5";

        // -------- Ilma Sect H --------
        freq_table[84] = "1"; freq_table[85] = "2"; freq_table[86] = "4"; freq_table[87] = ".";
        freq_table[88] = "2"; freq_table[89] = "0"; freq_table[90] = "0";

        // -------- Ilma Oulun lentoasema --------
        freq_table[91] = "1"; freq_table[92] = "2"; freq_table[93] = "4"; freq_table[94] = ".";
        freq_table[95] = "4"; freq_table[96] = "0"; freq_table[97] = "0";

        // -------- Ilma Helsinki --------
        freq_table[98] = "1"; freq_table[99] = "3"; freq_table[100] = "2"; freq_table[101] = ".";
        freq_table[102] = "3"; freq_table[103] = "2"; freq_table[104] = "5";

        // -------- Ilmailu ruotsi --------
        freq_table[105] = "1"; freq_table[106] = "3"; freq_table[107] = "2"; freq_table[108] = ".";
        freq_table[109] = "4"; freq_table[110] = "8"; freq_table[111] = "0";

        // -------- Meri Ch12 --------
        freq_table[112] = "1"; freq_table[113] = "5"; freq_table[114] = "6"; freq_table[115] = ".";
        freq_table[116] = "6"; freq_table[117] = "0"; freq_table[118] = "0";

        // -------- Meri Ch14 Meripelastusviranomainen --------
        freq_table[119] = "1"; freq_table[120] = "5"; freq_table[121] = "6"; freq_table[122] = ".";
        freq_table[123] = "7"; freq_table[124] = "0"; freq_table[125] = "0";

        // -------- Meri Ch15 kauppa-alusten sisäinen liikenne --------
        freq_table[126] = "1"; freq_table[127] = "5"; freq_table[128] = "6"; freq_table[129] = ".";
        freq_table[130] = "7"; freq_table[131] = "5"; freq_table[132] = "0";

        // -------- Meri Ch13 Luotsi --------
        freq_table[133] = "1"; freq_table[134] = "5"; freq_table[135] = "6"; freq_table[136] = ".";
        freq_table[137] = "6"; freq_table[138] = "5"; freq_table[139] = "0";

        // -------- GROUP 20 --------
        freq_table[140] = " "; freq_table[141] = " "; freq_table[142] = " "; freq_table[143] = " ";
        freq_table[144] = " "; freq_table[145] = " "; freq_table[146] = " ";

        // ... jatkuu samalla kaavalla ...

        // -------- GROUP 69 --------
        freq_table[483] = " "; freq_table[484] = " "; freq_table[485] = " "; freq_table[486] = " ";
        freq_table[487] = " "; freq_table[488] = " "; freq_table[489] = " ";

    end

    initial begin
        text_buf[0] = "2";
        text_buf[1] = "M";
        text_buf[2] = " ";
        text_buf[3] = " ";

        text_buf[4] = "R";
        text_buf[5] = "H";
        text_buf[6] = "A";
        text_buf[7] = " ";

        text_buf[8] = "L";
        text_buf[9] = "A";
        text_buf[10] = " ";
        text_buf[11] = " ";

        text_buf[12] = "I";
        text_buf[13] = "L";
        text_buf[14] = "M";
        text_buf[15] = "A";


        text_buf[16] = "M";
        text_buf[17] = "E";
        text_buf[18] = "R";
        text_buf[19] = "I";


    end
   
    initial begin
        text_bufdb[0] = "d";
        text_bufdb[1] = "B";
        text_bufdb[2] = " ";
        text_bufdb[3] = " ";
    end

    initial begin
        text_bufdbw[2] = "0";
        text_bufdbw[3] = " ";
        text_bufdbw[4] = "5";
        text_bufdbw[5] = " ";

        text_bufdbw[6] = "1";
        text_bufdbw[7] = "0";
        text_bufdbw[8] = "1";
        text_bufdbw[9] = "5";

        text_bufdbw[10] = "2";
        text_bufdbw[11] = "0";
        text_bufdbw[12] = "2";
        text_bufdbw[13] = "5";

        text_bufdbw[14] = "3";
        text_bufdbw[15] = "0";
        text_bufdbw[16] = "3";
        text_bufdbw[17] = "5";
    
        text_bufdbw[18] = "4";
        text_bufdbw[19] = "0";

    end

    function [7:0] font5x8;
        input [7:0] ch;     // ASCII-koodi
        input [2:0] col;    // 0..4, sarake kirjaimen sisällä
        begin
            case (ch)
    
            "A": case (col)
                0: font5x8 = 8'b1111110;
                1: font5x8 = 8'b0001001;
                2: font5x8 = 8'b0001001;
                3: font5x8 = 8'b0001001;
                4: font5x8 = 8'b1111110;
                default: font5x8 = 8'b00000000;
            endcase
    
            "B": case (col)
                0: font5x8 = 8'b1111111;
                1: font5x8 = 8'b1001001;
                2: font5x8 = 8'b1001001;
                3: font5x8 = 8'b1001001;
                4: font5x8 = 8'b0110110;
                default: font5x8 = 8'b00000000;
            endcase
        
            "d": case (col)
                0: font5x8 = 8'b0110000;
                1: font5x8 = 8'b1001000;
                2: font5x8 = 8'b1001000;
                3: font5x8 = 8'b1001000;
                4: font5x8 = 8'b1111111;
                default: font5x8 = 8'b00000000;
            endcase
            
            
            "H": case (col)
                0: font5x8 = 8'b1111111;
                1: font5x8 = 8'b0001000;
                2: font5x8 = 8'b0001000;
                3: font5x8 = 8'b0001000;
                4: font5x8 = 8'b1111111;
                default: font5x8 = 8'b00000000;
            endcase
    
            "I": case (col)
                0: font5x8 = 8'b0000000;
                1: font5x8 = 8'b1000001;
                2: font5x8 = 8'b1111111;
                3: font5x8 = 8'b1000001;
                4: font5x8 = 8'b0000000;
                default: font5x8 = 8'b00000000;
            endcase
            
            "M": case (col)
                0: font5x8 = 8'b1111111;
                1: font5x8 = 8'b0000010;
                2: font5x8 = 8'b0000100;
                3: font5x8 = 8'b0000010;
                4: font5x8 = 8'b1111111;
                default: font5x8 = 8'b00000000;
            endcase

            "E": case (col)
                0: font5x8 = 8'b1111111;
                1: font5x8 = 8'b1001001;
                2: font5x8 = 8'b1001001;
                3: font5x8 = 8'b1001001;
                4: font5x8 = 8'b1000001;
                default: font5x8 = 8'b00000000;
            endcase

            "L": case (col)
                0: font5x8 = 8'b1111111;
                1: font5x8 = 8'b1000000;
                2: font5x8 = 8'b1000000;
                3: font5x8 = 8'b1000000;
                4: font5x8 = 8'b1000000;
                default: font5x8 = 8'b00000000;
            endcase

            "O": case (col)
                0: font5x8 = 8'b0111110;
                1: font5x8 = 8'b1000001;
                2: font5x8 = 8'b1000001;
                3: font5x8 = 8'b1000001;
                4: font5x8 = 8'b0111110;
                default: font5x8 = 8'b00000000;
            endcase

            "R": case (col)
                0: font5x8 = 8'b1111111;
                1: font5x8 = 8'b0001001;
                2: font5x8 = 8'b0010101;
                3: font5x8 = 8'b1100111;
                4: font5x8 = 8'b0000000;
                default: font5x8 = 8'b00000000;
            endcase

            "T": case (col)
                0: font5x8 = 8'b0000001;
                1: font5x8 = 8'b0000001;
                2: font5x8 = 8'b1111111;
                3: font5x8 = 8'b0000001;
                4: font5x8 = 8'b0000001;
                default: font5x8 = 8'b00000000;
            endcase
            
            "1": case (col)
                0: font5x8 = 8'b0000000;
                1: font5x8 = 8'b1000001;
                2: font5x8 = 8'b1111111;
                3: font5x8 = 8'b1000000;
                4: font5x8 = 8'b0000000;
                default: font5x8 = 8'b00000000;
            endcase

            "4": case (col)
                0: font5x8 = 8'b0001100;
                1: font5x8 = 8'b0001010;
                2: font5x8 = 8'b1111111;
                3: font5x8 = 8'b0001000;
                4: font5x8 = 8'b0000000;
                default: font5x8 = 8'b00000000;
            endcase
    
            "0": case (col)
                0: font5x8 = 8'b0000000;
                1: font5x8 = 8'b0111110;
                2: font5x8 = 8'b1000001;
                3: font5x8 = 8'b0111110;
                4: font5x8 = 8'b0000000;
                default: font5x8 = 8'b00000000;
            endcase
            
            "3": case (col)
                0: font5x8 = 8'b000000;
                1: font5x8 = 8'b0100010;
                2: font5x8 = 8'b1001001;
                3: font5x8 = 8'b0110110;
                4: font5x8 = 8'b0000000;
                default: font5x8 = 8'b00000000;
            endcase

            ".": case (col)
                0: font5x8 = 8'b0000000;
                1: font5x8 = 8'b0000000;
                2: font5x8 = 8'b1000000;
                3: font5x8 = 8'b0000000;
                4: font5x8 = 8'b0000000;
                default: font5x8 = 8'b00000000;
            endcase

            "7": case (col)
                0: font5x8 = 8'b0000001;
                1: font5x8 = 8'b0001001;
                2: font5x8 = 8'b1111111;
                3: font5x8 = 8'b0001000;
                4: font5x8 = 8'b0000000;
                default: font5x8 = 8'b00000000;
            endcase

            "5": case (col)
                0: font5x8 = 8'b0000000;
                1: font5x8 = 8'b1000111;
                2: font5x8 = 8'b1000101;
                3: font5x8 = 8'b0111001;
                4: font5x8 = 8'b0000000;
                default: font5x8 = 8'b00000000;
            endcase
            
            "2": case (col)
                0: font5x8 = 8'b000000;
                1: font5x8 = 8'b1100001;
                2: font5x8 = 8'b1001001;
                3: font5x8 = 8'b1000110;
                4: font5x8 = 8'b0000000;
                default: font5x8 = 8'b00000000;
            endcase

            "6": case (col)
                0: font5x8 = 8'b0000000;
                1: font5x8 = 8'b0111110;
                2: font5x8 = 8'b1001001;
                3: font5x8 = 8'b0110001;
                4: font5x8 = 8'b0000000;
                default: font5x8 = 8'b00000000;
            endcase
        
            "8": case (col)
                0: font5x8 = 8'b0000000;
                1: font5x8 = 8'b0110110;
                2: font5x8 = 8'b1001001;
                3: font5x8 = 8'b0110110;
                4: font5x8 = 8'b0000000;
                default: font5x8 = 8'b00000000;
            endcase
    
            "9": case (col)
                0: font5x8 = 8'b0000000;
                1: font5x8 = 8'b0100110;
                2: font5x8 = 8'b1001001;
                3: font5x8 = 8'b0111110;
                4: font5x8 = 8'b0000000;
                default: font5x8 = 8'b00000000;
            endcase

            "->": case (col)
                0: font5x8 = 8'b0000100;
                1: font5x8 = 8'b0000010;
                2: font5x8 = 8'b1111111;
                3: font5x8 = 8'b0000010;
                4: font5x8 = 8'b0000100;
                default: font5x8 = 8'b00000000;
            endcase

    
            " ": font5x8 = 8'b00000000; // tyhjä merkki

            default: font5x8 = 8'b00000000; // kaikki muut
            endcase
        end
    endfunction

    reg [31:0] gain_cnt = 0;
    reg gain_cnt_db = 0;

    /*always @(posedge clk) begin
        if (char_valid) begin
            if (char_data == 8'h0A) begin
                wr_ptr <= 0;
            end else begin
                text_buf[wr_ptr] <= char_data;
                wr_ptr <= wr_ptr + 1;
            end
        end
    end*/


    // =========================================================
    // FSM
    // =========================================================
    always @(posedge clk) begin
        
        if(gain_select == 1)
            gain_cnt <= gain_cnt + 1;
        else begin      
            gain_cnt <= 0;
            gain_cnt_db <= 0;
        end
        if(gain_cnt == 20000000)begin
            gain_cnt <= 0;
            gain_cnt_db <= ~gain_cnt_db;
        end
            

        case (state)

        // -----------------------------------------------------
        // POWER + RESET
        // -----------------------------------------------------
        S_POWER: begin
            cs   <= 1;
            sclk <= 0;
            dc   <= 0;
            rst  <= 0;

            startup_cnt <= startup_cnt + 1;

            if (startup_cnt > STARTUP_WAIT) begin
                rst <= 1;
                cmd_index <= INIT_COUNT * 8;
                state <= S_LOAD_INIT;
            end
        end

        // -----------------------------------------------------
        // LOAD INIT COMMAND
        // -----------------------------------------------------
        S_LOAD_INIT: begin
            cs <= 0;
            dc <= 0;
            tx_byte <= init_cmds[cmd_index-1 -: 8];
            cmd_index <= cmd_index - 8;
            bit_cnt <= 3'd7;
            spi_cnt <= 0;
            state <= S_SEND;
        end

        // -----------------------------------------------------
        // SPI SEND (MODE 0)
        // -----------------------------------------------------
        S_SEND: begin
            spi_cnt <= spi_cnt + 1;

            if (spi_cnt == 0) begin
                sclk <= 0;
                mosi <= tx_byte[bit_cnt];
            end

            if (spi_cnt == SPI_DIV)
                sclk <= 1;

            if (spi_cnt == SPI_DIV*2) begin
                spi_cnt <= 0;
                sclk <= 0;

                if (bit_cnt == 0)begin
                    if(state_bit == 1)begin
                        state_bit <= 0;
                        state <= S_SET_COL_L;
                    end
                    else if(state_bit2 == 1)begin
                        state_bit2 <= 0;
                        state <= S_SET_COL_H;
                    end
                    else if(state_bit3 == 1)begin
                        state_bit3 <= 0;
                        state <= S_SEND_DATA;
                    end
                    else
                        state <= S_NEXT;
                end
                else
                    bit_cnt <= bit_cnt - 1;
            end
        end

        // -----------------------------------------------------
        // NEXT STATE
        // -----------------------------------------------------
        S_NEXT: begin
            cs <= 1;

            // INIT VAIHE
            if (dc == 0 && cmd_index != 0) begin
                state <= S_LOAD_INIT;
            end

            // INIT VALMIS → GRAFIIKKA
            else if (dc == 0 && cmd_index == 0) begin
                page <= 0;
                col  <= 0;
                state <= S_SET_PAGE;
            end

            // DATA
            else begin
                if (col == 127) begin
                    col <= 0;
                    if (page == 7)
                        page <= 0;
                    else
                        page <= page + 1;
                    state <= S_SET_PAGE;
                end else begin
                    col <= col + 1;
                    state <= S_SEND_DATA;
                end
            end
        end

        // -----------------------------------------------------
        // SET PAGE
        // -----------------------------------------------------
        S_SET_PAGE: begin
            cs <= 0;
            dc <= 0;
            tx_byte <= 8'hB0 | page;
            bit_cnt <= 3'd7;
            state_bit <= 1;
            state <= S_SEND;
        end

        // -----------------------------------------------------
        // SET COLUMN LOW (OFFSET = 2)
        // -----------------------------------------------------
        S_SET_COL_L: begin
            cs <= 0;
            dc <= 0;
            tx_byte <= 8'h02;
            bit_cnt <= 3'd7;
            state_bit2 <= 1;
            state <= S_SEND;
        end

        // -----------------------------------------------------
        // SET COLUMN HIGH
        // -----------------------------------------------------
        S_SET_COL_H: begin
            cs <= 0;
            dc <= 0;
            tx_byte <= 8'h10;
            bit_cnt <= 3'd7;
            state_bit3 <= 1;
            state <= S_SEND;
        end

        // -----------------------------------------------------
        // SEND DATA (128 BYTEA / PAGE)
        // -----------------------------------------------------
        S_SEND_DATA: begin
            cs <= 0;
            dc <= 1;
    

            // TESTIKUVIO: pystysuorat raidat
            //tx_byte <= (col[0]) ? 8'hFF : 8'h00;
            //tx_byte <= 8'hFF;

            // Esimerkki: tulosta 'A' pageen 3, alkaen columnista 10
            if(alarm_o == 1 && alarm_cnt < 4000000)begin
                alarm_cnt <= alarm_cnt + 1;
                if (page == PAGE_TEXT &&
                    col >= X_START &&
                    col < X_START + 7 * (CHAR_W + SPACE)) begin

                    char_index = (col - X_START) / (CHAR_W + SPACE);
                    char_col   = (col - X_START) % (CHAR_W + SPACE);
                    /*
                    if (char_col < CHAR_W)
                        tx_byte <= font5x8(freq_table[(freq_group * 28) + pulse_cnt * 7 + char_index], char_col);
                    else
                        tx_byte <= 8'h00;
                    */
                end
                //else
                   // tx_byte <= 8'h00;   
            end
            /*else if(~button_pressed1)begin
                if(pulse_cnt == 1) begin
                    if (page == PAGE_TEXT &&
                            col >= X_START &&
                            col < X_START + text_len71 * (CHAR_W + SPACE)) begin
            
                            char_index = (col - X_START) / (CHAR_W + SPACE);
                            char_col   = (col - X_START) % (CHAR_W + SPACE);

                            if (char_col < CHAR_W)
                                tx_byte <= font5x8(text_buf71[char_index], char_col);
                            else
                                tx_byte <= 8'h00;
                        end
                    else
                           tx_byte <= 8'h00;
                end
                else if(pulse_cnt == 0)begin
                    if (page == PAGE_TEXT &&
                            col >= X_START &&
                            col < X_START + text_len145 * (CHAR_W + SPACE)) begin
            
                            char_index = (col - X_START) / (CHAR_W + SPACE);
                            char_col   = (col - X_START) % (CHAR_W + SPACE);

                            if (char_col < CHAR_W)
                                tx_byte <= font5x8(text_buf145[char_index], char_col);
                            else
                                tx_byte <= 8'h00;
                        end
                    else
                           tx_byte <= 8'h00;
                    
                end
            end*/
            /*else begin
                alarm_cnt <= alarm_cnt + 1;
                if(alarm_cnt == 5500000)
                    alarm_cnt <= 0;
                if(pulse_cnt == 1 || pulse_cnt == 0)begin
                        if (page == PAGE_TEXT &&
                                col >= X_START &&
                                col < X_START + text_len145 * (CHAR_W + SPACE)) begin
                
                                char_index = (col - X_START) / (CHAR_W + SPACE);
                                char_col   = (col - X_START) % (CHAR_W + SPACE);

                                if (char_col < CHAR_W)
                                    tx_byte <= font5x8(text_buf145[char_index], char_col);
                                else
                                    tx_byte <= 8'h00;
                            end
                        else
                               tx_byte <= 8'h00;
                        
                    end
                else if(pulse_cnt == 2) begin
                    if (page == PAGE_TEXT &&
                            col >= X_START &&
                            col < X_START + text_len71 * (CHAR_W + SPACE)) begin
            
                            char_index = (col - X_START) / (CHAR_W + SPACE);
                            char_col   = (col - X_START) % (CHAR_W + SPACE);

                            if (char_col < CHAR_W)
                                tx_byte <= font5x8(text_buf71[char_index], char_col);
                            else
                                tx_byte <= 8'h00;
                        end
                    else
                           tx_byte <= 8'h00;
                end
            end*/
            else begin
                alarm_cnt <= alarm_cnt + 1;

                if(alarm_cnt == 5500000)
                    alarm_cnt <= 0;

                if (page == PAGE_TEXT &&
                    col >= X_START &&
                    col < X_START + 7 * (CHAR_W + SPACE)) begin

                    char_index = (col - X_START) / (CHAR_W + SPACE);
                    char_col   = (col - X_START) % (CHAR_W + SPACE);

                    if (char_col < CHAR_W)
                        tx_byte <= font5x8(freq_table[(freq_group * 28) + pulse_cnt * 7 + char_index], char_col);
                    else
                        tx_byte <= 8'h00;

                end
                else if (page == PAGE_TEXT_W)begin
                    if(col >= X_START &&
                        col < X_START + 4 * (CHAR_W + SPACE)) begin

                        char_index = (col - X_START) / (CHAR_W + SPACE);
                        char_col   = (col - X_START) % (CHAR_W + SPACE);

                        if (char_col < CHAR_W)
                            tx_byte <= font5x8(text_buf[freq_group * 4 + char_index], char_col);
                        else
                            tx_byte <= 8'h00;

                    end
                    else
                        tx_byte <= 8'h00;
                    if(col >= X_START_DB && col < X_START_DB + 4 * (CHAR_W + SPACE) && gain_cnt_db == 0)begin

                        char_index = (col - X_START_DB) / (CHAR_W + SPACE);
                        char_col   = (col - X_START_DB) % (CHAR_W + SPACE); 
                        
                        if (char_col < CHAR_W)
                            tx_byte <= font5x8(text_bufdb[char_index], char_col);
                        else
                            tx_byte <= 8'h00;
                    end
                    if(col >= X_START_DB_W && col < X_START_DB_W + 2 * (CHAR_W + SPACE))begin

                        char_index = (col - X_START_DB_W) / (CHAR_W + SPACE);
                        char_col   = (col - X_START_DB_W) % (CHAR_W + SPACE); 
                        
                        if (char_col < CHAR_W)
                            tx_byte <= font5x8(text_bufdbw[gain * 2 + char_index], char_col);
                        else
                            tx_byte <= 8'h00;
                    end
                end
                else
                    tx_byte <= 8'h00;
            end
            bit_cnt <= 3'd7;
            state <= S_SEND;
        end

        endcase

        // -----------------------------------------------------
        // PAGE → COLUMN SEQUENCE
        // -----------------------------------------------------
        /*if (state == S_SET_PAGE && state != S_SEND)
            state <= S_SET_COL_L;
        else if (state == S_SET_COL_L && state != S_SEND)
            state <= S_SET_COL_H;
        else if (state == S_SET_COL_H && state != S_SEND)
            state <= S_SEND_DATA;*/
  end

endmodule
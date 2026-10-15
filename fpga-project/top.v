
module top (
    input  wire clk,          
    input  wire uart_rx_pin,  
    input  wire button1,
    input  wire button2,
    input  wire button3,
    output wire Tx,
    output wire data1,
    output wire sclk,         // SPI Clock
    output wire mosi,         // SPI MOSI
    output wire cs,           // SPI Chip Select
    output wire dc,           // Data/Command
    output wire rst,           // Display Reset
    output wire led,
    output wire led7,
    output wire led8
);


    wire [7:0] rx_data;
    wire       rx_valid;
    wire alarm1;
    reg led1 = 1;
    reg led2 = 0;
    wire [7:0] data1;
    reg [7:0] ready_data;
    reg ready = 0;
    wire button1_pressed;
    wire button2_pressed;
    wire button3_pressed;
    wire ack_bit;
    reg Tx_en_reg = 1;
    wire Tx_en;
    reg [7:0] data_in = 0;
    wire txclken;
    wire rxclken;
    reg button1_pressed_d;
    reg button2_pressed_d;
    reg button3_pressed_d;
    reg [3:0] pulse_cnt = 0;
    reg data_cnt = 0;

    reg [31:0] cnt;
    reg [31:0] ack_cnt;
    reg [31:0] btn_cnt = 0;
    
    assign led7 = led1;
    //assign led8 = led2;
    assign Tx_en = Tx_en_reg;

    reg [4:0] send_cnt = 0;
    reg [3:0] freq_group = 0;
    reg [3:0] freq_group_active = 0;
    wire [7:0] data_inn;
    reg [3:0] gain = 3;
    

    uart_rx_alert uart_inst (
    .clk   (clk),
    //.rst_n   (rst_n),
    .led1   (led),
    .uart_rx    (uart_rx_pin),              // ASCII-tavu
    .alarm_w    (alarm1),
    .data     (data1),
    .clken    (rxclken),
    .ack_bit    (ack_bit)
    //.Tx_en      (Tx_en)
    

    );
    
    baudrate baud_inst (
    .clk   (clk),
    .Rxclk_en    (rxclken),            // ASCII-tavu
    .Txclk_en  (txclken)
    );

    sh1106_spi_full oled_inst (
        .clk        (clk),
        .sclk       (sclk),
        .mosi       (mosi),
        .cs         (cs),
        .dc         (dc),
        .rst        (rst),
        .alarm_o    (alarm1),
        .pulse_cnt  (pulse_cnt),
        .data_cnt   (data_cnt),
        .button_pressed1  (button1_pressed),
        .gain       (gain),
        .gain_select(gain_select),
        .freq_group (freq_group)
    );
    button button_inst  (
        .clk   (clk),
        .button1  (button1),
        .button2  (button2),
        .button3  (button3),
        .button1_pressed   (button1_pressed),
        .button2_pressed   (button2_pressed),
        .button3_pressed   (button3_pressed)
    );

    transmitter transmitter_inst  (
        .clk    (clk),
        .clken  (txclken),
        .Tx     (Tx),
        .Tx_en  (Tx_en),
        .data_in (data_in)
    );
    
    frequencies_data freq_data_inst (
        .clk   (clk),
        .led    (led8),
        .freq_group(freq_group),
        .send_cnt(send_cnt),
        .data_out(data_inn)
    );
    
    wire button1_pulse = ~button1_pressed & button1_pressed_d;
    wire button2_pulse = ~button2_pressed & button2_pressed_d;
    wire button3_pulse = ~button3_pressed & button3_pressed_d;
    

    reg pulse2_cnt = 0;
    reg [31:0] button_cnt = 0;
    reg button3_pulse_act = 0;
    reg send_request = 0;
    
    reg button1_lock = 0;
    reg button3_lock = 0;
    
    reg [31:0]button1_timer = 0;
    reg gain_select = 0;
    
    parameter
        IDLE            = 4'd0,
        DATA_TO_SEND    = 4'd1,
        SEND_DATA       = 4'd2;

    reg [3:0] state = IDLE;

    
    always @(posedge clk) begin
        
        if(gain <= 0)
            gain <= 1;
        else if(gain >= 10)
            gain <= 9;

        button1_pressed_d <= button1_pressed;
        button2_pressed_d <= button2_pressed;
        button3_pressed_d <= button3_pressed;

        Tx_en_reg <= 1;  
        
        if(button_cnt == 27000010)
            button_cnt <= 0;
        else
            button_cnt <= button_cnt + 1;

        if(button3_pressed == 1)begin
            button3_lock <= 0;
        end
        if(button1_pressed == 0)begin
            button1_timer <= button1_timer + 1;
            if(button1_timer == 70000000)begin  
                led1 <= ~led1;
                button1_timer <= 0;
                gain_select <= ~gain_select;
            end   
        end 
        else        
            button1_timer <= 0;
       
        if(button3_pulse) begin
            if(gain_select == 0)begin
                if(freq_group == 2)
                    //led1 <= ~led1;
                button3_lock <= 1;

                if(freq_group == 4)begin
                    freq_group <= 0;

                end
                else begin
                    freq_group <= freq_group + 1;

                end

                send_cnt <= 0;  
                pulse_cnt <= 0;
            end
            else if(gain_select == 1)begin
               
                gain <= gain - 1;

                data_in <= 8'h2D;
                send_request <= 1;
            end
                
        end
        
        if(button2_pulse)begin
            if(gain_select == 0)begin
                if(pulse2_cnt == 0)begin
                    
                    pulse2_cnt <= 1;
                end
                else if(pulse2_cnt == 1)begin     
                    pulse2_cnt <= 0;
                end
            end 
            else if(gain_select == 1)begin

                gain <= gain + 1;

                data_in <= 8'h2B;
                send_request <= 1;
            end
        end
        if(pulse2_cnt == 1 && button_cnt == 27000000 && alarm1 == 0 && gain_select == 0)begin        
            send_request <= 1;
            button_cnt <= 0;
        end


        
        if(button1_pulse && gain_select == 0) begin
            send_request <= 1;
        end

   
        if(send_request) begin
            if(gain_select == 0)begin
                send_request <= 0;

                data_in <= data_inn;
                Tx_en_reg <= 0;
                pulse_cnt <= pulse_cnt + 1;

                if(send_cnt == 3)begin
                    send_cnt <= 0;
                    pulse_cnt <= 0;
                end
                else begin
                    send_cnt <= send_cnt + 1;
                end
            end
            else if(gain_select == 1)
                send_request <= 0;
                Tx_en_reg <= 0;
        end

    end

        

    /*always @(posedge clk)begin
        //data_in <= (8'b11110000);
        button1_pressed_d <= button1_pressed;
        button2_pressed_d <= button2_pressed;
        if(button2_pulse)begin
            if(pulse2_cnt == 1)
                pulse2_cnt <= 0;
            else if(pulse2_cnt == 0)    
                pulse2_cnt <= 1;
        end
        if(pulse2_cnt || alarm1)begin
            led1 <= 1;
            if(button1_pulse)begin
                if(pulse_cnt == 0)begin
                    Tx_en_reg <= 0;
                    data_in <= 8'h44;
                    pulse_cnt <= 1;
                    data_cnt <= 1;
                    //led1 <= 0;
                end
                else if(pulse_cnt == 1)begin
                    Tx_en_reg <= 0;
                    data_in <= 8'h43;
                    pulse_cnt <= 0;
                    data_cnt <= 0;
                    //led1 <= 1;
                end
            end
            else begin
                Tx_en_reg <= 1;
            end
        end
        else begin
            led1 <= 0;
            if(btn_cnt == 0)begin
                Tx_en_reg <= 0;
                data_in <= 8'h44;
                btn_cnt <= btn_cnt + 1;
                data_cnt <= 1;
                pulse_cnt <= 1;
            end
            else if(btn_cnt == 270000000)begin
                Tx_en_reg <= 0;
                data_in <= 8'h43;
                btn_cnt <= btn_cnt + 1;
                data_cnt <= 0;
                pulse_cnt <= 0;
            end
            else if(btn_cnt == 539999999)begin
                btn_cnt <= 0;
            end
            else begin
                Tx_en_reg <= 1;
                data_in <= 0;
                btn_cnt <= btn_cnt + 1;
            end
        end
            
    end*/
endmodule

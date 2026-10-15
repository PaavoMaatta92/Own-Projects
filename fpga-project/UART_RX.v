module uart_rx_alert (
    input wire uart_rx,             
    output wire alarm_w,         
    input wire clk,        
    input wire clken,
    input wire led1,
    //input wire Tx_en,
    output reg [7:0] data,      
    output wire ack_bit
);


    initial begin         
        data = 8'b0;          
    end


    parameter RX_STATE_START = 2'b00;  
    parameter RX_STATE_DATA  = 2'b01;  
    parameter RX_STATE_STOP  = 2'b10;  


    reg [1:0] state = RX_STATE_START;  
    reg [3:0] sample = 0;              
    reg [3:0] bit_pos = 0;            
    reg [7:0] scratch = 8'b0;         
    wire Rx_en = 0;
    reg ledd = 0;
    reg [31:0] cnt = 0;
    reg [31:0] ack_cnt;
    reg alarm = 0;
    reg ack_bit_reg = 0;
    //reg Tx_en_reg = 1;
    
    assign led1 = ledd;
    assign alarm_w = alarm;
    assign ack_bit = ack_bit_reg;
    //assign Tx_en = Tx_en_reg;

   
    always @(posedge clk) begin
      
        cnt <= cnt +1;
        if(cnt == 600000000)begin
            cnt <= 0;
            ledd <= 0;
            alarm <= 0;
            ack_bit_reg <= 1;
            //Tx_en_reg <= 0;
        end
        if(ack_bit_reg == 1 && ack_cnt < 600000000)begin
            ack_cnt <= ack_cnt + 1;
        end
        else begin        
            ack_bit_reg <= 0;
            ack_cnt <= 0;
        end
        if (clken && ~Rx_en) begin  
            case (state)
                RX_STATE_START: begin  
                    if (!uart_rx || sample != 0)  
                        sample <= sample + 1;  
                    if (sample == 15) begin  
                        state <= RX_STATE_DATA;  
                        bit_pos <= 0;
                        sample <= 0;   
                        scratch <= 0;  
                    end
                end
                RX_STATE_DATA: begin  
                    if (sample == 15) begin
                        sample <= 0;
                        bit_pos <= bit_pos + 1;
                    end else begin
                        sample <= sample + 1;
                    end

                    if (sample == 8)
                        scratch[bit_pos] <= uart_rx;
                    if (bit_pos == 8)
                        state <= RX_STATE_STOP;
                        //ledd <= 0;
                end

                RX_STATE_STOP: begin  
                    if (sample == 15 || (sample >= 8 && !uart_rx)) begin  // Verify stop bit condition
                        state <= RX_STATE_START;  
                        data <= scratch;  
                        if(scratch == 8'h0x41)begin
                            alarm <= 1'b1;  
                            ledd <= 1;
                            cnt <= 0;
                        end
                        sample <= 0;  
                    end else
                        sample <= sample + 1; 
                end
                default: begin  
                    state <= RX_STATE_START;  
                end
            endcase
        end
    end

endmodule
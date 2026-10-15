module button (
  input  wire clk,
  input  wire button1,
  input  wire button2,
  input  wire button3,
  output wire  button1_pressed,
  output wire  button2_pressed,
  output wire  button3_pressed
);

  // 1️⃣ synkronointi
  reg btn1_sync1, btn1_sync2;
  reg btn2_sync1, btn2_sync2;
  reg btn3_sync1, btn3_sync2;
  // 2️⃣ laskuri
  reg [19:0] cnt1;  // riittää ~1M asti
  reg [19:0] cnt2;
  reg [19:0] cnt3;
  reg button1_pres = 1;
  reg button2_pres = 1;
  reg button3_pres = 1;

  assign button1_pressed = button1_pres;
  assign button2_pressed = button2_pres;
  assign button3_pressed = button3_pres;

  always @(posedge clk) begin
    btn1_sync1 <= button1;
    btn1_sync2 <= btn1_sync1;

    btn2_sync1 <= button2;
    btn2_sync2 <= btn2_sync1;

    btn3_sync1 <= button3;
    btn3_sync2 <= btn3_sync1;
  end

  always @(posedge clk) begin
    if (btn1_sync2 == button1_pres) begin
      cnt1 <= 0;
    end else begin
      if (cnt1 < 540_000)
        cnt1 <= cnt1 + 1;
      else begin
        button1_pres <= btn1_sync2;
        cnt1 <= 0;
      end
    end
    
    if (btn2_sync2 == button2_pres) begin
      cnt2 <= 0;
    end else begin
      if (cnt2 < 540_000)
        cnt2 <= cnt2 + 1;
      else begin
        button2_pres <= btn2_sync2;
        cnt2 <= 0;
      end
    end

    if (btn3_sync2 == button3_pres) begin
      cnt3 <= 0;
    end else begin
      if (cnt3 < 540_000)
        cnt3 <= cnt3 + 1;
      else begin
        button3_pres <= btn3_sync2;
        cnt3 <= 0;
      end
    end
  end
  
    

endmodule

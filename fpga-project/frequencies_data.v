module frequencies_data (
    input  wire       clk,
    input  wire       led,
    input  wire [2:0] freq_group,
    input  wire [4:0] send_cnt,
    output reg  [7:0] data_out
);

    // 1D-muoto: 5 datasettiä * 26 merkkiä = 130
    reg [7:0] data [0:129];

    initial begin
        // 🔹 group 0: 2m ja 70cm
        data[0]  = 8'h30; data[1]  = 8'h31; data[2]  = 8'h32; data[3]  = 8'h33;
        data[4]  = 8'h34; data[5]  = 8'h35; data[6]  = 8'h36; data[7]  = 8'h37;
        data[8]  = 8'h38; data[9]  = 8'h39; 
        data[10] = 8'h7E; data[11] = 8'h7E; data[12] = 8'h7E; data[13] = 8'h7E;
        data[14] = 8'h7E; data[15] = 8'h7E; data[16] = 8'h7E; data[17] = 8'h7E;
        data[18] = 8'h7E; data[19] = 8'h7E; data[20] = 8'h7E; data[21] = 8'h7E;
        data[22] = 8'h7E; data[23] = 8'h7E; data[24] = 8'h7E; data[25] = 8'h7E;

        // 🔹 group 1: RhA
        data[26] = 8'h41; data[27] = 8'h42; data[28] = 8'h43; data[29] = 8'h44;
        data[30] = 8'h45; data[31] = 8'h46; data[32] = 8'h47; data[33] = 8'h48;
        data[34] = 8'h49; data[35] = 8'h4A; data[36] = 8'h4B; data[37] = 8'h4C;
        data[38] = 8'h4D; data[39] = 8'h4E; data[40] = 8'h4F; data[41] = 8'h50;
        data[42] = 8'h51; data[43] = 8'h52; data[44] = 8'h53; data[45] = 8'h54;
        data[46] = 8'h55; data[47] = 8'h56; data[48] = 8'h57; data[49] = 8'h58;
        data[50] = 8'h59; data[51] = 8'h5A;

        // 🔹 group 2: LA-puhelin
        data[52] = 8'h61; data[53] = 8'h62; data[54] = 8'h63; data[55] = 8'h64;
        data[56] = 8'h65; data[57] = 8'h66; data[58] = 8'h67; data[59] = 8'h68;
        data[60] = 8'h69; data[61] = 8'h6A; data[62] = 8'h6B; data[63] = 8'h6C;
        data[64] = 8'h6D; data[65] = 8'h6E; data[66] = 8'h6F; data[67] = 8'h70;
        data[68] = 8'h71; data[69] = 8'h72; data[70] = 8'h73; data[71] = 8'h74;
        data[72] = 8'h75; data[73] = 8'h76; data[74] = 8'h77; data[75] = 8'h78;
        data[76] = 8'h79; data[77] = 8'h7A;

        // 🔹 group 3: Ilmailu
        data[78] = 8'h21; data[79] = 8'h22; data[80] = 8'h23; data[81] = 8'h24;
        data[82] = 8'h25; data[83] = 8'h26; data[84] = 8'h27; data[85] = 8'h28;
        data[86] = 8'h29; data[87] = 8'h2A; data[88] = 8'h2B; data[89] = 8'h2C;
        data[90] = 8'h2D; data[91] = 8'h2E; data[92] = 8'h2F; data[93] = 8'h7E;
        data[94] = 8'h7E; data[95] = 8'h7E; data[96] = 8'h7E; data[97] = 8'h7E;
        data[98] = 8'h7E; data[99] = 8'h7E; data[100] = 8'h7E; data[101] = 8'h7E;
        data[102] = 8'h7E; data[103] = 8'h7E;

        // 🔹 group 4: Meri
        data[104] = 8'h3A; data[105] = 8'h3B; data[106] = 8'h3C; data[107] = 8'h3D;
        data[108] = 8'h3E; data[109] = 8'h3F; data[110] = 8'h40; data[111] = 8'h5B;
        data[112] = 8'h5C; data[113] = 8'h5D; data[114] = 8'h5E; data[115] = 8'h5F;
        data[116] = 8'h60; data[117] = 8'h7B; data[118] = 8'h7C; data[119] = 8'h7D;
        data[120] = 8'h7E; data[121] = 8'h7E; data[122] = 8'h7E; data[123] = 8'h7E;
        data[124] = 8'h7E; data[125] = 8'h7E; data[126] = 8'h7E; data[127] = 8'h7E;
        data[128] = 8'h7E; data[129] = 8'h7E;
    end
    

    // 🔹 combinational read, EI synkroniviivettä
    always @(posedge clk) begin
        data_out <= data[freq_group*26 + send_cnt];
    end

endmodule
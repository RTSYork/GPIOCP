// Virtex-6 / 7-series 32kbit block RAM module

module bram_v6(CLK, RST_N,
            ADDRA, DIA, WEA, ENA, DOA,
            ADDRB, DIB, WEB, ENB, DOB);

    input   CLK;
    input   RST_N;
    input   [14:0] ADDRA;
    input   [31:0] DIA;
    input   [3:0] WEA;
    input   ENA;
    output  [31:0] DOA;
    input   [14:0] ADDRB;
    input   [31:0] DIB;
    input   [3:0] WEB;
    input   ENB;
    output  [31:0] DOB;

    parameter DATA_WIDTH = 1;

    wire RST;
    assign RST = ~RST_N;

    RAMB36E1 # ( 
        .DOA_REG (0),
        .DOB_REG (0),
        .EN_ECC_READ("FALSE"),
        .EN_ECC_WRITE("FALSE"),
        .RAM_MODE("TDP"),
        .READ_WIDTH_A (DATA_WIDTH),
        .READ_WIDTH_B (DATA_WIDTH),
        .SIM_COLLISION_CHECK ("ALL"),
        .SIM_DEVICE("VIRTEX6"),
        .SRVAL_A (0),
        .SRVAL_B (0),
        .WRITE_MODE_A ("READ_FIRST"),
        .WRITE_MODE_B ("READ_FIRST"),
        .WRITE_WIDTH_A (DATA_WIDTH),
        .WRITE_WIDTH_B (DATA_WIDTH)) v6 (
            .CASCADEOUTA (),
            .CASCADEOUTB (),
            .DBITERR (),
            .DOADO (DOA), 
            .DOBDO (DOB), 
            .DOPADOP (), 
            .DOPBDOP (),
            .ECCPARITY (),
            .RDADDRECC (),
            .SBITERR (),
            .ADDRARDADDR ({1'b1, ADDRA}), 
            .ADDRBWRADDR ({1'b1, ADDRB}),
            .CASCADEINA (1'b0),
            .CASCADEINB (1'b0), 
            .CLKARDCLK (CLK), 
            .CLKBWRCLK (CLK), 
            .DIADI (DIA), 
            .DIBDI (DIB), 
            .DIPADIP (4'b0), 
            .DIPBDIP (4'b0), 
            .ENARDEN (ENA), 
            .ENBWREN (ENB), 
            .INJECTDBITERR(1'b0),
            .INJECTSBITERR(1'b0),
            .REGCEAREGCE (1'b1), 
            .REGCEB (1'b1), 
            .RSTRAMARSTRAM (RST), 
            .RSTRAMB (RST), 
            .RSTREGARSTREG (1'b0), 
            .RSTREGB (1'b0), 
            .WEA (WEA), 
            .WEBWE ({4'b0000, WEB})
            );

            
endmodule


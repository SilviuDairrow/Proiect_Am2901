`timescale 1ns / 1ns

module Am2901_top(
    input CLK,
    input [3:0] A,
    input [3:0] B,
    input [3:0] DATAIN,
    input [8:0] I,
    input Cn, // carry-in
    output [3:0] Y,
    output Gneg, output Pneg,
    output Cn4,
    output OVR,
    output F_0,
    output F3,
    input RAM0_IN,
    input RAM3_IN,
    input Q0_IN,
    input Q3_IN,
    output RAM0_ENABLE,
    output RAM0_OUT,
    output RAM3_ENABLE,
    output RAM3_OUT,
    output Q0_ENABLE,
    output Q0_OUT,
    output Q3_ENABLE,
    output Q3_OUT
    );
    
    wire Q_ENABLE;
    wire [2:0] Q_REG_FUNCTION;
    wire WE;
    wire [2:0] RAM_FUNCTION;
    wire Y_OUTPUT;
    wire RAM_SHIFT0;
    wire RAM_SHIFT3;
    wire Q_SHIFT0;
    wire Q_SHIFT3;

    wire [2:0] decode;
    assign decode = {I[8], I[7], I[6]};
    ALU_Destination_Decode dest_decode(
                              decode,
                              Q_ENABLE,
                              Q_REG_FUNCTION,
                              WE,
                              RAM_FUNCTION,
                              Y_OUTPUT,
                              RAM_SHIFT0,
                              RAM_SHIFT3,
                              Q_SHIFT0,
                              Q_SHIFT3);
    
    assign {RAM0_ENABLE, RAM3_ENABLE, Q0_ENABLE, Q3_ENABLE} = {RAM_SHIFT0, RAM_SHIFT3, Q_SHIFT0, Q_SHIFT3};
    
    wire d0_ram, d1_ram, d2_ram, d3_ram;
    wire [3:0] f;
    MUX31 mux_D0_RAM(.SELECT(RAM_FUNCTION), .A(f[1]), .B(RAM0_IN), .C(f[0]), .DO(d0_ram)); // f[0] trebuie pus in Ram0 (A)
    MUX31 mux_D1_RAM(.SELECT(RAM_FUNCTION), .A(f[2]), .B(f[0]), .C(f[1]), .DO(d1_ram)); 
    MUX31 mux_D2_RAM(.SELECT(RAM_FUNCTION), .A(f[3]), .B(f[1]), .C(f[2]), .DO(d2_ram));
    MUX31 mux_D3_RAM(.SELECT(RAM_FUNCTION), .A(RAM3_IN), .B(f[2]), .C(f[3]), .DO(d3_ram)); // f[3] trebuie pus in Ram3 (B)
    wire [3:0] DO_A, DO_B;
    DPRAM_16x4 ram(
                   CLK,
                   WE,
                   A,
                   B,
                   {d3_ram, d2_ram, d1_ram, d0_ram}, // DI
                   DO_A,
                   DO_B
                   );
    
    wire [3:0] d_q;
    wire [3:0] Q;
    MUX31 mux_D0_Q(.SELECT(Q_REG_FUNCTION), .A(Q[1]), .B(Q0_IN), .C(f[0]), .DO(d_q[0])); // Q[0] trebuie pus in Q0 (A)
    MUX31 mux_D1_Q(.SELECT(Q_REG_FUNCTION), .A(Q[2]), .B(Q[0]), .C(f[1]), .DO(d_q[1]));
    MUX31 mux_D2_Q(.SELECT(Q_REG_FUNCTION), .A(Q[3]), .B(Q[1]), .C(f[2]), .DO(d_q[2]));
    MUX31 mux_D3_Q(.SELECT(Q_REG_FUNCTION), .A(Q3_IN), .B(Q[2]), .C(f[3]), .DO(d_q[3])); // Q[3] trebuie pus in Q3 (B)
    
    assign {RAM0_OUT, RAM3_OUT, Q0_OUT, Q3_OUT} = {f[0], f[3], Q[0], Q[3]};
    
    Q_Register q_reg(
                  CLK,
                  Q_ENABLE,
                  d_q,
                  Q
                  );  
    
    wire [2:0] func_decode_out;
    wire [2:0] f_decode;
    assign f_decode = {I[5], I[4], I[3]};              
    ALU_Function_Decode func_decode(f_decode, func_decode_out);
    
    wire [1:0] SELECT_R_REG_MUX, SELECT_S_REG_MUX;
    ALU_Source_Operand source_decode(
                           ({I[2], I[1], I[0]}),
                           SELECT_R_REG_MUX, //pt mux 2-1
                           SELECT_S_REG_MUX //pt mux 3-1                           
                           );
    
    wire [3:0] R, S;
    MUX21_ALU_R mux21_alu_R0(
                   .SELECT(SELECT_R_REG_MUX),
                   .BUS_DI(DATAIN[0]),
                   .RAM_DI(DO_A[0]),
                   .DO(R[0])
                   );
                   
    MUX21_ALU_R mux21_alu_R1(
                   .SELECT(SELECT_R_REG_MUX),
                   .BUS_DI(DATAIN[1]),
                   .RAM_DI(DO_A[1]),
                   .DO(R[1])
                   );
                   
    MUX21_ALU_R mux21_alu_R2(
                   .SELECT(SELECT_R_REG_MUX),
                   .BUS_DI(DATAIN[2]),
                   .RAM_DI(DO_A[2]),
                   .DO(R[2])
                   );
                   
    MUX21_ALU_R mux21_alu_R3(
                   .SELECT(SELECT_R_REG_MUX),
                   .BUS_DI(DATAIN[3]),
                   .RAM_DI(DO_A[3]),
                   .DO(R[3])
                   );    
                   
    MUX31_ALU_S mux31_alu_S0(
                   .SELECT(SELECT_S_REG_MUX),
                   .RAM_A_DI(DO_A[0]),
                   .RAM_B_DI(DO_B[0]),
                   .Q_DI(Q[0]),
                   .DO(S[0])
                   );
                   
    MUX31_ALU_S mux31_alu_S1(
                   .SELECT(SELECT_S_REG_MUX),
                   .RAM_A_DI(DO_A[1]),
                   .RAM_B_DI(DO_B[1]),
                   .Q_DI(Q[1]),
                   .DO(S[1])
                   );
                   
    MUX31_ALU_S mux31_alu_S2(
                   .SELECT(SELECT_S_REG_MUX),
                   .RAM_A_DI(DO_A[2]),
                   .RAM_B_DI(B[2]),
                   .Q_DI(Q[2]),
                   .DO(S[2])
                   );
                   
    MUX31_ALU_S mux31_alu_S3(
                   .SELECT(SELECT_S_REG_MUX),
                   .RAM_A_DI(DO_A[3]),
                   .RAM_B_DI(DO_B[3]),
                   .Q_DI(Q[3]),
                   .DO(S[3])
                   );
                   
    ALU arithmetic_logic_unit(
                              func_decode_out, R, S, Cn, f, Gneg, Pneg, Cn4,
                              OVR, F_0, F3
                              );
                            
    MUX21 mux21_Y0(
        .SELECT(Y_OUTPUT),
        .A(A[0]),
        .F(f[0]),
        .Y(Y[0])
        );
        
    MUX21 mux21_Y1(
        .SELECT(Y_OUTPUT),
        .A(A[1]),
        .F(f[1]),
        .Y(Y[1])
        );

    MUX21 mux21_Y2(
        .SELECT(Y_OUTPUT),
        .A(A[2]),
        .F(f[2]),
        .Y(Y[2])
        );
        
    MUX21 mux21_Y3(
        .SELECT(Y_OUTPUT),
        .A(A[3]),
        .F(f[3]),
        .Y(Y[3])
        );

endmodule
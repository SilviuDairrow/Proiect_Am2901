`timescale 1ns / 1ps

module Q_Register(
                  input CLK,
                  input ENABLE,
                  input [3:0] DI,
                  output reg [3:0] Q //nu stiu daca chiar tre sa fac q0,q1,q2,q3 || MERGE SI ASA
                  );
                  
   //assign DI = {DI_3, DI_2, DI_1, DI_0};
   
   always@(posedge CLK) begin
    if(ENABLE) begin
        Q <= DI;
    end 
   end
   
endmodule

module DPRAM_16x4(
                   input CLK,
                   input WE,
                   input [3:0] ADDR_A,
                   input [3:0] ADDR_B,
                   input [3:0] DI,
                   output reg [3:0] DO_A,
                   output reg [3:0] DO_B
                  );
 
    reg [3:0] mem[0:15]; 

    always@(ADDR_A or mem[ADDR_A]) begin
        DO_A = mem[ADDR_A];               
    end

    always@(ADDR_B or mem[ADDR_B]) begin
        DO_B = mem[ADDR_B];               
    end                  
    
    always@(posedge CLK) begin
        if (WE) begin
            mem[ADDR_B] <= DI; 
        end
    end    
    
endmodule


//RAM_FUNCTION Logic  |  Q_REG_FUNCTION Logic | Y Output DO  | RAM_SHIFT0 | Q_SHIFT0 
// down   - 00        |  down   - 00          | A - 0        | F0 - 0     | Q0 - 0
// up     - 01        |  up     - 01          | F - 1        | IN0 - 1    | IN0 - 1
// none   - 1x        |  none   - 1x          |              |            |
//                                                             RAM_SHIFT3 | Q_SHIFT3
//                                                             F3 - 0     | Q3 - 0
//                                                             IN3 - 1    | IN3 - 1   
module ALU_Destination_Decode(
                              input [2:0] I68,
                              output Q_ENABLE, // 0 - nu se face scriere in registrul Q, 1 - se face scriere
                              output [1:0] Q_REG_FUNCTION, // Select pentru multiplexoare la registrul Q
                              output WE, // WE de la memoria RAM, 0 - nu se face scriere ?n memorie
                              output [1:0] RAM_FUNCTION, // Select pentru multiplexoare la memoria RAM
                              output Y_OUTPUT, // A = 0, F = 1
                              output RAM_SHIFT0,
                              output RAM_SHIFT3,
                              output Q_SHIFT0,
                              output Q_SHIFT3
                              );     
    
    reg [10:0]concat;
    
    // toate x au fost trecute ca 0 sau 00 pentru noi
    always@(I68) begin
        casex(I68)
            //               Q_ENB  Q_FUN  R_ENB R_FUN  Y_OUT R_SHF0 R_SHF3  Q_SHFT0 Q_SHFT3
            3'b000: concat = {1'b1, 2'b10, 1'b0, 2'b00, 1'b1, 1'b0,  1'b0,   1'b0,   1'b0};
            3'b001: concat = {1'b0, 2'b00, 1'b0, 2'b00, 1'b1, 1'b0,  1'b0,   1'b0,   1'b0};
            3'b010: concat = {1'b0, 2'b00, 1'b1, 2'b11, 1'b0, 1'b0,  1'b0,   1'b0,   1'b0};
            3'b011: concat = {1'b0, 2'b00, 1'b1, 2'b11, 1'b1, 1'b0,  1'b0,   1'b0,   1'b0};
            3'b100: concat = {1'b1, 2'b00, 1'b1, 2'b00, 1'b1, 1'b1,  1'b0,   1'b1,   1'b0};
            3'b101: concat = {1'b0, 2'b00, 1'b1, 2'b00, 1'b1, 1'b1,  1'b0,   1'b0,   1'b0};
            3'b110: concat = {1'b1, 2'b01, 1'b1, 2'b01, 1'b1, 1'b0,  1'b1,   1'b0,   1'b1};
            3'b111: concat = {1'b0, 2'b00, 1'b1, 2'b01, 1'b1, 1'b0,  1'b1,   1'b0,   1'b0};
        endcase
    end
    
    assign {Q_ENABLE, Q_REG_FUNCTION, WE, RAM_FUNCTION, Y_OUTPUT, 
            RAM_SHIFT0, RAM_SHIFT3, Q_SHIFT0, Q_SHIFT3} = concat;
                      
endmodule



// mux 2 - 1 logic:
// A = 00
// D = 01
// 0 = 10 || 11

// mux 3 - 1 logic:
// A = 01
// B = 10
// Q = 11
// 0 = 00
module ALU_Source_Operand(
                           input [2:0] I02,
                           output reg [1:0] SELECT_R_REG_MUX, //pt mux 2-1
                           output reg [1:0] SELECT_S_REG_MUX //pt mux 3-1                           
                           );
                       
    always@(I02) begin
        casex(I02)
            3'b000: {SELECT_R_REG_MUX, SELECT_S_REG_MUX} = 4'b01_11; // R = A | S = Q
            3'b001: {SELECT_R_REG_MUX, SELECT_S_REG_MUX} = 4'b01_10; // R = A | S = B
            
            3'b010: {SELECT_R_REG_MUX, SELECT_S_REG_MUX} = 4'b00_11; // R = 0 | S = Q
            3'b011: {SELECT_R_REG_MUX, SELECT_S_REG_MUX} = 4'b00_10; // R = 0 | S = B
            3'b100: {SELECT_R_REG_MUX, SELECT_S_REG_MUX} = 4'b00_01; // R = 0 | S = A
            
            3'b101: {SELECT_R_REG_MUX, SELECT_S_REG_MUX} = 4'b10_01; // R = D | S = A
            3'b110: {SELECT_R_REG_MUX, SELECT_S_REG_MUX} = 4'b10_11; // R = D | S = Q
            3'b111: {SELECT_R_REG_MUX, SELECT_S_REG_MUX} = 4'b10_00; // R = D | S = 0
        endcase
    end
    
endmodule



// mux 2 - 1 logic:
// A = 01
// D = 10
// 0 = 00
module MUX21_ALU_R(
                   input [1:0] SELECT,
                   input BUS_DI,
                   input RAM_DI,
                   output reg DO
                   );

    always@(SELECT or BUS_DI or RAM_DI) begin //nu stiu daca alwaysu meu trebuie cu toate input sau nu
        casex(SELECT) 
            2'b00: DO = 1'b0;
            2'b01: DO = RAM_DI;
            2'b1x: DO = BUS_DI;
        endcase
    end

endmodule


// mux 3 - 1 logic:
// A = 01
// B = 10
// Q = 11
// 0 = 00
module MUX31_ALU_S(
                   input [1:0] SELECT,
                   input RAM_A_DI,
                   input RAM_B_DI,
                   input Q_DI,
                   output reg DO
                   );

    always@(SELECT or RAM_A_DI or RAM_B_DI or Q_DI) begin // la fel ca mai sus
        casex(SELECT)
            2'b00: DO = 0;
            2'b01: DO = RAM_A_DI;
            2'b10: DO = RAM_B_DI;
            2'b11: DO = Q_DI;    
        endcase
    end

endmodule


module ALU_Function_Decode(
    input [2:0] I35,
    output reg [2:0] ALU_Instruction
    );
    
    always@(I35)
    begin
        case(I35)
            3'b000: ALU_Instruction = 3'b000; // R plus S
            3'b001: ALU_Instruction = 3'b001; // S minus R
            3'b010: ALU_Instruction = 3'b010; // R minus S
            3'b011: ALU_Instruction = 3'b011; // R or S
            3'b100: ALU_Instruction = 3'b100; // R and S
            3'b101: ALU_Instruction = 3'b101; // not(R) and S
            3'b110: ALU_Instruction = 3'b110; // R ex-or S
            3'b111: ALU_Instruction = 3'b111; // R ex-nor S
        endcase
    end
    
endmodule

module MUX31(
    input [1:0] SELECT,
    input A,
    input B,
    input C,
    output reg DO
    );

    always@(SELECT or A or B or C)
    begin
        casex(SELECT)
            2'b00: DO = A;
            2'b01: DO = B;
            2'b1x: DO = C;
        endcase
    end

endmodule

module MUX21(
    input SELECT,
    input A,
    input F,
    output reg Y);
    
    always@(SELECT or A or F)
    begin
        case(SELECT)
            1'b0: Y = A;
            1'b1: Y = F;
        endcase
    end
    
endmodule

module ALU(
    input [2:0] instruction,
    input [3:0] R,
    input [3:0] S,
    input Cn,
    output reg [3:0] F,
    output reg Gneg, output reg Pneg,
    output reg Cn4,
    output reg OVR,
    output F_0,
    output F3
    );
    
    wire [3:0] P, G;
    assign P[0] = R[0] | S[0];
    assign P[1] = R[1] | S[1];    
    assign P[2] = R[2] | S[2];
    assign P[3] = R[3] | S[3];
    assign G[0] = R[0] & S[0];
    assign G[1] = R[1] & S[1];    
    assign G[2] = R[2] & S[2];
    assign G[3] = R[0] & S[3];    
    
    wire [3:0] P_Rn, G_Rn;      
    assign P_Rn[0] = (~R[0]) | S[0];
    assign P_Rn[1] = (~R[1]) | S[1];    
    assign P_Rn[2] = (~R[2]) | S[2];    
    assign P_Rn[3] = (~R[3]) | S[3];    
    assign G_Rn[0] = (~R[0]) & S[0];    
    assign G_Rn[1] = (~R[1]) & S[1];
    assign G_Rn[2] = (~R[2]) & S[2];    
    assign G_Rn[3] = (~R[3]) & S[3];   
    
    wire [3:0] P_Sn, G_Sn;
    assign P_Sn[0] = R[0] | (~S[0]);
    assign P_Sn[1] = R[1] | (~S[1]);
    assign P_Sn[2] = R[2] | (~S[2]);
    assign P_Sn[3] = R[3] | (~S[3]);    
    assign G_Sn[0] = R[0] & (~S[0]);
    assign G_Sn[1] = R[1] & (~S[1]);    
    assign G_Sn[2] = R[2] & (~S[2]);    
    assign G_Sn[3] = R[3] & (~S[3]);    
    
    wire C4;
    assign C4 = G[3] | P[3]&G[2] | P[3]&P[2]&G[1] | P[3]&P[2]&P[1]&G[0] | 
                 P[3]&P[2]&P[1]&P[0]&Cn;
    wire C3;
    assign C3 = G[2] | P[2]&G[1] | P[2]&P[1]&G[0] | P[2]&P[1]&P[0]&Cn;    
    
    always@(P or instruction or G or P_Rn or P_Sn or G_Rn)
    begin
        case(instruction)
            3'b000: Pneg = ~(P[3]&P[2]&P[1]&P[0]); 
            3'b001: Pneg = ~(P_Rn[3]&P_Rn[2]&P_Rn[1]&P_Rn[0]);
            3'b010: Pneg = ~(P_Sn[3]&P_Sn[2]&P_Sn[1]&P_Sn[0]);  
            3'b011, 3'b100, 3'b101: Pneg = 0;
            3'b110: Pneg = G_Rn[3] | G_Rn[2] | G_Rn[1] | G_Rn[0];
            3'b111: Pneg = G[3] | G[2] | G[1] | G[0];          
        endcase
    end
    
    always@(G or P or G_Rn or P_Rn or G_Sn or P_Sn or instruction)
    begin
        case(instruction)
            3'b000: Gneg = ~(G[3] | P[3]&G[2] | P[3]&P[2]&G[1] | P[3]&P[2]&P[1]&G[0]);
            3'b001: Gneg = ~(G_Rn[3] | P_Rn[3]&G_Rn[2] | P_Rn[3]&P_Rn[2]&G_Rn[1] | P_Rn[3]&P_Rn[2]&P_Rn[1]&G_Rn[0]);
            3'b010: Gneg = ~(G_Sn[3] | P_Sn[3]&G_Sn[2] | P_Sn[3]&P_Sn[2]&G_Sn[1] | P_Sn[3]&P_Sn[2]&P_Sn[1]&G_Sn[0]);
            3'b011: Gneg = P[3]&P[2]&P[1]&P[0];
            3'b100: Gneg = ~(G[3] | G[2] | G[1] | G[0]);
            3'b101: Gneg = ~(G_Rn[3] | G_Rn[2] | G_Rn[1] | G_Rn[0]);
            3'b110: Gneg = G_Rn[3] | P_Rn[3]&G_Rn[2] | P_Rn[3]&P_Rn[2]&G_Rn[1] | P_Rn[3]&P_Rn[2]&P_Rn[1]&P_Rn[0];
            3'b111: Gneg = G[3] | P[3]&G[2] | P[3]&P[2]&G[1] | P[3]&P[2]&P[1]&P[0];
        endcase
    end
    
    wire C_Rn4, C_Sn4;
    assign C_Rn4 = G_Rn[3] | P_Rn[3]&G_Rn[2] | P_Rn[3]&P_Rn[2]&G_Rn[1] | P_Rn[3]&P_Rn[2]&P_Rn[1]&G_Rn[0] | 
                 P_Rn[3]&P_Rn[2]&P_Rn[1]&P_Rn[0]&Cn;
    assign C_Sn4 = G_Sn[3] | P_Sn[3]&G_Sn[2] | P_Sn[3]&P_Sn[2]&G_Sn[1] | P_Sn[3]&P_Sn[2]&P_Sn[1]&G_Sn[0] | 
                 P_Sn[3]&P_Sn[2]&P_Sn[1]&P_Sn[0]&Cn;     
                         
    always@(C4 or C_Rn4 or C_Sn4 or Cn or instruction)
    begin
        case(instruction)
            3'b000: Cn4 = C4;
            3'b001: Cn4 = C_Rn4;
            3'b010: Cn4 = C_Sn4;
            3'b011: Cn4 = (~(P[3]&P[2]&P[1]&P[0])) | Cn;
            3'b100: Cn4 = G[3] | G[2] | G[1] | G[0] | Cn;
            3'b101: Cn4 = G_Rn[3] | G_Rn[2] | G_Rn[1] | G_Rn[0] | Cn;
            3'b110: Cn4 = ~(G_Rn[3] | P_Rn[3]&G_Rn[2] | P_Rn[3]&P_Rn[2]&G_Rn[1] | P_Rn[3]&P_Rn[2]&P_Rn[1]&P_Rn[0]&(G_Rn[0] | (~Cn)));
            4'b111: Cn4 = ~(G[3] | P[3]&G[2] | P[3]&P[2]&G[1] | P[3]&P[2]&P[1]&P[0]&(G[0] | (~Cn)));
        endcase
    end
    
    wire C_Rn3, C_Sn3;
    assign C_Rn3 = G_Rn[2] | P_Rn[2]&G_Rn[1] | P_Rn[2]&P_Rn[1]&G_Rn[0] | P_Rn[2]&P_Rn[1]&P_Rn[0]&Cn;
    assign C_Sn3 = G_Sn[2] | P_Sn[2]&G_Sn[1] | P_Sn[2]&P_Sn[1]&G_Sn[0] | P_Sn[2]&P_Sn[1]&P_Sn[0]&Cn;    
    
    always@(C3 or C_Rn3 or C_Sn3 or C4 or C_Rn4 or C_Sn4 or 
            G or G_Rn or P or P_Rn or instruction)
    begin
        case(instruction)
            3'b000: OVR = C3 ^ C4;
            3'b001: OVR = C_Rn3 ^ C_Rn4;
            3'b010: OVR = C_Sn3 ^ C_Sn4;
            3'b011: OVR = (~(P[3]&P[2]&P[1]&P[0])) | Cn;
            3'b100: OVR = G[3] | G[2] | G[1] | G[0] | Cn;
            3'b101: OVR = G_Rn[3] | G_Rn[2] | G_Rn[1] | G_Rn[0] | Cn;
            3'b110: OVR = ((~P_Rn[2]) | (~G_Rn[2])&(~P_Rn[1]) | (~G_Rn[2])&(~G_Rn[1])&(~P_Rn[0]) | (~G_Rn[2])&(~G_Rn[1])&(~G_Rn[0])&Cn) ^ 
                          ((~P_Rn[3]) | (~G_Rn[3])&(~P_Rn[2]) | (~G_Rn[3])&(~G_Rn[2])&(~P_Rn[1]) | (~G_Rn[3])&(~G_Rn[2])&(~G_Rn[1])&(~P_Rn[0]) | (~G_Rn[3])&(~G_Rn[2])&(~G_Rn[1])&(~G_Rn[0])&Cn);
            3'b111: OVR = ((~P[2]) | (~G[2])&(~P[1]) | (~G[2])&(~G[1])&(~P[0]) | (~G[2])&(~G[1])&(~G[0])&Cn) ^ 
                          ((~P[3]) | (~G[3])&(~P[2]) | (~G[3])&(~G[2])&(~P[1]) | (~G[3])&(~G[2])&(~G[1])&(~P[0]) | (~G[3])&(~G[2])&(~G[1])&(~G[0])&Cn);
        endcase
    end
    
    assign F_0 = ~(|F);
    assign F3 = F[3];
    
    always@(R or S or instruction)
    begin
        casex({instruction})
            3'b000: F = R + S + Cn;
            3'b001: F = S - R - Cn;
            3'b010: F = R - S - Cn;
            3'b011: F = R | S;
            3'b100: F = R & S;
            3'b101: F = (~R) & S;
            3'b110: F = R ^ S;
            3'b111: F = ~(R ^ S);
        endcase
    end 

endmodule

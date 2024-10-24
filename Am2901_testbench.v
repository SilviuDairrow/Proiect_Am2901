`timescale 1ns / 1ns

module Am2901_testbench(
    );
    
    reg CLK, Cn, RAM0_IN, RAM3_IN, Q0_IN, Q3_IN;
    reg [8:0] I;
    reg [3:0] A, B, DATAIN;
    wire Gneg, Pneg, Cn4, OVR, F_0, F3, RAM0_OUT, RAM3_OUT, Q0_OUT, Q3_OUT;
    wire [3:0] Y;
    wire RAM0_ENABLE, RAM3_ENABLE, Q0_ENABLE, Q3_ENABLE;
    
    Am2901_top am2901(
            .CLK(CLK), .A(A), .B(B), .DATAIN(DATAIN), .I(I),
            .Cn(Cn), .Y(Y), .Gneg(Gneg), .Pneg(Pneg), .Cn4(Cn4), .OVR(OVR),
            .F_0(F_0), .F3(F3), .RAM0_IN(RAM0_IN), .RAM3_IN(RAM3_IN), .Q0_IN(Q0_IN), .Q3_IN(Q3_IN),
            .RAM0_ENABLE(RAM0_ENABLE), .RAM0_OUT(RAM0_OUT),
            .RAM3_ENABLE(RAM3_ENABLE), .RAM3_OUT(RAM3_OUT), 
            .Q0_ENABLE(Q0_ENABLE), .Q0_OUT(Q0_OUT),
            .Q3_ENABLE(Q3_ENABLE), .Q3_OUT(Q3_OUT)
        );
    
    initial begin
        CLK = 0;
        A = 4'b0011;
        B = 4'b0001;
        DATAIN = 4'b1000;
        I = 9'b001_000_111; // la Y ar trebui sa fie DATAIN (valoarea 8)
        
        RAM0_IN = 0;
        RAM3_IN = 0; 
        Q0_IN = 0; 
        Q3_IN = 0;
        Cn = 0;             
        

        #4 I = 9'b011_000_111;
           B = 4'b0000;
           DATAIN = 4'b0010; // scrierea valorii 2 in locatia 0000 = 0

        #4 B = 4'b0001;
           DATAIN = 4'b0110; // scierea valorii 6 in locatia 0001 = 1

        #4 B = 4'b0010;
           DATAIN = 4'b0111; // scrierea valorii 7 in locatia 0010 = 2

        #4 I = 9'b000_000_111; // scrierea valorii 7 in registrul Q

        #4 I = 9'b001_000_010; // afiseaza continutul registrului Q in Y

        #4 I = 9'b011_000_000;
           A = 4'b0000;
           B = 4'b0011; // in locatia 0011 (B) = 3 scriem valoarea 2 + 7 (A + Q)
           
        #4 I = 9'b101_100_000; // Se face A si Q (2 si 7) => 2, apoi se shifteaza la dreapta 0010 (2) => se scrie la adresa B [0100] valoare 0001 
           A = 4'b0000; // se ia ce e in ram la adresa[0000] = 2 
           B = 4'b0100; // se scrie la adresa[0100] = 4 rezultatul
           //Q = 7 din scrierea anterioara
        
        #4 I = 9'b011_000_111; // scrierea valorii DATAIN la adresa B [0101]
           B = 4'b0101; // la adreasa [0101] = 5 se scrie valoarea DATAIN
           DATAIN = 4'b0000; // DATAIN = 0         
        
        #4 I = 9'b000_011_001;
           A = 4'b0010;
           B = 4'b0011; // in registrul Q se salveaza valoarea 7 OR 9 (A OR B) = F
        
        #4 I = 9'b111_011_000; // Se face A sau Q (0 sau F) = F (1111), apoi se shifteaza la stanga (1110) si rezultatul se pune la adresa B [0110] = 6 
           A = 4'b0101; // se ia val de la adresa [0101] = 0
           B = 4'b0110; // adresa la care se scrie [0110] = 6
           
           //                                        Q = 1111 =shiftat=> 0111 (7), DATAIN = 0110 =shiftat=> 0011 (3) 
        #4 I = 9'b100_000_111; // Se face shiftarea la dreapta la Q si DATAIN, DATAIN shiftat se pune la addr B [0111] = 7
           DATAIN = 4'b0111; // DATAIN = 7  
           B = 4'b0111; // Se scrie la adresa [0111] = 7
        
        #4 I = 9'b001_000_111; //  NOP cu afisare DATAIN pe Y
        
        #4 I = 9'b110_000_111; // shiftare la stanga la Q si DATAIN, DATAIN shiftat se pune la addr B [1000] = 8
           DATAIN = 4'b0110;
           B = 4'b1000; // Se scrie la adresa [1000] = 8
        
        #4 I = 9'b001_000_111; //  NOP cu afisare DATAIN pe Y   
    end    
        
    initial begin
        forever #2 CLK = ~CLK;
    end
endmodule
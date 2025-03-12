`timescale 1ns / 1ps



module ALU_reversible_m(

    input [31:0] A, B,         
    input [3:0] sel,           
    input Cin,                 
    output [31:0] F,         
    output Cout
);
    wire [31:0] carry;           
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin: alu_bits
            one_bit_reversible_alu ALU (
                .A(A[i]),
                .B(B[i]),
                .Cin((i == 0) ? Cin : carry[i-1]),
                .sel(sel),
                .out(F[i]),
                .cout(carry[i])
            );
        end
    endgenerate
    assign Cout = carry[31];
endmodule


module feynman_gate(
    input A, 
    output P, Q
);
    assign P = A;  
    assign Q = A ^ 1'b1;  
endmodule


module toffoli_gate(
    input A, B, C, 
    output P, Q, R
);
    assign P = A;
    assign Q = B;
    assign R = C ^ (A & B);  
endmodule


module peres_gate(
    input A, B, Cin, 
    output P, Q, R
);
    assign P = A;
    assign Q = A ^ B;     
    assign R = (A & B) ^ Cin; 
endmodule


module fredkin_gate(
    input S, A, B, 
    output P, Q, R
);
    assign P = A;  
    assign Q = S ? B : A;  
    assign R = S ? A : B;  
endmodule


module one_bit_reversible_alu(
    input A, B, Cin, 
    input [3:0] sel,          
    output out, 
    output cout
);
    wire and_operation, or_operation, xor_operation, add_operation, sub_operation, left_shift, right_shift;
    wire inc_a, dec_a, inc_b, dec_b, transfer_a, nand_operation, nor_operation, xnor_operation;
    wire peres_p, peres_q, peres_r;
    
   
    toffoli_gate toff1(.A(A), .B(B), .C(1'b0), .P(), .Q(), .R(and_operation));  
    toffoli_gate toff2(.A(A), .B(1'b1), .C(B), .P(), .Q(), .R(or_operation));   
    toffoli_gate toff3(.A(A), .B(B), .C(1'b0), .P(), .Q(), .R(xor_operation));  

    
    peres_gate peres1(.A(A), .B(B), .Cin(Cin), .P(peres_p), .Q(peres_q), .R(peres_r));
    assign add_operation = peres_q;
    assign cout = peres_r;

    // Subtraction (A - B = A + NOT(B) + 1)
    wire notB;
    feynman_gate feyn1(.A(B), .P(), .Q(notB));
    peres_gate peres2(.A(A), .B(notB), .Cin(Cin), .P(), .Q(sub_operation), .R());

    // Shift Operations
    fredkin_gate fred1(.S(sel[0]), .A(A), .B(B), .P(), .Q(left_shift), .R(right_shift));

   
    // Increment A (A + 1)
    peres_gate peres3(.A(A), .B(1'b1), .Cin(1'b0), .P(), .Q(inc_a), .R());

    // Decrement A (A - 1 = A + NOT(1) + 1)
    wire not_one;
    feynman_gate feyn2(.A(1'b1), .P(), .Q(not_one));
    peres_gate peres4(.A(A), .B(not_one), .Cin(1'b1), .P(), .Q(dec_a), .R());

    // Increment B (B + 1)
    peres_gate peres5(.A(B), .B(1'b1), .Cin(1'b0), .P(), .Q(inc_b), .R());

    // Decrement B (B - 1 = B + NOT(1) + 1)
    peres_gate peres6(.A(B), .B(not_one), .Cin(1'b1), .P(), .Q(dec_b), .R());

    // Transfer A (Output A directly)
    assign transfer_a = A;

    // NAND Operation (NOT(A AND B))
    wire and_temp;
    toffoli_gate toff7(.A(A), .B(B), .C(1'b0), .P(), .Q(), .R(and_temp));
    feynman_gate feyn3(.A(and_temp), .P(), .Q(nand_operation));

    // NOR Operation (NOT(A OR B))
    wire or_temp;
    toffoli_gate toff8(.A(A), .B(1'b1), .C(B), .P(), .Q(), .R(or_temp));
    feynman_gate feyn4(.A(or_temp), .P(), .Q(nor_operation));

    // XNOR Operation (NOT(A XOR B))
    wire xor_temp;
    toffoli_gate toff9(.A(A), .B(B), .C(1'b0), .P(), .Q(), .R(xor_temp));
    feynman_gate feyn5(.A(xor_temp), .P(), .Q(xnor_operation));

    
    assign out = (sel == 4'b0000) ? and_operation   : 
                 (sel == 4'b0001) ? or_operation    :
                 (sel == 4'b0010) ? xor_operation   :
                 (sel == 4'b0011) ? add_operation   :
                 (sel == 4'b0100) ? sub_operation   :
                 (sel == 4'b0101) ? left_shift      :
                 (sel == 4'b0110) ? right_shift     :
                 (sel == 4'b0111) ? inc_a           : 
                 (sel == 4'b1000) ? dec_a           : 
                 (sel == 4'b1001) ? inc_b           : 
                 (sel == 4'b1010) ? dec_b           : 
                 (sel == 4'b1011) ? transfer_a      : 
                 (sel == 4'b1100) ? nand_operation  : 
                 (sel == 4'b1101) ? nor_operation   : 
                 (sel == 4'b1110) ? xnor_operation  : 
                 1'b0;                               

endmodule

`line 2 "top.tlv" 0
//_\SV
   // This code can be found in: https://github.com/stevehoover/RISC-V_MYTH_Workshop
   
   // Included URL: "https://raw.githubusercontent.com/BalaDhinesh/RISC-V_MYTH_Workshop/master/tlv_lib/risc-v_shell_lib.tlv"// Included URL: "https://raw.githubusercontent.com/stevehoover/warp-v_includes/2d6d36baa4d2bc62321f982f78c8fe1456641a43/risc-v_defs.tlv"

//_\SV
   module top(input wire clk, input wire reset, input wire [31:0] cyc_cnt, output wire passed, output wire failed);    /* verilator lint_save */ /* verilator lint_off UNOPTFLAT */  bit [256:0] RW_rand_raw; bit [256+63:0] RW_rand_vect; pseudo_rand #(.WIDTH(257)) pseudo_rand (clk, reset, RW_rand_raw[256:0]); assign RW_rand_vect[256+63:0] = {RW_rand_raw[62:0], RW_rand_raw};  /* verilator lint_restore */  /* verilator lint_off WIDTH */ /* verilator lint_off UNOPTFLAT */   // (Expanded in Nav-TLV pane.)
`include "top_gen.sv" //_\TLV

   // /====================\
   // | Sum 1 to 9 Program |
   // \====================/
   //
   // Program for MYTH Workshop to test RV32I
   // Add 1,2,3,...,9 (in that order).
   //
   // Regs:
   //  r10 (a0): In: 0, Out: final sum
   //  r12 (a2): 10
   //  r13 (a3): 1..10
   //  r14 (a4): Sum
   // 
   // External to function:
   // Inst #0: ADD,r10,r0,r0             // Initialize r10 (a0) to 0.
   // Function:
   // Inst #1: ADD,r14,r10,r0            // Initialize sum register a4 with 0x0
   // Inst #2: ADDI,r12,r10,1010         // Store count of 10 in register a2.
   // Inst #3: ADD,r13,r10,r0            // Initialize intermediate sum register a3 with 0
   // Loop:
   // Inst #4: ADD,r14,r13,r14           // Incremental addition
   // Inst #5: ADDI,r13,r13,1            // Increment intermediate register by 1
   // Inst #6: BLT,r13,r12,1111111111000 // If a3 is less than a2, branch to label named <loop>
   // Inst #7: ADD,r10,r14,r0            // Store final result to register a0 so that it can be read by main program
   // Inst #8: SW,r0,r10,100             // Store
   // Inst #9: LW,r15,r0,100             // Load to x15 reg
   
   // Optional:
   // Inst #10: JAL,r7,00000000000000000000 // Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
   

   // Complete MYTH RISC-V CPU
   //_|cpu
      //_@0
         assign CPU_reset_a0 = reset;
         // Next PC
         assign CPU_pc_a0[31:0] = CPU_reset_a1 ? '0 : CPU_valid_taken_br_a3 ? CPU_br_tgt_pc_a3 : CPU_valid_load_a3 ? CPU_inc_pc_a3 : CPU_valid_jump_a3 && CPU_is_jal_a3 ? CPU_br_tgt_pc_a3 :CPU_valid_jump_a3 && CPU_is_jalr_a3 ? CPU_jalr_tgt_pc_a3 : CPU_inc_pc_a1;
                     
         assign CPU_imem_rd_en_a0 = !CPU_reset_a0;
         assign CPU_imem_rd_addr_a0[4-1:0] = CPU_pc_a0[4+1:2];
      //_@1
         assign CPU_inc_pc_a1[31:0] = CPU_pc_a1 + 32'd4;
         
         assign CPU_instr_a1[31:0] = CPU_imem_rd_data_a1[31:0];
         
         // Instruction Types Decode
         assign CPU_is_i_instr_a1 = CPU_instr_a1[6:2] ==? 5'b0000x ||
                       CPU_instr_a1[6:2] ==? 5'b001x0 ||
                       CPU_instr_a1[6:2] ==? 5'b11001 ||
                       CPU_instr_a1[6:2] ==? 5'b00100;
         
         assign CPU_is_r_instr_a1 = CPU_instr_a1[6:2] ==? 5'b01011 ||
                       CPU_instr_a1[6:2] ==? 5'b011x0 ||
                       CPU_instr_a1[6:2] ==? 5'b10100;
         
         assign CPU_is_s_instr_a1 = CPU_instr_a1[6:2] ==? 5'b0100x;
         
         assign CPU_is_b_instr_a1 = CPU_instr_a1[6:2] ==? 5'b11000;
         
         assign CPU_is_j_instr_a1 = CPU_instr_a1[6:2] ==? 5'b11011;
         
         assign CPU_is_u_instr_a1 = CPU_instr_a1[6:2] ==? 5'b0x101;
         
         // Instruction Immediate Decode
         assign CPU_imm_a1[31:0] = CPU_is_i_instr_a1 ? { {21{CPU_instr_a1[31]}}, CPU_instr_a1[30:20] } :
                      CPU_is_s_instr_a1 ? { {21{CPU_instr_a1[31]}}, CPU_instr_a1[30:25], CPU_instr_a1[11:7] } :
                      CPU_is_b_instr_a1 ? { {20{CPU_instr_a1[31]}}, CPU_instr_a1[7], CPU_instr_a1[31:25], CPU_instr_a1[11:8], 1'b0 } :
                      CPU_is_u_instr_a1 ? { CPU_instr_a1[31:12] , 12'b0 } :
                      CPU_is_j_instr_a1 ? { {12{CPU_instr_a1[31]}}, CPU_instr_a1[19:12], CPU_instr_a1[20], CPU_instr_a1[30:21], 1'b0 } :
                      32'b0 ;

         // Instruction Decode and RISC-V Instruction Field Decode
         assign CPU_funct7_valid_a1 = CPU_is_r_instr_a1;
         //_?$funct7_valid
            assign CPU_funct7_a1[6:0] = CPU_instr_a1[31:25];
            
         assign CPU_rs2_valid_a1 = CPU_is_r_instr_a1 || CPU_is_s_instr_a1 || CPU_is_b_instr_a1;
         //_?$rs2_valid
            assign CPU_rs2_a1[4:0] = CPU_instr_a1[24:20];
         
         assign CPU_rs1_valid_a1 = CPU_is_r_instr_a1 || CPU_is_i_instr_a1 || CPU_is_s_instr_a1 || CPU_is_b_instr_a1;
         //_?$rs1_valid
            assign CPU_rs1_a1[4:0] = CPU_instr_a1[19:15];
            
         assign CPU_funct3_valid_a1 = CPU_is_r_instr_a1 || CPU_is_i_instr_a1 || CPU_is_s_instr_a1 || CPU_is_b_instr_a1;
         //_?$funct3_valid
            assign CPU_funct3_a1[2:0] = CPU_instr_a1[14:12];
            
         assign CPU_rd_valid_a1 =  CPU_is_r_instr_a1 || CPU_is_i_instr_a1 || CPU_is_u_instr_a1 || CPU_is_j_instr_a1;
         //_?$rd_valid
            assign CPU_rd_a1[4:0] = CPU_instr_a1[11:7];
         
         assign CPU_opcode_a1[6:0] = CPU_instr_a1[6:0];
         
         // Rest of Instruction Decode
         assign CPU_dec_bits_a1[10:0] = {CPU_funct7_a1[5],CPU_funct3_a1,CPU_opcode_a1};
         assign CPU_is_beq_a1  = CPU_dec_bits_a1 ==? 11'bx_000_1100011;
         assign CPU_is_bne_a1  = CPU_dec_bits_a1 ==? 11'bx_001_1100011;
         assign CPU_is_blt_a1  = CPU_dec_bits_a1 ==? 11'bx_100_1100011;
         assign CPU_is_bge_a1  = CPU_dec_bits_a1 ==? 11'bx_101_1100011;
         assign CPU_is_bltu_a1 = CPU_dec_bits_a1 ==? 11'bx_110_1100011;
         assign CPU_is_bgeu_a1 = CPU_dec_bits_a1 ==? 11'bx_000_1100011;
         
         assign CPU_is_add_a1  = CPU_dec_bits_a1 ==? 11'bx_000_0110011;
         assign CPU_is_addi_a1 = CPU_dec_bits_a1 ==? 11'bx_000_0010011;
         
         assign CPU_is_lui_a1    = CPU_dec_bits_a1 ==? 11'bx_xxx_0110111;
         assign CPU_is_auipc_a1  = CPU_dec_bits_a1 ==? 11'bx_xxx_0010111;
         
         assign CPU_is_jal_a1    = CPU_dec_bits_a1 ==? 11'bx_xxx_1101111;
         assign CPU_is_jalr_a1   = CPU_dec_bits_a1 ==? 11'bx_000_1100111;
         
         assign CPU_is_sb_a1     = CPU_dec_bits_a1 ==? 11'bx_000_0100011;
         assign CPU_is_sh_a1     = CPU_dec_bits_a1 ==? 11'bx_001_0100011;
         assign CPU_is_sw_a1     = CPU_dec_bits_a1 ==? 11'bx_010_0100011;
         
         assign CPU_is_slti_a1   = CPU_dec_bits_a1 ==? 11'bx_010_0010011;
         
         assign CPU_is_sltiu_a1  = CPU_dec_bits_a1 ==? 11'bx_011_0010011;
         assign CPU_is_xori_a1   = CPU_dec_bits_a1 ==? 11'bx_100_0010011;
         assign CPU_is_ori_a1    = CPU_dec_bits_a1 ==? 11'bx_110_0010011;
         assign CPU_is_andi_a1   = CPU_dec_bits_a1 ==? 11'bx_111_0010011;
         assign CPU_is_slli_a1   = CPU_dec_bits_a1 ==? 11'b0_001_0010011;
         assign CPU_is_srli_a1   = CPU_dec_bits_a1 ==? 11'b0_101_0010011;
         assign CPU_is_srai_a1   = CPU_dec_bits_a1 ==? 11'b1_101_0010011;
         
         assign CPU_is_sub_a1    = CPU_dec_bits_a1 ==? 11'b1_000_0110011;
         assign CPU_is_sll_a1    = CPU_dec_bits_a1 ==? 11'b0_001_0110011;
         assign CPU_is_slt_a1    = CPU_dec_bits_a1 ==? 11'b0_010_0110011;
         assign CPU_is_sltu_a1   = CPU_dec_bits_a1 ==? 11'b0_011_0110011;
         assign CPU_is_xor_a1    = CPU_dec_bits_a1 ==? 11'b0_100_0110011;
         assign CPU_is_srl_a1    = CPU_dec_bits_a1 ==? 11'b0_101_0110011;
         assign CPU_is_sra_a1    = CPU_dec_bits_a1 ==? 11'b1_101_0110011;
         assign CPU_is_or_a1     = CPU_dec_bits_a1 ==? 11'b0_110_0110011;
         assign CPU_is_and_a1    = CPU_dec_bits_a1 ==? 11'b0_111_0110011;
         
         assign CPU_is_load_a1 = CPU_opcode_a1 == 7'b0000011;

         
         //`BOGUS_USE($is_beq $is_bne $is_blt $is_bge $is_bltu $is_bgeu $is_add $is_addi)
         // Testbench
         assign passed = CPU_Xreg_value_a6[15] == (1+2+3+4+5+6+7+8+9);
      //_@2
         // Register File Read
         assign CPU_rf_rd_en1_a2 = CPU_rs1_valid_a2; // oops corrected: was enl should be en1
         assign CPU_rf_rd_en2_a2 = CPU_rs2_valid_a2;
         assign CPU_rf_rd_index1_a2[4:0] = CPU_rs1_a2;
         assign CPU_rf_rd_index2_a2[4:0] = CPU_rs2_a2;
 
         //$src1_value[31:0] = (>>1$rf_wr_index == $rf_rd_index1) && >>1$rf_wr_en ? >>1$result : $rf_rd_data1;
         assign CPU_src1_value_a2[31:0] = (CPU_rf_wr_index_a3 == CPU_rf_rd_index1_a2) && CPU_rf_wr_en_a3 ? CPU_rf_wr_data_a3 : CPU_rf_rd_data1_a2;
         //$src2_value[31:0] = (>>1$rf_wr_index == $rf_rd_index2) && >>1$rf_wr_en ? >>1$result : $rf_rd_data2;
         assign CPU_src2_value_a2[31:0] = (CPU_rf_wr_index_a3 == CPU_rf_rd_index2_a2) && CPU_rf_wr_en_a3 ? CPU_rf_wr_data_a3 : CPU_rf_rd_data2_a2;
         
         assign CPU_br_tgt_pc_a2[31:0] = CPU_pc_a2 + CPU_imm_a2;
         
      //_@3
         // ALU
         assign CPU_sltu_rslt_a3    = CPU_src1_value_a3 < CPU_src2_value_a3;
         assign CPU_sltiu_rslt_a3   = CPU_src1_value_a3 < CPU_imm_a3;
         assign CPU_result_a3[31:0] = CPU_is_addi_a3    ? CPU_src1_value_a3 + CPU_imm_a3 :
                         CPU_is_add_a3     ? CPU_src1_value_a3 + CPU_src2_value_a3 :
                         CPU_is_lui_a3     ? {CPU_imm_a3[31:12], 12'b0} :
                         CPU_is_auipc_a3   ? CPU_pc_a3 + CPU_imm_a3 :
                         CPU_is_jal_a3     ? CPU_pc_a3 + 32'd4 :
                         CPU_is_jalr_a3    ? CPU_pc_a3 + 32'd4 :
                         CPU_is_load_a3    ? CPU_src1_value_a3 + CPU_imm_a3:
                         CPU_is_s_instr_a3 ? CPU_src1_value_a3 + CPU_imm_a3:
                         CPU_is_addi_a3    ? CPU_src1_value_a3 + CPU_imm_a3:
                         CPU_is_slti_a3    ? ((CPU_src1_value_a3[31] == CPU_imm_a3[31]) ? CPU_sltiu_rslt_a3 : {31'b0, CPU_src1_value_a3[31]}) :
                         CPU_is_sltiu_a3   ? CPU_sltiu_rslt_a3:
                         CPU_is_xori_a3    ? CPU_src1_value_a3 ^ CPU_imm_a3 :
                         CPU_is_ori_a3     ? CPU_src1_value_a3 | CPU_imm_a3 :
                         CPU_is_slli_a3    ? CPU_src1_value_a3 << CPU_imm_a3[5:0] :
                         CPU_is_srli_a3    ? CPU_src1_value_a3 >> CPU_imm_a3[5:0] :
                         CPU_is_srai_a3    ? {{32{CPU_src1_value_a3[31]}}, CPU_src1_value_a3} >> CPU_imm_a3[4:0] :
                         CPU_is_sub_a3     ? CPU_src1_value_a3 - CPU_src2_value_a3 :
                         CPU_is_sll_a3     ? CPU_src1_value_a3 << CPU_src2_value_a3[4:0] :
                         CPU_is_slt_a3     ? ((CPU_src1_value_a3[31] == CPU_src2_value_a3[31]) ? CPU_sltu_rslt_a3 : {31'b0, CPU_src1_value_a3[31]}) :
                         CPU_is_sltu_a3    ? CPU_sltu_rslt_a3 :
                         CPU_is_xor_a3     ? CPU_src1_value_a3 ^ CPU_src2_value_a3 :
                         CPU_is_srl_a3     ? CPU_src1_value_a3 >> CPU_src2_value_a3[4:0] :
                         CPU_is_sra_a3     ? {{32{CPU_src1_value_a3[31]}}, CPU_src1_value_a3} >> CPU_src2_value_a3[4:0] :
                         CPU_is_or_a3      ? CPU_src1_value_a3 | CPU_src2_value_a3 :
                         CPU_is_and_a3     ? CPU_src1_value_a3 & CPU_src2_value_a3 :
                         32'bx;
         
         // Register File Write
         assign CPU_rf_wr_en_a3 = (CPU_rd_valid_a3 && CPU_rd_a3 != 5'b0 && CPU_valid_a3) || CPU_valid_load_a5;
         assign CPU_rf_wr_index_a3[4:0] = CPU_valid_load_a5 ? CPU_rd_a5 : CPU_rd_a3;
         assign CPU_rf_wr_data_a3[31:0] = CPU_valid_load_a5 ? CPU_ld_data_a5 : CPU_result_a3;
         
         // Branches
         assign CPU_taken_br_a3 = CPU_is_beq_a3 ? (CPU_src1_value_a3 == CPU_src2_value_a3) :
                     CPU_is_bne_a3 ? (CPU_src1_value_a3 != CPU_src2_value_a3) :
                     CPU_is_blt_a3 ? ((CPU_src1_value_a3 < CPU_src2_value_a3) ^ (CPU_src1_value_a3[31] != CPU_src2_value_a3[31])):
                     CPU_is_bge_a3 ? ((CPU_src1_value_a3 >= CPU_src2_value_a3) ^ (CPU_src1_value_a3[31]!=  CPU_src2_value_a3[31])) :
                     CPU_is_bltu_a3 ? (CPU_src1_value_a3 < CPU_src2_value_a3) :
                     CPU_is_bgeu_a3 ? (CPU_src1_value_a3 >= CPU_src2_value_a3) : 1'b0;
                     
         // 3-Cycle RISC-V 1
         assign CPU_valid_taken_br_a3 = CPU_valid_a3 && CPU_taken_br_a3;
         
         // Redirect Loads
         assign CPU_valid_a3 = !(CPU_valid_taken_br_a4 || CPU_valid_taken_br_a5 || CPU_valid_load_a4 || CPU_valid_load_a5 || CPU_valid_jump_a4 || CPU_valid_jump_a5);
         assign CPU_valid_load_a3 = CPU_valid_a3 && CPU_is_load_a3;
         
         // Jump
         assign CPU_is_jump_a3 = CPU_is_jal_a3 || CPU_is_jalr_a3;
         assign CPU_valid_jump_a3 = CPU_is_jump_a3 && CPU_valid_a3;
         assign CPU_jalr_tgt_pc_a3 = CPU_src1_value_a3 + CPU_imm_a3;
         
      
         // Load data
      //_@4
         assign CPU_dmem_wr_en_a4 = CPU_valid_a4 && CPU_is_s_instr_a4;
         assign CPU_dmem_addr_a4[3:0] = CPU_result_a4[5:2];
         assign CPU_dmem_wr_data_a4[31:0] = CPU_src2_value_a4;
         assign CPU_dmem_rd_en_a4 = CPU_is_load_a4 ;
         
      //_@5
         // Load Data 2
         assign CPU_ld_data_a5[31:0] = CPU_dmem_rd_data_a5[31:0];
         
         

      // Note: Because of the magic we are using for visualisation, if visualisation is enabled below,
      //       be sure to avoid having unassigned signals (which you might be using for random inputs)
      //       other than those specifically expected in the labs. You'll get strange errors for these.

   
   // Assert these to end simulation (before Makerchip cycle limit).
   assign passed = cyc_cnt > 40;
   assign failed = 1'b0;
   
   // Macro instantiations for:
   //  o instruction memory
   //  o register file
   //  o data memory
   //  o CPU visualization
   //_|cpu
      `line 20 "/raw.githubusercontent.com/BalaDhinesh/RISCVMYTHWorkshop/master/tlvlib/riscvshelllib.tlv" 1
         // Instruction Memory containing program defined by m4_asm(...) instantiations.
         //_@1
            
            /*SV_plus*/
               // The program in an instruction memory.
               logic [31:0] instrs [0:11-1];
               assign instrs = '{
                  {7'b0000000, 5'd0, 5'd0, 3'b000, 5'd10, 7'b0110011}, {7'b0000000, 5'd0, 5'd10, 3'b000, 5'd14, 7'b0110011}, {12'b1010, 5'd10, 3'b000, 5'd12, 7'b0010011}, {7'b0000000, 5'd0, 5'd10, 3'b000, 5'd13, 7'b0110011}, {7'b0000000, 5'd14, 5'd13, 3'b000, 5'd14, 7'b0110011}, {12'b1, 5'd13, 3'b000, 5'd13, 7'b0010011}, {1'b1, 6'b111111, 5'd12, 5'd13, 3'b100, 4'b1100, 1'b1, 7'b1100011}, {7'b0000000, 5'd0, 5'd14, 3'b000, 5'd10, 7'b0110011}, {7'b0000000, 5'd10, 5'd0, 3'b010, 5'b00100, 7'b0100011}, {12'b100, 5'd0, 3'b010, 5'd15, 7'b0000011}, {1'b0, 10'b0000000000, 1'b0, 8'b00000000, 5'd7, 7'b1101111}
               };
            for (imem = 0; imem <= 10; imem++) begin : L1_CPU_Imem //_/imem
               assign CPU_Imem_instr_a1[imem][31:0] = instrs[imem]; end
            //_?$imem_rd_en
               assign CPU_imem_rd_data_a1[31:0] = CPU_Imem_instr_a1[CPU_imem_rd_addr_a1];
            
            
            
               
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
                              
              
          
      //_\end_source    // Args: (read stage)
      `line 253 "top.tlv" 2
      `line 75 "/raw.githubusercontent.com/BalaDhinesh/RISCVMYTHWorkshop/master/tlvlib/riscvshelllib.tlv" 1
         // Reg File
         //_@3
            for (xreg = 0; xreg <= 31; xreg++) begin : L1_CPU_Xreg logic L1_wr_a3; //_/xreg
               assign L1_wr_a3 = CPU_rf_wr_en_a3 && (CPU_rf_wr_index_a3 != 5'b0) && (CPU_rf_wr_index_a3 == xreg);
               assign CPU_Xreg_value_a3[xreg][31:0] = CPU_reset_a3 ?   xreg           :
                              L1_wr_a3        ?   CPU_rf_wr_data_a3 :
                                             CPU_Xreg_value_a4[xreg][31:0]; end
         //_@2
            //_?$rf_rd_en1
               assign CPU_rf_rd_data1_a2[31:0] = CPU_Xreg_value_a4[CPU_rf_rd_index1_a2];
            //_?$rf_rd_en2
               assign CPU_rf_rd_data2_a2[31:0] = CPU_Xreg_value_a4[CPU_rf_rd_index2_a2];
            `BOGUS_USE(CPU_rf_rd_data1_a2 CPU_rf_rd_data2_a2) 
      //_\end_source  // Args: (read stage, write stage) - if equal, no register bypass is required
      `line 254 "top.tlv" 2
      `line 92 "/raw.githubusercontent.com/BalaDhinesh/RISCVMYTHWorkshop/master/tlvlib/riscvshelllib.tlv" 1
         // Data Memory
         //_@4
            for (dmem = 0; dmem <= 15; dmem++) begin : L1_CPU_Dmem logic L1_wr_a4; //_/dmem
               assign L1_wr_a4 = CPU_dmem_wr_en_a4 && (CPU_dmem_addr_a4 == dmem);
               assign CPU_Dmem_value_a4[dmem][31:0] = CPU_reset_a4 ?   dmem :
                              L1_wr_a4        ?   CPU_dmem_wr_data_a4 :
                                             CPU_Dmem_value_a5[dmem][31:0]; end
                                        
            //_?$dmem_rd_en
               assign CPU_dmem_rd_data_a4[31:0] = CPU_Dmem_value_a5[CPU_dmem_addr_a4];
            `BOGUS_USE(CPU_dmem_rd_data_a4)
      //_\end_source    // Args: (read/write stage)
      `line 255 "top.tlv" 2

   //m4+cpu_viz(@4)    // For visualisation, argument should be at least equal to the last stage of CPU logic. @4 would work for all labs.
//_\SV
   endmodule


// Undefine macros defined by SandPiper (in "top_gen.sv").
`undef BOGUS_USE

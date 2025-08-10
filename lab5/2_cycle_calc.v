\m5_TLV_version 1d: tl-x.org
\m5
   
   // ============================================
   // Welcome, new visitors! Try the "Learn" menu.
   // ============================================
   
   //use(m5-1.0)   /// uncomment to use M5 macro library.
\SV
   // Macro providing required top-level module definition, random
   // stimulus support, and Verilator config.
   m5_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV
   // 2 cycle Calc in Pipeline
   |pipe_calc
      @1
         $valid = $reset ? 0 : (>>1$valid + 1);
         $reset_or_notvalid = $reset || $valid;
      ?$reset_or_notvalid
         
         @1
            $reset = *reset;

            $val1[31:0] = $rand1[3:0];
            $val2[31:0] = $rand2[3:0];
            $op[1:0] = $rand3[1:0];

            $sum[31:0] = $val1 + $val2;
            $diff[31:0] = $val1 - $val2;
            $prod[31:0] = $val1 * $val2;
            $quot[31:0] = $val1 / $val2;
         @2
            $out[31:0] = ($op == 2'b00) ? $sum[31:0] : ($op == 2'b01) ? $diff[31:0]:
                         ($op == 2'b10 ) ? $prod[31:0] : $quot[31:0];

   // Assert these to end simulation (before the cycle limit).
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule

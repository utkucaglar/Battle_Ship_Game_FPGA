module top (
  input clk,               
  input [3:0] sw,          
  input [3:0] btn,         
  output [7:0] led,        
  output [7:0] seven,      
  output [3:0] segment     
);

  wire divided_clk;        // Slow clock output from clk_divider
  wire cleaned_reset;      // Debounced reset signal
  wire cleaned_start;      // Debounced start signal
  wire cleaned_pAb;        // Debounced Player A button
  wire cleaned_pBb;        // Debounced Player B button
  wire [7:0] disp0, disp1, disp2, disp3; // SSD inputs from battleship

  // Clock Divider
  clk_divider clk_div_inst (
    .clk_in(clk),
    .divided_clk(divided_clk)
  );

  // Debouncer for Reset
  debouncer rst_db (
    .clk(divided_clk),
    .rst(1'b0),
    .noisy_in(btn[2]),
    .clean_out(cleaned_reset)
  );

  // Debouncer for Start
  debouncer start_db (
    .clk(divided_clk),
    .rst(1'b0),
    .noisy_in(btn[1]),
    .clean_out(cleaned_start)
  );

  // Debouncer for Player A Button
  debouncer pAb_db (
    .clk(divided_clk),
    .rst(1'b0),
    .noisy_in(btn[3]),
    .clean_out(cleaned_pAb)
  );

  // Debouncer for Player B Button
  debouncer pBb_db (
    .clk(divided_clk),
    .rst(1'b0),
    .noisy_in(btn[0]),
    .clean_out(cleaned_pBb)
  );

  // Battleship Module
  battleship battleship_inst (
    .clk(divided_clk),
    .rst(cleaned_reset),
    .start(cleaned_start),
    .X(sw[3:2]),
    .Y(sw[1:0]),
    .pAb(cleaned_pAb),
    .pBb(cleaned_pBb),
    .disp0(disp0),
    .disp1(disp1),
    .disp2(disp2),
    .disp3(disp3),
    .led(led)
  );

  // SSD Module
  ssd ssd_inst (
    .clk(clk),
    .disp0(disp0),
    .disp1(disp1),
    .disp2(disp2),
    .disp3(disp3),
    .seven(seven),
    .segment(segment)
  );

endmodule

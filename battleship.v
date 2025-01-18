module battleship (
  input clk,              
  input rst,              
  input start,            
  input [1:0] X,          
  input [1:0] Y,          
  input pAb,             
  input pBb,              
  output reg [7:0] disp0,
  output reg [7:0] disp1, 
  output reg [7:0] disp2, 
  output reg [7:0] disp3, 
  output reg [7:0] led    
);

  // Defining states for the finite state machine (FSM).
  parameter IDLE         = 4'd0,  // Waiting for game to start.
            INPUT_A      = 4'd1,  // Player A places their ships.
            INPUT_B      = 4'd2,  // Player B places their ships.
            ERROR_A      = 4'd3,  // Error state for Player A.
            ERROR_B      = 4'd4,  // Error state for Player B.
            SHOW_SCORE   = 4'd5,  // Display the current score.
            SHOOT_A      = 4'd6,  // Player A takes a shot.
            SHOOT_B      = 4'd7,  // Player B takes a shot.
            SHOW_SCORE_FIRST = 4'd8,  // Evaluate if the shot was a hit.
            WINNER       = 4'd9;  // Display the winner and end the game.

  // Declaring registers to store ship positions for each player.
  reg [3:0] playerA_ship_0, playerA_ship_1, playerA_ship_2, playerA_ship_3; // Ships of Player A.
  reg [3:0] playerB_ship_0, playerB_ship_1, playerB_ship_2, playerB_ship_3; // Ships of Player B.
  
  // Registers to count the number of inputs (ships placed) by each player.
  reg [1:0] input_count_A, input_count_B; // Number of ships placed by Player A and B.

  // Flags to indicate destroyed ships for each player.
  reg playerA_destroyed_0, playerA_destroyed_1, playerA_destroyed_2, playerA_destroyed_3;
  reg playerB_destroyed_0, playerB_destroyed_1, playerB_destroyed_2, playerB_destroyed_3;

  // Flag to detect overlapping ship positions during placement.
  reg overlap_detector;

  // Turn indicator: 0 = Player A, 1 = Player B.
  reg turn;

  // Flag to indicate if a hit occurred during a shot.
  reg hit_flag;

  // Registers for FSM state tracking.
  reg [3:0] current_state, next_state;

  // Counters for error and score display delays.
  reg [31:0] error_counter;       // Counter for delay during error states.
  localparam ERROR_WAIT = 50;     // Duration of error state (1 second at 50 Hz clock).
  reg [31:0] show_score_delay;    // Counter for delay during score display.
  localparam SCORE_WAIT = 50;     // Duration of score display (1 second).

  // Registers for player scores and win flags.
  reg [2:0] scoreA, scoreB;       // Scores for Player A and Player B.

  // Counter for WINNER state LED animation delay.
  reg [15:0] delay_cnt_error_and_winner; // Counter for winner animation.
  localparam WINNER_LEDS = 14;           // Duration of winner LED animation.

  // Encoding for seven-segment display (SSD) characters.
  reg [7:0] ssd_encode [0:15];
  initial begin
    ssd_encode[0]  = 8'b00111111; // "0"
    ssd_encode[1]  = 8'b00000110; // "1"
    ssd_encode[2]  = 8'b01011011; // "2"
    ssd_encode[3]  = 8'b01001111; // "3"
    ssd_encode[4]  = 8'b01100110; // "4"
    ssd_encode[5]  = 8'b00000110; // "I"
    ssd_encode[6]  = 8'b01011110; // "d"
    ssd_encode[7]  = 8'b00111000; // "L"
    ssd_encode[8]  = 8'b01111001; // "E"
    ssd_encode[9]  = 8'b01101111; // "9"
    ssd_encode[10] = 8'b01110111; // "A"
    ssd_encode[11] = 8'b01111100; // "b"
    ssd_encode[12] = 8'b01010000; // "r"
    ssd_encode[13] = 8'b01011100; // "o"
    ssd_encode[14] = 8'b01000000; // "-"
    ssd_encode[15] = 8'b01110001; // "F"
  end

// Sequential logic for FSM, handling state transitions and variable updates.
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Reset all game variables and state to initial values.
      input_count_A <= 0;       // Reset Player A's ship placement count.
      input_count_B <= 0;       // Reset Player B's ship placement count.

      playerA_ship_0 <= 4'b1111; playerA_ship_1 <= 4'b1111; // Initialize Player A's ship positions.
      playerA_ship_2 <= 4'b1111; playerA_ship_3 <= 4'b1111;

      playerB_ship_0 <= 4'b1111; playerB_ship_1 <= 4'b1111; // Initialize Player B's ship positions.
      playerB_ship_2 <= 4'b1111; playerB_ship_3 <= 4'b1111;

      playerA_destroyed_0 <= 0; playerA_destroyed_1 <= 0;  // Reset destroyed ship flags for Player A.
      playerA_destroyed_2 <= 0; playerA_destroyed_3 <= 0;
      
      playerB_destroyed_0 <= 0; playerB_destroyed_1 <= 0;  // Reset destroyed ship flags for Player B.
      playerB_destroyed_2 <= 0; playerB_destroyed_3 <= 0;

      scoreA <= 0; scoreB <= 0;                            // Reset scores.

      hit_flag <= 0; turn <= 0;                            // Reset hit flag and start with Player A's turn.

      error_counter <= 0; show_score_delay <= 0;           // Reset delay counters.
      delay_cnt_error_and_winner <= 0;                     // Reset winner animation counter.

      current_state <= IDLE;                               // Start in the IDLE state.

    end 
    else begin
      // FSM behavior based on current state.
        case (current_state)
            IDLE: begin
                if (start) begin
                    hit_flag <= 0;
                    current_state <= INPUT_A;
                end
            end

            INPUT_A: begin
                if (pAb && !overlap_detector && input_count_A < 4) begin
                    case (input_count_A)
                        2'b00: playerA_ship_0 <= {X, Y};
                        2'b01: playerA_ship_1 <= {X, Y};
                        2'b10: playerA_ship_2 <= {X, Y};
                        2'b11: playerA_ship_3 <= {X, Y};
                    endcase
                    input_count_A <= input_count_A + 1;
                    if (input_count_A == 3) current_state <= INPUT_B;
                end else if (pAb && overlap_detector) begin
                    current_state <= ERROR_A;
                end
            end

            INPUT_B: begin
                if (pBb && !overlap_detector && input_count_B < 4) begin
                    case (input_count_B)
                        2'b00: playerB_ship_0 <= {X, Y};
                        2'b01: playerB_ship_1 <= {X, Y};
                        2'b10: playerB_ship_2 <= {X, Y};
                        2'b11: playerB_ship_3 <= {X, Y};
                    endcase
                    input_count_B <= input_count_B + 1;
                    if (input_count_B == 3) current_state <= SHOW_SCORE_FIRST;
                end else if (pBb && overlap_detector) begin
                    current_state <= ERROR_B;
                end
            end

            ERROR_A, ERROR_B: begin
                if (error_counter < ERROR_WAIT) begin
                    error_counter <= error_counter + 1;
                end 
                else begin
                    error_counter <= 0;
                    if (current_state == ERROR_A) begin
                      current_state <= INPUT_A;
                    end 
                    else begin
                      current_state <= INPUT_B;
                    end
                end
            end

            SHOW_SCORE: begin
              // Check if a win condition is met
              if ((3 < scoreA) || (3 < scoreB) ) begin
                  current_state <= WINNER; // Direct transition to WINNER if a player wins
              end 
              else if (show_score_delay < SCORE_WAIT) begin
                  show_score_delay <= show_score_delay + 1; // Count delay
              end 
              else begin
                  show_score_delay <= 0; // Reset delay
                  // Transition to the next shooting state based on the turn
                  if (turn == 0) begin
                    current_state <= SHOOT_A;
                  end 
                  else begin
                    current_state <= SHOOT_B;
                  end
              end
            end

            SHOW_SCORE_FIRST:begin
              if (show_score_delay < SCORE_WAIT) begin
                show_score_delay <= show_score_delay + 1; // Count delay
              end 
              else begin
                show_score_delay <= 0; // Reset delay
                current_state <= SHOOT_A;
              end
            end

            SHOOT_A: begin
              if (pAb) begin
                  hit_flag <= 0; // Reset hit flag before evaluating
                  // Player A's turn: Check Player B's ships
                  if ((playerB_ship_0 == {X, Y}) && !playerB_destroyed_0) begin
                      playerB_destroyed_0 <= 1;
                      scoreA <= scoreA + 1; // Increment score
                      hit_flag <= 1;
                  end
                  if ((playerB_ship_1 == {X, Y}) && !playerB_destroyed_1) begin
                      playerB_destroyed_1 <= 1;
                      scoreA <= scoreA + 1;
                      hit_flag <= 1;
                  end
                  if ((playerB_ship_2 == {X, Y}) && !playerB_destroyed_2) begin
                      playerB_destroyed_2 <= 1;
                      scoreA <= scoreA + 1;
                      hit_flag <= 1;
                  end
                  if ((playerB_ship_3 == {X, Y}) && !playerB_destroyed_3) begin
                      playerB_destroyed_3 <= 1;
                      scoreA <= scoreA + 1;
                      hit_flag <= 1;
                  end
                  turn <= ~turn; // Alternate turns
                  current_state <= SHOW_SCORE; // Proceed to SHOW_SCORE otherwise
              end
              
            end
          
            SHOOT_B: begin
              if (pBb) begin
                  hit_flag <= 0; // Reset hit flag before evaluating
                  // Player B's turn: Check Player A's ships
                  if ((playerA_ship_0 == {X, Y}) && !playerA_destroyed_0) begin
                      playerA_destroyed_0 <= 1;
                      scoreB <= scoreB + 1; // Increment score
                      hit_flag <= 1;
                  end
                  if ((playerA_ship_1 == {X, Y}) && !playerA_destroyed_1) begin
                      playerA_destroyed_1 <= 1;
                      scoreB <= scoreB + 1;
                      hit_flag <= 1;
                  end
                  if ((playerA_ship_2 == {X, Y}) && !playerA_destroyed_2) begin
                      playerA_destroyed_2 <= 1;
                      scoreB <= scoreB + 1;
                      hit_flag <= 1;
                  end
                  if ((playerA_ship_3 == {X, Y}) && !playerA_destroyed_3) begin
                      playerA_destroyed_3 <= 1;
                      scoreB <= scoreB + 1;
                      hit_flag <= 1;
                  end
                  turn <= ~turn; // Alternate turns
                  current_state <= SHOW_SCORE; // Proceed to SHOW_SCORE otherwise
                  
              end
            end
          
        
            WINNER: begin
              if (delay_cnt_error_and_winner < WINNER_LEDS) begin
                  delay_cnt_error_and_winner <= delay_cnt_error_and_winner + 1;
              end 
              else begin
                  delay_cnt_error_and_winner <= 0;
                  // Hold in WINNER state or wait for reset
              end
          end

            default: current_state <= IDLE;
        endcase
    end
end

  // Next-State Logic
  // Combinational Logic for Next-State and Overlap Detection
  always @(*) begin
    next_state = current_state;
    overlap_detector = 0;

    case (current_state)
      IDLE: begin
        if (start)
          next_state = INPUT_A;
      end

      INPUT_A: begin
        // Check overlap for Player A's input
        overlap_detector = ((playerA_ship_0 == {X, Y}) && (input_count_A > 0)) ||
                           ((playerA_ship_1 == {X, Y}) && (input_count_A > 1)) ||
                           ((playerA_ship_2 == {X, Y}) && (input_count_A > 2)) ||
                           ((playerA_ship_3 == {X, Y}) && (input_count_A > 3));

        if (pAb && !overlap_detector && input_count_A < 4)
          if (input_count_A > 3) begin
            next_state = INPUT_B;
          end 
          else begin
            next_state = INPUT_A;
          end
        else if (pAb && overlap_detector)
          next_state = ERROR_A;
      end

      INPUT_B: begin
        // Check overlap for Player B's input, including Player A's ships
        overlap_detector = ((playerB_ship_0 == {X, Y}) && (input_count_B > 0)) ||
                           ((playerB_ship_1 == {X, Y}) && (input_count_B > 1)) ||
                           ((playerB_ship_2 == {X, Y}) && (input_count_B > 2)) ||
                           ((playerB_ship_3 == {X, Y}) && (input_count_B > 3)) ||
                           ((playerA_ship_0 == {X, Y})) ||
                           ((playerA_ship_1 == {X, Y})) ||
                           ((playerA_ship_2 == {X, Y})) ||
                           ((playerA_ship_3 == {X, Y}));
        if (pBb && !overlap_detector && input_count_B < 4)
          if (input_count_B > 3) begin
            next_state = SHOW_SCORE_FIRST;
          end 
          else begin
              next_state = INPUT_B;
          end
        else if (pBb && overlap_detector)
          next_state = ERROR_B;
      end

      default: next_state = IDLE;
    endcase
  end

  // Combinational Output Logic
  always @(*) begin
    // Default SSD outputs (To prevent error)
    disp0 = 8'b00000000;
    disp1 = 8'b00000000;
    disp2 = 8'b00000000;
    disp3 = 8'b00000000;

    // Default LED configuration (To prevent error)
    led = 8'b00000000;

    // Update LED input count and state indicators
    case (current_state)
      IDLE: begin
        disp3 = ssd_encode[5]; // "I"
        disp2 = ssd_encode[6]; // "d"
        disp1 = ssd_encode[7]; // "L"
        disp0 = ssd_encode[8]; // "E"
        led = 8'b10011001;      // LEDS 7,4,3,0
      end
      INPUT_A: begin
        disp3 = ssd_encode[10]; // "A"
        disp1 = ssd_encode[X];  // Show X-coordinate
        disp0 = ssd_encode[Y];  // Show Y-coordinate
        led[7] = 1;             // Indicate Player A's turn
        led[5:4] = input_count_A; // Display Player A input count
      end
      INPUT_B: begin
        disp3 = ssd_encode[11]; // "B"
        disp1 = ssd_encode[X];  // Show X-coordinate
        disp0 = ssd_encode[Y];  // Show Y-coordinate
        led[0] = 1;             // Indicate Player B's turn
        led[3:2] = input_count_B; // Display Player B input count
      end
      ERROR_A: begin
        disp3 = ssd_encode[8];  // "E"
        disp2 = ssd_encode[12]; // "r"
        disp1 = ssd_encode[12]; // "r"
        disp0 = ssd_encode[13]; // "o"
        led = 8'b10011001;     // Highlight error for Player A
      end
      ERROR_B: begin
        disp3 = ssd_encode[8];  // "E"
        disp2 = ssd_encode[12]; // "r"
        disp1 = ssd_encode[12]; // "r"
        disp0 = ssd_encode[13]; // "o"
        led = 8'b10011001;     // Highlight error for Player B
      end
      SHOW_SCORE: begin
        disp2 = ssd_encode[scoreA];
        disp1 = 8'b01000000; // "-"
        disp0 = ssd_encode[scoreB];
        if (hit_flag) begin
          led = 8'b11111111;
        end 
        else begin
            led = 8'b00000000;
        end
      end
      SHOW_SCORE_FIRST: begin
        disp2 = ssd_encode[scoreA];
        disp1 = 8'b01000000; // "-"
        disp0 = ssd_encode[scoreB];
        led = 8'b10011001;
      end
      SHOOT_A: begin
        disp3 = ssd_encode[10]; // "A"
        disp1 = ssd_encode[X];
        disp0 = ssd_encode[Y];
        led[7] = 1;
        led[5:4] = scoreA; // Display Player A input count
        led[3:2] = scoreB; // Display Player B input count
      end
      SHOOT_B: begin
        disp3 = ssd_encode[11]; // "B"
        disp1 = ssd_encode[X];
        disp0 = ssd_encode[Y];
        led[0] = 1;
        led[5:4] = scoreA; // Display Player A input count
        led[3:2] = scoreB; // Display Player B input count
      end

      WINNER: begin
        // Display the winner and animate LEDs
        if (3 < scoreA) disp3 = ssd_encode[10]; // "A"
        else if (3 < scoreB) disp3 = ssd_encode[11]; // "B"

        disp2 = ssd_encode[scoreA];
        disp1 = ssd_encode[14]; // "-"
        disp0 = ssd_encode[scoreB];

        // LED animation
        case (delay_cnt_error_and_winner)
          0: led = 8'b11000000;
          1: led = 8'b11000000;
          2: led = 8'b01100000;
          3: led = 8'b01100000;
          4: led = 8'b00110000;
          5: led = 8'b00110000;
          6: led = 8'b00011000;
          7: led = 8'b00011000;
          8: led = 8'b00001100;
          9: led = 8'b00001100;
          10: led = 8'b00000110;
          11: led = 8'b00000110;
          12: led = 8'b00000011;
          13: led = 8'b00000011;
          default: led = 8'b00000000;
        endcase
      end
    
    
    endcase
  end

endmodule

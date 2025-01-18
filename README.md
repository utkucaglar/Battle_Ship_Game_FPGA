# Electronic Battleship Game on FPGA

This project implements a two-player electronic Battleship game using Verilog on an FPGA. The game features real-time feedback, turn-based gameplay, and score tracking, utilizing LEDs, switches, and seven-segment displays (SSDs) for input and output.

## Project Files

1. **`battleship.v`**  
   The core logic module of the game. It handles gameplay mechanics such as:
   - Ship placement and validation.
   - Turn management and scoring.
   - Coordinate tracking and interaction between players.

2. **`top.v`**  
   The top-level module that integrates all sub-modules, including the game logic, SSDs, debouncers, and the clock divider. This is the primary interface connecting the game logic with FPGA inputs and outputs.

3. **`clk_divider.v`**  
   A clock divider module that converts the FPGA's high-frequency clock signal into a manageable 50 Hz frequency for gameplay operations and input/output synchronization.

4. **`debouncer.v`**  
   Ensures stable input signals by eliminating noise and preventing multiple triggers from mechanical switches. This ensures reliable player interactions.

5. **`ssd.v`**  
   Controls the seven-segment displays (SSDs), showing player scores, turn indicators, and coordinates. It maps input data to the appropriate segments for real-time display updates.

6. **`tangnano9k.cst`**  
   The constraint file specifies the pin mappings between the FPGA and external hardware components such as switches, buttons, LEDs, and SSDs. It ensures proper hardware-to-logic connections during implementation.

## Gameplay Overview

The game starts with each player placing their ships on a 4x4 grid using switches to select X-Y coordinates. Players take turns firing at the opponent's ships, with real-time feedback displayed on SSDs and LEDs. Scores are tracked dynamically, and the first player to sink all opponent ships wins.

## Features

- **Interactive Inputs:** Players use switches for X-Y coordinates and buttons for actions like placing ships and firing.
- **Real-Time Feedback:** LEDs and SSDs display the game state, turns, and scores.
- **Error Handling:** Invalid moves, such as overlapping ship placement, are indicated on SSDs.
- **Synchronization:** Clock divider and debouncer modules ensure smooth and reliable hardware operation.

## Hardware Used

- **FPGA Board:** Tang Nano 9K  
- **Components:** LEDs, Buttons, Switches, and Seven-Segment Displays (SSDs)

This project demonstrates the practical application of digital logic design principles and FPGA programming to create an engaging and interactive hardware-based game.

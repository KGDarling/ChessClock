----------------------------------------------------------------------------------
-- Developer: Ken Darling B552608
-- Create Date: 04/04/2019
-- Design Name:CHESS_CLOCK
-- Module Name:ZEDBOARD_CHESS_CLOCK
-- Project Name: 18WSC054 – Electronic System Design with FPGAs - Task2
-- Target Devices: ZedBoard - Zynq 7000 (xc7z020clg484pkg)
-- Tool Versions: Vivado 2016.4
-- Description: Map Zedboard I/O to chess clock with clock divider
-- Dependencies: CLOCK_DIVIDER.vhd, CHESS_CLOCK.vhd
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

entity ZEDBOARD is
    port(
        GCLK : in std_logic;
        BTNL : in std_logic; --Player 1
        BTNR : in std_logic; --Player 2
        BTNU : in std_logic; --Wrong mate
        BTND : in std_logic; --Reset
        SW7  : in std_logic; --Set time 10s
        SW6  : in std_logic; --Set time 60s
        SW5  : in std_logic; --Set time 120s
        SW1  : in std_logic; --Switch display mode
        SW0  : in std_logic; --Load
        LD0  : out std_logic;
        LD1  : out std_logic;
        LD2  : out std_logic;
        LD3  : out std_logic;
        LD4  : out std_logic;
        LD5  : out std_logic;
        LD6  : out std_logic;
        LD7  : out std_logic
    );
end ZEDBOARD;

architecture RTL of ZEDBOARD is

    signal CLOCK_1Hz         : std_logic;
    signal CLOCK_1Hz_RESET   : std_logic;
    signal RESET             : std_logic;
    signal PLAYER1_BUTTON    : std_logic;
    signal PLAYER2_BUTTON    : std_logic;
    signal WRONG_MATE_BUTTON : std_logic;
    signal P1_LED            : std_logic;
    signal P2_LED            : std_logic;
    signal VALUE             : std_logic_vector(15 downto 0);
    signal COUNT1            : std_logic_vector(15 downto 0);
    signal COUNT2            : std_logic_vector(15 downto 0);
    signal CURRENT_STATE     : std_logic_vector(2 downto 0);
    signal P1_COUNT          : integer := 0;
    signal P2_COUNT          : integer := 0;
    signal WRONG_COUNT       : integer := 0;
    signal PAUSE_COUNT       : integer := 0;
    signal P1_INT            : std_logic;
    signal P1_HOLD           : std_logic;
    signal P2_INT            : std_logic;
    signal P2_HOLD           : std_logic;
    signal WRONG_INT         : std_logic;
    signal WRONG_HOLD        : std_logic;
    signal PAUSE_INT         : std_logic;
    signal PAUSE_HOLD        : std_logic;
    signal PAUSE_SWAP        : integer := 1;

begin
    --Map control signals to the chess clock module
    RESET             <= BTND;
    PLAYER1_BUTTON    <= P1_INT;
    PLAYER2_BUTTON    <= P2_INT;
    WRONG_MATE_BUTTON <= WRONG_INT;
    --Reset clock divider when switching players turn to prevent the time taken
    --for the previous turn effecting the next turn.
    CLOCK_1Hz_RESET   <= RESET or P1_INT or P2_INT;

    --entity instantiation of the clock divider
    CLOCK_DIVIDER_1HZ: entity work.CLOCK_DIVIDER(RTL)
        generic map(
        DIVIDER => 50_000_000
        )
        port map(
        CLOCK     => GCLK,
        RESET     => CLOCK_1Hz_RESET,
        OUT_CLOCK => CLOCK_1Hz
        );
    --entity instantiation of the chess clock
    CHESS_CLOCK: entity work.CHESS_CLOCK(RTL)
        port map(
        CLOCK        => GCLK,
        CLOCK_1Hz    => CLOCK_1Hz,
        RESET        => RESET,
        PLAYER1_STOP => PLAYER1_BUTTON,
        PLAYER2_STOP => PLAYER2_BUTTON,
        LOAD         => SW0,
        WRONG_MATE   => WRONG_MATE_BUTTON,
        VALUE        => VALUE,
        COUNT1       => COUNT1,
        COUNT2       => COUNT2,
        CURRENT_STATE => CURRENT_STATE,
        P1_WIN       => P1_LED,
        P2_WIN       => P2_LED
        );
    --Set starting value process
    --User can set the timers starting value
    --Value shown is in seconds
    LOAD_PROCESS : process(SW7, SW6, SW5)
    begin
        if SW7 = '1' then
            VALUE <= x"0010";
        elsif SW6 = '1' then
            VALUE <= x"0060";
        elsif SW5 = '1' then
            VALUE <= x"0120";
        else
            VALUE <= x"0000";
        end if;
    end process;

    --Debounce process is used to manage input from the on-board buttons.
    --The processes checks if a button has been held for 10M clock cycles (0.1 seconds)
    --Once the button has been held for 0.1 seconds the respective button signal(s)
    --are set high for 1 clock cycle.
    --The HOLD signal is then set high prevent the output signal(s) being set high
    --for multiple clock cycles.
    DEBOUNCE_PROCESS : process (GCLK)
    begin
        if rising_edge(GCLK) then
            --Set intermediate signals to 0
            P1_INT <= '0';
            P2_INT <= '0';
            WRONG_INT <= '0';
            --When both buttons held Increment pause counter, reset individual timers
            if BTNL = '1' and BTNR = '1' then
                PAUSE_COUNT <= PAUSE_COUNT +1;
                P1_COUNT <= 1;
                P2_COUNT <= 1;
                --If both buttons have been held for 0.1 seconds and both buttons
                --have been released previously set the output to 1
                if (PAUSE_COUNT = 10_000_000) and PAUSE_HOLD = '0' then
                    --Set Both players signals high to pause the chess clock
                    --Set PAUSE_HOLD to protect against buttons being held
                    --Reset pause counter (PAUSE_COUNT)
                    P1_INT <= '1';
                    P2_INT <= '1';
                    PAUSE_HOLD <= '1';
                    P1_HOLD <= '1';
                    P2_HOLD <= '1';
                    PAUSE_COUNT <= 1;
                end if;
            --If only player1's button is held increment player1 turn counter
            elsif BTNL = '1' and BTNR = '0' then
                P1_COUNT <= P1_COUNT +1;
                --If the button has been held for 0.1 seconds and has
                -- been released previously set the output to 1
                if (P1_COUNT = 10_000_000) and P1_HOLD = '0' then
                    --Set PLayer1's signal high
                    --Set P1_HOLD to protect against buttons being held
                    --Reset player1's counter (P1_COUNT)
                    P1_INT <= '1';
                    P1_HOLD <= '1';
                    P1_COUNT <= 1;
                end if;
            --If only player2's button is held increment player1 turn counter
            elsif BTNL = '0' and BTNR = '1' then
                P2_COUNT <= P2_COUNT +1;
                --If the button has been held for 0.1 seconds and has
                -- been released previously set the output to 1
                if (P2_COUNT = 10_000_000) and P2_HOLD = '0' then
                    --Set PLayer2's signal high
                    --Set P2_HOLD to protect against buttons being held
                    --Reset player2's counter (P2_COUNT)
                    P2_INT <= '1';
                    P2_HOLD <= '1';
                    P2_COUNT <= 1;
                end if;
            --If no buttons are currently held reset all counters and hold flags
            else
                P1_HOLD <= '0';
                P1_COUNT <= 1;
                P2_HOLD <= '0';
                P2_COUNT <= 1;
                PAUSE_HOLD <= '0';
                PAUSE_COUNT <= 1;
            end if;
            WRONG_INT <= '0';
            --If the wrong mate button is being held increment wrong mate counter
            if BTNU = '1' then
                WRONG_COUNT <= WRONG_COUNT +1;
                --If wrong mate button has been held for 0.1 seconds
                --and has been released previously set the output to 1
                if (WRONG_COUNT = 10_000_000) and WRONG_HOLD = '0' then
                    --Set wrong mate signal high
                    --Set WRONG_HOLD to protect against buttons being held
                    --Reset wrong mate counter (WRONG_COUNT)
                    WRONG_INT <= '1';
                    WRONG_HOLD <= '1';
                    WRONG_COUNT <= 1;
                end if;
            else
                WRONG_HOLD <= '0';
                WRONG_COUNT <= 1;
            end if;
        end if;
    end process;

    --Process to drive the LEDs
    LED_PROCESS : process (GCLK)
    begin
        if rising_edge(GCLK) then
            --Show state of chess clock when Switch 1 is high
            if SW1 = '1' then
                if CURRENT_STATE = "000" then
                    LD2 <= '0';
                    LD3 <= '0';
                    LD4 <= '0';
                    LD5 <= '0';
                    LD6 <= '0';
                    LD7 <= '1';
                elsif CURRENT_STATE = "001" then
                    LD2 <= '0';
                    LD3 <= '0';
                    LD4 <= '0';
                    LD5 <= '0';
                    LD6 <= '1';
                    LD7 <= '0';
                elsif CURRENT_STATE = "010" then
                    LD2 <= '0';
                    LD3 <= '0';
                    LD4 <= '0';
                    LD5 <= '1';
                    LD6 <= '0';
                    LD7 <= '0';
                elsif CURRENT_STATE = "011" then
                    LD2 <= '0';
                    LD3 <= '0';
                    LD4 <= '1';
                    LD5 <= '0';
                    LD6 <= '0';
                    LD7 <= '0';
                else
                    LD2 <= '0';
                    LD3 <= '0';
                    LD4 <= '0';
                    LD5 <= '0';
                    LD6 <= '0';
                    LD7 <= '0';
                end if;
                if P1_LED = '1' then
                    LD1 <= '1';
                    LD0 <= '0';
                elsif P2_LED = '1' then
                    LD1 <= '0';
                    LD0 <= '1';
                else
                    LD1 <= '0';
                    LD0 <= '0';
                end if;
            else
            --Show Remaining time
                --Show Player1's counter value (last 8 bits)
                if CURRENT_STATE = "010" then
                    LD0 <= COUNT1(0);
                    LD1 <= COUNT1(1);
                    LD2 <= COUNT1(2);
                    LD3 <= COUNT1(3);
                    LD4 <= COUNT1(4);
                    LD5 <= COUNT1(5);
                    LD6 <= COUNT1(6);
                    LD7 <= COUNT1(7);
                --Show Player2's counter value (last 8 bits)
                elsif CURRENT_STATE = "011" then
                    LD0 <= COUNT2(0);
                    LD1 <= COUNT2(1);
                    LD2 <= COUNT2(2);
                    LD3 <= COUNT2(3);
                    LD4 <= COUNT2(4);
                    LD5 <= COUNT2(5);
                    LD6 <= COUNT2(6);
                    LD7 <= COUNT2(7);
                --Show VALUE in reset state
                elsif CURRENT_STATE = "000" then
                    LD0 <= VALUE(0);
                    LD1 <= VALUE(1);
                    LD2 <= VALUE(2);
                    LD3 <= VALUE(3);
                    LD4 <= VALUE(4);
                    LD5 <= VALUE(5);
                    LD6 <= VALUE(6);
                    LD7 <= VALUE(7);
                --Swap between the two players counters value
                --during the pause state
                elsif CURRENT_STATE = "001" then
                    --Increment counter
                    PAUSE_SWAP <= PAUSE_SWAP + 1;
                    --Reset the counter after 2 seconds
                    if PAUSE_SWAP = 100_000_000 then
                        PAUSE_SWAP <= 1;
                    end if;
                    --Show player1's counter for 1 second
                    if PAUSE_SWAP > 50_000_000 then
                        LD0 <= COUNT1(0);
                        LD1 <= COUNT1(1);
                        LD2 <= COUNT1(2);
                        LD3 <= COUNT1(3);
                        LD4 <= COUNT1(4);
                        LD5 <= COUNT1(5);
                        LD6 <= COUNT1(6);
                        LD7 <= COUNT1(7);
                    else
                        --Show player2's counter for 1 second
                        LD0 <= COUNT2(0);
                        LD1 <= COUNT2(1);
                        LD2 <= COUNT2(2);
                        LD3 <= COUNT2(3);
                        LD4 <= COUNT2(4);
                        LD5 <= COUNT2(5);
                        LD6 <= COUNT2(6);
                        LD7 <= COUNT2(7);
                    end if;
                --Set LEDs off
                else
                    LD0 <= '0';
                    LD1 <= '0';
                    LD2 <= '0';
                    LD3 <= '0';
                    LD4 <= '0';
                    LD5 <= '0';
                    LD6 <= '0';
                    LD7 <= '0';
                end if;
            end if;
        end if;
    end process;
end RTL;

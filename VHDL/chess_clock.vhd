----------------------------------------------------------------------------------
-- Developer: Ken Darling B552608
-- Create Date: 07/12/2018
-- Design Name:CHESS_CLOCK
-- Module Name:CHESS_CLOCK
-- Project Name: 18WSC054 – Electronic System Design with FPGAs - Task1
-- Target Devices: ZedBoard - Zynq 7000 (xc7z020clg484pkg)
-- Tool Versions: Vivado 2016.4
-- Description: Chess clock with two count down timers
-- Dependencies: FOUR_DIGIT_COUNTER.vhd, DECIMAL_COUNTER.vhd
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity CHESS_CLOCK is
    port(
        CLOCK         : in std_logic;
        CLOCK_1Hz     : in std_logic;
        RESET         : in std_logic;
        PLAYER1_STOP  : in std_logic;
        PLAYER2_STOP  : in std_logic;
        LOAD          : in std_logic;
        WRONG_MATE    : in std_logic;
        VALUE         : in std_logic_vector(15 downto 0);
        COUNT1        : out std_logic_vector(15 downto 0);
        COUNT2        : out std_logic_vector(15 downto 0);
        CURRENT_STATE : out std_logic_vector(2 downto 0);
        P1_WIN        : out std_logic;
        P2_WIN        : out std_logic
        );
end CHESS_CLOCK;

architecture RTL of CHESS_CLOCK is

    type STATE_TYPE is (RESET_STATE, PLAYER1_TURN, PLAYER2_TURN, PLAYER1_WIN, PLAYER2_WIN, PAUSE);
    signal STATE, NEXT_STATE : STATE_TYPE;
    signal PLAYER1_ENABLE  : std_logic;
    signal PLAYER2_ENABLE  : std_logic;
    signal LOAD_INTERNAL   : std_logic;
    signal COUNT1_READ     : unsigned(15 downto 0);
    signal COUNT2_READ     : unsigned(15 downto 0);


begin
    --Typecast counter value from each players counter to the output pin of the
    --Chess clock.
    COUNT1 <= std_logic_vector(COUNT1_READ);
    COUNT2 <= std_logic_vector(COUNT2_READ);
    --entity instantiation of each players counter
    FOUR_DIGIT_COUNTER_PLAYER1_START: entity work.FOUR_DIGIT_COUNTER(RTL)
        port map(
        ENABLE => PLAYER1_ENABLE,
        LOAD   => LOAD_INTERNAL,
        CLOCK  => CLOCK_1Hz,
        RESET  => RESET,
        VALUE  => unsigned(VALUE),
        COUNT  => COUNT1_READ
        );
    FOUR_DIGIT_COUNTER_PLAYER2_START: entity work.FOUR_DIGIT_COUNTER(RTL)
        port map(
        ENABLE => PLAYER2_ENABLE,
        LOAD   => LOAD_INTERNAL,
        CLOCK  => CLOCK_1Hz,
        RESET  => RESET,
        VALUE  => unsigned(VALUE),
        COUNT  => COUNT2_READ
        );
    --Reset process: set the state machine to the reset state.
    RESET_PROCESS : process (CLOCK, RESET)
    begin
        if (RESET = '1') then
        STATE <= RESET_STATE;
        elsif rising_edge(CLOCK) then
        STATE <= NEXT_STATE;
        end if;
    end process;
    --next state process: this contains the functionality of the finite state machine
    NEXT_STATE_PROCESS : process (LOAD, STATE, PLAYER1_STOP, PLAYER2_STOP, COUNT1_READ, COUNT2_READ, WRONG_MATE)
    begin
        case STATE is
          --Reset state, system will remain in this state until a players turn
          --Allows the load signal to reach the counters
            when RESET_STATE =>
                LOAD_INTERNAL <= LOAD;
                P1_WIN <= '0';
                P2_WIN <= '0';
                PLAYER1_ENABLE <= '0';
                PLAYER2_ENABLE <= '0';
                CURRENT_STATE  <= "000";
                if PLAYER1_STOP = '1' then
                    NEXT_STATE <= PLAYER1_TURN;
                elsif PLAYER2_STOP= '1' then
                    NEXT_STATE <= PLAYER2_TURN;
                else
                    NEXT_STATE <= RESET_STATE;
                end if;
            --Player1's turn, count1 counts down, count2 is paused
            when PLAYER1_TURN =>
                LOAD_INTERNAL <= '0';
                P1_WIN <= '0';
                P2_WIN <= '0';
                PLAYER1_ENABLE <= '1';
                PLAYER2_ENABLE <= '0';
                CURRENT_STATE  <= "010";
                if WRONG_MATE = '1' then
                    NEXT_STATE <= PLAYER1_WIN;
                elsif COUNT1_READ = x"0000" then
                    NEXT_STATE <= PLAYER2_WIN;
                elsif PLAYER1_STOP= '1' and PLAYER2_STOP= '1' then
                    NEXT_STATE <= PAUSE;
                elsif PLAYER1_STOP= '1' then
                    NEXT_STATE <= PLAYER2_TURN;
                else
                    NEXT_STATE <= PLAYER1_TURN;
                end if;
            --Player2's turn, count2 counts down, count1 is paused
            when PLAYER2_TURN =>
                LOAD_INTERNAL <= '0';
                P1_WIN <= '0';
                P2_WIN <= '0';
                PLAYER1_ENABLE <= '0';
                PLAYER2_ENABLE <= '1';
                CURRENT_STATE  <= "011";
                if WRONG_MATE = '1' then
                    NEXT_STATE <= PLAYER2_WIN;
                elsif COUNT2_READ = x"0000" then
                    NEXT_STATE <= PLAYER1_WIN;
                elsif PLAYER1_STOP= '1' and PLAYER2_STOP= '1' then
                    NEXT_STATE <= PAUSE;
                elsif PLAYER2_STOP= '1' then
                    NEXT_STATE <= PLAYER1_TURN;
                else
                    NEXT_STATE <= PLAYER2_TURN;
                end if;
            --Pause state, pause both timers if both start buttons
            --are pressed simultaneously
            when PAUSE =>
                LOAD_INTERNAL <= '0';
                P1_WIN <= '0';
                P2_WIN <= '0';
                PLAYER1_ENABLE <= '0';
                PLAYER2_ENABLE <= '0';
                CURRENT_STATE  <= "001";
                if PLAYER1_STOP= '1' and PLAYER2_STOP= '1' then
                    NEXT_STATE <= PAUSE;
                elsif PLAYER1_STOP = '1' then
                    NEXT_STATE <= PLAYER1_TURN;
                elsif PLAYER2_STOP = '1' then
                    NEXT_STATE <= PLAYER2_TURN;
                else
                    NEXT_STATE <= PAUSE;
                end if;
            --Player1 win state
            when PLAYER1_WIN =>
                LOAD_INTERNAL <= '0';
                P1_WIN <= '1';
                P2_WIN <= '0';
                PLAYER1_ENABLE <= '0';
                PLAYER2_ENABLE <= '0';
                CURRENT_STATE  <= "111";
                NEXT_STATE <= PLAYER1_WIN;
            --Player2 win state
            when PLAYER2_WIN =>
                LOAD_INTERNAL <= '0';
                P1_WIN <= '0';
                P2_WIN <= '1';
                PLAYER1_ENABLE <= '0';
                PLAYER2_ENABLE <= '0';
                CURRENT_STATE  <= "111";
                NEXT_STATE <= PLAYER2_WIN;
            end case;
        end process;
end RTL;

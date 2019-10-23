--------------------------------------------------------------------------------
-- Developer: Ken Darling B552608
-- Create Date: 20/04/2019
-- Design Name:TB_CHESS
-- Module Name:CHESS_CLOCK
-- Project Name: 18WSC054 – Electronic System Design with FPGAs - Task1
-- Target Devices: ZedBoard - Zynq 7000 (xc7z020clg484pkg)
-- Tool Versions: Vivado 2016.4
-- Description: Testbench for a Chess clock with two count down timers
-- Dependencies: CHESS_CLOCK.vhd, FOUR_DIGIT_COUNTER.vhd, DECIMAL_COUNTER.vhd
--------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity TB_CHESS is
end TB_CHESS;

architecture TESTBENCH OF TB_CHESS is
    signal CLOCK         : std_logic;
    signal CLOCK_TIMERS  : std_logic;
    signal RESET         : std_logic;
    signal PLAYER1_STOP  : std_logic;
    signal PLAYER2_STOP  : std_logic;
    signal WRONG_MATE    : std_logic;
    signal LOAD          : std_logic;
    signal VALUE         : std_logic_vector(15 downto 0);
    signal CURRENT_STATE : std_logic_vector(2 downto 0);
    signal COUNT1        : std_logic_vector(15 downto 0);
    signal COUNT2        : std_logic_vector(15 downto 0);
    signal P1_WIN        : std_logic;
    signal P2_WIN        : std_logic;

    constant CLOCK_PERIOD : TIME := 10 ns;

begin
        TEST_CHESS_CLOCK : entity work.CHESS_CLOCK
        port map(
            RESET         => RESET,
            CLOCK         => CLOCK,
            CLOCK_1Hz     => CLOCK_TIMERS,
            WRONG_MATE    => WRONG_MATE,
            PLAYER1_STOP => PLAYER1_STOP,
            PLAYER2_STOP => PLAYER2_STOP,
            LOAD          => LOAD,
            VALUE         => VALUE,
            CURRENT_STATE => CURRENT_STATE,
            COUNT1        => COUNT1,
            COUNT2        => COUNT2,
            P1_WIN        => P1_WIN,
            P2_WIN        => P2_WIN
            );
    --Clock process
    CLOCK_GEN : process
    begin
        CLOCK <= '0';
        wait for CLOCK_PERIOD/2;
        CLOCK <='1';
        wait for CLOCK_PERIOD/2;
    end process CLOCK_GEN;

    --Timer Clock process
    TIMER_CLOCK_GEN : process
    begin
        CLOCK_TIMERS <= '0';
        wait for CLOCK_PERIOD/2;
        CLOCK_TIMERS <='1';
        wait for CLOCK_PERIOD/2;
    end process TIMER_CLOCK_GEN;


    TEST : process
        --Reset procedure. Used to reset the chess clock
        procedure RESET_INPUTS is
        begin
            wait until rising_edge(CLOCK);
            RESET        <= '1';
            VALUE        <= x"0000";
            WRONG_MATE   <= '0';
            PLAYER1_STOP <= '0';
            PLAYER2_STOP <= '0';
            LOAD         <= '0';
            wait until rising_edge(CLOCK);
            RESET         <= '0';
            wait until rising_edge(CLOCK);
        end RESET_INPUTS;

        --Player 1 turn procedure, TURN input represents the number of
        --clock cycles the turn will last
        procedure PLAYER1 (TURN : in integer) is
        begin
            PLAYER2_STOP <= '1';
            wait for CLOCK_PERIOD;
            PLAYER2_STOP <= '0';
            wait for (TURN-1)*CLOCK_PERIOD;
        end PLAYER1;

        --Player 2 turn procedure, TURN input represents the number of
        --clock cycles the turn will last
        procedure PLAYER2 (TURN : in integer) is
        begin
            PLAYER1_STOP <= '1';
            wait for CLOCK_PERIOD;
            PLAYER1_STOP <= '0';
            wait for (TURN-1)*CLOCK_PERIOD;
        end PLAYER2;

        --First turn procedure used after a reset or pause.
        --Takes the player number (1,2) and the number of clock cycles for the
        --turn as input.
        procedure FIRST_TURN (PLAYER : in integer; TURN : in integer) is
        begin
            if PLAYER <= 1 then
                PLAYER1_STOP <= '1';
                wait for CLOCK_PERIOD;
                PLAYER1_STOP <= '0';
                wait for (TURN-1)*CLOCK_PERIOD;
            elsif PLAYER <= 2 then
                PLAYER2_STOP <= '1';
                wait for CLOCK_PERIOD;
                PLAYER2_STOP <= '0';
                wait for (TURN-1)*CLOCK_PERIOD;
            end if;
        end FIRST_TURN;

        --Pause procedure. Used to pause the game
        procedure PLAYERS_PAUSE (TURN : in integer) is
        begin
            PLAYER1_STOP <= '1';
            PLAYER2_STOP <= '1';
            wait for CLOCK_PERIOD;
            PLAYER1_STOP <= '0';
            PLAYER2_STOP <= '0';
            wait for (TURN-1)*CLOCK_PERIOD;
        end PLAYERS_PAUSE;

        --Wrong mate procedure. Used to set the wrong mate input.
        procedure WRONG  is
        begin
            WRONG_MATE <= '1';
            wait for CLOCK_PERIOD;
            WRONG_MATE <= '0';
            wait for CLOCK_PERIOD;
        end WRONG;

        --Test case of game from Task1
        procedure TESTCASE1 (FAIL_FLAG : inout std_logic) is
        begin
            VALUE <= x"0300";
            LOAD  <= '1';
            wait for CLOCK_PERIOD;
            LOAD  <= '0';
            FIRST_TURN(1,50);
            PLAYER2(50);
            PLAYERS_PAUSE(5);
            if COUNT1 = x"0250" and COUNT2 = x"0250" then
                assert(false) report "1st turn test passed" severity note;
            else
                assert(false) report "1st turn test failed" severity note;
                FAIL_FLAG := '1';
            end if;
            FIRST_TURN(1,100);
            PLAYER2(45);
            if COUNT1 = x"0150" and COUNT2 = x"0207" then
                assert(false) report "2nd turn test passed" severity note;
            else
                assert(false) report "2nd turn test failed" severity note;
                FAIL_FLAG := '1';
            end if;
            PLAYER1(12);
            PLAYER2(38);
            if COUNT1 = x"0138" and COUNT2 = x"0169" then
                assert(false) report "3rd turn test passed" severity note;
            else
                assert(false) report "3rd turn test failed" severity note;
                FAIL_FLAG := '1';
            end if;
            PLAYER1(11);
            PLAYER2(99);
            if COUNT1 = x"0127" and COUNT2 = x"0070" then
                assert(false) report "4th turn test passed" severity note;
            else
                assert(false) report "4th turn test failed" severity note;
                FAIL_FLAG := '1';
            end if;
            PLAYER1(16);
            PLAYER2(69);
            if COUNT1 = x"0111" and COUNT2 = x"0001" then
                assert(false) report "5th turn test passed" severity note;
            else
                assert(false) report "5th turn test failed" severity note;
                FAIL_FLAG := '1';
            end if;
            wait for 10*CLOCK_PERIOD;
            if P1_WIN = '1' then
                assert(false) report "Player 1 win test passed" severity note;
            else
                assert(false) report "Player 1 win test failed" severity note;
                FAIL_FLAG := '1';
            end if;
        end procedure TESTCASE1;

        --Testcase to test Wrong mate set using TCL script.
        procedure TESTCASE2 (FAIL_FLAG : inout std_logic) is
        begin
            VALUE <= x"0300";
            LOAD  <= '1';
            wait for CLOCK_PERIOD;
            LOAD  <= '0';
            FIRST_TURN(1,50);
            PLAYER2(50);
            PLAYER1(50);
            PLAYER2(260);
            if P2_WIN = '1' then
                assert(false) report "Player 2 win, Wrong mate test passed" severity note;
            else
                assert(false) report "Player 2 win, Wrong mate test failed" severity note;
                FAIL_FLAG := '1';
            end if;
        end procedure TESTCASE2;

        --Testcase used to test pause set using TCL script.
        procedure TESTCASE3 (FAIL_FLAG : inout std_logic) is
        begin
            VALUE <= x"0150";
            LOAD  <= '1';
            wait for CLOCK_PERIOD;
            LOAD  <= '0';
            FIRST_TURN(1,50);
            PLAYER2(50);
            if CURRENT_STATE = "001" then
                assert(false) report "TCL pause passed" severity note;
            else
                assert(false) report "TCL pause failed" severity note;
                FAIL_FLAG := '1';
            end if;
        end procedure TESTCASE3;

        --Testcase used to test Load functionality.
        procedure LOAD_TEST (FAIL_FLAG : inout std_logic) is
        begin
            VALUE <= x"0020";
            LOAD  <= '1';
            wait for CLOCK_PERIOD;
            LOAD  <= '0';
            FIRST_TURN(1,10);
            PLAYER2(4);
            LOAD <= '1';
            wait for CLOCK_PERIOD;
            LOAD  <= '0';
            PLAYERS_PAUSE(5);
            if COUNT1 = x"0010" and COUNT2 = x"0015" then
                assert(false) report "Load test passed" severity note;
            else
                assert(false) report "Load test failed" severity note;
                FAIL_FLAG := '1';
            end if;
        end procedure LOAD_TEST;
        variable FAIL_FLAG : std_logic;

    begin
        FAIL_FLAG := '0';
        RESET_INPUTS;
        TESTCASE1(FAIL_FLAG);
        RESET_INPUTS;
        TESTCASE2(FAIL_FLAG);
        RESET_INPUTS;
        TESTCASE3(FAIL_FLAG);
        if FAIL_FLAG = '1' then
            assert(false) report "A test failed" severity error;
        else
            assert(false) report "All tests passed" severity error;
        end if;
    end process TEST;
end TESTBENCH;

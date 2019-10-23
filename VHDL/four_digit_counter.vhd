----------------------------------------------------------------------------------
-- Developer: Ken Darling B552608
-- Create Date: 07/12/2018
-- Design Name:FOUR_DIGIT_COUNTER
-- Module Name:CHESS_CLOCK
-- Project Name: 18WSC054 – Electronic System Design with FPGAs - Task1
-- Target Devices: ZedBoard - Zynq 7000 (xc7z020clg484pkg)
-- Tool Versions: Vivado 2016.4
-- Description: Four digit counter, counts down when enable is high, stops at 0
-- Dependencies: DECIMAL_COUNTER.vhd
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FOUR_DIGIT_COUNTER is
        port(
        ENABLE : in std_logic;
        LOAD   : in std_logic;
        CLOCK  : in std_logic;
        RESET  : in std_logic;
        VALUE  : in unsigned(15 downto 0);
        COUNT  : out unsigned(15 downto 0)
        );
end FOUR_DIGIT_COUNTER;

architecture RTL of FOUR_DIGIT_COUNTER is

signal ENABLE_INTERNAL : std_logic;
signal COUNT_INT : unsigned(15 downto 0);
signal DC0_CARRY : std_logic;
signal DC1_CARRY : std_logic;
signal DC2_CARRY : std_logic;
signal DC3_CARRY : std_logic;


begin
    COUNT <= COUNT_INT;
    --four single digit counter entities
    --Each counter controls 1 digit
    DECIMAL_COUNTER0 : entity work.DECIMAL_COUNTER(RTL)
        port map(
            CLOCK => CLOCK,
            LOAD  => LOAD,
            RESET => RESET,
            ENABLE   => ENABLE_INTERNAL,
            VALUE => VALUE(3 downto 0),
            COUNT => COUNT_INT(3 downto 0)
        );
    DECIMAL_COUNTER1 : entity work.DECIMAL_COUNTER(RTL)
        port map(
            CLOCK => CLOCK,
            LOAD  => LOAD,
            RESET => RESET,
            ENABLE   => DC0_CARRY,
            VALUE => VALUE(7 downto 4),
            COUNT => COUNT_INT(7 downto 4)
        );
    DECIMAL_COUNTER2 : entity work.DECIMAL_COUNTER(RTL)
        port map(
            CLOCK => CLOCK,
            LOAD  => LOAD,
            RESET => RESET,
            ENABLE   => DC1_CARRY,
            VALUE => VALUE(11 downto 8),
            COUNT => COUNT_INT(11 downto 8)
        );
    DECIMAL_COUNTER3 : entity work.DECIMAL_COUNTER(RTL)
        port map(
            CLOCK => CLOCK,
            LOAD  => LOAD,
            RESET => RESET,
            ENABLE   => DC2_CARRY,
            VALUE => VALUE(15 downto 12),
            COUNT => COUNT_INT(15 downto 12)
        );
    --Decrement process,Controls the enable signal for the four counters,
    --when the previous digit hits zero the next counters enable goes high
    DECREMENT_SYNC : process(RESET, COUNT_INT, ENABLE)
    begin
        --When RESET is high disable all counter digits
        if RESET = '1' then
            DC0_CARRY <= '0';
            DC1_CARRY <= '0';
            DC2_CARRY <= '0';
            ENABLE_INTERNAL <= '0';
        --When ENABLE is high only start the first single digit counter
        elsif ENABLE = '1' then
            DC0_CARRY <= '0';
            DC1_CARRY <= '0';
            DC2_CARRY <= '0';
            ENABLE_INTERNAL <= '1';
            --When total value is 0 (0000) stop all counters
            if COUNT_INT(15 downto 0) = 0 then
                ENABLE_INTERNAL <= '0';
            --When the last three digets are 0 (-000) decrement first digit
            elsif COUNT_INT(11 downto 0) = 0 then
                DC2_CARRY <= '1';
                DC1_CARRY <= '1';
                DC0_CARRY <= '1';
            --When the last two digits are 0 (--00) decrement second digit
            elsif COUNT_INT(7 downto 0) = 0 then
                DC1_CARRY <= '1';
                DC0_CARRY <= '1';
            --When the last digit is 0 (---0) decrement third digit
            elsif COUNT_INT(3 downto 0) = 0 then
                DC0_CARRY <= '1';
            end if;
        -- Pause timer when not the players turn
        else
            ENABLE_INTERNAL <= '0';
            DC0_CARRY <= '0';
            DC1_CARRY <= '0';
            DC2_CARRY <= '0';
        end if;
    end process;
end RTL;

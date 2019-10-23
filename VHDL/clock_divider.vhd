----------------------------------------------------------------------------------
-- Developer: Ken Darling B552608
-- Create Date: 04/04/2019
-- Design Name:CHESS_CLOCK
-- Module Name:CLOCK_DIVIDER
-- Project Name: 18WSC054 – Electronic System Design with FPGAs - Task2
-- Target Devices: ZedBoard - Zynq 7000 (xc7z020clg484pkg)
-- Tool Versions: Vivado 2016.4
-- Description: CLock divider to reduce clock from 100Mhz to 1Hz
-- Dependencies: None
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

entity CLOCK_DIVIDER is
--generic used to set clock divider frequency
generic(DIVIDER : integer);
    port(
        CLOCK     : in std_logic;
        RESET     : in std_logic;
        OUT_CLOCK : out std_logic
    );
end CLOCK_DIVIDER;

architecture RTL of CLOCK_DIVIDER is
    --Initialise counter and intermediate output signal.
    signal COUNT   : integer := 1;
    signal CLK_DIV : std_logic := '0';

begin
    --Clock divider process
    process(CLOCK, RESET, CLK_DIV)
    begin
        if (RESET = '1') then
            OUT_CLOCK <= '0';
            CLK_DIV   <= '0';
        --On the rising edge of the clock increment the counter.
        elsif rising_edge(CLOCK) then
            COUNT<= COUNT + 1;
            --Once the counter reaches the specified value (DIVIDER) invert the
            --output signal and reset the counter.
            if (COUNT = DIVIDER) then
                CLK_DIV <= not CLK_DIV;
                COUNT   <= 1;
            end if;
        end if;
    --Set the output.
    OUT_CLOCK <= CLK_DIV;
    end process;
end RTL;

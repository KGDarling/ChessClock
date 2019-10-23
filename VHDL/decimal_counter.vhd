----------------------------------------------------------------------------------
-- Developer: Ken Darling B552608
-- Create Date: 07/12/2018
-- Design Name:DECIMAL_COUNTER
-- Module Name:CHESS_CLOCK
-- Project Name: 18WSC054 – Electronic System Design with FPGAs - Task1
-- Target Devices: ZedBoard - Zynq 7000 (xc7z020clg484pkg)
-- Tool Versions: Vivado 2016.4
-- Description: Chess clock with two count down timres
-- Dependencies:
----------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity DECIMAL_COUNTER is
    port(
    ENABLE: in std_logic;
    LOAD  : in std_logic;
    CLOCK : in std_logic;
    RESET : in std_logic;
    VALUE : in unsigned(3 downto 0);
    COUNT : out unsigned(3 downto 0)
    );
end DECIMAL_COUNTER;

architecture RTL of DECIMAL_COUNTER is
    signal COUNT_MOD : unsigned(3 downto 0);
begin
    COUNT <= COUNT_MOD;
    --Decrement process: decrement the value of the counter 1 on the rising edge
    --of the clock. Set the counter value to zero during reset.
    --The starting value for the counter is loaded then LOAD is high
    DECREMENT : process (CLOCK, RESET, LOAD, VALUE, ENABLE)
    begin
        if RESET = '1' then
            COUNT_MOD <= (others => '0');
        elsif rising_edge(CLOCK) then
            if LOAD = '1' then
                COUNT_MOD <= VALUE;
            elsif ENABLE = '1' then
                --When the counter hits 0, set the value to 9 (1001)
                if COUNT_MOD = 0 then
                    COUNT_MOD <= "1001";
                    --If enable is high,
                    --on the rising edge of the clock decrement counter value by 1
                else
                    COUNT_MOD <= COUNT_MOD - 1;
                end if;
            end if;
        end if;
    end process;
end RTL;

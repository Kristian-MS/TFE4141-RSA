----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09.09.2026 16:12:05
-- Design Name: 
-- Module Name: latch_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity latch_tb is
--  Port ( );
end latch_tb;

architecture Behavioral of latch_tb is

    signal Q  : std_logic;
    signal QB : std_logic;
    signal R  : std_logic := '0';
    signal S  : std_logic := '0';

begin

    uut : entity work.latch
        port map (
            Q  => Q,
            QB => QB,
            R  => R,
            S  => S
        );

    stimulus : process
    begin

        S <= '0';
        R <= '1';
        wait for 10 ns;

        R <= '0';
        wait for 10 ns;

        S <= '1';
        wait for 10 ns;

        S <= '0';
        wait for 10 ns;

        S <= '1';
        R <= '1';
        wait;
        
    end process;

end Behavioral;

----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.10.2026 15:31:57
-- Design Name: 
-- Module Name: blakely_mult - Behavioral
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

entity blakely_mult is
    Port ( A : in STD_LOGIC_VECTOR (256 downto 0);
           B : in STD_LOGIC_VECTOR (256 downto 0);
           n : in STD_LOGIC_VECTOR (256 downto 0);
           result : out STD_LOGIC_VECTOR (256 downto 0);
           output_valid : out STD_LOGIC;
           input_valid : in STD_LOGIC;
           reset : in std_logic;
           clk   : in  std_logic);
end blakely_mult;

architecture Behavioral of blakely_mult is

signal bit_index : integer range 0 to 255 := 255;

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if input_valid = '1' then
                result <= (others => '0');
                bit_index <= 255;
            else
                -- bruk A(bit_index)
    
                if bit_index > 0 then
                    bit_index <= bit_index - 1;
                else
                    -- ferdig
                end if;
            end if;
        end if;
    end process; 
end Behavioral;

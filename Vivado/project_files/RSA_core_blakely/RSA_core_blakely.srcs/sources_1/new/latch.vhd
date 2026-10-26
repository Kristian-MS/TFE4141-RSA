----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09.09.2026 16:03:15
-- Design Name: 
-- Module Name: latch - Behavioral
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

entity latch is
    Port ( Q : inout STD_LOGIC;
           QB : inout STD_LOGIC;
           R : in STD_LOGIC;
           S : in STD_LOGIC);
end latch;

architecture Behavioral of latch is

begin

Q <= R nor QB;
QB <= S nor Q;

end Behavioral;

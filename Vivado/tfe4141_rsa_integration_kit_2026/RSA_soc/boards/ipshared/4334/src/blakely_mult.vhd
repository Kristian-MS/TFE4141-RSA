----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 13.10.2026 17:01:30
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
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity blakely_mult is
    Port ( A : in STD_LOGIC_VECTOR (255 downto 0);
           B : in STD_LOGIC_VECTOR (255 downto 0);
           n : in STD_LOGIC_VECTOR (255 downto 0);
           result : out STD_LOGIC_VECTOR (255 downto 0);
           input_valid : in STD_LOGIC;
           output_valid : out STD_LOGIC;
           n_reset : in STD_LOGIC;
           clk : in STD_LOGIC);
end blakely_mult;

architecture Behavioral of blakely_mult is

type state_t is (
    IDLE,
    RUN,
    DONE
);

signal state     : state_t := IDLE;
signal bit_index : integer range 0 to 255 := 255;

signal a_reg, b_reg, n_reg : unsigned(255 downto 0);
signal s_reg : unsigned(257 downto 0); -- Extra bits for intermediate values

begin

process(clk)
    variable temp : unsigned(257 downto 0);
    variable n_extended : unsigned(257 downto 0);
    variable sub_temp    : unsigned(258 downto 0);
begin
    if rising_edge(clk) then
        if n_reset = '0' then
            state        <= IDLE;
            bit_index    <= 255;
            a_reg        <= (others => '0');
            b_reg        <= (others => '0');
            n_reg        <= (others => '0');
            s_reg        <= (others => '0');
            result       <= (others => '0');
            output_valid <= '0';

        else
            output_valid <= '0';
            case state is
                when IDLE => 
                    if input_valid = '1' then
                    
                        if unsigned(n) = 0 then
                          report "modulus operand n is zero" severity warning;
                            
                        elsif unsigned(B) >= unsigned(n) then
                          report "input B greater than modulus operand n, invalid inputs" severity warning;
                            
                        else --Valid inputs
                            a_reg        <= unsigned(A);
                            b_reg        <= unsigned(B);
                            n_reg        <= unsigned(n);
                            s_reg        <= (others => '0');
                            bit_index    <= 255;
                            output_valid <= '0';
                            state        <= RUN;
                        end if;
                    end if;

                when RUN =>
                    temp := shift_left(s_reg, 1);

                    if a_reg(bit_index) = '1' then
                        temp := temp + resize(b_reg, temp'length);
                    end if;
                    
                    -- Extend modulus to match temp
                    n_extended := resize(n_reg, n_extended'length);
                    
                    -- First modular reduction
                    sub_temp := ('0' & temp) - ('0' & n_extended);      -- '0' & n_extended er en måte å gi n_extend en signed bit smart for å sjekke underflow
                    
                    if sub_temp(258) = '0' then
                        temp := sub_temp(257 downto 0);
                    end if;
                    
                    -- Second modular reduction
                    sub_temp := ('0' & temp) - ('0' & n_extended);
                    
                    if sub_temp(258) = '0' then
                        temp := sub_temp(257 downto 0);
                    end if;
                    
                    s_reg <= temp;
                    
                    if bit_index = 0 then
                        state <= DONE;
                    else
                        bit_index <= bit_index - 1;
                    end if;

                when DONE =>
                    result       <= std_logic_vector(s_reg(255 downto 0));
                    output_valid <= '1';
                    state        <= IDLE;
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end if;
end process;

end Behavioral;
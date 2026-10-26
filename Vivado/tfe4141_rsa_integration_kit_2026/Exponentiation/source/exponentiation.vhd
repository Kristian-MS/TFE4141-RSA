library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity exponentiation is
	generic (
		C_block_size : integer := 256
	);
	port (
		--input controll
		valid_in	: in STD_LOGIC;
		ready_in	: out STD_LOGIC;

		--input data
		message 	: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
		key 		: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );

		--ouput controll
		ready_out	: in STD_LOGIC;
		valid_out	: out STD_LOGIC;

		--output data
		result 		: out STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		--modulus
		modulus 	: in STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		--utility
		clk 		: in STD_LOGIC;
		reset_n 	: in STD_LOGIC
		
	);
end exponentiation;


architecture expBehave of exponentiation is

    type state_t is (
        IDLE,
        RUN,
        FIRST_MULT,
        SECOND_MULT,
        DONE
    );
    
    signal state     : state_t := IDLE;
    signal bit_index : integer range 0 to 255 := 255;

    signal acc_reg, base_reg, n_reg, key_reg : unsigned(255 downto 0);
    
    signal mult_a      : std_logic_vector(255 downto 0);
    signal mult_b      : std_logic_vector(255 downto 0);
    signal modulus_reg : std_logic_vector(255 downto 0);
    signal mult_result : std_logic_vector(255 downto 0);
    
    signal mult_start  : std_logic;
    signal mult_done   : std_logic;
    signal mult_reset  : std_logic;

begin
    u_mult : entity work.blakely_mult
        port map (
            A            => mult_a,
            B            => mult_b,
            n            => modulus_reg,
            result       => mult_result,
            input_valid  => mult_start,
            output_valid => mult_done,
            reset        => mult_reset,
            clk          => clk
        );
        
    process(clk)
        variable temp : unsigned(255 downto 0);
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                state        <= IDLE;
                bit_index    <= 255;
                acc_reg        <= (others => '0');
                base_reg        <= (others => '0');
                n_reg        <= (others => '0');
                result       <= (others => '0');
                mult_reset <= '0';
                valid_out <= '0';
    
            else
                case state is
                    when IDLE =>
                        mult_reset <= '1';
                        if valid_in = '1' then
                            --acc_reg   <= to_unsigned(1, acc_reg'length);
                            base_reg        <= unsigned(message);
                            n_reg        <= unsigned(modulus);
                            key_reg     <= unsigned(key);
                            bit_index    <= 255;
                            valid_out <= '0';
                            --ready_in <= '0';

                            modulus_reg <= modulus;
                            
                            mult_a <= std_logic_vector(to_unsigned(1, acc_reg'length));
                            mult_b <= std_logic_vector(to_unsigned(1, acc_reg'length));
                            mult_start <= '1';

                            state        <= FIRST_MULT;
                        end if;
    
                    when FIRST_MULT =>
                        --ready_in <= '0';
                        mult_start <= '0';
                        if mult_done = '1' then
                            temp := unsigned(mult_result);
                                                
                            if key_reg(bit_index) = '1' then
                                mult_a <= std_logic_vector(temp);
                                mult_b <= std_logic_vector(base_reg);
                                mult_start <= '1';
                                state <= SECOND_MULT;
                            else
                                acc_reg <= temp;
                                
                                if bit_index = 0 then
                                    state <= DONE;
                                else
                                    bit_index <= bit_index - 1;
                                    mult_a <= std_logic_vector(temp);
                                    mult_b <= std_logic_vector(temp);
                                    mult_start <= '1';
                                    state <= FIRST_MULT;
                                end if;                                
                            end if;
                        end if;
                        
                    when SECOND_MULT =>
                        mult_start <= '0';
                        
                        if mult_done = '1' then
                            temp := unsigned(mult_result);
                            acc_reg <= temp;
                            if bit_index = 0 then
                                state <= DONE;
                            else
                                bit_index <= bit_index - 1;
                                mult_a <= std_logic_vector(temp);
                                mult_b <= std_logic_vector(temp);
                                mult_start <= '1';
                                state <= FIRST_MULT;
                            end if;
                        end if;
                         
                    when DONE =>
                        --valid_out <= '1';
                        result <= std_logic_vector(acc_reg(255 downto 0));
                        
                        if valid_out = '0' then
                            valid_out <= '1';
                        elsif ready_out = '1' then
                            valid_out <= '0';
                            state <= IDLE;
                        end if;
                        
                    when others =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;

    ready_in <= '1' when state = IDLE else '0';

end expBehave;

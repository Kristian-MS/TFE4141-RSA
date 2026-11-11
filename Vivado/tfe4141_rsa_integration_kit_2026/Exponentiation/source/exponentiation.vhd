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
        VALIDATE,
        INIT,
        CHECK_ZERO,
        SQUARE_START,
        SQUARE_WAIT,
        BASE_WAIT,
        DONE
    );
    
    signal state : state_t := IDLE;
    signal input_ok : std_logic;
    
    signal bit_index : integer range 0 to 255 := 255;

    signal acc_reg, base_reg, key_reg : unsigned(255 downto 0);
    
    signal mult_a      : std_logic_vector(255 downto 0);
    signal mult_b      : std_logic_vector(255 downto 0);
    signal modulus_reg : std_logic_vector(255 downto 0);
    signal mult_result : std_logic_vector(255 downto 0);
    
    signal mult_start  : std_logic;
    signal mult_done   : std_logic;
    signal mult_reset  : std_logic;
    signal multiply_base : std_logic;

begin
    u_mult : entity work.blakely_mult
        port map (
            A            => mult_a,
            B            => mult_b,
            n            => modulus_reg,
            result       => mult_result,
            input_valid  => mult_start,
            output_valid => mult_done,
            n_reset      => mult_reset,
            clk          => clk
        );
        
    
    mult_reset <= reset_n;
    mult_a <= std_logic_vector(acc_reg);
    mult_b <= std_logic_vector(base_reg) when multiply_base = '1' else std_logic_vector(acc_reg);
    
    
    process(clk)
        variable temp : unsigned(255 downto 0);
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                state        <= IDLE;
                bit_index    <= 255;
                acc_reg      <= (others => '0');
                base_reg     <= (others => '0');
                result       <= (others => '0');
                mult_start   <= '0';
                valid_out    <= '0';
                input_ok <= '0';
                multiply_base <= '0';
                
            else
            
                mult_start <= '0';
                
                case state is
                    when IDLE =>
                        if valid_in = '1' then
                            -- Lagre inngangene uten å vente på sammenligningen.
                            base_reg    <= unsigned(message);
                            key_reg     <= unsigned(key);
                            modulus_reg <= modulus;
                            valid_out   <= '0';
                    
                            state <= VALIDATE;
                        end if;

                    when VALIDATE =>
                        -- Sammenlign lokale, registrerte verdier.
                        -- Lagre resultatet i ett register.
                        if unsigned(modulus_reg) > 1 and
                           base_reg < unsigned(modulus_reg) then
                            input_ok <= '1';
                        else
                            input_ok <= '0';
                        end if;
                    
                        state <= INIT;
                    
                    when INIT =>
                        -- Her brukes det registrerte resultatet fra VALIDATE.
                        if input_ok = '1' then
                            acc_reg   <= to_unsigned(1, acc_reg'length);
                            bit_index <= 255;
                            state     <= CHECK_ZERO;
                        else
                            report "Invalid message or modulus" severity warning;
                            state <= IDLE;
                        end if;
                        
                    when CHECK_ZERO =>
                        if key_reg(255) = '1' then
                            -- Første ettbit: 1² * base = base.
                            -- Vi slipper begge multiplikasjonene.
                            acc_reg <= base_reg;
                    
                            if bit_index = 0 then
                                -- Eksponenten er 1.
                                result <= std_logic_vector(base_reg);
                                state  <= DONE;
                            else
                                -- Fortsett vanlig square-and-multiply
                                -- fra biten etter første ettbit.
                                key_reg   <= shift_left(key_reg, 1);
                                bit_index <= bit_index - 1;
                                state     <= SQUARE_START;
                            end if;
                    
                        elsif bit_index = 0 then
                            -- Alle 256 bitene var null: message^0 mod n = 1.
                            -- VALIDATE har allerede sikret n > 1.
                            result <= std_logic_vector(to_unsigned(1, result'length));
                            state  <= DONE;
                    
                        else
                            -- Ledende null: gå videre uten multiplikasjon.
                            key_reg   <= shift_left(key_reg, 1);
                            bit_index <= bit_index - 1;
                        end if;

                    when SQUARE_START =>
                        multiply_base <= '0';
                        mult_start   <= '1';
                        state        <= SQUARE_WAIT;
                        
                    when SQUARE_WAIT =>
                        mult_start <= '0';
                        
                        if mult_done = '1' then
                            temp:= unsigned(mult_result);
                            acc_reg <= temp;
                            
                            if key_reg(255) = '1' then
                                acc_reg       <= unsigned(mult_result);
                                multiply_base <= '1';
                                mult_start    <= '1';
                                state         <= BASE_WAIT;
                            else
                                if bit_index = 0 then
                                    result <= std_logic_vector(temp);
                                    state <= DONE;
                                else
                                    bit_index <= bit_index - 1;
                                    key_reg <= shift_left(key_reg, 1);
                                    state     <= SQUARE_START;               
                                end if;
                            end if;
                        end if;
                        
                    when BASE_WAIT =>
                        
                        if mult_done = '1' then
                            temp := unsigned(mult_result);
                            acc_reg <= temp;
                                
                            if bit_index = 0 then
                                result <= std_logic_vector(temp);
                                state <= DONE;
                            else
                                bit_index <= bit_index - 1;
                                key_reg <= shift_left(key_reg, 1);
                                state     <= SQUARE_START;
                            end if;
                        end if;
                         
                    when DONE =>
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

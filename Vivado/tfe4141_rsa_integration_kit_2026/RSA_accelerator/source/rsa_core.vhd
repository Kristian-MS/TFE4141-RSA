--------------------------------------------------------------------------------
-- Author       : Oystein Gjermundnes
-- Organization : Norwegian University of Science and Technology (NTNU)
--                Department of Electronic Systems
--                https://www.ntnu.edu/ies
-- Course       : TFE4141 Design of digital systems 1 (DDS1)
-- Year         : 2018-2019
-- Project      : RSA accelerator
-- License      : This is free and unencumbered software released into the
--                public domain (UNLICENSE)
--------------------------------------------------------------------------------
-- Purpose:
--   RSA encryption core template. This core currently computes
--   C = M xor key_n
--
--   Replace/change this module so that it implements the function
--   C = M**key_e mod key_n.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity rsa_core is
	generic (
		-- Users to add parameters here
		C_BLOCK_SIZE          : integer := 256
	);
	port (
		-----------------------------------------------------------------------------
		-- Clocks and reset
		-----------------------------------------------------------------------------
		clk                    :  in std_logic;
		reset_n                :  in std_logic;

		-----------------------------------------------------------------------------
		-- Slave msgin interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgin_valid             : in std_logic;
		-- Slave ready to accept a new message
		msgin_ready             : out std_logic;
		-- Message that will be sent out of the rsa_msgin module
		msgin_data              :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgin_last              :  in std_logic;

		-----------------------------------------------------------------------------
		-- Master msgout interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgout_valid            : out std_logic;
		-- Slave ready to accept a new message
		msgout_ready            :  in std_logic;
		-- Message that will be sent out of the rsa_msgin module
		msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgout_last             : out std_logic;

		-----------------------------------------------------------------------------
		-- Interface to the register block
		-----------------------------------------------------------------------------
		key_e_d                 :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		key_n                   :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		rsa_status              : out std_logic_vector(31 downto 0)

	);
end rsa_core;

architecture rtl of rsa_core is

    constant NUM_CORES : integer := 4;
    
    type message_id_array is array (0 to NUM_CORES-1) of std_logic_vector(C_BLOCK_SIZE-1 downto 0); -- litt overkill med C_BLOCK_SIZE
    
    signal msg_id_currently_working   : message_id_array;
    signal msg_id_done_waiting    : message_id_array;

    
    type data_array is array (0 to NUM_CORES-1) of std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    
    signal core_message   : data_array;
    signal core_result    : data_array;
    
    signal core_valid_in  : std_logic_vector(0 to NUM_CORES-1);
    signal core_ready_in  : std_logic_vector(0 to NUM_CORES-1);
    signal core_valid_out : std_logic_vector(0 to NUM_CORES-1);
    signal core_ready_out : std_logic_vector(0 to NUM_CORES-1);
    
    signal msg_queue_in_index : std_logic_vector(C_BLOCK_SIZE-1 downto 0); --Dette er index til hvilken meldiing som kommer inn. Denne skal puttes inn i message
    signal msg_queue_out_index : std_logic_vector(C_BLOCK_SIZE-1 downto 0); --Dette er index til hvilken melding som skal sendes ut

    signal core_iter_index : integer range 0 to NUM_CORES-1 := 0;    
    
begin
	gen_exponentiation : for i in 0 to NUM_CORES-1 generate

    i_exponentiation : entity work.exponentiation
        generic map (
            C_block_size => C_BLOCK_SIZE
        )
        port map (
            message   => core_message(i),
            key       => key_e_d,
            valid_in  => core_valid_in(i),
            ready_in  => core_ready_in(i),
            ready_out => core_ready_out(i),
            valid_out => core_valid_out(i),
            result    => core_result(i),
            modulus   => key_n,
            clk       => clk,
            reset_n   => reset_n
        );

    end generate;
    
    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
                core_iter_index <= 0;
                msgin_ready <= '0';
            else
                if core_ready_in(core_iter_index) = '1' then
                    msgin_ready <= '1';
                    if msgin_valid = '1' then
                        core_message(core_iter_index) <= msgin_data;
                        core_valid_in(core_iter_index) <= '1';
                        msgin_ready <= '0';
                    end if;
                end if;
                
                --if core_valid_out(core_iter_index) = '1' then
                    -- Process result
                --    core_iter_index <= (core_iter_index + 1) mod 4;
                --end if;
                core_iter_index <= (core_iter_index + 1) mod NUM_CORES;
            end if;
        end if;
    end process;
    
    msgout_last <= msgin_last;

	rsa_status   <= (others => '0');
end rtl;

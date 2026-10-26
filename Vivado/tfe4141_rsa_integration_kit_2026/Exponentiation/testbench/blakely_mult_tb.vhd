library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

-- Standalone test of Exponentiation/source/blakely_mult.vhd (VHDL-2008).
-- Contract: active-high reset; input_valid pulses for one clock to start.
-- Capture A/B/n at that edge. Assert output_valid when result is valid;
-- clear output_valid on reset and when accepting the next operation.
-- Inputs stay stable until completion. There is no output backpressure.
-- Tests use n > 1 and A,B < n. Increase MAX_CYCLES if needed.
entity blakely_mult_tb is
end entity;

architecture sim of blakely_mult_tb is
    constant PERIOD : time := 10 ns;
    constant MAX_CYCLES : positive := 4096;
    subtype word_t is unsigned(255 downto 0);
    signal clk : std_logic := '0';
    signal reset : std_logic := '1';
    signal input_valid : std_logic := '0';
    signal output_valid : std_logic;
    signal a, b, n : std_logic_vector(255 downto 0) := (others => '0');
    signal result : std_logic_vector(255 downto 0);
begin
    clk <= not clk after PERIOD / 2;

    dut : entity work.blakely_mult
        port map (
            A => a, B => b, n => n, result => result,
            input_valid => input_valid, output_valid => output_valid,
            reset => reset, clk => clk
        );

    stimulus : process
        variable count : natural := 0;
        variable seed : word_t := x"123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0";
        variable av, bv, nv : word_t;
        constant MAX_WORD : word_t := (others => '1');

        procedure apply_reset is
        begin
            wait until falling_edge(clk);
            reset <= '1';
            input_valid <= '0';
            for i in 1 to 3 loop
                wait until rising_edge(clk);
            end loop;
            wait until falling_edge(clk);
            assert output_valid = '0'
                report "Reset must clear output_valid" severity failure;
            reset <= '0';
        end procedure;

        procedure check_case(constant label_text : string;
                             constant aa, bb, nn : word_t) is
            variable product, remainder_value : unsigned(511 downto 0);
            variable expected : word_t;
            variable completed : boolean := false;
        begin
            assert nn > 1 and aa < nn and bb < nn
                report "Invalid test operands" severity failure;
            -- Independent mathematical oracle; not a copy of Blakely's algorithm.
            product := aa * bb;
            remainder_value := product rem resize(nn, 512);
            expected := resize(remainder_value, 256);

            wait until falling_edge(clk);
            a <= std_logic_vector(aa);
            b <= std_logic_vector(bb);
            n <= std_logic_vector(nn);
            input_valid <= '1';
            wait until rising_edge(clk); -- Input accepted here.
            wait until falling_edge(clk);
            input_valid <= '0';

            -- Sample on falling edges, after clocked DUT updates have settled.
            for cycle in 0 to MAX_CYCLES loop
                if output_valid = '1' then
                    assert not is_x(result)
                        report label_text & ": result contains unknown bits" severity failure;
                    assert unsigned(result) = expected
                        report label_text & ": expected 0x" & to_hstring(expected)
                        & ", got 0x" & to_hstring(result) severity failure;
                    completed := true;
                    exit;
                end if;
                wait until falling_edge(clk);
            end loop;
            assert completed
                report label_text & ": timeout waiting for output_valid" severity failure;
            count := count + 1;
            report "PASS " & label_text severity note;
        end procedure;

        procedure next_word(variable state : inout word_t) is
        begin
            -- Deterministic xorshift values for reproducible full-width tests.
            state := state xor shift_left(state, 13);
            state := state xor shift_right(state, 7);
            state := state xor shift_left(state, 17);
        end procedure;
    begin
        apply_reset;
        check_case("zero A", to_unsigned(0, 256), to_unsigned(9, 256), to_unsigned(13, 256));
        check_case("zero B", to_unsigned(9, 256), to_unsigned(0, 256), to_unsigned(13, 256));
        check_case("identity", to_unsigned(1, 256), to_unsigned(9, 256), to_unsigned(13, 256));
        check_case("7*9 mod 13 = 11", to_unsigned(7, 256), to_unsigned(9, 256), to_unsigned(13, 256));
        check_case("two subtractions", to_unsigned(7, 256), to_unsigned(9, 256), to_unsigned(10, 256));
        check_case("exact multiple", to_unsigned(3, 256), to_unsigned(5, 256), to_unsigned(15, 256));
        check_case("full width square", MAX_WORD - 1, MAX_WORD - 1, MAX_WORD);
        check_case("high bit A", shift_left(to_unsigned(1, 256), 255), MAX_WORD - 2, MAX_WORD);
        check_case("even modulus", MAX_WORD - 2, MAX_WORD - 3, MAX_WORD - 1);

        for i in 1 to 32 loop
            next_word(seed);
            nv := seed;
            nv(255) := '1';
            next_word(seed);
            av := seed rem nv;
            next_word(seed);
            bv := seed rem nv;
            check_case("generated case " & integer'image(i), av, bv, nv);
        end loop;

        -- Re-use after reset as well as consecutive operations without reset.
        apply_reset;
        check_case("after reset", to_unsigned(12, 256), to_unsigned(12, 256), to_unsigned(13, 256));
        report "ALL " & integer'image(count) & " MULTIPLIER TESTS PASSED" severity note;
        finish;
        wait;
    end process;
end architecture;

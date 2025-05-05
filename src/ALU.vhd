----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
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

entity ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is
component ripple_adder is
    Port ( A : in STD_LOGIC_VECTOR (3 downto 0);
           B : in STD_LOGIC_VECTOR (3 downto 0);
           Cin : in STD_LOGIC;
           S : out STD_LOGIC_VECTOR (3 downto 0);
           Cout : out STD_LOGIC);
end component ripple_adder;

signal A_first : std_logic_vector(3 downto 0);
signal A_second : std_logic_vector(3 downto 0);
signal B_first : std_logic_vector(3 downto 0);
signal B_second : std_logic_vector(3 downto 0);
signal B_subtraction : std_logic_vector(7 downto 0);

signal sum_first : std_logic_vector(3 downto 0);
signal sum_second : std_logic_vector(3 downto 0);
signal sum_final : std_logic_vector(7 downto 0);

signal carry_first : std_logic;
signal carry_second : std_logic;

signal result : std_logic_vector(7 downto 0);

signal Cin : std_logic;

signal overflow_xnor : std_logic;
signal overflow_xor : std_logic;
signal overflow_alu_op : std_logic;
signal overflow_xnor_and_xor : std_logic;

begin

A_first <= i_A(3 downto 0);
A_second <= i_A(7 downto 4);

B_subtraction <= i_B when (i_op = "000" or i_op = "010" or i_op = "011") else (not i_B);
B_first <= B_subtraction(3 downto 0);
B_second <= B_subtraction(7 downto 4);

Cin <= '1' when i_op = "001" else '0';

ripple_adder_first : ripple_adder port map(
    A => A_first,
    B => B_first,
    Cin => Cin,
    S => sum_first,
    Cout => carry_first
);

ripple_adder_second : ripple_adder port map(
    A => A_second,
    B => B_second,
    Cin => carry_first,
    S => sum_second,
    Cout => carry_second
);

sum_final(3 downto 0) <= sum_first;
sum_final(7 downto 4) <= sum_second;

with i_op select
result <= sum_final when "000",
          sum_final when "001",
          (B_subtraction and i_A) when "010",
          (B_subtraction or i_A) when "011",
           "00000000" when others;
              
o_flags(3) <= result(7);
o_flags(2) <= '1' when result = "00000000" else '0';
o_flags(1) <= carry_second and (not i_op(1));

overflow_alu_op <= not i_op(1);

overflow_xnor <= not(i_A(7) xor i_B(7) xor i_op(0));

overflow_xor <= i_A(7) xor result(7);

overflow_xnor_and_xor <= overflow_xnor and overflow_xor;

o_flags(0) <= overflow_xnor_and_xor and overflow_alu_op;

o_result <= result;

end Behavioral;

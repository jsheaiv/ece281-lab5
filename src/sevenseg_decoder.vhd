----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/24/2025 01:06:35 PM
-- Design Name: 
-- Module Name: sevenseg_decoder - Behavioral
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

entity sevenseg_decoder is
  Port ( 
  i_Hex : in std_logic_vector(3 downto 0);
  o_seg_n : out std_logic_vector(6 downto 0)
  );
end sevenseg_decoder;

architecture Behavioral of sevenseg_decoder is

begin
    with i_HEX select
    o_seg_n <=  "1000000" when x"0",
                "1111001" when x"1",
                "0100100" when x"2",
                "0110000" when x"3",
                "0011001" when x"4",
                "0010010" when x"5",
                "0000010" when x"6",
                "1111000" when x"7",
                "0000000" when x"8",
                "0011000" when x"9",
                "0001000" when x"A",
                "0000011" when x"B",
                "0100111" when x"C",
                "0100001" when x"D",
                "0000110" when x"E",
                "0001110" when x"F",
                "0000000" when others;
          

end Behavioral;

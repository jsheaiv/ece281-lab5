----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is

type state is (clear, reg1, reg2, answer);

signal current_state, next_state : state;

begin

next_state <= state'succ(current_state) when (i_adv = '1');
              

with current_state select
o_cycle <=  "0001" when clear,
            "0010" when reg1,
            "0100" when reg2,
            "1000" when answer;
            
register_proc : process(i_adv)
    begin
    if rising_edge(i_adv) then
        if i_reset = '1' then
            current_state <= clear;
        else
            current_state <= next_state;
        end if;
     end if;
 end process register_proc;

end FSM;

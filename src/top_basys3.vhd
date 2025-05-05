--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(7 downto 0); -- operands and opcode
        btnU    :   in std_logic; -- reset
        btnC    :   in std_logic; -- fsm cycle
        btnL    :   in std_logic;
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is 
  
	-- declare components and signals
	component ALU is
    Port ( i_A : in STD_LOGIC_VECTOR (7 downto 0);
           i_B : in STD_LOGIC_VECTOR (7 downto 0);
           i_op : in STD_LOGIC_VECTOR (2 downto 0);
           o_result : out STD_LOGIC_VECTOR (7 downto 0);
           o_flags : out STD_LOGIC_VECTOR (3 downto 0));
end component ALU;

component TDM4 is
	generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
    Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	);
end component TDM4;

component clock_divider is
	generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
											   -- Effectively, you divide the clk double this 
											   -- number (e.g., k_DIV := 2 --> clock divider of 4)
	port ( 	i_clk    : in std_logic;
			i_reset  : in std_logic;		   -- asynchronous
			o_clk    : out std_logic		   -- divided (slow) clock
	);
end component clock_divider;

component controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end component controller_fsm;

component sevenseg_decoder is
  Port ( 
  i_Hex : in std_logic_vector(3 downto 0);
  o_seg_n : out std_logic_vector(6 downto 0)
  );
end component sevenseg_decoder;

component twos_comp is
    port (
        i_bin: in std_logic_vector(7 downto 0);
        o_sign: out std_logic;
        o_hund: out std_logic_vector(3 downto 0);
        o_tens: out std_logic_vector(3 downto 0);
        o_ones: out std_logic_vector(3 downto 0)
    );
end component twos_comp;

signal w_clk_TDM4 : std_logic;
signal w_reset_fsm : std_logic;
signal w_reset_master : std_logic;

signal w_cycle : std_logic_vector (3 downto 0) := "0001";

signal w_a_register : std_logic_vector(7 downto 0);
signal w_b_register : std_logic_vector(7 downto 0);
signal w_alu_result : std_logic_vector(7 downto 0);
signal w_opcode : std_logic_vector (2 downto 0);
signal w_flags : std_logic_vector (3 downto 0);

signal w_mux_o : std_logic_vector(7 downto 0);

signal w_negative : std_logic;
signal w_hundreds : std_logic_vector(3 downto 0);
signal w_tens : std_logic_vector(3 downto 0);
signal w_ones : std_logic_vector(3 downto 0);

signal w_TDM4_o : std_logic_vector(3 downto 0);
signal w_TDM4_sel : std_logic_vector(3 downto 0);
signal w_negative_display : std_logic_vector(3 downto 0);

signal w_segment : std_logic_vector(6 downto 0);


signal w_mux_sel : std_logic_vector(1 downto 0);
signal w_positive : std_logic_vector(6 downto 0) := "1111111";
signal w_negative_sign : std_logic_vector(6 downto 0) := "0111111";


  
begin
	-- PORT MAPS ----------------------------------------
controller_fsm_port : controller_fsm port map(
    i_reset => btnU,
    i_adv => btnC,
    o_cycle => w_cycle
);



clock_divider_TDM_port : clock_divider 
generic map(k_div => 50000)
port map(
    i_clk => clk,
    i_reset => btnL,
    o_clk => w_clk_TDM4
);

alu_port : ALU port map(
    i_A => w_a_register,
    i_B => w_b_register,
    i_op => w_opcode,
    o_result => w_alu_result,
    o_flags => w_flags
);

twos_comp_port : twos_comp port map(
    i_bin => w_mux_o,
    o_sign => w_negative,
    o_hund => w_hundreds,
    o_tens => w_tens,
    o_ones => w_ones
);

tdm4_port : TDM4 
generic map(k_WIDTH => 4)
port map(
    i_reset => btnU,
    i_clk => w_clk_TDM4,
    i_D0 => w_ones,
    i_D1 => w_tens,
    i_D2 => w_hundreds,
    i_D3 => w_negative_display,
    o_data => w_TDM4_o,
    o_sel => w_TDM4_sel
);

sevenseg_decoder_port : sevenseg_decoder port map(
    i_Hex => w_TDM4_o,
    o_seg_n => w_segment
);

state_register_1 : process(w_cycle(1))
    begin
    if rising_edge(w_cycle(1)) then
        if w_reset_fsm = '1' then
            w_a_register <= "00000000";
        else
            w_a_register <= sw;
        end if;
    end if;
end process state_register_1;

state_register_2 : process(w_cycle(2))
    begin
    if rising_edge(w_cycle(2)) then
        if w_reset_fsm = '1' then
            w_b_register <= "00000000";
        else
            w_b_register <= sw;
        end if;
    end if;
end process state_register_2;
	
	
	-- CONCURRENT STATEMENTS ----------------------------
	
	w_opcode <= sw(2 downto 0);
	
	w_reset_fsm <= btnU or w_cycle(3);
	
	with w_cycle select
	w_mux_o <= w_a_register when "0010",
	           w_b_register when "0100",
	           w_alu_result when "1000",
	           "00000000" when others;
	           
	 w_mux_sel(0) <= w_TDM4_sel(3);
	 w_mux_sel(1) <= w_negative;
	 
	 with w_mux_sel select
	 seg <= w_positive when "00",
	        w_negative_sign when "10",
	        w_segment when others;
	              
	 an <= w_TDM4_sel;
	 
	 led(3 downto 0) <= w_cycle;
	 led(11 downto 4) <= (others => '0');
	 led(15 downto 12) <= w_flags;
	
	
end top_basys3_arch;

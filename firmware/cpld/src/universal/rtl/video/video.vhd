-------------------------------------------------------------------------------
-- VIDEO Controller
-------------------------------------------------------------------------------

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;

entity video is
	generic (
			enable_turbo 		 : boolean := true
	);
	port (
		CLK2X 	: in std_logic; -- 28 MHz
		CLK		: in std_logic; -- 14 MHz
		ENA		: in std_logic; -- 7 MHz 

		BORDER	: in std_logic_vector(2 downto 0);	-- bordr color (port #xxFE)
		DI			: in std_logic_vector(7 downto 0);	-- video data from memory
		TURBO 	: in std_logic := '0'; -- 1 = turbo mode, 0 = normal mode
		INTA		: in std_logic := '0'; -- int request for turbo mode
		INT		: out std_logic; -- int output
		ATTR_O	: out std_logic_vector(7 downto 0); -- attribute register output
		A			: out std_logic_vector(13 downto 0); -- video address

		VIDEO_R	: out std_logic_vector(2 downto 0);
		VIDEO_G	: out std_logic_vector(2 downto 0);
		VIDEO_B	: out std_logic_vector(2 downto 0);
		
		HSYNC		: buffer std_logic;
		VSYNC		: buffer std_logic;
		CSYNC		: out std_logic;
		
		DS80		: in std_logic; -- 1 = Profi CP/M mode. 0 = standard mode
		
		VBUS_MODE : in std_logic := '0'; -- 1 = video bus, 2 = cpu bus
		VID_RD : in std_logic -- 1 = read attribute, 0 = read pixel data
	);
end entity;

architecture rtl of video is

	signal rgb 	 		: std_logic_vector(2 downto 0);
	signal i 			: std_logic;
	
	-- profi videocontroller signals
	signal vid_a_profi : std_logic_vector(13 downto 0);
	signal int_profi : std_logic;
	signal rgb_profi : std_logic_vector(2 downto 0);
	signal i_profi : std_logic;
	signal hsync_profi : std_logic;
	signal vsync_profi : std_logic;

	-- spectrum videocontroller signals
	signal vid_a_spec : std_logic_vector(13 downto 0);
	signal int_spec : std_logic;
	signal rgb_spec : std_logic_vector(2 downto 0);
	signal i_spec : std_logic;
	signal hsync_spec : std_logic;
	signal vsync_spec : std_logic;

begin

	U_PENT: entity work.pentagon_video 
	generic map (
		enable_turbo => enable_turbo
	)
	port map (
		CLK => CLK, -- 14
		CLK2x => CLK2x, -- 28
		ENA => ENA, -- 7
		BORDER => BORDER,
		DI => DI,
		TURBO => TURBO,
		INTA => INTA,
		INT => int_spec,
		ATTR_O => ATTR_O, 
		A => vid_a_spec,

		RGB => rgb_spec,
		I 	 => i_spec,
		
		HSYNC => hsync_spec,
		VSYNC => vsync_spec,

		VBUS_MODE => VBUS_MODE,
		VID_RD => VID_RD
	);

	U_PROFI: entity work.profi_video 
	port map (
		CLK => CLK, -- 14
		CLK2x => CLK2x, -- 28
		ENA => ENA, -- 7
		BORDER => BORDER,
		DI => DI,
		INTA => INTA,
		INT => int_profi,
		A => vid_a_profi,

		RGB => rgb_profi,
		I 	 => i_profi,
		
		HSYNC => hsync_profi,
		VSYNC => vsync_profi,

		VBUS_MODE => VBUS_MODE,
		VID_RD => VID_RD
	);

	A <= vid_a_profi when ds80 = '1' else vid_a_spec;

	INT <= int_profi when ds80 = '1' else int_spec;

	rgb <= rgb_profi when ds80 = '1' else rgb_spec;
	i <= i_profi when ds80 = '1' else i_spec;

	HSYNC <= hsync_profi when ds80 = '1' else hsync_spec;
	VSYNC <= vsync_profi when ds80 = '1' else vsync_spec;	
	
	-- RGBS output
	VIDEO_R <= "000" when rgb = "000" else 
				  rgb(2) & rgb(2) & '1' when i = '1' else 
				  rgb(2) & "ZZ";
	VIDEO_G <= "000" when rgb = "000" else 
				  rgb(1) & rgb(1) & '1' when i = '1' else 
				  rgb(1) & "ZZ";
	VIDEO_B <= "000" when rgb = "000" else 
			  rgb(0) & rgb(0) & '1' when i = '1' else 
			  rgb(0) & "ZZ";	
			  
	CSYNC <= not (vsync xor hsync);

end architecture;
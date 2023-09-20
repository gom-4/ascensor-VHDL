--SSDD I
--Eduardo Gómez González, DNI: 17497497V

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity ascensor is
    port (
        V_SW: in std_logic_vector(1 downto 0); --Interruptores que serán el número de planta que marca el usuario
		G_CLOCK_50: in std_logic;              --Reloj de 50MHz de la placa
        G_LEDR: out std_logic_vector(3 downto 0); --Led para ver las salidas: G_LEDR(0)->Movimiento del motor, G_LEDR(3) y 2 indicarán la planta en la que nos encontramos
		G_HEX0: out std_logic_vector(6 downto 0)  --Display de 7 segmentos 0
    );
end ascensor;

architecture behavioral of ascensor is

    signal count : unsigned(26 downto 0) :=(others => '0');  -- Está señal será el temporizador, el cual inicializamos a 0
    signal motor_timer: std_logic; --Variable que simula el motor, la cual será el reloj de la memoria
    signal q:std_logic_vector(1 downto 0); --Salidas de la memoria
    
begin
    --Asignación de variables a salidas de la placa
    G_LEDR(0) <= motor_timer; --Parpadeo que indica el cambio de piso
    G_LEDR(3) <= q(1); --Asignamos las salidas de la memoria a los leds para ver el piso en el que estamos
    G_LEDR(2) <= q(0);
    
    --Modelado del motor como timer
    modelado_motor: process (G_CLOCK_50)
    begin
		if (V_SW = q) then motor_timer <='0'; --En caso de que la entrada en los switches sea igual al estado de la memoria, el motor no se mueve porque ya estamos en el piso que queremos
		else --Si el piso en el que nos encontramos y la entrada en los switches no es igual, el motor comienza a moverse
			if (rising_edge(G_CLOCK_50)) then count <= count + 1;
			end if;
			if (count(26)='1') then motor_timer<='1';
			else motor_timer<='0';
			end if;
			if (count="111111111111111111111111111") then count <= "000000000000000000000000000";
			end if;
		end if;
    end process modelado_motor;
    
    --Memoria
    memoria: process(motor_timer) --Proceso que dependerá de su reloj, el cual es la salida del motor
    begin
        if (rising_edge(motor_timer)) then --La memoria solamente se actualizará en los flancos ascendentes del reloj
            if(V_SW="00") then --Caso en el que pulsamos piso 0
                case q is --Con la sentencia secuencial case vamos poniendo las transiciones dependiendo en el piso que estemos (análogo para cada piso)
                    when "00" => q <= "00"; --Si ya estamos en el 0, nos quedamos ahí
                    when "01" => q <= "00"; --Si estamos en el piso 1 bajamos un piso
                    when "10" => q <= "01"; --Si estamos en el piso dos, bajamos al piso 1 para después ir al 0
                    when "11" => q <= "10"; --Si estamos en el piso 3, bajamos al 2 para después ir al 1 y finalmente al 0
                    when others => q <= "00";
                end case;
            elsif (V_SW="01") then --Caso en el que pulsamos piso 1
                case q is
                    when "00" => q <= "01"; 
                    when "01" => q <= "01";
                    when "10" => q <= "01";
                    when "11" => q <= "10";
                    when others => q <= "00";
				end case;
            elsif (V_SW="10") then --Caso en el que pulsamos piso 2
                case q is
                    when "00" => q <= "01";
                    when "01" => q <= "10";
                    when "10" => q <= "10";
                    when "11" => q <= "10";
                    when others => q <= "00";
				end case;
            elsif (V_SW="11") then --Caso en el que pulsamos piso 3
                case q is
                    when "00" => q <= "01";
                    when "01" => q <= "10";
                    when "10" => q <= "11";
                    when "11" => q <= "11";
                    when others => q <= "00";   
				end case;
            end if;
        end if;     
    end process memoria;
	
	--Visualización del piso en display de 7 segmentos
	G_HEX0(6 downto 0) <=
		"1000000" when q="00" else
		"1111001" when q="01" else
		"0100100" when q="10" else
		"0110000" when q="11" else
		"1111111";
		
end behavioral;
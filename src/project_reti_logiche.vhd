----------------------------------------------------------------------------------

-- Engineer: Isabel Reguera, Alice Piacentini
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: PROGETTO RETI LOGICHE ANNO ACCADEMICO 2024/2025

----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



entity project_reti_logiche is
 port(
 i_clk : in std_logic;
 i_rst   : in std_logic;
 i_start : in std_logic; --va a 1 quando comincio l'elaborazione, va riportato a 0 per poterne iniziare un'altra
 i_add  : in std_logic_vector(15 downto 0); --indirizzo di memoria del 1 Byte della sequenza da elaborare (generato dal testbench)
 o_done : out std_logic; --segnale che va a 1 alla fine dell'elaborazione
 o_mem_addr : out std_logic_vector(15 downto 0); --segnale in uscita dal componente verso la memoria contenente l'indirizzo nel quale scrivere in mem (non so se quello iniziale o se si aggiorna man mano)
 i_mem_data : in std_logic_vector(7 downto 0); --segnale in arrivo dalla memoria che contiene il dato da usare
 o_mem_data : out std_logic_vector(7 downto 0); --dato elaborato da scrivere in memoria
 o_mem_we   : out std_logic; --write enable, da mandare a memoria. se 1 accesso in scrittura, se 0 accesso in lettura
 o_mem_en   : out std_logic --segnale di enable, se a 1 è possibile comunicare con la memoria
 );
 end project_reti_logiche;
 

architecture Behavioral of project_reti_logiche is

type State is (Idle,S1,S2,S3,S4,S5,S6,S7,S7_Wait,S8,S9_Write,S10,S11,S12,S12_Wait);
signal currState,nextState: State;
signal k1,k2,s: unsigned(7 downto 0);
signal k: unsigned(15 downto 0);
type coefficient_array_type is array (0 to 6) of signed(7 downto 0);
signal coeff: coefficient_array_type;
type words_array_type is array (0 to 6) of signed(7 downto 0);
signal words : words_array_type;
signal counter_coeff,counter_words: unsigned(2 downto 0);
signal firstAddr, currAddrW,currAddrR: unsigned(15 downto 0);
signal i: unsigned(15 downto 0);
signal result: std_logic_vector(7 downto 0);



begin

--processo che assegna a currState il valore calcolato al ciclo prima e salvato in nextState
process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            currState <= Idle;
            firstAddr <= (others => '0');
            k1 <= (others => '0');
            k2 <= (others => '0');
            s <= (others => '0');
            k <= (others => '0');
           coeff <= (others => (others => '0'));
           counter_coeff <= (others => '0');
           counter_words <= (others => '0');
           currAddrW <= (others => '0');
           currAddrR <= (others => '0');
           i <= (others => '0');
           words <= (others => (others => '0'));
           
        elsif rising_edge(i_clk) then
            currState <= nextState;      
            if currState = S1 then
                 firstAddr <= unsigned(i_add);
                 end if;
            if currState = S2 then
                 k1 <= unsigned(i_mem_data);
                 end if;
            if currState = S3 then
                 k2<= unsigned(i_mem_data);                
                 end if;
            if currState = S4 then
                 s<= unsigned(i_mem_data);
                 currAddrW <= firstAddr + 17;              
                 end if;
           if currState = S5 then
                if to_integer(counter_coeff) < 7 then
                    coeff(to_integer(counter_coeff)) <= signed(i_mem_data);          
                end if;
                counter_coeff <= counter_coeff + 1;
                end if;
           if currState = S6 then
                k <= (shift_left(resize(k1,k'length),8)) + resize(k2,k'length);      
                i <= (others => '0');
                counter_words <= (others => '0');
                end if;            
           if currState=S7 then
                words(to_integer(counter_words)) <= signed(i_mem_data);
                counter_words <= counter_words + 1;              
                end if;            
           if currState = S7_Wait then            
                null;
                end if;
           if currState = S8 then          
                currAddrR <= firstAddr + 17 + k+i;
                i <= i + 1;                    
                end if;                        
          if currState=S9_Write then
                null;
                end if;                
          if currState = S10 then
                null;      
                end if;              
          if currState = S12 then
                currAddrW <= currAddrW + 1;
                counter_words <= (others => '0');
                end if;          
          if currState = S12_Wait then
                null;      
                end if;
         
          end if;
    end process;  
   
 --precalcolo di NextState            
 process(currState,i_start,counter_coeff, counter_words,i,k)
       begin
           nextState <= currState;
           case currState is
               when Idle =>
                   if i_start = '1' then
                       nextState <= S1;
                   end if;
               when S1 =>
                   nextState <= S2;
               when S2 =>
                   nextState <= S3;
               when S3 =>
                   nextState <= S4;
               when S4 =>
                   nextState <= S5;
               when S5 =>
                   if counter_coeff<7 then
                   nextState <= S5;
                   elsif counter_coeff=7 then
                   nextState<= S6;
                   end if;
               when S6 =>
                  nextState<= S7;
               when S7 =>
                    nextState<= S7_Wait;
               when S7_Wait =>
                    if counter_words<7 then
                       nextState <= S7;
                       elsif counter_words=7 then
                        nextState<= S8;
                        end if;
               when S8 =>
                   nextState<= S9_Write;
                
                when S9_Write =>
                   if i<k then
                   nextState <= S10;
                   elsif i=k then
                   nextState <= S11;
                   end if;
             
               when S10 =>
                  if i<4 then
                     nextState <= S8;
                  else
                    nextState <= S12;
                  end if;
               when S11 =>
                   if i_start = '0' then
                   nextState <= Idle;
                   end if;
               when S12 =>
                   nextState <= S12_Wait;  
               when S12_Wait =>
                   nextState <= S7;  
           end case;
       end process;
       
process(currState, i_add, firstAddr, k1, k2, s, k, coeff, counter_coeff, counter_words, currAddrW, currAddrR, i, i_mem_data)
    begin
        o_mem_en <= '0';
        o_done <= '0';
        o_mem_we <= '0';
        o_mem_addr <= (others => '0');
        o_mem_data <= (others => '0');
       case currState is
          when Idle=>
            null;
          when S1=>
            o_mem_en <= '1';
            o_mem_we <= '0';
            o_mem_addr <= std_logic_vector(unsigned(i_add));
         when S2=>
            o_mem_en  <= '1';
            o_mem_we <= '0';
            o_mem_addr <= std_logic_vector(firstAddr + 1);
         when S3=>
            o_mem_en  <= '1';
            o_mem_we <= '0';
            o_mem_addr <= std_logic_vector(firstAddr + 2);
         when S4=>
            o_mem_en  <= '1';
            o_mem_we <= '0';
            if i_mem_data(0)='0' then
                o_mem_addr <= std_logic_vector(firstAddr + 3);
            elsif i_mem_data(0)='1' then
                o_mem_addr <= std_logic_vector(firstAddr + 3+7);
            end if;
         when S5=>
               o_mem_en  <= '1';
               o_mem_we <= '0';
               if s(0)='0' then
                    o_mem_addr <= std_logic_vector(firstAddr +4+ resize(counter_coeff, firstAddr'length));
               elsif s(0)='1' then
                    o_mem_addr<= std_logic_vector(firstAddr +4+7+ resize(counter_coeff, firstAddr'length));
               end if;
         when S6=>
              o_mem_en  <= '1';
              o_mem_we <= '0';
              o_mem_addr <= std_logic_vector(currAddrW);
         when S7=>
               null;
         when S7_Wait=>
                o_mem_en  <= '1';
                o_mem_we <= '0';
                o_mem_addr <= std_logic_vector(currAddrW + resize(counter_words,currAddrW'length));
           
         when S8=>
              o_mem_en  <= '1';
              o_mem_we <= '0';
             
        when S9_Write=>
                o_mem_en  <= '1';
                o_mem_we <= '1';
                o_mem_addr <= std_logic_vector(currAddrR);
                o_mem_data<=result;
         when S10=>
              o_mem_en  <= '0';
              o_mem_we <= '0';
             
         when S11=>
              o_done <= '1';
              o_mem_en  <= '0';
         when S12=>
               o_mem_en  <= '1';
               o_mem_we <= '0';
         when S12_Wait=>
               o_mem_en  <= '1';
               o_mem_we <= '0';
               o_mem_addr <= std_logic_vector(currAddrW);  
               end case;
   end process;
   
 
 process(i_clk, i_rst)
       variable currentSomma : integer;
       variable tmpSigned: signed(31 downto 0);
       variable tmpResult : signed(7 downto 0);
       variable normalized : signed(31 downto 0);
       variable term1 : signed(31 downto 0);
       variable term2 : signed(31 downto 0);
       variable term3 : signed(31 downto 0);
       variable term4 : signed(31 downto 0);
       variable jVal: integer;
       variable tmpInt : integer;
   begin
       if i_rst = '1' then
           
           tmpResult := (others => '0');
           result <= (others => '0');
       elsif rising_edge(i_clk) then
           if currState=S8 then
               currentSomma := 0;    
               if s(0)='0' then    
                   if i<4 then                
                       for jVal in -2 to +2 loop                        
                           if (to_signed(jVal, 8) + signed(i)) < 0 or (to_signed(jVal, 8) + signed(i)) >= signed(k) then                          
                               currentSomma := currentSomma + 0;
                           else
                               currentSomma := currentSomma + (to_integer(signed(coeff(jVal+3))) * to_integer(signed(words(to_integer(signed(i)+to_signed(jVal,i'length))))));
                               end if;
                       end loop;
                   else                      
                       for jVal in -2 to +2 loop
                           if (to_signed(jVal, 8) + signed(i)) < 0 or (to_signed(jVal, 8) + signed(i)) >= signed(k) then
                               currentSomma := currentSomma + 0;                            
                           else
                               currentSomma := currentSomma + (to_integer(signed(coeff(jVal+3))) * to_integer(signed(words(jVal+3))));                          
                           end if;
                       end loop;
                   end if;
               elsif s(0)='1' then                
                   if i<4 then                    
                       for jVal in -3 to +3 loop
                           if (to_signed(jVal, 8) + signed(i)) < 0 or (to_signed(jVal, 8) + signed(i)) >= signed(k) then
                               currentSomma := currentSomma + 0;                          
                           else
                               currentSomma := currentSomma + (to_integer(signed(coeff(jVal+3))) * to_integer(signed(words(to_integer(signed(i)+to_signed(jVal,i'length))))));        
                           end if;
                       end loop;
                   else          
                       for jVal in -3 to +3 loop
                           if (to_signed(jVal, 8) + signed(i)) < 0 or (to_signed(jVal, 8) + signed(i)) >= signed(k) then
                               currentSomma := currentSomma + 0;                              
                           else
                               currentSomma := currentSomma +( to_integer(signed(coeff(jVal+3))) *to_integer(signed(words(jVal+3))));                            
                           end if;
                       end loop;
                   end if;
               end if;
                           
               
               tmpSigned:=to_signed(currentSomma,32);  
               if s(0)='0' then              
                   term1 := shift_right(tmpSigned,4);
                   if tmpSigned < to_signed(0,tmpSigned'length) then
                       term1:= term1+ 1;                    
                                       
                   end if;  
                   term2 := shift_right(tmpSigned, 6);
                   if tmpSigned < to_signed(0, tmpSigned'length) then
                       term2:= term2+ 1;                    
                                       
                   end if;  
                   term3 := shift_right(tmpSigned, 8);
                   if tmpSigned < to_signed(0, tmpSigned'length) then
                       term3:= term3+ 1;
                                       
                   end if;
                   term4 := shift_right(tmpSigned, 10);
                   if tmpSigned < to_signed(0, tmpSigned'length) then
                       term4:= term4+ 1;                      
                                         
                   end if;
   
                   normalized:= term1 + term2+ term3+ term4;
                   
               else
                   
                   term1 := shift_right(tmpSigned, 6);
                   if tmpSigned< to_signed(0,tmpSigned'length) then
                       term1:= term1 + 1;                      
                                         
                   end if;  
                   term2 := shift_right(tmpSigned, 10);
                   if tmpSigned < to_signed(0, tmpSigned'length) then
                       term2:= term2+ 1;                      
                                       
                   end if;  
                   normalized:= term1 + term2;                  
               end if;
               
               
               tmpInt := to_integer(normalized);                
               if tmpInt > 127 then
                   tmpInt := 127;
               elsif tmpInt < -128 then
                   tmpInt := -128;
               end if;
               tmpResult := to_signed(tmpInt, 8);
               result<=std_logic_vector(tmpResult);
                   
          end if;
       end if;
   end process;

         
 

end Behavioral;

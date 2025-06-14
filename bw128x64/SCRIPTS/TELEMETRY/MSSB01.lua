-- MultiSwitch WM MODE für GlobalVariable

-- INFO
-- Unter Custom Scripts mswgv.lua hinzufügen mit GlobalVariable von diesem Script

-- GlobalVariable und Flugphase 
local Adresse = 1									-- Modul Adresse 0-3
local GlobalVariable = 2							-- GlobalVariable 1-9
local Flugphase = 0									-- Flugphase 0-8

-- Spalten, Reihen und Buttons 
local Spalten = 4									-- Anzahl Spalten min 1 max 4
local Reihen = 2									-- Anzahl Reihen min 1 max 2
local Buttons = 8									-- Anzahl Buttons min 1 max 8

local Zeit_Taster = 500								-- Zeit in ms "Ein" Taster
local Debug = 1										-- Debuganzeige ja(1)/nein(0)

-- Bezeichnungen, wird als Ueberschrift angezeigt
local name_b = "Beleuchtung"

-- config = Alle Einstellungen der Buttons
-- [1] = Buttonummer
-- output = Button Zuordnung Ansteuerung Button 1 = Ausgang1 usw.
-- type = "toggle" Button oder "momentary" Taster  "Zeit_Taster" an
-- name_s = Kurzbezeichnungen
-- name = Langbezeichnungen wird als Unterschrift angezeigt

config = {
    [1] = {output = 1, type = "toggle", name_s = "01", name = "Licht 01"},
    [2] = {output = 2, type = "toggle", name_s = "02", name = "Licht 02"},
	[3] = {output = 3, type = "toggle", name_s = "03", name = "Licht 03"},
	[4] = {output = 4, type = "toggle", name_s = "04", name = "Licht 04"},
	[5] = {output = 5, type = "toggle", name_s = "05", name = "Licht 05"},
	[6] = {output = 6, type = "toggle", name_s = "06", name = "Licht 06"},
	[7] = {output = 7, type = "toggle", name_s = "07", name = "Licht 07"},
	[8] = {output = 8, type = "momentary", name_s = "08", name = "Licht 08"},
};

-- Interne Variablen
local timeprev 
local timeprev_Taster = 1
local running = false
local cpos = 1
local cpress = 0
local status ={0,0,0,0,0,0,0,0,}
local lastStatus ={0,0,0,0,0,0,0,0,}
local Data = 0	

local function background()
	if not running then -- einmal ausführen
      running = true
	  timeprev = getTime()
	end

	local timenow = getTime() -- 10ms Auflösung
  
	if timenow - timeprev > 20 then -- sind  200 ms vergengen ? 
		timeprev = timenow
	        
        Data = 0 -- Data leeren		
		 
		Data = bit32.lshift(Adresse, 8); -- Adresse hinzufügen
		
		--Schalterauswertung
		for Schalter = 1, 8 do --Alle 8 Schalter
			Data = Data + (status[Schalter] * (math.pow(2,config[Schalter].output - 1)))	-- Wertigkeit addieren
		end
		
		model.setGlobalVariable(GlobalVariable - 1,Flugphase,Data); -- GlobalVariable beschreiben
	end

end

local function run(event)
	lcd.clear()
	
	
	-- Tasten rechts neben Display - + ENT / Scrollrad bei X9Lite
	if( event == EVT_ROT_RIGHT) then cpos = (cpos + 1)  % 10  -- 100 / EVT_PLUS_FIRST / Taste +
	elseif( event == EVT_ROT_LEFT) then cpos = (cpos -1) % 10  -- 101 / EVT_MINUS_FIRST /Taste -
	elseif( event ==  EVT_ENTER_FIRST) then cpress = 1 else cpress = 0 -- 98 / Taste ENT
	end

	if Spalten > 4 then -- Spalten max 4
		Spalten = 4
	end	

	if Spalten < 1 then -- Spalten min 1
		Spalten = 1
	end	

	if Reihen > 2 then -- Reihen max 4
		Reihen = 2
	end	

	if Reihen < 1 then -- Reihen min 1
		Reihen = 1
	end	

	if Buttons > 8 then -- Buttons max 8
		Buttons = 8
	end	

	if Buttons < 1 then -- Buttons min 1
		Buttons = 1
	end	

	if Buttons > Spalten * Reihen then -- Mehr Buttons als Platz ?
		Buttons = Spalten * Reihen
	end	

	if cpos == 0 then -- Positon als Umlauf 1-X 1-X usw (X = Anzahl Buttons)
		cpos = Buttons
	end  
	if cpos == Buttons + 1 then
		cpos = 1
	end 
	
	local timenow = getTime() -- 10ms Auflösung
 
	if ((cpress ==1) and ( lastStatus[cpos] ==0)) then 
		status[cpos]=1 --Scrollrad Klick wenn 0 wird 1 toggle
		timeprev_Taster = timenow
	end
	if ((cpress ==1) and ( lastStatus[cpos] ==1)) then 
	    status[cpos]=0 --Scrollrad Klick wenn 1 wird 0 toggle
	end
	if ((timenow - timeprev_Taster) > Zeit_Taster/10) and config[cpos].type == "momentary" then 
	    status[cpos]=0 --Zeit wenn Taster wenn 1 wird 0 toggle
	end
	
	i = 1
	
	local Button_w_off = 3 --Button Abstand Breite  
	local Button_h_off = 3 --Button Abstand Höhe 
	
	local Spalten_w = 128/Spalten -- 128 Pixel / Spaltenanzahl = Spalten Breite
	local Reihen_h = 40/Reihen -- 40 Pixel /  Reihenanzahl = Reihen Höhe
	
	local Button_w = (Spalten_w - Button_w_off - Button_w_off)
	local Button_h = (Reihen_h - Button_h_off - Button_h_off)

	for xp = 0, Spalten-1, 1 do -- X Achse 0-3 Schrittweite 1
		for yp = 0, Reihen-1, 1 do -- Y Achse 0-1 Schrittweite 1

			if i == cpos then -- Ausgewählter Schalter 
				lcd.drawFilledRectangle( (xp * Spalten_w) + Button_w_off, 12 + (yp * Reihen_h) + Button_h_off, Button_w / 2, Button_h) -- Rechteck gefüllt Ausgewählter für Schalter X Y B H
				lcd.drawText( (xp * Spalten_w) + Button_w_off + 2, 12 + (yp * Reihen_h) + Button_h / 2, config[i].name_s, SMLSIZE + INVERS) -- Text Ausgewählter Schalter 
			else -- nicht Ausgewählter Schalter
				lcd.drawRectangle( (xp * Spalten_w) + Button_w_off, 12 + (yp * (Reihen_h)) + Button_h_off , Button_w / 2, Button_h) -- Rechteck für nicht Ausgewählter Schalter X Y B H
				lcd.drawText( (xp * Spalten_w) + Button_w_off + 2, 12 + (yp * Reihen_h) + Button_h / 2, config[i].name_s, SMLSIZE) -- Text nicht Ausgewählter Schalter 
			end
			lastStatus[cpos] = status[cpos] -- Schalter True ?
			if status[ i] == 1 then --Schalter ein
				lcd.drawFilledRectangle((xp * Spalten_w) + Button_w_off + (Button_w / 2), 12 + (yp * Reihen_h) + Button_h_off , (Button_w / 2), Button_h) -- Rechteck wenn Schalter ein X Y B H
			else
				lcd.drawRectangle((xp * Spalten_w) + Button_w_off + (Button_w / 2), 12 + (yp * Reihen_h) + Button_h_off , (Button_w / 2), Button_h) -- Rechteck wenn Schalter aus X Y B H
			end
			i = i + 1
			if i > Buttons then -- Anzahl Buttons erstellt Ende
				break
			end	
		end
		if i > Buttons then -- Anzahl Buttons erstellt Ende
			break
		end		
	end 

	lcd.drawFilledRectangle( 0, 0 , 128, 12) -- Schwazer Balken Oben
	lcd.drawText( 2, 2, name_b .."@".. Adresse , 0 + INVERS) -- Ueberschrift im Schwarzen Balken
	lcd.drawText( 10, 52, config[cpos].name, 0) -- Langbezeichnungen unter Schalter
    if Debug == 1 then	
		lcd.drawText ( 103, 4, model.getGlobalVariable(GlobalVariable - 1,Flugphase), SMLSIZE + INVERS) -- GlobalVariable anzeigen Debug 
	end
end

return { init=init, run=run, background=background }
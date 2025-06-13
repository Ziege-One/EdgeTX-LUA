local timeprev 
local running = false
local cpos = 1
local cpress = 0
local status ={0,0,0,0,0,0,0,0,}
local lastStatus ={0,0,0,0,0,0,0,0,}

-- Start Logicherschalter +7
local SwitchLS = 10

-- Bezeichnungen, wird als Ueberschrift angezeigt
local nm_b = "Beleuchtung"

-- Kurzbezeichnungen innerhalb des Schalters:
local nm_s = 
{
 "01", "02",
 "03", "04",
 "05", "06",
 "07", "08",
}
-- Langbezeichnungen, wird als Unterschrift angezeigt
local nm_l =
{
 "Positionslampen",
 "Schlepplicht",
 "Blaulicht",
 "Ankerlicht",
 "Rundum",
 "06",
 "07",
 "Suchscheinwerfer",
}

local function init()
	options = opt
    for variable = -1, 6 do --Alle 8 Logischen Schalter (z.B. Logischer Schalter L10 hat die ID 9)
		local ls = model.getLogicalSwitch(SwitchLS + variable); --Logischen Schalter auswählen 
		if (ls.func ~= LS_FUNC_STICKY) then
			model.setLogicalSwitch(SwitchLS + variable, {func = LS_FUNC_STICKY}); -- Auf Sticky setzen wenn noch nicht
			setStickySwitch(SwitchLS + variable, false); -- Auf False schalten
		else
			setStickySwitch(SwitchLS + variable, false); -- Auf False schalten
		end	
	end
end

local function background()
	if not running then -- einmal ausführen
      running = true
	  timeprev = getTime()
	end

	local timenow = getTime() -- 10ms Auflösung
  
	if timenow - timeprev > 20 then -- sind  200 ms vergengen ? 
		timeprev = timenow
	        
		--Schalterauswertung
		for Schalter = 1, 8 do --Alle 8 Schalter
	
		if (status[Schalter]==1) then --wenn Schalter True 
			if (not getLogicalSwitchValue(SwitchLS+Schalter-2)) then --wenn Logischen Schalter False
				setStickySwitch(SwitchLS+Schalter-2, true) --Logischen Schalter auf True
			end	
		elseif (status[Schalter]==0) then
			if (getLogicalSwitchValue(SwitchLS+Schalter-2)) then --wenn Logischen Schalter True
				setStickySwitch(SwitchLS+Schalter-2, false) --Logischen Schalter auf False
			end			
		end
	end
end

end

local function run(event)
	lcd.clear()
	-- Tasten rechts neben Display - + ENT / Scrollrad bei X9Lite
	if( event == EVT_ROT_RIGHT) then cpos = (cpos + 1)  % 10  -- 100 / EVT_PLUS_FIRST / Taste +
	elseif( event == EVT_ROT_LEFT) then cpos = (cpos -1) % 10  -- 101 / EVT_MINUS_FIRST /Taste -
	elseif( event ==  EVT_ENTER_FIRST) then cpress = 1 else cpress = 0 -- 98 / Taste ENT
	end

	if cpos == 0 then -- Positon als Umlauf 1-8 1-8 usw
		cpos = 8
	end  
	if cpos == 9 then
		cpos = 1
	end 
 
	if ((cpress ==1) and ( lastStatus[cpos] ==0)) then status[cpos]=1 --Scrollrad Klick wenn 0 wird 1 toggle
	end
	if ((cpress ==1) and ( lastStatus[cpos] ==1)) then status[cpos]=0 --Scrollrad Klick wenn 1 wird 0 toggle
	end
	i = 1
	for xp = 0, 3, 1 do -- X Achse 0-3 Schrittweite 1
	for yp = 15, 35, 20 do -- Y Achse 15-35 Schrittweite 20
		lcd.drawRectangle( (xp * 31) + 3, yp, 24, 12) -- Rechteck für Schalter
		if i == cpos then
			lcd.drawText( (xp * 31) + 6, yp + 3, nm_s[ i], SMLSIZE + INVERS) -- Ausgewählter Schalter 
		else
			lcd.drawText( (xp * 31) + 6, yp + 3, nm_s[ i], SMLSIZE) -- nicht Ausgewählter Schalter 
		end
		lastStatus[cpos] = status[cpos] -- Schalter True ?
		if status[ i] == 1 then
			lcd.drawFilledRectangle( (xp * 31) + 3 + 14, yp + 1 , 9, 10) -- Rechteck wenn Schalter True
		else
			lcd.drawLine((xp * 31) + 3 + 14,yp + 1,(xp * 31) + 3 + 14,yp + 1 + 10,SOLID,FORCE) -- Linie wenn Schalter False
		end
		i = i + 1
	end
 end 

	lcd.drawFilledRectangle( 0, 0 , 128, 12) -- Schwazer Balken Oben
	lcd.drawText( 2, 2, nm_b, 0 + INVERS) -- Ueberschrift im Schwarzen Balken
	lcd.drawText( 10, 52, nm_l[cpos], 0) -- Langbezeichnungen unter Schalter
end

return { init=init, run=run, background=background }
#!/usr/bin/lua

M = {}
-- Rules -------------------------------------------------------------------------
-- Отключение передачи в Mdm
function Rule1()
 if not Var.action then return; end
 local rt = string.find(Var.action, "cfgMdm_No")
 if rt then 
   logger:warn("Updating variable: cfgMdm to No")
   writeparam("cfgMdm", "No")
  end  
end
M.Rule1 = Rule1
-- Включение передачи в Mdm
function Rule2()
 if not Var.action then return; end
 local rt = string.find(Var.action, "cfgMdm_Yes")
 if rt then 
   logger:warn("Updating variable: cfgMdm to Yes")
   writeparam("cfgMdm", "Yes")
 end
end
M.Rule2 = Rule2
-- Отключение передачи в Thingspeak
function Rule3()
 if not Var.action then return; end
 local rt = string.find(Var.action, "cfgThingspeak_No")
 if rt then 
   logger:warn("Updating variable: cfgThingspeak to No")
   writeparam("cfgThingspeak", "No")
  end  
end
M.Rule3 = Rule3
-- Включение передачи в Thingspeak
function Rule4()
 if not Var.action then return; end
 local rt = string.find(Var.action, "cfgThingspeak_Yes")
 if rt then 
   logger:warn("Updating variable: cfgThingspeak to Yes")
   writeparam("cfgThingspeak", "Yes")
 end
end
M.Rule4 = Rule4
-- отключить регулировку
function Rule5()
 if not Var.action then return; end
 local rt = string.find(Var.action, "cfgHwork_No")
 if rt then 
   logger:warn("Updating variable: cfgHwork to 0")
   writeparam("cfgHwork", "0")
   Var.TimerCycleStart = nil
   Var.TimerManualCycleStart = nil
   Var.TimerPauseStart = nil
   Param.Hpause = 0
   Param.Hcycle = 0
   rt,status = pcall(setgpio, GPIO_FAN, GPIO_FAN_OFF)
   if not rt then logger:warn("Error set gpio Fan: %s",status); end
  end  
end
M.Rule5 = Rule5
-- включить регулировку
function Rule6()
 local rt,status
 if not Var.action then return; end
 local rt = string.find(Var.action, "cfgHwork_Yes")
 if rt then 
   logger:warn("Updating variable: cfgHwork to 1")
   if Cfg.Hwork == 0 then
    writeparam("cfgHwork", "1")
    Var.TimerCycleStart = nil
    Var.TimerPauseStart = nil
    Var.TimerManualCycleStart = nil
    Param.Hpause = 0
    Param.Hcycle = 0
   end
 end
end
M.Rule6 = Rule6
-- запуск вентилятора вручную
function Rule7()
  local rt,status
  if (not Param.Fan) or (Var.ButtonFlag == nil) then return; end
  if (not Var.action) and (Var.ButtonFlag ~= true) then return; end
  if Var.action then
    rt = string.find(Var.action, "StartFanManualFun")
  else
    rt = nil
  end
  if (rt or Var.ButtonFlag) and (Param.Fan == 0) then
    -- запуск вкетилятора
    Var.ButtonFlag = false
    rt,status = pcall(setgpio, GPIO_FAN, GPIO_FAN_ON)
    if not rt then logger:warn("Error set gpio Fan: %s",status); end
    Var.TimerManualCycleStart = socket.gettime();
    Var.TimerCycleStart = nil
    Var.TimerPauseStart = nil
    Param.Hpause = 0
    Param.Hcycle = 0
    logger:warn("Start Fan manual")
  end
end
M.Rule7 = Rule7
-- остановка вентилятора вручную
function Rule8()
  local rt, status, tm
  -- print("8_1")
  if (not Param.Fan) or (Param.Fan ~= 1) then return; end
  if  Var.ButtonFlag == nil then return; end
  if (not Var.action) and (not Var.TimerManualCycleStart) and (Var.ButtonFlag ~= true) then return; end
  if Var.action then
    rt = string.find(Var.action, "StopFanManualFun")
  else
    rt = nil
  end
  if Var.TimerManualCycleStart then
    tm = socket.gettime() - Var.TimerManualCycleStart
  else
    rm = nil
  end
  if rt or Var.ButtonFlag or ( tm and (tm > TIME_MANUAL_FAN)) then
    -- остановка вкнтилятора
    Var.TimerManualCycleStart = nil
    Var.TimerCycleStart = nil
    Var.TimerPauseStart = nil
    Param.Hpause = 0
    Param.Hcycle = 0
    Var.ButtonFlag = false
    rt,status = pcall(setgpio, GPIO_FAN, GPIO_FAN_OFF)
    if not rt then logger:warn("Error set gpio Fan: %s",status); end
    logger:warn("Stop Fan manual")
  end
end
M.Rule8 = Rule8
-- запуск вентилятора по влажности
function Rule9()
  if (not Cfg.Hwork) or (Cfg.Hwork ~= 1) then return; end
  if (not Param.Fan) or (Param.Fan ~= 0) then return; end
  if Var.TimerManualCycleStart or Var.TimerCycleStart or Var.TimerPauseStart then return; end
  if (not Param.Hcellar) or (not Cfg.Hstart) then return; end
  -- проверка абс. влажности
  if Param.HcellarA and Param.HgarageA and (Param.HcellarA <= Param.HgarageA) then return; end
  -- проверка на выпадение рассы
  if Param.HcellarA and Param.HgarageAC then
    if (Param.HcellarA > Param.HgarageAC) then return; end 
  end
  -- проверка влажности
  if Param.Hcellar > Cfg.Hstart then
    local rt, status
    rt,status = pcall(setgpio, GPIO_FAN, GPIO_FAN_ON)
    if not rt then logger:warn("Error set gpio Fan: %s",status); end
    Var.TimerCycleStart = socket.gettime()
    logger:debug("Start Fan cycle Hcellar=" .. Param.Hcellar)
  end
end
M.Rule9 = Rule9
-- остановка цикла по влажности
function Rule10()
 if (not Param.Fan) or (Param.Fan ~= 1) or (not Var.TimerCycleStart) then return; end
 if (not Param.Hcellar) or (not Cfg.Hstop) then return; end
  if Param.Hcellar <= Cfg.Hstop then
    local rt, status
    rt,status = pcall(setgpio, GPIO_FAN, GPIO_FAN_OFF)
    if not rt then logger:warn("Error set gpio Fan: %s",status); end
    Var.TimerCycleStart = nil
    -- запустить цикл паузы работы
    Var.TimerPauseStart = socket.gettime()
    Param.Hcycle = 0;
    logger:debug("Stop Fan cycle Hcellar=" .. Param.Hcellar)
  end
end
M.Rule10 = Rule10
-- остановка цикла по времени работы
function Rule11()
 if (not Param.Fan) or (Param.Fan ~= 1) or (not Var.TimerCycleStart) then return; end
 if (not Param.Hcellar) or (not Cfg.Hstop) then return; end
 local tm = socket.gettime() - Var.TimerCycleStart
 if tm >= Cfg.TimeCycleFan then
    local rt, status
    rt,status = pcall(setgpio, GPIO_FAN, GPIO_FAN_OFF)
    if not rt then logger:warn("Error set gpio Fan: %s",status); end
    Var.TimerCycleStart = nil
    -- запустить цикл паузы работы
    Var.TimerPauseStart = socket.gettime()
    Param.Hcycle = 0;
    logger:debug("Stop Fan cycle (timeout) Hcellar=" .. Param.Hcellar)
 else
   -- занести остаток секунд в переменную
   tm = Cfg.TimeCycleFan - tm
   tm = tm - tm%0.1
   Param.Hcycle = tm
 end
end
M.Rule11 = Rule11
-- обработка цикла паузы
function Rule12()
  if not Var.TimerPauseStart then return; end
  local tm = socket.gettime() - Var.TimerPauseStart
  if tm >= Cfg.TimePauseFan then
    Param.Hpause = 0
    Var.TimerPauseStart = nil
    logger:debug("End Pause Fan ")
  else
   -- занести остаток секунд в переменную
   tm = Cfg.TimePauseFan - tm
   tm = tm - tm%0.1
   Param.Hpause = tm
  end
end
M.Rule12 = Rule12

return M

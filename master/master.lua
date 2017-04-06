#!/usr/bin/lua

package.path = '/etc/master/lua/?.lua;/etc/master/?.lua;' .. package.path
require "socket"
require "logging.rolling_file"
DATA_PATH = '/var/data'
CFG_PATCH = '/etc/master/cfg'
GPIO_FAN = '0'
GPIO_FAN_ON = '1'
GPIO_FAN_OFF = '0'
-- время ручного запуска
TIME_MANUAL_FAN = 600
-- периодичность считывания внутренней температуры
TIN_CYCLE_TIME = 60

-- mqtt 
MQTT_RECONECT_TIME = 60
MQTT_SUBCRIBE_TOPICS = { 'Garage/cmd/#' }

require "private"

-- функция логов
logger = logging.rolling_file("/var/log/masterlua.log", 1024*100, 5)


-- работа с MQTT
function callback(
    topic,    -- string
    message)  -- string

    print("Topic: " .. topic .. ", message: '" .. message .. "'")

    if (topic == "Garage/cmd/cfgHstart") then
        if (tonumber(message) ~= nil) then
            writeparam("cfgHstart",message)
            writecfgparam("cfgHstart",message)
            Cfg.cfgHstart = message
            Cfg.Hstart = tonumber(message)
        end
    end
    if (topic == "Garage/cmd/cfgHstop") then
        if (tonumber(message) ~= nil) then
            writeparam("cfgHstop",message)
            writecfgparam("cfgHstop",message)
            Cfg.cfgHstop = message
            Cfg.Hstop = tonumber(message)
        end
    end
    if (topic == "Garage/cmd/cfgTimeCycleFan") then
        if (tonumber(message) ~= nil) then
            writeparam("cfgTimeCycleFan",message)
            writecfgparam("cfgTimeCycleFan",message)
            Cfg.cfgTimeCycleFan = message
            Cfg.TimeCycleFan = tonumber(message)*60
        end
    end
    if (topic == "Garage/cmd/cfgTimePauseFan") then
        if (tonumber(message) ~= nil) then
            writeparam("cfgTimePauseFan",message)
            writecfgparam("cfgTimePauseFan",message)
            Cfg.cfgTimePauseFan = message
            Cfg.TimePauseFan = tonumber(message)*60
        end
    end
    if (topic == "Garage/cmd/cfgHwork") then
        if (message == "ON") then
            writeparam("cfgHwork","1")
            writecfgparam("cfgHwork","1")
            Cfg.cfgHwork = "1"
            Cfg.Hwork = 1
        end
        if (message == "OFF") then
            writeparam("cfgHwork","0")
            writecfgparam("cfgHwork","0")
            Cfg.cfgHwork = "0"
            Cfg.Hwork = 0
        end
    end
    if (topic == "Garage/cmd/cfgVpnChk") then
        if (message == "ON") then
            writeparam("cfgVpnChk","1")
            writecfgparam("cfgVpnChk","1")
            Cfg.cfgVpnChk = "1"
        end
        if (message == "OFF") then
            writeparam("cfgVpnChk","0")
            writecfgparam("cfgVpnChk","0")
            Cfg.cfgVpnChk = "0"
        end
    end
    if (topic == "Garage/cmd/cfgWdog") then
        if (message == "ON") then
            writeparam("cfgWdog","1")
            writecfgparam("cfgWdog","1")
            Cfg.cfgWdog = "1"
        end
        if (message == "OFF") then
            writeparam("cfgWdog","0")
            writecfgparam("cfgWdog","0")
            Cfg.cfgWdog = "0"
        end
    end
    if (topic == "Garage/cmd/cfgThingspeak") then
        if (message == "ON") then
            writeparam("cfgThingspeak","Yes")
            writecfgparam("cfgThingspeak","Yes")
            Cfg.cfgThingspeak = "Yes"
        end
        if (message == "OFF") then
            writeparam("cfgThingspeak","No")
            writecfgparam("cfgThingspeak","No")
            Cfg.cfgThingspeak = "No"
        end
    end
    if (topic == "Garage/cmd/cfgMdm") then
        if (message == "ON") then
            writeparam("cfgMdm","Yes")
            writecfgparam("cfgMdm","Yes")
            Cfg.cfgMdm = "Yes"
        end
        if (message == "OFF") then
            writeparam("cfgMdm","No")
            writecfgparam("cfgMdm","No")
            Cfg.cfgMdm = "No"
        end
    end
end



-- функция чтения конфигурации
function readconfig(x)
  readcfgparam(x, "cfgHstart")
  readcfgparam(x, "cfgHstop")
  readcfgparam(x, "cfgHwork")
  readcfgparam(x, "cfgMdm")
  readcfgparam(x, "cfgThingspeak")
  readcfgparam(x, "cfgVpnChk")
  readcfgparam(x, "cfgWdog")
  readcfgparam(x, "cfgTimeCycleFan")
  readcfgparam(x, "cfgTimePauseFan")
  -- перевод в number для расчетов
  x.Hstart = tonumber(x.cfgHstart)
  if not x.Hstart then logger:warn("Error convert to num Hsart: %s", x.cfgHstart); end
  x.Hstop = tonumber(x.cfgHstop)
  if not x.Hstop then logger:warn("Error convert to num Hstop: %s", x.cfgHstop); end
  x.Hwork = tonumber(x.cfgHwork)
  if not x.Hwork then logger:warn("Error convert to num Hwork: %s", x.cfgHwork); end

  x.TimeCycleFan = tonumber(x.cfgTimeCycleFan)*60
  if not x.TimeCycleFan then logger:warn("Error convert to num TimeCycleFan %s", x.cfgTimeCycleFan); end

  x.TimePauseFan = tonumber(x.cfgTimePauseFan)*60
  if not x.TimePauseFan then logger:warn("Error convert to num TimePauseFan %s", x.cfgTimePauseFan); end
end

-- чтение конфирурационного параметра с записью при изменении
function readcfgparam(x, name)
  local rt, vl, status
  rt,vl = pcall(readparam, name)
  if rt == false then
    if rt==false then logger:warn("Error read %s: %s", name, vl); end
    x[tostring(name)] = nil;
  else
    -- сохранить в EEPROM при изменении значения
    if  x[tostring(name)] and (x[tostring(name)] ~= vl) then
      logger:debug("Save to EEPROM %s=%s",name, vl)
      rt, status = pcall(writecfgparam, name, vl)
      if rt==false then logger:warn("Error write %s: %s", name, status); end
    end
    x[tostring(name)] = vl
  end;
end

-- сохранение параметров для обмена с WEB сервером
function saveparms(x)
  local rt, status
  for name,vl in pairs(x) do
    rt,status = pcall(writeparam, name, vl)
    if not rt then logger:warn("Error write %s: %s", name, status); end
  end
  -- запись значение при ошибке считывания тегов 
  if not x.Hcellar then rt,status = pcall(writeparam, "Hcellar", "-1"); end
  if not x.HcellarA then rt,status = pcall(writeparam, "HcellarA", "-1"); end
  if not x.Tcellar then rt,status = pcall(writeparam, "Tcellar", "-1"); end
  if not x.Hgarage then rt,status = pcall(writeparam, "Hgarage", "-1"); end
  if not x.HgarageA then rt,status = pcall(writeparam, "HgarageA", "-1"); end
  if not x.Tgarage then rt,status = pcall(writeparam, "Tgarage", "-1"); end
  if not x.Tin then rt,status = pcall(writeparam, "Tin", "-1"); end
   
  --формирования строки для передачи Thingspeak
  local str=""
  if x.Hcellar 	then str = str .. string.format("&field1=%.1f", x.Hcellar); end
  if x.Tcellar 	then str = str .. string.format("&field2=%.1f", x.Tcellar); end
  if x.Tgarage 	then str = str .. string.format("&field3=%.1f", x.Tgarage); end
  if x.Fan 	then str = str .. string.format("&field4=%d", x.Fan); end
  if x.Tin 	then str = str .. string.format("&field5=%.1f", x.Tin); end
  if x.Hgarage 	then str = str .. string.format("&field6=%.1f", x.Hgarage); end
  rt,status = pcall(writeparam, "strThingspeak", str)
end

-- сохранение параметра в MQTT
function publishnumparam(x, s, dlt, mqtt_client, topic)
    if ( mqtt_client.connected == true) then
        if x then
            if (s == nil) or (math.abs(x-s) >= dlt) then
                mqtt_client:publish(topic, tostring(x), true)
                print("Mqtt publish " .. topic .. "=" .. tostring(x))
                return x
            else
                if (x == 0) and (s ~= 0) then
                    mqtt_client:publish(topic, tostring(x), true)
                    print("Mqtt publish1 " .. topic .. "=" .. tostring(x))
                    return x
                else
                    return s
                end
            end
        else
            if (s ~= nil) then
                mqtt_client:publish(topic, "NULL", true)
                print("Mqtt publish " .. topic .. "=NULL")
            end
            return x
        end
    else
        return s
    end
end 

function publishboolmparam(x, s, mqtt_client, topic)
    if (mqtt_client.connected == true) then
        if (x ~= nil) then
            if (s == nil) or (x ~= s) then
                mqtt_client:publish(topic, x, true)
                print("Mqtt publis2 " .. topic .. "=" .. tostring(x))
            end
            return x
        else
            if (s ~= nil) then
                mqtt_client:publish(topic, "NULL", true)
                print("Mqtt publish " .. topic .. "=NULL")
                return x
            end
        end
    else
        return s
    end
end

function publishonoffparam(x, s, mqtt_client, topic, onstr)
    if (mqtt_client.connected == true) then
        if (x ~= nil) then
            if (s == nil) or (x ~= s) then
                if(x == onstr) then
                    mqtt_client:publish(topic, "ON", true)
                    print("Mqtt publis2 " .. topic .. "=ON")
                else
                    mqtt_client:publish(topic, "OFF", true)
                    print("Mqtt publis2 " .. topic .. "=OFF")

                end
            end
            return x
        else
            if (s ~= nil) then
                mqtt_client:publish(topic, "NULL", true)
                print("Mqtt publish " .. topic .. "=NULL")
                return x
            end
        end
    else
        return s
    end
end


function initmqttsave(s)
    s.Hcellar = -30000
    s.HcellarA = -30000
    s.Tcellar = -30000
    s.Hgarage = -30000
    s.HgarageA = -30000
    s.Tgarage = -30000
    s.Tin = -30000
    s.Hpause = -30000
    s.Hcycle = -30000

    s.Fan = -30000
    s.cfgHstart = ' '
    s.cfgHstop = ' '
    s.cfgTimeCycleFan = ' '
    s.cfgTimePauseFan = ' '

    s.cfgHwork = ' '
    s.cfgMdm = ' '
    s.cfgThingspeak = ' '
    s.cfgVpnChk = ' '
    s.cfgWdog = ' '
end



function publishparams(x,s,Cfg,mqtt_client) 
      
    if (Var.MqttStatusSend == false) and (mqtt_client.connected == true) then
        mqtt_client:publish('Garage/status','CON', true)
         Var.MqttStatusSend = true
    end
   
    s.Hcellar = publishnumparam(x.Hcellar, s.Hcellar, 0.1, mqtt_client, "Garage/Hcellar")
    s.HcellarA = publishnumparam(x.HcellarA, s.HcellarA, 0.1, mqtt_client, "Garage/HcellarA")
    s.Tcellar = publishnumparam(x.Tcellar, s.Tcellar, 0.1, mqtt_client, "Garage/Tcellar")
    s.Hgarage = publishnumparam(x.Hgarage, s.Hgarage, 0.1, mqtt_client, "Garage/Hgarage")
    s.HgarageA = publishnumparam(x.HgarageA, s.HgarageA, 0.1, mqtt_client, "Garage/HgarageA")
    s.Tgarage = publishnumparam(x.Tgarage, s.Tgarage, 0.1, mqtt_client, "Garage/Tgarage")
    s.Tin = publishnumparam(x.Tin, s.Tin, 0.15, mqtt_client, "Garage/Tdir320")
    s.Hcycle = publishnumparam(x.Hcycle, s.Hcycle, 10, mqtt_client, "Garage/Hcycle")
    s.Hpause = publishnumparam(x.Hpause, s.Hpause, 10, mqtt_client, "Garage/Hpause")
    
    
    
    s.Fan = publishboolmparam(x.Fan, s.Fan, mqtt_client, "Garage/Fan")
    s.cfgHstart = publishboolmparam(Cfg.cfgHstart, s.cfgHstart, mqtt_client, "Garage/cfgHstart")
    s.cfgHstop = publishboolmparam(Cfg.cfgHstop, s.cfgHstop, mqtt_client, "Garage/cfgHstop")
    s.cfgTimeCycleFan = publishboolmparam(Cfg.cfgTimeCycleFan, s.cfgTimeCycleFan, mqtt_client, "Garage/cfgTimeCycleFan")
    s.cfgTimePauseFan = publishboolmparam(Cfg.cfgTimePauseFan, s.cfgTimePauseFan, mqtt_client, "Garage/cfgTimePauseFan")


    s.cfgHwork = publishonoffparam(Cfg.cfgHwork, s.cfgHwork, mqtt_client, "Garage/cfgHwork","1")
    s.cfgThingspeak = publishonoffparam(Cfg.cfgThingspeak, s.cfgThingspeak, mqtt_client, "Garage/cfgThingspeak","Yes")
    s.cfgMdm = publishonoffparam(Cfg.cfgMdm, s.cfgMdm, mqtt_client, "Garage/cfgMdm","Yes")
    s.cfgVpnChk = publishonoffparam(Cfg.cfgVpnChk, s.cfgVpnChk, mqtt_client, "Garage/cfgVpnChk","1")
    s.cfgWdog = publishonoffparam(Cfg.cfgWdog, s.cfgWdog, mqtt_client, "Garage/cfgWdog","1")
 
end


-- чтение параметра
function readparam(name)
  local pfile = io.open(DATA_PATH .. "/" .. tostring(name) .. ".dat")
  if pfile == nil then 
    logger:warn("Error read param: %s", DATA_PATH .. "/" .. tostring(name) .. ".dat")
    return
  end
  local pdata = pfile:read();
  pfile:close();
  
  return pdata  
end
-- чтение и очистка камандного файла
function readaction()
  local file = io.open(DATA_PATH .. "/incoming_action.txt")
  if file == nil then return nil; end
  local data = file:read("*a");
  file:close();
  os.execute("rm -f " .. DATA_PATH .. "/incoming_action.txt")
  return data  
end

-- запись параметров
function writeparam(name, val)
  local file = io.open(DATA_PATH .. "/" .. tostring(name) .. ".dat","w")
  file:write(tostring(val));
  file:close();
end
function writecfgparam(name, val)
  local file = io.open(CFG_PATCH .. "/" .. tostring(name) .. ".dat","w")
  file:write(tostring(val));
  file:close();
end

-- функции чтения датчиков

function readdht(fname)
	local dhtfile = io.open(fname)
	local dhtfun = string.gmatch(dhtfile:read(),"[^ ]+")
	dhtfile:close()
	if dhtfun() == "OK" then
		return tonumber(dhtfun()),tonumber(dhtfun())
	else
		return nil,nil
	end
end

--[[
function w1_read(num)
	local w1file = io.open("/1wire/" .. num .. "/temperature")
	local w1data = w1file:read();
	w1file:close();
	return tonumber(w1data)
end
]]

function w1_read() 
	local w1file = io.popen("digitemp_DS9097 -t 0  -q  -c /etc/master/digitemp.conf")
	local w1data = w1file:read("*a");
	w1file:close();
	return tonumber(w1data)
end

function readgpio(num)

	local gpiofile = io.open("/sys/class/gpio/gpio" .. num .. "/value")
	local gpiodata = gpiofile:read();
	gpiofile:close();
	return tonumber(gpiodata)
end

function setgpio(num, val)
  local gpiofile = io.open("/sys/class/gpio/gpio" .. tostring(num) .. "/value","w")
  gpiofile:write(tostring(val));
  gpiofile:close();
end

-- работа с файлами
function exists(name) 
  if type(name)~="string" then 
    return false 
  end 
  return os.rename(name,name) and true or false 
end 

function isFile(name) 
  if type(name)~="string" then 
    return false 
  end
  if not exists(name) then 
    return false 
  end
  local f = io.open(name)
  if f then 
    f:close()
    return true
  end
  return false
end 

function isDir(name)
  return (exists(name) and not isFile(name))
end


-- Rules
myrules = require "rules"

-- --------------------------------------------------------------
-- иницилизация
--
print("Hello")
logger = logging.rolling_file("/var/log/masterlua.log", 1024*100, 5)
logger:setLevel(logging.WARN)

Param = {}
Cfg = {}
Var = {}
SVar = {}
initmqttsave(SVar)
Param.Hcycle = 0
Param.Hpause = 0
local error_message = nil
-- ожидание окончания инициализации
logger:error("Master cycle start wait")
socket.sleep(45)
print("Master cycle init")
logger:error("Master cycle init")
-- Создание директории
if exists("/var/data/") == false then
  logger:debug("dir is not exist: %s", DATA_PATH)
  os.execute("mkdir " .. DATA_PATH)
  os.execute("chmod 0666 " .. DATA_PATH)
else
  -- очистить папку от данных
  logger:debug("clear dir: %s", DATA_PATH)
  os.execute("rm -f " .. DATA_PATH .. "/*")
end

-- востановить конфигурационные переменные
os.execute("cp " .. CFG_PATCH .. "/cfg*.dat " .. DATA_PATH .. "/")
-- установить gpio
Rs,status = pcall(setgpio, GPIO_FAN, GPIO_FAN_OFF)
if not Rs then logger:warn("Error set gpio Fan: %s",status); end
-- Подключение MQTT клиента к серверу
local MQTT = require "paho.mqtt"
MQTT.Utility.set_debug(false)
local mqtt_client = MQTT.client.create(MQTT_HOST, 1883, callback)
mqtt_client:auth(MQTT_USER, MQTT_PASSWORD)
Var.MqttStatusSend = false
mqtt_client:connect("garage","Garage/status",0,1,"NOCON")
mqtt_client:subscribe(MQTT_SUBCRIBE_TOPICS)
if(mqtt_client.connected == true) then
    mqtt_client:publish('Garage/status','CON', true)
    Var.MqttStatusSend = true
end
Var.MqttConTime= socket.gettime()

-- основной цикл программы ----------------------------------------------------------
while true do
  
  -- чтение параметров --------------------------------------------------------------
  tstart = socket.gettime();
  Rs,Param.Hcellar,Param.Tcellar = pcall(readdht,"/sys/class/my/dht1")
  if Rs == false then Param.Hcellar=nil; end;
  --	print(string.format("Hcellar=%.1f Tcellar=%.1f",Param.Hcellar,Param.Tcellar))
  t1 = socket.gettime();
  Rs,Param.Hgarage,Param.Tgarage = pcall(readdht,"/sys/class/my/dht2")
  if Rs == false then Param.Hgarage=nil; end;
  t2 = socket.gettime();
  -- измерение внутренней температуры
  do
    local tm
    if Var.TinTime then tm = socket.gettime() - Var.TinTime; end
    if (not Var.TinTime) or (tm >= TIN_CYCLE_TIME) then
      Rs,Param.Tin = pcall(w1_read)
      if Rs == false then Param.Tin=nil; end;
      Var.TinTime = socket.gettime()
      logger:debug("Load Tin value")
    end
  end
  t3 = socket.gettime();
  Rs,Param.Fan = pcall(readgpio, "0")
  if Rs == false then Param.Fan=nil; end;
  -- чтение клавиши и определение нажатия
  Rs,Param.Button = pcall(readgpio, "6")
  if Rs == false then 
    Param.Button=nil; Var.ButtonFlag = false; Var.ButtonOld = nil
  else
    if Var.ButtonOld and (Param.Button == 0 and Var.ButtonOld == 1) then
      Var.ButtonFlag = true
      logger:warn("Button is pressed")
    else
      Var.ButtonFlag = false
    end
      Var.ButtonOld = Param.Button
  end;
  t4 = socket.gettime()
  -- чтение конфигурационных переменных
  readconfig(Cfg)
  t5 = socket.gettime()
  
  -- проверка работы программмы
  if exists(DATA_PATH .. "/work_chk") then
    logger:debug("Clear check work file")
    os.execute("rm -f " .. DATA_PATH .. "/work_chk")
  end
  
  -- чтение командного файла
  Var.action = readaction();
  if Var.action then logger:warn("Action : %s", Var.action) end
  
  -- расчет абсолютных влажностей
  if Param.Hcellar and Param.Tcellar then
    local t = tonumber(Param.Tcellar)
    local h = tonumber(Param.Hcellar)	
    local x = 17.67 * t/(243.5 + t)
    local e = 6.112 * math.exp(x) * h * 18.02
    Param.HcellarA = e / ((273.15 + t) * 100.00 * 0.08314)
  else
     Param.HcellarA = nil
  end
  if Param.Hgarage and Param.Tgarage then
    local t = tonumber(Param.Tgarage)
    local h = tonumber(Param.Hgarage)	
    local x = 17.67 * t/(243.5 + t)
    local e = 6.112 * math.exp(x) * h * 18.02
    Param.HgarageA = e / ((273.15 + t) * 100.00 * 0.08314)
  else
    Param.HgarageA = nil
  end
  if Param.HcellarA and Param.Tgarage then
    local t = tonumber(Param.Tgarage)
    local h = 100.0	
    local x = 17.67 * t/(243.5 + t)
    local e = 6.112 * math.exp(x) * h * 18.02
    Param.HgarageAC = e / ((273.15 + t) * 100.00 * 0.08314)
  else
    Param.HgarageAC = nil
  end

  
  -- обработка rules
  for name,fun in pairs(myrules) do
      local rt,status
      rt,status = pcall(fun); if not rt then logger:warn("Error execute %s: %s",name,status); end
      print(name)
  end


 -- do
--    local rt,status 
--    rt,status = pcall(Rule1); if not rt then logger:warn("Error execute rule0: %s",status); end
--    rt,status = pcall(Rule2); if not rt then logger:warn("Error execute rule2: %s",status); end
--    rt,status = pcall(Rule3); if not rt then logger:warn("Error execute rule3: %s",status); end
--    rt,status = pcall(Rule4); if not rt then logger:warn("Error execute rule4: %s",status); end
--    rt,status = pcall(Rule5); if not rt then logger:warn("Error execute rule5: %s",status); end
--    rt,status = pcall(Rule6); if not rt then logger:warn("Error execute rule6: %s",status); end
--    rt,status = pcall(Rule7); if not rt then logger:warn("Error execute rule7: %s",status); end
--    rt,status = pcall(Rule8); if not rt then logger:warn("Error execute rule8: %s",status); end
--    rt,status = pcall(Rule9); if not rt then logger:warn("Error execute rule9: %s",status); end
--    rt,status = pcall(Rule10); if not rt then logger:warn("Error execute rule10: %s",status); end
--    rt,status = pcall(Rule11); if not rt then logger:warn("Error execute rule11: %s",status); end
--    rt,status = pcall(Rule12); if not rt then logger:warn("Error execute rule12: %s",status); end
--  end
  
  
  
  saveparms(Param)
  t6 = socket.gettime()
  -- print("Heep is " .. collectgarbage("count"))
  -- collectgarbage("step",1000)
  tend = socket.gettime();
  --[[
  print("All " .. tend - tstart .. " Sec");
  print("dht1 " .. t1 - tstart .. " Sec");
  print("dht2 " .. t2 - t1 .. " Sec");
  print("w1 " .. t3 - t2 .. " Sec");
  print("gpio  " .. t4 - t3 .. " Sec");
  print("cfgparam  " .. t5 - t4 .. " Sec");
  print("saveparam  " .. t6 - t5 .. " Sec");
  print("heep  " .. tend - t6 .. " Sec");
 ]]
 -- mqtt
 -- print("Mqtt status is " .. tostring(mqtt_client.connected))
 if (mqtt_client.connected == true) then 
     error_message = mqtt_client:handler()
     if (error_message ~= nil) then
        print("MQTT " .. error_message)
        logger:error("MQTT " .. error_message)
        publishparams(Param,SVar,Cfg,mqtt_client)
     end
 else
    local tm
    if Var.MqttConTime then tm = socket.gettime() - Var.MqttConTime; end
    if (not Var.MqttConTime) or (tm >= MQTT_RECONECT_TIME) then
      print("Mqtt reconnect")
      mqtt_client:destroy()
      Var.MqttConTime= socket.gettime()
      mqtt_client = MQTT.client.create(MQTT_HOST, 1883, callback)
      mqtt_client:auth(MQTT_USER, MQTT_PASSWORD)
      mqtt_client:connect("garage","Garage/status",0,1,"NOCON")
      mqtt_client:subscribe(MQTT_SUBCRIBE_TOPICS)
      if(mqtt_client.connected == true) then
         mqtt_client:publish('Garage/status','CON', true)
         Var.MqttStatusSend = true
      end
     logger:error("Reconnect to MQTT server")
    end
 end


 logger:debug(string.format("Time cycle : %.1f ms",(tend - tstart)*1000))


  Param.Tcycle = tend-tstart;
  if Param.Tcycle < 2.0 and Param.Tcycle >= 0 then
    -- socket.sleep(2.0 - Param.Tcycle)
    while ((socket.gettime()- tstart) < 2.0) do
        socket.sleep(0.2)
        if (mqtt_client.connected == true) then 
            error_message = mqtt_client:handler()
            if (error_message ~= nil) then
                print("MQTT " .. error_message)
                logger:error("MQTT " .. error_message)
            end
            publishparams(Param,SVar,Cfg,mqtt_client)
        end
    end
  else
    socket.sleep(2.0)
  end
  Param.Tcycle = Param.Tcycle*1000
end

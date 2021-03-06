--------------------------------------------------------------------------------
-- energy-monitor v0.2 A program to monitor a Draconic Evolution Energy Core.
-- Copyright (C) 2017 by Luisau  -  luisau.mc@gmail.com
-- 
--    This program is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--    
--    This program is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with this program.  If not, see <http://www.gnu.org/licenses/>
--
-- For Documentation and License see
--  /usr/share/doc/energy-monitor/README.md
--  
-- Repo URL:
-- https://github.com/OpenPrograms/luisau-Programs/tree/master/src/energy-monitor
--------------------------------------------------------------------------------

require("energy-monitor-lib")
local sides = require("sides")

--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

-- redstoneSide: side to emit a redstone signal when the threshold is reached
-- nil to disable this feature (i.e.: local side = nil  )
local side = sides.bottom

-- threshold: Minimum threshold required to emit a redstone signal
-- Valid values: 1 to 100
local threshold = 75

-- step: run interval in seconds.
local step = 1

-- debug: print aditional debug info (usually at start).
local debug = true

-- name: Name of your Energy Core
local name = "Energy Core"

--------------------------------------------------------------------------------
-- Constants and Globals
--------------------------------------------------------------------------------
local storageName = "draconic_rf_storage"
local initDelay = 1
local startX = 1
local startY = 1
local gaugeHeight = 3
local highPeak = 1
local lowPeak = -1
local lastX = 1

--------------------------------------------------------------------------------
-- Prints the current energy values
--------------------------------------------------------------------------------
function printEnergy (core, term)
  local gpu = term.gpu()
  local w, h = gpu.getResolution()
  gpu.fill(startX,startY,w,h, " ")

  printHeader (term, startX, startY, name, w)

  -- empty gauge
  gpu.setBackground(0xFF0000)
  gpu.fill (startX, startY+1, w, gaugeHeight, " ")
  local currentWidth = math.ceil (core:getLastPercentStored() * w / 100)

  -- stored gauge
  gpu.setBackground(0x00FF00)
  gpu.fill (startX, startY+1, currentWidth, gaugeHeight, " ")

  -- percent on moving gauge
  gpu.setForeground(0x000000)
  local textX = currentWidth + 2
  local textBackground = 0xFF0000
  if currentWidth >= (w - 10) then
    textBackground = 0x00FF00
    textX = w - 16
  end
  gpu.setBackground(textBackground)
  term.setCursor(textX, math.ceil (gaugeHeight/2)+startY)
  term.write (string.format("%.2f", core:getLastPercentStored()) .. "%")

  -- current stored energy / max energy
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  term.setCursor (startX, startY + gaugeHeight + 1)
  term.write (formatNumber(core:getLastEnergyStored()) .. " / " ..
    formatNumber(core:getMaxEnergyStored()) .. "   ("..
    string.format("%.2f", core:getLastPercentStored()) .. "%)")
end

--------------------------------------------------------------------------------
-- Prints the change on energy levels
--------------------------------------------------------------------------------
function printEnergyChange (change, term, histogram)
  histogram:render(change)
end

--------------------------------------------------------------------------------
-- Updates values on screen continuously (until interrupted)
--------------------------------------------------------------------------------
function run ()
  local core, term, component =
    init (storageName, "graphic", debug, initDelay, threshold)

  local histogram = Histogram:create(term, startX, startY + gaugeHeight + 2)

  if core == nil then
    return 1
  end

  term.clear()
  os.sleep (step)
  while isRunning() do
    local energyChange = core:getEnergyChange()
    printEnergy (core, term)
    printEnergyChange (energyChange, term, histogram)
    checkThreshold (term, core, startX, side)
    os.sleep(step)
  end
  
  return 0
end


--------------------------------------------------------------------------------
-- Main Program
--------------------------------------------------------------------------------
local exitCode = run ()
if exitCode ~= 0 then
  print ("An internal error occurred. Exit code ".. exitCode)
else
  print ("Exiting... [exit code: "+exitCode+"]")
end

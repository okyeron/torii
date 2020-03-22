--  **\_____________/**
--      ____________
--      \\//   \\//  
--        ||||       ||||
--        ||||       ||||   torii
--        ||||       ||||   
--        ||||       ||||   ( gates )
--
-- v0.2.5 @okyeron
--      |||||||||||||||||||||||||||||

engine.name = 'R'

local R = require 'r/lib/r'
local Option = require 'params/option'
local Formatters = require 'formatters'
local MusicUtil = require 'musicutil'

local sliders = {}
local sequence = {}

local edit = 0
local accum = 1
local step = 0
local thresh = 0
local bypass = false
local default_bpm = 130
local seq_length = 32

local BeatClock = require 'beatclock'
local clk = BeatClock.new()
clk.steps_per_beat = 8
clk.beats_per_bar = 8
local clk_midi = midi.connect()
clk_midi.event = function(data)
  clk:process_midi(data)
end

local grds = {}
local grid_device
local grid_w = 0
local grid_h = 0
local devicepos = 1


local k = metro.init()
k.count = -1
k.time = 0.05
k.event = function(stage)
end

function step_event()
    step = (step + 1) % seq_length
  --tab.print(sliders)
  
  --if sliders[step+1] > thresh then
  if sequence[step+1].lev > thresh then
    if bypass == false then 
      engine.set("Env.Gate", 1)
      engine.set("FEnv.Gate", 1)
      --rndo = sliders[step+1]/100
      rndo = sequence[step+1].lev/100
      engine.set("EnvFilter.FM", rndo)
    end
  else
    if bypass == false then 
      engine.set("Env.Gate", 0)
      engine.set("FEnv.Gate", 0)
    end
  end
  redraw()
  gridredraw()

end
function randomize()
  for i=1,seq_length do
    sliders[i] = 0
    sequence[i].on = 0
    sequence[i].lev = 0
    if i % 2 ~= 0 then
      if i+math.random(1,seq_length) <= i+math.random(1,seq_length) then 
        sliders[i] = 0
        sequence[i].on = 0
      else 
        sliders[i] = math.random(1,100)
        sequence[i].on = 1
        sequence[i].lev = math.random(1,100)
      end
    end 
  end 
end 

-- INIT

function init()
  -- grid connect
  connect()
  get_grid_names()
  
  -- setup grid params
  params:add{type = "option", id = "grid_device", name = "Grid", options = grds , default = 1,
    action = function(value)
      grid_device:all(0)
      grid_device:refresh()
      grid_device.key = nil
      --grid.cleanup()
      grid_device = grid.connect(value)
      grid_device.key = grid_key
      grid.update_devices()
      grid_dirty = true
      grid_w = grid_device.cols
      grid_h = grid_device.rows
      --print (grid_w, grid_h)
      
      grds = {}
      get_grid_names()
      params.params[1].options = grds
      
      devicepos = value
      print ("grid ".. devicepos .." selected " .. grds[devicepos].." "..grid_w .."x"..grid_h)
      
    end}

  for i=1,seq_length do
    sliders[i] = 0
    sequence[i] = {['on']=0, ['lev']=0} 
  
    if i % 2 ~= 0 then
      if i+math.random(1,seq_length) <= i+math.random(1,seq_length) then 
        sliders[i] = 0
        sequence[i].on = 0
      else 
        sliders[i] = math.random(1,100)
        sequence[i].on = 1
        sequence[i].lev = math.random(1,100)
      end
    end 
  end 
  

  clk.on_step = step_event
--  clk.on_stop = stop
--  clk.on_select_internal = function() clk:start() end
--  clk.on_select_external = reset_pattern
  clk:add_clock_params()
  params:set("bpm", default_bpm)

  engine.new("Env", "ADSREnv")
  engine.new("FEnv", "ADSREnv")
  engine.new("Filter", "MMFilter")
  engine.new("EnvFilter", "MMFilter")
  engine.new("Amp", "Amp")
  engine.new("SoundIn", "SoundIn")
  engine.new("SoundOut", "SoundOut")
  engine.new("Delay", "Delay")


  --engine.new("FreqGate", "FreqGate")
  engine.new("LFO", "MultiLFO")
  engine.new("FilterMod", "LinMixer")
  --engine.new("Osc", "PulseOsc")

  --engine.set("Osc.FM", 1)

  --engine.connect("FreqGate/Frequency", "OscFM")
  --engine.connect("FreqGate/Gate", "Env/Gate")
  --engine.connect("LFO/Sine", "Osc/PWM")
  --engine.connect("LFO/Sine", "FilterMod/In1")
  --engine.connect("Env/Out", "FilterMod/In2")
  --engine.connect("FilterMod/Out", "Filter/Frequency")


  engine.connect("SoundIn/Left", "Filter*In")
  engine.connect("SoundIn/Right", "Filter*In")
  engine.connect("Filter/Lowpass", "EnvFilter*In")

  --engine.connect("SoundIn/Left", "EnvFilter*In")
  --engine.connect("SoundIn/Right", "EnvFilter*In")
  engine.connect("EnvFilter/Lowpass", "Amp*In")
  
  engine.connect("Env/Out", "Amp*Lin")
  engine.connect("FEnv/Out", "EnvFilter*FM")

  engine.connect("Amp/Out", "Delay*In")
  engine.connect("Delay/Out", "SoundOut*Left")
  engine.connect("Delay/Out", "SoundOut*Right")

  engine.connect("Amp/Out", "SoundOut*Left")
  engine.connect("Amp/Out", "SoundOut*Right")


  local midi_note_list = {}
  for i=0,127 do
    midi_note_list[i] = i
  end

--  local gate = Option.new("gate", "Gate", {0, 1})
--  gate.action = function(value)
    --engine.set("Env.Gate", value-1)
    --engine.set("FEnv.Gate", value-1)
--  end
--  params:add { param=gate }

--  local note = Option.new("note", "Note", midi_note_list, 60)
--  note.action = function(value)
--    engine.set("FreqGate.Frequency", MusicUtil.note_num_to_freq(value))
--  end
--  params:add { param=note }

-- EnvFilter.Frequency
  local envfilterfreq_spec = R.specs.MMFilter.Frequency:copy()
  envfilterfreq_spec.default = 20000
  params:add {
    type="control", id="envfilterfreq_spec",name="EnvFilter.Frequency",controlspec=envfilterfreq_spec,
    action=function(value) 
      engine.set("EnvFilter.Frequency", value)
    end
  }

-- EnvFilter.FM
  local envfilterfm_spec = R.specs.MMFilter.FM:copy()
  envfilterfm_spec.default = 1
  params:add {
    type="control", id="envfilterfreq_spec",name="EnvFilter.FM",controlspec=envfilterfm_spec,
    formatter=Formatters.percentage,
    action=function(value) 
      engine.set("EnvFilter.FM", value)
    end
  }

  -- FEnv.Attack
  local fenv_attack_spec = R.specs.ADSREnv.Attack:copy()
  fenv_attack_spec.default = 5
  params:add {
    type="control", id="fenv_attack", name="FEnv.Attack", controlspec=fenv_attack_spec,
    action=function(value) 
      engine.set("FEnv.Attack", value)
    end
  }

  -- FEnv.Decay
  local fenv_decay_spec = R.specs.ADSREnv.Decay:copy()
  fenv_decay_spec.default = 5
  params:add {
    type="control",id="fenv_decay",name="FEnv.Decay",controlspec=fenv_decay_spec,
    action=function(value) 
      engine.set("FEnv.Decay", value)
    end
  }

  -- FEnv.Sustain
  local fenv_sustain_spec = R.specs.ADSREnv.Sustain:copy()
  fenv_sustain_spec.default = .5
  params:add {
    type="control",id="fenv_sustain",name="FEnv.Sustain",controlspec=fenv_sustain_spec,
    formatter=Formatters.percentage,
    action=function(value) 
      engine.set("FEnv.Sustain", value) 
    end
  }

  -- FEnv.Release
  local fenv_release_spec = R.specs.ADSREnv.Release:copy()
  fenv_release_spec.default = 5
  params:add {
    type="control",id="fenv_release",name="FEnv.Release",controlspec=fenv_release_spec,
    action=function(value) engine.set("FEnv.Release", value) end
  }


  -- Env.Attack
  local env_attack_spec = R.specs.ADSREnv.Attack:copy()
  env_attack_spec.default = 20
  params:add {
    type="control", id="env_attack", name="Env.Attack",controlspec=env_attack_spec,
    action=function(value) 
      engine.set("Env.Attack", value)
    end
  }

  -- Env.Decay
  local env_decay_spec = R.specs.ADSREnv.Decay:copy()
  env_decay_spec.default = 20
  params:add {
    type="control",id="env_decay",name="Env.Decay",controlspec=env_decay_spec,
    action=function(value) 
      engine.set("Env.Decay", value)
    end
  }

  -- Env.Sustain
  local env_sustain_spec = R.specs.ADSREnv.Sustain:copy()
  env_sustain_spec.default = .35
  params:add {
    type="control",id="env_sustain",name="Env.Sustain",controlspec=env_sustain_spec,
    formatter=Formatters.percentage,
    action=function(value) 
      engine.set("Env.Sustain", value) 
    end
  }

  -- Env.Release
  local env_release_spec = R.specs.ADSREnv.Release:copy()
  env_release_spec.default = 5
  params:add {
    type="control",id="env_release",name="Env.Release",controlspec=env_release_spec,
    action=function(value) engine.set("Env.Release", value) end
  }

  -- Delay.DelayTime
  local delay_time_spec = R.specs.Delay.DelayTime:copy()
  delay_time_spec.default = .1
  params:add {
    type="control",id="delay_time_spec",name="Delay.DelayTime",controlspec=delay_time_spec,
    action=function(value) engine.set("Delay.DelayTime", value) end
  }

  -- Filter.Frequency
  local filter_frequency_spec = R.specs.MMFilter.Frequency:copy()
  filter_frequency_spec.default = 20000
  params:add {
    type="control",id="filter_frequency",name="Filter.Frequency",controlspec=filter_frequency_spec,
    action=function(value) engine.set("Filter.Frequency", value) end
  }

  -- Filter.Resonance
  local filter_resonance_spec = R.specs.MMFilter.Resonance:copy()
  filter_resonance_spec.default = 0
  params:add {
    type="control",id="filter_resonance",name="Filter.Resonance",controlspec=filter_resonance_spec,
    formatter=Formatters.percentage,
    action=function(value) engine.set("Filter.Resonance", value) end
  }

  -- LFO > Filter.FM
  local lfo_to_filter_fm_spec = R.specs.MMFilter.FM:copy()
  lfo_to_filter_fm_spec.default = 0.4
  params:add {
    type="control",id="lfo_to_filter_fm",name="LFO > Filter.FM",controlspec=lfo_to_filter_fm_spec,
    formatter=Formatters.percentage,
    action=function(value) engine.set("FilterMod.In1", value) end
  }

  -- LFO.Frequency
  local lfo_frequency_spec = R.specs.MultiLFO.Frequency:copy()
  lfo_frequency_spec.default = 0.2
  params:add {
    type="control",id="lfo_frequency",name="LFO.Frequency",controlspec=lfo_frequency_spec,
    formatter=Formatters.round(0.001),
    action=function(value) engine.set("LFO.Frequency", value) end
  }

  -- Env > Filter.FM
  local lfo_to_filter_fm_spec = R.specs.LinMixer.In2:copy()
  lfo_to_filter_fm_spec.default = 0.3
  params:add {
    type="control",id="env_to_filter_fm",name="Env > Filter.FM",controlspec=lfo_to_filter_fm_spec,
    formatter=Formatters.percentage,
    action=function(value) engine.set("FilterMod.In2", value) end
  }

  engine.set("FilterMod.Out", 1)
  engine.set("Filter.FM", 1)
  engine.set("Env.Gate", 1)
  
  params:bang()
  --k:start()
  
  clk:start()
  
  -- end init
end

-- ENCODERS

function enc(n, delta)
  if n == 1 then
    --mix:delta("output", delta)
    params:delta("bpm", delta)
  elseif n == 2 then
    accum = (accum + delta) --% seq_length
    if accum > seq_length-1 then 
      accum = seq_length-1
    elseif accum < 0 then
      accum = 0
    end
    edit = accum
  elseif n == 3 then
    --sliders[edit+1] = sliders[edit+1] + delta
    --if sliders[edit+1] > 100 then sliders[edit+1] = 100 end
    --if sliders[edit+1] < 0 then sliders[edit+1] = 0 end

    sequence[edit+1].lev = sequence[edit+1].lev + delta
    if sequence[edit+1].lev > 100 then sequence[edit+1].lev = 100 end
    if sequence[edit+1].lev > 0 then sequence[edit+1].on = 1 end
    if sequence[edit+1].lev < 0 then 
      sequence[edit+1].lev = 0 
      sequence[edit+1].on = 0 
    end
  end
  redraw()
  gridredraw()
end

-- KEYS

function key(n, z)
  if n == 2 and z == 1 then
    randomize()
    redraw()
    gridredraw()
  elseif n == 3 and z == 1 then
    if bypass == false then
      bypass = true
      engine.set("Env.Gate", 1)
    else
      bypass = false
      engine.set("Env.Gate", 1)
    end

    redraw()
    gridredraw()
  end
end

function get_grid_names()
  -- Get a list of grid devices
  for id,device in pairs(grid.vports) do
    grds[id] = device.name
  end
end

function connect()
  grid.update_devices()
  grid_device = grid.connect(devicepos)
  grid_device.key = grid_key
  grid_device.add = on_grid_add
  grid_device.remove = on_grid_remove
  grid_w = grid_device.cols
  grid_h = grid_device.rows
end

function on_grid_add(g)
  print('on_grid_add')
end

function on_grid_remove(g)
  print('on_grid_remove')
end

-- GRID REDRAW

function gridredraw()
  grid_device:all(0)
  gridfrompattern()
  grid_device:refresh()
end 

-- GRID KEYS

function grid_key(x, y, z)
  -- 
  if y < 8 and z == 1 then
    --sliders[x] = math.floor(100 - (y-1)*16)
    sequence[x].lev = math.floor(100 - (y-1)*16)
  end
  if y == 8 and z == 1 then
    --if sliders[x] > 0 then
    if sequence[x].on > 0 then
      --sliders[x] = 0
      sequence[x].on = 0
    else
      --sliders[x] = 100
      sequence[x].on = 1
    end
  end

  redraw()
  gridredraw()
end

function gridfrompattern()
  for i=0, 15 do -- 16 steps available on grid
      --print ("edit",edit)
      --print ("step",step)
      if edit > 16 then offset = 16 else offset = edit end

      -- show level for each step
      
      --if sliders[i+1+offset] > 0 then
      if sequence[i+1+offset].lev > 0 then  
        --pos = math.floor(math.abs((100 - sliders[i+1+offset])/16 +1))
        pos = math.floor(math.abs((100 - sequence[i+1+offset].lev)/16 +1))
        if sequence[i+1+offset].on == 1 then
          ledlev = 6
        else
          ledlev = 3
        end 
        for w = 1,7 do 
          if pos <= w then
            grid_device:led(i+1, w, ledlev)
          end
        end
      end

      if i+edit == step then
        grid_device:led(i+1, 8, 15)
      --elseif sliders[i+1+offset] > 0 then
      elseif sequence[i+1+offset].on == 1 then
        grid_device:led(i+1, 8, 10)
      elseif i == edit then
        grid_device:led(i+1, 8, 5)
      else
        grid_device:led(i+1, 8, 0)
      end
      

  end
end

function redraw()

  screen.aa(1)
  screen.line_width(1.0)
  screen.clear()
  
  screen.move(0,62)
  screen.text("BPM:")
  screen.level(15)
  screen.move(20,62)
  screen.text(params:get("bpm")) 

  if bypass == true then
    screen.move(96,62)
    screen.text('BYPASS')
  end
  
  for i=0, seq_length - 1 do
    if i == edit then
      screen.level(15)
    else
      screen.level(2)
    end
    screen.move(1+i*4, 48)
    --screen.line(1+i*4, 46 - math.floor(sliders[i+1]/2))
    screen.line(1+i*4, 46 - math.floor(sequence[i+1].lev/2))
    screen.stroke()

    --if sliders[i+1] > 0 then
    if sequence[i+1].on == 1 then
      screen.level(15)
    else
      screen.level(2)
    end
    screen.move(1+i*4, 50)
    screen.line(1+i*4, 54)
    screen.stroke()

  end
  screen.level(10)
  screen.move(1+step*4, 50)
  screen.line(1+step*4, 54)
  screen.stroke()
  
  screen.update()
 
end

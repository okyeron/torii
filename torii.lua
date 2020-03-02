--  **\_____________/**
--      ____________
--      \\//   \\//  
--        ||||       ||||
--        ||||       ||||   torii
--        ||||       ||||   
--        ||||       ||||   ( gates )
--
-- v0.1.1 @okyeron
--      |||||||||||||||||||||||||||||

engine.name = 'R'

local R = require 'r/lib/r'
local Option = require 'params/option'
local Formatters = require 'formatters'
local MusicUtil = require 'musicutil'

local sliders = {}
local edit = 1
local accum = 1
local step = 0
local thresh = 1

local k = metro.init()
k.count = -1
k.time = 0.05
k.event = function(stage)
  step = (step + 1) % 32
  --print(sliders[step+1])
  if sliders[step+1] > thresh then
    engine.set("Env.Gate", 1)
    engine.set("FEnv.Gate", 1)
    rndo = sliders[step+1]/100
    --print(sliders[step+1])
    engine.set("EnvFilter.FM", rndo)
    --params:set("gate", 2)
  else
    engine.set("Env.Gate", 0)
    engine.set("FEnv.Gate", 0)
    --engine.set("EnvFilter.FM", 0)
    
    --params:set("gate", 1)
  end
  redraw()
end

function randomize()
  for i=1,32 do
    sliders[i] = 0
    if i % 2 ~= 0 then
      if i+math.random(1,32) <= i+math.random(1,32) then 
        sliders[i] = 0
      else 
        sliders[i] = math.random(1,100)
      end
    end 
  end 
end 

function init()
  
  for i=1,32 do
    sliders[i] = 0
    if i % 2 ~= 0 then
      if i+math.random(1,32) <= i+math.random(1,32) then 
        sliders[i] = 0
      else 
        sliders[i] = math.random(1,100)
      end
    end 
  end 
  
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

  --engine.connect("FreqGate/Frequency", "Osc/FM")
  --engine.connect("FreqGate/Gate", "Env/Gate")
  --engine.connect("LFO/Sine", "Osc/PWM")
  --engine.connect("LFO/Sine", "FilterMod/In1")
  --engine.connect("Env/Out", "FilterMod/In2")
  --engine.connect("FilterMod/Out", "Filter/Frequency")


--  engine.connect("SoundIn/Left", "Filter/In")
--  engine.connect("SoundIn/Right", "Filter/In")
--  engine.connect("Filter/Lowpass", "Amp/In")

  engine.connect("SoundIn/Left", "EnvFilter/In")
  engine.connect("SoundIn/Right", "EnvFilter/In")
  engine.connect("EnvFilter/Lowpass", "Amp/In")
  
  engine.connect("Env/Out", "Amp/Lin")
  engine.connect("FEnv/Out", "EnvFilter/FM")

  engine.connect("Amp/Out", "Delay/In")
  engine.connect("Delay/Out", "SoundOut/Left")
  engine.connect("Delay/Out", "SoundOut/Right")

  engine.connect("Amp/Out", "SoundOut/Left")
  engine.connect("Amp/Out", "SoundOut/Right")


  local midi_note_list = {}
  for i=0,127 do
    midi_note_list[i] = i
  end

  local gate = Option.new("gate", "Gate", {0, 1})
  gate.action = function(value)
    --engine.set("Env.Gate", value-1)
    --engine.set("FEnv.Gate", value-1)
  end
  params:add { param=gate }

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
  k:start()
end

function redraw()
  screen.aa(1)
  screen.line_width(1.0)
  screen.clear()

  for i=0, 31 do
    if i == edit then
      screen.level(15)
    else
      screen.level(2)
    end
    screen.move(1+i*4, 48)
    screen.line(1+i*4, 46-sliders[i+1]/2)
    screen.stroke()
  end

  screen.level(10)
  screen.move(1+step*4, 50)
  screen.line(1+step*4, 54)
  screen.stroke()

  screen.update()
end


function enc(n, delta)
  if n == 1 then
    mix:delta("output", delta)
  elseif n == 2 then
    accum = (accum + delta) % 32
    edit = accum
  elseif n == 3 then
    sliders[edit+1] = sliders[edit+1] + delta
    if sliders[edit+1] > 100 then sliders[edit+1] = 100 end
    if sliders[edit+1] < 0 then sliders[edit+1] = 0 end
  end
  redraw()
end

function key(n, z)
  if n == 2 and z == 1 then
    randomize()
    --sliders[1] = math.floor(math.random()*4)
    --for i=2, 32 do
    --  sliders[i] = sliders[i-1]+math.floor(math.random()*8)-3
    --end
    redraw()
  elseif n == 3 and z == 1 then
    for i=1, 32 do
      sliders[i] = sliders[i]+math.floor(math.random()*5)-2
    end
    redraw()
  end
end


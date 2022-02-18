local Softdelay={}

local Formatters=require 'formatters'

function Softdelay:new(o)
  o=o or {} -- create object if user does not provide one
  setmetatable(o,self)
  self.__index=self
  o.voices=o.voices or {softcut.VOICE_COUNT-1,softcut.VOICE_COUNT}

  params:add_group("SOFTDELAY",6)
  local voice_options={}
  for i=1,softcut.VOICE_COUNT/2 do
    table.insert(voice_options,(i*2-1).."+"..(i*2))
  end
  params:add_control("softdelay_level","level",controlspec.new(0,2,'lin',0.01,0.2,'amp',0.01/2))
  params:set_action("softdelay_level",function(x)
    for _,i in ipairs(o.voices) do
      softcut.level(i,x)
    end
  end)
  params:add {
    type='control',
    id='softdelay_fc',
    name='filter cutoff',
    controlspec=controlspec.new(20,20000,'exp',0,20000,'Hz'),
    formatter=Formatters.format_freq,
    action=function(value)
      for _,i in ipairs(o.voices) do
        softcut.post_filter_fc(i,value)
      end
    end
  }
  params:add {
    type='control',
    id='softdelay_rc',
    name='filter rq',
    controlspec=controlspec.new(0.05,1,'lin',0.01,1,'',0.01/1),
    action=function(value)
      for _,i in ipairs(o.voices) do
        softcut.post_filter_rq(i,value)
      end
    end
  }
  params:add {
    type='control',
    id='softdelay_beats',
    name='delay time',
    controlspec=controlspec.new(0.01,4,'lin',0.01,1,'beats',0.01/4),
    action=function(value)
      for _,i in ipairs(o.voices) do
        softcut.loop_end(i,260+clock.get_beat_sec()*value)
        softcut.position(i,260)
      end
    end
  }
  params:add {
    type='control',
    id='softdelay_feedback',
    name='feedback',
    controlspec=controlspec.new(0.01,1,'lin',0.01,0.5,'',0.01/1),
    action=function(value)
      for _,i in ipairs(o.voices) do
        softcut.pre_level(i,value)
      end
    end
  }
  params:add_option("softdelay_voice","sc voice",voice_options)
  params:set_action("softdelay_voice",function(x)
    print("softdelay: enabling voices")
    o.voices={x*2-1,x*2}
    audio.level_adc_cut(1)

    for buf,i in ipairs(o.voices) do
      softcut.level_input_cut(buf,i,1.0)
      softcut.enable(i,1)
      softcut.buffer(i,buf)
      softcut.level(i,params:get("softdelay_level"))
      softcut.loop(i,1)
      softcut.loop_start(i,260)
      softcut.loop_end(i,260+clock.get_beat_sec())
      softcut.position(i,260)
      softcut.rate(i,1.0)
      softcut.play(i,1)
      softcut.rec(i,1)
      softcut.fade_time(i,0.1)
      softcut.rec_level(i,0.5)
      softcut.pan(i,buf*2-3)
    end
  end)
  -- initialize
  params:set("softdelay_voice",softcut.VOICE_COUNT/2)
  params:set("softdelay_beats",0.25)
  params:set("softdelay_feedback",0.5)
  params:set("softdelay_level",1.0)
  prit("softdelay initialized")
  return o
end

return Softdelay


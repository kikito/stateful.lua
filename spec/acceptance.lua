require 'spec/lib/middleclass'

Stateful = require 'stateful'

context("Acceptance tests", function()

  local Enemy

  before(function()
    Enemy = class('Enemy'):include(Stateful)

    function Enemy:initialize(health)
      self.health = health
    end

    function Enemy:speak()
      return 'My health is ' .. tostring(self.health)
    end

  end)

  test("works on the basic case", function()

    local Immortal = Enemy:addState('Immortal')

    function Immortal:speak() return 'I am UNBREAKABLE!!' end
    function Immortal:die()   return 'I can not die now!' end

    local peter = Enemy:new(10)

    assert_equal(peter:speak(), 'My health is 10')

    peter:gotoState('Immortal')

    assert_equal(peter:speak(), 'I am UNBREAKABLE!!')
    assert_equal(peter:die(), 'I can not die now!')

    peter:gotoState(nil)

    assert_equal(peter:speak(), 'My health is 10')

  end)

  test("basic callbacks", function()

    local Drunk = Enemy:addState('Drunk')

    function Drunk:enteredState() self.health = self.health - 1 end
    function Drunk:exitedState() self.health = self.health + 1 end

    local john = Enemy:new(10)

    assert_equal(john:speak(), 'My health is 10')

    john:gotoState('Drunk')
    assert_equal(john:speak(), 'My health is 9')
    assert_type(john.enteredState, 'nil')
    assert_type(john.exitedState, 'nil')

    john:gotoState(nil)
    assert_equal(john:speak(), 'My health is 10')

  end)

  test("state inheritance", function()

    function Enemy:sing() return "dadadada" end
    function Enemy:singMore() return "lalalala" end

    local Happy = Enemy:addState('Happy')
    function Happy:speak() return "hehehe" end

    local Stalker = class('Stalker', Enemy)
    function Stalker.states.Happy:sing() return "I'll be watching you" end

    local VeryHappy = Stalker:addState('VeryHappy', Happy)
    function VeryHappy:sing() return 'hehey' end

    local jimmy = Stalker:new(10)

    assert_equal(jimmy:speak(), "My health is 10")
    assert_equal(jimmy:sing(), "dadadada")
    jimmy:gotoState('Happy')
    assert_equal(jimmy:sing(), "I'll be watching you")
    assert_equal(jimmy:singMore(), "lalalala")
    assert_equal(jimmy:speak(), "hehehe")
    jimmy:gotoState('VeryHappy')
    assert_equal(jimmy:sing(), 'hehey')
    assert_equal(jimmy:singMore(), "lalalala")
    assert_equal(jimmy:speak(), "hehehe")

  end)

  test("state stacking", function()

    function Enemy:sing()  return "la donna e mobile" end
    function Enemy:dance() return "up down left right" end
    function Enemy:all()   return table.concat({ self:dance(), self:sing(), self:speak() }, ' - ') end

    local SteveWonder = Enemy:addState('SteveWonder')
    function SteveWonder:sing() return 'you are the sunshine of my life' end

    local FredAstaire = Enemy:addState('FredAstaire')
    function FredAstaire:dance() return 'clap clap clappity clap' end

    local PhilCollins = Enemy:addState('PhilCollins')
    function PhilCollins:dance() return "I can't dance" end
    function PhilCollins:sing() return "I can't sing" end
    function PhilCollins:speak() return "Only thing about me is the way I walk" end

    local artist = Enemy:new(10)


    assert_equal(artist:all(), "up down left right - la donna e mobile - My health is 10")

    artist:gotoState('PhilCollins')
    assert_equal(artist:all(), "I can't dance - I can't sing - Only thing about me is the way I walk")

    artist:pushState('FredAstaire')
    assert_equal(artist:all(), "clap clap clappity clap - I can't sing - Only thing about me is the way I walk")

    artist:pushState('SteveWonder')
    assert_equal(artist:all(), "clap clap clappity clap - you are the sunshine of my life - Only thing about me is the way I walk")

    artist:popAllStates()
    assert_equal(artist:all(), "up down left right - la donna e mobile - My health is 10")


    artist:pushState('PhilCollins')
    artist:pushState('FredAstaire')
    artist:pushState('SteveWonder')
    artist:popState('FredAstaire')
    assert_equal(artist:all(), "I can't dance - you are the sunshine of my life - Only thing about me is the way I walk")

    artist:popState()
    assert_equal(artist:all(), "I can't dance - I can't sing - Only thing about me is the way I walk")

    artist:popState('FredAstaire')
    assert_equal(artist:all(), "I can't dance - I can't sing - Only thing about me is the way I walk")

    artist:gotoState('FredAstaire')
    assert_equal(artist:all(), "clap clap clappity clap - la donna e mobile - My health is 10")

  end)

  test("stack-related callbacks", function()
    local TweetPaused = Enemy:addState('TweetPaused')
    function TweetPaused:pausedState() self.tweet = true end

    local TootContinued = Enemy:addState('TootContinued')
    function TootContinued:continuedState() self.toot = true end

    local PamPushed = Enemy:addState('PamPushed')
    function PamPushed:pushedState() self.pam = true end

    local PopPopped = Enemy:addState('PopPopped')
    function PopPopped:poppedState() self.pop = true end

    local QuackExited = Enemy:addState('QuackExited')
    function QuackExited:exitedState() self.quack = true end

    local MooEntered = Enemy:addState('MooEntered')
    function MooEntered:enteredState() self.moo = true end

    local e = Enemy:new()

    e:gotoState('TweetPaused')
    assert_nil(e.tweet)
    e:pushState('TootContinued')
    assert_true(e.tweet)

    e:pushState('PopPopped')
    e:popState()

    assert_true(e.toot)
    assert_true(e.pop)

    e:pushState('PopPopped')
    e:pushState('PamPushed')
    assert_true(e.pam)

    e.toot = false
    e.pop = false

    e:popState('PopPopped')
    assert_true(e.pop)

    e:popState()
    assert_true(e.toot)

    e:pushState('QuackExited')
    e:pushState('MooEntered')
    assert_true(e.moo)
    assert_nil(e.quack)

    e.quack = false
    e:popState('QuackExited')
    assert_true(e.quack)

    e = Enemy:new()
    e:pushState('PopPopped')
    e:pushState('QuackExited')
    e:popAllStates()
    assert_true(e.pop)
    assert_true(e.quack)

  end)

  test("debugging", function()
    local State1 = Enemy:addState('State1')
    local State2 = Enemy:addState('State2')

    local e = Enemy:new()
    local info = e:getStateStackDebugInfo()
    assert_equal(#info,0)

    e:pushState('State1')
    info = e:getStateStackDebugInfo()
    assert_equal(#info,1)
    assert_equal(info[1], 'State1')

    e:pushState('State2')
    info = e:getStateStackDebugInfo()
    assert_equal(#info,2)
    assert_equal(info[1], 'State2')
    assert_equal(info[2], 'State1')
  end)

  context("Errors", function()
    test("addState raises an error if the state is already present, or not a valid id", function()
      local Immortal = Enemy:addState('Immortal')
      assert_error(function() Enemy:addState('Immortal') end)
      assert_error(function() Enemy:addState(1) end)
      assert_error(function() Enemy:addState() end)
    end)
    test("gotoState raises an error if the state doesn't exist, or not a valid id", function()
      local e = Enemy:new()
      assert_error(function() e:gotoState('Inexisting') end)
      assert_error(function() e:gotoState(1) end)
      assert_error(function() e:gotoState({}) end)
    end)
    test("popState raises an error if the state doesn't exist", function()
      local e = Enemy:new()
      assert_error(function() e:popState('Inexisting') end)
    end)
    test("pushState raises an error if the state doesn't exist", function()
      local e = Enemy:new()
      assert_error(function() e:pushState('Inexisting') end)
    end)
  end)

end)


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

  test("basic callbacks work", function()

    local Drunk = Enemy:addState('Drunk')

    function Drunk:enterState() self.health = self.health - 1 end
    function Drunk:exitState() self.health = self.health + 1 end

    local john = Enemy:new(10)

    assert_equal(john:speak(), 'My health is 10')

    john:gotoState('Drunk')
    assert_equal(john:speak(), 'My health is 9')
    assert_type(john.enterState, 'nil')
    assert_type(john.exitState, 'nil')

    john:gotoState(nil)
    assert_equal(john:speak(), 'My health is 10')

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
  end)

end)


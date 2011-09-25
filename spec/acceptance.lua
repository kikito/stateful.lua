require 'spec/lib/middleclass'

Stateful = require 'stateful'

context("Acceptance tests", function()

  local Enemy

  before(function()
    Enemy = class('Enemy'):include(Stateful)

    function Enemy:initialize(health)
      self.health = health
    end
  end)

  test("works on the basic case", function()

    function Enemy:speak()
      return 'My health is ' .. tostring(self.health)
    end

    local Immortal = Enemy:addState('Immortal')

    function Immortal:speak()
      return 'I am UNBREAKABLE!!'
    end
    function Immortal:die()
      return 'I can not die now!'
    end

    local peter = Enemy:new(10)

    assert_equal(peter:speak(), 'My health is 10')
    peter:gotoState('Immortal')
    assert_equal(peter:speak(), 'I am UNBREAKABLE!!')
    assert_equal(peter:die(), 'I can not die now!')
    peter:gotoState(nil)
    assert_equal(peter:speak(), 'My health is 10')

  end)

  context("Errors", function()
    test("AddState throws an error if the state is already present", function()
      local Immortal = Enemy:addState('Immortal')
      assert_error(function() Enemy:addState('Immortal') end)
    end)
    test("AddState throws an error if the state isn't a string", function()
      assert_error(function() Enemy:addState(1) end)
      assert_error(function() Enemy:addState() end)
    end)
  end)

end)


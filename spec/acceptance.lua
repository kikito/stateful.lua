require 'spec/lib/middleclass'

Stateful = require 'stateful'

context("Acceptance tests", function()

  it("works on the basic case", function()

    local Enemy = class('Enemy')
    Enemy:include(Stateful)

    function Enemy:initialize(health)
      self.health = health
    end

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


end)

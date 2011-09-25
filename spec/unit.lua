require 'spec/lib/middleclass'

Stateful = require 'stateful'

describe("Unit tests", function()

  describe("including the mixin", function()
    test("The class gets a new class attribute called 'states'", function()
      local C = class('C')
      C:include(Stateful)
      assert_type(C.states, "table")
    end)
  end)

  describe("addState", function()
    describe("When given a valid state name", function()
      test("class.states contains an entry with that name", function()
        local C = class('C'):include(Stateful)
        C:addState("State")
        assert_type(C.states.State, "table")
      end)
    end)
  end)

  describe("gotoState", function()
    describe("when given a valid state name", function()
      test("the class instances use that state methods instead of the default ones", function()
        local Enemy = class('Enemy'):include(Stateful)
        function Enemy:foo() return 'foo' end
        local SayBar = Enemy:addState('SayBar')
        function SayBar:foo() return 'bar' end

        local e = Enemy:new()
        assert_equal(e:foo(), 'foo')
        e:gotoState('SayBar')
        assert_equal(e:foo(), 'bar')

      end)
    end)
  end)


end)

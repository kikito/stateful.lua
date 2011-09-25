require 'spec/lib/middleclass'

Stateful = require 'stateful'


describe("Unit tests", function()

  local Enemy

  before(function()
    Enemy = class('Enemy'):include(Stateful)
  end)

  it("gets a new class attribute called 'states' when including the mixin", function()
    assert_type(Enemy.states, "table")
  end)

  describe("addState", function()
    it("adds an entry to class.states when given a valid, new name", function()
      Enemy:addState("State")
      assert_type(Enemy.states.State, "table")
    end)
    it("throws an error when given the name of an already existing state", function()
      Enemy:addState("State")
      assert_error(function() Enemy:addState("State") end)
    end)
    it("throws an error when given a non-string name", function()
      assert_error(function() Enemy:addState(1) end)
      assert_error(function() Enemy:addState() end)
    end)
  end)

  describe("gotoState", function()
    describe("when given a valid state name", function()
      test("the class instances use that state methods instead of the default ones", function()
        function Enemy:foo() return 'foo' end
        local SayBar = Enemy:addState('SayBar')
        function SayBar:foo() return 'bar' end

        local e = Enemy:new()
        assert_equal(e:foo(), 'foo')
        e:gotoState('SayBar')
        assert_equal(e:foo(), 'bar')

      end)
    end)

    it("throws an error when the state doesn't exist", function()
      local e = Enemy:new()
      assert_error(function() e:gotoState('Inexisting') end)
    end)
  end)


end)

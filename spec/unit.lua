require 'spec/lib/middleclass'

Stateful = require 'stateful'


describe("Unit tests", function()

  local Enemy

  before(function()
    Enemy = class('Enemy'):include(Stateful)
  end)

  describe("including the mixin", function()
    test("The class gets a new class attribute called 'states'", function()
      assert_type(Enemy.states, "table")
    end)
  end)

  describe("addState", function()
    describe("When given a valid state name", function()
      test("class.states contains an entry with that name", function()
        Enemy:addState("State")
        assert_type(Enemy.states.State, "table")
      end)
    end)
    describe("When given the name of an already existing state", function()
      test("throws an error", function()
        Enemy:addState("State")
        assert_error(function() Enemy:addState("State") end)
      end)
    end)
    describe("When given a non-string name", function()
      test("throws an error", function()
        assert_error(function() Enemy:addState(1) end)
        assert_error(function() Enemy:addState() end)
      end)
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
  end)


end)

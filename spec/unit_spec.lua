local class    = require 'spec.lib.middleclass'
local Stateful = require 'stateful'

describe("A Stateful class", function()

  local Enemy

  before_each(function()
    Enemy = class('Enemy'):include(Stateful)
  end)

  it("gets a new class attribute called 'states' when including the mixin", function()
    assert.equals(type(Enemy.states), "table")
  end)

  describe("when intheriting from another stateful class", function()
    it("has a list of states, different from the superclass", function()
      local SubEnemy = class('SubEnemy', Enemy)
      assert.equals(type(SubEnemy.states), "table")
      assert.not_equals(Enemy.states, SubEnemy.states)
    end)

    it("each inherited state inherits methods from the superclass' states", function()
      local Scary = Enemy:addState("Scary")
      function Scary:speak() return "boo!" end
      function Scary:fly() return "like the wind" end

      local Clown = class('Clown', Enemy)
      function Clown.states.Scary:speak() return "mock, mock!" end

      local it = Clown:new()
      it:gotoState("Scary")

      assert.equals(it:fly(), "like the wind")
      assert.equals(it:speak(), "mock, mock!")
    end)

    it("states can be inherited individually too", function()
      function Enemy:speak() return 'booboo' end

      local Funny = Enemy:addState("Funny")
      function Funny:laugh() return "hahaha" end

      local VeryFunny = Enemy:addState("VeryFunny", Funny)
      function VeryFunny:laughMore() return "hehehe" end

      local albert = Enemy:new()
      albert:gotoState('VeryFunny')
      assert.equals(albert:speak(), "booboo")
      assert.equals(albert:laugh(), "hahaha")
      assert.equals(albert:laughMore(), "hehehe")
    end)

  end)

  describe(":addState", function()
    it("adds an entry to class.states when given a valid, new name", function()
      Enemy:addState("State")
      assert.equals(type(Enemy.states.State), "table")
    end)
    it("throws an error when given the name of an already existing state", function()
      Enemy:addState("State")
      assert.error(function() Enemy:addState("State") end)
    end)
    it("throws an error when given a non-string name", function()
      assert.error(function() Enemy:addState(1) end)
      assert.error(function() Enemy:addState() end)
    end)
    it("doesn't add state callbacks to instances", function()
      Enemy:addState("State")
      local e = Enemy:new()
      e:gotoState("State")
      assert.is_nil(e.enterState)
      assert.is_nil(e.exitState)
    end)
  end)

  describe(":gotoState", function()
    describe("when given a valid state name", function()
      it("makes the class instances use that state methods instead of the default ones", function()
        function Enemy:foo() return 'foo' end
        local SayBar = Enemy:addState('SayBar')
        function SayBar:foo() return 'bar' end

        local e = Enemy:new()
        assert.equals(e:foo(), 'foo')
        e:gotoState('SayBar')
        assert.equals(e:foo(), 'bar')
      end)

      it("calls enteredState callback, if it exists", function()
        local Marked = Enemy:addState('Marked')

        function Marked:enteredState() self.mark = true end

        local e = Enemy:new()
        assert.is_nil(e.mark)

        e:gotoState('Marked')
        assert.is_true(e.mark)
      end)

      it("passes all additional arguments to enteredState and exitedState", function()
        local State1 = Enemy:addState("State1")
        local State2 = Enemy:addState("State2")

        State1.exitedState = function(self, x) assert.equals(x, "foobar") end
        State2.enteredState = function(self, x) assert.equals(x, "foobar") end

        local e = Enemy:new()
        e:gotoState("State1")
        e:gotoState("State2", "foobar")
      end)

      describe('when there are several states in the stack', function()
        it("calls exitedState in all the stacked states", function()
          local counter = 0
          local count = function() counter = counter + 1 end
          local Jumping  = Enemy:addState('Jumping')
          local Firing   = Enemy:addState('Firing')
          Enemy:addState('Shouting')

          Jumping.exitedState   = count
          Firing.exitedState    = count

          local e = Enemy:new()
          e:pushState('Jumping')
          e:pushState('Firing')

          e:gotoState('Shouting')

          assert.equals(counter, 2)
        end)
      end)
    end)

    it("raises an error when given an invalid id", function()
      local e = Enemy:new()
      assert.error(function() e:gotoState(1) end)
      assert.error(function() e:gotoState({}) end)
    end)

    it("raises an error when the state doesn't exist", function()
      local e = Enemy:new()
      assert.error(function() e:gotoState('Inexisting') end)
    end)
  end)

  describe("state stacking", function()
    local Piled, New, e
    before_each(function()
      function Enemy:foo() return 'foo' end

      Piled = Enemy:addState('Piled')
      function Piled:foo() return 'foo2' end
      function Piled:bar() return 'bar' end

      New = Enemy:addState('New')
      function New:bar() return 'new bar' end

      e = Enemy:new()
      e:gotoState('Piled')
    end)

    describe("pushState", function()
      it("uses the new state state for the lookaheads, before the pushed state", function()
        e:pushState('New')
        assert.equals(e:bar(), 'new bar')
      end)

      it("looks up in the stack if the top state doesn't have a method", function()
        e:pushState('New')
        assert.equals(e:foo(), 'foo2')
      end)

      it("invokes the pushedState callback, if it exists", function()
        function New:pushedState() self.mark = true end
        e:pushState('New')
        assert.is_true(e.mark)
      end)

      it("invokes the enteredState callback, if it exists", function()
        function New:enteredState() self.mark = true end
        e:pushState('New')
        assert.is_true(e.mark)
      end)

      it("does not invoke the exitedState callback on the previous state", function()
        function Piled:exitedState() self.mark = true end
        e:pushState('New')
        assert.is_nil(e.mark)
      end)

      it("If the current state has a paused state, it gets invoked", function()
        function Piled:pausedState() self.mark = true end
        e:pushState('New')
        assert.is_true(e.mark)
      end)
    end)

    describe(":popAllStates", function()
      it("Renders the object stateless", function()
        e:pushState('New')
        e:popAllStates()
        assert.is_equal(e:foo(), 'foo')
      end)

      it("Invokes callbacks in the right order", function()
        function Piled:poppedState() self.popped = true end
        function New:exitedState() self.exited = true end
        e:pushState('New')
        e:popAllStates()
        assert.is_true(e.popped)
        assert.is_true(e.exited)
      end)
    end)

    describe(":popState", function()

      describe("when given a valid name", function()
        it("pops the state by name", function()
          e:pushState('New')
          e:popState('Piled')
          assert.equals(e:foo(), 'foo')
          assert.equals(e:bar(), 'new bar')
        end)
        it("invokes the poppedState on the popped state, if it exists", function()
          function Piled:poppedState() self.popped = true end
          e:pushState('New')
          e:popState('Piled')
          assert.is_true(e.popped)
        end)
        it("invokes the exitstate on the state that is removed from the pile", function()
          function Piled:exitedState() self.exited = true end
          e:pushState('New')
          e:popState('Piled')
          assert.is_true(e.exited)
        end)
      end)

      describe("when not given a name", function()
        it("pops the top state", function()
          e:pushState('New')
          e:popState()
          assert.equals(e:foo(), 'foo2')
          assert.equals(e:bar(), 'bar')
        end)

        it("invokes the poppedState callback on the old state", function()
          function Piled:poppedState() self.popped = true end
          e:popState()
          assert.is_true(e.popped)
        end)

        it("invokes the continuedState on the new state, if it exists", function()
          function Piled:continuedState() self.continued = true end
          e:pushState('New')
          e:popState()
          assert.is_true(e.continued)
        end)

        it("throws an error if the state doesn't exist", function()
          e:popState()
          assert.error(function() e:popState('Inexisting') end)
        end)
      end)
    end)
  end)

  describe(':getStateStackDebugInfo', function()
    it("returns an empty table on the nil state", function()
      local e = Enemy:new()
      local info = e:getStateStackDebugInfo()
      assert.equals(#info, 0)
    end)
    it("returns the name of the current state", function()
      Enemy:addState('State1')
      Enemy:addState('State2')
      local e = Enemy:new()

      e:gotoState('State1')
      e:pushState('State2')

      local info = e:getStateStackDebugInfo()
      assert.equals(#info, 2)
      assert.equals(info[1], 'State2')
      assert.equals(info[2], 'State1')
    end)
  end)
end)

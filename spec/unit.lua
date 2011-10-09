require 'spec/lib/middleclass'

Stateful = require 'stateful'


describe("Unit tests", function()

  local Enemy

  before(function()
    Enemy = class('Enemy'):include(Stateful)
  end)

  test("a stateful class gets a new class attribute called 'states' when including the mixin", function()
    assert_type(Enemy.states, "table")
  end)

  describe("when inheriting from a stateful class", function()
    test("the subclass has a list of states, different from the superclass", function()
      local SubEnemy = class('SubEnemy', Enemy)
      assert_type(SubEnemy.states, "table")
      assert_not_equal(Enemy.states, SubEnemy.states)
    end)

    test("each inherited state inherits methods from the superclass' states", function()
      local Scary = Enemy:addState("Scary")
      function Scary:speak() return "boo!" end
      function Scary:fly() return "like the wind" end

      local Clown = class('Clown', Enemy)
      function Clown.states.Scary:speak() return "mock, mock!" end

      local it = Clown:new()
      it:gotoState("Scary")

      assert_equal(it:fly(), "like the wind")
      assert_equal(it:speak(), "mock, mock!")

    end)

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
    it("doesn't add state callbacks to instances", function()
      Enemy:addState("State")
      local e = Enemy:new()
      e:gotoState("State")
      assert_nil(e.enterState)
      assert_nil(e.exitState)
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

      test("the enteredState callback is called, if it exists", function()
        local Marked = Enemy:addState('Marked')

        function Marked:enteredState() self.mark = true end

        local e = Enemy:new()
        assert_nil(e.mark)

        e:gotoState('Marked')
        assert_true(e.mark)
      end)

    end)

    it("raises an error when given an invalid id", function()
      local e = Enemy:new()
      assert_error(function() e:gotoState(1) end)
      assert_error(function() e:gotoState({}) end)
    end)

    it("raises an error when the state doesn't exist", function()
      local e = Enemy:new()
      assert_error(function() e:gotoState('Inexisting') end)
    end)
  end)

  describe("state stacking", function()
    local Pushed, New, e
    before(function()
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
      test("The new state is used for the lookaheads, before the pushed state", function()
        e:pushState('New')
        assert_equal(e:bar(), 'new bar')
      end)

      test("The new state conserves the lookaheads, of the previous ones in the stack", function()
        e:pushState('New')
        assert_equal(e:foo(), 'foo2')
      end)

      test("It invokes the pushedState callback, if it exists", function()
        function New:pushedState() self.mark = true end
        e:pushState('New')
        assert_true(e.mark)
      end)

      test("If the current state has a paused state, it gets invoked", function()
        function Piled:pausedState() self.mark = true end
        e:pushState('New')
        assert_true(e.mark)
      end)
    end)

    describe("popAllStates", function()
      test("Renders the object stateless", function()
        e:pushState('New')
        e:popAllStates()
        assert_equal(e:foo(), 'foo')
      end)
    end)

    describe("popState", function()

      describe("when given a valid name", function()
        test("pops the state by name", function()
          e:pushState('New')
          e:popState('Piled')
          assert_equal(e:foo(), 'foo')
          assert_equal(e:bar(), 'new bar')
        end)
        test("invokes the poppedState on the popped state, if it exists", function()
          function Piled:poppedState() self.popped = true end
          e:pushState('New')
          e:popState('Piled')
          assert_true(e.popped)
        end)
      end)

      describe("when not given a name", function()
        test("pops the top state", function()
          e:pushState('New')
          e:popState()
          assert_equal(e:foo(), 'foo2')
          assert_equal(e:bar(), 'bar')
        end)

        test("invokes the poppedState callback on the old state", function()
          function Piled:poppedState() self.popped = true end
          e:popState()
          assert_true(e.popped)
        end)

        test("invokes the continuedState on the new state, if it exists", function()
          function Piled:continuedState() self.continued = true end
          e:pushState('New')
          e:popState()
          assert_true(e.continued)
        end)
      end)
    end)
  end)


end)

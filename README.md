# Stateful

[![Build Status](https://travis-ci.org/kikito/stateful.lua.svg?branch=master)](https://travis-ci.org/kikito/stateful.lua)

* Classes gain the capacity of creating "states"
* States can override instance methods and create new ones
* States are inherited by subclasses
* States are stackable - the state on the top of the stack is the most prioritary
* There are callback functions invoked automatically when a state is entered, exited, pushed, popped ...

# Example

``` lua
local class    = require 'middleclass'
local Stateful = require 'stateful'

local Enemy = class('Enemy')
Enemy:include(Stateful)

function Enemy:initialize(health)
  self.health = health
end

function Enemy:speak()
  return 'My health is' .. tostring(self.health)
end

local Immortal = Enemy:addState('Immortal')

-- overriden function
function Immortal:speak()
  return 'I am UNBREAKABLE!!'
end

-- added function
function Immortal:die()
  return 'I can not die now!'
end

local peter = Enemy:new(10)

peter:speak() -- My health is 10
peter:gotoState('Immortal')
peter:speak() -- I am UNBREAKABLE!!
peter:die() -- I can not die now!
peter:gotoState(nil)
peter:speak() -- My health is 10
```


# Installation

First, make sure that you have downloaded and installed [middleclass](https://github.com/kikito/middleclass)

Just copy the stateful.lua file wherever you want it (for example on a lib/ folder). Then write this in any Lua file where you want to use it:

``` lua
local class = require 'middleclass'
local Stateful = require 'stateful'
```

The `package.path` variable must be configured so that the folder in which stateful.lua is copied is available, of course.

# Specs

This project uses [busted](http://olivinelabs.com/busted/) for its specs. In order to run them, install busted, and then execute it on the top folder:

```
busted
```

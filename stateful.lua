local Stateful = { static = {} }

local function _modifyInstanceDict(klass)
  local prevIndex = klass.__instanceDict.__index

  klass.__instanceDict.__index = function(instance, name)
    local currentState = rawget(instance, '__currentState')
    if currentState and currentState[name] then return currentState[name] end

    if type(prevIndex) == 'function' then return prevIndex(instance, name) end
    return prevIndex[name]
  end

end

function Stateful:included(klass)
  klass.static.states = {}
  _modifyInstanceDict(klass)
end

function Stateful.static:addState(stateName)
  self.static.states[stateName] = {}
  return self.static.states[stateName]
end

function Stateful:gotoState(stateName)
  local state = self.class.states[stateName]

  self.__currentState = state
end

return Stateful

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
  assert(self.static.states[stateName] == nil, "State " .. tostring(stateName) .. " already exists on " .. tostring(self) )
  assert(type(stateName) == 'string', "stateName must be a string. Got " .. tostring(stateName) .. "(" .. type(stateName) .. ")" )

  self.static.states[stateName] = {}
  return self.static.states[stateName]
end

function Stateful:gotoState(stateName)

  if stateName == nil then
    self.__currentState = nil
  else
    local state = self.class.states[stateName]
    assert(state, "The state" .. stateName .. " was not found in class " .. tostring(self.class) )
    self.__currentState = state
  end
end

return Stateful

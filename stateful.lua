local Stateful = { static = {} }

local _callbacks = {
  enterState = 1,
  exitState = 1
}

local _BaseState = {}

for callbackName,_ in pairs(_callbacks) do
  _BaseState[callbackName] = function() end
end

local function _invokeCallback(instance, state, callbackName)
  if state then state[callbackName](instance) end
end

local function _modifyInstanceDict(klass)
  local prevIndex = klass.__instanceDict.__index

  klass.__instanceDict.__index = function(instance, name)
    if not _callbacks[name] then
      local currentState = rawget(instance, '__currentState')
      if currentState and currentState[name] then return currentState[name] end
    end
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

  self.static.states[stateName] = setmetatable({}, {__index = _BaseState})
  return self.static.states[stateName]
end

function Stateful:gotoState(stateName)

  _invokeCallback(self, self.__currentState, 'exitState')

  if stateName == nil then
    self.__currentState = nil
  else
    assert(type(stateName)=='string', "stateName must be a string or nil. Got " .. tostring(stateName) .. "(" .. type(stateName) .. ")" )

    local state = self.class.states[stateName]
    assert(state, "The state" .. stateName .. " was not found in class " .. tostring(self.class) )

    _invokeCallback(self, state, 'enterState')

    self.__currentState = state
  end

end

return Stateful

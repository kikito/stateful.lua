local Stateful = { static = {} }

local _callbacks = {
  enterState = 1,
  exitState = 1
}

local _BaseState = {}

for callbackName,_ in pairs(_callbacks) do
  _BaseState[callbackName] = function() end
end

local function _assert_type(val, name, expected_type, type_to_s)
  assert(type(val) == expected_type, "Expected " .. name .. " to be of type " .. (type_to_s or expected_type) .. ". Was " .. tostring(val) .. "(" .. type(val) .. ")")
end

local function _addStatesToClass(klass, superStates)
  klass.static.states = {}
  for stateName, state in pairs(superStates or {}) do
    klass.static.states[stateName] = setmetatable({}, { __index = state })
  end
end

local function _invokeCallback(instance, state, callbackName)
  if state then state[callbackName](instance) end
end

local function _getStatefulMethod(instance, name)
  if not _callbacks[name] then
    local state = rawget(instance, '__currentState')
    if state and state[name] then return state[name] end
  end
end

local function _getNewInstanceIndex(prevIndex)
  if type(prevIndex) == 'function' then
    return function(instance, name) return _getStatefulMethod(instance, name) or prevIndex(instance, name) end
  end
  return function(instance, name) return _getStatefulMethod(instance, name) or prevIndex[name] end
end

local function _modifyInstanceIndex(klass)
  klass.__instanceDict.__index = _getNewInstanceIndex(klass.__instanceDict.__index)
end

local function _getNewSubclassMethod(prevSubclass)
  return function(klass, name)
    local subclass = prevSubclass(klass, name)
    _addStatesToClass(subclass, klass.states)
    _modifyInstanceIndex(subclass)
    return subclass
  end
end

local function _modifySubclassMethod(klass)
  klass.static.subclass = _getNewSubclassMethod(klass.static.subclass)
end

function Stateful:included(klass)
  _addStatesToClass(klass)
  _modifyInstanceIndex(klass)
  _modifySubclassMethod(klass)
end

function Stateful.static:addState(stateName)
  _assert_type(stateName, 'stateName', 'string')
  assert(self.static.states[stateName] == nil, "State " .. tostring(stateName) .. " already exists on " .. tostring(self) )

  self.static.states[stateName] = setmetatable({}, { __index = _BaseState })
  return self.static.states[stateName]
end

function Stateful:gotoState(stateName)

  _invokeCallback(self, self.__currentState, 'exitState')

  if stateName == nil then
    self.__currentState = nil
  else
    _assert_type(stateName, 'stateName', 'string', 'string or nil')

    local state = self.class.static.states[stateName]
    assert(state, "The state" .. stateName .. " was not found in class " .. tostring(self.class) )

    _invokeCallback(self, state, 'enterState')

    self.__currentState = state
  end

end

return Stateful

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

local function _invokeCallback(instance, state, callbackName)
  if state then state[callbackName](instance) end
end

local function _addStatesToClass(klass, superStates)
  klass.static.states = {}
  for stateName, state in pairs(superStates or {}) do
    klass.static.states[stateName] = setmetatable({}, { __index = state })
  end
end

local function _getStatefulMethod(instance, name)
  if not _callbacks[name] then
    local stack = rawget(instance, '__stateStack')
    if not stack then return end
    for i = #stack, 1, -1 do
      if stack[i][name] then return stack[i][name] end
    end
  end
end

local function _getNewInstanceIndex(prevIndex)
  if type(prevIndex) == 'function' then
    return function(instance, name) return _getStatefulMethod(instance, name) or prevIndex(instance, name) end
  end
  return function(instance, name) return _getStatefulMethod(instance, name) or prevIndex[name] end
end

local function _getNewAllocateMethod(oldAllocateMethod)
  return function(klass, ...)
    local instance = oldAllocateMethod(klass, ...)
    instance.__stateStack = {}
    return instance
  end
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

local function _modifyAllocateMethod(klass)
  klass.static.allocate = _getNewAllocateMethod(klass.static.allocate)
end

function Stateful:included(klass)
  _addStatesToClass(klass)
  _modifyInstanceIndex(klass)
  _modifySubclassMethod(klass)
  _modifyAllocateMethod(klass)
end

function Stateful.static:addState(stateName)
  _assert_type(stateName, 'stateName', 'string')
  assert(self.static.states[stateName] == nil, "State " .. tostring(stateName) .. " already exists on " .. tostring(self) )

  self.static.states[stateName] = setmetatable({}, { __index = _BaseState })
  return self.static.states[stateName]
end

function Stateful:gotoState(stateName)

  _invokeCallback(self, self.__stateStack[#self.__stateStack], 'exitState')

  if stateName == nil then
    self.__stateStack = { }
  else
    _assert_type(stateName, 'stateName', 'string', 'string or nil')

    local state = self.class.static.states[stateName]
    assert(state, "The state" .. stateName .. " was not found in class " .. tostring(self.class) )

    _invokeCallback(self, state, 'enterState')

    self.__stateStack = { state }
  end

end

function Stateful:pushState(stateName)

  local state = self.class.static.states[stateName]
  assert(state, "The state" .. stateName .. " was not found in class " .. tostring(self.class) )

  table.insert(self.__stateStack, state)
end

function Stateful:popState()
end

function Stateful:popAllStates()
end

return Stateful

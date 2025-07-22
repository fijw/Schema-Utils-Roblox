--[[
    Extended Schema Manager (State Management Library)

    @Author:  @roblox_user_5618502527
    @version: 1.0.2
    @usage:
    ```luau
        local Schema = path.to.ESM.schema({
            Secondary = {
                test1 = "example",
                test2 = "example"
            }
        }) 
        if not Schema then return end
        

        Schema:pushStateData("new test1 example", "test1", "Secondary")
        Schema:pushStateData("new test3 example", "test3", "Secondary")

        Schema:pushMetaData("__newindex", function<K, V>(...: { [K]: V } & K & V)
            rawset(...)
        end)


        Schema:ovwrOnStateChanged(function<P, K, V>(prev: P, key: K, value: V): (P, K, V)
            print(prev, key, value)
            return prev, key, value
        end)

        Schema:ovwrOnCalled(function()
            print("!CALLED...")
        end)


        Schema:lockSchema() -- UNCHANGEABLE...
        print(Schema:getState())
    ```
]]
--!strict


--[[ @TYPES ]]

type ProtoSchemaType<T> = {
    [any]: any,

    __call:  (...any) -> (...any)?,
    __index: {
        ovwrOnCalled:       (self: ExtendedSchema<T>, newFunc: (...any) -> (...any)) -> (),
        ovwrOnStateChanged: (self: ExtendedSchema<T>, newFunc: (...any) -> (...any)) -> (),
        pushStateData:      <V, K, P...>(self: ExtendedSchema<T>, value: V, key: K?, P...) -> (),
        pushMetaData:       <D>(self: ExtendedSchema<T>, method: string, data: D | (...any) -> (...any)) -> (),
        getState:           (self: ExtendedSchema<T>) -> (any),
        lockSchema:         (self: ExtendedSchema<T>) -> ()
    }
}

type InternalSchema<T> = {
    state:            T,
    onStateChangedFN: (...any) -> (...any)?
}

export type ExtendedSchema<T> = typeof(setmetatable(
    ... :: InternalSchema<T>,
    ... :: ProtoSchemaType<T>
))


--[[ @VARIABLES ]]

local ExtendedSchemaManager = {}
local ProtoSchema           = {}


--[[ @CONSTRUCTOR ]]

--[[
    @usage Constructs a new prototype schema.
    @param      value              The initial value of the schema.
    @param      changedCallback    The function to call when the schema is changed.
    @param      calledCallback     The function to call when the schema is called.
    @return     ExtendedSchema<T>?
]]
function ExtendedSchemaManager.schema<T>(
    value:           T,
    changedCallback: (...any) -> (...any)?,
    calledCallback:  (...any) -> (...any)?
): ExtendedSchema<T>?

    local self: InternalSchema<T> = {
        state            = value,
        onStateChangedFN = changedCallback
    }
    
	setmetatable(self,
		{
        	__call  = calledCallback,
        	__index = ProtoSchema
		} :: ProtoSchemaType<T>
	)
    
    return self
end


--[[ @MANIPULATIONS ]]

function ProtoSchema:ovwrOnCalled(newFunc: (...any) -> (...any))
    getmetatable(self).__call = newFunc
end

function ProtoSchema:ovwrOnStateChanged(newFunc: (...any) -> (...any))
    self.onStateChangedFN = newFunc
end


--[[ @PUSHING ]]

--[[
	@usage Pushes state data into the schema.
	@param     value    The value to push into the schema.
	@param     key      Optional key to associate with the value.
	@param     ...      Additional parameters to navigate the schema.
	@return    nil
]]
function ProtoSchema:pushStateData<V, K, P...>(value: V, key: K?, ...: P...)
	local packed    = table.pack(...)
	local pushScope = self:getState()
    local prev: typeof(self:getState()) | typeof(pushScope[key])

	for i = 1, packed.n do
		if not pushScope[packed[i]] then return end
		pushScope = pushScope[packed[i]]
	end

	if key then
        prev           = pushScope[key]
		pushScope[key] = value

		if not self.onStateChangedFN then return end
		self.onStateChangedFN(prev, key, value)

		return
	end

    prev       = self:getState()
	self.state = value :: any

	if not self.onStateChangedFN then return end
	self.onStateChangedFN(prev, nil, value)
end

--[[
	@usage Pushes metadata into the schema.
	@param     method    The method name to associate with the data.
	@param     data      The data to push, can be a value or a function.
	@return    nil
]]
function ProtoSchema:pushMetaData<D>(method: string, data: D | (...any) -> (...any))
	getmetatable(self)[method] = data
end


--[[ @ACCESS ]]

function ProtoSchema:getState(): any
    return self.state
end

function ProtoSchema:lockSchema()
    setmetatable(self :: any, table.freeze(getmetatable(self)) )
    table.freeze(self :: ExtendedSchema<typeof(self:getState())>)
end


return ExtendedSchemaManager
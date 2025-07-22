--[[
    @Author:  @roblox_user_5618502527
    @version: 1.0.4
    @usage:
    ```luau
        local ProfileSchema = dataractiveManager.newProfileSchema(player)
        if not ProfileSchema then return end


        local ExtendedSchema = ProfileSchema:ovwrExtended()
        ExtendedSchema.coins:pushStateData(999)
        ExtendedSchema.Settings:pushStateData(false, "MusicEnabled")
        ExtendedSchema.isFirstTime:pushStateData(false)

        ExtendedSchema.Inventory:pushStateData(
            {
                Name     = "test",
                Level    = 0,
                Rarity   = "test",
                Equipped = false
            },
            HTTPService:GenerateGUID(false),
            "Pets"
        )

        ExtendedSchema.Achievements:pushStateData(
            {
                Name 	    = "test",
                Description = "test",
                Completed   = true
            },
            "test"
        )


        ProfileSchema = ExtendedSchema:ovwrCompacted()
        ProfileSchema:saveSchema()
    ```
]]
--!strict


--[[ @VARIABLES ]]

local ServerStorage 	    = game:GetService("ServerStorage")
local profileStoreManager   = require(ServerStorage.Private.ProfileStore)
local extendedSchemaManager = require(ServerStorage.Private.ESM)


local Dataractive = {}
local Proto 	  = {}


local SCHEMA_TEMPLATE: PrimitiveProtoSchema = {
	coins 	    = 0,
	isFirstTime = true,

	Inventory = {
		Pets  = {},
		Items = {}
	},

	Settings = {
		SoundEnabled 	     = true,
		MusicEnabled 	     = true,
		NotificationsEnabled = true
	},

    Achievements = {}
}

local PROFILES_STORAGE = profileStoreManager.New("Profiles", SCHEMA_TEMPLATE)


--[[ @TYPES ]]

type Profile<T>        = profileStoreManager.Profile<T>
type ExtendedSchema<T> = extendedSchemaManager.ExtendedSchema<T>


type InventorySchema = {
	Pets: {
		[string]: {
			Name:     string,
			Level:    number,
			Rarity:   string,
			Equipped: boolean
		}
	},

	Items: {
		[string]: {
			Name:     string,
			Type:     string,
			Quantity: number
		}
	}
}

type SettingsSchema = {
	SoundEnabled:         boolean,
	MusicEnabled:         boolean,
	NotificationsEnabled: boolean
}

type AchievementsSchema = {
	[string]: {
		Name:        string,
		Description: string,
		Completed:   boolean
	}
}


type PrimitiveProtoSchema = {
	coins:        number,
	Inventory:    InventorySchema,
	Settings:     SettingsSchema,
	Achievements: AchievementsSchema,
	isFirstTime:  boolean,

    	Profile: Profile<PrimitiveProtoSchema>?
} & ProtoSchema

export type AdvancedProtoSchema = {
	coins:        ExtendedSchema<number>,
	Inventory:    ExtendedSchema<InventorySchema>,
	Settings:     ExtendedSchema<SettingsSchema>,
	Achievements: ExtendedSchema<AchievementsSchema>,
	isFirstTime:  ExtendedSchema<boolean>,

	Profile: Profile<AdvancedProtoSchema>?
} & ProtoSchema


type ProtoSchema = {
	ovwrExtended:  (self: PrimitiveProtoSchema) -> (AdvancedProtoSchema),
	ovwrCompacted: (self: AdvancedProtoSchema) -> (PrimitiveProtoSchema),
	saveSchema:    (self: PrimitiveProtoSchema) -> ()
}


--[[ @CONSTRUCTORS ]]

--[[
	@usage Creates a new schema for a player's data.
	@param      player    Player    The player to create the schema for.
	@return     PrimitiveProtoSchema?
]]
function Dataractive.newProfileSchema(player: Player): PrimitiveProtoSchema?
	local Profile = PROFILES_STORAGE:StartSessionAsync(`{player.UserId}`, {})
	if not Profile then return end

	Profile:Reconcile()
	Profile:AddUserId(player.UserId)

	local MetaProto      = Proto
	MetaProto["Profile"] = Profile

	setmetatable(Profile.Data :: PrimitiveProtoSchema, { __index = MetaProto })
	return Profile.Data :: PrimitiveProtoSchema
end

--[[
    @usage Fetches the schema for a player's data.
    @param      player    Player    The player to fetch the schema for.
    @return     PrimitiveProtoSchema?
]]
function Dataractive.fetchProfileSchema(player: Player): PrimitiveProtoSchema?
	local Profile = PROFILES_STORAGE:GetAsync(`{player.UserId}`)
	if not Profile then return end

	local MetaProto      = Proto
	MetaProto["Profile"] = Profile

	setmetatable(Profile.Data :: PrimitiveProtoSchema, { __index = MetaProto })
	return Profile.Data :: PrimitiveProtoSchema
end


--[[ @MANIPULATIONS ]]

function Proto:ovwrExtended(): AdvancedProtoSchema
	local TempSchema = {
		coins 	     = extendedSchemaManager.schema(self.coins),
		Inventory    = extendedSchemaManager.schema(self.Inventory),
		Settings     = extendedSchemaManager.schema(self.Settings),
		Achievements = extendedSchemaManager.schema(self.Achievements),
		isFirstTime  = extendedSchemaManager.schema(self.isFirstTime),

		Profile = self.Profile
	} :: AdvancedProtoSchema

	setmetatable(TempSchema :: AdvancedProtoSchema, { __index = Proto })
	return TempSchema :: AdvancedProtoSchema
end

function Proto:ovwrCompacted(): PrimitiveProtoSchema
	local TempSchema = {
		coins 	     = self.coins:getState(),
		Inventory    = self.Inventory:getState(),
		Settings     = self.Settings:getState(),
		Achievements = self.Achievements:getState(),
		isFirstTime  = self.isFirstTime:getState(),

		Profile = self.Profile
	} :: PrimitiveProtoSchema

	setmetatable(TempSchema :: PrimitiveProtoSchema, { __index = Proto })
	return TempSchema :: PrimitiveProtoSchema
end


--[[ @SAVING ]]

function Proto:saveSchema()
	self.Profile:Save()
end


return Dataractive

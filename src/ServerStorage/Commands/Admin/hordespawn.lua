return {
	Name = "hordespawn",
	Aliases = {},
	Description = "Spawns a set number of zombies",
	Group = "DefaultUtil",
	Args = {
		{
			Type = "npc",
			Name = "Type",
			Description = "The type of zombie to spawn in"
		},
		{
			Type = "number",
			Name = "Amount",
			Description = "The amount zombies that will be spawned in",
		},

	},
}
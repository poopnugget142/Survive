return {
	Name = "setmaxhealth",
	Aliases = {},
	Description = "Applies damage to select entity",
	Group = "DefaultUtil",
	Args = {
        {
			Type = "player",
			Name = "Player",
			Description = "The name of the player you are increasing the max health of"
		},
        {
			Type = "number",
			Name = "Amount",
			Description = "The amount you are setting the max health to"
		},
    },
}
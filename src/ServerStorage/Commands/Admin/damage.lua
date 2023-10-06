return {
	Name = "damage",
	Aliases = {"dmg"},
	Description = "Applies damage to select entity",
	Group = "DefaultUtil",
	Args = {
        {
			Type = "player",
			Name = "Player",
			Description = "The name of the thing you are damaging"
		},
        {
			Type = "number",
			Name = "Amount",
			Description = "The amount of damage you are applying"
		},
    },
}
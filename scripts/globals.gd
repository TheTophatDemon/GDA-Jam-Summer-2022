extends Node

const LAYER_BIT_TERRAIN = 1 << 1
const LAYER_BIT_PLAYERS = 1 << 2
const LAYER_BIT_ENEMIES = 1 << 3
const LAYER_BIT_PROPS   = 1 << 4
const LAYER_BIT_HAZARDS = 1 << 5

const GROUP_NAVMESH = "navmesh"
const GROUP_PROJECTILES = "projectiles"

func print_err(err:int):
	print("!!! Function returned error: ", err)

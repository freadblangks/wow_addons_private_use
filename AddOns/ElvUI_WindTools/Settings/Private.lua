local W, F, E, L, V, P, G = unpack(select(2, ...))

V.combat = {
	talentManager = {
		enable = true,
		sets = {}
	}
}

V.maps = {
	worldMap = {
		enable = true,
		reveal = true,
		clearCache = true,
		scale = {
			enable = true,
			size = 1.24
		}
	},
	minimapButtons = {
		enable = true,
		mouseOver = false,
		buttonsPerRow = 6,
		buttonSize = 30,
		backdrop = true,
		backdropSpacing = 3,
		spacing = 2,
		inverseDirection = false,
		orientation = "HORIZONTAL",
		calendar = false,
		garrison = false
	}
}

V.misc = {
	saveArtifact = true,
	pauseToSlash = true,
	disableTalkingHead = false,
	moveBlizzardFrames = true,
	moveElvUIBags = true,
	rememberPositions = true,
	framePositions = {},
	tags = true,
	mute = {
		enable = false,
		mount = {
			[63796] = false,
			[229385] = false
		}
	}
}

V.quest = {
	objectiveTracker = {
		enable = true,
		noDash = true,
		colorfulProgress = true,
		percentage = false,
		colorfulPercentage = false,
		header = {
			name = E.db.general.font,
			size = E.db.general.fontSize + 2,
			style = "OUTLINE"
		},
		title = {
			name = E.db.general.font,
			size = E.db.general.fontSize + 1,
			style = "OUTLINE"
		},
		info = {
			name = E.db.general.font,
			size = E.db.general.fontSize - 1,
			style = "OUTLINE"
		},
		titleColor = {
			enable = true,
			classColor = false,
			customColorNormal = {r = 0.000, g = 0.659, b = 1.000},
			customColorHighlight = {r = 0.282, g = 0.859, b = 0.984}
		}
	}
}

V.skins = {
	enable = true,
	windtools = true,
	removeParchment = true,
	shadow = true,
	color = {
		r = 0,
		g = 0,
		b = 0
	},
	addons = {
		ace3 = true,
		bigWigs = true,
		bugSack = true,
		hekili = true,
		immersion = true,
		tinyInspect = true,
		weakAuras = true,
		weakAurasOptions = true
	},
	blizzard = {
		enable = true,
		achievements = true,
		addonManager = true,
		adventureMap = true,
		alerts = true,
		auctionHouse = true,
		azeriteEssence = true,
		barberShop = true,
		blackMarket = true,
		calendar = true,
		challenges = true,
		channels = true,
		character = true,
		collections = true,
		communities = true,
		debugTools = true,
		dressingRoom = true,
		encounterJournal = true,
		flightMap = true,
		friends = true,
		garrison = true,
		gossip = true,
		guildBank = true,
		help = true,
		inputMethodEditor = true,
		inspect = true,
		lookingForGroup = true,
		loot = true,
		lossOfControl = true,
		macro = true,
		mail = true,
		merchant = true,
		microButtons = true,
		mirrorTimers = true,
		misc = true,
		objectiveTracker = true,
		orderHall = true,
		playerChoice = true,
		quest = true,
		raidInfo = true,
		scenario = true,
		scrappingMachine = true,
		spellBook = true,
		staticPopup = true,
		talent = true,
		talkingHead = true,
		taxi = true,
		timeManager = true,
		tooltips = true,
		trade = true,
		tradeSkill = true,
		trainer = true,
		tutorial = true,
		warboard = true,
		worldMap = true
	},
	elvui = {
		enable = true,
		actionBarsBackdrop = true,
		actionBarsButton = true,
		afk = true,
		altPowerBar = true,
		auras = true,
		bags = true,
		castBars = true,
		chatDataPanels = true,
		chatPanels = true,
		classBars = true,
		chatCopyFrame = true,
		dataBars = true,
		miniMap = true,
		option = true,
		panels = true,
		raidUtility = true,
		staticPopup = true,
		statusReport = true,
		totemBar = true,
		unitFrames = true
	}
}

V.tooltips = {
	icon = true,
	objectiveProgress = true,
	objectiveProgressAccuracy = 1,
	progression = {
		enable = true,
		raids = {
			enable = true,
			["Castle Nathria"] = true,
			["Ny'alotha, The Waking City"] = true
		},
		mythicDungeons = {
			enable = true,
			["The Necrotic Wake"] = true,
			["Plaguefall"] = true,
			["Mists of Tirna Scithe"] = true,
			["Halls of Atonement"] = true,
			["Theater of Pain"] = true,
			["De Other Side"] = true,
			["Spires of Ascension"] = true,
			["Sanguine Depths"] = true
		}
	}
}

V.social = {
	smartTab = {
		whisperTargets = {}
	}
}

V.unitFrames = {
	quickFocus = {
		enable = true,
		modifier = "shift",
		button = "BUTTON1"
	},
	roleIcon = {
		enable = true,
		roleIconStyle = "SUNUI"
	}
}

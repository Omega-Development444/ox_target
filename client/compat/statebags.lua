local plaSrvIn = GetPlayerServerId(PlayerId())
isCuffed = nil
isDead = nil
carryingGarbabge = nil
inGarbagbeZone = nil
oxyJoiner = nil
oxyBuyer = nil
lookingforvehicle = nil
isEscorting = nil
inTrunk = nil
myPos = nil
inChopZone = nil
chopping = nil
isInArena = nil
onDuty = nil

AddStateBagChangeHandler("isCuffed", ("player:%s"):format(plaSrvIn), function(bagName, key, value, reserved, replicated)
    isCuffed = value
end)

AddStateBagChangeHandler("isDead", ("player:%s"):format(plaSrvIn), function(bagName, key, value, reserved, replicated)
    isDead = value
end)

AddStateBagChangeHandler("carryingGarbabge", ("player:%s"):format(plaSrvIn), function(bagName, key, value, reserved, replicated)
    carryingGarbabge = value
end)

AddStateBagChangeHandler("inGarbagbeZone", ("player:%s"):format(plaSrvIn), function(bagName, key, value, reserved, replicated)
    inGarbagbeZone = value
end)

AddStateBagChangeHandler("oxyJoiner", ("player:%s"):format(plaSrvIn), function(bagName, key, value, reserved, replicated)
    oxyJoiner = value
end)

AddStateBagChangeHandler("oxyBuyer", ("player:%s"):format(plaSrvIn), function(bagName, key, value, reserved, replicated)
    oxyBuyer = value
end)

AddStateBagChangeHandler("lookingforvehicle", ("player:%s"):format(plaSrvIn), function(bagName, key, value, reserved, replicated)
    lookingforvehicle = value
end)

AddStateBagChangeHandler("isEscorting", ("player:%s"):format(plaSrvIn), function(bagName, key, value, reserved, replicated)
    isEscorting = value
end)

AddStateBagChangeHandler("inTrunk", ("player:%s"):format(plaSrvIn), function(bagName, key, value, reserved, replicated)
    inTrunk = value
end)

AddStateBagChangeHandler("myPos", ("player:%s"):format(plaSrvIn), function(bagName, key, value, reserved, replicated)
    myPos = value
end)

AddStateBagChangeHandler("inChopZone", ("player:%s"):format(plaSrvIn), function(bagName, key, value, reserved, replicated)
    inChopZone = value
end)

AddStateBagChangeHandler("chopping", ("player:%s"):format(plaSrvIn), function(bagName, key, value, reserved, replicated)
    chopping = value
end)

AddStateBagChangeHandler("isInArena", ("player:%s"):format(plaSrvIn), function(bagName, key, value, reserved, replicated)
    isInArena = value
end)

AddStateBagChangeHandler("onDuty", ("player:%s"):format(plaSrvIn), function(bagName, key, value, reserved, replicated)
    onDuty = value
end)
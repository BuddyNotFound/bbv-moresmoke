Main = {
    Particles = {},
    ParticleName = "scr_recartheft",
    ParticleBase = "core",
    SmokeON = true
}

RegisterCommand(Config.Settings.Command, function(source,args)
    if args[1] == "on" then 
        Main.SmokeON = true
        Main.Notify('Smoke is now on!')
    end
    if args[1] == "off" then 
        Main.SmokeON = false
        Main.Notify('Smoke is now off!')
    end
end)

if Config.Settings.BackWheelsOnly then
    bones = {"wheel_lr", "wheel_rr"}
else
    bones = {"wheel_lr", "wheel_rr", "wheel_lf", "wheel_rf"}
end

CreateThread(function()
    Main:loadParticleAssets(Main.ParticleName)
    Main:loadParticleAssets(Main.ParticleBase)

    while true do
        Wait(0)
        if Main.SmokeON then
            local player = GetPlayerPed(-1)
            local vehicle = GetVehiclePedIsUsing(player)
            local driftAngle, vehicleSpeed = Main:calculateDriftParams(vehicle)

            if vehicleSpeed >= 3.0 and driftAngle ~= 0 then
                Main:createSlideEffect(Main.ParticleName, "scr_wheel_burnout", vehicle, Config.Settings.SmokeDensity, Config.Settings.SmokeSize)
            end
            if vehicleSpeed < 2.0 and vehicleSpeed > 1.0 then
                Main:createSlideEffect(Main.ParticleName, "scr_wheel_burnout", vehicle, Config.Settings.SmokeDensity, Config.Settings.SmokeSize)
            end
        end
    end
end)

function Main:loadParticleAssets(assetName)
    RequestNamedPtfxAsset(assetName)
    while not HasNamedPtfxAssetLoaded(assetName) do
        Wait(0)
    end
end

function Main:createSlideEffect(particleSet, effectName, vehicle, density, scale)
    local activeParticles = Main.Particles

    for i = 1, density do
        for _, bone in ipairs(bones) do
            UseParticleFxAssetNextCall(particleSet)
            local particle = StartParticleFxLoopedOnEntityBone(
                effectName, vehicle, 0.05, 0, 0, 0, 0, 0,
                GetEntityBoneIndexByName(vehicle, bone), scale, 0, 0, 0
            )
            activeParticles[#activeParticles + 1] = particle
        end
    end

    Wait(1000)

    for _, particle in ipairs(activeParticles) do
        StopParticleFxLooped(particle, true)
    end
end

function Main:calculateDriftParams(vehicle)
    if not vehicle then return 0, 0 end

    local velocityX, velocityY, _ = table.unpack(GetEntityVelocity(vehicle))
    local combinedSpeed = math.sqrt(velocityX * velocityX + velocityY * velocityY)
    local _, _, rotationZ = table.unpack(GetEntityRotation(vehicle, 0))
    local sinZ, cosZ = -math.sin(math.rad(rotationZ)), math.cos(math.rad(rotationZ))

    if GetEntitySpeed(vehicle) * 3.6 < 5 or GetVehicleCurrentGear(vehicle) == 0 then return 0, combinedSpeed end

    local driftFactor = (sinZ * velocityX + cosZ * velocityY) / combinedSpeed
    if driftFactor > 0.966 or driftFactor < 0 then return 0, combinedSpeed end

    return math.deg(math.acos(driftFactor)) * 0.5, combinedSpeed
end

function Main:Notify(txt)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(txt)
    DrawNotification(0,1)  
end
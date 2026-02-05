if getgenv().TestMode then
local a = {}

local b = {
    velocitySmoothFactor = 0.35,
    pingCompensation = 0.9,
    distanceScaleMin = 1.0,
    distanceScaleMax = 1.75,
    distanceScaleRange = 480,
    distanceScaleOffset = 80,
    timeScaleMultiplier = 0.45,
    timeScaleMax = 1.6,
    epsilon = 1e-9
}

local cloneref = cloneref or function(obj)
    return obj
end
local d = cloneref(game:GetService("Players"))
local e = d.LocalPlayer

local f = {}
local g = {}

local h = 0
local i = false
if getthreadidentity and setthreadidentity then
    i = true
    h = getthreadidentity()
elseif shared.vape and shared.vape.ThreadFix then
    i = true
    h = 0
end

local function setThreadSafe(j)
    if i then
        setthreadidentity(j)
    end
end

local function isZero(j)
    return j > -b.epsilon and j < b.epsilon
end

local function cuberoot(j)
    return (j >= 0) and math.pow(j, 0.3333333333333333) or -math.pow(-j, 0.3333333333333333)
end

local function solveQuadric(j, k, l)
    local m = k / (2 * j)
    local n = l / j
    local o = m * m - n

    if isZero(o) then
        return -m
    elseif o < 0 then
        return nil, nil
    else
        local p = math.sqrt(o)
        return p - m, -p - m
    end
end

local function solveCubic(j, k, l, m)
    local n = k / j
    local o = l / j
    local p = m / j

    local q = n * n
    local r = (0.3333333333333333) * (-q / 3 + o)
    local s = 0.5 * ((7.4074074074074066E-2) * n * q - (n * o) / 3 + p)

    local t = s * s + r * r * r
    local u, v, w, x

    if isZero(t) then
        if isZero(s) then
            u, x = 0, 1
        else
            local y = cuberoot(-s)
            u, v, x = 2 * y, -y, 2
        end
    elseif t < 0 then
        local y = (0.3333333333333333) * math.acos(-s / math.sqrt(-r * r * r))
        local z = 2 * math.sqrt(-r)
        u = z * math.cos(y)
        v = -z * math.cos(y + math.pi / 3)
        w = -z * math.cos(y - math.pi / 3)
        x = 3
    else
        local y = math.sqrt(t)
        local z = cuberoot(y - s)
        local A = -cuberoot(y + s)
        u, x = z + A, 1
    end

    local y = n / 3
    if x and x > 0 then
        u = u and (u - y) or nil
    end
    if x and x > 1 then
        v = v and (v - y) or nil
    end
    if x and x > 2 then
        w = w and (w - y) or nil
    end

    return u, v, w
end

function a.solveQuartic(j, k, l, m, n)
    local o = k / j
    local p = l / j
    local q = m / j
    local r = n / j

    local s = o * o
    local t = -0.375 * s + p
    local u = 0.125 * s * o - 0.5 * o * p + q
    local v = -1.171875E-2 * s * s + 0.0625 * s * p - 0.25 * o * q + r

    local w, x, y, z
    local A = {}

    if isZero(v) then
        A = {1, 0, t, u}
        w, x, y = solveCubic(A[1], A[2], A[3], A[4])
    else
        A[1] = 1
        A[2] = -0.5 * t
        A[3] = -v
        A[4] = 0.5 * v * t - 0.125 * u * u

        local B = solveCubic(A[1], A[2], A[3], A[4])
        if not B then
            return nil
        end

        local C = B * B - v
        local D = 2 * B - t
        if C < 0 or D < 0 then
            return nil
        end

        C = isZero(C) and 0 or math.sqrt(C)
        D = isZero(D) and 0 or math.sqrt(D)

        local function quad(E, F)
            return solveQuadric(1, F, E)
        end

        w, x = quad(B - C, u < 0 and -D or D)
        y, z = quad(B + C, u < 0 and D or -D)
    end

    local B = o * 0.25
    if w then
        w = w - B
    end
    if x then
        x = x - B
    end
    if y then
        y = y - B
    end
    if z then
        z = z - B
    end

    return {w, x, y, z}
end

local function distanceScale(j)
    return math.clamp(1 + (j - b.distanceScaleOffset) / b.distanceScaleRange, b.distanceScaleMin, b.distanceScaleMax)
end

local function timeScale(j)
    return math.clamp(1 + j * b.timeScaleMultiplier, 1, b.timeScaleMax)
end

local function getSmoothedVelocity(j, k)
    if not j or not k then
        return Vector3.zero
    end

    local l = j.UserId
    local m = k.AssemblyLinearVelocity
    local n = tick()

    if not f[l] then
        f[l] = m
        g[l] = n
        return m
    end

    local o = n - (g[l] or n)
    local p = math.clamp(o * 60 * b.velocitySmoothFactor, 0, 1)

    local q = f[l]:Lerp(m, p)

    f[l] = q
    g[l] = n

    return q
end

local function getPingSeconds()
    local j, k =
        pcall(
        function()
            return e:GetNetworkPing()
        end
    )

    if j and k and k > 0 then
        return k
    end

    return 0.01
end

function a.clearPlayerData(j)
    if j then
        local k = j.UserId
        f[k] = nil
        g[k] = nil
    end
end

function a.clearAllData()
    f = {}
    g = {}
end

function a.predictStrafingMovement(j, k, l, m, n)
    if not j or not j.Character or not k then
        return k and k.Position or n
    end

    local o = k.Position
    local p = getSmoothedVelocity(j, k)
    local q = o - n
    local r = q.Magnitude

    if r < 1 then
        return o
    end

    local s = r / l
    local t = distanceScale(r)
    local u = timeScale(s)

    s = s * math.clamp(1.15 * t, 1.15, 1.9)

    local v = Vector3.new(p.X, 0, p.Z)
    local w = v * s * (0.85 * t)

    local x
    if p.Y < -12 then
        x = p.Y * s * (0.38 * u)
    elseif p.Y > 10 then
        x = p.Y * s * (0.33 * u)
    else
        x = (p.Y * s * 0.26) - (m * s * s * 0.12)
    end

    return o + w + Vector3.new(0, x, 0)
end

local function predictWithPing(j, k, l, m, n)
    if not j or not k then
        return n
    end

    local o = a.predictStrafingMovement(j, k, l, m, n)

    local p = getPingSeconds()
    local q = getSmoothedVelocity(j, k)
    local r = (o - n).Magnitude

    local s = math.clamp(1 + r / 350, 1, 1.6)

    local t = q * p * b.pingCompensation * s

    t = Vector3.new(t.X, math.clamp(t.Y, -8, 8), t.Z)

    return o + t
end

function a.SolveTrajectory(j, k, l, m, n, o, p, q, r, s, t)
    setThreadSafe(8)

    if s and t then
        m = predictWithPing(s, t, k, l, j)
        n = getSmoothedVelocity(s, t)
    end

    if not m then
        setThreadSafe(h)
        return j
    end

    local u = m - j
    if u.Magnitude < 1 then
        setThreadSafe(h)
        return m
    end

    n = n or Vector3.zero

    local v, w, x = n.X, n.Y, n.Z
    local y, z, A = u.X, u.Y, u.Z
    local B = -0.5 * l

    local C =
        a.solveQuartic(
        B * B,
        -2 * w * B,
        w * w - 2 * z * B - k ^ 2 + v * v + x * x,
        2 * z * w + 2 * y * v + 2 * A * x,
        z * z + y * y + A * A
    )

    local D

    if C then
        local E
        for F, G in ipairs(C) do
            if G and G > 0 then
                if not E or G < E then
                    E = G
                end
            end
        end

        if E then
            local F = E * timeScale(E)

            local G = (y + v * F) / F
            local H = (z + w * F - B * F * F) / F
            local I = (A + x * F) / F

            D = j + Vector3.new(G, H, I)
        end
    end

    if not D then
        if isZero(l) then
            local E = u.Magnitude / k
            D = j + u + n * E
        else
            D = m
        end
    end

    setThreadSafe(h)

    return D
end

function a.PredictInstantHit(j, k, l)
    if not j or not k then
        return l
    end

    local m = k.Position
    local n = getSmoothedVelocity(j, k)
    local o = getPingSeconds()

    return m + n * o * b.pingCompensation
end

function a.GetSimplePrediction(j, k, l, m)
    if not j or not k then
        return m
    end

    local n = k.Position
    local o = getSmoothedVelocity(j, k)
    local p = (n - m).Magnitude
    local q = p / l

    return n + o * q
end

function a.setConfig(j)
    for k, l in pairs(j) do
        if b[k] ~= nil then
            b[k] = l
        end
    end
end

function a.getConfig()
    return table.clone(b)
end

function a.getPlayerVelocityData(j)
    if not j then
        return nil
    end
    local k = j.UserId
    return {
        lastVelocity = f[k],
        lastTime = g[k],
        age = g[k] and (tick() - g[k]) or nil
    }
end

function a.PredictMeleeCombat(j, k, l, m)
    m = m or {}

    local n = {
        usePingCompensation = m.usePingCompensation ~= false,
        useVelocityPrediction = m.useVelocityPrediction ~= false,
        swingTime = m.swingTime or 0.3,
        extraLead = m.extraLead or 0,
        velocityMultiplier = m.velocityMultiplier or 1.0,
        distanceScale = m.distanceScale or 1.0,
        predictStrafe = m.predictStrafe ~= false,
        predictVertical = m.predictVertical ~= false,
        useAcceleration = m.useAcceleration or false,
        clampVertical = m.clampVertical or true
    }

    if not j or not k or not l then
        return k and k.Position or l
    end

    setThreadSafe(8)

    local o = k.Position
    local p = getSmoothedVelocity(j, k)
    local q = (o - l).Magnitude

    if not n.useVelocityPrediction then
        setThreadSafe(h)
        return o
    end

    local r = n.swingTime + n.extraLead

    if n.usePingCompensation then
        local s = getPingSeconds()
        r = r + s
    end

    if n.distanceScale ~= 1.0 then
        local s = distanceScale(q)
        r = r * s * n.distanceScale
    end

    local s = o

    if n.predictStrafe then
        local t = Vector3.new(p.X, 0, p.Z) * n.velocityMultiplier
        s = s + t * r
    end

    if n.predictVertical then
        local t = p.Y * n.velocityMultiplier
        local u = t * r

        if n.clampVertical then
            u = math.clamp(u, -8, 8)
        end

        s = s + Vector3.new(0, u, 0)
    end

    setThreadSafe(h)

    return s, {
        distance = q,
        velocity = p,
        predictionTime = r,
        originalPos = o
    }
end

function a.PredictMeleeRaycast(j, k, l, m, n)
    local o, p = a.PredictMeleeCombat(j, k, l, n)

    local q = (o - l).Unit

    local r = math.max(p.distance - 14.399, 0)
    local s = l + q * r

    return {
        targetPosition = o,
        cameraPosition = s,
        cursorDirection = q,
        distance = p.distance,
        predictionTime = p.predictionTime
    }
end

function a.GetPredictedClosestPoint(j, k, l, m)
    local n = a.PredictMeleeCombat(j, k, l, m)

    local o = Vector3.new(2, 3, 2)

    local p = math.clamp(l.X, n.X - o.X / 2, n.X + o.X / 2)
    local q = math.clamp(l.Y, n.Y - o.Y / 2, n.Y + o.Y / 2)
    local r = math.clamp(l.Z, n.Z - o.Z / 2, n.Z + o.Z / 2)

    return Vector3.new(p, q, r)
end

function a.PredictMultipleTargets(j, k, l)
    local m = {}

    for n, o in ipairs(j) do
        if o.Player and o.RootPart then
            local p, q = a.PredictMeleeCombat(o.Player, o.RootPart, k, l)

            table.insert(
                m,
                {
                    entity = o,
                    position = p,
                    distance = q.distance,
                    velocity = q.velocity,
                    predictionTime = q.predictionTime
                }
            )
        end
    end

    table.sort(
        m,
        function(n, o)
            return n.distance < o.distance
        end
    )

    return m
end

return a

else
--[[
	Prediction Library
	Source: https://devforum.roblox.com/t/predict-projectile-ballistics-including-gravity-and-motion/1842434
]]

-- rewritten and stabilized by soryed + YWG KUSH

local module = {}
local eps = 1e-9
local oldthread = 0
if getthreadidentity and setthreadidentity or vape.ThreadFix then
	oldthread = getthreadidentity()
else
	oldthread = 0
end
local cloneref = cloneref or function(obj)
	return obj
end

local playersService = cloneref(game:GetService("Players"))
local lplr = playersService.LocalPlayer

local function isZero(d)
	return d > -eps and d < eps
end

local function cuberoot(x)
	return (x >= 0) and math.pow(x, 1/3) or -math.pow(-x, 1/3)
end

local function solveQuadric(c0, c1, c2)
	local p = c1 / (2 * c0)
	local q = c2 / c0
	local D = p*p - q

	if isZero(D) then
		return -p
	elseif D < 0 then
		return
	else
		local s = math.sqrt(D)
		return s - p, -s - p
	end
end

local function solveCubic(c0, c1, c2, c3)
	local A = c1 / c0
	local B = c2 / c0
	local C = c3 / c0

	local sqA = A*A
	local p = (1/3)*(-sqA/3 + B)
	local q = 0.5*((2/27)*A*sqA - (A*B)/3 + C)

	local D = q*q + p*p*p
	local s0, s1, s2, num

	if isZero(D) then
		if isZero(q) then
			s0, num = 0, 1
		else
			local u = cuberoot(-q)
			s0, s1, num = 2*u, -u, 2
		end
	elseif D < 0 then
		local phi = (1/3)*math.acos(-q / math.sqrt(-p*p*p))
		local t = 2*math.sqrt(-p)
		s0 = t*math.cos(phi)
		s1 = -t*math.cos(phi + math.pi/3)
		s2 = -t*math.cos(phi - math.pi/3)
		num = 3
	else
		local sd = math.sqrt(D)
		local u = cuberoot(sd - q)
		local v = -cuberoot(sd + q)
		s0, num = u + v, 1
	end

	local sub = A / 3
	if num and num > 0 then s0 -= sub end
	if num and num > 1 then s1 -= sub end
	if num and num > 2 then s2 -= sub end

	return s0, s1, s2
end

function module.solveQuartic(c0, c1, c2, c3, c4)
	local A = c1 / c0
	local B = c2 / c0
	local C = c3 / c0
	local D = c4 / c0

	local sqA = A*A
	local p = -0.375*sqA + B
	local q = 0.125*sqA*A - 0.5*A*B + C
	local r = -(3/256)*sqA*sqA + 0.0625*sqA*B - 0.25*A*C + D

	local s0, s1, s2, s3
	local coeffs = {}

	if isZero(r) then
		coeffs = {1, 0, p, q}
		s0, s1, s2 = solveCubic(coeffs[1], coeffs[2], coeffs[3], coeffs[4])
	else
		coeffs[1] = 1
		coeffs[2] = -0.5*p
		coeffs[3] = -r
		coeffs[4] = 0.5*r*p - 0.125*q*q

		local z = solveCubic(coeffs[1], coeffs[2], coeffs[3], coeffs[4])
		if not z then return end

		local u = z*z - r
		local v = 2*z - p
		if u < 0 or v < 0 then return end

		u = isZero(u) and 0 or math.sqrt(u)
		v = isZero(v) and 0 or math.sqrt(v)

		local function quad(a, b)
			return solveQuadric(1, b, a)
		end

		s0, s1 = quad(z - u, q < 0 and -v or v)
		s2, s3 = quad(z + u, q < 0 and v or -v)
	end

	local sub = A * 0.25
	if s0 then s0 -= sub end
	if s1 then s1 -= sub end
	if s2 then s2 -= sub end
	if s3 then s3 -= sub end

	return {s0, s1, s2, s3}
end



local function distanceScale(dist)
	return math.clamp(1 + (dist - 80) / 480, 1, 1.75)
end

local function timeScale(t)
	return math.clamp(1 + t * 0.45, 1, 1.6)
end

local lastVelocity = {}

local function getSmoothedVelocity(player, part)
	local id = player.UserId
	local vel = part.AssemblyLinearVelocity

	if lastVelocity[id] then
		vel = lastVelocity[id]:Lerp(vel, 0.35)
	end

	lastVelocity[id] = vel
	return vel
end

local function getPingSeconds()
	local p = lplr:GetNetworkPing()
	return (p > 0 and p) or 0.01
end

function module.predictStrafingMovement(targetPlayer, targetPart, projSpeed, gravity, origin)
	if not targetPlayer or not targetPlayer.Character or not targetPart then
		return targetPart and targetPart.Position or Vector3.zero
	end

	local pos = targetPart.Position
	local vel = getSmoothedVelocity(targetPlayer, targetPart)
	local disp = pos - origin
	local dist = disp.Magnitude
	if dist < 1 then return pos end

	local time = dist / projSpeed
	local dScale = distanceScale(dist)
	local tScale = timeScale(time)

	time *= math.clamp(1.15 * dScale, 1.15, 1.9)

	local hVel = Vector3.new(vel.X, 0, vel.Z)
	local hPred = hVel * time * (0.85 * dScale)

	local vPred
	if vel.Y < -12 then
		vPred = vel.Y * time * (0.38 * tScale)
	elseif vel.Y > 10 then
		vPred = vel.Y * time * (0.33 * tScale)
	else
		vPred = (vel.Y * time * 0.26) - (gravity * time * time * 0.12)
	end

	return pos + hPred + Vector3.new(0, vPred, 0)
end

local function predictWithPing(targetPlayer, targetPart, projSpeed, gravity, origin)
	local ping = getPingSeconds()
	local base = module.predictStrafingMovement(targetPlayer, targetPart, projSpeed, gravity, origin)

	local vel = getSmoothedVelocity(targetPlayer, targetPart)
	local dist = (base - origin).Magnitude
	local pingScale = math.clamp(1 + dist / 350, 1, 1.6)

	local lead = vel * ping * 0.9 * pingScale
	lead = Vector3.new(lead.X, math.clamp(lead.Y, -8, 8), lead.Z)

	return base + lead
end

function module.SolveTrajectory(origin,projectileSpeed,gravity,targetPos,targetVelocity,playerGravity,playerHeight,playerJump,params,targetPlayer,targetPart)
	local newPOS = nil
	task.spawn(function()
		if getthreadidentity and setthreadidentity or vape.ThreadFix then
			setthreadidentity(8)
		end
	end)	
	if targetPlayer then
		targetPos = predictWithPing(targetPlayer, targetPart, projectileSpeed, gravity, origin)
		targetVelocity = getSmoothedVelocity(targetPlayer, targetPart)
	end

	local disp = targetPos - origin
	if disp.Magnitude < 1 then
		return targetPos
	end

	local p, q, r = targetVelocity.X, targetVelocity.Y, targetVelocity.Z
	local h, j, k = disp.X, disp.Y, disp.Z
	local l = -0.5 * gravity

	local solutions = module.solveQuartic(l*l,-2*q*l,q*q - 2*j*l - projectileSpeed^2 + p*p + r*r,2*j*q + 2*h*p + 2*k*r,j*j + h*h + k*k)

	if solutions then
		local bestT
		for _, t in ipairs(solutions) do
			if t and t > 0 then
				if not bestT or t < bestT then
					bestT = t
				end
			end
		end

		if bestT then
			local t = bestT * timeScale(bestT)

			local vx = (h + p*t) / t
			local vy = (j + q*t - l*t*t) / t
			local vz = (k + r*t) / t

			newPOS = origin + Vector3.new(vx, vy, vz)
		end
	elseif gravity == 0 then
		local t = disp.Magnitude / projectileSpeed
		newPOS = origin + disp + targetVelocity * t
	end
	task.spawn(function()
		if getthreadidentity and setthreadidentity or vape.ThreadFix then
			setthreadidentity(oldthread)
		end
	end)
	return newPOS	
end

return module

end

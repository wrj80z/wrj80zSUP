--[[
	Prediction Library
	Source: https://devforum.roblox.com/t/predict-projectile-ballistics-including-gravity-and-motion/1842434
]]

-- rewritten and stabilized by soryed + YWG KUSH

local module = {}
local eps = 1e-9

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
	if not c0 or c0 == 0 then return end
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
	if not c0 or c0 == 0 then return end

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
	if not c0 or c0 == 0 then return end

	local A = c1 / c0
	local B = c2 / c0
	local C = c3 / c0
	local D = c4 / c0

	local sqA = A*A
	local p = -0.375*sqA + B
	local q = 0.125*sqA*A - 0.5*A*B + C
	local r = -(3/256)*sqA*sqA + 0.0625*sqA*B - 0.25*A*C + D

	local s0, s1, s2, s3

	if isZero(r) then
		s0, s1, s2 = solveCubic(1, 0, p, q)
	else
		local z = solveCubic(1, -0.5*p, -r, 0.5*r*p - 0.125*q*q)
		if not z then return end

		local u = z*z - r
		local v = 2*z - p
		if u < 0 or v < 0 then return end

		u = isZero(u) and 0 or math.sqrt(u)
		v = isZero(v) and 0 or math.sqrt(v)

		s0, s1 = solveQuadric(1, q < 0 and -v or v, z - u)
		s2, s3 = solveQuadric(1, q < 0 and v or -v, z + u)
	end

	local sub = A * 0.25
	if s0 then s0 -= sub end
	if s1 then s1 -= sub end
	if s2 then s2 -= sub end
	if s3 then s3 -= sub end

	return {s0, s1, s2, s3}
end

local lastVelocity = {}
local lastTime = {}

local function getSmoothedVelocity(player, part)
	if not part or not part:IsA("BasePart") then
		return Vector3.zero
	end

	local realPlayer = player and player:IsA("Player") and player
		or playersService:GetPlayerFromCharacter(player)

	local vel = part.AssemblyLinearVelocity

	if not realPlayer then
		return vel
	end

	local id = realPlayer.UserId
	local now = tick()

	if lastVelocity[id] then
		local alpha = math.clamp(vel.Magnitude / 60, 0.45, 0.8)
		vel = lastVelocity[id]:Lerp(vel, alpha)

		local dt = now - (lastTime[id] or now)
		if dt > 0 then
			local accel = (vel - lastVelocity[id]) / dt
			vel = vel + accel * 0.08
		end
	end

	lastVelocity[id] = vel
	lastTime[id] = now

	return vel
end

local function getPing()
	local p = lplr and lplr:GetNetworkPing() or 0.01
	return (p > 0 and p) or 0.01
end

function module.SolveTrajectory(origin, projectileSpeed, gravity, targetPos, targetVelocity, _, _, _, _, targetPlayer, targetPart)
	if targetPlayer and targetPart then
		targetVelocity = getSmoothedVelocity(targetPlayer, targetPart)
		targetPos = targetPart.Position
	end

	if not targetPos or not targetVelocity then
		return targetPos
	end

	local disp = targetPos - origin
	if disp.Magnitude < 1 then
		return targetPos
	end

	local p, q, r = targetVelocity.X, targetVelocity.Y, targetVelocity.Z
	local h, j, k = disp.X, disp.Y, disp.Z
	local l = -0.5 * gravity

	local solutions = module.solveQuartic(
		l*l,
		-2*q*l,
		q*q - 2*j*l - projectileSpeed^2 + p*p + r*r,
		2*j*q + 2*h*p + 2*k*r,
		j*j + h*h + k*k
	)

	local bestT
	if solutions then
		for _, t in ipairs(solutions) do
			if t and t > 0.01 and t < 4 then
				if not bestT or t < bestT then
					bestT = t
				end
			end
		end
	end

	if bestT then
		local ping = getPing()
		bestT += ping + (0.5 / projectileSpeed)

		local vx = (h + p*bestT) / bestT
		local vy = (j + q*bestT - l*bestT*bestT) / bestT
		local vz = (k + r*bestT) / bestT

		return origin + Vector3.new(vx, vy, vz)
	end

	if gravity == 0 then
		local t = disp.Magnitude / projectileSpeed
		return targetPos + targetVelocity * t
	end

	return targetPos
end

return module

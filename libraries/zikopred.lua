--[[ 
Improved Prediction Library 
Source: https://devforum.roblox.com/t/predict-projectile-ballistics-including-gravity-and-motion/1842434
]]

local module = {}

local eps = 1e-16
local MAX_ITERATIONS = 5 
local CONVERGENCE_THRESHOLD = 1e-6

local function isZero(d)
	return (d > -eps and d < eps)
end

local function cuberoot(x)
	return (x > 0) and math.pow(x, (1 / 3)) or -math.pow(math.abs(x), (1 / 3))
end

local function solveQuadric(c0, c1, c2)
	local s0, s1
	local p, q, D
	
	p = c1 / (2 * c0)
	q = c2 / c0
	D = p * p - q
	
	if isZero(D) then
		s0 = -p
		return s0
	elseif (D < 0) then
		return
	else
		local sqrt_D = math.sqrt(D)
		s0 = sqrt_D - p
		s1 = -sqrt_D - p
		return s0, s1
	end
end

local function solveCubic(c0, c1, c2, c3)
	local s0, s1, s2
	local num, sub
	local A, B, C
	local sq_A, p, q
	local cb_p, D
	
	A = c1 / c0
	B = c2 / c0
	C = c3 / c0
	
	sq_A = A * A
	p = (1 / 3) * (-(1 / 3) * sq_A + B)
	q = 0.5 * ((2 / 27) * A * sq_A - (1 / 3) * A * B + C)
	
	cb_p = p * p * p
	D = q * q + cb_p
	
	if isZero(D) then
		if isZero(q) then
			s0 = 0
			num = 1
		else
			local u = cuberoot(-q)
			s0 = 2 * u
			s1 = -u
			num = 2
		end
	elseif (D < 0) then
		local phi = (1 / 3) * math.acos(-q / math.sqrt(-cb_p))
		local t = 2 * math.sqrt(-p)
		s0 = t * math.cos(phi)
		s1 = -t * math.cos(phi + math.pi / 3)
		s2 = -t * math.cos(phi - math.pi / 3)
		num = 3
	else
		local sqrt_D = math.sqrt(D)
		local u = cuberoot(sqrt_D - q)
		local v = -cuberoot(sqrt_D + q)
		s0 = u + v
		num = 1
	end
	
	sub = (1 / 3) * A
	
	if (num > 0) then s0 = s0 - sub end
	if (num > 1) then s1 = s1 - sub end
	if (num > 2) then s2 = s2 - sub end
	
	return s0, s1, s2
end

function module.solveQuartic(c0, c1, c2, c3, c4)
	local s0, s1, s2, s3
	local coeffs = {}
	local z, u, v, sub
	local A, B, C, D
	local sq_A, p, q, r
	local num
	
	A = c1 / c0
	B = c2 / c0
	C = c3 / c0
	D = c4 / c0
	
	sq_A = A * A
	p = -0.375 * sq_A + B
	q = 0.125 * sq_A * A - 0.5 * A * B + C
	r = -(3 / 256) * sq_A * sq_A + 0.0625 * sq_A * B - 0.25 * A * C + D
	
	if isZero(r) then
		coeffs[3] = q
		coeffs[2] = p
		coeffs[1] = 0
		coeffs[0] = 1
		
		local results = {solveCubic(coeffs[0], coeffs[1], coeffs[2], coeffs[3])}
		num = #results
		s0, s1, s2 = results[1], results[2], results[3]
	else
		coeffs[3] = 0.5 * r * p - 0.125 * q * q
		coeffs[2] = -r
		coeffs[1] = -0.5 * p
		coeffs[0] = 1
		
		s0, s1, s2 = solveCubic(coeffs[0], coeffs[1], coeffs[2], coeffs[3])
		
		z = s0
		u = z * z - r
		v = 2 * z - p
		
		if isZero(u) then
			u = 0
		elseif (u > 0) then
			u = math.sqrt(u)
		else
			return
		end
		
		if isZero(v) then
			v = 0
		elseif (v > 0) then
			v = math.sqrt(v)
		else
			return
		end
		
		coeffs[2] = z - u
		coeffs[1] = q < 0 and -v or v
		coeffs[0] = 1
		
		do
			local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
			num = #results
			s0, s1 = results[1], results[2]
		end
		
		coeffs[2] = z + u
		coeffs[1] = q < 0 and v or -v
		coeffs[0] = 1
		
		if (num == 0) then
			local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
			num = num + #results
			s0, s1 = results[1], results[2]
		end
		if (num == 1) then
			local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
			num = num + #results
			s1, s2 = results[1], results[2]
		end
		if (num == 2) then
			local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
			num = num + #results
			s2, s3 = results[1], results[2]
		end
	end
	
	sub = 0.25 * A
	
	if (num > 0) then s0 = s0 - sub end
	if (num > 1) then s1 = s1 - sub end
	if (num > 2) then s2 = s2 - sub end
	if (num > 3) then s3 = s3 - sub end
	
	return {s3, s2, s1, s0}
end

local function improvedGravityCompensation(targetPos, targetVelocity, projectileSpeed, gravity, playerGravity, playerHeight, params)
	if not playerGravity or playerGravity <= 0 or math.abs(targetVelocity.Y) <= 0.01 then
		return targetPos, targetVelocity
	end
	
	local origin = targetPos
	local velocity = targetVelocity
	local timeStep = 0.016 
	local maxSteps = 200
	
	local estTime = (targetPos - origin).Magnitude / projectileSpeed
	local steps = math.min(math.ceil(estTime / timeStep), maxSteps)
	
	local predictedPos = targetPos
	local predictedVel = velocity
	
	for i = 1, steps do
		local currentTime = i * timeStep
		
		predictedVel = Vector3.new(
			velocity.X,
			velocity.Y - playerGravity * currentTime,
			velocity.Z
		)
		
		predictedPos = targetPos + Vector3.new(
			velocity.X * currentTime,
			velocity.Y * currentTime - 0.5 * playerGravity * currentTime * currentTime,
			velocity.Z * currentTime
		)
		
		if params and i % 3 == 0 then
			local rayOrigin = predictedPos + Vector3.new(0, playerHeight * 0.5, 0)
			local rayDirection = Vector3.new(0, -playerHeight * 2, 0)
			
			local success, ray = pcall(function()
				return workspace:Raycast(rayOrigin, rayDirection, params)
			end)
			
			if success and ray then
				predictedPos = ray.Position + Vector3.new(0, playerHeight, 0)
				predictedVel = Vector3.new(velocity.X, 0, velocity.Z)
				break
			end
		end
		
		if predictedVel.Y < -1 and predictedPos.Y < targetPos.Y then
			break
		end
	end
	
	return predictedPos, predictedVel
end

local function refineTrajectory(origin, projectileSpeed, gravity, targetPos, targetVelocity, initialSolution)
	if not initialSolution then return nil end
	
	local bestSolution = initialSolution
	local bestError = math.huge
	
	for iteration = 1, MAX_ITERATIONS do
		local aimDir = (bestSolution - origin).Unit
		local estTime = (bestSolution - origin).Magnitude / projectileSpeed
		
		local predictedTarget = targetPos + targetVelocity * estTime
		predictedTarget = predictedTarget - Vector3.new(0, 0.5 * gravity * estTime * estTime, 0)
		
		local erro = (bestSolution - predictedTarget).Magnitude
		
		if erro < CONVERGENCE_THRESHOLD then
			break
		end
		
		if erro < bestError then
			bestError = erro
			bestSolution = predictedTarget + Vector3.new(0, 0.5 * gravity * estTime * estTime, 0)
		else
			break 
		end
	end
	
	return bestSolution
end

local function selectBestTimeRoot(posRoots, origin, projectileSpeed, gravity, targetPos, targetVelocity)
	if #posRoots == 0 then return nil end
	
	table.sort(posRoots)
	
	for _, t in ipairs(posRoots) do
		if t > 0.01 then 
			local distance = (targetPos - origin).Magnitude
			local minTime = distance / (projectileSpeed * 1.5)
			
			if t >= minTime then
				return t
			end
		end
	end
	
	return posRoots[1]
end

function module.SolveTrajectory(origin, projectileSpeed, gravity, targetPos, targetVelocity, playerGravity, playerHeight, playerJump, params, targetAcceleration)
	if not origin or not targetPos or not projectileSpeed or projectileSpeed <= 0 then
		return nil
	end
	
	targetVelocity = targetVelocity or Vector3.new(0, 0, 0)
	targetAcceleration = targetAcceleration or Vector3.new(0, 0, 0)
	gravity = gravity or 0
	
	local t = module.GetTimeToHit(origin, projectileSpeed, gravity, targetPos, targetVelocity, playerGravity, playerHeight, params, targetAcceleration)
	
	if not t then return nil end
	
	local adjustedTargetPos = targetPos
	local adjustedVelocity = targetVelocity
	
	if targetAcceleration.Magnitude > 0.01 then
		adjustedTargetPos = targetPos + targetVelocity * t + 0.5 * targetAcceleration * t * t
		adjustedVelocity = targetVelocity + targetAcceleration * t
	end
	
	adjustedTargetPos, adjustedVelocity = improvedGravityCompensation(
		adjustedTargetPos, 
		adjustedVelocity, 
		projectileSpeed, 
		gravity, 
		playerGravity, 
		playerHeight, 
		params
	)
	
	local disp = adjustedTargetPos - origin
	local p, q, r = adjustedVelocity.X, adjustedVelocity.Y, adjustedVelocity.Z
	local h, j, k = disp.X, disp.Y, disp.Z
	local l = -0.5 * gravity
	
	local straightLineDistance = disp.Magnitude
	if straightLineDistance < 0.1 then
		return origin 
	end
	
	if math.abs(gravity) < eps then
		local d = (h + p*t)/t
		local e = (j + q*t)/t
		local f = (k + r*t)/t
		return origin + Vector3.new(d, e, f)
	end
	
	local d = (h + p*t)/t
	local e = (j + q*t - l*t*t)/t
	local f = (k + r*t)/t
	
	local aimPoint = origin + Vector3.new(d, e, f)
	
	aimPoint = refineTrajectory(origin, projectileSpeed, gravity, adjustedTargetPos, adjustedVelocity, aimPoint) or aimPoint
	
	return aimPoint
end

function module.GetTimeToHit(origin, projectileSpeed, gravity, targetPos, targetVelocity, playerGravity, playerHeight, params, targetAcceleration)
	if not origin or not targetPos or not projectileSpeed or projectileSpeed <= 0 then
		return nil
	end
	
	targetVelocity = targetVelocity or Vector3.new(0, 0, 0)
	targetAcceleration = targetAcceleration or Vector3.new(0, 0, 0)
	gravity = gravity or 0
	
	local adjustedTargetPos = targetPos
	local adjustedVelocity = targetVelocity
	
	if targetAcceleration.Magnitude > 0.01 then
		local estTime = (targetPos - origin).Magnitude / projectileSpeed
		
		for i = 1, 3 do
			adjustedTargetPos = targetPos + targetVelocity * estTime + 0.5 * targetAcceleration * estTime * estTime
			adjustedVelocity = targetVelocity + targetAcceleration * estTime
			estTime = (adjustedTargetPos - origin).Magnitude / projectileSpeed
		end
	end
	
	adjustedTargetPos, adjustedVelocity = improvedGravityCompensation(
		adjustedTargetPos,
		adjustedVelocity,
		projectileSpeed,
		gravity,
		playerGravity,
		playerHeight,
		params
	)
	
	local disp = adjustedTargetPos - origin
	local p, q, r = adjustedVelocity.X, adjustedVelocity.Y, adjustedVelocity.Z
	local h, j, k = disp.X, disp.Y, disp.Z
	local l = -0.5 * gravity
	
	if math.abs(gravity) < eps then
		return disp.Magnitude / projectileSpeed
	end
	
	local solutions = module.solveQuartic(
		l*l,
		-2*q*l,
		q*q - 2*j*l - projectileSpeed*projectileSpeed + p*p + r*r,
		2*j*q + 2*h*p + 2*k*r,
		j*j + h*h + k*k
	)
	
	if not solutions then return nil end
		local posRoots = {}
	for _, v in ipairs(solutions) do
		if v and v > 0 then
			table.insert(posRoots, v)
		end
	end
	
	return selectBestTimeRoot(posRoots, origin, projectileSpeed, gravity, adjustedTargetPos, adjustedVelocity)
end

return module

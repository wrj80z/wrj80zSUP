local front = {}
local vape = shared.vape
local cloneref = cloneref or function(obj)
	return obj
end
local playersService = cloneref(game:GetService('Players'))
local lplr = playersService.LocalPlayer
local httpService = cloneref(game:GetService('HttpService'))
local api = "https://onyxapi.ssoryed.workers.dev"

local username = getgenv().username or "GUEST"
local password = getgenv().password or "PASSWORD"

local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('Onyx', 'Failed to load : '..err, 30, 'alert')
	end
	return res
end
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/wrj80z/wrj80zSUP/'..readfile('ReVape/profiles/commit.txt')..'/'..select(1, path:gsub('ReVape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local gen = loadstring(downloadFile('ReVape/libraries/Generator.lua'), 'Generator')()
local req = (syn and syn.request) or http_requestor or request or nil
task.spawn(function()
    if req == nil or typeof(req) ~= 'function' then
        lplr:Kick('your shitty executor just doesnt support anything for requesting ig. get a better executor retard')
        return
    end
end)

local function getHWID()
    if not isfile('ReVape/accounts/hwid.txt') then
        writefile('ReVape/accounts/hwid.txt', gen:UUID())
    end
    return readfile('ReVape/accounts/hwid.txt')
end

local function decodeSafe(body)
    local ok, result = pcall(function() return httpService:JSONDecode(body) end)
    return ok and result or nil
end

function front:Login()
    local role, U, P = "", username, password
    local token = nil

    local ok = pcall(function()
        local post = req({
            Url = api.."/login",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = httpService:JSONEncode({
                username = username,
                password = password,
                hwid = getHWID()
            })
        })
        if not post then
            error("No response from the server, possibly ur shitty wifi or API is down")
        end
        if post.StatusCode == 403 then
            vape:CreateNotification("Onyx", "API HWID Mis-Match. Guest mode. Code 403", 7,'warning')
            role = "guest"
            return
        end
        if post.StatusCode ~= 200 then
            vape:CreateNotification("Onyx", `API Unreachable. Guest mode. Code {post.StatusCode or 1101}`, 7,'warning')
            role = "guest"
            return
        end
        local decoded = decodeSafe(post.Body)
        if not decoded or not decoded.success then
            vape:CreateNotification("Onyx", `Bad login response. Guest mode. Code {post.StatusCode or 1101}`, 7,'warning')
            role = "guest"
            return
        end
        token = decoded.token
        getgenv().onyx_token = token
        role = decoded.role or "user"
        getgenv().role = role
    end)

    return role, U, P, token
end

function front:ResetHWID()
    if not getgenv().onyx_token then
        vape:CreateNotification("Onyx", "You must login first.", 6, "alert")
        return false
    end

    local success = false

    local ok = pcall(function()
        local res = req({
            Url = api.."/reset-hwid",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["Authorization"] = "Bearer "..getgenv().onyx_token
            }
        })

        if not res then
            error("No response from the server, possibly ur shitty wifi or API is down")
        end
        local decoded = decodeSafe(res.Body)
        if res.StatusCode == 200 and decoded and decoded.success then
            vape:CreateNotification("Onyx", decoded.message or "HWID reset successful", 6, "success")
            success = true
            writefile("ReVape/accounts/hwid.txt", gen:UUID())
        elseif res.StatusCode == 429 then
            vape:CreateNotification("Onyx", "Reset limit reached. Try later.", 6, "warning")
        elseif res.StatusCode == 401 then
            vape:CreateNotification("Onyx", "Session expired. Login again.", 6, "warning")
        else
            vape:CreateNotification("Onyx", "Reset failed.", 6, "alert")
        end
    end)

    return success
end

return front

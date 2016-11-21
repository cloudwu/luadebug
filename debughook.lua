local rdebug = require "remotedebug"
assert(rdebug.status == "debugger")

local hook = {}

local probe_list = {}

function hook.probe(src, line, func)
	local list = probe_list[src]
	if list then
		list[line] = func
		if not func then
			if not next(list) then
				probe_list[src] = nil
				if not next(probe_list) then
					-- no more probe
					rdebug.hookmask()
				end
				return
			end
		end
	elseif func then
		probe_list[src] = { [line] = func }
	else
		return
	end
	rdebug.hookmask "crl"
end

local cr = { ["call"] = true, ["tail call"] = true, ["return"] = true }
local source
local info = {}

function hook.hook(event, currentline)
	if cr[event] then
		source = rdebug.getinfo(1,info).source
	elseif event == "line" then
		source = source or rdebug.getinfo(info).source
	else
		return	-- not hook event
	end
	local list = probe_list[source]
	if not list then
		rdebug.hookmask "cr"
		return false
	else
		rdebug.hookmask "l"
	end
	local f = list[currentline]
	if f then
		f(source, currentline)
		return true
	end
	return false
end

return hook
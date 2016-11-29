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
local linedefined
local lastlinedefined
local info = {}

function hook.hook(event, currentline)
	if cr[event] then
		local s = rdebug.getinfo(1,info)
		source = s.source
		linedefined = s.linedefined
		lastlinedefined = s.lastlinedefined
	elseif event == "line" then
		source = source or rdebug.getinfo(1, info).source
	else
		return	-- not hook event
	end
	local list = probe_list[source]
	if not list then
		if event == "line" then
			rdebug.hookmask "cr"
		end
	elseif cr[event] then
		for line, func in pairs(list) do
			if line >= linedefined and line <= lastlinedefined then
				local activeline = rdebug.activeline(line)
				if activeline == nil then
					-- todo: print(line, "disable")
					list[line] = nil
					rdebug.hookmask "cr"
					break
				end
				if activeline ~= line then
					list[line] = nil
					list[activeline] = func
				end
				rdebug.hookmask "crl"
				break
			end
		end
	else
		-- only line event can trigger probe
		local f = list[currentline]
		if f then
			f(source, currentline)
			return true
		end
	end
	return false
end

return hook

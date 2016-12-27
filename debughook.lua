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
local info = {}
local trigger_line

function hook.hook(event, currentline)
	if cr[event] then
		trigger_line = nil
		rdebug.hookmask "crl"
		return false
	end
	if trigger_line == nil then
		trigger_line = true
		-- first line after call/return
		local s = rdebug.getinfo(1,info)
		local source = s.source
		local linedefined = s.linedefined
		local lastlinedefined = s.lastlinedefined
		local list = probe_list[source]
		if not list then
			-- turn off line hook
			rdebug.hookmask "cr"
			return false
		else
			local capture = false
			for line, func in pairs(list) do
				if line >= linedefined and line <= lastlinedefined then
					local activeline = rdebug.activeline(line)
					if activeline == nil then
						-- todo: print(line, "disable")
						list[line] = nil
					else
						if activeline ~= line then
							list[line] = nil
							list[activeline] = func
						end
						capture = true
					end
				end
			end
			if not capture then
				-- turn off line hook
				rdebug.hookmask "cr"
				return false
			end
		end
	end

	-- trigger probe
	local f = list[currentline]
	if f then
		f(source, currentline)
		return true
	end
	return false
end

return hook

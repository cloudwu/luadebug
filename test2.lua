local rdebug = require "remotedebug"

if not pcall(rdebug.start, "debugsocket") then
	print "debugger disable"
end

local function foo(a,b)
	local c = a + b	-- look debugsocket.lua
	return c
end

local s = 0
for i=1,10 do
	s = foo(i,s)
	s = s + 1
end
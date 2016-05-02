local option = {}

-- options = {
--{"options=","explanation",do,"number"}
--}
function option.new()
	local obj = {options = {}}
	return setmetatable(obj,{__index = option})
end

local function escape(str)
	return str:gsub("([()%%.%[%]*+-?])","%%%1")
end

-- b,i
-- i: 引数を食ったら一つ増やす
-- b: true：オプションとして処理した，false：オプションじゃない，nil：失敗，iにメッセージ
local function option_withoutarg(i,args,optname,action)
	local r1,dummy,minus = args[i]:find("^%-%-?" .. escape(optname) .. "(%-?)$")
	if r1 == nil then return false,i end
	local msg = action(minus ~= "-")
	if msg ~= nil then return nil,msg
	else return true,i end
end

local function option_witharg(i,args,optname,action,argtype)
	local r1,r2 = args[i]:find("^%-%-?" .. escape(optname))
	if r1 == nil then return false,i end
	local msg
	local actionarg
	if args[i]:len() == r2 then
		i = i + 1
		actionarg = args[i]
	elseif args[i]:sub(r2 + 1,r2 + 1) == "=" then
		actionarg = args[i]:sub(r2 + 2)
	else return false,i end
	if actionarg == nil then return nil,"option " .. optname .. " needs an argument" end
	if argtype ~= nil then
		if argtype == "number" then
			local a = tonumber(actionarg)
			if a == nil then return nil,"option " .. optname .. " needs a number" end
			actionarg = a
		end
	end
	msg = action(actionarg)
	if msg ~= nil then return nil,msg
	else return true,i end
end

function option:parse(args)
	local remains = {}
	local i = 1
	while i <= #args do
		local b = false
		for dummy,opt in ipairs(self.options) do
			if opt[1]:sub(-1,-1) == "=" then b,i = option_witharg(i,args,opt[1]:sub(1,-2),opt[3],opt[4])
			else b,i = option_withoutarg(i,args,opt[1],opt[3]) end
			if b == nil then return nil,i end
			if b == true then break end
		end
		if b == false then table.insert(remains,args[i]) end
		i = i + 1
	end
	return remains
end

function option:helps()
	local length = 0
	local helps = {}
	for dummy,s in ipairs(self.options) do
		if s[1]:sub(-1,-1) == "=" then length = math.max(length,s[1]:len() + 5)
		elseif s[1]:sub(-1,-1) == ":" then length = math.max(length,s[1]:len() + 7)
		else length = math.max(length,s[1]:len())
		end
	end
	length = length + 2
	
	for dummy,s in ipairs(self.options) do
		local h = ""
		local valtype
		if tostring(s[4]):lower() == "number" then valtype = "NUM"
		else valtype = "VAL" end
		if s[1]:sub(-1,-1) == "=" then h = "--" .. s[1]:sub(1,-2) .. "=<" .. valtype .. ">"
		elseif s[1]:sub(-1,-1) == ":" then h = "--" .. s[1]:sub(1,-2) .. "[=<" .. valtype .. ">]"
		else h = "--" .. s[1]
		end
		table.insert(helps,string.format("%-" .. tostring(length) .. "s  %s",h,s[2]))
	end
	return table.concat(helps,"\n")
end

-- test
--local opt = option.new()
--opt.options = {
--	{"A=","",function(s) print("option A: " .. s) end},
--	{"B","",function(s) print("option B: " .. tostring(s)) end},
--}
--local args = {"A=B","--A=C","-A=X","-A","D","B","--B-","-B"}
--print("args")
--print(table.unpack(args))
--local r = opt:parse(args)
--print("remaining")
--print(table.unpack(r))

return option




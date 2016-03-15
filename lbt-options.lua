local option = {}

-- options = {
--{"options=","explanation",do}
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
	local r1,r2,minus = args[i]:find("^%-%-?" .. escape(optname) .. "(%-?)$")
	if r1 == nil then return false,i end
	local msg = action(minus ~= "-")
	if msg ~= nil then return nil,msg
	else return true,i end
end

local function option_witharg(i,args,optname,action)
	local r1,r2 = args[i]:find("^%-%-?" .. escape(optname))
	if r1 == nil then return false,i end
	local msg = nil
	if args[i]:len() == r2 then
		if i == #args then return nil,"option " .. optname .. " needs an argument"
		else
			i = i + 1
			msg = action(args[i])
		end
	elseif args[i]:sub(r2 + 1,r2 + 1) == "=" then
		msg = action(args[i]:sub(r2 + 2))
	else return false,i end
	if msg ~= nil then return nil,mg
	else return true,i end
end


function option:parse(args)
	local remains = {}
	local i = 1
	while i <= #args do
		local b = false
		for dummy,opt in ipairs(self.options) do
			if opt[1]:sub(-1,-1) == "=" then b,i = option_witharg(i,args,opt[1]:sub(1,-2),opt[3])
			else b,i = option_withoutarg(i,args,opt[1],opt[3]) end
			if b == nil then return nil,i end
			if b == true then break end
		end
		if b == false then table.insert(remains,args[i]) end
		::continue::
		i = i + 1
	end
	return remains
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




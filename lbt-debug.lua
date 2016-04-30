local debug = {}

debug.debug = false

function debug.outputarray(a)
	print("array size = " .. tostring(#a) .. "\n")
	for i = 1, #a do
		print("i = " .. tostring(i) .. ", type = " .. type(a[i]) .. "\n" .. tostring(a[i]))
	end
end

function debug.outputtable(a)
	for k,v in pairs(a) do
		print("key = " .. tostring(k) .. ", type = " .. type(v) .. "\n" .. tostring(v))
	end
end

return debug


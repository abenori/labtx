function table_include(table1,table2)
	for k,v in pairs(table1) do
		if v ~= table2[k] then return false end
	end
	return true
end
function table_equal(table1,table2)
	return table_include(table1,table2) and table_include(table2,table1)
end

function isequal(x,y)
	if type(x) ~= type(y) then
		print("type of [" .. tostring(x) .. "] and [" .. tostring(y) .. "] is different")
		print(debug.traceback())
		os.exit(1)
	end
	if type(x) == "table" then
		if table_equal(x,y) == false then
			print("tables are different")
			print("[" .. table.concat(x, "] [") .. "]")
			print("[" .. table.concat(y, "] [") .. "]")
			print(debug.traceback())
			os.exit(1)
		end
	elseif x ~= y then
		print("different: [" .. tostring(x) .. "] [" .. tostring(y) .. "]")
		print(debug.traceback())
		os.exit(1)
	end
end

package.path = package.path .. ";..\\?.lua"

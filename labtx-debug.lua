local labtxdebug = {}

labtxdebug.debugmode = false
local backup_io = io
local backup_os = os

-- labtxdebug.outputarray(array)
-- arary: 配列
-- 戻り値：なし
-- arrayの中身をコンソールに出力する
function labtxdebug.outputarray(a)
	print("array size = " .. tostring(#a) .. "\n")
	for i = 1, #a do
		print("i = " .. tostring(i) .. ", type = " .. type(a[i]) .. "\n" .. tostring(a[i]))
	end
end

-- labtxdebug.outputarray(table)
-- table: テーブル
-- 戻り値：なし
-- tableの中身をコンソールに出力する
function labtxdebug.outputtable(a)
	for k,v in pairs(a) do
		print("key = " .. tostring(k) .. ", type = " .. type(v) .. "\n" .. tostring(v))
	end
end

-- labtxdebug.abort
-- 戻り値：なし
-- 強制的に終了する．
function labtxdebug.abort()
	backup_io.stderr:write(debug.traceback(nil,3))
	backup_os.exit(0)
end

-- labtxdebug.typecheck(arg,typename,argname,acceptnil)
-- arg: 変数
-- argname: 変数名
-- typename: 文字列または文字列からなる配列
-- acceptnil: boolean （省略可能，省略時はfalse．）
-- 戻り値：なし
-- 変数argの型がtypenameに含まれるかチェックし，含まれない場合はエラーメッセージ出力後終了する．
-- acceptnil = trueの場合はarg = nilでもエラーにはならない．
function labtxdebug.typecheck(arg,argname,typename,acceptnil)
	if (acceptnil == nil or acceptnil == false) and arg == nil then
		backup_io.stderr:write("argument error: " .. argname .. " should not be nil\n")
		labtxdebug.abort()
	end
	if type(typename) == "string" then typename = {typename} end
	if arg ~= nil then
		local typenames = ""
		local found = false
		for i,tn in ipairs(typename) do
			if type(arg) == tn then
				found = true
			end
			if typenames ~= "" then typenames = typenames .. ", " end
			typenames = typenames .. tn
		end
		if found == false then
			backup_io.stderr:write("argument error: " .. argname .. " should be " .. typenames .. " but " .. type(arg) .. "\n")
			labtxdebug.abort()
		end
	end
end

return labtxdebug


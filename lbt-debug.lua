local lbtdebug = {}

lbtdebug.debugmode = false
local backup_io = io
local backup_os = os

-- lbtdebug.outputarray(array)
-- arary: 配列
-- 戻り値：なし
-- arrayの中身をコンソールに出力する
function lbtdebug.outputarray(a)
	print("array size = " .. tostring(#a) .. "\n")
	for i = 1, #a do
		print("i = " .. tostring(i) .. ", type = " .. type(a[i]) .. "\n" .. tostring(a[i]))
	end
end

-- lbtdebug.outputarray(table)
-- table: テーブル
-- 戻り値：なし
-- tableの中身をコンソールに出力する
function lbtdebug.outputtable(a)
	for k,v in pairs(a) do
		print("key = " .. tostring(k) .. ", type = " .. type(v) .. "\n" .. tostring(v))
	end
end

-- lbtdebug.abort
-- 戻り値：なし
-- 強制的に終了する．
function lbtdebug.abort()
	backup_io.stderr:write(debug.traceback(nil,3))
	backup_os.exit(0)
end

-- lbtdebug.typecheck(arg,typename,acceptnil)
-- arg: 変数
-- typename: 文字列または文字列からなる配列
-- acceptnil: boolean （省略可能，省略時はfalse．）
-- 戻り値：なし
-- 変数argの型がtypenameに含まれるかチェックし，含まれない場合はエラーメッセージ出力後終了する．
-- acceptnil = trueの場合はarg = nilでもエラーにはならない．
function lbtdebug.typecheck(arg,typename,acceptnil)
	if (acceptnil == nil or acceptnil == false) and arg == nil then
		backup_io.stderr:write("argument error: should not nil\n")
		lbtdebug.abort()
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
			backup_io.stderr:write("argument error: should be " .. typename .. " but " .. type(arg) .. "\n")
			lbtdebug.abort()
		end
	end
end

return lbtdebug


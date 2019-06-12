require "test"
local Functions = require "labtx-funcs"

-- change_case
local function change_case_check(str,t,expect)
	isequal(Functions.change_case(str,t),expect)
end
change_case_check("TeX: aiYZ: AiU","t","Tex: aiyz: Aiu")
change_case_check("ŁaiuŁeo: ŁTł: TXX","t","Łaiułeo: Łtł: Txx")
change_case_check("A \\TeX {\\TeX BCD} E","t","A \\tex {\\TeX bcd} e")
change_case_check("A {\\TeX B}","t","A {\\TeX b}")
change_case_check("A {X \\TeX B}","t","A {X \\TeX B}")
change_case_check("{X \\TeX B}","t","{X \\TeX B}")
change_case_check("{\\TeX B}","t","{\\TeX B}")
change_case_check("A: {\\TeX B}","t","A: {\\TeX B}")
change_case_check("A \\TeX {\\TeX BCD} E","l","a \\tex {\\TeX bcd} e")
change_case_check("A: {\\TeX E} FgH","t","A: {\\TeX E} fgh")
change_case_check("A: {EFgH\\TeX} FgH","t","A: {EFgH\\TeX} fgh")

-- string_split
local function string_split_check(str,func,expect1,expect2)
	local a,b = Functions.string_split(str,func)
	isequal(a,expect1)
	isequal(b,expect2)
end
string_split_check("aXbYc",function(s) return s:find("[XY]") end,{"a","b","c"},{"X","Y"})
string_split_check("aあいYc",function(s) return unicode.utf8.find(s,"[あY]") end,{"a","い","c"},{"あ","Y"})

-- text_prefix
local function text_prefix_check(str,num,expect)
	isequal(Functions.text_prefix(str,num),expect)
end
text_prefix_check("aiueo",2,"ai")
text_prefix_check("あいう",4,"あい")
text_prefix_check("あ{いう}え",4,"あ{い}")
text_prefix_check("あ{いう}eo",9,"あ{いう}")
text_prefix_check("{xb{\\ss ab}}",3,"{xb{\\}}")
text_prefix_check("abc{\\ss {n}es}xyz",5,"abc{\\ss {n}es}x")

-- text_length
local function text_length_check(str,expect)
	isequal(Functions.text_length(str),expect)
end
text_length_check("あいう",9)
text_length_check("あ{\\TeX いう}",4)
text_length_check("あ{いう}",9)
text_length_check("abc{\\ss {n}es}xyz",7)





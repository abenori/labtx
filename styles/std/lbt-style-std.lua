require "lbt-core"
require "lbt-funcs"
require "lbt-crossref"
local icu = require "lbt-string"
local U = icu.ustring
local collator = icu.collator
local col = collator.open("US")
col:strength(collator.PRIMARY)

local std_styles = {}

std_styles.macros = {}
std_styles.macros["jan"] = U"January"
std_styles.macros["feb"] = U"February"
std_styles.macros["mar"] = U"March"
std_styles.macros["apr"] = U"April"
std_styles.macros["may"] = U"May"
std_styles.macros["jun"] = U"June"
std_styles.macros["jul"] = U"July"
std_styles.macros["aug"] = U"August"
std_styles.macros["sep"] = U"September"
std_styles.macros["oct"] = U"October"
std_styles.macros["nov"] = U"November"
std_styles.macros["dec"] = U"December"
std_styles.macros["acmcs"] = U"ACM Computing Surveys"
std_styles.macros["acta"] = U"Acta Informatica"
std_styles.macros["cacm"] = U"Communications of the ACM"
std_styles.macros["ibmjrd"] = U"IBM Journal of Research and Development"
std_styles.macros["ibmsj"] = U"IBM Systems Journal"
std_styles.macros["ieeese"] = U"IEEE Transactions on Software Engineering"
std_styles.macros["ieeetc"] = U"IEEE Transactions on Computers"
std_styles.macros["ieeetcad"] = U"IEEE Transactions on Computer-Aided Design of Integrated Circuits"
std_styles.macros["ipl"] = U"Information Processing Letters"
std_styles.macros["jacm"] = U"Journal of the ACM"
std_styles.macros["jcss"] = U"Journal of Computer and System Sciences"
std_styles.macros["scp"] = U"Science of Computer Programming"
std_styles.macros["sicomp"] = U"SIAM Journal on Computing"
std_styles.macros["tocs"] = U"ACM Transactions on Computer Systems"
std_styles.macros["tods"] = U"ACM Transactions on Database Systems"
std_styles.macros["tog"] = U"ACM Transactions on Graphics"
std_styles.macros["toms"] = U"ACM Transactions on Mathematical Software"
std_styles.macros["toois"] = U"ACM Transactions on Office Information Systems"
std_styles.macros["toplas"] = U"ACM Transactions on Programming Languages and Systems"
std_styles.macros["tcs"] = U"Theoretical Computer Science"

-- generate label
local makelabelfuncs = {}
makelabelfuncs["author"] = function(names)
	local a = LBibTeX.split_names(names)
	local s = U""
	if #a > 4 then s = U"{\\etalchar{+}}" end
	local n = #a
	for i = 1,n - 5 do table.remove(a) end
	s = LBibTeX.make_name_list(a,"{v{}}{l{}}",{""},"{\\etalchar{+}}") .. s
	if #a > 1 then return s
	else
		if LBibTeX.text_length(s) > 1 then return s
		else return LBibTeX.text_prefix(LBibTeX.format_name(names,U"{ll}"),3) end
	end
end

makelabelfuncs["editor"] = makelabelfuncs["author"]
makelabelfuncs["organization"] = function(s) return LBibTeX.text_prefix(s:gsub(U"^The",U""),3) end
makelabelfuncs["key"] = function(s) return LBibTeX.text_prefix(s,3) end

local function get_label(c,fa)
	for i = 1,#fa do
		if c.fields[U(fa[i])] ~= nil then return makelabelfuncs[fa[i]](c.fields[U(fa[i])]) end
	end
	return c.key:sub(1,4)
end

local function make_label_head(c)
	if c.type == U"book" or c.type == U"inbook" then
		return get_label(c,{"author","editor","key"})
	elseif c.type == U"proceedings" then
		return get_label(c,{"editor","key","organization"})
	elseif c.type == U"manual" then
		return get_label(c,{"author","key","organization"})
	else
		return get_label(c,{"author","key"})
	end
end

function std_styles.make_label(c)
	local year
	if c.fields[U"year"] == nil then year = U""
	else year = c.fields[U"year"]:gsub(U"^[a-zA-Z~ ]",U"") end
	return make_label_head(c) .. year:sub(-2,-1)
end

local function firstnonnull(c,a)
	for i = 1,#a do
		if c.fields[a[i]] ~= nil then
			if a[i] == U"organization" then
				return c.fields[a[i]]:gsub(U"^The",U"")
			else
				return c.fields[a[i]]
			end
		end
	end
	return nil
end

local function sortfunc(a,b)
	if not equal(a.sort_label,b.sort_label) then return lessthan(a.sort_label,b.sort_label) end
	if not equal(a.sort_name_key,b.sort_name_key) then return lessthan(a.sort_name_key,b.sort_name_key) end
	if not equal(a.fields[U"year"],b.fields[U"year"]) then return lessthan(a.fields[U"year"],b.fields[U"year"]) end
	if not equal(a.sort_title_key,b.sort_title_key) then return lessthan(a.sort_title_key,b.sort_title_key) end
	return col:lessthan(a.key,b.key)
end

std_styles.sort_formatter = {}

function std_styles.sort_formatter.name(c)
	if c.type == U"book" or c.type == U"inbook" then
		x = firstnonnull(c,{U"author",U"editor"})
	elseif c.type == U"proceedings" then
		x = firstnonnull(c,{U"editor",U"organization"})
	elseif c.type == U"manual" then
		x = firstnonnull(c,{U"author",U"organization"})
	else
		x = firstnonnull(c,{U"author"})
	end
	if x~= nil then return LBibTeX.remove_TeX_cs(LBibTeX.make_name_list(LBibTeX.split_names(x),"{vv{ } }{ll{ }}{  ff{ }}{  jj{ }}",{"   "},"et al"))
	else return nil end
end

function std_styles.sort_formatter.title(c)
	title = c.fields[U"title"]
	if title ~= nil then
		if title:sub(1,4) == U"The " then title = title:sub(5)
		elseif title:sub(1,3) == U"An " then title = title:sub(4)
		elseif title:sub(1,2) == U"A " then  title = title:sub(3)
		end
		return title
	end
	return nil
end

function std_styles.sort_formatter.label(c) return c.label end
function std_styles.sort_formatter.entry_key(c) return c.key end

function std_styles.sort(cites,array,formatter,equals,lessthan)
	if array == nil then array = {"label","name","year","title","entry_key"} end
	if formatter == nil then formatter = std_styles.sort_formatter end
	if equals == nil then equals = function(a,b) return col:equals(a,b) end end
	if lessthan == nil then lessthan = function(a,b) return col:lessthan(a,b) end end
	local function eq(a,b)
		if a == nil then
			if b == nil then return true
			else return false
			end
		else
			if b == nil then return false
			else return equals(a,b)
			end
		end
	end
	-- assuming a ~= b
	local function lt(a,b)
		if a == nil then
			return false
		else
			if b == nil then return true
			else return lessthan(a,b)
			end
		end
	end
	
	for j = 1,#cites do
		if cites[j].sort_key == nil then cites[j].sort_key = {} end
	end
	
	for i = 1,#array do
		if type(array[i]) ~= "table" then
			if type(array[i]) == "string" then array[i] = U(array[i]) end
			if formatter[array[i]] == nil then formatter[array[i]] = formatter[U.encode(array[i])] end
			if formatter[array[i]] ~= nil then
				for j = 1,#cites do
					cites[j].sort_key[array[i]] = formatter[array[i]](cites[j])
				end
			end
		end
	end
	
	local function sortfunc(a,b)
		for i = 1,#array do
			if type(array[i]) == "table" then
				if not eq(a[array[i][1]],b[array[i][1]]) then return lt(a[array[i][1]],b[array[i][1]]) end
			elseif formatter[array[i]] ~= nil then
				if not eq(a.sort_key[array[i]],b.sort_key[array[i]]) then return lt(a.sort_key[array[i]],b.sort_key[array[i]]) end
			else
				if not eq(a.fields[array[i]],b.fields[array[i]]) then return lt(a.fields[array[i]],b.fields[array[i]]) end
			end
		end
	end
	
	table.sort(cites,sortfunc)
	return cites
end

std_styles.blockseparator = {}
std_styles.blockseparator[1] = ".\n\\newblock "
std_styles.blockseparator[2] = ", "
std_styles.blocklast = {}
std_styles.blocklast[1] = "."
std_styles.blocklast[2] = ". "

std_styles.Templates = {}
std_styles.Templates["article"] = "[$<author>:$<title>:[$<journal>:$<volume_number_pages>:$<date>]:$<note>]"
std_styles.Templates["book"] = "[$<author|editor>:[$<btitle>:$<book_volume>]:[<Number|$<number_if_not_volume>| in >$<series_if_not_volume>][$<publisher>:$<address>:$<edition>:$<date>]:$<note>]"
std_styles.Templates["booklet"] = "[$<author>:$<title>:[$<howpublished>:$<address>:$<date>]:$<note>]"
std_styles.Templates["inbook"] = "[$<author|editor>:[$<btitle>:$<book_volume>:$<chapter_pages>]:[<Number|$<number_if_not_volume>| in >$<series_if_not_volume>][$<publisher>:$<address>:$<edition>:$<date>]:$<note>]"
std_styles.Templates["incollection"] = "[$<author>:$<title>:[In <|$<editor>|, ><{\\em |$<booktitle>|}>:$<book_volume>:<number|$<number_if_not_volume>| in >$<series_if_not_volume>:$<chapter_pages>][$<publisher>:$<address>:$<edition>:$<date>]:$<note>]"
std_styles.Templates["inproceedings"] = "[$<author>:$<title>:[In <|$<editor>|, ><{\\em |$<booktitle>|}>:$<book_volume>:<number|$<number_if_not_volume>| in >$<series_if_not_volume>:$<pages>:$<address>:$<date_if_address>:@S<. >$<organization_if_editor_publisher>:$<date_if_not_address>]:$<note>]"
std_styles.Templates["conference"] = std_styles.Templates["incollection"]
std_styles.Templates["manual"] = "[[$<author|organization_address>]:$<btitle>:[$<organization>:$<address>:$<edition>:$<date>]:$<note>]"
std_styles.Templates["mastersthesis"] = "[$<author>:$<title>:[$<master_thesis_type>:$<school>:$<address>:$<date>]:$<note>]"
std_styles.Templates["misc"] = "[$<author>:$<title>:[$<howpublished>:$<date>]:$<note>]"
std_styles.Templates["phdthesis"] = "[$<author>:$<btitle>:[$<phd_thesis_type>:$<school>:$<address>:$<date>]:$<note>]"
std_styles.Templates["proceedings"] = "[$<editor|organization>:[$<btitle>:$<book_volume>:<number|$<number_if_not_volume>| in >$<series_if_not_volume>:$<address>:$<date_if_address>:@S<. >$<organization_if_editor_publisher>:$<date_if_not_address>]:$<note>]"
std_styles.Templates["techreport"] = "[$<author>:$<title>:[$<tr_number>:$<institution>:$<address>:$<date>]:$<note>]"
std_styles.Templates["unpublished"] = "[$<author>:$<title>:[$<note>:$<date>]]"
std_styles.Templates[""] = std_styles.Templates["misc"]

std_styles.Formatter = {}
std_styles.Formatter.date = U"<<|$<month>| >|$<year>|>"

function std_styles.Formatter:nameformat(c) return "{ff~}{vv~}{ll}{, jj}" end

function std_styles.Formatter:format_names(names)
	local a = LBibTeX.split_names(names)
	if #a <= 2 then return LBibTeX.make_name_list(a,self:nameformat(c),{", "," and "},", et~al.")
	else return LBibTeX.make_name_list(a,self:nameformat(c),{", ",", and "},", et~al.") end
end

function std_styles.Formatter:author(c)
	if c.fields["author"] == nil then return nil
	else return self:format_names(c.fields["author"]) end
end

function std_styles.Formatter:volume_number_pages(c)
	local v = c.fields["volume"]
	if v == nil then v = U"" end
	local n = c.fields["number"]
	if n == nil then n = U"" else n = U"(" .. n .. U")" end
	local p = c.fields["pages"]
	if p ~= nil then
		if v == U"" and n == U"" then p = self:pages(c)
		else p = U":" .. p:gsub(U"([^-])-([^-])",U"%1--%2") end
	else p = U"" end
	return v .. n .. p
end

function std_styles.Formatter:editor(c)
	if c.fields["editor"] == nil then return nil end
	local a = LBibTeX.split_names(c.fields["editor"])
	local r = self:format_names(c.fields["editor"]) .. U", editor"
	if #a > 1 then r = r .. U"s" end
	return r
end

function std_styles.Formatter:title(c)
	if c.fields["title"] == nil then return nil
	else return LBibTeX.change_case(c.fields["title"],"t") end
end

function std_styles.Formatter:btitle(c)
	if c.fields["title"] == nil then return nil
	else return U"{\\em " .. c.fields["title"] .. U"}" end
end

function std_styles.Formatter:journal(c)
	if c.fields["journal"] == nil then return nil
	else return U"{\\em " .. c.fields["journal"] .. U"}" end
end

local function tie_or_space(x)
	if x:len() < 3 then return U"~" .. x
	else return U" " .. x end
end

function std_styles.Formatter:edition(c)
	if c.fields["edition"] == nil then return nil
	else return LBibTeX.change_case(c.fields["edition"],"l") .. U" edition" end
end

function std_styles.Formatter:organization_if_editor_publisher(c)
	local r = nil
	if c.fields["editor"] ~= nil then r = c.fields["organization"] end
	if r == nil then r = U"" end
	if c.fields["publisher"] ~= nil then
		if r ~= U"" then r = r .. U", " end
		r = r .. c.fields["publisher"]
	end
	return r
end

function std_styles.Formatter:pages(c)
	local p = c.fields["pages"]
	if p ~= nil then
		if p:find(U"[-,+]") == nil then return U"page" .. tie_or_space(p)
		else return U"pages" .. tie_or_space(p:gsub(U"([^-])-([^-])",U"%1--%2")) end
	else return nil end
end

function std_styles.Formatter:book_volume(c)
	if c.fields["volume"] == nil then return nil end
	local r = U"volume" .. tie_or_space(c.fields["volume"])
	if c.fields["series"] ~= nil then r = r .. U" of {\\em " .. c.fields["series"] .. U"}" end
	return r
end

function std_styles.Formatter:number_if_not_volume(c)
	if c.fields["volume"] == nil and c.fields["number"] ~= nil then return tie_or_space(c.fields["number"]) end
end

function std_styles.Formatter:series_if_not_volume(c)
	if c.fields["volume"] == nil and c.fields["series"] ~= nil then return c.fields["series"] end
end

function std_styles.Formatter:chapter_pages(c)
	if c.fields["chapter"] == nil then return self:pages(c) end
	local r = U""
	if c.fields["type"] == nil then r = U"chapter"
	else r = LBibTeX.change_case(c.fields["type"],"l") end
	r = r .. tie_or_space(c.fields["chapter"])
	if c.fields["pages"] ~= nil then r = r .. U", " .. self:pages(c) end
	return r
end

function std_styles.Formatter:proceedings_organization_publisher(c)
	if c.fields["editor"] == nil then return c.fields["publisher"]
	else return c.fields["organization"] end
end

function std_styles.Formatter:master_thesis_type(c)
	if c.fields["type"] == nil then return U"Master's thesis"
	else return LBibTeX.change_case(c.fields["type"],"t") end
end

function std_styles.Formatter:phd_thesis_type(c)
	if c.fields["type"] == nil then return U"PhD thesis"
	else return LBibTeX.change_case(c.fields["type"],"t") end
end

function std_styles.Formatter:tr_number(c)
	local r = c.fields["type"]
	if r == nil then r = U"Technical Report" end
	if c.fields["number"] == nil then r = LBibTeX.change_case(r,"t")
	else r = r .. tie_or_space(c.fields["number"]) end
	return r
end

function std_styles.Formatter:date_if_address(c)
	if c.fields["address"] ~= nil then return self:date(c) end
end

function std_styles.Formatter:date_if_not_address(c)
	if c.fields["address"] == nil then return self:date(c) end
end

std_styles.CrossReference = LBibTeX.CrossReference.new()
std_styles.CrossReference.Templates = {}
std_styles.CrossReference.Templates["article"] = "[$<author>:$<title>:[<In |$<key|journal_crossref>|> \\cite{$<crossref>}:$<pages>]:$<note>]"
std_styles.CrossReference.Templates["book"] = "[$<author|editor>:$<btitle>:[$<book_crossref>  \\cite{$<crossref>}:$<edition>:$<date>]:$<note>]"
std_styles.CrossReference.Templates["inbook"] = "[$<author|editor>:[$<btitle>:$<chapter_pages>]:[$<book_crossref>  \\cite{$<crossref>}:$<edition>:$<date>]:$<note>]"
std_styles.CrossReference.Templates["incollection"] = "[$<author>:$<title>:[$<incollection_crossref> \\cite{$<crossref>}:$<chapter_pages>]:$<note>]"
std_styles.CrossReference.Templates["inproceedings"] = "[$<author>:$<title>:[$<incollection_crossref> \\cite{$<crossref>}:$<chapter_pages>]:$<note>]"
std_styles.CrossReference.Templates["conference"] = std_styles.Templates["inproceedings"]

function std_styles.Formatter:crossref(c)
	return c.fields["crossref"]:lower()
end

function std_styles.Formatter:journal_crossref(c)
	if c.fields["journal"] == nil then return nil
	else return U"{\\em " .. c.fields["journal"] .. U"\\/}" end
end

function std_styles.Formatter:book_crossref(c)
	r = U""
	if c.fields["volume"] == nil then r = U"In "
	else r = U"Volume" .. tie_or_space(c.fields["volume"]) .. U" of " end
	if c.fields["editor"] ~= nil or c.fields["editor"] == c.fields["author"] then
		r = r .. self:editor_crossref(c)
	elseif c.fields["key"] ~= nil then r = r .. c.fields["key"]
	elseif c.fields["series"] ~= nil then r = r .. U"{\\em " .. c.fields["series"] .. U"\\/}"
	end
	return r
end

function std_styles.Formatter:editor_crossref(c)
	local r = U""
	local a = LBibTeX.split_names(c.fields["editor"])
	r = r .. LBibTeX.format_name(a[1],"{vv~}{ll}")
	if (#a == 2 and a[2] == U"others") or (#a > 2) then r = r .. U" et~al."
	else r = r .. U" and " .. LBibTeX.format_name(a[2],"{vv~}{ll}") end
	return r
end

function std_styles.Formatter:incollection_crossref(c)
	local r = U""
	if c.fields["editor"] ~= nil or c.fields["editor"] == c.fields["author"] then
		return U"In " .. self:editor_crossref(c)
	elseif c.fields["key"] ~= nil then return U"In " .. c.fields["key"]
	elseif c.fields["booktitle"] ~= nil then return U"In {\\em " .. c.fields["booktitle"] .. U"\\/}"
	end
	return nil
end

return std_styles


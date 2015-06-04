require "lbt-core"
require "lbt-funcs"
require "lbt-styles"
require "lbt-template"
require "lbt-crossref"
local U = require "icu.ustring"

LBibTeX.Styles.std = {}

LBibTeX.Styles.std.macros = {}
LBibTeX.Styles.std.macros["jan"] = U"January"
LBibTeX.Styles.std.macros["feb"] = U"February"
LBibTeX.Styles.std.macros["mar"] = U"March"
LBibTeX.Styles.std.macros["apr"] = U"April"
LBibTeX.Styles.std.macros["may"] = U"May"
LBibTeX.Styles.std.macros["jun"] = U"June"
LBibTeX.Styles.std.macros["jul"] = U"July"
LBibTeX.Styles.std.macros["aug"] = U"August"
LBibTeX.Styles.std.macros["sep"] = U"September"
LBibTeX.Styles.std.macros["oct"] = U"October"
LBibTeX.Styles.std.macros["nov"] = U"November"
LBibTeX.Styles.std.macros["dec"] = U"December"
LBibTeX.Styles.std.macros["acmcs"] = U"ACM Computing Surveys"
LBibTeX.Styles.std.macros["acta"] = U"Acta Informatica"
LBibTeX.Styles.std.macros["cacm"] = U"Communications of the ACM"
LBibTeX.Styles.std.macros["ibmjrd"] = U"IBM Journal of Research and Development"
LBibTeX.Styles.std.macros["ibmsj"] = U"IBM Systems Journal"
LBibTeX.Styles.std.macros["ieeese"] = U"IEEE Transactions on Software Engineering"
LBibTeX.Styles.std.macros["ieeetc"] = U"IEEE Transactions on Computers"
LBibTeX.Styles.std.macros["ieeetcad"] = U"IEEE Transactions on Computer-Aided Design of Integrated Circuits"
LBibTeX.Styles.std.macros["ipl"] = U"Information Processing Letters"
LBibTeX.Styles.std.macros["jacm"] = U"Journal of the ACM"
LBibTeX.Styles.std.macros["jcss"] = U"Journal of Computer and System Sciences"
LBibTeX.Styles.std.macros["scp"] = U"Science of Computer Programming"
LBibTeX.Styles.std.macros["sicomp"] = U"SIAM Journal on Computing"
LBibTeX.Styles.std.macros["tocs"] = U"ACM Transactions on Computer Systems"
LBibTeX.Styles.std.macros["tods"] = U"ACM Transactions on Database Systems"
LBibTeX.Styles.std.macros["tog"] = U"ACM Transactions on Graphics"
LBibTeX.Styles.std.macros["toms"] = U"ACM Transactions on Mathematical Software"
LBibTeX.Styles.std.macros["toois"] = U"ACM Transactions on Office Information Systems"
LBibTeX.Styles.std.macros["toplas"] = U"ACM Transactions on Programming Languages and Systems"
LBibTeX.Styles.std.macros["tcs"] = U"Theoretical Computer Science"

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

function LBibTeX.Styles.std.make_label(c)
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


local collator = require "icu.collator"
local col = collator.open("US")
col:strength(collator.PRIMARY)

local function equal(a,b)
	if a == nil then
		if b == nil then return true
		else return false
		end
	else
		if b == nil then return false
		else return col:equals(a,b)
		end
	end
end

-- assuming a ~= b
local function lessthan(a,b)
	if a == nil then
		return false
	else
		if b == nil then return true
		else return col:lessthan(a,b)
		end
	end
end

local function sortfunc(a,b)
	if not equal(a.sort_label,b.sort_label) then return lessthan(a.sort_label,b.sort_label) end
	if not equal(a.sort_name_key,b.sort_name_key) then return lessthan(a.sort_name_key,b.sort_name_key) end
	if not equal(a.fields[U"year"],b.fields[U"year"]) then return lessthan(a.fields[U"year"],b.fields[U"year"]) end
	if not equal(a.sort_title_key,b.sort_title_key) then return lessthan(a.sort_title_key,b.sort_title_key) end
	return col:lessthan(a.key,b.key)
end


function LBibTeX.Styles.std.sort(cites)
	local use_label = false
	if #cites > 0 and cites[1].label ~= nil then use_label = true end
	for i = 1,#cites do
		if use_label then
			local year
			if cites[i].fields[U"year"] == nil then year = U""
			else year = cites[i].fields[U"year"]:gsub(U"[^a-zA-Z~ 0-9]",U"") end
			cites[i].sort_label = LBibTeX.remove_TeX_cs(make_label_head(cites[i]) .. year:sub(-4,-1))
		end
		local x
		if cites[i].type == U"book" or cites[i].type == U"inbook" then
			x = firstnonnull(cites[i],{U"author",U"editor"})
		elseif cites[i].type == U"proceedings" then
			x = firstnonnull(cites[i],{U"editor",U"organization"})
		elseif cites[i].type == U"manual" then
			x = firstnonnull(cites[i],{U"author",U"organization"})
		else
			x = firstnonnull(cites[i],{U"author"})
		end
		if x~= nil then cites[i].sort_name_key = LBibTeX.remove_TeX_cs(LBibTeX.make_name_list(LBibTeX.split_names(x),"{vv{ } }{ll{ }}{  ff{ }}{  jj{ }}",{"   "},"et al")) end
		title = cites[i].fields[U"title"]
		if title ~= nil then
			if title:sub(1,4) == U"The " then title = title:sub(5)
			elseif title:sub(1,3) == U"An " then title = title:sub(4)
			elseif title:sub(1,2) == U"A " then  title = title:sub(3)
			end
			cites[i].sort_title_key = LBibTeX.remove_TeX_cs(title)
		end
	end
	table.sort(cites, sortfunc)
	return cites
end

LBibTeX.Styles.std.blockseparator = {}
LBibTeX.Styles.std.blockseparator[1] = ".\n\\newblock "
LBibTeX.Styles.std.blockseparator[2] = ", "
LBibTeX.Styles.std.blocklast = {}
LBibTeX.Styles.std.blocklast[1] = "."
LBibTeX.Styles.std.blocklast[2] = ". "

LBibTeX.Styles.std.Templates = {}
LBibTeX.Styles.std.Templates["article"] = "[$<author>:$<title>:[$<journal>:$<volume_number_pages>:$<date>]:$<note>]"
LBibTeX.Styles.std.Templates["book"] = "[$<author|editor>:[$<btitle>:$<book_volume>]:[<Number|$<number_if_not_volume>| in >$<series_if_not_volume>][$<publisher>:$<address>:$<edition>:$<date>]:$<note>]"
LBibTeX.Styles.std.Templates["booklet"] = "[$<author>:$<title>:[$<howpublished>:$<address>:$<date>]:$<note>]"
LBibTeX.Styles.std.Templates["inbook"] = "[$<author|editor>:[$<btitle>:$<book_volume>:$<chapter_pages>]:[<Number|$<number_if_not_volume>| in >$<series_if_not_volume>][$<publisher>:$<address>:$<edition>:$<date>]:$<note>]"
LBibTeX.Styles.std.Templates["incollection"] = "[$<author>:$<title>:[In <|$<editor>|, ><{\\em |$<booktitle>|}>:$<book_volume>:<number|$<number_if_not_volume>| in >$<series_if_not_volume>:$<chapter_pages>][$<publisher>:$<address>:$<edition>:$<date>]:$<note>]"
LBibTeX.Styles.std.Templates["inproceedings"] = "[$<author>:$<title>:[In <|$<editor>|, ><{\\em |$<booktitle>|}>:$<book_volume>:<number|$<number_if_not_volume>| in >$<series_if_not_volume>:$<pages>:$<address>:$<date_if_address>:@S<. >$<organization_if_editor_publisher>:$<date_if_not_address>]:$<note>]"
LBibTeX.Styles.std.Templates["conference"] = LBibTeX.Styles.std.Templates["incollection"]
LBibTeX.Styles.std.Templates["manual"] = "[[$<author|organization_address>]:$<btitle>:[$<organization>:$<address>:$<edition>:$<date>]:$<note>]"
LBibTeX.Styles.std.Templates["mastersthesis"] = "[$<author>:$<title>:[$<master_thesis_type>:$<school>:$<address>:$<date>]:$<note>]"
LBibTeX.Styles.std.Templates["misc"] = "[$<author>:$<title>:[$<howpublished>:$<date>]:$<note>]"
LBibTeX.Styles.std.Templates["phdthesis"] = "[$<author>:$<btitle>:[$<phd_thesis_type>:$<school>:$<address>:$<date>]:$<note>]"
LBibTeX.Styles.std.Templates["proceedings"] = "[$<editor|organization>:[$<btitle>:$<book_volume>:<number|$<number_if_not_volume>| in >$<series_if_not_volume>:$<address>:$<date_if_address>:@S<. >$<organization_if_editor_publisher>:$<date_if_not_address>]:$<note>]"
LBibTeX.Styles.std.Templates["techreport"] = "[$<author>:$<title>:[$<tr_number>:$<institution>:$<address>:$<date>]:$<note>]"
LBibTeX.Styles.std.Templates["unpublished"] = "[$<author>:$<title>:[$<note>:$<date>]]"
LBibTeX.Styles.std.Templates[""] = LBibTeX.Styles.std.Templates["misc"]

LBibTeX.Styles.std.Formatter = {}
LBibTeX.Styles.std.Formatter.date = U"<<|$<month>| >|$<year>|>"

function LBibTeX.Styles.std.Formatter:nameformat(c) return "{ff~}{vv~}{ll}{, jj}" end

function LBibTeX.Styles.std.Formatter:format_names(names)
	local a = LBibTeX.split_names(names)
	if #a <= 2 then return LBibTeX.make_name_list(a,self:nameformat(c),{", "," and "},", et~al.")
	else return LBibTeX.make_name_list(a,self:nameformat(c),{", ",", and "},", et~al.") end
end

function LBibTeX.Styles.std.Formatter:author(c)
	if c.fields["author"] == nil then return nil
	else return self:format_names(c.fields["author"]) end
end

function LBibTeX.Styles.std.Formatter:volume_number_pages(c)
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

function LBibTeX.Styles.std.Formatter:editor(c)
	if c.fields["editor"] == nil then return nil end
	local a = LBibTeX.split_names(c.fields["editor"])
	local r = self:format_names(c.fields["editor"]) .. U", editor"
	if #a > 1 then r = r .. U"s" end
	return r
end

function LBibTeX.Styles.std.Formatter:title(c)
	if c.fields["title"] == nil then return nil
	else return LBibTeX.change_case(c.fields["title"],"t") end
end

function LBibTeX.Styles.std.Formatter:btitle(c)
	if c.fields["title"] == nil then return nil
	else return U"{\\em " .. c.fields["title"] .. U"}" end
end

function LBibTeX.Styles.std.Formatter:journal(c)
	if c.fields["journal"] == nil then return nil
	else return U"{\\em " .. c.fields["journal"] .. U"}" end
end

local function tie_or_space(x)
	if x:len() < 3 then return U"~" .. x
	else return U" " .. x end
end

function LBibTeX.Styles.std.Formatter:edition(c)
	if c.fields["edition"] == nil then return nil
	else return LBibTeX.change_case(c.fields["edition"],"l") .. U" edition" end
end

function LBibTeX.Styles.std.Formatter:organization_if_editor_publisher(c)
	local r = nil
	if c.fields["editor"] ~= nil then r = c.fields["organization"] end
	if r == nil then r = U"" end
	if c.fields["publisher"] ~= nil then
		if r ~= U"" then r = r .. U", " end
		r = r .. c.fields["publisher"]
	end
	return r
end

function LBibTeX.Styles.std.Formatter:pages(c)
	local p = c.fields["pages"]
	if p ~= nil then
		if p:find(U"[-,+]") == nil then return U"page" .. tie_or_space(p)
		else return U"pages" .. tie_or_space(p:gsub(U"([^-])-([^-])",U"%1--%2")) end
	else return nil end
end

function LBibTeX.Styles.std.Formatter:book_volume(c)
	if c.fields["volume"] == nil then return nil end
	local r = U"volume" .. tie_or_space(c.fields["volume"])
	if c.fields["series"] ~= nil then r = r .. U" of {\\em " .. c.fields["series"] .. U"}" end
	return r
end

function LBibTeX.Styles.std.Formatter:number_if_not_volume(c)
	if c.fields["volume"] == nil and c.fields["number"] ~= nil then return tie_or_space(c.fields["number"]) end
end

function LBibTeX.Styles.std.Formatter:series_if_not_volume(c)
	if c.fields["volume"] == nil and c.fields["series"] ~= nil then return c.fields["series"] end
end

function LBibTeX.Styles.std.Formatter:chapter_pages(c)
	if c.fields["chapter"] == nil then return self:pages(c) end
	local r = U""
	if c.fields["type"] == nil then r = U"chapter"
	else r = LBibTeX.change_case(c.fields["type"],"l") end
	r = r .. tie_or_space(c.fields["chapter"])
	if c.fields["pages"] ~= nil then r = r .. U", " .. self:pages(c) end
	return r
end

function LBibTeX.Styles.std.Formatter:proceedings_organization_publisher(c)
	if c.fields["editor"] == nil then return c.fields["publisher"]
	else return c.fields["organization"] end
end

function LBibTeX.Styles.std.Formatter:master_thesis_type(c)
	if c.fields["type"] == nil then return U"Master's thesis"
	else return LBibTeX.change_case(c.fields["type"],"t") end
end

function LBibTeX.Styles.std.Formatter:phd_thesis_type(c)
	if c.fields["type"] == nil then return U"PhD thesis"
	else return LBibTeX.change_case(c.fields["type"],"t") end
end

function LBibTeX.Styles.std.Formatter:tr_number(c)
	local r = c.fields["type"]
	if r == nil then r = U"Technical Report" end
	if c.fields["number"] == nil then r = LBibTeX.change_case(r,"t")
	else r = r .. tie_or_space(c.fields["number"]) end
	return r
end

function LBibTeX.Styles.std.Formatter:date_if_address(c)
	if c.fields["address"] ~= nil then return self:date(c) end
end

function LBibTeX.Styles.std.Formatter:date_if_not_address(c)
	if c.fields["address"] == nil then return self:date(c) end
end

LBibTeX.Styles.std.CrossReference = LBibTeX.CrossReference.new()
LBibTeX.Styles.std.CrossReference.Templates = {}
LBibTeX.Styles.std.CrossReference.Templates["article"] = "[$<author>:$<title>:[<In |$<key|journal_crossref>|> \\cite{$<crossref>}:$<pages>]:$<note>]"
LBibTeX.Styles.std.CrossReference.Templates["book"] = "[$<author|editor>:$<btitle>:[$<book_crossref>  \\cite{$<crossref>}:$<edition>:$<date>]:$<note>]"
LBibTeX.Styles.std.CrossReference.Templates["inbook"] = "[$<author|editor>:[$<btitle>:$<chapter_pages>]:[$<book_crossref>  \\cite{$<crossref>}:$<edition>:$<date>]:$<note>]"
LBibTeX.Styles.std.CrossReference.Templates["incollection"] = "[$<author>:$<title>:[$<incollection_crossref> \\cite{$<crossref>}:$<chapter_pages>]:$<note>]"
LBibTeX.Styles.std.CrossReference.Templates["inproceedings"] = "[$<author>:$<title>:[$<incollection_crossref> \\cite{$<crossref>}:$<chapter_pages>]:$<note>]"
LBibTeX.Styles.std.CrossReference.Templates["conference"] = LBibTeX.Styles.std.Templates["inproceedings"]

function LBibTeX.Styles.std.Formatter:crossref(c)
	return c.fields["crossref"]:lower()
end

function LBibTeX.Styles.std.Formatter:journal_crossref(c)
	if c.fields["journal"] == nil then return nil
	else return U"{\\em " .. c.fields["journal"] .. U"\\/}" end
end

function LBibTeX.Styles.std.Formatter:book_crossref(c)
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

function LBibTeX.Styles.std.Formatter:editor_crossref(c)
	local r = U""
	local a = LBibTeX.split_names(c.fields["editor"])
	r = r .. LBibTeX.format_name(a[1],"{vv~}{ll}")
	if (#a == 2 and a[2] == U"others") or (#a > 2) then r = r .. U" et~al."
	else r = r .. U" and " .. LBibTeX.format_name(a[2],"{vv~}{ll}") end
	return r
end

function LBibTeX.Styles.std.Formatter:incollection_crossref(c)
	local r = U""
	if c.fields["editor"] ~= nil or c.fields["editor"] == c.fields["author"] then
		return U"In " .. self:editor_crossref(c)
	elseif c.fields["key"] ~= nil then return U"In " .. c.fields["key"]
	elseif c.fields["booktitle"] ~= nil then return U"In {\\em " .. c.fields["booktitle"] .. U"\\/}"
	end
	return nil
end


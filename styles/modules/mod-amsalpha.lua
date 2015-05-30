require "lbt-core"
require "lbt-funcs"
require "lbt-styles"
require "lbt-template"
local U = require "icu.ustring"

LBibTeX.Styles.amsalpha = {}
LBibTeX.Styles.amsalpha.macros = {}
LBibTeX.Styles.amsalpha.macros["jan"] = U"January"
LBibTeX.Styles.amsalpha.macros["feb"] = U"February"
LBibTeX.Styles.amsalpha.macros["mar"] = U"March"
LBibTeX.Styles.amsalpha.macros["apr"] = U"April"
LBibTeX.Styles.amsalpha.macros["may"] = U"May"
LBibTeX.Styles.amsalpha.macros["jun"] = U"June"
LBibTeX.Styles.amsalpha.macros["jul"] = U"July"
LBibTeX.Styles.amsalpha.macros["aug"] = U"August"
LBibTeX.Styles.amsalpha.macros["sep"] = U"September"
LBibTeX.Styles.amsalpha.macros["oct"] = U"October"
LBibTeX.Styles.amsalpha.macros["nov"] = U"November"
LBibTeX.Styles.amsalpha.macros["dec"] = U"December"

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

function LBibTeX.Styles.amsalpha.make_label(c)
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
	return false
end


function LBibTeX.Styles.amsalpha.sort(cites)
	for i = 1,#cites do
		local year
		if cites[i].fields[U"year"] == nil then year = U""
		else year = cites[i].fields[U"year"]:gsub(U"[^a-zA-Z~ 0-9]",U"") end
		cites[i].sort_label = LBibTeX.remove_TeX_cs(make_label_head(cites[i]) .. year:sub(-4,-1))
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
		end
--		cites[i].sort_title_key = title:gsub(U"[^a-zA-Z~ 0-9]",U"")
		cites[i].sort_title_key = LBibTeX.remove_TeX_cs(title)
	end
	table.sort(cites, sortfunc)
	return cites
end

LBibTeX.Styles.amsalpha.Templates = {}

LBibTeX.Styles.amsalpha.Templates["article"] = U"[$<author>:<\\emph{|$<title>|}>:<|$<journal>|< \\textbf{|$<volume>|}>< (|$<year>|)>>:<no.~|$<number>|>:$<pages>:@S<>< (|$<language>|)>:$<note>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["book"] = U"[$<author|editor>:<\\emph{|$<title>|}>:$<edition>:$<book_volume_series_number>:$<publisher>:$<address>:$<date>:@S<>< (|$<language>|)>:$<note>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["booklet"] = U"[$<author>:<\\emph{|$<title>|}>:$<howpublished>:$<address>:$<date>:$<note>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["inbook"] = U"[$<author|editor>:<\\emph{|$<title>|}>:$<edition>:$<book_volume_series_number>:$<chapter_pages>:$<publisher>:$<address>:$<date>:@S<>$< (|$<language>|)>:$<note>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["incollection"] = U"[$<author>:<\\emph{|$<title>|}>:$<incollection_title_editor>:$<book_volume_series_number>:$<publisher>:$<address>:$<edition>:$<date>:$<note>:$<book_pages>:@S<>< (|$<language>|)>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["inproceedings"] = U"[$<author>:<\\emph{|$<title>|}>:<|$<booktitle>|< (|$<address>|)>< |$<editor_nonauthor>|>>:$<book_volume_series_number>:$<organization>:$<publisher>:$<date>:$<note>:$<book_pages>:@S<>< (|$<language>|)>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["conference"] = LBibTeX.Styles.amsalpha.Templates[U"inproceedings"]
LBibTeX.Styles.amsalpha.Templates["manual"] = U"[$<author|organization_address>:<\\emph{|$<title>|}>:$<manual_organization_address_aftertittle>:$<edition>:$<date>:$<note>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["mastersthesis"] = U"[$<author>:<\\emph{|$<title>|}>:$<master_thesis_type>:$<school>:$<address>:$<date>:$<note>:$<book_pages>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["misc"] = U"[$<author>:<\\emph{|$<title>|}>:$<howpublished>:$<date>:$<note>:$<book_pages>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["phdthesis"] = U"[$<author>:<\\emph{|$<title>|}>:$<phd_thesis_type>:$<school>:$<address>:$<date>:$<note>:$<book_pages>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["proceedings"] = U"[$<editor|organization>:<\\emph{|$<title>|}>:$<book_volume_series_number>:$<address>:$<proceedings_organization>:$<publisher>:$<date>:$<note>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["techreport"] = U"[$<author>:<\\emph{|$<title>|}>:$<tech_rep_number>:$<institution>:$<address>:$<date>:$<note>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["unpublished"] = U"[$<author>:<\\emph{|$<title>|}>:$<note>:$<date>]$<mrnumfunc>"

local function format_names(names)
	local a = LBibTeX.split_names(names)
	if #a <= 2 then return LBibTeX.make_name_list(a,"{ff~}{vv~}{ll}{, jj}",{", "," and "},", et~al.")
	else return LBibTeX.make_name_list(a,"{ff~}{vv~}{ll}{, jj}",{", ",", and "},", et~al.") end
end

LBibTeX.Styles.amsalpha.Formatter = {}

function LBibTeX.Styles.amsalpha.Formatter.proceedings_organization(c)
	if c.fields[U"editor"] ~= nil then return c.fields[U"organization"] end
end

local function tie_or_space(x)
	if x:len() < 3 then return U"~" .. x
	else return U" " .. x end
end

function LBibTeX.Styles.amsalpha.Formatter.tech_rep_number(c)
	local r = c.fields[U"type"]
	if r == nil then r = U"Tech. Report" end
	if c.fields[U"number"] == nil then r = LBibTeX.change_case(r,U"t")
	else r = r .. tie_or_space(c.fields[U"number"]) end
	return r
end

function LBibTeX.Styles.amsalpha.Formatter.manual_organization_address_aftertittle(c)
	if c.fields[U"author"] == nil then
		if c.fields[U"organization"] ~= nil then
			return c.fields[U"address"]
		end
	else return LBibTeX.Styles.amsalpha.Formatter.organization_address(c)
	end
end

LBibTeX.Styles.amsalpha.Formatter.date = U"<<|$<month>| >|$<year>|>"

function LBibTeX.Styles.amsalpha.Formatter.author(c)
	if c.fields[U"author"] == nil then return nil
	else return format_names(c.fields[U"author"]) end
end

function LBibTeX.Styles.amsalpha.Formatter.editor(c)
	local e = c.fields[U"editor"]
	if e == nil then return nil
	else
		local r = format_names(e)
		if #LBibTeX.split_names(e) > 1 then r = r .. U" (eds.)"
		else r = r .. U" (ed.)" end
		return r
	end
end


function LBibTeX.Styles.amsalpha.Formatter.pages(c)
	if c.fields[U"pages"] == nil then print("page is nil") return nil
	else return c.fields[U"pages"]:gsub(U"([^-])-([^-])","%1--%2") end
end

function LBibTeX.Styles.amsalpha.Formatter.title(c)
	if c.fields[U"title"] == nil then return nil
	else return LBibTeX.change_case(c.fields[U"title"],"t") end
end

function LBibTeX.Styles.amsalpha.Formatter.edition(c)
	if c.fields[U"edition"] == nil then return nil
	else return LBibTeX.change_case(c.fields[U"edition"],U"l") .. U" ed." end
end

function LBibTeX.Styles.amsalpha.Formatter.book_volume_series_number(c)
	if c.fields[U"series"] == nil then
		if c.fields[U"volume"] == nil then
			if c.fields[U"number"] == nil then return nil
			else return U"no." .. tie_or_space(c.fields[U"number"]) end
		else return U"vol." .. tie_or_space(c.fields[U"volume"]) end
	else
		if c.fields[U"volume"] == nil  then
			if c.fields[U"number"] == nil then return c.fields[U"series"]
			else  return c.fields[U"series"] .. U", no." .. tie_or_space(c.fields[U"number"]) end
		else
			if c.fields[U"number"] == nil then return c.fields[U"series"] .. U", vol." .. tie_or_space(c.fields[U"volume"])
			else return U"vol." .. tie_or_space(c.fields[U"volume"]) .. ", " .. c.fields[U"series"] .. U", no.~" .. tie_or_space(c.fields[U"number"]) end
		end
	end
end

function LBibTeX.Styles.amsalpha.Formatter.chapter_pages(c)
	if c.fields[U"chapter"] == nil then return LBibTeX.Styles.amsalpha.Formatter.book_pages(c)
	else 
		local r = U""
		if c.fields[U"type"] == nil then r = U"ch.~"
		else r = LBibTeX.change_case(c.fields[U"type"],U"l") .. U" "
		end
		r = r .. c.fields[U"chapter"]
		if c.fields[U"pages"] ~= nil then r = r .. U", " .. LBibTeX.Styles.amsalpha.Formatter.book_pages(c) end
		return r
	end
end

function LBibTeX.Styles.amsalpha.Formatter.book_pages(c)
	local p = c.fields[U"pages"]
	if p ~= nil then
		if p:find(U"[-,+]") == nil then return U"p.~" .. p
		else return U"pp.~" .. p:gsub(U"([^-])-([^-])",U"%1--%2") end
	end
end

function LBibTeX.Styles.amsalpha.Formatter.organization_address(c)
	return {c.fields[U"organization"] , c.fields[U"address"]}
end

function LBibTeX.Styles.amsalpha.Formatter.master_thesis_type(c)
	if c.fields[U"type"] == nil then return U"Master's thesis"
	else return c.fields[U"type"] end
end

function LBibTeX.Styles.amsalpha.Formatter.phd_thesis_type(c)
	if c.fields[U"type"] == nil then return U"Ph.D. thesis"
	else return LBibTeX.change_case(c.fields[U"type"],"t") end
end

function LBibTeX.Styles.amsalpha.Formatter.incollection_title_editor(c)
	local r = c.fields[U"booktitle"]
	if r == nil then r = U"" end
	local e = LBibTeX.Styles.amsalpha.Formatter.editor_nonauthor(c)
	if r ~= U"" and e ~= U"" then r = r .. U" " .. e
	else r = r .. e end
	return r
end

function LBibTeX.Styles.amsalpha.Formatter.editor_nonauthor(c)
	if c.fields[U"editor"] ~= nil then
		local e = c.fields[U"editor"]
		local r = U"(" .. format_names(e) .. U", ed"
		if #e > 1 then r = r .. U"s" end
		r = r .. U".)"
		return r
	else return U""
	end
end

LBibTeX.Styles.amsalpha.Formatter.mrnumfunc = U"<\\MR{|$<mrnumber>|}>"

LBibTeX.Styles.amsalpha.blockseparator = {U", "}
LBibTeX.Styles.amsalpha.blocklast = {U". "}

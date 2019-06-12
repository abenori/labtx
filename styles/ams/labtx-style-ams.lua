local Functions = require "labtx-funcs"
local CrossReference = require "labtx-crossref"

ams_styles = {}
ams_styles.macros = {}

ams_styles.macros["jan"] = "January"
ams_styles.macros["feb"] = "February"
ams_styles.macros["mar"] = "March"
ams_styles.macros["apr"] = "April"
ams_styles.macros["may"] = "May"
ams_styles.macros["jun"] = "June"
ams_styles.macros["jul"] = "July"
ams_styles.macros["aug"] = "August"
ams_styles.macros["sep"] = "September"
ams_styles.macros["oct"] = "October"
ams_styles.macros["nov"] = "November"
ams_styles.macros["dec"] = "December"

ams_styles.preamble =
"\\providecommand{\\bysame}{\\leavevmode\\hbox to3em{\\hrulefill}\\thinspace}\n" .. 
"\\providecommand{\\MR}{\\relax\\ifhmode\\unskip\\space\\fi MR }\n" ..
"% \\MRhref is called by the amsart/book/proc definition of \\MR.\n" ..
"\\providecommand{\\MRhref}[2]{%\n" ..
"  \\href{http://www.ams.org/mathscinet-getitem?mr=#1}{#2}\n" ..
"}\n" ..
"\\providecommand{\\href}[2]{#2}\n"


-- templates

ams_styles.blockseparator = {{", ", ". "}}

ams_styles.templates = {}
ams_styles.templates["article"] = "[$<author>:$<title>:<|$<journal>|< \\textbf{|$<volume>|}>< (|$<year>|)>>:<no.~|$<number>|>:$<pages>:@S<>< (|$<language>|)>:$<note>]$<mrnumfunc>"
ams_styles.templates["book"] = "[$<author|editor>:$<title>:$<edition>:$<book_volume_series_number>:$<publisher>:$<address>:$<date>:@S<>< (|$<language>|)>:$<note>]$<mrnumfunc>"
ams_styles.templates["booklet"] = "[$<author>:$<title>:$<howpublished>:$<address>:$<date>:$<note>]$<mrnumfunc>"
ams_styles.templates["inbook"] = "[$<author|editor>:$<title>:$<edition>:$<book_volume_series_number>:$<chapter_pages>:$<publisher>:$<address>:$<date>:@S<>$< (|$<language>|)>:$<note>]$<mrnumfunc>"
ams_styles.templates["incollection"] = "[$<author>:$<title>:$<incollection_title_editor>:$<book_volume_series_number>:$<publisher>:$<address>:$<edition>:$<date>:$<note>:$<book_pages>:@S<>< (|$<language>|)>]$<mrnumfunc>"
ams_styles.templates["inproceedings"] = "[$<author>:$<title>:<|$<booktitle>|< (|$<address>|)>< |$<editor_nonauthor>|>>:$<book_volume_series_number>:$<organization>:$<publisher>:$<date>:$<note>:$<book_pages>:@S<>< (|$<language>|)>]$<mrnumfunc>"
ams_styles.templates["conference"] = ams_styles.templates["inproceedings"]
ams_styles.templates["manual"] = "[$<author|organization_address>:$<title>:$<manual_organization_address_aftertittle>:$<edition>:$<date>:$<note>]$<mrnumfunc>"
ams_styles.templates["mastersthesis"] = "[$<author>:$<title>:$<master_thesis_type>:$<school>:$<address>:$<date>:$<note>:$<book_pages>]$<mrnumfunc>"
ams_styles.templates["misc"] = "[$<author>:$<title>:$<howpublished>:$<date>:$<note>:$<book_pages>]$<mrnumfunc>"
ams_styles.templates["phdthesis"] = "[$<author>:$<title>:$<phd_thesis_type>:$<school>:$<address>:$<date>:$<note>:$<book_pages>]$<mrnumfunc>"
ams_styles.templates["proceedings"] = "[$<editor|organization>:$<title>:$<book_volume_series_number>:$<address>:$<proceedings_organization>:$<publisher>:$<date>:$<note>]$<mrnumfunc>"
ams_styles.templates["techreport"] = "[$<author>:$<title>:$<tech_rep_number>:$<institution>:$<address>:$<date>:$<note>]$<mrnumfunc>"
ams_styles.templates["unpublished"] = "[$<author>:$<title>:$<note>:$<date>]$<mrnumfunc>"
ams_styles.templates[""] = ams_styles.templates["misc"]

ams_styles.formatters = {}
function ams_styles.formatters:nameformat(c) return "{ff~}{vv~}{ll}{, jj}" end

function ams_styles.formatters:format_names(names)
	local a = Functions.split_names(names)
	if #a <= 2 then return Functions.make_name_list(a,self:nameformat(c),{", "," and "},", et~al.")
	else return Functions.make_name_list(a,self:nameformat(c),{", ",", and "},", et~al.") end
end

function ams_styles.formatters:proceedings_organization(c)
	if c.fields["editor"] ~= nil then return c.fields["organization"] end
end

local function tie_or_space(x)
	if x:len() < 3 then return "~" .. x
	else return " " .. x end
end

function ams_styles.formatters:tech_rep_number(c)
	local r = c.fields["type"]
	if r == nil then r = "Tech. Report" end
	if c.fields["number"] == nil then r = Functions.change_case(r,"t")
	else r = r .. tie_or_space(c.fields["number"]) end
	return r
end

function ams_styles.formatters:manual_organization_address_aftertittle(c)
	if c.fields["author"] == nil then
		if c.fields["organization"] ~= nil then
			return c.fields["address"]
		end
	else return self:organization_address(c)
	end
end

ams_styles.formatters.date = "<<|$<month>| >|$<year>|>"

function ams_styles.formatters:author(c)
	if c.fields["author"] == nil then return nil
	else return self:format_names(c.fields["author"]) end
end

function ams_styles.formatters:editor(c)
	local e = c.fields["editor"]
	if e == nil then return nil
	else
		local r = self:format_names(e)
		if #Functions.split_names(e) > 1 then r = r .. " (eds.)"
		else r = r .. " (ed.)" end
		return r
	end
end


function ams_styles.formatters:pages(c)
	if c.fields["pages"] == nil then return nil
	else return c.fields["pages"]:gsub("([^-])-([^-])","%1--%2") end
end

function ams_styles.formatters:title(c)
	if c.fields["title"] == nil then return nil
	else return "\\emph{" .. Functions.change_case(c.fields["title"],"t") .. "}" end
end

function ams_styles.formatters:edition(c)
	if c.fields["edition"] == nil then return nil
	else return Functions.change_case(c.fields["edition"],"l") .. " ed." end
end

function ams_styles.formatters:book_volume_series_number(c)
	if c.fields["series"] == nil then
		if c.fields["volume"] == nil then
			if c.fields["number"] == nil then return nil
			else return "no." .. tie_or_space(c.fields["number"]) end
		else return "vol." .. tie_or_space(c.fields["volume"]) end
	else
		if c.fields["volume"] == nil  then
			if c.fields["number"] == nil then return c.fields["series"]
			else  return c.fields["series"] .. ", no." .. tie_or_space(c.fields["number"]) end
		else
			if c.fields["number"] == nil then return c.fields["series"] .. ", vol." .. tie_or_space(c.fields["volume"])
			else return "vol." .. tie_or_space(c.fields["volume"]) .. ", " .. c.fields["series"] .. ", no.~" .. tie_or_space(c.fields["number"]) end
		end
	end
end

function ams_styles.formatters:chapter_pages(c)
	if c.fields["chapter"] == nil then return self:book_pages(c)
	else 
		local r = ""
		if c.fields["type"] == nil then r = "ch.~"
		else r = Functions.change_case(c.fields["type"],"l") .. " "
		end
		r = r .. c.fields["chapter"]
		if c.fields["pages"] ~= nil then r = r .. ", " .. self:book_pages(c) end
		return r
	end
end

function ams_styles.formatters:book_pages(c)
	local p = c.fields["pages"]
	if p ~= nil then
		if p:find("[-,+]") == nil then return "p.~" .. p
		else return "pp.~" .. p:gsub("([^-])-([^-])","%1--%2") end
	end
end

function ams_styles.formatters:organization_address(c)
	return {c.fields["organization"], c.fields["address"]}
end

function ams_styles.formatters:master_thesis_type(c)
	if c.fields["type"] == nil then return "Master's thesis"
	else return c.fields["type"] end
end

function ams_styles.formatters:phd_thesis_type(c)
	if c.fields["type"] == nil then return "Ph.D. thesis"
	else return Functions.change_case(c.fields["type"],"t") end
end

function ams_styles.formatters:incollection_title_editor(c)
	local r = c.fields["booktitle"]
	if r == nil then r = "" end
	local e = self:editor_nonauthor(c)
	if r ~= "" and e ~= "" then r = r .. " " .. e
	else r = r .. e end
	return r
end

function ams_styles.formatters:editor_nonauthor(c)
	if c.fields["editor"] ~= nil then
		local e = c.fields["editor"]
		local r = "(" .. self:format_names(e) .. ", ed"
		if #e > 1 then r = r .. "s" end
		r = r .. ".)"
		return r
	else return ""
	end
end

ams_styles.formatters.mrnumfunc = "<\\MR{|$<mrnumber>|}>"



-- cross reference
ams_styles.crossref = CrossReference.new()
ams_styles.crossref.templates = {}
ams_styles.crossref.templates["article"] = "[$<author>:$<title>:<in |$<key|journal>|> \\cite{$<crossref>}:$<pages>:@S<>< (|$<language>|)>:$<note>]$<mrnumfunc>"
ams_styles.crossref.templates["book"] = "[$<author|editor>:$<title>:$<edition>:$<book_crossref> \\cite{$<crossref>}:$<date>:@S<>< (|$<language>|)>:$<note>]$<mrnumfunc>"
ams_styles.crossref.templates["inbook"] = "[$<author|editor>:$<title>:$<edition>:$<chapter_pages>:$<book_crossref> \\cite{$<crossref>}:$<date>:@S<>$< (|$<language>|)>:$<note>]$<mrnumfunc>"
ams_styles.crossref.templates["incollection"] = "[$<author>:$<title>:$<incollection_crossref> \\cite{$<crossref>}:$<note>:$<book_pages>:@S<>< (|$<language>|)>]$<mrnumfunc>"
ams_styles.crossref.templates["inproceedings"] = "[$<author>:$<title>:$<incollection_crossref> \\cite{$<crossref>}:$<note>:$<book_pages>:@S<>< (|$<language>|)>]$<mrnumfunc>"
ams_styles.crossref.templates["conference"] = ams_styles.crossref.templates["inproceedings"]

ams_styles.crossref.formatters = {}
function ams_styles.formatters:book_crossref(c)
	r = ""
	if c.fields["volume"] == nil then r = "in "
	else r = "vol." .. tie_or_space(c.fields["volume"]) .. " of " end
	if c.fields["editor"] == nil or c.fields["editor"] == c.fields["author"] then
		if c.fields["key"] == nil then
			if c.fields["series"] ~= nil then r = r .. c.fields["series"] end
		else
			r = r .. c.fields["key"]
		end
	else
		r = r .. self:editor_crossref(c)
	end
	return r
end

function ams_styles.formatters:incollection_crossref(c)
	if c.fields["editor"] ~= nil and c.fields["editor"] ~= c.fields["author"] then
		return "in " .. self:editor_crossref(c)
	end
	if c.fields["key"] ~= nil then
		return "in " .. c.fields["key"]
	end
	if c.fields["booktitle"] ~= nil then
		return "in \\emph{" .. c.fields["booktitle"] .. "}"
	end
end

function ams_styles.formatters:editor_crossref(c)
	local r = ""
	local a = Functions.split_names(c.fields["editor"])
	r = r .. Functions.format_name(a[1],"{vv~}{ll}")
	if (#a == 2 and a[2] == "others") or (#a > 2) then r = r .. " et~al."
	else r = r .. " and " .. Functions.format_name(a[2],"{vv~}{ll}") end
	return r
end

function ams_styles.formatters:crossref(c)
	return c.fields["crossref"]:lower()
end

function ams_styles.modify_citations(self,cites)
	if #cites == 0 then return cites end
	local lastauthor = cites[1].fields["author"]
	for i = 2,#cites do
		local author = cites[i].fields["author"]
		if lastauthor == author then
			cites[i].fields["author"] = "\\bysame"
		elseif author ~= nil and author ~= "" then
			lastauthor = author
		end
	end
	return cites
end

return ams_styles

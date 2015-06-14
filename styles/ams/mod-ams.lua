require "lbt-core"
require "lbt-funcs"
require "lbt-template"
require "lbt-crossref"
local icu = require "lbt-string"
local U = icu.ustring

local std_styles = require "mod-std"

ams_styles = {}
ams_styles.macros = {}

ams_styles.macros[U"jan"] = U"January"
ams_styles.macros[U"feb"] = U"February"
ams_styles.macros[U"mar"] = U"March"
ams_styles.macros[U"apr"] = U"April"
ams_styles.macros[U"may"] = U"May"
ams_styles.macros[U"jun"] = U"June"
ams_styles.macros[U"jul"] = U"July"
ams_styles.macros[U"aug"] = U"August"
ams_styles.macros[U"sep"] = U"September"
ams_styles.macros[U"oct"] = U"October"
ams_styles.macros[U"nov"] = U"November"
ams_styles.macros[U"dec"] = U"December"

-- generate label
ams_styles.make_label = std_styles.make_label

-- sort
ams_styles.sort = std_styles.sort

-- templates
ams_styles.Templates = {}

ams_styles.Templates["article"] = U"[$<author>:$<title>:<|$<journal>|< \\textbf{|$<volume>|}>< (|$<year>|)>>:<no.~|$<number>|>:$<pages>:@S<>< (|$<language>|)>:$<note>]$<mrnumfunc>"
ams_styles.Templates["book"] = U"[$<author|editor>:$<title>:$<edition>:$<book_volume_series_number>:$<publisher>:$<address>:$<date>:@S<>< (|$<language>|)>:$<note>]$<mrnumfunc>"
ams_styles.Templates["booklet"] = U"[$<author>:$<title>:$<howpublished>:$<address>:$<date>:$<note>]$<mrnumfunc>"
ams_styles.Templates["inbook"] = U"[$<author|editor>:$<title>:$<edition>:$<book_volume_series_number>:$<chapter_pages>:$<publisher>:$<address>:$<date>:@S<>$< (|$<language>|)>:$<note>]$<mrnumfunc>"
ams_styles.Templates["incollection"] = U"[$<author>:$<title>:$<incollection_title_editor>:$<book_volume_series_number>:$<publisher>:$<address>:$<edition>:$<date>:$<note>:$<book_pages>:@S<>< (|$<language>|)>]$<mrnumfunc>"
ams_styles.Templates["inproceedings"] = U"[$<author>:$<title>:<|$<booktitle>|< (|$<address>|)>< |$<editor_nonauthor>|>>:$<book_volume_series_number>:$<organization>:$<publisher>:$<date>:$<note>:$<book_pages>:@S<>< (|$<language>|)>]$<mrnumfunc>"
ams_styles.Templates["conference"] = ams_styles.Templates[U"inproceedings"]
ams_styles.Templates["manual"] = U"[$<author|organization_address>:$<title>:$<manual_organization_address_aftertittle>:$<edition>:$<date>:$<note>]$<mrnumfunc>"
ams_styles.Templates["mastersthesis"] = U"[$<author>:$<title>:$<master_thesis_type>:$<school>:$<address>:$<date>:$<note>:$<book_pages>]$<mrnumfunc>"
ams_styles.Templates["misc"] = U"[$<author>:$<title>:$<howpublished>:$<date>:$<note>:$<book_pages>]$<mrnumfunc>"
ams_styles.Templates["phdthesis"] = U"[$<author>:$<title>:$<phd_thesis_type>:$<school>:$<address>:$<date>:$<note>:$<book_pages>]$<mrnumfunc>"
ams_styles.Templates["proceedings"] = U"[$<editor|organization>:$<title>:$<book_volume_series_number>:$<address>:$<proceedings_organization>:$<publisher>:$<date>:$<note>]$<mrnumfunc>"
ams_styles.Templates["techreport"] = U"[$<author>:$<title>:$<tech_rep_number>:$<institution>:$<address>:$<date>:$<note>]$<mrnumfunc>"
ams_styles.Templates["unpublished"] = U"[$<author>:$<title>:$<note>:$<date>]$<mrnumfunc>"
ams_styles.Templates[""] = ams_styles.Templates["misc"]
ams_styles.Formatter = {}

function ams_styles.Formatter:nameformat(c) return "{ff~}{vv~}{ll}{, jj}" end

function ams_styles.Formatter:format_names(names)
	local a = LBibTeX.split_names(names)
	if #a <= 2 then return LBibTeX.make_name_list(a,self:nameformat(c),{", "," and "},", et~al.")
	else return LBibTeX.make_name_list(a,self:nameformat(c),{", ",", and "},", et~al.") end
end

function ams_styles.Formatter:proceedings_organization(c)
	if c.fields["editor"] ~= nil then return c.fields["organization"] end
end

local function tie_or_space(x)
	if x:len() < 3 then return U"~" .. x
	else return U" " .. x end
end

function ams_styles.Formatter:tech_rep_number(c)
	local r = c.fields[U"type"]
	if r == nil then r = U"Tech. Report" end
	if c.fields["number"] == nil then r = LBibTeX.change_case(r,U"t")
	else r = r .. tie_or_space(c.fields["number"]) end
	return r
end

function ams_styles.Formatter:manual_organization_address_aftertittle(c)
	if c.fields["author"] == nil then
		if c.fields["organization"] ~= nil then
			return c.fields["address"]
		end
	else return self:organization_address(c)
	end
end

ams_styles.Formatter.date = U"<<|$<month>| >|$<year>|>"

function ams_styles.Formatter:author(c)
	if c.fields["author"] == nil then return nil
	else return self:format_names(c.fields["author"]) end
end

function ams_styles.Formatter:editor(c)
	local e = c.fields["editor"]
	if e == nil then return nil
	else
		local r = self:format_names(e)
		if #LBibTeX.split_names(e) > 1 then r = r .. U" (eds.)"
		else r = r .. U" (ed.)" end
		return r
	end
end


function ams_styles.Formatter:pages(c)
	if c.fields["pages"] == nil then return nil
	else return c.fields["pages"]:gsub(U"([^-])-([^-])","%1--%2") end
end

function ams_styles.Formatter:title(c)
	if c.fields["title"] == nil then return nil
	else return U"\\emph{" .. LBibTeX.change_case(c.fields["title"],"t") .. U"}" end
end

function ams_styles.Formatter:edition(c)
	if c.fields["edition"] == nil then return nil
	else return LBibTeX.change_case(c.fields["edition"],U"l") .. U" ed." end
end

function ams_styles.Formatter:book_volume_series_number(c)
	if c.fields["series"] == nil then
		if c.fields["volume"] == nil then
			if c.fields["number"] == nil then return nil
			else return U"no." .. tie_or_space(c.fields[U"number"]) end
		else return U"vol." .. tie_or_space(c.fields[U"volume"]) end
	else
		if c.fields["volume"] == nil  then
			if c.fields["number"] == nil then return c.fields["series"]
			else  return c.fields[U"series"] .. U", no." .. tie_or_space(c.fields["number"]) end
		else
			if c.fields["number"] == nil then return c.fields["series"] .. U", vol." .. tie_or_space(c.fields[U"volume"])
			else return U"vol." .. tie_or_space(c.fields["volume"]) .. ", " .. c.fields[U"series"] .. U", no.~" .. tie_or_space(c.fields[U"number"]) end
		end
	end
end

function ams_styles.Formatter:chapter_pages(c)
	if c.fields["chapter"] == nil then return ams_styles.Formatter.book_pages(c)
	else 
		local r = U""
		if c.fields["type"] == nil then r = U"ch.~"
		else r = LBibTeX.change_case(c.fields["type"],U"l") .. U" "
		end
		r = r .. c.fields["chapter"]
		if c.fields["pages"] ~= nil then r = r .. U", " .. self:book_pages(c) end
		return r
	end
end

function ams_styles.Formatter:book_pages(c)
	local p = c.fields["pages"]
	if p ~= nil then
		if p:find(U"[-,+]") == nil then return U"p.~" .. p
		else return U"pp.~" .. p:gsub(U"([^-])-([^-])",U"%1--%2") end
	end
end

function ams_styles.Formatter:organization_address(c)
	return {c.fields["organization"], c.fields["address"]}
end

function ams_styles.Formatter:master_thesis_type(c)
	if c.fields["type"] == nil then return U"Master's thesis"
	else return c.fields["type"] end
end

function ams_styles.Formatter:phd_thesis_type(c)
	if c.fields["type"] == nil then return U"Ph.D. thesis"
	else return LBibTeX.change_case(c.fields["type"],"t") end
end

function ams_styles.Formatter:incollection_title_editor(c)
	local r = c.fields["booktitle"]
	if r == nil then r = U"" end
	local e = self:editor_nonauthor(c)
	if r ~= U"" and e ~= U"" then r = r .. U" " .. e
	else r = r .. e end
	return r
end

function ams_styles.Formatter:editor_nonauthor(c)
	if c.fields["editor"] ~= nil then
		local e = c.fields["editor"]
		local r = U"(" .. self:format_names(e) .. U", ed"
		if #e > 1 then r = r .. U"s" end
		r = r .. U".)"
		return r
	else return U""
	end
end

ams_styles.Formatter.mrnumfunc = U"<\\MR{|$<mrnumber>|}>"

ams_styles.blockseparator = {U", "}
ams_styles.blocklast = {U". "}


-- cross reference
ams_styles.CrossReference = LBibTeX.CrossReference.new()
ams_styles.CrossReference.Templates = {}
ams_styles.CrossReference.Templates["article"] = U"[$<author>:$<title>:<in |$<key|journal>|> \\cite{$<crossref>}:$<pages>:@S<>< (|$<language>|)>:$<note>]$<mrnumfunc>"
ams_styles.CrossReference.Templates["book"] = U"[$<author|editor>:$<title>:$<edition>:$<book_crossref> \\cite{$<crossref>}:$<date>:@S<>< (|$<language>|)>:$<note>]$<mrnumfunc>"
ams_styles.CrossReference.Templates["inbook"] = U"[$<author|editor>:$<title>:$<edition>:$<chapter_pages>:$<book_crossref> \\cite{$<crossref>}:$<date>:@S<>$< (|$<language>|)>:$<note>]$<mrnumfunc>"
ams_styles.CrossReference.Templates["incollection"] = U"[$<author>:$<title>:$<incollection_crossref> \\cite{$<crossref>}:$<note>:$<book_pages>:@S<>< (|$<language>|)>]$<mrnumfunc>"
ams_styles.CrossReference.Templates["inproceedings"] = U"[$<author>:$<title>:$<incollection_crossref> \\cite{$<crossref>}:$<note>:$<book_pages>:@S<>< (|$<language>|)>]$<mrnumfunc>"
ams_styles.CrossReference.Templates["conference"] = ams_styles.CrossReference.Templates["inproceedings"]

function ams_styles.Formatter:book_crossref(c)
	r = U""
	if c.fields["volume"] == nil then r = U"in "
	else r = U"vol." .. tie_or_space(c.fields["volume"]) .. U" of " end
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

function ams_styles.Formatter:incollection_crossref(c)
	if c.fields["editor"] ~= nil and c.fields["editor"] ~= c.fields["author"] then
		return U"in " .. self:editor_crossref(c)
	end
	if c.fields["key"] ~= nil then
		return U"in " .. c.fields["key"]
	end
	if c.fields["booktitle"] ~= nil then
		return U"in \\emph{" .. c.fields["booktitle"] .. U"}"
	end
end

function ams_styles.Formatter:editor_crossref(c)
	local r = U""
	local a = LBibTeX.split_names(c.fields["editor"])
	r = r .. LBibTeX.format_name(a[1],"{vv~}{ll}")
	if (#a == 2 and a[2] == U"others") or (#a > 2) then r = r .. U" et~al."
	else r = r .. U" and " .. LBibTeX.format_name(a[2],"{vv~}{ll}") end
	return r
end

function ams_styles.Formatter:crossref(c)
	return c.fields["crossref"]:lower()
end

return ams_styles

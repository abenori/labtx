require "lbt-core"
require "lbt-funcs"
require "lbt-styles"
require "lbt-template"
require "lbt-crossref"
local icu = require "lbt-string"
local U = icu.ustring

require "mod-std"

LBibTeX.Styles.amsalpha = {}
LBibTeX.Styles.amsalpha.macros = {}

LBibTeX.Styles.amsalpha.macros[U"jan"] = U"January"
LBibTeX.Styles.amsalpha.macros[U"feb"] = U"February"
LBibTeX.Styles.amsalpha.macros[U"mar"] = U"March"
LBibTeX.Styles.amsalpha.macros[U"apr"] = U"April"
LBibTeX.Styles.amsalpha.macros[U"may"] = U"May"
LBibTeX.Styles.amsalpha.macros[U"jun"] = U"June"
LBibTeX.Styles.amsalpha.macros[U"jul"] = U"July"
LBibTeX.Styles.amsalpha.macros[U"aug"] = U"August"
LBibTeX.Styles.amsalpha.macros[U"sep"] = U"September"
LBibTeX.Styles.amsalpha.macros[U"oct"] = U"October"
LBibTeX.Styles.amsalpha.macros[U"nov"] = U"November"
LBibTeX.Styles.amsalpha.macros[U"dec"] = U"December"

-- generate label
LBibTeX.Styles.amsalpha.make_label = LBibTeX.Styles.std.make_label

-- sort
LBibTeX.Styles.amsalpha.sort = LBibTeX.Styles.std.sort

-- templates
LBibTeX.Styles.amsalpha.Templates = {}

LBibTeX.Styles.amsalpha.Templates["article"] = U"[$<author>:$<title>:<|$<journal>|< \\textbf{|$<volume>|}>< (|$<year>|)>>:<no.~|$<number>|>:$<pages>:@S<>< (|$<language>|)>:$<note>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["book"] = U"[$<author|editor>:$<title>:$<edition>:$<book_volume_series_number>:$<publisher>:$<address>:$<date>:@S<>< (|$<language>|)>:$<note>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["booklet"] = U"[$<author>:$<title>:$<howpublished>:$<address>:$<date>:$<note>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["inbook"] = U"[$<author|editor>:$<title>:$<edition>:$<book_volume_series_number>:$<chapter_pages>:$<publisher>:$<address>:$<date>:@S<>$< (|$<language>|)>:$<note>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["incollection"] = U"[$<author>:$<title>:$<incollection_title_editor>:$<book_volume_series_number>:$<publisher>:$<address>:$<edition>:$<date>:$<note>:$<book_pages>:@S<>< (|$<language>|)>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["inproceedings"] = U"[$<author>:$<title>:<|$<booktitle>|< (|$<address>|)>< |$<editor_nonauthor>|>>:$<book_volume_series_number>:$<organization>:$<publisher>:$<date>:$<note>:$<book_pages>:@S<>< (|$<language>|)>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["conference"] = LBibTeX.Styles.amsalpha.Templates[U"inproceedings"]
LBibTeX.Styles.amsalpha.Templates["manual"] = U"[$<author|organization_address>:$<title>:$<manual_organization_address_aftertittle>:$<edition>:$<date>:$<note>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["mastersthesis"] = U"[$<author>:$<title>:$<master_thesis_type>:$<school>:$<address>:$<date>:$<note>:$<book_pages>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["misc"] = U"[$<author>:$<title>:$<howpublished>:$<date>:$<note>:$<book_pages>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["phdthesis"] = U"[$<author>:$<title>:$<phd_thesis_type>:$<school>:$<address>:$<date>:$<note>:$<book_pages>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["proceedings"] = U"[$<editor|organization>:$<title>:$<book_volume_series_number>:$<address>:$<proceedings_organization>:$<publisher>:$<date>:$<note>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["techreport"] = U"[$<author>:$<title>:$<tech_rep_number>:$<institution>:$<address>:$<date>:$<note>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates["unpublished"] = U"[$<author>:$<title>:$<note>:$<date>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.Templates[""] = LBibTeX.Styles.amsalpha.Templates["misc"]
LBibTeX.Styles.amsalpha.Formatter = {}

function LBibTeX.Styles.amsalpha.Formatter:nameformat(c) return "{ff~}{vv~}{ll}{, jj}" end

function LBibTeX.Styles.amsalpha.Formatter:format_names(names)
	local a = LBibTeX.split_names(names)
	if #a <= 2 then return LBibTeX.make_name_list(a,self:nameformat(c),{", "," and "},", et~al.")
	else return LBibTeX.make_name_list(a,self:nameformat(c),{", ",", and "},", et~al.") end
end

function LBibTeX.Styles.amsalpha.Formatter:proceedings_organization(c)
	if c.fields["editor"] ~= nil then return c.fields["organization"] end
end

local function tie_or_space(x)
	if x:len() < 3 then return U"~" .. x
	else return U" " .. x end
end

function LBibTeX.Styles.amsalpha.Formatter:tech_rep_number(c)
	local r = c.fields[U"type"]
	if r == nil then r = U"Tech. Report" end
	if c.fields["number"] == nil then r = LBibTeX.change_case(r,U"t")
	else r = r .. tie_or_space(c.fields["number"]) end
	return r
end

function LBibTeX.Styles.amsalpha.Formatter:manual_organization_address_aftertittle(c)
	if c.fields["author"] == nil then
		if c.fields["organization"] ~= nil then
			return c.fields["address"]
		end
	else return self:organization_address(c)
	end
end

LBibTeX.Styles.amsalpha.Formatter.date = U"<<|$<month>| >|$<year>|>"

function LBibTeX.Styles.amsalpha.Formatter:author(c)
	if c.fields["author"] == nil then return nil
	else return self:format_names(c.fields["author"]) end
end

function LBibTeX.Styles.amsalpha.Formatter:editor(c)
	local e = c.fields["editor"]
	if e == nil then return nil
	else
		local r = self:format_names(e)
		if #LBibTeX.split_names(e) > 1 then r = r .. U" (eds.)"
		else r = r .. U" (ed.)" end
		return r
	end
end


function LBibTeX.Styles.amsalpha.Formatter:pages(c)
	if c.fields["pages"] == nil then return nil
	else return c.fields["pages"]:gsub(U"([^-])-([^-])","%1--%2") end
end

function LBibTeX.Styles.amsalpha.Formatter:title(c)
	if c.fields["title"] == nil then return nil
	else return U"\\emph{" .. LBibTeX.change_case(c.fields["title"],"t") .. U"}" end
end

function LBibTeX.Styles.amsalpha.Formatter:edition(c)
	if c.fields["edition"] == nil then return nil
	else return LBibTeX.change_case(c.fields["edition"],U"l") .. U" ed." end
end

function LBibTeX.Styles.amsalpha.Formatter:book_volume_series_number(c)
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

function LBibTeX.Styles.amsalpha.Formatter:chapter_pages(c)
	if c.fields["chapter"] == nil then return LBibTeX.Styles.amsalpha.Formatter.book_pages(c)
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

function LBibTeX.Styles.amsalpha.Formatter:book_pages(c)
	local p = c.fields["pages"]
	if p ~= nil then
		if p:find(U"[-,+]") == nil then return U"p.~" .. p
		else return U"pp.~" .. p:gsub(U"([^-])-([^-])",U"%1--%2") end
	end
end

function LBibTeX.Styles.amsalpha.Formatter:organization_address(c)
	return {c.fields["organization"], c.fields["address"]}
end

function LBibTeX.Styles.amsalpha.Formatter:master_thesis_type(c)
	if c.fields["type"] == nil then return U"Master's thesis"
	else return c.fields["type"] end
end

function LBibTeX.Styles.amsalpha.Formatter:phd_thesis_type(c)
	if c.fields["type"] == nil then return U"Ph.D. thesis"
	else return LBibTeX.change_case(c.fields["type"],"t") end
end

function LBibTeX.Styles.amsalpha.Formatter:incollection_title_editor(c)
	local r = c.fields["booktitle"]
	if r == nil then r = U"" end
	local e = self:editor_nonauthor(c)
	if r ~= U"" and e ~= U"" then r = r .. U" " .. e
	else r = r .. e end
	return r
end

function LBibTeX.Styles.amsalpha.Formatter:editor_nonauthor(c)
	if c.fields["editor"] ~= nil then
		local e = c.fields["editor"]
		local r = U"(" .. self:format_names(e) .. U", ed"
		if #e > 1 then r = r .. U"s" end
		r = r .. U".)"
		return r
	else return U""
	end
end

LBibTeX.Styles.amsalpha.Formatter.mrnumfunc = U"<\\MR{|$<mrnumber>|}>"

LBibTeX.Styles.amsalpha.blockseparator = {U", "}
LBibTeX.Styles.amsalpha.blocklast = {U". "}


-- cross reference
LBibTeX.Styles.amsalpha.CrossReference = LBibTeX.CrossReference.new()
LBibTeX.Styles.amsalpha.CrossReference.Templates = {}
LBibTeX.Styles.amsalpha.CrossReference.Templates["article"] = U"[$<author>:$<title>:<in |$<key|journal>|> \\cite{$<crossref>}:$<pages>:@S<>< (|$<language>|)>:$<note>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.CrossReference.Templates["book"] = U"[$<author|editor>:$<title>:$<edition>:$<book_crossref> \\cite{$<crossref>}:$<date>:@S<>< (|$<language>|)>:$<note>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.CrossReference.Templates["inbook"] = U"[$<author|editor>:$<title>:$<edition>:$<chapter_pages>:$<book_crossref> \\cite{$<crossref>}:$<date>:@S<>$< (|$<language>|)>:$<note>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.CrossReference.Templates["incollection"] = U"[$<author>:$<title>:$<incollection_crossref> \\cite{$<crossref>}:$<note>:$<book_pages>:@S<>< (|$<language>|)>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.CrossReference.Templates["inproceedings"] = U"[$<author>:$<title>:$<incollection_crossref> \\cite{$<crossref>}:$<note>:$<book_pages>:@S<>< (|$<language>|)>]$<mrnumfunc>"
LBibTeX.Styles.amsalpha.CrossReference.Templates["conference"] = LBibTeX.Styles.amsalpha.CrossReference.Templates["inproceedings"]

function LBibTeX.Styles.amsalpha.Formatter:book_crossref(c)
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

function LBibTeX.Styles.amsalpha.Formatter:incollection_crossref(c)
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

function LBibTeX.Styles.amsalpha.Formatter:editor_crossref(c)
	local r = U""
	local a = LBibTeX.split_names(c.fields["editor"])
	r = r .. LBibTeX.format_name(a[1],"{vv~}{ll}")
	if (#a == 2 and a[2] == U"others") or (#a > 2) then r = r .. U" et~al."
	else r = r .. U" and " .. LBibTeX.format_name(a[2],"{vv~}{ll}") end
	return r
end

function LBibTeX.Styles.amsalpha.Formatter:crossref(c)
	return c.fields["crossref"]:lower()
end


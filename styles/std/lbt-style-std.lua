local Functions = require "lbt-funcs"
local CrossReference = require "lbt-crossref"

local std_styles = {}

std_styles.macros = {}
std_styles.macros["jan"] = "January"
std_styles.macros["feb"] = "February"
std_styles.macros["mar"] = "March"
std_styles.macros["apr"] = "April"
std_styles.macros["may"] = "May"
std_styles.macros["jun"] = "June"
std_styles.macros["jul"] = "July"
std_styles.macros["aug"] = "August"
std_styles.macros["sep"] = "September"
std_styles.macros["oct"] = "October"
std_styles.macros["nov"] = "November"
std_styles.macros["dec"] = "December"
std_styles.macros["acmcs"] = "ACM Computing Surveys"
std_styles.macros["acta"] = "Acta Informatica"
std_styles.macros["cacm"] = "Communications of the ACM"
std_styles.macros["ibmjrd"] = "IBM Journal of Research and Development"
std_styles.macros["ibmsj"] = "IBM Systems Journal"
std_styles.macros["ieeese"] = "IEEE Transactions on Software Engineering"
std_styles.macros["ieeetc"] = "IEEE Transactions on Computers"
std_styles.macros["ieeetcad"] = "IEEE Transactions on Computer-Aided Design of Integrated Circuits"
std_styles.macros["ipl"] = "Information Processing Letters"
std_styles.macros["jacm"] = "Journal of the ACM"
std_styles.macros["jcss"] = "Journal of Computer and System Sciences"
std_styles.macros["scp"] = "Science of Computer Programming"
std_styles.macros["sicomp"] = "SIAM Journal on Computing"
std_styles.macros["tocs"] = "ACM Transactions on Computer Systems"
std_styles.macros["tods"] = "ACM Transactions on Database Systems"
std_styles.macros["tog"] = "ACM Transactions on Graphics"
std_styles.macros["toms"] = "ACM Transactions on Mathematical Software"
std_styles.macros["toois"] = "ACM Transactions on Office Information Systems"
std_styles.macros["toplas"] = "ACM Transactions on Programming Languages and Systems"
std_styles.macros["tcs"] = "Theoretical Computer Science"

std_styles.blockseparator = {
	{".\n\\newblock ","."},
	{", ",". "}
}

std_styles.templates = {}
std_styles.templates["article"] = "[$<author>:$<title>:[$<journal>:$<volume_number_pages>:$<date>]:$<note>]"
std_styles.templates["book"] = "[$<author|editor>:[$<btitle>:$<book_volume>]:[<Number|$<number_if_not_volume>| in >$<series_if_not_volume>][$<publisher>:$<address>:$<edition>:$<date>]:$<note>]"
std_styles.templates["booklet"] = "[$<author>:$<title>:[$<howpublished>:$<address>:$<date>]:$<note>]"
std_styles.templates["inbook"] = "[$<author|editor>:[$<btitle>:$<book_volume>:$<chapter_pages>]:[<Number|$<number_if_not_volume>| in >$<series_if_not_volume>][$<publisher>:$<address>:$<edition>:$<date>]:$<note>]"
std_styles.templates["incollection"] = "[$<author>:$<title>:[In <|$<editor>|, ><{\\em |$<booktitle>|}>:$<book_volume>:<number|$<number_if_not_volume>| in >$<series_if_not_volume>:$<chapter_pages>][$<publisher>:$<address>:$<edition>:$<date>]:$<note>]"
std_styles.templates["inproceedings"] = "[$<author>:$<title>:[In <|$<editor>|, ><{\\em |$<booktitle>|}>:$<book_volume>:<number|$<number_if_not_volume>| in >$<series_if_not_volume>:$<pages>:$<address>:$<date_if_address>:@S<. >$<organization_if_editor_publisher>:$<date_if_not_address>]:$<note>]"
std_styles.templates["conference"] = std_styles.templates["incollection"]
std_styles.templates["manual"] = "[[$<author|organization_address>]:$<btitle>:[$<organization>:$<address>:$<edition>:$<date>]:$<note>]"
std_styles.templates["mastersthesis"] = "[$<author>:$<title>:[$<master_thesis_type>:$<school>:$<address>:$<date>]:$<note>]"
std_styles.templates["misc"] = "[$<author>:$<title>:[$<howpublished>:$<date>]:$<note>]"
std_styles.templates["phdthesis"] = "[$<author>:$<btitle>:[$<phd_thesis_type>:$<school>:$<address>:$<date>]:$<note>]"
std_styles.templates["proceedings"] = "[$<editor|organization>:[$<btitle>:$<book_volume>:<number|$<number_if_not_volume>| in >$<series_if_not_volume>:$<address>:$<date_if_address>:@S<. >$<organization_if_editor_publisher>:$<date_if_not_address>]:$<note>]"
std_styles.templates["techreport"] = "[$<author>:$<title>:[$<tr_number>:$<institution>:$<address>:$<date>]:$<note>]"
std_styles.templates["unpublished"] = "[$<author>:$<title>:[$<note>:$<date>]]"
std_styles.templates[""] = std_styles.templates["misc"]

std_styles.formatters = {}
std_styles.formatters.date = "<<|$<month>| >|$<year>|>"

function std_styles.formatters:nameformat(c) return "{ff~}{vv~}{ll}{, jj}" end

function std_styles.formatters:format_names(names)
	local a = Functions.split_names(names)
	if #a <= 2 then return Functions.make_name_list(a,self:nameformat(c),{", "," and "},", et~al.")
	else return Functions.make_name_list(a,self:nameformat(c),{", ",", and "},", et~al.") end
end

function std_styles.formatters:author(c)
	if c.fields["author"] == nil then return nil
	else return self:format_names(c.fields["author"]) end
end

function std_styles.formatters:volume_number_pages(c)
	local v = c.fields["volume"]
	if v == nil then v = "" end
	local n = c.fields["number"]
	if n == nil then n = "" else n = "(" .. n .. ")" end
	local p = c.fields["pages"]
	if p ~= nil then
		if v == "" and n == "" then p = self:pages(c)
		else p = ":" .. p:gsub("([^-])-([^-])","%1--%2") end
	else p = "" end
	return v .. n .. p
end

function std_styles.formatters:editor(c)
	if c.fields["editor"] == nil then return nil end
	local a = Functions.split_names(c.fields["editor"])
	local r = self:format_names(c.fields["editor"]) .. ", editor"
	if #a > 1 then r = r .. "s" end
	return r
end

function std_styles.formatters:title(c)
	if c.fields["title"] == nil then return nil
	else return Functions.change_case(c.fields["title"],"t") end
end

function std_styles.formatters:btitle(c)
	if c.fields["title"] == nil then return nil
	else return "{\\em " .. c.fields["title"] .. "}" end
end

function std_styles.formatters:journal(c)
	if c.fields["journal"] == nil then return nil
	else return "{\\em " .. c.fields["journal"] .. "}" end
end

local function tie_or_space(x)
	if x:len() < 3 then return "~" .. x
	else return " " .. x end
end

function std_styles.formatters:edition(c)
	if c.fields["edition"] == nil then return nil
	else return Functions.change_case(c.fields["edition"],"l") .. " edition" end
end

function std_styles.formatters:organization_if_editor_publisher(c)
	local r = nil
	if c.fields["editor"] ~= nil then r = c.fields["organization"] end
	if r == nil then r = "" end
	if c.fields["publisher"] ~= nil then
		if r ~= "" then r = r .. ", " end
		r = r .. c.fields["publisher"]
	end
	return r
end

function std_styles.formatters:pages(c)
	local p = c.fields["pages"]
	if p ~= nil then
		if p:find("[-,+]") == nil then return "page" .. tie_or_space(p)
		else return "pages" .. tie_or_space(p:gsub("([^-])-([^-])","%1--%2")) end
	else return nil end
end

function std_styles.formatters:book_volume(c)
	if c.fields["volume"] == nil then return nil end
	local r = "volume" .. tie_or_space(c.fields["volume"])
	if c.fields["series"] ~= nil then r = r .. " of {\\em " .. c.fields["series"] .. "}" end
	return r
end

function std_styles.formatters:number_if_not_volume(c)
	if c.fields["volume"] == nil and c.fields["number"] ~= nil then return tie_or_space(c.fields["number"]) end
end

function std_styles.formatters:series_if_not_volume(c)
	if c.fields["volume"] == nil and c.fields["series"] ~= nil then return c.fields["series"] end
end

function std_styles.formatters:chapter_pages(c)
	if c.fields["chapter"] == nil then return self:pages(c) end
	local r = ""
	if c.fields["type"] == nil then r = "chapter"
	else r = Functions.change_case(c.fields["type"],"l") end
	r = r .. tie_or_space(c.fields["chapter"])
	if c.fields["pages"] ~= nil then r = r .. ", " .. self:pages(c) end
	return r
end

function std_styles.formatters:proceedings_organization_publisher(c)
	if c.fields["editor"] == nil then return c.fields["publisher"]
	else return c.fields["organization"] end
end

function std_styles.formatters:master_thesis_type(c)
	if c.fields["type"] == nil then return "Master's thesis"
	else return Functions.change_case(c.fields["type"],"t") end
end

function std_styles.formatters:phd_thesis_type(c)
	if c.fields["type"] == nil then return "PhD thesis"
	else return Functions.change_case(c.fields["type"],"t") end
end

function std_styles.formatters:tr_number(c)
	local r = c.fields["type"]
	if r == nil then r = "Technical Report" end
	if c.fields["number"] == nil then r = Functions.change_case(r,"t")
	else r = r .. tie_or_space(c.fields["number"]) end
	return r
end

function std_styles.formatters:date_if_address(c)
	if c.fields["address"] ~= nil then return self:date(c) end
end

function std_styles.formatters:date_if_not_address(c)
	if c.fields["address"] == nil then return self:date(c) end
end

std_styles.crossref = CrossReference.new()
std_styles.crossref.templates = {}
std_styles.crossref.templates["article"] = "[$<author>:$<title>:[<In |$<key|journal_crossref>|> \\cite{$<crossref>}:$<pages>]:$<note>]"
std_styles.crossref.templates["book"] = "[$<author|editor>:$<btitle>:[$<book_crossref>  \\cite{$<crossref>}:$<edition>:$<date>]:$<note>]"
std_styles.crossref.templates["inbook"] = "[$<author|editor>:[$<btitle>:$<chapter_pages>]:[$<book_crossref>  \\cite{$<crossref>}:$<edition>:$<date>]:$<note>]"
std_styles.crossref.templates["incollection"] = "[$<author>:$<title>:[$<incollection_crossref> \\cite{$<crossref>}:$<chapter_pages>]:$<note>]"
std_styles.crossref.templates["inproceedings"] = "[$<author>:$<title>:[$<incollection_crossref> \\cite{$<crossref>}:$<chapter_pages>]:$<note>]"
std_styles.crossref.templates["conference"] = std_styles.crossref.templates["inproceedings"]

std_styles.crossref.formatters = {}
function std_styles.formatters:crossref(c)
	return c.fields["crossref"]:lower()
end

function std_styles.formatters:journal_crossref(c)
	if c.fields["journal"] == nil then return nil
	else return "{\\em " .. c.fields["journal"] .. "\\/}" end
end

function std_styles.formatters:book_crossref(c)
	r = ""
	if c.fields["volume"] == nil then r = "In "
	else r = "Volume" .. tie_or_space(c.fields["volume"]) .. " of " end
	if c.fields["editor"] ~= nil and c.fields["editor"] == c.fields["author"] then
		r = r .. self:editor_crossref(c)
	elseif c.fields["key"] ~= nil then r = r .. c.fields["key"]
	elseif c.fields["series"] ~= nil then r = r .. "{\\em " .. c.fields["series"] .. "\\/}"
	end
	return r
end

function std_styles.formatters:editor_crossref(c)
	local r = ""
	local a = Functions.split_names(c.fields["editor"])
	r = r .. Functions.format_name(a[1],"{vv~}{ll}")
	if (#a == 2 and a[2] == "others") or (#a > 2) then r = r .. " et~al."
	else r = r .. " and " .. Functions.format_name(a[2],"{vv~}{ll}") end
	return r
end

function std_styles.formatters:incollection_crossref(c)
	local r = ""
	if c.fields["editor"] ~= nil and c.fields["editor"] ~= c.fields["author"] then
		return "In " .. self:editor_crossref(c)
	elseif c.fields["key"] ~= nil then return "In " .. c.fields["key"]
	elseif c.fields["booktitle"] ~= nil then return "In {\\em " .. c.fields["booktitle"] .. "\\/}"
	end
	return nil
end

return std_styles


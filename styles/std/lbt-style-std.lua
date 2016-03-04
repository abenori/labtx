require "lbt-core"
require "lbt-funcs"
require "lbt-crossref"

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

-- generate label
local makelabelfuncs = {}
makelabelfuncs["author"] = function(names)
	local a = LBibTeX.split_names(names)
	local s = ""
	if #a > 4 then s = "{\\etalchar{+}}" end
	local n = #a
	for i = 1,n - 5 do table.remove(a) end
	s = LBibTeX.make_name_list(a,"{v{}}{l{}}",{""},"{\\etalchar{+}}") .. s
	if #a > 1 then return s
	else
		if LBibTeX.text_length(s) > 1 then return s
		else return LBibTeX.text_prefix(LBibTeX.format_name(names,"{ll}"),3) end
	end
end

makelabelfuncs["editor"] = makelabelfuncs["author"]
makelabelfuncs["organization"] = function(s) return LBibTeX.text_prefix(s:gsub("^The",""),3) end
makelabelfuncs["key"] = function(s) return LBibTeX.text_prefix(s,3) end

local function get_label(c,fa)
	for i = 1,#fa do
		if c.fields[(fa[i])] ~= nil then return makelabelfuncs[fa[i]](c.fields[(fa[i])]) end
	end
	return c.key:sub(1,4)
end

local function make_label_head(c)
	if c.type == "book" or c.type == "inbook" then
		return get_label(c,{"author","editor","key"})
	elseif c.type == "proceedings" then
		return get_label(c,{"editor","key","organization"})
	elseif c.type == "manual" then
		return get_label(c,{"author","key","organization"})
	else
		return get_label(c,{"author","key"})
	end
end

function std_styles.make_label(c)
	local year
	if c.fields["year"] == nil then year = ""
	else year = c.fields["year"]:gsub("^[a-zA-Z~ ]","") end
	return make_label_head(c) .. year:sub(-2,-1)
end

local function firstnonnull(c,a)
	for i = 1,#a do
		if c.fields[a[i]] ~= nil then
			if a[i] == "organization" then
				return c.fields[a[i]]:gsub("^The","")
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
	if not equal(a.fields["year"],b.fields["year"]) then return lessthan(a.fields["year"],b.fields["year"]) end
	if not equal(a.sort_title_key,b.sort_title_key) then return lessthan(a.sort_title_key,b.sort_title_key) end
end

std_styles.sort_formatter = {}

function std_styles.sort_formatter.name(c)
	if c.type == "book" or c.type == "inbook" then
		x = firstnonnull(c,{"author","editor"})
	elseif c.type == "proceedings" then
		x = firstnonnull(c,{"editor","organization"})
	elseif c.type == "manual" then
		x = firstnonnull(c,{"author","organization"})
	else
		x = firstnonnull(c,{"author"})
	end
	if x~= nil then return LBibTeX.remove_TeX_cs(LBibTeX.make_name_list(LBibTeX.split_names(x),"{vv{ } }{ll{ }}{  ff{ }}{  jj{ }}",{"   "},"et al"))
	else return nil end
end

function std_styles.sort_formatter.title(c)
	title = c.fields["title"]
	if title ~= nil then
		if title:sub(1,4) == "The " then title = title:sub(5)
		elseif title:sub(1,3) == "An " then title = title:sub(4)
		elseif title:sub(1,2) == "A " then  title = title:sub(3)
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
	if equals == nil then equals = function(a,b) return a:lower() == b:lower() end end
	if lessthan == nil then lessthan = function(a,b) return a:lower() < b:lower() end end
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
			if formatter[array[i]] == nil then formatter[array[i]] = formatter[array[i]] end
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
	
	LBibTeX.stable_sort(cites,sortfunc)
	return cites
end

std_styles.Template = LBibTeX.Template.new()

std_styles.Template.blockseparator[1] = ".\n\\newblock "
std_styles.Template.blockseparator[2] = ", "
std_styles.Template.blocklast[1] = "."
std_styles.Template.blocklast[2] = ". "

std_styles.Template.Templates = {}
std_styles.Template.Templates["article"] = "[$<author>:$<title>:[$<journal>:$<volume_number_pages>:$<date>]:$<note>]"
std_styles.Template.Templates["book"] = "[$<author|editor>:[$<btitle>:$<book_volume>]:[<Number|$<number_if_not_volume>| in >$<series_if_not_volume>][$<publisher>:$<address>:$<edition>:$<date>]:$<note>]"
std_styles.Template.Templates["booklet"] = "[$<author>:$<title>:[$<howpublished>:$<address>:$<date>]:$<note>]"
std_styles.Template.Templates["inbook"] = "[$<author|editor>:[$<btitle>:$<book_volume>:$<chapter_pages>]:[<Number|$<number_if_not_volume>| in >$<series_if_not_volume>][$<publisher>:$<address>:$<edition>:$<date>]:$<note>]"
std_styles.Template.Templates["incollection"] = "[$<author>:$<title>:[In <|$<editor>|, ><{\\em |$<booktitle>|}>:$<book_volume>:<number|$<number_if_not_volume>| in >$<series_if_not_volume>:$<chapter_pages>][$<publisher>:$<address>:$<edition>:$<date>]:$<note>]"
std_styles.Template.Templates["inproceedings"] = "[$<author>:$<title>:[In <|$<editor>|, ><{\\em |$<booktitle>|}>:$<book_volume>:<number|$<number_if_not_volume>| in >$<series_if_not_volume>:$<pages>:$<address>:$<date_if_address>:@S<. >$<organization_if_editor_publisher>:$<date_if_not_address>]:$<note>]"
std_styles.Template.Templates["conference"] = std_styles.Template.Templates["incollection"]
std_styles.Template.Templates["manual"] = "[[$<author|organization_address>]:$<btitle>:[$<organization>:$<address>:$<edition>:$<date>]:$<note>]"
std_styles.Template.Templates["mastersthesis"] = "[$<author>:$<title>:[$<master_thesis_type>:$<school>:$<address>:$<date>]:$<note>]"
std_styles.Template.Templates["misc"] = "[$<author>:$<title>:[$<howpublished>:$<date>]:$<note>]"
std_styles.Template.Templates["phdthesis"] = "[$<author>:$<btitle>:[$<phd_thesis_type>:$<school>:$<address>:$<date>]:$<note>]"
std_styles.Template.Templates["proceedings"] = "[$<editor|organization>:[$<btitle>:$<book_volume>:<number|$<number_if_not_volume>| in >$<series_if_not_volume>:$<address>:$<date_if_address>:@S<. >$<organization_if_editor_publisher>:$<date_if_not_address>]:$<note>]"
std_styles.Template.Templates["techreport"] = "[$<author>:$<title>:[$<tr_number>:$<institution>:$<address>:$<date>]:$<note>]"
std_styles.Template.Templates["unpublished"] = "[$<author>:$<title>:[$<note>:$<date>]]"
std_styles.Template.Templates[""] = std_styles.Template.Templates["misc"]

std_styles.Template.Formatters = {}
std_styles.Template.Formatters.date = "<<|$<month>| >|$<year>|>"

function std_styles.Template.Formatters:nameformat(c) return "{ff~}{vv~}{ll}{, jj}" end

function std_styles.Template.Formatters:format_names(names)
	local a = LBibTeX.split_names(names)
	if #a <= 2 then return LBibTeX.make_name_list(a,self:nameformat(c),{", "," and "},", et~al.")
	else return LBibTeX.make_name_list(a,self:nameformat(c),{", ",", and "},", et~al.") end
end

function std_styles.Template.Formatters:author(c)
	if c.fields["author"] == nil then return nil
	else return self:format_names(c.fields["author"]) end
end

function std_styles.Template.Formatters:volume_number_pages(c)
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

function std_styles.Template.Formatters:editor(c)
	if c.fields["editor"] == nil then return nil end
	local a = LBibTeX.split_names(c.fields["editor"])
	local r = self:format_names(c.fields["editor"]) .. ", editor"
	if #a > 1 then r = r .. "s" end
	return r
end

function std_styles.Template.Formatters:title(c)
	if c.fields["title"] == nil then return nil
	else return LBibTeX.change_case(c.fields["title"],"t") end
end

function std_styles.Template.Formatters:btitle(c)
	if c.fields["title"] == nil then return nil
	else return "{\\em " .. c.fields["title"] .. "}" end
end

function std_styles.Template.Formatters:journal(c)
	if c.fields["journal"] == nil then return nil
	else return "{\\em " .. c.fields["journal"] .. "}" end
end

local function tie_or_space(x)
	if x:len() < 3 then return "~" .. x
	else return " " .. x end
end

function std_styles.Template.Formatters:edition(c)
	if c.fields["edition"] == nil then return nil
	else return LBibTeX.change_case(c.fields["edition"],"l") .. " edition" end
end

function std_styles.Template.Formatters:organization_if_editor_publisher(c)
	local r = nil
	if c.fields["editor"] ~= nil then r = c.fields["organization"] end
	if r == nil then r = "" end
	if c.fields["publisher"] ~= nil then
		if r ~= "" then r = r .. ", " end
		r = r .. c.fields["publisher"]
	end
	return r
end

function std_styles.Template.Formatters:pages(c)
	local p = c.fields["pages"]
	if p ~= nil then
		if p:find("[-,+]") == nil then return "page" .. tie_or_space(p)
		else return "pages" .. tie_or_space(p:gsub("([^-])-([^-])","%1--%2")) end
	else return nil end
end

function std_styles.Template.Formatters:book_volume(c)
	if c.fields["volume"] == nil then return nil end
	local r = "volume" .. tie_or_space(c.fields["volume"])
	if c.fields["series"] ~= nil then r = r .. " of {\\em " .. c.fields["series"] .. "}" end
	return r
end

function std_styles.Template.Formatters:number_if_not_volume(c)
	if c.fields["volume"] == nil and c.fields["number"] ~= nil then return tie_or_space(c.fields["number"]) end
end

function std_styles.Template.Formatters:series_if_not_volume(c)
	if c.fields["volume"] == nil and c.fields["series"] ~= nil then return c.fields["series"] end
end

function std_styles.Template.Formatters:chapter_pages(c)
	if c.fields["chapter"] == nil then return self:pages(c) end
	local r = ""
	if c.fields["type"] == nil then r = "chapter"
	else r = LBibTeX.change_case(c.fields["type"],"l") end
	r = r .. tie_or_space(c.fields["chapter"])
	if c.fields["pages"] ~= nil then r = r .. ", " .. self:pages(c) end
	return r
end

function std_styles.Template.Formatters:proceedings_organization_publisher(c)
	if c.fields["editor"] == nil then return c.fields["publisher"]
	else return c.fields["organization"] end
end

function std_styles.Template.Formatters:master_thesis_type(c)
	if c.fields["type"] == nil then return "Master's thesis"
	else return LBibTeX.change_case(c.fields["type"],"t") end
end

function std_styles.Template.Formatters:phd_thesis_type(c)
	if c.fields["type"] == nil then return "PhD thesis"
	else return LBibTeX.change_case(c.fields["type"],"t") end
end

function std_styles.Template.Formatters:tr_number(c)
	local r = c.fields["type"]
	if r == nil then r = "Technical Report" end
	if c.fields["number"] == nil then r = LBibTeX.change_case(r,"t")
	else r = r .. tie_or_space(c.fields["number"]) end
	return r
end

function std_styles.Template.Formatters:date_if_address(c)
	if c.fields["address"] ~= nil then return self:date(c) end
end

function std_styles.Template.Formatters:date_if_not_address(c)
	if c.fields["address"] == nil then return self:date(c) end
end

std_styles.CrossReference = LBibTeX.CrossReference.new()
std_styles.CrossReference.Templates = {}
std_styles.CrossReference.Templates["article"] = "[$<author>:$<title>:[<In |$<key|journal_crossref>|> \\cite{$<crossref>}:$<pages>]:$<note>]"
std_styles.CrossReference.Templates["book"] = "[$<author|editor>:$<btitle>:[$<book_crossref>  \\cite{$<crossref>}:$<edition>:$<date>]:$<note>]"
std_styles.CrossReference.Templates["inbook"] = "[$<author|editor>:[$<btitle>:$<chapter_pages>]:[$<book_crossref>  \\cite{$<crossref>}:$<edition>:$<date>]:$<note>]"
std_styles.CrossReference.Templates["incollection"] = "[$<author>:$<title>:[$<incollection_crossref> \\cite{$<crossref>}:$<chapter_pages>]:$<note>]"
std_styles.CrossReference.Templates["inproceedings"] = "[$<author>:$<title>:[$<incollection_crossref> \\cite{$<crossref>}:$<chapter_pages>]:$<note>]"
std_styles.CrossReference.Templates["conference"] = std_styles.CrossReference.Templates["inproceedings"]

function std_styles.Template.Formatters:crossref(c)
	return c.fields["crossref"]:lower()
end

function std_styles.Template.Formatters:journal_crossref(c)
	if c.fields["journal"] == nil then return nil
	else return "{\\em " .. c.fields["journal"] .. "\\/}" end
end

function std_styles.Template.Formatters:book_crossref(c)
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

function std_styles.Template.Formatters:editor_crossref(c)
	local r = ""
	local a = LBibTeX.split_names(c.fields["editor"])
	r = r .. LBibTeX.format_name(a[1],"{vv~}{ll}")
	if (#a == 2 and a[2] == "others") or (#a > 2) then r = r .. " et~al."
	else r = r .. " and " .. LBibTeX.format_name(a[2],"{vv~}{ll}") end
	return r
end

function std_styles.Template.Formatters:incollection_crossref(c)
	local r = ""
	if c.fields["editor"] ~= nil and c.fields["editor"] == c.fields["author"] then
		return "In " .. self:editor_crossref(c)
	elseif c.fields["key"] ~= nil then return "In " .. c.fields["key"]
	elseif c.fields["booktitle"] ~= nil then return "In {\\em " .. c.fields["booktitle"] .. "\\/}"
	end
	return nil
end

return std_styles


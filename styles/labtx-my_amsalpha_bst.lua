ams_styles = require "labtx-style-ams"

--local labtxdebug = require "labtx-debug"
---labtxdebug.debugmode = true

--for i,c in ipairs(BibTeX.cites) do
--	BibTeX:outputline("%@" .. c.type .. "{" .. c.key .. ",")
--	for k,v in pairs(c.fields) do
--		if k ~= "myurl" and k ~= "pdf" then
--			BibTeX:outputline("%  " .. k .. " = " .. c:get_raw_field(k) .. ",")
--		end
--	end
--	BibTeX:outputline("%}")
--end
--BibTeX:outputline("")

function ams_styles.formatters:nameformat(c) return "{f.~}{vv~}{ll}{, jj}" end

BibTeX.macros = ams_styles.macros
BibTeX.crossref = ams_styles.crossref
BibTeX.blockseparator = ams_styles.blockseparator

BibTeX.templates = {}
BibTeX.templates["article"] = "[$<author>:$<title>:<|$<journal>|< \\textbf{|$<volume>|}>< (|$<year>|)>>:<no.~|$<number>|>:$<pages>:@S<>< (|$<language>|)>:$<note>:$<doi>]"
BibTeX.templates["book"] = "[$<author|editor>:$<title>:$<edition>:$<book_volume_series_number>:$<publisher>:$<address>:$<date>:@S<>< (|$<language>|)>:$<note>:$<doi>]"
BibTeX.templates["booklet"] = "[$<author>:$<title>:$<howpublished>:$<address>:$<date>:$<note>:$<doi>]"
BibTeX.templates["inbook"] = "[$<author|editor>:$<title>:$<edition>:$<book_volume_series_number>:$<chapter_pages>:$<publisher>:$<address>:$<date>:@S<>$< (|$<language>|)>:$<note>:$<doi>]"
BibTeX.templates["incollection"] = "[$<author>:$<title>:$<incollection_title_editor>:$<book_volume_series_number>:$<publisher>:$<address>:$<edition>:$<date>:$<note>:$<book_pages>:@S<>< (|$<language>|)>:$<doi>]"
BibTeX.templates["inproceedings"] = "[$<author>:$<title>:<|$<booktitle>|< (|$<address>|)>< |$<editor_nonauthor>|>>:$<book_volume_series_number>:$<organization>:$<publisher>:$<date>:$<note>:$<book_pages>:@S<>< (|$<language>|)>:$<doi>]"
BibTeX.templates["conference"] = BibTeX.templates["inproceedings"]
BibTeX.templates["manual"] = "[$<author|organization_address>:$<title>:$<manual_organization_address_aftertittle>:$<edition>:$<date>:$<note>:$<doi>]"
BibTeX.templates["mastersthesis"] = "[$<author>:$<title>:$<master_thesis_type>:$<school>:$<address>:$<date>:$<note>:$<book_pages>:$<doi>]"
BibTeX.templates["misc"] = "[$<author>:$<title>:$<howpublished>:$<date>:$<note>:$<book_pages>:$<doi>]"
BibTeX.templates["phdthesis"] = "[$<author>:$<title>:$<phd_thesis_type>:$<school>:$<address>:$<date>:$<note>:$<book_pages>:$<doi>]"
BibTeX.templates["proceedings"] = "[$<editor|organization>:$<title>:$<book_volume_series_number>:$<address>:$<proceedings_organization>:$<publisher>:$<date>:$<note>:$<doi>]"
BibTeX.templates["techreport"] = "[$<author>:$<title>:$<tech_rep_number>:$<institution>:$<address>:$<date>:$<note>:$<doi>]"
BibTeX.templates["unpublished"] = "[$<author>:$<title>:$<note>:$<date>:$<doi>]"
BibTeX.templates[""] = BibTeX.templates["misc"]

BibTeX.crossref.templates = {}
BibTeX.crossref.templates["article"] = "[$<author>:$<title>:<in |$<key|journal>|> \\cite{$<crossref>}:$<pages>:@S<>< (|$<language>|)>:$<note>:$<doi>]"
BibTeX.crossref.templates["book"] = "[$<author|editor>:$<title>:$<edition>:$<book_crossref> \\cite{$<crossref>}:$<date>:@S<>< (|$<language>|)>:$<note>:$<doi>]"
BibTeX.crossref.templates["inbook"] = "[$<author|editor>:$<title>:$<edition>:$<chapter_pages>:$<book_crossref> \\cite{$<crossref>}:$<date>:@S<>$< (|$<language>|)>:$<note>:$<doi>]"
BibTeX.crossref.templates["incollection"] = "[$<author>:$<title>:$<incollection_crossref> \\cite{$<crossref>}:$<note>:$<book_pages>:@S<>< (|$<language>|)>:$<doi>]"
BibTeX.crossref.templates["inproceedings"] = "[$<author>:$<title>:$<incollection_crossref> \\cite{$<crossref>}:$<note>:$<book_pages>:@S<>< (|$<language>|)>:$<doi>]"
BibTeX.crossref.templates["conference"] = BibTeX.crossref.templates["inproceedings"]

BibTeX.formatters = ams_styles.formatters
function BibTeX.formatters:doi(c)
	if c.fields["pages"] == nil then
		if c.fields["doi"] ~= nil then return "DOI:" .. c.fields["doi"] end
	end
	return nil
end
BibTeX.sorting.targets = {"label","year","name","title"}

BibTeX:outputthebibliography()


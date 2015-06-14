require "lbt-funcs"
require "lbt-template"
local icu = require "lbt-string"
local U = icu.ustring
require "lbt-style-ams"

for v,k in pairs(LBibTeX.Styles.ams.macros) do
	BibTeX.macros[v] = k
end

BibTeX:read()
LBibTeX.Styles.ams.CrossReference:modify_citations(BibTeX)
BibTeX:output_citation_check(LBibTeX.LBibTeX.citation_check(BibTeX.cites))

-- label
for i = 1,#BibTeX.cites do
	BibTeX.cites[i].label = LBibTeX.Styles.ams.make_label(BibTeX.cites[i])
end

-- sort
BibTeX.cites = LBibTeX.Styles.ams.sort(BibTeX.cites)

-- 同じのが続いたら，末尾にabcとつける．
local lastchar = string.byte("a") - 1
local changed = false
local lastname = nil
for i = 1,#BibTeX.cites - 1 do
	if BibTeX.cites[i].label == BibTeX.cites[i + 1].label then
		lastchar = lastchar + 1
		BibTeX.cites[i].label = BibTeX.cites[i].label .. U(string.char(lastchar))
		changed = true
	else
		if changed then
			lastchar = lastchar + 1
			BibTeX.cites[i].label = BibTeX.cites[i].label .. U(string.char(lastchar))
		end
		lastchar = string.byte("a") - 1
		changed = false
	end
	if BibTeX.cites[i].fields[U"author"] == lastname and lastname ~= nil and lastname ~= U"" then
		BibTeX.cites[i].fields[U"author"] = U"\\bysame "
	else
		lastname = BibTeX.cites[i].fields[U"author"]
	end
end

LBibTeX.Template.blockseparator = LBibTeX.Styles.ams.blockseparator
LBibTeX.Template.blocklast = LBibTeX.Styles.ams.blocklast

BibTeX:outputline(U"\\newcommand{\\etalchar}[1]{$^{#1}$}")
BibTeX:outputline(BibTeX.preamble)
BibTeX:outputline(U"\\begin{thebibliography}{" .. BibTeX:get_longest_label() .. U"}")
local f1 = LBibTeX.Template.make(LBibTeX.Styles.ams.Templates,LBibTeX.Styles.ams.Formatter)
local f2 = LBibTeX.Template.make(LBibTeX.Styles.ams.CrossReference.Templates,LBibTeX.Styles.ams.Formatter)
local f = LBibTeX.Styles.ams.CrossReference:make_formatter(f1,f2)
BibTeX:outputcites(f)
BibTeX:outputline(U"\\end{thebibliography}")


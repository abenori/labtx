require "lbt-funcs"
require "lbt-template"
require "mod-std"

for v,k in pairs(LBibTeX.Styles.std.macros) do
	BibTeX.macros[v] = k
end

BibTeX:read()
LBibTeX.Styles.std.CrossReference:modify_citations(BibTeX)
BibTeX:output_citation_check(LBibTeX.LBibTeX.citation_check(BibTeX.cites))

-- label
for i = 1,#BibTeX.cites do
	BibTeX.cites[i].label = LBibTeX.Styles.std.make_label(BibTeX.cites[i])
end

-- sort
BibTeX.cites = LBibTeX.Styles.std.sort(BibTeX.cites)

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
end

LBibTeX.Template.blockseparator = LBibTeX.Styles.std.blockseparator
LBibTeX.Template.blocklast = LBibTeX.Styles.std.blocklast

BibTeX:outputline(BibTeX.preamble)
BibTeX:outputline(U"\\begin{thebibliography}{" .. BibTeX:get_longest_label() .. U"}")
local f1 = LBibTeX.Template.make(LBibTeX.Styles.std.Templates,LBibTeX.Styles.std.Formatter)
local f2 = LBibTeX.Template.make(LBibTeX.Styles.std.CrossReference.Templates,LBibTeX.Styles.std.Formatter)
local f = LBibTeX.Styles.std.CrossReference:make_formatter(f1,f2)
BibTeX:outputcites(f)
BibTeX:outputline(U"\\end{thebibliography}")


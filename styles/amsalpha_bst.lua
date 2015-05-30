require "lbt-funcs"
require "lbt-template"
local U = require "icu.ustring"
require "mod-amsalpha"

for v,k in pairs(LBibTeX.Styles.amsalpha.macros) do
	BibTeX.macros[v] = k
end

BibTeX:read()

-- label
for i = 1,#BibTeX.cites do
	BibTeX.cites[i].label = LBibTeX.Styles.amsalpha.make_label(BibTeX.cites[i])
end

-- sort
BibTeX.cites = LBibTeX.Styles.amsalpha.sort(BibTeX.cites)

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

LBibTeX.Template.blockseparator = {}
for i = 1,#LBibTeX.Styles.amsalpha.blockseparator do
	LBibTeX.Template.blockseparator[i] = LBibTeX.Styles.amsalpha.blockseparator[i]
end

LBibTeX.Template.blocklast = {}
for i = 1,#LBibTeX.Styles.amsalpha.blocklast do
	LBibTeX.Template.blocklast[i] = LBibTeX.Styles.amsalpha.blocklast[i]
end

BibTeX:outputline(U"\\newcommand{\\etalchar}[1]{$^{#1}$}")
BibTeX:outputline(BibTeX.preamble)
BibTeX:outputline(U"\\begin{thebibliography}{" .. BibTeX:get_longest_label() .. U"}")
f = LBibTeX.Template.make(LBibTeX.Styles.amsalpha.Templates,LBibTeX.Styles.amsalpha.Formatter)
if f == nil then BibTeX:error(LBibTeX.Template.LastMsg) end
BibTeX:outputcites(f)
BibTeX:outputline(U"\\end{thebibliography}")


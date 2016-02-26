require "lbt-funcs"
require "lbt-template"
local ams_style = require "lbt-style-ams"

for v,k in pairs(ams_style.macros) do
	BibTeX.macros[v] = k
end

BibTeX.cites = ams_style.CrossReference:modify_citations(BibTeX.cites,BibTeX)
BibTeX:output_citation_check(LBibTeX.citation_check(BibTeX.cites))

-- label
for i = 1,#BibTeX.cites do
	BibTeX.cites[i].label = ams_style.make_label(BibTeX.cites[i])
end

-- sort
BibTeX.cites = ams_style.sort(BibTeX.cites)

-- 同じのが続いたら，末尾にabcとつける．
local lastchar = string.byte("a") - 1
local changed = false
local lastname = nil
for i = 1,#BibTeX.cites - 1 do
	if BibTeX.cites[i].label == BibTeX.cites[i + 1].label then
		lastchar = lastchar + 1
		BibTeX.cites[i].label = BibTeX.cites[i].label .. string.char(lastchar)
		changed = true
	else
		if changed then
			lastchar = lastchar + 1
			BibTeX.cites[i].label = BibTeX.cites[i].label .. string.char(lastchar)
		end
		lastchar = string.byte("a") - 1
		changed = false
	end
	if BibTeX.cites[i].fields["author"] == lastname and lastname ~= nil and lastname ~= "" then
		BibTeX.cites[i].fields["author"] = "\\bysame "
	else
		lastname = BibTeX.cites[i].fields["author"]
	end
end


BibTeX:outputline("\\newcommand{\\etalchar}[1]{$^{#1}$}")
BibTeX:outputline(BibTeX.preamble)
BibTeX:outputline("\\begin{thebibliography}{" .. BibTeX:get_longest_label() .. "}")
local f1 = ams_style.Template:make(ams_style.Template.Templates,ams_style.Template.Formatter)
local f2 = ams_style.Template:make(ams_style.CrossReference.Templates,ams_style.Template.Formatter)
local f = ams_style.CrossReference:make_formatter(f1,f2)
BibTeX:outputcites(f)
BibTeX:outputline("\\end{thebibliography}")


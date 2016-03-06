require "lbt-funcs"
require "lbt-template"
std_styles = require "lbt-style-std"

for v,k in pairs(std_styles.macros) do
	BibTeX.macros[v] = k
end

BibTeX.cites = std_styles.CrossReference:modify_citations(BibTeX.cites,BibTeX)
BibTeX:output_citation_check(LBibTeX.citation_check(BibTeX.cites))

-- label
for i = 1,#BibTeX.cites do
	BibTeX.cites[i].label = std_styles.make_label(BibTeX.cites[i])
end

-- sort
BibTeX.cites = std_styles.sort(BibTeX.cites)

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
end

local f1 = std_styles.Template:make(std_styles.Template.Templates,std_styles.Template.Formatters)
local f2 = std_styles.Template:make(std_styles.CrossReference.Templates,std_styles.Template.Formatters)
local f = std_styles.CrossReference:make_formatter(f1,f2)
BibTeX:outputthebibliography(f)

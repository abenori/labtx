require "lbt-funcs"
require "lbt-template"
std_styles = require "lbt-style-std"
local icu = require "lbt-string"
local U = icu.ustring

for v,k in pairs(std_styles.macros) do
	BibTeX.macros[v] = k
end

BibTeX:read()
std_styles.CrossReference:modify_citations(BibTeX)
BibTeX:output_citation_check(LBibTeX.LBibTeX.citation_check(BibTeX.cites))

LBibTeX.Template.blockseparator = std_styles.blockseparator
LBibTeX.Template.blocklast = std_styles.blocklast

local f1 = LBibTeX.Template.make(std_styles.Templates,std_styles.Formatter)
local f2 = LBibTeX.Template.make(std_styles.CrossReference.Templates,std_styles.Formatter)
local f = std_styles.CrossReference:make_formatter(f1,f2)
BibTeX:outputthebibliography(f)


require "lbt-funcs"
require "lbt-template"
require "mod-std"

for v,k in pairs(LBibTeX.Styles.std.macros) do
	BibTeX.macros[v] = k
end

BibTeX:read()
LBibTeX.Styles.std.CrossReference:modify_citations(BibTeX)
BibTeX:output_citation_check(LBibTeX.LBibTeX.citation_check(BibTeX.cites))

-- sort
BibTeX.cites = LBibTeX.Styles.std.sort(BibTeX.cites)

LBibTeX.Template.blockseparator = LBibTeX.Styles.std.blockseparator
LBibTeX.Template.blocklast = LBibTeX.Styles.std.blocklast

BibTeX:outputline(BibTeX.preamble)
BibTeX:outputline(U"\\begin{thebibliography}{" .. U(tostring(#BibTeX.cites)) .. U"}")
local f1 = LBibTeX.Template.make(LBibTeX.Styles.std.Templates,LBibTeX.Styles.std.Formatter)
local f2 = LBibTeX.Template.make(LBibTeX.Styles.std.CrossReference.Templates,LBibTeX.Styles.std.Formatter)
local f = LBibTeX.Styles.std.CrossReference:make_formatter(f1,f2)
BibTeX:outputcites(f)
BibTeX:outputline(U"\\end{thebibliography}")


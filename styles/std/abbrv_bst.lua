require "lbt-funcs"
require "lbt-template"
require "mod-std"

BibTeX.macros[U"jan"] = U"Jan."
BibTeX.macros[U"feb"] = U"Feb."
BibTeX.macros[U"mar"] = U"Mar."
BibTeX.macros[U"apr"] = U"Apr."
BibTeX.macros[U"may"] = U"May"
BibTeX.macros[U"jun"] = U"June"
BibTeX.macros[U"jul"] = U"July"
BibTeX.macros[U"aug"] = U"Aug."
BibTeX.macros[U"sep"] = U"Sept."
BibTeX.macros[U"oct"] = U"Oct."
BibTeX.macros[U"nov"] = U"Nov."
BibTeX.macros[U"dec"] = U"Dec."
BibTeX.macros[U"acmcs"] = U"ACM Comput. Surv."
BibTeX.macros[U"acta"] = U"Acta Inf."
BibTeX.macros[U"cacm"] = U"Commun. ACM"
BibTeX.macros[U"ibmjrd"] = U"IBM J. Res. Dev."
BibTeX.macros[U"ibmsj"] = U"IBM Syst.~J."
BibTeX.macros[U"ieeese"] = U"IEEE Trans. Softw. Eng."
BibTeX.macros[U"ieeetc"] = U"IEEE Trans. Comput."
BibTeX.macros[U"ieeetcad"] = U"IEEE Trans. Comput.-Aided Design Integrated Circuits"
BibTeX.macros[U"ipl"] = U"Inf. Process. Lett."
BibTeX.macros[U"jacm"] = U"J.~ACM"
BibTeX.macros[U"jcss"] = U"J.~Comput. Syst. Sci."
BibTeX.macros[U"scp"] = U"Sci. Comput. Programming"
BibTeX.macros[U"sicomp"] = U"SIAM J. Comput."
BibTeX.macros[U"tocs"] = U"ACM Trans. Comput. Syst."
BibTeX.macros[U"tods"] = U"ACM Trans. Database Syst."
BibTeX.macros[U"tog"] = U"ACM Trans. Gr."
BibTeX.macros[U"toms"] = U"ACM Trans. Math. Softw."
BibTeX.macros[U"toois"] = U"ACM Trans. Office Inf. Syst."
BibTeX.macros[U"toplas"] = U"ACM Trans. Prog. Lang. Syst."
BibTeX.macros[U"tcs"] = U"Theoretical Comput. Sci."


BibTeX:read()
LBibTeX.Styles.std.CrossReference:modify_citations(BibTeX)
BibTeX:output_citation_check(LBibTeX.LBibTeX.citation_check(BibTeX.cites))

LBibTeX.Template.blockseparator = LBibTeX.Styles.std.blockseparator
LBibTeX.Template.blocklast = LBibTeX.Styles.std.blocklast

local formatter = LBibTeX.Styles.std.Formatter
function formatter:nameformat(c) return "{f.~}{vv~}{ll}{, jj}" end

BibTeX:outputline(BibTeX.preamble)
BibTeX:outputline(U"\\begin{thebibliography}{" .. U(tostring(#BibTeX.cites)) .. U"}")
local f1 = LBibTeX.Template.make(LBibTeX.Styles.std.Templates,LBibTeX.Styles.std.Formatter)
local f2 = LBibTeX.Template.make(LBibTeX.Styles.std.CrossReference.Templates,LBibTeX.Styles.std.Formatter)
local f = LBibTeX.Styles.std.CrossReference:make_formatter(f1,f2)
BibTeX:outputcites(f)
BibTeX:outputline(U"\\end{thebibliography}")


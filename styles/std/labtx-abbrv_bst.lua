local std_styles = require "labtx-style-std"

BibTeX.macros["jan"] = "Jan."
BibTeX.macros["feb"] = "Feb."
BibTeX.macros["mar"] = "Mar."
BibTeX.macros["apr"] = "Apr."
BibTeX.macros["may"] = "May"
BibTeX.macros["jun"] = "June"
BibTeX.macros["jul"] = "July"
BibTeX.macros["aug"] = "Aug."
BibTeX.macros["sep"] = "Sept."
BibTeX.macros["oct"] = "Oct."
BibTeX.macros["nov"] = "Nov."
BibTeX.macros["dec"] = "Dec."
BibTeX.macros["acmcs"] = "ACM Comput. Surv."
BibTeX.macros["acta"] = "Acta Inf."
BibTeX.macros["cacm"] = "Commun. ACM"
BibTeX.macros["ibmjrd"] = "IBM J. Res. Dev."
BibTeX.macros["ibmsj"] = "IBM Syst.~J."
BibTeX.macros["ieeese"] = "IEEE Trans. Softw. Eng."
BibTeX.macros["ieeetc"] = "IEEE Trans. Comput."
BibTeX.macros["ieeetcad"] = "IEEE Trans. Comput.-Aided Design Integrated Circuits"
BibTeX.macros["ipl"] = "Inf. Process. Lett."
BibTeX.macros["jacm"] = "J.~ACM"
BibTeX.macros["jcss"] = "J.~Comput. Syst. Sci."
BibTeX.macros["scp"] = "Sci. Comput. Programming"
BibTeX.macros["sicomp"] = "SIAM J. Comput."
BibTeX.macros["tocs"] = "ACM Trans. Comput. Syst."
BibTeX.macros["tods"] = "ACM Trans. Database Syst."
BibTeX.macros["tog"] = "ACM Trans. Gr."
BibTeX.macros["toms"] = "ACM Trans. Math. Softw."
BibTeX.macros["toois"] = "ACM Trans. Office Inf. Syst."
BibTeX.macros["toplas"] = "ACM Trans. Prog. Lang. Syst."
BibTeX.macros["tcs"] = "Theoretical Comput. Sci."

function std_styles.formatters:nameformat(c) return "{f.~}{vv~}{ll}{, jj}" end

BibTeX.crossref = std_styles.crossref
BibTeX.blockseparator = std_styles.blockseparator
BibTeX.templates = std_styles.templates
BibTeX.formatters = std_styles.formatters
BibTeX.label.make = nil

BibTeX:outputthebibliography()

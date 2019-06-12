std_styles = require "labtx-style-std"

BibTeX.macros = std_styles.macros
BibTeX.crossref = std_styles.crossref
BibTeX.blockseparator = std_styles.blockseparator
BibTeX.templates = std_styles.templates
BibTeX.formatters = std_styles.formatters
BibTeX.label.make = nil

BibTeX.languages.ja = {}
BibTeX.languages.ja.templates = {}
BibTeX.languages.ja.templates["article"] = "[$<author>:$<title>:$<journal>:JA]"
BibTeX.languages.ja.crossref = {}
BibTeX.languages.ja.crossref.templates = {}
BibTeX.languages.ja.crossref.templates["article"] = "CROSSREF: JA"

BibTeX:outputthebibliography()


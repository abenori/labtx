local ams_styles = require "labtx-style-ams"

--local labtxdebug = require "labtx-debug"
--labtxdebug.debugmode = true

BibTeX.preamble = BibTeX.preamble .. ams_styles.preamble
BibTeX.macros = ams_styles.macros
BibTeX.crossref = ams_styles.crossref
BibTeX.blockseparator = ams_styles.blockseparator
BibTeX.templates = ams_styles.templates
BibTeX.formatters = ams_styles.formatters
BibTeX.modify_citations = ams_styles.modify_citations
BibTeX.sorting.targets = {"label","name","year","title"}

BibTeX:outputthebibliography()




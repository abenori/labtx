std_styles = require "labtx-style-std"

BibTeX.macros = std_styles.macros
BibTeX.crossref = std_styles.crossref
BibTeX.blockseparator = std_styles.blockseparator
BibTeX.templates = std_styles.templates
BibTeX.formatters = std_styles.formatters
BibTeX.label.make = nil

BibTeX:outputthebibliography()


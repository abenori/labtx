ams_styles = require "lbt-style-ams"

--(require "lbt-debug").debug = true

--for i,c in ipairs(BibTeX.cites) do
--	BibTeX:outputline("%@" .. c.type .. "{" .. c.key .. ",")
--	for k,v in pairs(c.fields) do
--		if k ~= "myurl" and k ~= "pdf" then
--			BibTeX:outputline("%  " .. k .. " = " .. c:get_raw_field(k) .. ",")
--		end
--	end
--	BibTeX:outputline("%}")
--end
--BibTeX:outputline("")

function ams_styles.formatters:mrnumfunc(c) return nil end
function ams_styles.formatters:nameformat(c) return "{f.~}{vv~}{ll}{, jj}" end

BibTeX.macros = ams_styles.macros
BibTeX.crossref = ams_styles.crossref
BibTeX.blockseparator = ams_styles.blockseparator
BibTeX.templates = ams_styles.templates
BibTeX.formatters = ams_styles.formatters
BibTeX.sorting.targets = {"label","name","year","title"}


BibTeX:outputthebibliography()


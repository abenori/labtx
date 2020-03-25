local bibitem = {}

function bibitem.new(ref,label)
	local obj = {ref = ref, label = label}
	return setmetatable(obj,{__index = bibitem, __tostring = bibitem.tostring})
end

function bibitem:toustring()
	local r = "\\bibitem"
	if self.label ~= nil then r = r .. "[" .. self.label .. "]" end
	return r .. "{" .. self.ref .. "}"
end

function bibitem:tostring()
	return tostring(self:toustring())
end


return bibitem

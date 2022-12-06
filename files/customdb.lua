json = require "json"
io = require "io"
Customdb = {}
-- Adding data to playlists
function Customdb:main(file)
	local f = io:open(file, "rb")
	if not f then
		 return {}
	end
	local jstring = f:read "*a" 
	local jdata = json.decode(jstring)
	f:close()

	return jdata

end
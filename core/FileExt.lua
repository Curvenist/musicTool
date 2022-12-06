FileExt = {
	db = "database.json",
	data = nil,
	path = "Interface/Addons/musicTool/files/",
	ext = ".mp3"
}
-- loading existing external files added in database.json
function FileExt:main()
	self.data = Customdb:main(self.db)
end

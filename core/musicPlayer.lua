musicPlayer = {
	List = {},
	Playlist = {},
	ExternalDB = {},
	delayer = {},
	repeater = false,
	autoLoadNextPlaylist = false,
	probTimeCycle = nil,

	songspec = {
		count = nil, -- track number
		mustimer = nil, -- setting a chronometer before delayer takes place
		currentsong = nil -- our track id / name
	},

	currentTime = {
		hours = nil,
		min = nil
	}
	
	
}

function musicPlayer:main()
	self.ExternalDB = Customdb:main("database.json")
	self.List = Customdb:main("playlist.json")

	local RawConfig = Customdb:main("config.json")
	self:setDelayer(RawConfig["delayer"])
	self:setRepeater(RawConfig["repeater"])
	self:setAutoLoadNextPlaylist(RawConfig["autoLoadNextPlaylist"])
	self:setprobTimeCycle(RawConfig["probTimeCycle"]["min"], RawConfig["probTimeCycle"]["max"])

end

function musicPlayer:execLoadDB(db) -- in case the player wants to control another playlist
	self.List = Customdb:main(db)
end

function musicPlayer:execPlaylistLoadout(playlist) -- playlist.json
	-- contains all music data
	-- List = {array of files}
	self.PlayList = self.List[playlist]

end

-- all setters parameters for playlists type
function musicPlayer:setDelayer(min, max) -- set a delayer between songs
	min = min or 0
	max = max or 0
	if max < min then
		max = min
	end
	
	self.delayer = {
		min = min,
		max = max
	}
end

function musicPlayer:setRepeater(boolean) -- set a repeater for songs - bypasses probTimeCycle
	self.repeater = boolean
end

function musicPlayer:setAutoLoadNextPlaylist(boolean) -- jump to next playlist in current self.List
	self.autoLoadNextPlaylist = boolean
end

-- in case we get datad / datan, we can set up a probability of playling day or night songs
-- for instance true / 0.8 means during the night time, we have a small chance of playing day music by 20%, 1 means, no day music at all for night and vice versa
function musicPlayer:setprobTimeCycle(boolean, prob) 
	if boolean then
		self.probTimeCycle = prob
	end
end

function musicPlayer:getProbTimeCycle()
	return self.probTimeCycle
end

function musicPlayer:getPlaylist(playlist)
	playlist = playlist or nil
	if playlist ~= nil then
		return self.PlayList[playlist]
	end
	return {}
end
-- string.find(k, "n")
-- 	
function musicPlayer:getDataSong(playlist) 
	local isCycling = self:roll(self:getProbTimeCycle(), 1) -- the probability of day cycling song playing

	for k, v in pairs(self:getPlaylist(playlist)) do
		if k == "data" then -- no day and night cycle
			return k
		elseif self:getProbTimeCycle() ~= nil then // we're going to check the prob playing the other track for this next one!
			if self:timeDayCheck() and string.match(k, "n$") ~= nil and isCycling then -- day lookging for night => if got day, and k is datan, and cycle is true : take this data instead
				return k
			elseif not self:timeDayCheck() and string.match(k, "d$") ~= nil and isCycling then -- reversed
				return k
			end
		else
			if self:timeDayCheck() and string.match(k, "d$") ~= nil then return k
			elseif not self:timeDayCheck() and string.match(k, "n$") ~= nil then return k 
			end
		end
	end
	
end

function musicPlayer:getSong(playlist, isNext, number)
	local data = self:getDataSong(playlist) -- loading the array of id / names
	if isNext and self.songspec["count"] >= #self:getPlaylist(playlist)[data] or not isNext and number < 1 then -- in case we have extra border array values, we set to 0 to avoid errors
		isNext = not isNext
		if isNext then number = 0
		else number = #self:getPlaylist(playlist)[data] - 1 end
	end
	if isNext then
		self.songspec["count"] = number + 1
	else
		self.songspec["count"] = number - 1
	end
	
	self.songspec["currentsong"] = self:getPlaylist(playlist)[data][self.songspec["count"]] -- our song is picked, we can play it
	
end


-- end all setters for playlist type of playing

function musicPlayer:roll(min, max)
	min = min or 0
	max = max or 0
	local rand = math.random(0, max)
	if rand < min then -- min% luck to get a number lower than the min given
		return true
	end
	return false
end



function musicPlayer:timeDayCheck()
	self.currentTime["hours"], self.currentTime["min"] = GetGameTime()
	if self.currentTime["hours"] >= 18 and self.currentTime["hours"] <= 6 then -- @todo careful for english time
		return false
	else
		return true
	end
end



-- our custom Player
function musicPlayer:PlayMusic(song)
	song = song or nil
	if song ~= nil then
		PlayMusic(song)
	end
end


function musicPlayer:Play(playlist, isNext, number)
	-- first, we need to know wich time we have for datad and datan in order to take whats wanted
	isNext = isNext or true
	if self.songspec["count"] == nil then
		self.songspec["count"] = 0
	end
	number = number or self.songspec["count"]
	self:timeDayCheck()

	if self.Playlist == nil then
		self:execPlaylistLoadout(playlist)
	end

	-- loading our song
	self:getSong(playlist, isNext, number)

	if self.repeater then
		self:PlayMusic(self.songspec["currentsong"])
	end
		if self.timer > chronometer then
		end
	end

end

function musicPlayer:reset()

end


function musicPlayer:UnloadPlaylist()
	self.List = {}
end
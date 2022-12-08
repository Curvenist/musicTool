musicPlayer = {
	List = {},
	Playlist = {},
	ExternalDB = {},

	delayer = {
		min = nil,
		max = nil
	},

	typeRepeater = nil, -- 0 = play playlist once  / 1 = repeat playlist / 2 = repeat same / 3 = jump to next playlist
	probTimeCycle = nil,
	timeline = nil,
	chronoDelayer = nil,
	start = false, -- just to know if a song has been started
	isRandom = false,

	currentSong = {
		count = nil, -- track number in playlist
		mustimer = nil, -- setting a timeline before delayer takes place
		track = nil -- our track id / name
	},

	currentTime = {
		hours = nil,
		min = nil
	},
	
	wait = nil
	
}

function musicPlayer:main()
	self.ExternalDB = Customdb:main("database.json")
	self.List = Customdb:main("playlist.json")

	local RawConfig = Customdb:main("config.json")
	self:setDelayer(RawConfig["delayer"])
	self:setTypeRepeater(RawConfig["typeRepeater"])
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

-- all setters / getters parameters for playlists type
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

function musicPlayer:getDelayer(param)
	if param ~= nil then
		return self.delayer[param]
	end
	return self.delayer
end

function musicPlayer:settimeline(value)
	self.timeline = value
end

function musicPlayer:gettimeline()
	return self.timeline
end

function musicPlayer:setchronodelayer(value)
	self.chronoDelayer = value
end

function musicPlayer:getChronoDelayer()
	return self.chronoDelayer
end


function musicPlayer:setTypeRepeater(number) -- set a typeRepeater for songs - bypasses probTimeCycle
	self.typeRepeater = number
end

function musicPlayer:getTypeRepeater()
	return self.typeRepeater
end

function musicPlayer:setIsRandom(boolean)
	self.isRandom = boolean
end

function musicPlayer:getIsRandom()
	return self.isRandom
end

function musicPlayer:setCurrentSong(param, value)
	self.currentSong[param] = value
end

function musicPlayer:getCurrentSong(param)
	if param ~= nil then
		return self.currentSong[param]
	end
	return self.currentSong
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

function musicPlayer:getDataSong(playlist) 
	local isCycling = self:roll(self:getProbTimeCycle(), 1) -- the probability of day cycling song playing

	for k, v in pairs(self:getPlaylist(playlist)) do
		if k == "data" then -- no day and night cycle
			return k
		elseif self:getProbTimeCycle() ~= nil then -- we're going to check the prob playing the other track for this next one!
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

function musicPlayer:getSong(playlist, isNext, number, isRandom)
	local data = self:getDataSong(playlist) -- loading the array of id / names

	-- full random
	if isRandom then
		self:setCurrentSong("count", math.random(0, #self:getPlaylist(playlist)[data][1]))

		self:setCurrentSong("track", self:getPlaylist(playlist)[data][1][self:getCurrentSong("count")])
		self:setCurrentSong("mustimer", #self:getPlaylist(playlist)[data][2])
		return
	end

	-- not random, but if data is cycled, next song can be selected in the other data => cf getDataSong
	if isNext and self:getCurrentSong("count") >= #self:getPlaylist(playlist)[data] then -- in case we have extra border array values, we set to 0 to avoid errors
		number = 0	
	elseif not isNext and number < 1 then
		number = #self:getPlaylist(playlist)[data] + 1
	end

	if isNext then
		self:setCurrentSong("count", number + 1)
	else
		self:setCurrentSong("count", number - 1)
	end
	
	self:setCurrentSong("track", self:getPlaylist(playlist)[data][1][self:getCurrentSong("count")]) -- our song is picked, we can play it
	self:setCurrentSong("mustimer", #self:getPlaylist(playlist)[data][2])
	return
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


-- our custom Player direct commands
function musicPlayer:PlayMusic(song)
	song = song or nil
	if song ~= nil then
		PlayMusic(song)
		self.start = true
	end
	return
end

function musicPlayer:StopMusic()
	StopMusic()
	return
end


-- our music player main functionnality
function musicPlayer:Play(playlist, isNext, number, isRandom)
	-- first, we need to know wich time we have for datad and datan in order to take whats wanted
	isNext = isNext or true
	isRandom = isRandom or self:getIsRandom()

	if self:getCurrentSong("count") == nil then
		self:setCurrentSong("count", 0)
	end
	number = number or self:getCurrentSong("count")
	self:timeDayCheck()

	if self:getPlaylist(playlist) == nil then
		self:execPlaylistLoadout(playlist)
	end

	-- loading our song
	self:getSong(playlist, isNext, number, isRandom)

	-- Our player timing function
	self.wait = CreateFrame("Frame")
	
	self.wait:SetScript("OnUpdate", function()
		-- if has repeater, we just load music and it plays without anymore actions
		if self:getTypeRepeater() == 2 and not self.start then
			self:setchronodelayer(math.random(self:getDelayer("min"), self:getDelayer("max")))
			self:settimeline(GetTime() + self:getCurrentSong("mustimer"))
			self:PlayMusic(self:getCurrentSong("track")) -- just once, music automatically plays loops :)
		else
			if not self.start then -- starting music

				self:setchronodelayer(math.random(self:getDelayer("min"), self:getDelayer("max")))
				self:settimeline(GetTime() + self:getCurrentSong("mustimer"))
				self:PlayMusic(self:getCurrentSong("track"))

			elseif self.start and self:gettimeline() < GetTime() then -- timeline
				
				-- stopSong!
				self:StopMusic()
				SetCVar("Sound_EnableMusic", 0)
				self.start = false

			elseif self.start and self:gettimeline() + self:getChronoDelayer() < GetTime()  then -- adding the delayer in timeline

			end	

		
		end
	end)
	self.wait:UnregisterEvent("OnUpdate")

end

function musicPlayer:reset()
	
end


function musicPlayer:UnloadPlaylist()
	self.List = {}
end

if self:getTypeRepeater() ~= 0 then -- if not repeat self, start a new song
	SetCVar("Sound_EnableMusic", 1)
	self:getSong(playlist, true, number, isRandom)
end
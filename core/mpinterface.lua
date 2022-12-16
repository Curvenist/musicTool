mpInterface = mpentity


function mpInterface:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function mpInterface:main()
	self.ExternalDB = Customdb:main("database.json")
	self.List = Customdb:main("playlist.json")

	local RawConfig = Customdb:main("config.json")
	self:setDelayer(RawConfig["delayer"])
	self:setTypeRepeater(RawConfig["typeRepeater"])
	self:setprobTimeCycle(RawConfig["probTimeCycle"]["min"], RawConfig["probTimeCycle"]["max"])
	self:settimeline(GetTime())
	self:setIsRandom(RawConfig["isRandom"])

	self:initPlayerFrame() --initializing our player once, we will both register and UnregisterEvent events furthermore
end

function mpInterface:initPlayerFrame()
	self.player = CreateFrame("Frame")
end


function mpInterface:roll(min, max)
	min = min or 0
	max = max or 0
	local rand = math.random(0, max)
	if rand < min then -- min% luck to get a number lower than the min given
		return true
	end
	return false
end

function mpInterface:getDataSong() 
	local isCycling = self:roll(self:getProbTimeCycle(), 1) -- the probability of day cycling song playing

	for k, v in pairs(self:getPlaylist()) do
		if k == "data" then -- no day and night cycle
			return k
		elseif self:getProbTimeCycle() ~= nil then -- we're going to check the probability playing the other track for this next one!
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

function mpInterface:initPlayerData(data)
	if self:getCurrentSong("count")[data] == nil then
		self:setCurrentSong("count", {[data] = 0})
	end
	return self:getCurrentSong("count")[data]
end

function mpInterface:getSong(isNext, number, isRandom)
	local data = self:getDataSong() -- loading the array of id / names

	-- full random
	if isRandom then
		self:setCurrentSong("count", {[data] = math.random(0, #self:getPlaylist()[data])})
	else
		if isNext and self:getCurrentSong("count")[data] >= #self:getPlaylist()[data] then -- in case we have extra border array values, we set to 0 to avoid errors
			number = 0	
		elseif not isNext and number < 1 then
			number = #self:getPlaylist()[data] + 1
		end

		if isNext then
			self:setCurrentSong("count", {[data] = number + 1})
		else
			self:setCurrentSong("count", {[data] = number - 1})
		end
	end
	-- not random, but if data is cycled, next song can be selected in the other data => cf getDataSong
	self:setCurrentSong("listname", data)
	self:setCurrentSong("track", self:getPlaylist()[data][1][self:getCurrentSong("count")[data]]) -- our song is picked, we can play it
	self:setCurrentSong("mustimer", self:getPlaylist()[data][2])
	return
end

function mpInterface:playlistBehaviour()

end

function mpInterface:timeDayCheck()
	self:setCurrentTime()
	if self:getCurrentTime()["hours"] >= 18 and self:getCurrentTime()["hours"] <= 6 then -- @todo careful for english time
		return false
	else
		return true
	end
end


-- our custom Player direct commands
function mpInterface:execPlayMusic(song)
	song = song or nil
	if song ~= nil then
		PlayMusic(song)
		self.start = true
	end
	return
end

function mpInterface:execStopMusic()
	StopMusic()
	return
end

function mpInterface:playLoader()
	SetCVar("Sound_EnableMusic", 1)
	self:setchronodelayer(math.random(self:getDelayer("min"), self:getDelayer("max")))
	self:settimeline(GetTime() + self:getCurrentSong("mustimer"))
	self:execPlayMusic(self:getCurrentSong("track"))
	return
end

-- our music player main feature
function mpInterface:execPlay(playlist, isNext, number)
	-- loading our playlist if doesn't exist
	if self:getPlaylist() == nil then
		self:execPlaylistLoadout(playlist)
	end
	isNext = isNext or true
	
	-- setting up count data if not setup
	for k, v in pairs(self:getPlaylist()) do
		self:initPlayerData(k)
	end
	-- getting or not the current data playlist if its recorded, if not given, the player detect our current
	local countData = 0
	if self:getCurrentSong("listname") ~= nil then
		countData = self:getCurrentSong("count")[self:getCurrentSong("listname")]
	end
	number = number or countData

	-- loading our song
	self:getSong(isNext, number, self:getIsRandom())

	-- Our player timing function
	self.playerFrame:SetScript("OnUpdate", function()
		if not self.start then -- starting music
				self:playLoader()
				print("mPstarted")
		end
		if self:getTypeRepeater() ~= 2 then
			if self.start and self:gettimeline() < GetTime() then -- timeline
					-- stopSong!
					self:execStopMusic()
					SetCVar("Sound_EnableMusic", 0)
					print("mPended!")
			elseif self.start and self:gettimeline() + self:getChronoDelayer() > GetTime()  then -- adding the delayer in timeline
					
					self.start = false
					local ListName = self:getCurrentSong("Listname")
					local trackLimit = #self:getPlaylist()[ListName]
					-- following case, we arrived at the song limit count
					if self:getCurrentSong("count")[ListName] > trackLimit then
						if self:getTypeRepeater() == 0 then -- check if it's the end, we stop
							self.playerFrame:UnregisterEvent("OnUpdate")
							return -- over
						elseif self:getTypeRepeater() == 1 then -- check if it's a repeat : startover playlist is possible
							self:resetAllCounts()
						end
					end
					self:getSong(isNext, self:getCurrentSong("count")[ListName], self:getIsRandom())
			end	
		end
	end)
	self.playerFrame:UnregisterEvent("OnUpdate")

end

function mpInterface:reset()
	self:setPlaylist()
	self:setCurrentSong()
end

function mpInterface:resetAllCounts()
	for k, v in pairs(self:getCurrentSong("count")) do
		self:getCurrentSong("count")[k] = 0
	end
end

function mpInterface:nextPlaylist()
	self:getList()
end


function mpInterface:UnloadList()
	self:setList()
end
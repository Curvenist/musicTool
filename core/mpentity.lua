mpentity = {
	List = {},
	Playlist = {},
	ExternalDB = {},

	delayer = {
		min = nil,
		max = nil
	},

	typeRepeater = nil, -- 0 = play playlist once  / 1 = repeat playlist / 2 = repeat same
	probTimeCycle = nil,
	timeline = nil,
	chronoDelayer = nil,
	start = false, -- just to know if a song has been started
	isRandom = false,
	player = nil,

	currentSong = {
		count = {}, -- track number in data
		listname = nil, -- track is in specific data, datad, datan
		mustimer = nil, -- setting a timeline before delayer takes place
		track = nil -- our track id / name
	},

	currentTime = {
		hours = nil,
		min = nil
	}
}

function mpentity:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
  end

-- waiting for a full json data!
function mpentity:setlist(list) -- list in json
	list = list or {}
	self.List = list
end

function mpentity:getlist(playlist) -- list in name
	if playlist ~= nil then
		return self.List[playlist]
	end
	return self.List
	
end

function mpentity:setPlaylist(playlist) -- playlist in json
	playlist = playlist or {}
	self.PlayList = playlist
end


function mpInterface:getPlaylist() -- playlist name
	return self.PlayList
end

function mpentity:execLoadDB(db) -- in case the player wants to load another playlist
	self:setList(Customdb:main(db))
end

function mpentity:execPlaylistLoadout(playlist) -- playlist.json
	-- contains all music data
	-- List = {array of files}
	self:setPlaylist(self:getList(playlist))
end

-- all setters / getters parameters for playlists type
function mpentity:setDelayer(min, max) -- set a delayer between songs
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

function mpentity:getDelayer(param)
	if param ~= nil then
		return self.delayer[param]
	end
	return self.delayer
end

function mpentity:settimeline(value)
	self.timeline = value
end

function mpentity:gettimeline()
	return self.timeline
end

function mpentity:setchronodelayer(value)
	self.chronoDelayer = value
end

function mpentity:getChronoDelayer()
	return self.chronoDelayer
end

function mpentity:setTypeRepeater(number) -- set a typeRepeater for songs - bypasses probTimeCycle
	self.typeRepeater = number
end

function mpentity:getTypeRepeater()
	return self.typeRepeater
end

function mpentity:setIsRandom(boolean)
	self.isRandom = boolean
end

function mpentity:getIsRandom()
	return self.isRandom
end

function mpentity:setCurrentSong(param, value)
	if param ~= nil then
		self.currentSong[param] = value
		return
	end
	self.currentSong = {}
end

function mpentity:getCurrentSong(param)
	if param ~= nil then
		return self.currentSong[param]
	end
	return self.currentSong
end

function mpentity:setCurrentTime() -- k = hours / min, v = value as time
	self.currentTime["hours"], self.currentTime["min"] = GetGameTime()
end

function mpentity:getCurrentTime()
	return self.currentTime
end

-- in case we get datad / datan, we can set up a probability of playling day or night songs
-- for instance true / 0.8 means during the night time, we have a small chance of playing day music by 20%, 1 means, no day music at all for night and vice versa
function mpInterface:setprobTimeCycle(boolean, prob) 
	if boolean then
		self.probTimeCycle = prob
		return
	end
	self.probTimeCycle = 0
	return
end

function mpInterface:getProbTimeCycle()
	return self.probTimeCycle
end

--SETUP-----------------------------------------------------
local PLUGIN_NAME     = 'Namyts\'s Automatic Bookmark'

-- Reload extension using Tools -> Plugins and Extensions -> Active Extensions -> Reload -> Toggle on again in View menu

local options = {
  	playlist_path   = '', -- use \\ instead of \
  	bookmark_filename = 'bookmark'
}

function descriptor()
  	return {
		title = PLUGIN_NAME,
		version = '1.0',
		author = 'Namyts',
		description = [[
			When a video is paused, save an M3U playlist with all future episodes in the folder, and the timestamp of the current episode.
		]],
		capabilities = {'playing-listener', 'input-listener'},
	}
end

--CODE-----------------------------------------------------

local function log(text)
	if(text~=nil) then
		vlc.msg.info(('[%s]: %s'):format(PLUGIN_NAME, text))
	end
end

-- required...
function activate()
end
function deactivate()
end

local function splitByRegex(text,regex)
	return text:gsub(regex, ''), text:match(regex)
end

local function splitPathAndFile(path)
	return splitByRegex(path,'[^\\/]+$')
end

local function splitFileAndExtension(file)
	return splitByRegex(file,'%.[^.]+$')
end

local function onPause()
	log('\n')
  	log('detected a pause')

	local fullVideoPathURI = vlc.input.item():uri()
	local fullVideoPath = vlc.strings.decode_uri(fullVideoPathURI)
		:gsub('^[^/]*/*', '')
		:gsub('/', '\\')
	local videoDirectory, videoPath = splitPathAndFile(fullVideoPath)
	local videoBase, videoExtension = splitFileAndExtension(videoPath)

	local files = vlc.io.readdir(videoDirectory)
	table.sort(files)

	local block = {} -- Table of text that will be written to a file line by line

	local play_time = vlc.var.get(vlc.object.input(), 'time') / 1000000
	table.insert(block,'#EXTVLCOPT:start-time='..play_time)
	
	local activated = false
	for i, f in ipairs(files) do
		local playlistVid, playlistExt = splitFileAndExtension(f)
		if(videoPath==f) then
			activated = true
		end
		if(videoExtension==playlistExt and activated) then -- append the rest of the season to the playlist. inlcuding the episode youre on, so that the start-time works.
			table.insert(block,f)
		end
	end

	local fileString = table.concat(block,'\n')

	log(fileString)

	local bookmark = ('%s.m3u'):format(options.bookmark_filename)
	os.remove(bookmark)
	local f = io.open(bookmark, 'w')
	f:write(fileString)
	f:close()
end

function playing_changed()
  	if vlc.playlist.status() == 'paused' then
    	local ok, msg = pcall(onPause)
		if not ok then
			log(('[ERROR!]: %s'):format(msg))
		end
  	end
end

function open()
	vlc.activate()
end

function close()
	local ok, msg = pcall(onPause)
	if not ok then
		log(('[ERROR!]: %s'):format(msg))
	end
    vlc.deactivate()
end
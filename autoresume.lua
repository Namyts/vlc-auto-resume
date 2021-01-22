--SETUP-----------------------------------------------------
local PLUGIN_NAME     = 'Auto Resumer'

-- Reload extension using Tools -> Plugins and Extensions -> Active Extensions -> Reload -> Toggle on again in View menu

local options = {
  	playlist_path   = '', -- use \\
  	bookmark_filename = 'bookmark'
}

function descriptor()
  	return {
		title = PLUGIN_NAME,
		version = '1.0',
		author = 'Namyts',
		description = [[
			When a video is paused, save an M3U playlist with current playback position.
			Open this script in a text editor to configure.
		]],
		capabilities = {'playing-listener', 'input-listener'},
	}
end

--CODE-----------------------------------------------------

-- required...
function activate()
end
function deactivate()
end

local function log(text)
	vlc.msg.info(('[%s]: %s'):format(PLUGIN_NAME, text))
end

-- C:\foo\bar.txt -> C:\foo\
local function splitPathAndFile(path)
	local base_regex = '[^\\/]+$'
  	return path:gsub(base_regex, ''), path:match(base_regex)
end

local function removeFileExtension(file)
	local file_ext_regex = '%.[^.]+$'
	return file:gsub(file_ext_regex, '')
end

local function onPause()
	log('\n')
  	log('detected a pause')

	local fullVideoPathURI = vlc.input.item():uri()
	local fullVideoPath = vlc.strings.decode_uri(fullVideoPathURI)
		:gsub('^[^/]*/*', '')
		:gsub('/', '\\')

	-- log(fullVideoPath)

	local videoDirectory, videoPath = splitPathAndFile(fullVideoPath)
	local videoBase = removeFileExtension(videoPath)

	log(('video dir: %s\n, file: %s\n, base: %s\n'):format(videoDirectory, videoPath, videoBase))

	local bookmark = ('%s.m3u'):format(options.bookmark_filename)
	os.remove(bookmark)

	local play_time = vlc.var.get(vlc.object.input(), 'time') / 1000000
	local block = '#EXTVLCOPT:start-time=%d\n'..
					'%s\n'..
					'\n'
	block = block:format(play_time, fullVideoPathURI)
	local f = io.open(bookmark, 'w')
	f:write(block)
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

function trigger()
	log('I AM TRIGGERRED!!!!')
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
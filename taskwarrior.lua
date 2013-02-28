-- external modules
local os = os
local string = string
local screen = screen
local widget = widget
local awful = require("awful")
local naughty = require("naughty")
local ansiDecode = require("ansiDecode")

-- widgets and notifications
local taskwarrior_widget = nil
local tasklist_popup = nil

-- the taskwarrior command to generate the tasklist
local command = 'task %s overview' -- The placeholder is for the configuration overrides
local overrides = 'rc.echo.command=no rc._forcecolor=yes rc.blanklines=false rc.hooks=off'

-- local state
local tasklist_raw = ''		-- raw output of `task`
local tasklist_text = ''	-- text of the tasklist to be displayed
local taskcount = 0		-- number of tasks
local screennum = 1		-- which screen to show notifications

module('taskwarrior')

-- helper functions
local function explode(separator, str)
	local pos, arr = 0, {}
	for st, sp in function() return string.find(str, separator, pos, true) end do
		table.insert(arr, string.sub(str,pos,st-1))
		pos = sp + 1
	end
	table.insert(arr,string.sub(str,pos))
	return arr
end

-- refresh the tasklist data
function refresh_tasklist(gc)
        task_overrides = overrides
        if gc == nil or gc == false then
                task_overrides = 'rc.gc:off ' .. overrides
        end
        task_command = string.format(command, task_overrides)
	tasklist_raw = awful.util.pread(task_command)
	tasklist_text = ansiDecode.decodeAnsiColor(string.gsub(tasklist_raw, "\n%d+ tasks.+", ''))
	taskcount = string.match(tasklist_raw, '(%d+) tasks')
	if taskcount == nil then
		tasklist_text = 'There are no tasks'
		taskcount = 0
	end
	refresh_widget()
end

-- refresh the tasklist widget
function refresh_widget()
	if taskwarrior_widget ~= nil then
		taskwarrior_widget.text = ' ' .. taskcount .. ' tasks'
	end
end

-- remove the tasklist popup
function remove_tasklist()
	if tasklist_popup ~= nil then
		naughty.destroy(tasklist_popup)
		tasklist_popup = nil
	end
end

-- show the tasklist popup
function add_tasklist()
	remove_tasklist()
	tasklist_popup = naughty.notify({
		text = tasklist_text,
		timeout = 0,
		screen = screennum,
	})
end

-- Toggle the tasklist
function toggle_tasklist()
	if tasklist_popup == nil then
	        refresh_tasklist(true)
		add_tasklist()
	else
		remove_tasklist()
	end
end

-- Show a change notification
function notify(message)
	refresh_tasklist()
	naughty.notify({
		text = message,
		screen = screennum,
	})
end

-- Callback called by taskwarrior on an update
function on_update()
	refresh_tasklist()
	if tasklist_popup ~= nil then
	        refresh_tasklist(false)
		add_tasklist()
	end
end

-- create a new taskwarrior widget
function create_widget(notify_screen)
	screennum = notify_screen

	if screennum == nil then screennum = 1 end
	if screen.count() < screennum then
		screennum = 1
	end

	refresh_tasklist()
	taskwarrior_widget = widget({type = "textbox", align = "right"})
	taskwarrior_widget.text = ' ' .. taskcount .. ' tasks'

	return taskwarrior_widget
end


to list_position(this_item, this_list)
	repeat with i from 1 to the count of this_list
		if item i of this_list is this_item then return i
	end repeat
	return 0
end list_position

-- List of day names for identification
set dayNames to {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"}
set dayOffset to {0, 1, 2, 3, 4, 5, 6}

-- List of repeating reminders
set repeatingReminders to {"Gym", "Mins", "Washing out", "Washing on", "Bins out", "Mirrors", "Bathroom", "Plan for week ahead"}

tell application "Notes"
	set theNote to the note "To Do  TH 2024 Edition"
	set noteContent to the body of theNote
end tell

-- Script to clean the note content
set cleanScript to "echo " & quoted form of noteContent & ¬
	" | sed -E 's/<div><h3>([[:alpha:]]+)<\\/h3><\\/div>/\\n\\1\\n/g' " & ¬
	"| sed -E 's/<[^>]+>//g' " & ¬
	"| sed -E '/🍲/,/🦖/{//!d;};/🍲|🦖/d'" & ¬
	"| sed '/🏠/d'" & ¬
	"| sed '/To Do  TH 2024 Edition/d'" & ¬
	"| sed '/^$/d'"

-- Run the shell script
set cleanedContent to do shell script cleanScript

-- For debugging, let's just display the result
-- return cleanedContent


-- Split the content into lines
set textLines to paragraphs of cleanedContent

-- Variables to hold current day and tasks
set currentDay to ""
set currentTasks to {}
set dayWiseTasks to {}


-- Iterate through each line
repeat with aLine in textLines
	set lineText to aLine as string
	
	-- Check if the line is a day name
	if dayNames contains lineText then
		-- Save tasks of the previous day
		if currentDay is not "" then
			set end of dayWiseTasks to {currentDay, currentTasks}
		end if
		-- Update currentDay and reset currentTasks
		set currentDay to lineText
		set currentTasks to {}
	else
		-- Add the line to current tasks
		set end of currentTasks to lineText
	end if
end repeat

-- Add the last day's tasks
if currentDay is not "" then
	set end of dayWiseTasks to {currentDay, currentTasks}
end if

-- dayWiseTasks now contains each day and its corresponding tasks
-- return dayWiseTasks

-- Loop through each day
repeat with aDay in dayWiseTasks
	-- Extract the day name and tasks
	set dayName to item 1 of aDay
	set tasks to item 2 of aDay
	
	set dayOffset to list_position(dayName, dayNames)
	
	set theDay to (current date) + ((dayOffset - 1) * days)
	
	tell application "Reminders"
		set allReminders to reminders of list "To Do"
		
		-- Create a reminder for each task
		repeat with aTask in tasks
			set found to false
			-- Check if the reminder already exists
			repeat with aReminder in allReminders
				if name of aReminder is aTask then
					-- Reset the reminder if it's a repeating task and completed
					if (aTask is in repeatingReminders) then
						set found to true
						if (completed of aReminder is true) then
							set completed of aReminder to false
						end if
					end if
				end if
			end repeat
			
			-- If the reminder does not exist, create a new one
			if not found then
				tell list "To Do"
					make new reminder with properties {name:aTask, due date:theDay as date}
				end tell
			end if
		end repeat
	end tell
end repeat


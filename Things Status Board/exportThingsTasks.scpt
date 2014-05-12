on convertDate(aDate)
	-- Create a list of the date elements
	set dateComponentList to {year, month, day} of aDate
	
	-- Manipulate the numeric values accordingly
	set item 1 of dateComponentList to (item 1 of dateComponentList) * 10000
	set item 2 of dateComponentList to (item 2 of dateComponentList) * 100
	
	-- Generate the final numeric value
	set numericDate to (item 1 of dateComponentList) + (item 2 of dateComponentList) + (item 3 of dateComponentList)
	
	-- Return the date's numeric value
	return (numericDate)
end convertDate

on extractThingsTasks(taskListName)
	set currentDate to convertDate(current date)
	set taskList to {}

	tell application "Things"
		repeat with currentTask in to dos of list taskListName
			-- Initialize task list item
			set taskListItem to ""

      -- Skip tasks that are completed
      if (status of currentTask) is not equal to completed then
  			(* 	Extract tasks (and their project/area) from Things.app and
  				save them in comma seperated taskListItem *)
  			if (project of currentTask) is not missing value then
  				set taskListItem to (name of currentTask) & "," & (name of project of currentTask)
  			else if (area of currentTask) is not missing value then
  				set taskListItem to (name of currentTask) & "," & (name of area of currentTask)
  			else
  				set taskListItem to (name of currentTask) & "," & "None"
  			end if
			
  			-- Add the due date column to taskListItem
  			if (due date of currentTask) is not missing value then
  				set dueDate to my convertDate(due date of currentTask)
  				set dateDiff to dueDate - currentDate

  				if dateDiff is equal to 0 then
  					set taskListItem to taskListItem & "," & "Due Today"
  				else if dateDiff is less than 0 then
  					set taskListItem to taskListItem & "," & "Overdue"
  				else if dateDiff is equal to 1 then
  					set taskListItem to taskListItem & "," & dateDiff & " " & "Day Left"
  				else
  					set taskListItem to taskListItem & "," & dateDiff & " " & "Days Left"
  				end if
  			else
  				set taskListItem to taskListItem & "," & " "
  			end if
			
  			-- Add the task to the task list
  			if taskListItem is not equal to "" and taskList does not contain taskListItem then
  				set the end of taskList to taskListItem
  			end if
      end if
		end repeat
	end tell
	
	-- Return the task list
	return (taskList)
end extractThingsTasks

on run(argv)
	-- Extract task list from things
	set taskList to extractThingsTasks(item 1 of argv)
	
	-- Initialize csv text variable
	set csvText to ""
	
	-- Write csv text
	repeat with nextTask in taskList
		set csvText to csvText & text of nextTask & "\n"
	end repeat
	
	-- Return csv text
	return(csvText)
end run
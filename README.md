# CPU Temperature Display Script

This PowerShell script monitors your CPU temperature in real-time using a simple graphical display. It updates every 30 seconds and logs temperature data to a daily CSV file.

![screenshot](screenshot_cpu_temp_CandF.png)

##     Change Log:

### 1.2 - 
        Revised temperature update logic to use a unified Get-CPUTemp function that safely retrieves both Celsius and Fahrenheit values.
        The timer event now handles missing or invalid temperature readings gracefully and displays "N/A" instead of blank values. Degree symbols are rendered correctly using Unicode ([char]176]) to prevent mojibake (“Â°”).

        Details:
        Replaced separate Get-CPUTempC and Get-CPUTempF calls with consolidated Get-CPUTemp.
        Added null checks to avoid empty display when temperature data unavailable.
        Updated UI label text logic for correct degree symbol display.
        Logging now records $null when no temperature reading is available, avoiding incorrect entries.
        Improved robustness and readability of the update timer block.

### 1.1 
- Added configuration options, improved logging, fixed timer disposal
- Created a dedicated Write-TempLog function
- Fixed the variable name bug introduced when adding °F (was using $temp instead of $tempC/$tempF)
- Now logs both Celsius and Fahrenheit in a single line
- Eliminated redundant logging code- Added a FormClosed event handler to properly terminate the Form and the timer.
  The timer previouly continued to run in the PowerShell instance and running the script again resulted in two timers triggering additional temperature checks and logging. Closing PowerShell did end the timers, but it's better to clean up resources properly.
- Added option to show both temperature units
- Organized UI creation code into a logical section
- Grouped related functionality
- Improved readability with consistent spacing and formatting
- Removed commented-out code

### 1.0 - Initial release

## Features

- Displays current CPU temperature in a small window (°C & °F)
- Updates every 30 seconds (configurable)
- Logs data to a daily CSV file (e.g. `temperature_log_2025-07-15.csv`)


### Contains a configuration hashtable - Makes it easy to adjust settings in one place

- Update interval (Set to desired seconds, 1000 = 1 second.)
- Log file path
- Option to display Fahrenheit

## TODO - Features to add in future version

- Tidy up the threshold setting. Allow user to enter actual seconds - do the x1000 elsewhere.
- Prettier display
- Automatically delete log files older than 7 days
- Allow user to set delete interval
- Optional red warning text if temperature exceeds preset threshold
- Allow user to set threshold temp
- Pop-up warning when critical heat is reached - _CAUTION! Need to ensure only one pop-up allowed at a time_
- Check CPU type and lookup manufacturer recommended max temp - how? where?
- Auto minimise the PowerShell window on script run
- Auto restart in Administrator mode if run in user mode
- Auto launch PowerShell in administrator mode - Error in normal mode: `Get-WmiObject : Access denied`
- Auto launch PowerShell in minimised administrator mode - requires previous step

## Requirements

- Windows (with WMI access) - _Run in Administrator Mode_
- PowerShell 5.x or newer
- .NET Windows Forms (built-in on most Windows systems)
- Visual Studio Code (recommended) with the PowerShell extension

## Usage

1. Clone this repository:
   ```
   git clone https://github.com/MichaelMcKibbin/cpu_temp_display
   ```

## The script in action

### Version 1.0

![screenshot](screenshot_script.png)

### Version 1.1
### Version 1.2


![screenshot](screenshot-script-with-fahrenheit.png)

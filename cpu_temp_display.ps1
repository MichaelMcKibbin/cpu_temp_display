<#
.SYNOPSIS
    CPU Temperature Monitor and Logger

.DESCRIPTION
    Displays and logs CPU temperature in both Celsius and Fahrenheit

.NOTES
    Version:        1.2
    Author:         Michael McKibbin
    Creation Date:  July 15, 2025
    Last Modified:  Oct 25, 2025
    Change Log:

    1.2 - Summary:
        Revised temperature update logic to use a unified Get-CPUTemp function that safely retrieves both Celsius and Fahrenheit values. The timer event now handles missing or invalid temperature readings gracefully and displays "N/A" instead of blank values. Degree symbols are rendered correctly using Unicode ([char]176]) to prevent mojibake (“Â°”).

        Details:
        Replaced separate Get-CPUTempC and Get-CPUTempF calls with consolidated Get-CPUTemp.
        Added null checks to avoid empty display when temperature data unavailable.
        Updated UI label text logic for correct degree symbol display.
        Logging now records $null when no temperature reading is available, avoiding incorrect entries.
        Improved robustness and readability of the update timer block.

    1.1 - Added configuration options, improved logging, fixed timer disposal
    1.0 - Initial release
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Configuration
$config = @{
    UpdateInterval = 10000  # 5000 = 5 seconds, 30000 = 30 seconds, etc.
    LogPath = "$env:USERPROFILE\temperature_log_$(Get-Date -Format 'yyyy-MM-dd').csv"
    DisplayFahrenheit = $true
}

# Function to get CPU temperature raw value in Kelvin
# To be more precise, the ACPI thermal zone temperature is an abstract representation created by the BIOS/UEFI firmware that can include multiple sensors
# It is sometimes possible to map particular sensors more precisely, e.g TZ00, TZ01, etc., but it depends on the system.
# In my case, I can be fairly certain that I'm getting the best representation of the CPU temperature by watching the changes when adding/removing load on the CPU

function Get-CPUTempRaw {
  try {
    $t = Get-CimInstance -Namespace root/wmi -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop |
         Where-Object { $_.CurrentTemperature -gt 0 } |
         Select-Object -First 1 -ExpandProperty CurrentTemperature
    # Filter obviously bad values
    if ($null -eq $t -or $t -in 0, 2732, 65535) { return $null }
    [int]$t
  } catch {
    $null
  }
}
function Get-CPUTemp {
  $raw = Get-CPUTempRaw
  if ($null -eq $raw) { return $null }
  $c = [math]::Round(($raw/10) - 273.15, 1)
  $f = [math]::Round((($c * 9) / 5) + 32, 1)
  [pscustomobject]@{ C = $c; F = $f; Raw = $raw }
}


# Function to log temperature data
function Write-TempLog {
    param (
        [string]$timestamp,
        [string]$tempC,
        [string]$tempF
    )
    
    "$timestamp,$tempC,$tempF" | Out-File -FilePath $config.LogPath -Append
}

# Create UI
$form = New-Object System.Windows.Forms.Form
$form.Text = "CPU Temperature Monitor"
$form.Size = New-Object System.Drawing.Size(300, 100)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $true

$label = New-Object System.Windows.Forms.Label
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(30, 30)
$label.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Regular)
$form.Controls.Add($label)

# Timer to update temperature and log it
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = [int]$config.UpdateInterval
$timer.add_Tick({
    $t = Get-CPUTemp           # returns @{C=..; F=..; Raw=..} or $null
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    if ($t) {
        $c = $t.C
        $f = $t.F

        if ($config.DisplayFahrenheit) {
            # Use a reliable degree symbol to avoid "Â°" mojibake
            $label.Text = "CPU Temp: $c$([char]176)C / $f$([char]176)F"
        } else {
            $label.Text = "CPU Temp: $c$([char]176)C"
        }
    } else {
        # No reading available
        $label.Text = "CPU Temp: N/A"
        $c = $null
        $f = $null
    }

    # Log either the real values or nulls if unavailable
    Write-TempLog -timestamp $timestamp -tempC $c -tempF $f
})

# (Make sure your UI starts the timer somewhere)
# $timer.Start()


# Start monitoring
$timer.Start()

# Handle form closing to clean up resources
$form.Add_FormClosed({
    $timer.Stop()
    $timer.Dispose()
})

# Run the form
[System.Windows.Forms.Application]::Run($form)

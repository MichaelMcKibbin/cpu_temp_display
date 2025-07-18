<#
.SYNOPSIS
    CPU Temperature Monitor and Logger

.DESCRIPTION
    Displays and logs CPU temperature in both Celsius and Fahrenheit

.NOTES
    Version:        1.1
    Author:         Michael McKibbin
    Creation Date:  July 15, 2025
    Last Modified:  July 18, 2025
    Change Log:
    1.1 - Added configuration options, improved logging, fixed timer disposal
    1.0 - Initial release
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Configuration
$config = @{
    UpdateInterval = 30000  # 5000 = 5 seconds, 30000 = 30 seconds, etc.
    LogPath = "$env:USERPROFILE\temperature_log_$(Get-Date -Format 'yyyy-MM-dd').csv"
    DisplayFahrenheit = $true
}

# Function to get CPU temperature raw value in Kelvin (x10)
function Get-CPUTempRaw {
    return Get-WmiObject -Namespace "root/wmi" -Class MSAcpi_ThermalZoneTemperature |
        Select-Object -ExpandProperty CurrentTemperature -ErrorAction SilentlyContinue
}

# Function to get CPU temperature in Celsius
function Get-CPUTempC {
    $tempRaw = Get-CPUTempRaw
    if ($tempRaw) {
        return [math]::Round(($tempRaw - 2732) / 10, 1)
    } else {
        return "N/A"
    }
}

# Function to get CPU temperature in Fahrenheit
function Get-CPUTempF {
    $tempRaw = Get-CPUTempRaw
    if ($tempRaw) {
        return [math]::Round((($tempRaw - 2732) / 10 * 9 / 5 + 32), 1)
    } else {
        return "N/A"
    }
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
$timer.Interval = $config.UpdateInterval
$timer.Add_Tick({
    $tempC = Get-CPUTempC
    $tempF = Get-CPUTempF
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    
    # Update display
    if ($config.DisplayFahrenheit) {
        $label.Text = "CPU Temp: $tempC°C / $tempF°F"
    } else {
        $label.Text = "CPU Temp: $tempC°C"
    }
    
    # Log data
    Write-TempLog -timestamp $timestamp -tempC $tempC -tempF $tempF
})

# Start monitoring
$timer.Start()

# Handle form closing to clean up resources
$form.Add_FormClosed({
    $timer.Stop()
    $timer.Dispose()
})

# Run the form
[System.Windows.Forms.Application]::Run($form)

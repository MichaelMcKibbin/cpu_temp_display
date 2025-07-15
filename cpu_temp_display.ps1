Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Set up the log file path
#$logPath = "$env:USERPROFILE\temperature_log.csv"
$today = Get-Date -Format "yyyy-MM-dd"
$logPath = "$env:USERPROFILE\temperature_log_$today.csv"

# Create the main display form
$form = New-Object System.Windows.Forms.Form
$form.Text = "CPU Temperature Monitor"
$form.Size = New-Object System.Drawing.Size(300, 100)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $true

# Create a label to display the temperature
$label = New-Object System.Windows.Forms.Label
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(30, 30)
$label.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Regular)
$form.Controls.Add($label)

# Function to get CPU temperature
# Converts Kelvin to Centigrade
function Get-CPUTemp {
    $tempRaw = Get-WmiObject -Namespace "root/wmi" -Class MSAcpi_ThermalZoneTemperature |
        Select-Object -ExpandProperty CurrentTemperature -ErrorAction SilentlyContinue
    if ($tempRaw) {
        return [math]::Round(($tempRaw - 2732) / 10, 1)
    } else {
        return "N/A"
    }
}

# Timer to update temperature and log it
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 5000  # 1000 = 1 second. 30000 = 30 seconds 
$timer.Add_Tick({
    $temp = Get-CPUTemp
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $label.Text = "CPU Temp: $temp°C"

    if ($temp -ne "N/A") {
        "$timestamp,$temp" | Out-File -FilePath $logPath -Append
    } else {
        "$timestamp,N/A" | Out-File -FilePath $logPath -Append
    }

})

# Start monitoring
$timer.Start()

# Run the form
[System.Windows.Forms.Application]::Run($form)

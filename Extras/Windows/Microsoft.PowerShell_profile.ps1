Clear-Host
Set-Location -Path 'C:\Users\ELLIOTTCABLE'

Set-Alias subl 'C:\Program Files\Sublime Text 3\sublime_text.exe'

function Prompt {
    Write-Host (">") -nonewline -foregroundcolor Green
    return " "
}

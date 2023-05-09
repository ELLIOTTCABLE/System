
function Install-Package-Manager-Build-Deps {

}

function Install-Package-Manager {
   $URL = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
   $URL = (Invoke-WebRequest -Uri $URL).Content | ConvertFrom-Json |
         Select-Object -ExpandProperty "assets" |
         Where-Object "browser_download_url" -Match '.msixbundle' |
         Select-Object -ExpandProperty "browser_download_url"

   # Download
   Invoke-WebRequest -Uri $URL -OutFile "Setup.msix" -UseBasicParsing

   # Install
   Add-AppxPackage -Path "Setup.msix"

   # Delete file
   Remove-Item "Setup.msix"
}


Install-Package-Manager

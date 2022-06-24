#todo: add comments for how to run
#todo: determine where I can save it to share with Bob & Michael

#todo: add script to pull list of webpages to check, adjust script to allow for All or external only
$Output = @()
$csvPath = "C:\Users\xxxxxxx\OneDrive - Environmental Protection Agency (EPA)\Documents\linkCheckerExport\"
$csvFileName = "linkcheck_$((Get-Date).ToString('yyyyMMddHHmm')).csv"

Write-Host "filename: " $csvFileName
$rootUrl = "work.epa.gov/cui/epa-cui-registry"
try { 

    Write-Host "loading page: " $rootUrl
    $links = (Invoke-WebRequest -Uri $rootUrl).Links
    
    Write-Host "links found: " $links.Count

    $filterDescription = "-like http*, -notlike *.epa.gov/*, -notlike *.sharepoint.com/* "
    Write-Host "filtering links: " $filterDescription

    $notRelative = $links | Where-Object {$_.href -like "http*"}
    $notEPA = $notRelative | Where-Object{$_.href -notlike "*.epa.gov/*"}
    $notSP = $notEPA | Where-Object{$_.href -notlike "*.sharepoint.com/*"}
    
    Write-Host "links filterd to: " $notSP.Count
    foreach ($link in $notSP){ 
       try { 
           $req = Invoke-WebRequest -uri $link.href
           Write-Output $link.href ": " $req.StatusCode
            $newLine = New-Object -TypeName PSObject -Property @{
                title = $link.innerText
                href = $link.href
                status = $req.StatusCode
            } 
            $Output += $newLine
       }
       catch{
         $errMsg = $_
         $errorLine = New-Object -TypeName PSObject -Property @{
                title = $link.innerText
                href = $link.href
                status = "0 error occurred $($errMsg)"
            } 
            
          $Output += $errorLine
       }

     }
    }
 catch{
         $pgmError = $_
         Write-Host "error occurred $($pgmError)"
} 

$fullPath = "$($csvPath)$($csvFileName)"
$Output | Export-Csv -Path $fullPath -NoTypeInformation
Write-Host "results saved to: " $fullPath
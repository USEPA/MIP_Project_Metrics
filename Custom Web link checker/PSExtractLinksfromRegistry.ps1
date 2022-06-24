#todo: add comments for how to run
#todo: determine where I can save it to share with Bob & Michael



function Get-RegistryLinks(){
 
  $registryURL   = "work.epa.gov/cui/epa-cui-registry"

  Write-Host "loading page: " $registryURL
    $links = (Invoke-WebRequest -Uri $registryURL).Links
    
    Write-Host "links found: " $links.Count

    $filterDescription = "-like http*, -notlike *.epa.gov/*, -notlike *.sharepoint.com/* "
    Write-Host "filtering links: " $filterDescription

    $notRelative = $links | Where-Object {$_.href -like "http*"}
    $notEPA = $notRelative | Where-Object{$_.href -notlike "*.epa.gov/*"}
    $notSP = $notEPA | Where-Object{$_.href -notlike "*.sharepoint.com/*"}
    
    Write-Host "links filterd to: " $notSP.Count

    #add source url to object
    
    $notSP | Add-Member -MemberType NoteProperty -Name 'sourceURL' -Value ''

    foreach ($link in $notSP){ 
        $link.sourceURL = $registryURL;
    }
    
    return $notSP

}

function Get-CUIIntranetLinks($linkURL){
 
    Write-Host "loading page: " $linkURL
    $linksFromPage = (Invoke-WebRequest -Uri $linkURL).Links
    
    Write-Host "links found: " $linksFromPage.Count

    $filterDescription = "-like /cui/*"
    Write-Host "filtering links: " $filterDescription

    $cuiIntranetLinks = $linksFromPage | Where-Object {$_.href -like "/cui/*"}
    
    Write-Host "links filterd to: " $cuiIntranetLink.Count

    #add source url to object
    
    $cuiIntranetLinks | Add-Member -MemberType NoteProperty -Name 'sourceURL' -Value ''

    foreach ($link in $cuiIntranetLinks){ 
      $link.sourceURL = $linkURL;
      #append base url since urls are relative
      $link.href = $baseIntranetURL + $link.href
   }
    return $cuiIntranetLinks

}

#todo: add script to pull list of webpages to check, adjust script to allow for All or external only
$Output = @()
$csvPath = "C:\Users\XXXXXXXXX\OneDrive - Environmental Protection Agency (EPA)\Documents\linkCheckerExport\"
$csvFileName = "linkcheck_$((Get-Date).ToString('yyyyMMddHHmm')).csv"


Write-Host "filename: " $csvFileName

$baseIntranetURL = "https://work.epa.gov"

#future: change to dynamic list
$cuiIntranetUrls = @(
"https://work.epa.gov/cui/controlled-unclassified-information-program-overview",
"https://work.epa.gov/cui/cui-program-news",
"https://work.epa.gov/cui/cui-policy-and-procedures",
"https://work.epa.gov/cui/cui-program-resources",
"https://work.epa.gov/cui/cui-leadership-and-program-staff",
"https://work.epa.gov/cui/contact-us-epas-controlled-unclassified-information-program"
)


try { 

    $registryLinks = Get-RegistryLinks
    $linksToCheck = $registryLinks


    #load links from list of pages
    $urlResults = @()
    foreach ($iUrl in $cuiIntranetUrls){ 
      $lResult = Get-CUIIntranetLinks($iUrl)
      $urlResults += $lResult
    }

    $linksToCheck = $linksToCheck + $urlResults

    foreach ($link in $linksToCheck){ 
       try { 
           $req = Invoke-WebRequest -uri $link.href
           Write-Output $link.href ": " $req.StatusCode

            $newLine = New-Object -TypeName PSObject -Property @{
                sourceUrl = $link.sourceUrl
                title = $link.innerText
                href = $link.href
                #status = "0" 
                status = $req.StatusCode
            } 

            $Output += $newLine
       }
       catch{
         $errMsg = $_
         $errorLine = New-Object -TypeName PSObject -Property @{
                sourceUrl = $link.sourceUrl
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


$cores= 'sitecore_master_index', 'sitecore_master_index_sec','sitecore_web_index', 'sitecore_web_index_sec', `
'taggable_master_index', 'taggable_master_index_sec', 'taggable_web_index', 'taggable_web_index_sec'
$solr_hosts = '192.168.0.1:50001', '192.168.0.2:50001'

$threshold_warn = 1
$threshold_crit = 2
$w=0
$c=0
$logs = "OK.log", "CRITICAL.log", "WARNING.log"

function sent-email ($logfile, $stat) {
$smtpServer = "10.0.1.20"
$smtpFrom = "test@test.com"
$smtpTo = "devops@test.com"
$messageSubject = "Replication status $stat"
[string]$messagebody = ""
$logs = Get-Content $logfile

foreach ($log in $logs){
    $messagebody = $messagebody + $log + "`r`n"
}


$smtp = New-Object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($smtpFrom,$smtpTo,$messagesubject,$messagebody)
}


foreach ($log in $logs){
 if(Test-Path $home\Desktop\$log){Clear-Content $home\Desktop\$log}  
}


foreach ($solr_host in $solr_hosts) {
  if ($solr_host -eq "10.229.163.84:50001"){ 
     foreach ($log in $logs){ Add-Content $home\Desktop\$log "SOLR-REPEATER"}  
  }
  elseif ($solr_host -eq "10.229.168.224:50001"){
    foreach ($log in $logs){ Add-Content $home\Desktop\$log "SOLR-SLAVE"}
  }
 foreach ($core in $cores) {
    $jsonResult=Invoke-WebRequest "http://$solr_host/solr/$core/replication?command=details&wt=json" -UseBasicParsing -Method Get

    $localgeneration = ConvertFrom-Json -InputObject $jsonResult.content | select -expand details | select -ExpandProperty generation

    $mastergeneration = ConvertFrom-Json -InputObject $jsonResult.content | `
     select -expand details |select -expand slave | select -expand masterDetails | `
     select -expand master | select -ExpandProperty replicableGeneration

    if (!$mastergeneration -or !$localgeneration){ Write-Output 'status = CRITICAL'}    
     
    $generationdiff = $mastergeneration - $localgeneration

    if ($generationdiff > $threshold_warn) {
      $content = " $core - status = WARNING"
      $logfileW = "$home\Desktop\WARNING.log"
      Add-Content $logfileW $content
      # $w++ 
    }
    elseif ($generationdiff > $threshold_crit) {
      $content = " $core - status = CRITICAL"
      $logfileC = "$home\Desktop\CRITICAL.log"
      Add-Content $logfileC $content
      #$c++ 
    }    
    else { 
      $content = "  $core - status = OK"
      $logfileO = "$home\Desktop\OK.log"
      Add-Content $logfileO $content
    }
 }
}

if ($w>0){sent-email -logfile $logfileW -stat "WARNING" }
elseif ($c>0){sent-email -logfile $logfileC -stat "CRITICAL"}
else {sent-email -logfile $logfileO -stat "OK"}
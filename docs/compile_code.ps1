$outFile = "c:\Mind-Nest\docs\PROGRAM_CODE.md"
$n = "`n"
$codeFence = '```'

("# 5. PROGRAM CODE" + $n + $n + "## 5.1) main.dart" + $n + $codeFence + "dart") | Out-File -FilePath $outFile -Encoding utf8
Get-Content -Path "c:\Mind-Nest\lib\main.dart" | Out-File -FilePath $outFile -Append -Encoding utf8
($n + $codeFence + $n + $n + "## 5.2) Routine Management Module (home_routine_engine.dart)" + $n + $codeFence + "dart") | Out-File -FilePath $outFile -Append -Encoding utf8
Get-Content -Path "c:\Mind-Nest\lib\features\home\application\home_routine_engine.dart" | Out-File -FilePath $outFile -Append -Encoding utf8
($n + $codeFence + $n + $n + "## 5.3) AI Chat Module (chat_service.dart)" + $n + $codeFence + "dart") | Out-File -FilePath $outFile -Append -Encoding utf8
Get-Content -Path "c:\Mind-Nest\lib\services\chat_service.dart" | Out-File -FilePath $outFile -Append -Encoding utf8
($n + $codeFence) | Out-File -FilePath $outFile -Append -Encoding utf8

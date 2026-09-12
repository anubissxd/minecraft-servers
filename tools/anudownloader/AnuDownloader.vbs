Set objShell = CreateObject("WScript.Shell")
strPath = objShell.CurrentDirectory
objShell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & strPath & "\AnuDownloader.ps1""", 0, False

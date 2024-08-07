if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell -Verb RunAs -ArgumentList "-File", $MyInvocation.MyCommand.Path
    exit
}

$sample0 = "C:\ProgramData\MyFiles"
$sample1 = "C:\ProgramData\AvastSvcpCP"

$restartFlag = $false

$UACRegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$UACValue = Get-ItemProperty -Path $UACRegistryPath -Name "ConsentPromptBehaviorAdmin"

Write-Output ".__                            "
Write-Output "|  |    ____    ____  ______   "
Write-Output "|  |   /  _ \  /  _ \ \____ \  "
Write-Output "|  |__(  <_> )(  <_> )|  |_> > "
Write-Output "|____/ \____/  \____/ |   __/  "
Write-Output "                      |__|     "
Write-Output "                                      v2.1"
Write-Output "https://github.com/ltxhhz/loop"

function Remove-StartupRegistry {
    param (
        [string]$AppName
    )

    # 删除当前用户的启动项
    $regPathCurrentUser = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path "$regPathCurrentUser\$AppName") {
        Remove-ItemProperty -Path $regPathCurrentUser -Name $AppName
        Write-Output "已删除当前用户的启动项：$AppName"
    }

    # 删除所有用户的启动项
    $regPathAllUsers = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    if (Test-Path "$regPathAllUsers\$AppName") {
        Remove-ItemProperty -Path $regPathAllUsers -Name $AppName
        Write-Output "已删除所有用户的启动项：$AppName"
    }
}

function Remove-StartupShortcut {
    param (
        [string]$ShortcutName
    )

    $startupFolderCurrentUser = [System.IO.Path]::Combine($env:APPDATA, "Microsoft\Windows\Start Menu\Programs\Startup", $ShortcutName)
    if (Test-Path $startupFolderCurrentUser) {
        Remove-Item $startupFolderCurrentUser
        Write-Output "已删除当前用户启动文件夹中的快捷方式：$ShortcutName"
    }

    $startupFolderAllUsers = [System.IO.Path]::Combine("C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp", $ShortcutName)
    if (Test-Path $startupFolderAllUsers) {
        Remove-Item $startupFolderAllUsers
        Write-Output "已删除所有用户启动文件夹中的快捷方式：$ShortcutName"
    }
}

# 示例
# Remove-StartupRegistry -AppName "YourAppName"
# Remove-StartupShortcut -ShortcutName "YourAppShortcut.lnk"


if ($UACValue.ConsentPromptBehaviorAdmin -le 3) {
    Write-Output "UAC 已关闭，建议打开选择第二级（默认等级）"
    $openUAC = Read-Host "按1打开UAC设置，修改后重启电脑生效"
    if ($openUAC -eq 1) {
        Start-Process UserAccountControlSettings.exe
    }
}

Read-Host 按Enter开始检查


if (Test-Path "$sample0") {
    Write-Output "$sample0 存在"
    Stop-Process -Name rundll32 -Force
    Start-Sleep -Seconds 1
    Remove-Item -Recurse -Force "$sample0"
    Write-Output "$sample0 已删除"
    $restartFlag = $true
}
if (Test-Path "$sample1") {
    Write-Output "$sample1 存在"
    Stop-Process -Name AvastSvc.exe -Force
    Start-Sleep -Seconds 1
    Remove-Item -Recurse -Force "$sample1"
    Write-Output "$sample1 已删除"
    Remove-StartupRegistry -AppName "AvastSvcpCP"
    $restartFlag = $true
}

Write-Output 检查完成

if ($restartFlag) {
    try {
        New-ItemProperty -Path "Registry::HKCR\lnkfile" -Name "IsShortcut" -Value "" -PropertyType String -Force
        $inp = Read-Host "需要重启资源管理器，按1重启"
        if ($inp -eq 1) {
            Stop-Process -Name explorer -Force
            Start-Process explorer
        }
    }
    catch {
        Write-Output "注册表修改失败：$_"
    }
}

Write-Output 开始监听插入的盘，有问题的盘会自动被处理，在输出`"已处理`"之前，请等待

while ($true) {
    for ($i = 101; $i -lt 106; $i++) {
        [char]$letter = $i
        if ((Test-Path "${letter}:\*.lnk") -or (Test-Path "${letter}:\hypertrm*")) {
            Write-Host "盘${letter}: 发现 lnk 或 hypertrm"
            Set-Location "${letter}:"
            attrib -r -s -h * /s /d
            Start-Sleep -Milliseconds 200
            Remove-Item -Force -Recurse -ErrorAction SilentlyContinue *.lnk, hypertrm*, uk1337BA1, 49BA59ABBE56E057, '$RECYCLE.BIN'
            Write-Output $disk.DeviceID hypertrm 已处理
        }
        if ((Test-Path "${letter}:\ ")) { # 不间断空格 ascii 160
            Write-Host "盘${letter}: 发现 AvastSvc"
            Set-Location "${letter}:"
            attrib -r -s -h * /s /d
            # Move-Item "${letter}:\ \*" "${letter}:\" # 低版本ps不支持
            foreach ($item in $(Get-ChildItem "${letter}:\ \")) {
                cmd /c "move /y `"$($item.FullName)`" `"${letter}:\`""
            }
            cmd /c "rmdir `"${letter}:\ \`""
            Remove-Item -Force -Recurse 'RECYCLE.BIN'
            Write-Output $disk.DeviceID AvastSvc 已处理
        }
    }
    Start-Sleep -Seconds 1
}

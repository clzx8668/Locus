<#
.SYNOPSIS
  Locus PocketBase 一键部署脚本
.DESCRIPTION
  自动下载 PocketBase，创建管理员账号，生成启动脚本。
  PocketBase 会在 http://127.0.0.1:8090/_/ 提供管理界面。
.NOTES
  - 首次运行需要联网下载 PocketBase (~15MB)
  - 数据文件存储在 .\pb_data 目录，不会丢失
#>

param(
  [string]$Version = "0.27.4",
  [string]$AdminEmail = "admin@locus.local",
  [string]$AdminPassword = "Locus2024ChangeMe!"
)

$ErrorActionPreference = "Stop"
Set-Location (Split-Path $MyInvocation.MyCommand.Path -Parent)

$os = if ($env:OS -match "Windows") { "windows" } else { "linux" }
$arch = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "armv7" }
$zipName = "pocketbase_${Version}_${os}_${arch}.zip"
$zipUrl  = "https://github.com/pocketbase/pocketbase/releases/download/v${Version}/${zipName}"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Locus PocketBase 一键部署" -ForegroundColor Cyan
Write-Host "  Version: $Version  |  Platform: $os/$arch" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Download ──────────────────────────────────────────
if (Test-Path "pocketbase.exe") {
  Write-Host "[1/4] pocketbase.exe 已存在，跳过下载" -ForegroundColor Green
} else {
  Write-Host "[1/4] 下载 PocketBase v${Version} ..." -ForegroundColor Yellow
  try {
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipName -UseBasicParsing
  } catch {
    Write-Host "  Download failed. Trying with TLS 1.2..." -ForegroundColor Red
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipName -UseBasicParsing
  }

  Write-Host "  解压中..."
  Expand-Archive -Path $zipName -DestinationPath . -Force
  Remove-Item $zipName
  Write-Host "  Done: pocketbase.exe" -ForegroundColor Green
}

# ── Step 2: Create admin superuser (if not exists) ─────────────
Write-Host ""
Write-Host "[2/4] 创建管理员账号..." -ForegroundColor Yellow

# Start PocketBase as job for admin creation
$pb = Start-Process -FilePath ".\pocketbase.exe" -ArgumentList "serve","--http=127.0.0.1:8090" -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 3

try {
  $body = @{email=$AdminEmail;password=$AdminPassword;passwordConfirm=$AdminPassword} | ConvertTo-Json
  $resp = Invoke-RestMethod -Uri "http://127.0.0.1:8090/api/admins" -Method Post -Body $body -ContentType "application/json" -ErrorAction SilentlyContinue
  Write-Host "  Admin created: $AdminEmail" -ForegroundColor Green
} catch {
  if ($_.Exception.Message -match "409|already exists") {
    Write-Host "  Admin already exists: $AdminEmail (skip)" -ForegroundColor Green
  } else {
    Write-Host "  Admin creation skipped (may already exist or server not ready)" -ForegroundColor Yellow
  }
} finally {
  Stop-Process -Id $pb.Id -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 1
}

# ── Step 3: Generate startup script ────────────────────────────
Write-Host ""
Write-Host "[3/4] 生成启动脚本..." -ForegroundColor Yellow

$startBat = @"
@echo off
title Locus PocketBase Server
echo.
echo ========================================
echo   Locus PocketBase Server
echo   http://127.0.0.1:8090/_/
echo ========================================
echo.
echo Admin UI:  http://127.0.0.1:8090/_/
echo REST API:  http://127.0.0.1:8090/api/
echo.
echo Press Ctrl+C to stop
echo.
".\pocketbase.exe" serve --http=127.0.0.1:8090
pause
"@
Set-Content -Path "start_pocketbase.bat" -Value $startBat
Write-Host "  Created: start_pocketbase.bat" -ForegroundColor Green

# ── Step 4: Print summary ──────────────────────────────────────
Write-Host ""
Write-Host "[4/4] 部署完成！" -ForegroundColor Green
Write-Host ""
Write-Host "  ┌─────────────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "  │  启动方式：双击 `start_pocketbase.bat`              │" -ForegroundColor Cyan
Write-Host "  │  管理界面：http://127.0.0.1:8090/_/                │" -ForegroundColor Cyan
Write-Host "  │  管理员账号：$AdminEmail                           │" -ForegroundColor Cyan
Write-Host "  │  管理员密码：$AdminPassword                        │" -ForegroundColor Cyan
Write-Host "  │                                                     │" -ForegroundColor Cyan
Write-Host "  │  App 连接：Settings > PocketBase Sync               │" -ForegroundColor Cyan
Write-Host "  │          URL: http://127.0.0.1:8090                 │" -ForegroundColor Cyan
Write-Host "  │  （手机端请使用 PC 的局域网 IP）                   │" -ForegroundColor Cyan
Write-Host "  └─────────────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host ""

Read-Host "按 Enter 退出"

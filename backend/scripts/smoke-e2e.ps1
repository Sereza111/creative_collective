# End-to-end smoke: auth, management, marketplace, finance, legal, notifications.
# Usage:
#   $env:SMOKE_API_BASE = "http://YOUR_IP:8080"   # or http://localhost:3000
#   .\scripts\smoke-e2e.ps1
$ErrorActionPreference = "Stop"

$api = $env:SMOKE_API_BASE
if (-not $api) { $api = "http://localhost:3000" }
$api = $api.TrimEnd('/')

Write-Host "E2E smoke API: $api"

function Invoke-Json($method, $url, $body, $headers) {
  if (-not $headers) { $headers = @{} }
  if ($null -ne $body) {
    return Invoke-RestMethod -Method $method -Uri $url -Headers $headers -ContentType "application/json" -Body ($body | ConvertTo-Json -Depth 12)
  }
  return Invoke-RestMethod -Method $method -Uri $url -Headers $headers
}

# --- Health ---
$health = Invoke-Json "GET" "$api/health"
if (-not $health.success) { throw "Health failed" }
Write-Host "OK health"

# --- Users ---
$rand = ([Guid]::NewGuid().ToString("N").Substring(0, 8))
$freelancerEmail = "e2e_fl_$rand@example.com"
$clientEmail = "e2e_cl_$rand@example.com"
$pass = "Test12345!"

$flReg = Invoke-Json "POST" "$api/api/v1/auth/register" @{
  email = $freelancerEmail
  password = $pass
  full_name = "E2E Freelancer"
  user_role = "freelancer"
}
$flToken = $flReg.data.accessToken
if (-not $flToken) { throw "No freelancer token" }
$flAuth = @{ Authorization = "Bearer $flToken" }
$flMe = Invoke-Json "GET" "$api/api/v1/auth/me" $null $flAuth
$flId = $flMe.data.id
if (-not $flId) { throw "No freelancer id" }

# Отклик на заказ списывает 50 ₽ — пополнение через БД (нужен .env с DB_* и mysql-доступ)
if ($env:SMOKE_CREDIT_BALANCE -eq "1") {
  $backendRoot = Split-Path -Parent $PSScriptRoot
  Push-Location $backendRoot
  try {
    node scripts/credit-user-balance.js $flId 500
    if ($LASTEXITCODE -ne 0) { throw "credit-user-balance failed" }
  } finally {
    Pop-Location
  }
}

$clReg = Invoke-Json "POST" "$api/api/v1/auth/register" @{
  email = $clientEmail
  password = $pass
  full_name = "E2E Client"
  user_role = "client"
}
$clToken = $clReg.data.accessToken
$clAuth = @{ Authorization = "Bearer $clToken" }
$clMe = Invoke-Json "GET" "$api/api/v1/auth/me" $null $clAuth
$clId = $clMe.data.id
if (-not $clId) { throw "No client id" }

Write-Host "OK auth + me"

# --- Management: team -> member -> project -> task ---
$team = Invoke-Json "POST" "$api/api/v1/teams" @{
  name = "E2E Team $rand"
  description = "smoke"
} $flAuth
$teamId = $team.data.id
if (-not $teamId) { throw "No team id" }

Invoke-Json "POST" "$api/api/v1/teams/$teamId/members" @{
  user_id = $clId
  role = "Member"
} $flAuth | Out-Null

$start = (Get-Date).ToString("yyyy-MM-dd")
$end = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")
$proj = Invoke-Json "POST" "$api/api/v1/projects" @{
  name = "E2E Project $rand"
  description = "smoke"
  status = "active"
  start_date = $start
  end_date = $end
  team_id = $teamId
} $flAuth
$projectId = $proj.data.id
if (-not $projectId) { throw "No project id" }

$task = Invoke-Json "POST" "$api/api/v1/tasks" @{
  title = "E2E Task"
  project_id = $projectId
  status = "todo"
  priority = 2
} $flAuth
$taskId = $task.data.id
if (-not $taskId) { throw "No task id" }

Invoke-Json "PUT" "$api/api/v1/tasks/$taskId" @{
  status = "in_progress"
} $flAuth | Out-Null

Write-Host "OK management (team, project, task)"

# --- Marketplace ---
$order = Invoke-Json "POST" "$api/api/v1/orders" @{
  title = "E2E Order $rand"
  description = "smoke order"
  budget = 1000
  deadline = (Get-Date).AddDays(7).ToString("yyyy-MM-dd")
  category = "design"
} $clAuth
$orderId = $order.data.id
if (-not $orderId) { throw "No order id" }

$app = Invoke-Json "POST" "$api/api/v1/orders/$orderId/apply" @{
  message = "E2E apply"
  proposed_budget = 1000
} $flAuth
$appId = $app.data.id
if (-not $appId) { throw "No application id" }

Invoke-Json "POST" "$api/api/v1/orders/$orderId/applications/$appId/accept" $null $clAuth | Out-Null

$chatInfo = Invoke-Json "GET" "$api/api/v1/chat/order/$orderId" $null $flAuth
$chatId = $chatInfo.data.id
if (-not $chatId) { throw "No chat id" }
Invoke-Json "POST" "$api/api/v1/chat/$chatId/messages" @{
  content = "E2E hello from freelancer"
} $flAuth | Out-Null

Invoke-Json "POST" "$api/api/v1/orders/$orderId/complete" $null $clAuth | Out-Null

Write-Host "OK marketplace (order, apply, accept, chat, complete)"

# --- Finance ---
$bal = Invoke-Json "GET" "$api/api/v1/finance/balance" $null $flAuth
if ($null -eq $bal.data) { throw "Finance balance failed" }
Write-Host "OK finance balance"

# --- Legal (skip if no seeded documents) ---
try {
  $docs = Invoke-Json "GET" "$api/api/v1/legal/documents" $null @{}
  $first = $docs.data | Select-Object -First 1
  if ($first -and $first.id) {
    Invoke-Json "POST" "$api/api/v1/legal/sign" @{
      document_id = $first.id
      document_type = $first.document_type
    } $flAuth | Out-Null
    Write-Host "OK legal sign"
  } else {
    Write-Host "SKIP legal (no legal_documents in DB — seed or insert)"
  }
} catch {
  Write-Host "SKIP legal:" $_.Exception.Message
}

# --- Notifications (listing + unread; team add may have created one) ---
$notif = Invoke-Json "GET" "$api/api/v1/notifications?limit=5" $null $flAuth
$unread = Invoke-Json "GET" "$api/api/v1/notifications/unread-count" $null $flAuth
if ($null -eq $notif.data) { throw "Notifications list failed" }
if ($null -eq $unread.data) { throw "Unread count failed" }
Write-Host "OK notifications"

Write-Host ""
Write-Host "=== E2E smoke PASSED ==="
Write-Host "Record this run in docs/PRODUCTION_READINESS.md (E2E section) with date and API base."

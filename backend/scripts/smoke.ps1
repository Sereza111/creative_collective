$ErrorActionPreference = "Stop"

$api = $env:SMOKE_API_BASE
if (-not $api) { $api = "http://localhost:3000" }

Write-Host "Using API base: $api"

function Invoke-Json($method, $url, $body, $headers) {
  if (-not $headers) { $headers = @{} }
  if ($body) {
    return Invoke-RestMethod -Method $method -Uri $url -Headers $headers -ContentType "application/json" -Body ($body | ConvertTo-Json -Depth 10)
  }
  return Invoke-RestMethod -Method $method -Uri $url -Headers $headers
}

# 1) Health
$health = Invoke-Json "GET" "$api/health"
Write-Host "health:" ($health | ConvertTo-Json -Depth 10)
if (-not $health.success) { throw "Health failed" }

# 2) Register
$email = "smoke_" + ([Guid]::NewGuid().ToString("N").Substring(0,8)) + "@example.com"
$register = Invoke-Json "POST" "$api/api/v1/auth/register" @{
  email = $email
  password = "Test12345!"
  full_name = "Smoke Test"
  user_role = "freelancer"
}
Write-Host "register:" ($register | ConvertTo-Json -Depth 10)

$accessToken = $register.data.accessToken
if (-not $accessToken) { throw "No accessToken from register" }
$auth = @{ Authorization = "Bearer $accessToken" }

# 3) Me
$me = Invoke-Json "GET" "$api/api/v1/auth/me" $null $auth
Write-Host "me:" ($me | ConvertTo-Json -Depth 10)

# 4) Marketplace: create order as client (need client role)
# Switch role by registering a client user.
$clientEmail = "smoke_client_" + ([Guid]::NewGuid().ToString("N").Substring(0,8)) + "@example.com"
$clientReg = Invoke-Json "POST" "$api/api/v1/auth/register" @{
  email = $clientEmail
  password = "Test12345!"
  full_name = "Client Smoke"
  user_role = "client"
}
$clientToken = $clientReg.data.accessToken
$clientAuth = @{ Authorization = "Bearer $clientToken" }

$order = Invoke-Json "POST" "$api/api/v1/orders" @{
  title = "Smoke order"
  description = "Smoke description"
  budget = 1000
  deadline = (Get-Date).AddDays(7).ToString("yyyy-MM-dd")
  category = "design"
} $clientAuth
Write-Host "order:" ($order | ConvertTo-Json -Depth 10)

Write-Host "✅ Smoke OK"


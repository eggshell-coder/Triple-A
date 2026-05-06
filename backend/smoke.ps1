$API_URL = "https://triple-a-gkpq.onrender.com"

Write-Host "API URL: $API_URL"

# Optional login. This is only needed if you want the order linked to a customer user.
# If login fails, the script continues because /api/orders is public.
$TOKEN = $null

try {
  $loginBody = @{
    email    = "rinoyhasan5@gmail.com"
    password = "123456"
  } | ConvertTo-Json

  $login = Invoke-RestMethod -Method Post "$API_URL/api/auth/customer/login" `
    -Headers @{ "Content-Type" = "application/json" } `
    -Body $loginBody

  $TOKEN = $login.data.token
  Write-Host "Got token."
} catch {
  Write-Host "Login failed or skipped. Continuing without token."
}

# Get one valid product
$products = Invoke-RestMethod -Method Get "$API_URL/api/products?limit=1"

$PRODUCT_ID = $products.data[0].id
Write-Host "Using product: $PRODUCT_ID"
Write-Host "Product name: $($products.data[0].name)"

# Same key must be used for both requests
$IDEMPOTENCY_KEY = "smoke-test-$(Get-Date -UFormat %s)"
Write-Host "Using idempotency key: $IDEMPOTENCY_KEY"

$body = @{
  customer = @{
    full_name    = "Smoke Test User"
    phone        = "01700000000"
    district     = "Dhaka"
    upazila      = "Dhanmondi"
    address_line = "123 Test Street"
    email        = "smoke@test.com"
  }
  items = @(
    @{
      product_id = $PRODUCT_ID
      quantity   = 1
    }
  )
  delivery_charge = 60
  note = "Idempotency smoke test"
} | ConvertTo-Json -Depth 5

$headers = @{
  "Content-Type"    = "application/json"
  "Idempotency-Key" = $IDEMPOTENCY_KEY
}

if ($TOKEN) {
  $headers["Authorization"] = "Bearer $TOKEN"
}

Write-Host ""
Write-Host "Sending first order request..."

$first = Invoke-RestMethod -Method Post "$API_URL/api/orders" `
  -Headers $headers `
  -Body $body

Write-Host ""
Write-Host "Sending duplicate order request with same Idempotency-Key..."

$second = Invoke-RestMethod -Method Post "$API_URL/api/orders" `
  -Headers $headers `
  -Body $body

Write-Host ""
Write-Host "First response:"
$first | ConvertTo-Json -Depth 10

Write-Host ""
Write-Host "Second response:"
$second | ConvertTo-Json -Depth 10

$firstOrderId = $first.data.order_id
$secondOrderId = $second.data.order_id

$duplicateFlag = $second.duplicate
if ($null -eq $duplicateFlag) {
  $duplicateFlag = $second.data.duplicate
}

Write-Host ""
Write-Host "Idempotency check:"
Write-Host "First order_id: $firstOrderId"
Write-Host "Second order_id: $secondOrderId"
Write-Host "Second duplicate flag: $duplicateFlag"
Write-Host "Idempotency key: $IDEMPOTENCY_KEY"

if ($firstOrderId -eq $secondOrderId -and $duplicateFlag -eq $true) {
  Write-Host "PASS - same order_id and duplicate true"
} elseif ($firstOrderId -eq $secondOrderId) {
  Write-Host "PARTIAL PASS - same order_id, but duplicate flag is missing or false"
} else {
  Write-Host "FAIL - order_id mismatch"
}
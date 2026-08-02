# PocketBase Collection Initialization Script (v2)
# Run AFTER creating the superuser via web UI at http://127.0.0.1:8090/_/
param(
    [string]$Email = "admin@locus.local",
    [string]$Password = "Locus2024!"
)

$BaseUrl = "http://127.0.0.1:8090"
$ErrorActionPreference = "Continue"

Write-Host "=== Locus PocketBase Collection Setup ===" -ForegroundColor Cyan

# Step 1: Authenticate as admin
Write-Host "Authenticating as $Email..." -ForegroundColor Yellow
$authBody = @{ identity = $Email; password = $Password } | ConvertTo-Json
try {
    $auth = Invoke-RestMethod -Uri "$BaseUrl/api/collections/_superusers/auth-with-password" -Method Post -Body $authBody -ContentType "application/json"
    $token = $auth.token
    Write-Host "Authenticated!" -ForegroundColor Green
} catch {
    Write-Host "Auth failed: $_" -ForegroundColor Red
    Write-Host "Please create superuser first at: $BaseUrl/_/" -ForegroundColor Yellow
    exit 1
}

$headers = @{ Authorization = "Bearer $token"; "Content-Type" = "application/json" }

# Store created collection IDs
$collectionIds = @{}

function New-Collection {
    param($Name, $Body)
    Write-Host "Creating collection: $Name..." -ForegroundColor Yellow
    try {
        $result = Invoke-RestMethod -Uri "$BaseUrl/api/collections" -Method Post -Body $Body -Headers $headers
        $collectionIds[$Name] = $result.id
        Write-Host "  OK: $Name (id: $($result.id))" -ForegroundColor Green
        return $result.id
    } catch {
        $errText = "$_"
        # Handle "already exists" — any creation failure triggers fallback lookup
        if ($errText -match "(409|400)") {
            Write-Host "  SKIP: $Name already exists (fetching ID...)" -ForegroundColor Gray
            try {
                $existing = Invoke-RestMethod -Uri "$BaseUrl/api/collections" -Method Get -Headers $headers
                foreach ($col in $existing.items) {
                    if ($col.name -eq $Name) {
                        $collectionIds[$Name] = $col.id
                        Write-Host "  Found existing ID: $($col.id)" -ForegroundColor Green
                        return $col.id
                    }
                }
                Write-Host "  WARN: $Name not in existing collections" -ForegroundColor Yellow
            } catch {
                Write-Host "  WARN: Could not fetch existing ID for $Name" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  ERROR: $errText" -ForegroundColor Red
        }
    }
    return $null
}

function Add-Index {
    param($CollectionName, $FieldName)
    $colId = $collectionIds[$CollectionName]
    if (-not $colId) {
        Write-Host "  WARN: Cannot add index — $CollectionName not found" -ForegroundColor Yellow
        return
    }
    try {
        # Get current collection to read internal field IDs
        $col = Invoke-RestMethod -Uri "$BaseUrl/api/collections/$colId" -Method Get -Headers $headers
        
        # Build field name -> internal ID mapping
        $fieldMap = @{}
        foreach ($f in $col.fields) {
            $fieldMap[$f.name] = $f.id
        }
        
        # PocketBase uses the `name` property as the actual SQL column name,
        # not the `id` property (which is an internal GUID).
        # We just use the field name directly — it's the SQL column.
        $internalId = $FieldName
        if (-not $internalId) {
            Write-Host "    Skip: field '$FieldName' not found in $CollectionName" -ForegroundColor Yellow
            return
        }
        
        $indexName = "idx_${CollectionName}_${FieldName}"
        $indexSql = "CREATE INDEX $indexName ON $CollectionName($internalId)"
        
        # Append index to existing list
        if (-not $col.indexes) { $existingIndexes = @() } else { $existingIndexes = $col.indexes }
        $existingIndexes += $indexSql
        $updateBody = @{ indexes = $existingIndexes } | ConvertTo-Json
        Invoke-RestMethod -Uri "$BaseUrl/api/collections/$colId" -Method Patch -Body $updateBody -Headers $headers | Out-Null
        Write-Host "    Index: $indexName" -ForegroundColor Green
    } catch {
        Write-Host "    Index FAILED: $_" -ForegroundColor Red
    }
}

# =========================================
# 1. contacts
# =========================================
New-Collection "contacts" @'
{
  "name": "contacts",
  "type": "base",
  "fields": [
    {"name": "sync_uuid", "type": "text", "required": false},
    {"name": "sync_status", "type": "number", "required": false},
    {"name": "name", "type": "text", "required": true},
    {"name": "aliases", "type": "text", "required": false},
    {"name": "company", "type": "text", "required": false},
    {"name": "role", "type": "text", "required": false},
    {"name": "phone", "type": "text", "required": false},
    {"name": "email", "type": "text", "required": false},
    {"name": "tags", "type": "text", "required": false},
    {"name": "notes", "type": "text", "required": false},
    {"name": "avatar_path", "type": "text", "required": false},
    {"name": "is_deleted", "type": "bool", "required": true},
    {"name": "updated_at", "type": "text", "required": false}
  ]
}
'@
Add-Index "contacts" "sync_uuid"
Add-Index "contacts" "company"
Add-Index "contacts" "name"

# =========================================
# 2. deals
# =========================================
New-Collection "deals" @'
{
  "name": "deals",
  "type": "base",
  "fields": [
    {"name": "sync_uuid", "type": "text", "required": false},
    {"name": "sync_status", "type": "number", "required": false},
    {"name": "contact_id", "type": "text", "required": true},
    {"name": "title", "type": "text", "required": true},
    {"name": "stage", "type": "text", "required": false},
    {"name": "value", "type": "number", "required": false},
    {"name": "probability", "type": "number", "required": false},
    {"name": "expected_close_date", "type": "date", "required": false},
    {"name": "notes", "type": "text", "required": false},
    {"name": "is_deleted", "type": "bool", "required": true},
    {"name": "updated_at", "type": "text", "required": false}
  ]
}
'@
Add-Index "deals" "sync_uuid"
Add-Index "deals" "contact_id"
Add-Index "deals" "stage"

# =========================================
# 3. activities
# =========================================
New-Collection "activities" @'
{
  "name": "activities",
  "type": "base",
  "fields": [
    {"name": "sync_uuid", "type": "text", "required": false},
    {"name": "sync_status", "type": "number", "required": false},
    {"name": "contact_id", "type": "text", "required": true},
    {"name": "deal_id", "type": "text", "required": false},
    {"name": "type", "type": "text", "required": true},
    {"name": "content", "type": "text", "required": true},
    {"name": "media_paths", "type": "text", "required": false},
    {"name": "is_deleted", "type": "bool", "required": true},
    {"name": "updated_at", "type": "text", "required": false}
  ]
}
'@
Add-Index "activities" "sync_uuid"
Add-Index "activities" "contact_id"

# =========================================
# 4. tasks
# =========================================
New-Collection "tasks" @'
{
  "name": "tasks",
  "type": "base",
  "fields": [
    {"name": "sync_uuid", "type": "text", "required": false},
    {"name": "sync_status", "type": "number", "required": false},
    {"name": "title", "type": "text", "required": true},
    {"name": "contact_id", "type": "text", "required": false},
    {"name": "deal_id", "type": "text", "required": false},
    {"name": "due_date", "type": "date", "required": false},
    {"name": "priority", "type": "number", "required": false},
    {"name": "status", "type": "text", "required": false},
    {"name": "source_text", "type": "text", "required": false},
    {"name": "is_deleted", "type": "bool", "required": true},
    {"name": "updated_at", "type": "text", "required": false}
  ]
}
'@
Add-Index "tasks" "sync_uuid"
Add-Index "tasks" "status"
Add-Index "tasks" "due_date"

# =========================================
# 5. products
# =========================================
New-Collection "products" @'
{
  "name": "products",
  "type": "base",
  "fields": [
    {"name": "sync_uuid", "type": "text", "required": false},
    {"name": "sync_status", "type": "number", "required": false},
    {"name": "name", "type": "text", "required": true},
    {"name": "category", "type": "text", "required": false},
    {"name": "specs", "type": "text", "required": false},
    {"name": "unit_price", "type": "number", "required": false},
    {"name": "notes", "type": "text", "required": false},
    {"name": "is_deleted", "type": "bool", "required": true},
    {"name": "updated_at", "type": "text", "required": false}
  ]
}
'@
Add-Index "products" "sync_uuid"
Add-Index "products" "category"

# =========================================
# 6. hub_payloads
# =========================================
New-Collection "hub_payloads" @'
{
  "name": "hub_payloads",
  "type": "base",
  "fields": [
    {"name": "sync_uuid", "type": "text", "required": false},
    {"name": "sync_status", "type": "number", "required": false},
    {"name": "raw_text", "type": "text", "required": true},
    {"name": "media_paths", "type": "text", "required": false},
    {"name": "intent_tag", "type": "text", "required": false},
    {"name": "is_deleted", "type": "bool", "required": true},
    {"name": "updated_at", "type": "text", "required": false}
  ]
}
'@
Add-Index "hub_payloads" "sync_uuid"
Add-Index "hub_payloads" "intent_tag"

# =========================================
# 7. chat_sessions
# =========================================
New-Collection "chat_sessions" @'
{
  "name": "chat_sessions",
  "type": "base",
  "fields": [
    {"name": "sync_uuid", "type": "text", "required": false},
    {"name": "sync_status", "type": "number", "required": false},
    {"name": "title", "type": "text", "required": true},
    {"name": "is_deleted", "type": "bool", "required": true},
    {"name": "updated_at", "type": "text", "required": false}
  ]
}
'@
Add-Index "chat_sessions" "sync_uuid"

# =========================================
# 8. chat_messages
# =========================================
New-Collection "chat_messages" @'
{
  "name": "chat_messages",
  "type": "base",
  "fields": [
    {"name": "sync_uuid", "type": "text", "required": false},
    {"name": "sync_status", "type": "number", "required": false},
    {"name": "session_id", "type": "text", "required": true},
    {"name": "role", "type": "text", "required": true},
    {"name": "content", "type": "text", "required": true},
    {"name": "is_deleted", "type": "bool", "required": true},
    {"name": "updated_at", "type": "text", "required": false}
  ]
}
'@
Add-Index "chat_messages" "sync_uuid"
Add-Index "chat_messages" "session_id"

# =========================================
# 9. long_term_memories
# =========================================
New-Collection "long_term_memories" @'
{
  "name": "long_term_memories",
  "type": "base",
  "fields": [
    {"name": "sync_uuid", "type": "text", "required": false},
    {"name": "sync_status", "type": "number", "required": false},
    {"name": "content", "type": "text", "required": true},
    {"name": "tags", "type": "text", "required": false},
    {"name": "is_deleted", "type": "bool", "required": true},
    {"name": "updated_at", "type": "text", "required": false}
  ]
}
'@
Add-Index "long_term_memories" "sync_uuid"

# =========================================
# 10. knowledge_files
# =========================================
New-Collection "knowledge_files" @'
{
  "name": "knowledge_files",
  "type": "base",
  "fields": [
    {"name": "sync_uuid", "type": "text", "required": false},
    {"name": "sync_status", "type": "number", "required": false},
    {"name": "name", "type": "text", "required": true},
    {"name": "local_path", "type": "text", "required": true},
    {"name": "size", "type": "number", "required": true},
    {"name": "extension", "type": "text", "required": true},
    {"name": "is_active", "type": "bool", "required": true},
    {"name": "is_deleted", "type": "bool", "required": true},
    {"name": "updated_at", "type": "text", "required": false}
  ]
}
'@
Add-Index "knowledge_files" "sync_uuid"

Write-Host ""
Write-Host "=== All collections and indexes created! ===" -ForegroundColor Cyan
Write-Host "Dashboard: $BaseUrl/_/" -ForegroundColor Green

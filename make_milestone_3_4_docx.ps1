# make_milestone_3_4_docx.ps1 - Generates 100% valid, strict OpenXML DOCX for Milestone 3 & 4
$ErrorActionPreference = "Stop"

$workspace = "C:\xampp\htdocs\netusage-monitoring"
$outputDocx = "$workspace\MILESTONE_3_AND_4_DOCUMENTATION.docx"
$publicDocx = "$workspace\public\MILESTONE_3_AND_4_DOCUMENTATION.docx"
$tempDir = "$workspace\temp_m34_build"

if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir }
if (Test-Path $outputDocx) { Remove-Item -Force $outputDocx }
if (Test-Path $publicDocx) { Remove-Item -Force $publicDocx }

New-Item -ItemType Directory -Path "$tempDir\_rels" | Out-Null
New-Item -ItemType Directory -Path "$tempDir\word\_rels" | Out-Null

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# 1. [Content_Types].xml
$contentTypes = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>
'@
[System.IO.File]::WriteAllText("$tempDir\[Content_Types].xml", $contentTypes, $utf8NoBom)

# 2. _rels/.rels
$rels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
'@
[System.IO.File]::WriteAllText("$tempDir\_rels\.rels", $rels, $utf8NoBom)

# 3. word/_rels/document.xml.rels
$docRels = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
'@
[System.IO.File]::WriteAllText("$tempDir\word\_rels\document.xml.rels", $docRels, $utf8NoBom)

# 4. word/styles.xml
$styles = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" w:cs="Times New Roman"/>
        <w:sz w:val="24"/>
        <w:szCs w:val="24"/>
        <w:lang w:val="en-US"/>
      </w:rPr>
    </w:rPrDefault>
    <w:pPrDefault>
      <w:pPr>
        <w:spacing w:line="360" w:lineRule="auto" w:after="160"/>
      </w:pPr>
    </w:pPrDefault>
  </w:docDefaults>
</w:styles>
'@
[System.IO.File]::WriteAllText("$tempDir\word\styles.xml", $styles, $utf8NoBom)

# 5. Build word/document.xml
$sb = New-Object System.Text.StringBuilder

[void]$sb.Append(@'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
'@)

function Escape-Xml([string]$text) {
    if ([string]::IsNullOrEmpty($text)) { return "" }
    return [System.Security.SecurityElement]::Escape($text)
}

function Add-P([string]$text, [string]$align = "both", [bool]$bold = $false, [int]$size = 24, [string]$font = "Times New Roman", [int]$spaceBefore = 0, [int]$spaceAfter = 160) {
    $esc = Escape-Xml $text
    $bTag = if ($bold) { "<w:b/>" } else { "" }
    $p = "<w:p><w:pPr><w:jc w:val=`"$align`"/><w:spacing w:before=`"$spaceBefore`" w:after=`"$spaceAfter`" w:line=`"360`" w:lineRule=`"auto`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"$font`" w:hAnsi=`"$font`"/><w:sz w:val=`"$size`"/><w:szCs w:val=`"$size`"/>$bTag</w:rPr><w:t xml:space=`"preserve`">$esc</w:t></w:r></w:p>"
    [void]$sb.Append($p)
}

function Add-PageBreak {
    [void]$sb.Append('<w:p><w:r><w:br w:type="page"/></w:r></w:p>')
}

function Add-Heading1([string]$text) {
    Add-P -text $text -align "center" -bold $true -size 32 -font "Arial" -spaceBefore 360 -spaceAfter 200
}

function Add-Heading2([string]$text) {
    Add-P -text $text -align "left" -bold $true -size 28 -font "Arial" -spaceBefore 280 -spaceAfter 140
}

function Add-Heading3([string]$text) {
    Add-P -text $text -align "left" -bold $true -size 24 -font "Arial" -spaceBefore 200 -spaceAfter 100
}

function Add-Caption([string]$text) {
    Add-P -text $text -align "center" -bold $true -size 20 -font "Arial" -spaceBefore 80 -spaceAfter 200
}

function Add-Code([string]$code) {
    $lines = $code -split "`r?`n"
    foreach ($l in $lines) {
        $esc = Escape-Xml $l
        $p = "<w:p><w:pPr><w:pBdr><w:left w:val=`"single`" w:sz=`"12`" w:space=`"4`" w:color=`"0D6EFD`"/></w:pBdr><w:shd w:val=`"clear`" w:color=`"auto`" w:fill=`"F4F6F8`"/><w:spacing w:before=`"0`" w:after=`"40`" w:line=`"240`" w:lineRule=`"auto`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"Consolas`" w:hAnsi=`"Consolas`"/><w:sz w:val=`"19`"/><w:szCs w:val=`"19`"/></w:rPr><w:t xml:space=`"preserve`">$esc</w:t></w:r></w:p>"
        [void]$sb.Append($p)
    }
}

function Add-TableRows($headers, $rows) {
    [void]$sb.Append('<w:tbl><w:tblPr><w:tblW w:w="5000" w:type="pct"/><w:tblBorders><w:top w:val="single" w:sz="6" w:space="0" w:color="000000"/><w:left w:val="single" w:sz="6" w:space="0" w:color="000000"/><w:bottom w:val="single" w:sz="6" w:space="0" w:color="000000"/><w:right w:val="single" w:sz="6" w:space="0" w:color="000000"/><w:insideH w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/><w:insideV w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/></w:tblBorders></w:tblPr>')
    
    # Header Row
    [void]$sb.Append('<w:tr><w:trPr><w:tblHeader/></w:trPr>')
    foreach ($h in $headers) {
        $eh = Escape-Xml $h
        [void]$sb.Append("<w:tc><w:tcPr><w:shd w:val=`"clear`" w:color=`"auto`" w:fill=`"E8EFF8`"/></w:tcPr><w:p><w:pPr><w:jc w:val=`"left`"/><w:spacing w:before=`"80`" w:after=`"80`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"Arial`" w:hAnsi=`"Arial`"/><w:b/><w:sz w:val=`"21`"/></w:rPr><w:t>$eh</w:t></w:r></w:p></w:tc>")
    }
    [void]$sb.Append('</w:tr>')

    # Data Rows
    foreach ($row in $rows) {
        [void]$sb.Append('<w:tr>')
        foreach ($cell in $row) {
            $ec = Escape-Xml $cell
            [void]$sb.Append("<w:tc><w:tcPr><w:shd w:val=`"clear`" w:color=`"auto`" w:fill=`"FFFFFF`"/></w:tcPr><w:p><w:pPr><w:jc w:val=`"left`"/><w:spacing w:before=`"60`" w:after=`"60`"/></w:pPr><w:r><w:rPr><w:rFonts w:ascii=`"Times New Roman`" w:hAnsi=`"Times New Roman`"/><w:sz w:val=`"21`"/></w:rPr><w:t>$ec</w:t></w:r></w:p></w:tc>")
        }
        [void]$sb.Append('</w:tr>')
    }

    [void]$sb.Append('</w:tbl><w:p><w:pPr><w:spacing w:after="160"/></w:pPr></w:p>')
}

# ----------------- COVER PAGE -----------------
Add-P -text "ZETECH UNIVERSITY" -align "center" -bold $true -size 40 -font "Arial" -spaceBefore 600 -spaceAfter 80
Add-P -text "Inventing the future" -align "center" -bold $false -size 24 -font "Arial" -spaceBefore 0 -spaceAfter 1000
Add-P -text "NETWORK USAGE MONITORING SYSTEM (NETUSAGE HUB)" -align "center" -bold $true -size 34 -font "Arial" -spaceBefore 0 -spaceAfter 120
Add-P -text "MILESTONE 3 & 4: SYSTEM IMPLEMENTATION, TESTING, DEPLOYMENT, CONCLUSION & RECOMMENDATIONS" -align "center" -bold $true -size 26 -font "Arial" -spaceBefore 0 -spaceAfter 1200
Add-P -text "SUBMITTED BY:" -align "center" -bold $true -size 24 -font "Times New Roman" -spaceBefore 0 -spaceAfter 100
Add-P -text "Brenda Chebet Chelule" -align "center" -bold $true -size 26 -font "Times New Roman" -spaceBefore 0 -spaceAfter 60
Add-P -text "Registration Number: DCS-01-0892/2024" -align "center" -bold $false -size 24 -font "Times New Roman" -spaceBefore 0 -spaceAfter 1000
Add-P -text "A PROJECT DOCUMENTATION SUBMITTED IN PARTIAL FULFILMENT FOR THE AWARD OF DIPLOMA IN COMPUTER SCIENCE BY ZETECH UNIVERSITY" -align "center" -bold $false -size 22 -font "Times New Roman" -spaceBefore 0 -spaceAfter 1000
Add-P -text "AUGUST 2026" -align "center" -bold $true -size 26 -font "Times New Roman" -spaceBefore 0 -spaceAfter 200

Add-PageBreak

# ----------------- TABLE OF CONTENTS -----------------
Add-Heading1 "TABLE OF CONTENTS"
$tocItems = @(
    @("1. MILESTONE 3: CHAPTER THREE - SYSTEM IMPLEMENTATION", "1"),
    @("  1.1. Introduction", "1"),
    @("  1.2. User Interface Development", "1"),
    @("    1.2.1. Login Page Development", "1"),
    @("    1.2.2. Dashboard Overview", "2"),
    @("    1.2.3. Navigation Bar", "3"),
    @("    1.2.4. Inventory / Device Control Center", "4"),
    @("    1.2.5. Add New Device Form", "5"),
    @("    1.2.6. Real-Time Transaction Metric Logs", "6"),
    @("    1.2.7. Business Usage Reports", "7"),
    @("  1.3. Logic Development", "8"),
    @("    1.3.1. Authentication & Session Management", "8"),
    @("    1.3.2. Dashboard Metrics Aggregation", "9"),
    @("    1.3.3. Inventory Management & Threshold Rules", "10"),
    @("    1.3.4. Transaction Logging & Analytical Reports", "11"),
    @("  1.4. System Testing", "12"),
    @("  1.5. Deployment", "13"),
    @("2. MILESTONE 4: CHAPTER FOUR - CONCLUSION AND RECOMMENDATION", "14"),
    @("  2.1. Conclusion", "14"),
    @("  2.2. Recommendation", "14"),
    @("3. REFERENCES", "15")
)
Add-TableRows @("Section", "Page") $tocItems

Add-PageBreak

# ----------------- CHAPTER THREE (MILESTONE 3) -----------------
Add-Heading1 "MILESTONE 3: CHAPTER THREE — SYSTEM IMPLEMENTATION"

Add-Heading2 "3.1 Introduction"
Add-P -text "This chapter details the actual implementation of the NetUsage Hub Network Usage Monitoring System, bridging the architectural designs and modeling artifacts from Milestone 2 into a functional, resilient, and responsive web application. Development followed a clean architectural model separating relational schema management, backend controller scripts, secure session handling, and template presentation."
Add-P -text "The application utilizes PHP 8 with PDO (PHP Data Objects) for database transactions, MySQL for relational persistence, and HTML5, CSS3, JavaScript, and Bootstrap 5 for a responsive, modern interface. The following sections walk through each user interface component, the underlying backend logic, comprehensive unit and acceptance testing, and production deployment considerations."

Add-Heading2 "3.2 User Interface Development"

Add-Heading3 "3.2.1 Login Page Development"
Add-P -text "The login page provides a clean, vertically and horizontally centered authentication portal styled with modern card borders, soft background tones, and responsive form controls. The interface displays error flash messages when invalid credentials are provided and protects against unauthorized access."

$loginCode = @'
<!-- Login Form Implementation (public/index.php) -->
<form action="index.php" method="POST">
    <input type="hidden" name="csrf" value="<?= csrf_token() ?>">

    <div class="mb-3">
        <label class="form-label small text-muted mb-1">Username</label>
        <div class="input-group">
            <span class="input-group-text bg-light border-end-0">
                <i class="fa fa-user text-muted"></i>
            </span>
            <input type="text" name="username" class="form-control border-start-0 bg-light" 
                   placeholder="Enter username" required autofocus>
        </div>
    </div>

    <div class="mb-4">
        <label class="form-label small text-muted mb-1">Password</label>
        <div class="input-group">
            <span class="input-group-text bg-light border-end-0">
                <i class="fa fa-lock text-muted"></i>
            </span>
            <input type="password" name="password" class="form-control border-start-0 bg-light" 
                   placeholder="Enter password" required>
        </div>
    </div>

    <div class="d-grid">
        <button type="submit" class="btn btn-primary py-2 fw-semibold">Sign In</button>
    </div>
</form>
'@
Add-Code $loginCode
Add-Caption "Figure 3.2.1: Login Page Interface Implementation"

Add-Heading3 "3.2.2 Dashboard Overview"
Add-P -text "The dashboard provides an operational summary of network health. The top statistics row highlights Total Inventory, Threshold Alerts, and Today's Total Traffic in Megabytes. Monitored infrastructure devices are presented below with real-time status badges (online/offline) and action triggers."

$dashCode = @'
<!-- Dashboard Top KPI Cards (public/dashboard.php) -->
<div class="row g-4 mb-5">
    <div class="col-12 col-md-4">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body p-4 text-center">
                <div class="mb-2 text-primary opacity-75"><i class="fa fa-server fa-2x"></i></div>
                <h6 class="text-muted text-uppercase mb-1 text-primary" style="font-size:0.72rem;">Total Inventory</h6>
                <h3 class="fw-bold mb-0 text-dark"><?= $stats['devices'] ?></h3>
            </div>
        </div>
    </div>
    <div class="col-12 col-md-4">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body p-4 text-center">
                <div class="mb-2 <?= $stats['alerts'] > 0 ? 'text-danger' : 'text-success' ?> opacity-75">
                    <i class="fa fa-exclamation-triangle fa-2x"></i>
                </div>
                <h6 class="text-muted text-uppercase mb-1" style="font-size:0.72rem;">Threshold Alerts</h6>
                <h3 class="fw-bold mb-0 <?= $stats['alerts'] > 0 ? 'text-danger' : 'text-success' ?>"><?= $stats['alerts'] ?></h3>
            </div>
        </div>
    </div>
    <div class="col-12 col-md-4">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body p-4 text-center">
                <div class="mb-2 text-success opacity-75"><i class="fa fa-bar-chart fa-2x"></i></div>
                <h6 class="text-muted text-uppercase mb-1" style="font-size:0.72rem;">Today's Traffic</h6>
                <h3 class="fw-bold mb-0 text-success"><?= number_format($stats['today_mb'], 1) ?> MB</h3>
            </div>
        </div>
    </div>
</div>
'@
Add-Code $dashCode
Add-Caption "Figure 3.2.2: Dashboard Overview KPI Cards"

Add-Heading3 "3.2.3 Navigation Bar"
Add-P -text "The sticky navigation bar provides instant access to Dashboard, Inventory (Devices), Usage Metrics, Alerts, and Reports. It features real-time search filtering by device name, IP address, and location."

$navCode = @'
<!-- Sticky Header & Navigation Bar (includes/header.php) -->
<nav class="navbar navbar-expand-lg navbar-white bg-white border-bottom sticky-top py-2">
    <div class="container-fluid px-4">
        <a class="navbar-brand fw-bold d-flex align-items-center" href="dashboard.php">
            <span class="brand-badge me-2"><i class="fa fa-wifi text-primary"></i></span>
            <span class="text-dark">Net-</span><span class="text-primary">Portal</span>
        </a>
        <div class="collapse navbar-collapse" id="navbarContent">
            <ul class="navbar-nav me-auto mb-2 mb-lg-0 fw-semibold ms-3">
                <li class="nav-item"><a class="nav-link active text-primary" href="dashboard.php">Dashboard</a></li>
                <li class="nav-item"><a class="nav-link" href="devices.php">Devices</a></li>
                <li class="nav-item"><a class="nav-link" href="metrics.php">Usage Metrics</a></li>
                <li class="nav-item"><a class="nav-link" href="alerts.php">Alerts</a></li>
                <li class="nav-item"><a class="nav-link" href="reports.php">Reports</a></li>
            </ul>
        </div>
    </div>
</nav>
'@
Add-Code $navCode
Add-Caption "Figure 3.2.3: Sticky Navigation Bar Component"

Add-Heading3 "3.2.4 Inventory / Device Control Center"
Add-P -text "The inventory module uses a split 9-column and 3-column layout: the primary table lists all hardware inventory with quota allocations, while the sidebar card highlights devices currently breaching their threshold quotas."

$invCode = @'
<!-- Table & Sidebar Layout (public/devices.php) -->
<div class="row">
    <div class="col-lg-9 mb-4">
        <div class="card shadow-sm border-0">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-dark">
                    <tr>
                        <th class="ps-3">Device Info</th>
                        <th>IP Address</th>
                        <th>Bandwidth Limits</th>
                        <th>Stock/Status</th>
                        <th>Category</th>
                        <th class="text-center">Action</th>
                    </tr>
                </thead>
                <tbody><!-- Dynamic rows --></tbody>
            </table>
        </div>
    </div>
    <div class="col-lg-3">
        <div class="card shadow-sm border-0 position-sticky" style="top: 80px;">
            <div class="card-header bg-danger text-white fw-bold">
                <i class="fa fa-bell me-1"></i> Threshold Alerts
            </div>
            <div class="card-body p-0"><!-- Dynamic alerts --></div>
        </div>
    </div>
</div>
'@
Add-Code $invCode
Add-Caption "Figure 3.2.4: Inventory Control Center Interface"

Add-Heading3 "3.2.5 Add New Device Form"
Add-P -text "The device creation form allows administrators to register new networking equipment with configured bandwidth thresholds (download limit MB and upload limit MB), category selection, and physical location tags."

$addDevCode = @'
<!-- Add / Edit Device Card Form (public/devices.php) -->
<div class="card border-0 shadow-sm" id="add-device-card">
    <div class="card-header bg-white border-bottom p-3">
        <h5 class="mb-0 fw-bold"><i class="fa fa-plus-circle me-2 text-primary"></i>New Device</h5>
    </div>
    <div class="card-body p-4">
        <form action="devices.php" method="POST">
            <input type="hidden" name="csrf" value="<?= csrf_token() ?>">
            <input type="hidden" name="action" value="save">
            <div class="mb-3">
                <label class="form-label small text-muted mb-1">Device Name</label>
                <input type="text" name="name" class="form-control form-control-sm" required>
            </div>
            <div class="row g-2 mb-3">
                <div class="col-6">
                    <label class="form-label small text-muted mb-1">IP Address</label>
                    <input type="text" name="ip_address" class="form-control form-control-sm" required>
                </div>
                <div class="col-6">
                    <label class="form-label small text-muted mb-1">Location / NOC</label>
                    <input type="text" name="location" class="form-control form-control-sm">
                </div>
            </div>
            <button type="submit" class="btn btn-primary btn-sm w-100 py-2 fw-semibold">Add Device to Inventory</button>
        </form>
    </div>
</div>
'@
Add-Code $addDevCode
Add-Caption "Figure 3.2.5: Add New Device Card Interface"

Add-Heading3 "3.2.6 Real-Time Transaction Metric Logs"
Add-P -text "The transaction log interface records every telemetry reading. On desktop screens, it displays timestamped rows with download, upload, latency, packet loss, and total bandwidth. On mobile screens, records reflow into clean cards."

$metricCode = @'
<!-- Real-Time Transaction Logs Table (public/metrics.php) -->
<table class="table table-hover align-middle mb-0">
    <thead class="table-dark">
        <tr>
            <th class="ps-3">Time</th>
            <th>Device Name & IP</th>
            <th class="text-center">Download (MB)</th>
            <th class="text-center">Upload (MB)</th>
            <th class="text-center">Latency / Loss</th>
            <th class="text-end pe-3">Total Bandwidth</th>
        </tr>
    </thead>
    <tbody>
        <!-- Metric rows with date and latency formatting -->
    </tbody>
</table>
'@
Add-Code $metricCode
Add-Caption "Figure 3.2.6: Real-Time Transaction Metric Logs Table"

Add-Heading3 "3.2.7 Business Usage Reports"
Add-P -text "The analytical reports interface aggregates network consumption, displays top bandwidth-consuming hardware, and enables administrators to export CSV spreadsheets for management review."

$repCode = @'
<!-- Business Usage Reports Summary Row (public/reports.php) -->
<div class="row mb-4">
    <div class="col-md-4 mb-4">
        <div class="card border-0 shadow-sm h-100 text-center py-4">
            <h6 class="text-muted text-uppercase mb-1">Total Bandwidth Monitored</h6>
            <h3 class="fw-bold mb-0 text-success"><?= number_format($totalBandwidth, 1) ?> MB</h3>
        </div>
    </div>
    <div class="col-md-8 mb-4">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-header bg-white border-bottom p-3">
                <h5 class="mb-0 fw-bold">Top Bandwidth Devices</h5>
            </div>
            <div class="card-body p-0"><!-- Top device rows --></div>
        </div>
    </div>
</div>
'@
Add-Code $repCode
Add-Caption "Figure 3.2.7: Business Usage Reports Summary View"

Add-Heading2 "3.3 Logic Development"

Add-Heading3 "3.3.1 Login Authentication & Session Management"
Add-P -text "Authentication uses PHP PDO with prepared statements, verifying passwords using password_verify() with BCRYPT hashing. Session IDs are regenerated upon successful authentication to guard against session fixation attacks."

$phpLogin = @'
function attempt_login(string $username, string $password): bool {
    $stmt = db()->prepare('SELECT * FROM users WHERE username = ? LIMIT 1');
    $stmt->execute([$username]);
    $record = $stmt->fetch();
    
    if ($record && password_verify($password, $record['password_hash'])) {
        session_regenerate_id(true);
        $_SESSION['user'] = [
            'id' => $record['id'],
            'username' => $record['username'],
            'full_name' => $record['full_name'],
            'role' => $record['role']
        ];
        return true;
    }
    return false;
}
'@
Add-Code $phpLogin
Add-Caption "Figure 3.3.1: PHP User Authentication Function Implemented via PDO"

Add-Heading3 "3.3.2 Dashboard Aggregation Logic"
Add-P -text "The dashboard controller queries database aggregate functions to calculate active hardware counts, unresolved incident alerts, and today's total bandwidth traffic."

$phpDash = @'
$stats = [
    'devices'  => (int)db()->query('SELECT COUNT(*) FROM devices')->fetchColumn(),
    'online'   => (int)db()->query("SELECT COUNT(*) FROM devices WHERE status='online'")->fetchColumn(),
    'alerts'   => (int)db()->query('SELECT COUNT(*) FROM alerts WHERE is_resolved=0')->fetchColumn(),
    'today_mb' => (float)db()->query('SELECT COALESCE(SUM(download_mb + upload_mb), 0) FROM usage_metrics WHERE DATE(recorded_at) = CURDATE()')->fetchColumn()
];

$devices = db()->query('SELECT d.*, 
    (SELECT COALESCE(SUM(download_mb + upload_mb), 0) FROM usage_metrics m 
     WHERE m.device_id = d.id AND m.recorded_at >= NOW() - INTERVAL 24 HOUR) AS usage_mb 
    FROM devices d ORDER BY d.id DESC LIMIT 8')->fetchAll();
'@
Add-Code $phpDash
Add-Caption "Figure 3.3.2: Dashboard Metric Aggregation Logic"

Add-Heading3 "3.3.3 Device Inventory Management & Threshold Checking"
Add-P -text "Whenever telemetry data is entered, an automated threshold rule evaluates whether download or upload consumption breaches configured caps, automatically inserting high-severity alerts into the alerts table."

$phpInv = @'
$pdo = db();
$pdo->beginTransaction();

$stmt = $pdo->prepare('INSERT INTO usage_metrics (device_id, download_mb, upload_mb, latency_ms, packet_loss_percent) VALUES (?, ?, ?, ?, ?)');
$stmt->execute([$device, $download, $upload, $latency, $loss]);
$metricId = $pdo->lastInsertId();

$dStmt = $pdo->prepare('SELECT * FROM devices WHERE id = ?');
$dStmt->execute([$device]);
$dev = $dStmt->fetch();

if ($dev && $download > $dev['download_limit_mb']) {
    $pdo->prepare('INSERT INTO alerts (device_id, metric_id, alert_type, message, severity) VALUES (?, ?, ?, ?, ?)')
        ->execute([$device, $metricId, 'download_limit', "Download traffic ({$download} MB) exceeded cap", 'critical']);
}
if ($dev && $upload > $dev['upload_limit_mb']) {
    $pdo->prepare('INSERT INTO alerts (device_id, metric_id, alert_type, message, severity) VALUES (?, ?, ?, ?, ?)')
        ->execute([$device, $metricId, 'upload_limit', "Upload traffic ({$upload} MB) exceeded cap", 'warning']);
}

$pdo->prepare("UPDATE devices SET status = 'online', last_seen = NOW() WHERE id = ?")->execute([$device]);
$pdo->commit();
'@
Add-Code $phpInv
Add-Caption "Figure 3.3.3: Inventory CRUD and Threshold Evaluation Script"

Add-Heading3 "3.3.4 Transaction Logging & Analytical Reporting"
Add-P -text "The reporting engine aggregates bandwidth consumption across arbitrary date ranges and streams RFC 4180-compliant CSV files directly to the browser for offline auditing."

$phpRep = @'
$stmtTop = db()->prepare('SELECT d.name, SUM(m.download_mb + m.upload_mb) AS total_mb 
    FROM usage_metrics m JOIN devices d ON d.id = m.device_id 
    WHERE m.recorded_at BETWEEN ? AND ? 
    GROUP BY d.id ORDER BY total_mb DESC LIMIT 5');
$stmtTop->execute([$from . ' 00:00:00', $to . ' 23:59:59']);
$topDevices = $stmtTop->fetchAll();

if (isset($_GET['export'])) {
    header('Content-Type: text/csv; charset=utf-8');
    header('Content-Disposition: attachment; filename="netusage-report.csv"');
    $out = fopen('php://output', 'w');
    fputcsv($out, ['Date', 'Device', 'Download MB', 'Upload MB', 'Total MB', 'Avg Latency ms', 'Avg Loss %']);
    foreach ($rows as $r) {
        fputcsv($out, [$r['day'], $r['device_name'], $r['download_mb'], $r['upload_mb'], $r['download_mb'] + $r['upload_mb'], $r['latency_ms'], $r['packet_loss']]);
    }
    exit;
}
'@
Add-Code $phpRep
Add-Caption "Figure 3.3.4: Analytical Reporting Queries and CSV Stream Engine"

Add-Heading2 "3.4 Testing"
Add-P -text "Comprehensive testing was performed across all modules to verify proper operation, data integrity, and error recovery:"

$testRows = @(
    @("User Authentication", "Attempted login with valid and invalid credentials.", "Valid credentials grant dashboard access; invalid entries display error flash.", "Allowed valid login, but initially lacked proper alert styling on bad password.", "Refined authentication controller to set error message in session flash and highlight input field."),
    @("Device Inventory CRUD", "Added new Cisco router, updated IP address, and removed dummy switch.", "Record inserted, updated in database, and removed on delete.", "Worked as intended with foreign key integrity.", "None required."),
    @("Threshold Monitoring", "Ingested metric with download exceeding configured 5000 MB limit.", "System logs metric and immediately generates a critical alert.", "Metric logged, but alert initially did not associate with device name.", "Corrected foreign-key joining query in alert view to link alerts.device_id to devices.id."),
    @("Real-Time Transaction Log", "Submitted telemetry readings via web form and JSON API endpoint.", "Both channels record identical schema values into usage_metrics.", "API rejected input due to JSON header decoding discrepancy.", "Enhanced API parser to inspect both php://input stream and POST array payloads."),
    @("Report Date Filtering & CSV", "Filtered metrics between two calendar dates and clicked 'Export CSV'.", "CSV file downloads with filtered rows matching table display.", "CSV opened with missing headers in older spreadsheet software.", "Added explicit RFC 4180 headers and UTF-8 charset declarations."),
    @("Navigation & Responsiveness", "Tested interface navigation on smartphone viewport and desktop screen.", "Layout reflows cleanly; tables collapse or scroll horizontally.", "Table overflowed on mobile screen.", "Implemented responsive mobile card view (d-md-none) alongside desktop table view (d-none d-md-block).")
)
Add-TableRows @("Test Case", "Testing Action", "Expected Outcome", "Actual Result", "Corrective Action") $testRows
Add-Caption "Table 3.4.1: Test Cases, Verification Results, and Corrective Actions"

Add-Heading2 "3.5 Deployment"
Add-P -text "The Network Usage Monitoring System has been deployed and validated in the local XAMPP Apache/MariaDB development environment at C:\xampp\htdocs\netusage-monitoring."
Add-P -text "Deployment steps included placing files in the htdocs directory, importing the schema into MariaDB/MySQL from database/schema.sql, updating database credentials in config/config.php, and executing public/setup.php to initialize tables and default credentials."
Add-P -text "For cloud production hosting, SSL/TLS certificates should be provisioned for HTTPS encryption, API authentication tokens enforced, and setup.php removed to prevent unauthorized schema resets."

Add-PageBreak

# ----------------- CHAPTER FOUR (MILESTONE 4) -----------------
Add-Heading1 "MILESTONE 4: CHAPTER FOUR — CONCLUSION AND RECOMMENDATIONS"

Add-Heading2 "4.1 Conclusion"
Add-P -text "The objective of this project was to design, develop, and deploy the NetUsage Hub Network Usage Monitoring System to solve the challenges of manual network record-keeping, unmonitored bandwidth consumption, and lack of historical network audits."
Add-P -text "Milestone 1 defined the problem, objectives, and schedule. Milestone 2 completed the system wireframes, flowcharts, DFDs, ERDs, use cases, and class diagrams. Milestone 3 translated these specifications into functional PHP/MySQL scripts, responsive Bootstrap interfaces, complete testing, and local server deployment. Milestone 4 validated project deliverables, established user-acceptance criteria, and outlined future system enhancements."
Add-P -text "The resulting application successfully automates network inventory tracking, metric recording, threshold-based incident alerting, and business report generation, providing an efficient, reliable management tool for NetUsage Hub in Kisii."

Add-Heading2 "4.2 Recommendations"
Add-P -text "Although the Network Usage Monitoring System operates reliably and accomplishes all MVP functional requirements, the following improvements are recommended for subsequent versions:"
Add-P -text "1. Automated Hardware Telemetry via SNMP: Implement background SNMP (Simple Network Management Protocol v2c/v3) polling daemons to retrieve interface byte counts and status automatically from physical routers and switches."
Add-P -text "2. Instant SMS & Email Notification: Integrate external SMS APIs (such as Africa's Talking or Twilio) to notify network engineers immediately on mobile devices when critical bandwidth thresholds are breached."
Add-P -text "3. M-Pesa Bandwidth Billing Integration: Integrate Safaricom Daraja M-Pesa APIs to automate commercial client billing, payment verification, and automated bandwidth allocation."
Add-P -text "4. Predictive Traffic Forecasting: Incorporate time-series forecasting algorithms to identify seasonal network congestion patterns and guide bandwidth procurement."
Add-P -text "5. Role-Based Access Control: Expand administrative roles to include Field Technicians, Read-Only Network Auditors, and System Administrators with granular permissions."

Add-PageBreak

# ----------------- REFERENCES -----------------
Add-Heading1 "REFERENCES"
Add-P -text "Djohan, T., and Stefvy. (2023, April). 'Inventory Shortages and Poor Management Systems Negatively Affect Customer Satisfaction in the Retail and Infrastructure Industry'. Research Synergy Press Journals. https://www.researchgate.net/publication/371763839"
Add-P -text "International Telecommunication Union (ITU). (2023). Measuring digital development: Facts and figures 2023. https://www.itu.int/en/Pages/default.aspx"
Add-P -text "Kurose, J. F., and Ross, K. W. (2021). Computer Networking: A Top-Down Approach (8th ed.). Pearson Education."
Add-P -text "Laudon, K. C., and Laudon, J. P. (2022). Management information systems: Managing the digital firm (17th ed.). Pearson Education."
Add-P -text "Mhlongo, N. et al. (2024, February 6). 'Reviewing the impact of cloud computing on small and medium enterprises in Africa'. International Journal of Science and Research Archive. https://ijsra.net/sites/default/files/IJSRA-2024-0236.pdf"
Add-P -text "Rashid, M. et al. (2025, July 18). 'A Review of Technological Advancements and Operational Improvements in IoT for Network Inventory Management'. IJRISS. https://rsisinternational.org/journals/ijriss/"
Add-P -text "Stallings, W. (2020). Data and Computer Communications (10th ed.). Pearson Education."

# Close body and document with strict section properties (w:sectPr)
[void]$sb.Append(@'
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>
      <w:cols w:space="720"/>
      <w:docGrid w:linePitch="360"/>
    </w:sectPr>
  </w:body>
</w:document>
'@)

[System.IO.File]::WriteAllText("$tempDir\word\document.xml", $sb.ToString(), $utf8NoBom)

# 6. Compress into .docx using ZipArchive with EXPLICIT FORWARD SLASHES (/)
[System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null

$zipStream = New-Object System.IO.FileStream($outputDocx, [System.IO.FileMode]::Create)
$archive = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)

$allFiles = Get-ChildItem -Path $tempDir -Recurse -File
foreach ($file in $allFiles) {
    $relPath = $file.FullName.Substring($tempDir.Length + 1).Replace("\", "/")
    $entry = $archive.CreateEntry($relPath, [System.IO.Compression.CompressionLevel]::Optimal)
    $entryStream = $entry.Open()
    $fileBytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $entryStream.Write($fileBytes, 0, $fileBytes.Length)
    $entryStream.Dispose()
}

$archive.Dispose()
$zipStream.Dispose()

# Copy to public folder
Copy-Item -Path $outputDocx -Destination $publicDocx -Force

# Cleanup
Remove-Item -Recurse -Force $tempDir

Write-Host "SUCCESS: Generated MILESTONE_3_AND_4_DOCUMENTATION.docx at:"
Write-Host "  $outputDocx"
Write-Host "  $publicDocx"

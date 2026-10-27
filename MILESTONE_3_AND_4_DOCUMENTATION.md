# ZETECH UNIVERSITY
### FACULTY OF INFORMATION AND COMMUNICATION TECHNOLOGY
### DEPARTMENT OF COMPUTER SCIENCE

---

<br><br>

# NETWORK USAGE MONITORING SYSTEM (NETUSAGE HUB)
## MILESTONE 3 & 4 DOCUMENTATION: SYSTEM IMPLEMENTATION, TESTING, DEPLOYMENT, CONCLUSION & RECOMMENDATIONS

<br>

**SUBMITTED BY:**  
**Student Name:** Brenda Chebet Chelule  
**Registration Number:** DCS-01-0892/2024  

<br>

**A PROJECT REPORT SUBMITTED IN PARTIAL FULFILMENT FOR THE AWARD OF DIPLOMA IN COMPUTER SCIENCE BY ZETECH UNIVERSITY**

<br>

**AUGUST 2026**

---

<div style="page-break-after: always;"></div>

## TABLE OF CONTENTS

- **1. MILESTONE 3: CHAPTER THREE — SYSTEM IMPLEMENTATION**
  - 1.1 Introduction
  - 1.2 User Interface Development
    - 1.2.1 Login Page Development
    - 1.2.2 Dashboard Overview & KPI Cards
    - 1.2.3 Header & Navigation Bar
    - 1.2.4 Inventory / Device Control Center
    - 1.2.5 Add New Device Form & Modal
    - 1.2.6 Real-Time Transaction Metric Logs
    - 1.2.7 Business Usage Reports & Summary View
  - 1.3 Back-End Logic Development
    - 1.3.1 Secure Authentication & Session Management
    - 1.3.2 Real-Time Dashboard Aggregation Engine
    - 1.3.3 Device Inventory Management & Threshold Checking Rules
    - 1.3.4 Telemetry Transaction Logging & Analytical Reporting
  - 1.4 System Testing & Quality Assurance
    - 1.4.1 Comprehensive Testing Matrix & Results
  - 1.5 System Deployment
    - 1.5.1 Local Server Deployment (XAMPP / Apache / MySQL)
    - 1.5.2 Cloud & Production Deployment Guidelines
- **2. MILESTONE 4: CHAPTER FOUR — CONCLUSION AND RECOMMENDATIONS**
  - 2.1 Conclusion & Project Summary
  - 2.2 Recommendations for Future Improvements
- **3. REFERENCES**

---

<div style="page-break-after: always;"></div>

# MILESTONE 3: CHAPTER THREE — SYSTEM IMPLEMENTATION

## 3.1 Introduction

This milestone details the practical implementation of the NetUsage Hub Network Usage Monitoring System, translating the architectural models and design wireframes developed in Milestone 2 into a functional, resilient, and responsive web application. The development follows a structured software architecture that cleanly decouples relational schema persistence, server-side controller scripting, security middleware, and responsive template presentation.

The application stack comprises:
- **Back-End Scripting:** PHP 8 with PHP Data Objects (PDO) for prepared statements and transactional consistency.
- **Database Engine:** MySQL / MariaDB featuring normalized relational tables (`users`, `devices`, `usage_metrics`, `alerts`).
- **Front-End Stack:** HTML5, CSS3, JavaScript (ES6), and Bootstrap 5 for modern, responsive interfaces across desktop and mobile devices.
- **Local Server Stack:** Apache HTTP Server within the XAMPP environment on Windows.

---

## 3.2 User Interface Development

### 3.2.1 Login Page Development
The authentication portal provides a centered, professional login card with custom CSS styling, visual iconography, and clear feedback alerts for invalid login attempts.

```html
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
```

```css
/* Login Card Stylesheet (public/assets/css/app.css) */
body {
    background: #f0f2f5;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    font-family: 'Montserrat', sans-serif;
}
.login-card {
    width: 100%;
    max-width: 400px;
    border: none;
    border-radius: 8px;
    box-shadow: 0 2px 16px rgba(0, 0, 0, 0.08);
    background: #ffffff;
    padding: 2.25rem 2rem;
}
```
*Figure 3.2.1: Login Page Interface Implementation and CSS Styling*

---

### 3.2.2 Dashboard Overview & KPI Cards
The dashboard interface gives administrators instant operational awareness. The top row renders three critical Key Performance Indicator (KPI) cards: **Total Monitored Inventory**, **Threshold Alerts**, and **Today's Bandwidth Traffic**. Below the metrics, active network devices are presented in an intuitive status grid.

```html
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
```
*Figure 3.2.2: Dashboard Overview KPI Cards and Infrastructure Grid*

---

### 3.2.3 Header & Navigation Bar
The sticky navigation header implements a pure white elevated toolbar containing brand identity, active link states, search bar for instantaneous IP/device lookup, and administrator session controls.

```html
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
            <form class="d-flex ms-lg-3 my-2 my-lg-0 search-form-wrap" action="devices.php" method="GET">
                <div class="input-group">
                    <input class="form-control form-control-sm bg-light" type="search" name="q" placeholder="Search devices, IP, type...">
                    <button class="btn btn-sm btn-primary px-3" type="submit"><i class="fa fa-search"></i></button>
                </div>
            </form>
            <div class="ms-lg-3 d-flex align-items-center">
                <span class="text-muted small me-3"><i class="fa fa-user-circle me-1"></i> Admin</span>
                <a href="logout.php" class="btn btn-sm btn-outline-secondary px-3">Logout</a>
            </div>
        </div>
    </div>
</nav>
```
*Figure 3.2.3: Sticky Navigation Bar with Live Search and Profile Controls*

---

### 3.2.4 Inventory / Device Control Center
The inventory module adopts a split layout: a 9-column tabular catalog with a dark table header (`thead class="table-dark"`) displaying device specifications, and a 3-column sticky sidebar highlighting active threshold breaches and critical incidents.

```html
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
                <tbody>
                    <!-- Dynamically rendered device rows -->
                </tbody>
            </table>
        </div>
    </div>
    <div class="col-lg-3">
        <div class="card shadow-sm border-0 position-sticky" style="top: 80px;">
            <div class="card-header bg-danger text-white fw-bold">
                <i class="fa fa-bell me-1"></i> Threshold Alerts
            </div>
            <div class="card-body p-0">
                <!-- Dynamically rendered over-quota alert list -->
            </div>
        </div>
    </div>
</div>
```
*Figure 3.2.4: Inventory Control Center Table and Threshold Alert Sidebar*

---

### 3.2.5 Add New Device Form & Modal
The device creation form allows administrators to easily register routers, switches, access points, and firewalls into the database, specifying their network location and daily download/upload threshold caps.

```html
<!-- Add / Edit Device Card Form (public/devices.php) -->
<div class="card border-0 shadow-sm" id="add-device-card">
    <div class="card-header bg-white border-bottom p-3 d-flex justify-content-between align-items-center">
        <h5 class="mb-0 fw-bold"><i class="fa fa-plus-circle me-2 text-primary"></i>New Device</h5>
    </div>
    <div class="card-body p-4">
        <form action="devices.php" method="POST">
            <input type="hidden" name="csrf" value="<?= csrf_token() ?>">
            <input type="hidden" name="action" value="save">
            <div class="mb-3">
                <label class="form-label small text-muted mb-1">Device Name</label>
                <input type="text" name="name" class="form-control form-control-sm" placeholder="e.g. Cisco Core Router 2901" required>
            </div>
            <div class="row g-2 mb-3">
                <div class="col-6">
                    <label class="form-label small text-muted mb-1">IP Address</label>
                    <input type="text" name="ip_address" class="form-control form-control-sm" placeholder="192.168.1.1" required>
                </div>
                <div class="col-6">
                    <label class="form-label small text-muted mb-1">Location / NOC</label>
                    <input type="text" name="location" class="form-control form-control-sm" placeholder="Server Room A">
                </div>
            </div>
            <div class="row g-2 mb-3">
                <div class="col-4">
                    <label class="form-label small text-muted mb-1">DL Limit (MB)</label>
                    <input type="number" step="0.01" name="download_limit_mb" class="form-control form-control-sm" value="5000" required>
                </div>
                <div class="col-4">
                    <label class="form-label small text-muted mb-1">UL Limit (MB)</label>
                    <input type="number" step="0.01" name="upload_limit_mb" class="form-control form-control-sm" value="2000" required>
                </div>
                <div class="col-4">
                    <label class="form-label small text-muted mb-1">Category / Type</label>
                    <select name="device_type" class="form-select form-select-sm">
                        <option value="Router">Router</option>
                        <option value="Switch">Switch</option>
                        <option value="Access Point">Access Point</option>
                        <option value="Firewall">Firewall</option>
                    </select>
                </div>
            </div>
            <button type="submit" class="btn btn-primary btn-sm w-100 py-2 fw-semibold">Add Device to Inventory</button>
        </form>
    </div>
</div>
```
*Figure 3.2.5: Add/Edit New Device Modal Card Implementation*

---

### 3.2.6 Real-Time Transaction Metric Logs
The transaction log interface records every telemetry event. It includes desktop and mobile views: on desktop, an audit table displays time, device identity, download and upload traffic, latency, and total bandwidth. On mobile screens, cards display the records without horizontal scrolling.

```html
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
        <?php foreach ($metrics as $m): $dt = new DateTime($m['recorded_at']); ?>
            <tr>
                <td class="ps-3 text-muted">
                    <span class="fw-bold text-dark d-block"><?= $dt->format('H:i') ?></span>
                    <small><?= $dt->format('d/m') ?></small>
                </td>
                <td><strong><?= e($m['device_name']) ?></strong></td>
                <td class="text-center"><?= number_format($m['download_mb'], 2) ?></td>
                <td class="text-center"><?= number_format($m['upload_mb'], 2) ?></td>
                <td class="text-center"><?= number_format($m['latency_ms'], 1) ?> ms</td>
                <td class="text-end pe-3 text-success fw-bold"><?= number_format($m['total_mb'], 2) ?> MB</td>
            </tr>
        <?php endforeach; ?>
    </tbody>
</table>
```
*Figure 3.2.6: Real-Time Transaction Metric Logs Interface and Mobile View*

---

### 3.2.7 Business Usage Reports & Summary View
The reporting module consolidates usage metrics across customizable date ranges, presenting total network bandwidth, ranked bandwidth-consuming devices, and a one-click CSV export engine for offline analysis.

```html
<!-- Business Usage Reports Summary Row (public/reports.php) -->
<div class="row mb-4">
    <div class="col-md-4 mb-4">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body py-4 text-center">
                <div class="mb-2 text-success opacity-75"><i class="fa fa-area-chart fa-2x"></i></div>
                <h6 class="text-muted text-uppercase mb-1" style="font-size:0.72rem;">Total Bandwidth Monitored</h6>
                <h3 class="fw-bold mb-0 text-success"><?= number_format($totalBandwidth, 1) ?> MB</h3>
            </div>
        </div>
    </div>
    <div class="col-md-8 mb-4">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-header bg-white border-bottom p-3">
                <h5 class="mb-0 fw-bold text-dark">Top Bandwidth Devices</h5>
            </div>
            <div class="card-body p-0">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light"><tr><th class="ps-4">Device Name</th><th class="text-end pe-4">Total MB</th></tr></thead>
                    <tbody><!-- Top device rows --></tbody>
                </table>
            </div>
        </div>
    </div>
</div>
```
*Figure 3.2.7: Business Usage Reports Summary and Export Interface*

---

## 3.3 Back-End Logic Development

### 3.3.1 Secure Authentication & Session Management
Authentication employs standard password hashing (`password_hash` and `password_verify` with BCRYPT) combined with CSRF token verification and session regeneration to defeat credential harvesting and session fixation.

```php
// Backend Authentication Logic (includes/auth.php & public/index.php)
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
```
*Figure 3.3.1: Authentication Backend Logic and Password Verification*

---

### 3.3.2 Real-Time Dashboard Aggregation Engine
The dashboard controller issues database aggregation queries calculating total devices, online devices, active threshold alerts, and total bandwidth consumed today.

```php
// Dashboard Backend Aggregation (public/dashboard.php)
$stats = [
    'devices'  => (int)db()->query('SELECT COUNT(*) FROM devices')->fetchColumn(),
    'online'   => (int)db()->query("SELECT COUNT(*) FROM devices WHERE status='online'")->fetchColumn(),
    'alerts'   => (int)db()->query('SELECT COUNT(*) FROM alerts WHERE is_resolved=0')->fetchColumn(),
    'today_mb' => (float)db()->query('SELECT COALESCE(SUM(download_mb + upload_mb), 0) FROM usage_metrics WHERE DATE(recorded_at) = CURDATE()')->fetchColumn()
];

// Rolling 24-hour usage per device
$devices = db()->query('SELECT d.*, 
    (SELECT COALESCE(SUM(download_mb + upload_mb), 0) FROM usage_metrics m 
     WHERE m.device_id = d.id AND m.recorded_at >= NOW() - INTERVAL 24 HOUR) AS usage_mb 
    FROM devices d ORDER BY d.id DESC LIMIT 8')->fetchAll();
```
*Figure 3.3.2: Dashboard Metric Aggregation Queries*

---

### 3.3.3 Device Inventory Management & Threshold Checking Rules
When telemetry metrics are ingested, an automated threshold evaluation routine runs within an ACID database transaction. If the recorded traffic exceeds the device's configured limits, an alert is triggered immediately.

```php
// Metric Ingestion & Threshold Trigger (public/metrics.php & public/api/record_metric.php)
$pdo = db();
$pdo->beginTransaction();

$stmt = $pdo->prepare('INSERT INTO usage_metrics (device_id, download_mb, upload_mb, latency_ms, packet_loss_percent) VALUES (?, ?, ?, ?, ?)');
$stmt->execute([$device, $download, $upload, $latency, $loss]);
$metricId = $pdo->lastInsertId();

$dStmt = $pdo->prepare('SELECT * FROM devices WHERE id = ?');
$dStmt->execute([$device]);
$dev = $dStmt->fetch();

// Evaluate threshold rules
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
```
*Figure 3.3.3: Device Inventory CRUD and Threshold Evaluation Script*

---

### 3.3.4 Telemetry Transaction Logging & Analytical Reporting
The analytical reporting queries aggregate usage across date ranges, find the highest bandwidth consumers, and support RFC 4180-compliant CSV exports directly to spreadsheet software.

```php
// Analytical Reporting & CSV Stream Engine (public/reports.php)
$stmtTop = db()->prepare('SELECT d.name, SUM(m.download_mb + m.upload_mb) AS total_mb 
    FROM usage_metrics m 
    JOIN devices d ON d.id = m.device_id 
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
```
*Figure 3.3.4: Analytical Reporting Queries and CSV Export Engine*

---

## 3.4 System Testing & Quality Assurance

Rigorous unit, integration, and user-acceptance testing was conducted across all system modules to guarantee reliable data ingestion, quota calculations, and error-handling.

| Test Case | Testing Action | Expected Outcome | Actual Result | Corrective Action |
| :--- | :--- | :--- | :--- | :--- |
| **User Authentication** | Attempted login with valid and invalid credentials. | Valid credentials grant dashboard access; invalid entries display error flash. | Allowed valid login, but initially lacked proper alert styling on bad password. | Refined authentication controller to set error message in session flash and highlight input field. |
| **Device Inventory CRUD** | Added new Cisco router, updated IP address, and removed dummy switch. | Record inserted, updated in database, and removed on delete. | Worked as intended with foreign key integrity. | None required. |
| **Threshold Monitoring** | Ingested metric with download exceeding configured 5000 MB limit. | System logs metric and immediately generates a critical alert. | Metric logged, but alert initially did not associate with device name. | Corrected foreign-key joining query in alert view to link `alerts.device_id` to `devices.id`. |
| **Real-Time Transaction Log** | Submitted telemetry readings via web form and JSON API endpoint. | Both channels record identical schema values into `usage_metrics`. | API rejected input due to JSON header decoding discrepancy. | Enhanced API parser to inspect both `php://input` stream and `$_POST` array payloads. |
| **Report Date Filtering & CSV** | Filtered metrics between two calendar dates and clicked 'Export CSV'. | CSV file downloads with filtered rows matching table display. | CSV opened with missing headers in older spreadsheet software. | Added explicit RFC 4180 headers and UTF-8 charset declarations. |
| **Navigation & Responsiveness** | Tested interface navigation on smartphone viewport and desktop screen. | Layout reflows cleanly; tables collapse or scroll horizontally. | Table overflowed on mobile screen. | Implemented responsive mobile card view (`d-md-none`) alongside desktop table view (`d-none d-md-block`). |

*Table 3.4.1: Test Cases, Verification Results, and Corrective Actions*

---

## 3.5 System Deployment

The system is deployed on an Apache and MariaDB/MySQL stack and is ready for both local intranet and cloud environments:

### 3.5.1 Local Server Deployment (XAMPP)
1. **Document Root Deployment:** The application resides at `C:\xampp\htdocs\netusage-monitoring`.
2. **Database Initialization:** The database schema is imported into MySQL via phpMyAdmin or the MySQL CLI using `database/schema.sql`.
3. **Configuration:** Database host, port, database name, and user credentials are configured in `config/config.php`.
4. **Data Seeding:** The administrative account (`admin` / `admin123`) and initial sample network devices are populated by executing `http://localhost/netusage-monitoring/public/setup.php` once.
5. **Operational Verification:** The system is accessed via web browser at `http://localhost/netusage-monitoring/public/`.

### 3.5.2 Cloud & Production Deployment Guidelines
1. **Transport Layer Security (HTTPS):** Production environments require SSL/TLS certificates to protect credentials and telemetry data transmitted over public channels.
2. **Per-Device API Keys:** For automated telemetry reporting from physical edge routers, per-device API tokens must be verified in `public/api/record_metric.php`.
3. **Database Security:** In production, remove `setup.php` or restrict file execution permissions to prevent unauthorized database resets.

---

<div style="page-break-after: always;"></div>

# MILESTONE 4: CHAPTER FOUR — CONCLUSION AND RECOMMENDATIONS

## 4.1 Conclusion & Project Summary

The NetUsage Hub Network Usage Monitoring System successfully addresses the operational bottlenecks of manual network tracking, undetected equipment outages, and unmonitored bandwidth consumption. 

Through the four project milestones, the following objectives were accomplished:
- **Milestone 1:** Clarified the problem statement, established system objectives, and scheduled the development lifecycle.
- **Milestone 2:** Produced the system design models, including wireframes, flowcharts, Context & Level 1 DFDs, ERDs, Use Case Diagrams, and Class Diagrams.
- **Milestone 3:** Developed the PHP/MySQL backend and responsive Bootstrap 5 interface, conducted end-to-end testing, and completed deployment on the local Apache server.
- **Milestone 4:** Evaluated project outcomes, conducted user-acceptance reviews, and outlined future technological enhancements.

Through the development of this project, valuable technical competencies were acquired in full-stack web development, database normalization, session security, and network telemetry handling. The resulting system delivers an effective internal management platform for NetUsage Hub in Kisii.

---

## 4.2 Recommendations for Future Improvements

To build upon the foundation established in NetUsage Hub, the following enhancements are recommended:

1. **Automated Hardware Telemetry via SNMP:**  
   Integrate automated Simple Network Management Protocol (SNMP v2c/v3) polling daemons to periodically query routers, switches, and access points for interface octets, interface status, and uptime, eliminating manual data entry.
   
2. **Instant SMS & Email Alert Notification:**  
   Integrate external communication gateways (e.g., Africa's Talking, Twilio, or AWS SNS) to send immediate SMS alerts to network engineers when high-priority threshold violations occur.
   
3. **M-Pesa Bandwidth Billing Integration:**  
   Integrate the Safaricom Daraja M-Pesa API to enable automated billing, client voucher generation, and quota top-ups for public or commercial hotspots.
   
4. **Predictive Capacity Planning & Analytics:**  
   Implement time-series predictive modeling to forecast traffic growth, assisting management with bandwidth procurement and infrastructure upgrades before congestion happens.
   
5. **Role-Based Access Control (RBAC):**  
   Expand user privileges to support multiple administrative tiers, including Super Admins, Network Engineers, and Read-Only Auditors.

---

<div style="page-break-after: always;"></div>

# REFERENCES

- Djohan, T., & Stefvy. (2023, April). “Inventory Shortages and Poor Management Systems Negatively Affect Customer Satisfaction in the Retail and Infrastructure Industry”. *Research Synergy Press Journals*. https://www.researchgate.net/publication/371763839
- International Telecommunication Union (ITU). (2023). *Measuring digital development: Facts and figures 2023*. Geneva: ITU Publications. https://www.itu.int/en/Pages/default.aspx
- Kurose, J. F., & Ross, K. W. (2021). *Computer Networking: A Top-Down Approach* (8th ed.). Pearson Education.
- Laudon, K. C., & Laudon, J. P. (2022). *Management Information Systems: Managing the Digital Firm* (17th ed.). Pearson Education.
- Mhlongo, N. et al. (2024, February 6). “Reviewing the impact of cloud computing and network automation on small and medium enterprises in Africa”. *International Journal of Science and Research Archive*, 11(1), 234-245. https://ijsra.net/sites/default/files/IJSRA-2024-0236.pdf
- Rashid, M. et al. (2025, July 18). “A Review of Technological Advancements and Operational Improvements in IoT and Telemetry for Network Inventory Management”. *International Journal of Research and Innovation in Social Science (IJRISS)*. https://rsisinternational.org/journals/ijriss/
- Stallings, W. (2020). *Data and Computer Communications* (10th ed.). Pearson Education.

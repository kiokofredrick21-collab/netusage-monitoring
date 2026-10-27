# NetUsage Hub (Net-Portal) — Network Usage Monitoring System

A professional PHP 8 + MySQL web application and academic project documentation designed and developed for **Zetech University**, adhering strictly to the university's Diploma in Computer Science system documentation and UI presentation template.

---

## 🚀 Key Modules & UI Features

The application's interface and component structure directly reproduce the commercial-grade template style:
- **Sticky Navigation Bar (`includes/header.php`):** Two-tone brand badge (`Net-`**Portal**), real-time device search bar, navigation links with active indicators, and administrator session controls.
- **Login Portal (`public/index.php`):** Centered card layout on `#f0f2f5`, credential inputs with Font Awesome icons, validation flash feedback, and CSRF token protection.
- **Dashboard Overview (`public/dashboard.php`):** 
  - 3 top KPI summary cards: **Total Inventory**, **Threshold Alerts**, and **Today's Bandwidth**.
  - **Monitored Infrastructure Grid:** Responsive device cards with status badges (Online, Offline, Maintenance), hardware icons, 24h traffic telemetry, and quick-action triggers.
  - Active incident audit table.
- **Inventory Control Center (`public/devices.php`):**
  - Dark-header (`table-dark`) responsive device inventory table with live IP codes, bandwidth limits, inline traffic burst logger, edit and delete actions.
  - Sticky **Threshold Alert Sidebar** (`col-lg-3`) highlighting devices operating over configured limits.
  - **Add/Edit Device Form:** Multi-column card modal format for adding routers, switches, access points, and firewalls.
- **Real-Time Transaction Logs (`public/metrics.php`):**
  - Telemetry audit trail recording download (MB), upload (MB), latency (ms), and packet loss (%).
  - Desktop table view with dual-line timestamps + mobile card view.
  - Form to record new hardware readings.
- **Business Usage Reports (`public/reports.php`):**
  - Summary row pairing total monitored bandwidth with a top bandwidth-consuming devices leaderboard.
  - Calendar date range filter with one-click **CSV export**.
  - Recent activity banner linking to the metric ledger.
- **Threshold Alerts Center (`public/alerts.php`):**
  - Incident tracking table with severity badges (Critical, Warning, Info) and one-click incident resolution controls.

---

## 📄 Academic System Documentation

The repository includes complete, publication-ready academic documentation written according to Zetech University's specifications:
1. **Microsoft Word Format (.docx):** [NETWORK_USAGE_MONITORING_SYSTEM_DOCUMENTATION.docx](file:///c:/xampp/htdocs/netusage-monitoring/NETWORK_USAGE_MONITORING_SYSTEM_DOCUMENTATION.docx)  
   Complete genuine Word `.docx` file pre-formatted with cover page, declaration, tables, diagrams, code blocks, page breaks, and APA references.
2. **Interactive HTML / Printable PDF Format:** [public/documentation.html](file:///c:/xampp/htdocs/netusage-monitoring/public/documentation.html)  
   Open in your browser (`http://localhost/netusage-monitoring/public/documentation.html`) to view the fully formatted document or click the "Download Word (.docx)" button in the top toolbar. Use **Ctrl+P** (Print -> Save as PDF) for academic submission.
3. **Markdown Format:** [SYSTEM_DOCUMENTATION.md](file:///c:/xampp/htdocs/netusage-monitoring/SYSTEM_DOCUMENTATION.md)  
   Stored in the project root for version control and repository documentation.

---

## 💻 Local Installation & Setup with XAMPP

1. **Verify Workspace Path:**  
   Ensure the project is in `C:\xampp\htdocs\netusage-monitoring`.
2. **Start Apache & MySQL:**  
   Open the XAMPP Control Panel and start both Apache and MySQL.
3. **Database Configuration:**  
   Database parameters are set in `config/config.php` (default user `root`, no password, database `netusage_hub`).
4. **Initialize Database & Seed Sample Records:**  
   Open your browser and navigate to:  
   `http://localhost/netusage-monitoring/public/setup.php`  
   This will automatically create the tables and seed sample devices, metrics, alerts, and the administrator account.
5. **Log In:**  
   Navigate to:  
   `http://localhost/netusage-monitoring/public/index.php`  
   - **Username:** `admin`  
   - **Password:** `admin123`

<?php
require_once __DIR__ . '/../config/config.php';

$message = null;
$error = null;

try {
    $pdo = db();

    // 1. Create or ensure tables exist
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS users (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            username VARCHAR(80) NOT NULL UNIQUE,
            password_hash VARCHAR(255) NOT NULL,
            full_name VARCHAR(120) NOT NULL,
            role ENUM('admin','operator') NOT NULL DEFAULT 'admin',
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB;

        CREATE TABLE IF NOT EXISTS devices (
            id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(120) NOT NULL,
            ip_address VARCHAR(45) NOT NULL UNIQUE,
            device_type VARCHAR(80) NOT NULL DEFAULT 'Router',
            location VARCHAR(120) NULL,
            status ENUM('online','offline','maintenance') NOT NULL DEFAULT 'offline',
            download_limit_mb DECIMAL(12,2) NOT NULL DEFAULT 5000,
            upload_limit_mb DECIMAL(12,2) NOT NULL DEFAULT 2000,
            last_seen DATETIME NULL,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB;

        CREATE TABLE IF NOT EXISTS usage_metrics (
            id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            device_id INT UNSIGNED NOT NULL,
            download_mb DECIMAL(12,2) NOT NULL DEFAULT 0,
            upload_mb DECIMAL(12,2) NOT NULL DEFAULT 0,
            latency_ms DECIMAL(10,2) NOT NULL DEFAULT 0,
            packet_loss_percent DECIMAL(5,2) NOT NULL DEFAULT 0,
            recorded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_dev_time (device_id, recorded_at)
        ) ENGINE=InnoDB;

        CREATE TABLE IF NOT EXISTS alerts (
            id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            device_id INT UNSIGNED NOT NULL,
            metric_id BIGINT UNSIGNED NULL,
            alert_type VARCHAR(60) NOT NULL,
            message VARCHAR(255) NOT NULL,
            severity ENUM('info','warning','critical') NOT NULL DEFAULT 'warning',
            is_resolved TINYINT(1) NOT NULL DEFAULT 0,
            created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            resolved_at DATETIME NULL,
            INDEX idx_resolved (is_resolved, created_at)
        ) ENGINE=InnoDB;
    ");

    // 2. Ensure Admin User
    $stmt = $pdo->prepare("SELECT COUNT(*) FROM users WHERE username = 'admin'");
    $stmt->execute();
    if ((int)$stmt->fetchColumn() === 0) {
        $ins = $pdo->prepare("INSERT INTO users (username, password_hash, full_name, role) VALUES (?, ?, ?, ?)");
        $ins->execute(['admin', password_hash('admin123', PASSWORD_DEFAULT), 'Brenda Chebet Chelule', 'admin']);
    }

    // 3. Ensure Sample Devices
    $deviceCount = (int)$pdo->query("SELECT COUNT(*) FROM devices")->fetchColumn();
    if ($deviceCount === 0) {
        $devs = [
            ['Cisco Core Router 2901', '192.168.1.1', 'Router', 'Main Server Room', 'online', 5000, 2000],
            ['Catalyst 3750 Switch', '192.168.1.2', 'Switch', 'Data Center Rack B', 'online', 8000, 4000],
            ['MikroTik CCR1009 Gateway', '192.168.1.254', 'Router', 'Kisii Edge Gateway', 'online', 10000, 5000],
            ['UniFi AP Pro (Admin)', '192.168.1.10', 'Access Point', 'Admin Wing Level 1', 'online', 2500, 1000],
            ['UniFi AP AC (Library)', '192.168.1.11', 'Access Point', 'Campus Library Block', 'offline', 2500, 1000],
            ['FortiGate 60F Firewall', '192.168.1.250', 'Firewall', 'Security Operations Room', 'online', 12000, 6000]
        ];

        $insDev = $pdo->prepare("INSERT INTO devices (name, ip_address, device_type, location, status, download_limit_mb, upload_limit_mb, last_seen) VALUES (?, ?, ?, ?, ?, ?, ?, NOW())");
        foreach ($devs as $d) {
            $insDev->execute($d);
        }

        // Sample metrics
        $allDevs = $pdo->query("SELECT id FROM devices")->fetchAll(PDO::FETCH_COLUMN);
        $insMetric = $pdo->prepare("INSERT INTO usage_metrics (device_id, download_mb, upload_mb, latency_ms, packet_loss_percent, recorded_at) VALUES (?, ?, ?, ?, ?, ?)");
        
        foreach ($allDevs as $did) {
            $insMetric->execute([$did, rand(350, 1800), rand(80, 500), rand(10, 45), 0.0, date('Y-m-d H:i:s', strtotime('-2 hours'))]);
            $insMetric->execute([$did, rand(400, 2200), rand(120, 650), rand(12, 50), 0.2, date('Y-m-d H:i:s', strtotime('-20 minutes'))]);
        }

        // Sample alerts
        if (!empty($allDevs[0])) {
            $pdo->prepare("INSERT INTO alerts (device_id, metric_id, alert_type, message, severity, is_resolved) VALUES (?, NULL, 'download_limit', 'Core Router exceeded threshold capacity', 'critical', 0)")
                ->execute([$allDevs[0]]);
        }
        if (!empty($allDevs[4])) {
            $pdo->prepare("INSERT INTO alerts (device_id, metric_id, alert_type, message, severity, is_resolved) VALUES (?, NULL, 'connectivity', 'UniFi AP AC (Library) unreachable / offline', 'warning', 0)")
                ->execute([$allDevs[4]]);
        }
    }

    $message = 'Database initialized successfully with template-compatible sample records!';
} catch (Throwable $e) {
    $error = $e->getMessage();
}
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Setup | Net-Portal</title>
    <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="assets/css/app.css">
    <style>
        body {
            background: #f0f2f5;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .setup-card {
            max-width: 480px;
            width: 100%;
            background: #fff;
            border-radius: 10px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
            padding: 30px;
        }
    </style>
</head>
<body>

<div class="setup-card text-center">
    <div class="mb-3 text-primary fs-1">
        <i class="fa fa-database"></i>
    </div>
    <h3 class="fw-bold mb-1"><span class="text-dark">Net-</span><span class="text-primary">Portal</span></h3>
    <p class="text-muted small mb-4">Network Usage Monitoring System Setup</p>

    <?php if ($message): ?>
        <div class="alert alert-success small text-start mb-4">
            <i class="fa fa-check-circle me-1"></i> <?= e($message) ?>
        </div>
        <p class="small text-muted mb-4">
            Default credentials:<br>
            Username: <strong>admin</strong><br>
            Password: <strong>admin123</strong>
        </p>
        <a href="index.php" class="btn btn-primary w-100 py-2 fw-semibold">
            Proceed to Login <i class="fa fa-arrow-right ms-1"></i>
        </a>
    <?php else: ?>
        <div class="alert alert-danger small text-start mb-4">
            <i class="fa fa-exclamation-triangle me-1"></i> <?= e($error) ?>
        </div>
        <p class="small text-muted">
            Please make sure MySQL is running in XAMPP and database <code>netusage_hub</code> is accessible in <code>config/config.php</code>.
        </p>
    <?php endif; ?>
</div>

</body>
</html>

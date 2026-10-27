<?php
require_once __DIR__ . '/../includes/auth.php';

// Handle POST actions: Save, Delete, Quick Log
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    verify_csrf();
    $action = $_POST['action'] ?? '';

    if ($action === 'save') {
        $id = (int)($_POST['id'] ?? 0);
        $name = trim($_POST['name'] ?? '');
        $ip_address = trim($_POST['ip_address'] ?? '');
        $device_type = trim($_POST['device_type'] ?? 'Router');
        $location = trim($_POST['location'] ?? 'Kisii NOC');
        $status = $_POST['status'] ?? 'offline';
        $download_limit = (float)($_POST['download_limit_mb'] ?? 5000);
        $upload_limit = (float)($_POST['upload_limit_mb'] ?? 2000);

        if ($id > 0) {
            $stmt = db()->prepare('UPDATE devices SET name=?, ip_address=?, device_type=?, location=?, status=?, download_limit_mb=?, upload_limit_mb=? WHERE id=?');
            $stmt->execute([$name, $ip_address, $device_type, $location, $status, $download_limit, $upload_limit, $id]);
            $_SESSION['flash'] = "Device '{$name}' updated successfully.";
        } else {
            $stmt = db()->prepare('INSERT INTO devices (name, ip_address, device_type, location, status, download_limit_mb, upload_limit_mb, last_seen) VALUES (?,?,?,?,?,?,?,NOW())');
            $stmt->execute([$name, $ip_address, $device_type, $location, $status, $download_limit, $upload_limit]);
            $_SESSION['flash'] = "Device '{$name}' added to inventory successfully.";
        }
    } elseif ($action === 'delete') {
        $id = (int)($_POST['id'] ?? 0);
        $stmt = db()->prepare('DELETE FROM devices WHERE id = ?');
        $stmt->execute([$id]);
        $_SESSION['flash'] = 'Device removed from inventory.';
    } elseif ($action === 'quick_log') {
        $id = (int)($_POST['id'] ?? 0);
        $mb = (float)($_POST['quick_mb'] ?? 100);
        $pdo = db();
        $pdo->beginTransaction();
        
        $pdo->prepare('INSERT INTO usage_metrics (device_id, download_mb, upload_mb, latency_ms, packet_loss_percent) VALUES (?, ?, ?, 18.5, 0.0)')
            ->execute([$id, $mb * 0.7, $mb * 0.3]);
        $metricId = $pdo->lastInsertId();

        $dev = $pdo->query("SELECT * FROM devices WHERE id = {$id}")->fetch();
        if ($dev && ($mb * 0.7) > $dev['download_limit_mb']) {
            $pdo->prepare('INSERT INTO alerts (device_id, metric_id, alert_type, message, severity) VALUES (?, ?, ?, ?, ?)')
                ->execute([$id, $metricId, 'download_limit', "Download traffic ({$mb} MB) exceeded cap", 'critical']);
        }
        $pdo->prepare("UPDATE devices SET status = 'online', last_seen = NOW() WHERE id = ?")->execute([$id]);
        $pdo->commit();

        $_SESSION['flash'] = "Recorded {$mb} MB traffic for {$dev['name']}.";
    }

    redirect('devices.php');
}

// Search Query
$search = trim($_GET['q'] ?? '');
if ($search !== '') {
    $stmt = db()->prepare('SELECT * FROM devices WHERE name LIKE ? OR ip_address LIKE ? OR device_type LIKE ? OR location LIKE ? ORDER BY name');
    $like = "%{$search}%";
    $stmt->execute([$like, $like, $like, $like]);
    $devices = $stmt->fetchAll();
} else {
    $devices = db()->query('SELECT * FROM devices ORDER BY name')->fetchAll();
}

// Edit Record
$edit = null;
if (isset($_GET['edit'])) {
    $stmt = db()->prepare('SELECT * FROM devices WHERE id = ?');
    $stmt->execute([(int)$_GET['edit']]);
    $edit = $stmt->fetch();
}

// Threshold alerts (Devices exceeding limit in last 24h or with active alerts)
$thresholdAlerts = [];
try {
    $thresholdAlerts = db()->query('SELECT d.id, d.name, d.download_limit_mb, 
        COUNT(a.id) AS alert_count,
        COALESCE(SUM(m.download_mb), 0) AS total_dl
        FROM devices d
        LEFT JOIN alerts a ON a.device_id = d.id AND a.is_resolved = 0
        LEFT JOIN usage_metrics m ON m.device_id = d.id AND m.recorded_at >= NOW() - INTERVAL 24 HOUR
        GROUP BY d.id
        HAVING alert_count > 0 OR total_dl > d.download_limit_mb')->fetchAll();
} catch (Throwable $e) {}

$title = 'Inventory Control Center';
require __DIR__ . '/../includes/header.php';
?>

<!-- Title and Action Bar -->
<div class="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-2">
    <div>
        <h2 class="fw-bold text-dark mb-0">Inventory Control Center</h2>
        <p class="text-muted small mb-0">Manage network devices, monitor bandwidth limits, and configure hardware.</p>
    </div>
    <div>
        <a href="#add-device-card" class="btn btn-success px-4 shadow-sm" onclick="document.getElementById('add-device-card').scrollIntoView({behavior: 'smooth'})">
            <i class="fa fa-plus me-1"></i> Add New Stock
        </a>
    </div>
</div>

<?php if ($search !== ''): ?>
    <div class="alert alert-info py-2 d-flex justify-content-between align-items-center mb-4">
        <span><i class="fa fa-filter me-2"></i>Showing search results for: <strong><?= e($search) ?></strong> (<?= count($devices) ?> found)</span>
        <a href="devices.php" class="btn btn-sm btn-outline-dark">Clear Search</a>
    </div>
<?php endif; ?>

<div class="row">
    <!-- Left Column: Devices Table (9 Cols) -->
    <div class="col-lg-9 mb-4">
        <div class="card shadow-sm border-0">
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0" style="width: 100%; min-width: 100%;">
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
                            <?php foreach ($devices as $d): ?>
                                <tr>
                                    <td class="ps-3">
                                        <div class="d-flex align-items-center">
                                            <div class="me-3 p-2 bg-light rounded text-primary fs-5">
                                                <i class="fa fa-server"></i>
                                            </div>
                                            <div>
                                                <div class="fw-bold text-dark"><?= e($d['name']) ?></div>
                                                <small class="text-muted"><?= e($d['location'] ?? 'Kisii Hub') ?></small>
                                            </div>
                                        </div>
                                    </td>
                                    <td><code class="text-dark fw-bold"><?= e($d['ip_address']) ?></code></td>
                                    <td>
                                        <div class="small">
                                            <span class="text-muted">DL:</span> <?= number_format($d['download_limit_mb']) ?> MB<br>
                                            <span class="text-muted">UL:</span> <?= number_format($d['upload_limit_mb']) ?> MB
                                        </div>
                                    </td>
                                    <td>
                                        <?php if ($d['status'] === 'offline'): ?>
                                            <span class="badge bg-danger px-2">OFFLINE</span>
                                        <?php elseif ($d['status'] === 'maintenance'): ?>
                                            <span class="badge bg-warning text-dark px-2">MAINTENANCE</span>
                                        <?php else: ?>
                                            <span class="badge bg-success px-2">ONLINE</span>
                                        <?php endif; ?>
                                    </td>
                                    <td><span class="text-muted fw-semibold"><?= e($d['device_type']) ?></span></td>
                                    <td>
                                        <div class="d-flex align-items-center gap-1 justify-content-center">
                                            <!-- Inline Quick Traffic Simulation Form -->
                                            <form action="devices.php" method="POST" class="d-flex align-items-center me-1">
                                                <input type="hidden" name="csrf" value="<?= csrf_token() ?>">
                                                <input type="hidden" name="action" value="quick_log">
                                                <input type="hidden" name="id" value="<?= $d['id'] ?>">
                                                <input type="number" name="quick_mb" value="100" min="10" step="10" class="form-control form-control-sm me-1" style="width: 65px;" title="Quick traffic burst (MB)">
                                                <button type="submit" class="btn btn-primary btn-sm px-2 text-nowrap" title="Record Quick Traffic Burst">
                                                    Log
                                                </button>
                                            </form>

                                            <!-- Edit Button -->
                                            <a href="?edit=<?= (int)$d['id'] ?>#add-device-card" class="btn btn-sm btn-outline-secondary px-2" title="Edit">
                                                <i class="fa fa-pencil"></i>
                                            </a>

                                            <!-- Delete Button -->
                                            <form action="devices.php" method="POST" onsubmit="return confirm('Delete <?= e(addslashes($d['name'])) ?> from inventory?');">
                                                <input type="hidden" name="csrf" value="<?= csrf_token() ?>">
                                                <input type="hidden" name="action" value="delete">
                                                <input type="hidden" name="id" value="<?= (int)$d['id'] ?>">
                                                <button type="submit" class="btn btn-sm btn-outline-danger px-2" title="Delete">
                                                    <i class="fa fa-trash"></i>
                                                </button>
                                            </form>
                                        </div>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                            <?php if (!$devices): ?>
                                <tr>
                                    <td colspan="6" class="text-center py-4 text-muted">No devices found in the inventory.</td>
                                </tr>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- Right Column: Low Stock / Threshold Sidebar (3 Cols) -->
    <div class="col-lg-3">
        <div class="card shadow-sm border-0 mb-4 position-sticky" style="top: 80px;">
            <div class="card-header bg-danger text-white fw-bold">
                <i class="fa fa-bell me-1"></i> Threshold Alerts
            </div>
            <div class="card-body p-0">
                <?php if ($thresholdAlerts): ?>
                    <ul class="list-group list-group-flush">
                        <?php foreach ($thresholdAlerts as $ta): ?>
                            <li class="list-group-item d-flex justify-content-between align-items-center">
                                <span class="small fw-semibold text-truncate" style="max-width: 140px;" title="<?= e($ta['name']) ?>">
                                    <?= e($ta['name']) ?>
                                </span>
                                <?php if ($ta['alert_count'] > 0): ?>
                                    <span class="badge bg-danger"><?= $ta['alert_count'] ?> alert<?= $ta['alert_count'] > 1 ? 's' : '' ?></span>
                                <?php else: ?>
                                    <span class="badge bg-warning text-dark">Over Limit</span>
                                <?php endif; ?>
                            </li>
                        <?php endforeach; ?>
                    </ul>
                <?php else: ?>
                    <div class="p-3 text-center text-muted small">
                        <i class="fa fa-check-circle text-success fa-2x mb-2 d-block"></i>
                        All stock & bandwidth levels are healthy.
                    </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
</div>

<!-- Add / Edit Device Form (Figure 3.2.5 template card style) -->
<div class="row justify-content-center align-items-center mt-3 mb-5" id="add-device-card">
    <div class="col-md-8 col-lg-6">
        <div class="card border-0 shadow-sm">
            <div class="card-header bg-white border-bottom p-3 d-flex justify-content-between align-items-center">
                <h5 class="mb-0 fw-bold">
                    <i class="fa fa-plus-circle me-2 text-primary"></i>
                    <?= $edit ? 'Edit Monitored Device' : 'New Device' ?>
                </h5>
                <?php if ($edit): ?>
                    <a href="devices.php" class="btn-close" aria-label="Close"></a>
                <?php endif; ?>
            </div>
            <div class="card-body p-4">
                <form action="devices.php" method="POST">
                    <input type="hidden" name="csrf" value="<?= csrf_token() ?>">
                    <input type="hidden" name="action" value="save">
                    <input type="hidden" name="id" value="<?= (int)($edit['id'] ?? 0) ?>">

                    <div class="mb-3">
                        <label class="form-label small text-muted mb-1">Device Name</label>
                        <input type="text" name="name" class="form-control form-control-sm" placeholder="e.g. Cisco Core Router 2901" required value="<?= e($edit['name'] ?? '') ?>">
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-6">
                            <label class="form-label small text-muted mb-1">IP Address</label>
                            <input type="text" name="ip_address" class="form-control form-control-sm" placeholder="192.168.1.1" required value="<?= e($edit['ip_address'] ?? '') ?>">
                        </div>
                        <div class="col-6">
                            <label class="form-label small text-muted mb-1">Location / NOC</label>
                            <input type="text" name="location" class="form-control form-control-sm" placeholder="Server Room A" value="<?= e($edit['location'] ?? 'Kisii NOC') ?>">
                        </div>
                    </div>

                    <div class="row g-2 mb-3">
                        <div class="col-4">
                            <label class="form-label small text-muted mb-1">DL Limit (MB)</label>
                            <input type="number" step="0.01" name="download_limit_mb" class="form-control form-control-sm" placeholder="5000" value="<?= e($edit['download_limit_mb'] ?? 5000) ?>" required>
                        </div>
                        <div class="col-4">
                            <label class="form-label small text-muted mb-1">UL Limit (MB)</label>
                            <input type="number" step="0.01" name="upload_limit_mb" class="form-control form-control-sm" placeholder="2000" value="<?= e($edit['upload_limit_mb'] ?? 2000) ?>" required>
                        </div>
                        <div class="col-4">
                            <label class="form-label small text-muted mb-1">Category / Type</label>
                            <select name="device_type" class="form-select form-select-sm">
                                <?php foreach (['Router', 'Switch', 'Access Point', 'Firewall', 'Server'] as $type): ?>
                                    <option value="<?= $type ?>" <?= (($edit['device_type'] ?? 'Router') === $type) ? 'selected' : '' ?>><?= $type ?></option>
                                <?php endforeach; ?>
                            </select>
                        </div>
                    </div>

                    <div class="mb-4">
                        <label class="form-label small text-muted mb-1">Operational Status</label>
                        <select name="status" class="form-select form-select-sm">
                            <option value="online" <?= (($edit['status'] ?? 'online') === 'online') ? 'selected' : '' ?>>Online</option>
                            <option value="offline" <?= (($edit['status'] ?? '') === 'offline') ? 'selected' : '' ?>>Offline</option>
                            <option value="maintenance" <?= (($edit['status'] ?? '') === 'maintenance') ? 'selected' : '' ?>>Maintenance</option>
                        </select>
                    </div>

                    <div class="d-grid">
                        <button type="submit" class="btn btn-primary btn-sm py-2 fw-semibold">
                            <?= $edit ? 'Update Device Settings' : 'Add Device to Inventory' ?>
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>

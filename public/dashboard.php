<?php
require_once __DIR__ . '/../includes/auth.php';

$stats = [
    'devices' => 0,
    'online' => 0,
    'alerts' => 0,
    'today_mb' => 0.0
];

try {
    $stats['devices'] = (int)db()->query('SELECT COUNT(*) FROM devices')->fetchColumn();
    $stats['online'] = (int)db()->query("SELECT COUNT(*) FROM devices WHERE status='online'")->fetchColumn();
    $stats['alerts'] = (int)db()->query('SELECT COUNT(*) FROM alerts WHERE is_resolved=0')->fetchColumn();
    $stats['today_mb'] = (float)db()->query('SELECT COALESCE(SUM(download_mb + upload_mb), 0) FROM usage_metrics WHERE DATE(recorded_at) = CURDATE()')->fetchColumn();
} catch (Throwable $e) {}

$devices = [];
try {
    $devices = db()->query('SELECT d.*, 
        (SELECT COALESCE(SUM(download_mb + upload_mb), 0) FROM usage_metrics m WHERE m.device_id = d.id AND m.recorded_at >= NOW() - INTERVAL 24 HOUR) AS usage_mb 
        FROM devices d 
        ORDER BY d.id DESC 
        LIMIT 8')->fetchAll();
} catch (Throwable $e) {}

$alerts = [];
try {
    $alerts = db()->query('SELECT a.*, d.name AS device_name, d.ip_address 
        FROM alerts a 
        JOIN devices d ON d.id = a.device_id 
        WHERE a.is_resolved = 0 
        ORDER BY a.created_at DESC 
        LIMIT 5')->fetchAll();
} catch (Throwable $e) {}

$title = 'Dashboard Overview';
require __DIR__ . '/../includes/header.php';
?>

<!-- Dashboard Heading and Stats -->
<div class="row mb-5 align-items-center">
    <div class="col-md-8">
        <h1 class="fw-bold text-dark">Dashboard Overview</h1>
        <p class="text-muted mb-0">Welcome to the internal network usage monitoring and infrastructure portal.</p>
    </div>
    <div class="col-md-4 text-md-end mt-3 mt-md-0">
        <a href="devices.php#add-device-card" class="btn btn-primary px-4 shadow-sm"><i class="fa fa-plus me-2"></i>Add Device</a>
    </div>
</div>

<div class="row g-4 mb-5">
    <!-- Total Monitored Devices Card -->
    <div class="col-12 col-md-4">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body p-4 text-center">
                <div class="mb-2 text-primary opacity-75">
                    <i class="fa fa-server fa-2x"></i>
                </div>
                <h6 class="text-muted text-uppercase mb-1 text-primary" style="font-size: 0.72rem; letter-spacing: 0.5px;">Total Inventory</h6>
                <h3 class="fw-bold mb-0 text-dark"><?= $stats['devices'] ?></h3>
            </div>
        </div>
    </div>

    <!-- Low Stock / Active Alerts Card -->
    <div class="col-12 col-md-4">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body p-4 text-center">
                <div class="mb-2 <?= $stats['alerts'] > 0 ? 'text-danger' : 'text-success' ?> opacity-75">
                    <i class="fa fa-exclamation-triangle fa-2x"></i>
                </div>
                <h6 class="text-muted text-uppercase mb-1" style="font-size: 0.72rem; letter-spacing: 0.5px;">Threshold Alerts</h6>
                <h3 class="fw-bold mb-0 <?= $stats['alerts'] > 0 ? 'text-danger' : 'text-success' ?>"><?= $stats['alerts'] ?></h3>
            </div>
        </div>
    </div>

    <!-- Today's Traffic Card -->
    <div class="col-12 col-md-4">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body p-4 text-center">
                <div class="mb-2 text-success opacity-75">
                    <i class="fa fa-bar-chart fa-2x"></i>
                </div>
                <h6 class="text-muted text-uppercase mb-1" style="font-size: 0.72rem; letter-spacing: 0.5px;">Today's Traffic</h6>
                <h3 class="fw-bold mb-0 text-success"><?= number_format($stats['today_mb'], 1) ?> MB</h3>
            </div>
        </div>
    </div>
</div>

<!-- Main Content Area: Monitored Devices -->
<div class="mb-5" id="featured">
    <div class="d-flex justify-content-between align-items-center mb-4 border-bottom pb-3">
        <h3 class="fw-bold mb-0 text-dark">Monitored Infrastructure</h3>
        <a href="devices.php" class="btn btn-dark px-4 shadow-sm">View Full Inventory</a>
    </div>

    <?php if ($devices): ?>
        <div class="row row-cols-1 row-cols-md-2 row-cols-lg-4 g-4">
            <?php foreach ($devices as $d): 
                $icon = 'server';
                $typeLower = strtolower($d['device_type'] ?? '');
                if (str_contains($typeLower, 'router')) $icon = 'random';
                elseif (str_contains($typeLower, 'switch')) $icon = 'exchange';
                elseif (str_contains($typeLower, 'point') || str_contains($typeLower, 'wifi')) $icon = 'wifi';
                elseif (str_contains($typeLower, 'firewall')) $icon = 'shield';
            ?>
                <div class="col">
                    <div class="card h-100 border-0 shadow-sm">
                        <div class="card-header bg-transparent border-0 p-0 position-relative">
                            <?php if ($d['status'] === 'online'): ?>
                                <span class="badge bg-success position-absolute top-0 end-0 m-3 shadow-sm rounded-1">Online</span>
                            <?php elseif ($d['status'] === 'maintenance'): ?>
                                <span class="badge bg-warning text-dark position-absolute top-0 end-0 m-3 shadow-sm rounded-1">Maintenance</span>
                            <?php else: ?>
                                <span class="badge bg-danger position-absolute top-0 end-0 m-3 shadow-sm rounded-1">Offline</span>
                            <?php endif; ?>
                            
                            <div class="img-wrapper d-flex align-items-center justify-content-center bg-light rounded-top" style="height: 180px;">
                                <div class="device-glyph">
                                    <i class="fa fa-<?= $icon ?>"></i>
                                </div>
                            </div>
                        </div>

                        <div class="card-body d-flex flex-column p-4">
                            <div class="mb-2">
                                <small class="text-uppercase text-muted fw-bold" style="font-size: 0.72rem; letter-spacing: 1px;">
                                    <?= e($d['device_type']) ?>
                                </small>
                            </div>
                            <h5 class="card-title fw-bold text-dark mb-1 text-truncate" title="<?= e($d['name']) ?>">
                                <?= e($d['name']) ?>
                            </h5>
                            <p class="card-text text-secondary mb-3 small">
                                <?= e($d['ip_address']) ?> · <?= e($d['location'] ?? 'Kisii NOC') ?>
                            </p>

                            <div class="mt-auto pt-3 border-top d-flex justify-content-between align-items-center">
                                <div class="me-2">
                                    <span class="d-block text-muted small">24h Traffic</span>
                                    <span class="fw-bold text-dark fs-6"><?= number_format($d['usage_mb'], 1) ?> MB</span>
                                </div>
                                <a href="metrics.php?device_id=<?= $d['id'] ?>" class="btn btn-dark px-3 shadow-sm text-nowrap">
                                    <i class="fa fa-tachometer me-1"></i> Log
                                </a>
                            </div>
                        </div>
                    </div>
                </div>
            <?php endforeach; ?>
        </div>
    <?php else: ?>
        <div class="text-center py-5">
            <div class="display-1 text-muted opacity-25 mb-3"><i class="fa fa-server"></i></div>
            <h4 class="text-muted">No devices available in the inventory.</h4>
            <p class="text-muted mb-4 opacity-75">Start managing your network infrastructure by adding a new device.</p>
            <a href="devices.php#add-device-card" class="btn btn-primary px-4">Add First Device</a>
        </div>
    <?php endif; ?>
</div>

<!-- Active Threshold Alerts Section -->
<?php if ($alerts): ?>
    <div class="card border-0 shadow-sm mb-5">
        <div class="card-header bg-white border-bottom p-3 d-flex justify-content-between align-items-center">
            <h5 class="mb-0 fw-bold text-dark"><i class="fa fa-exclamation-triangle text-danger me-2"></i>Active Threshold Alerts</h5>
            <a href="alerts.php" class="btn btn-sm btn-outline-primary">View All Alerts</a>
        </div>
        <div class="card-body p-0">
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead class="table-light">
                        <tr>
                            <th class="ps-3">Device</th>
                            <th>IP Address</th>
                            <th>Alert Message</th>
                            <th>Severity</th>
                            <th>Time</th>
                            <th class="text-end pe-3">Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach ($alerts as $a): ?>
                            <tr>
                                <td class="ps-3 fw-bold"><?= e($a['device_name']) ?></td>
                                <td><code><?= e($a['ip_address']) ?></code></td>
                                <td><?= e($a['message']) ?></td>
                                <td>
                                    <span class="badge <?= $a['severity'] === 'critical' ? 'bg-danger' : 'bg-warning text-dark' ?>">
                                        <?= ucfirst($a['severity']) ?>
                                    </span>
                                </td>
                                <td class="text-muted small"><?= e($a['created_at']) ?></td>
                                <td class="text-end pe-3">
                                    <a href="alerts.php" class="btn btn-sm btn-outline-primary">Manage</a>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
<?php endif; ?>

<?php require __DIR__ . '/../includes/footer.php'; ?>

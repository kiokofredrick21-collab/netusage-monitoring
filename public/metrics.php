<?php
require_once __DIR__ . '/../includes/auth.php';

// Record metric POST handling
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    verify_csrf();
    $device = (int)($_POST['device_id'] ?? 0);
    $download = (float)($_POST['download_mb'] ?? 0);
    $upload = (float)($_POST['upload_mb'] ?? 0);
    $latency = (float)($_POST['latency_ms'] ?? 0);
    $loss = (float)($_POST['packet_loss_percent'] ?? 0);

    if ($device > 0) {
        $pdo = db();
        $pdo->beginTransaction();

        $stmt = $pdo->prepare('INSERT INTO usage_metrics (device_id, download_mb, upload_mb, latency_ms, packet_loss_percent) VALUES (?, ?, ?, ?, ?)');
        $stmt->execute([$device, $download, $upload, $latency, $loss]);
        $metricId = $pdo->lastInsertId();

        $dStmt = $pdo->prepare('SELECT * FROM devices WHERE id = ?');
        $dStmt->execute([$device]);
        $dev = $dStmt->fetch();

        // Check download threshold
        if ($dev && $download > $dev['download_limit_mb']) {
            $pdo->prepare('INSERT INTO alerts (device_id, metric_id, alert_type, message, severity) VALUES (?, ?, ?, ?, ?)')
                ->execute([$device, $metricId, 'download_limit', "Download traffic ({$download} MB) exceeded threshold limit ({$dev['download_limit_mb']} MB)", 'critical']);
        }
        // Check upload threshold
        if ($dev && $upload > $dev['upload_limit_mb']) {
            $pdo->prepare('INSERT INTO alerts (device_id, metric_id, alert_type, message, severity) VALUES (?, ?, ?, ?, ?)')
                ->execute([$device, $metricId, 'upload_limit', "Upload traffic ({$upload} MB) exceeded threshold limit ({$dev['upload_limit_mb']} MB)", 'warning']);
        }

        $pdo->prepare("UPDATE devices SET status = 'online', last_seen = NOW() WHERE id = ?")->execute([$device]);
        $pdo->commit();

        $_SESSION['flash'] = 'Metric recorded and threshold limits evaluated successfully.';
    }

    redirect('metrics.php');
}

$devices = db()->query('SELECT * FROM devices ORDER BY name')->fetchAll();
$metrics = db()->query('SELECT m.*, d.name AS device_name, d.ip_address, (m.download_mb + m.upload_mb) AS total_mb 
    FROM usage_metrics m 
    JOIN devices d ON d.id = m.device_id 
    ORDER BY m.recorded_at DESC 
    LIMIT 40')->fetchAll();

$selectedDeviceId = (int)($_GET['device_id'] ?? 0);

$title = 'Real-Time Transaction Logs';
require __DIR__ . '/../includes/header.php';
?>

<!-- Header with Action Button -->
<div class="mb-4 d-flex justify-content-between align-items-center flex-wrap gap-2">
    <div>
        <h2 class="fw-bold text-dark mb-0">Real-Time Transaction Logs</h2>
        <p class="text-muted mb-0">Audit trail for all network metric logs and device bandwidth movements.</p>
    </div>
    <div class="d-flex gap-2">
        <a href="#metric-form-card" class="btn btn-primary" onclick="document.getElementById('metric-form-card').scrollIntoView({behavior: 'smooth'})">
            <i class="fa fa-plus me-1"></i> Log Reading
        </a>
        <a href="reports.php" class="btn btn-outline-primary">
            Summary Report
        </a>
    </div>
</div>

<!-- Desktop Table View (Hidden on Mobile) -->
<div class="d-none d-md-block mb-4">
    <div class="card shadow-sm border-0">
        <div class="card-body p-0">
            <div class="table-responsive">
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
                        <?php foreach ($metrics as $m): 
                            $dt = new DateTime($m['recorded_at']);
                        ?>
                            <tr>
                                <td class="ps-3 text-muted">
                                    <div class="d-flex flex-column" style="line-height: 1.1;">
                                        <span class="fw-bold text-dark"><?= $dt->format('H:i') ?></span>
                                        <small style="font-size: 0.75rem;"><?= $dt->format('d/m') ?></small>
                                    </div>
                                </td>
                                <td>
                                    <span class="fw-bold text-dark"><?= e($m['device_name']) ?></span>
                                    <small class="d-block text-muted"><code><?= e($m['ip_address']) ?></code></small>
                                </td>
                                <td class="text-center"><?= number_format($m['download_mb'], 2) ?></td>
                                <td class="text-center"><?= number_format($m['upload_mb'], 2) ?></td>
                                <td class="text-center">
                                    <span class="badge bg-light text-dark border"><?= number_format($m['latency_ms'], 1) ?> ms</span>
                                    <span class="badge bg-light text-secondary border"><?= number_format($m['packet_loss_percent'], 1) ?>% loss</span>
                                </td>
                                <td class="text-end pe-3 text-success fw-bold">
                                    <?= number_format($m['total_mb'], 2) ?> MB
                                </td>
                            </tr>
                        <?php endforeach; ?>
                        <?php if (!$metrics): ?>
                            <tr>
                                <td colspan="6" class="text-center py-4 text-muted">No metric transactions recorded yet.</td>
                            </tr>
                        <?php endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<!-- Mobile Card View (Visible only on Mobile) -->
<div class="d-md-none mb-4">
    <?php foreach ($metrics as $m): 
        $dt = new DateTime($m['recorded_at']);
    ?>
        <div class="card shadow-sm border-0 mb-3">
            <div class="card-body p-3">
                <div class="d-flex justify-content-between align-items-start mb-2">
                    <h6 class="fw-bold text-dark mb-0 text-truncate" style="max-width: 70%;">
                        <?= e($m['device_name']) ?>
                    </h6>
                    <span class="text-success fw-bold"><?= number_format($m['total_mb'], 2) ?> MB</span>
                </div>
                <div class="d-flex justify-content-between align-items-center text-muted small">
                    <div>
                        <i class="fa fa-clock-o me-1"></i> <?= $dt->format('d/m H:i') ?>
                    </div>
                    <div>
                        DL: <span class="fw-bold text-dark"><?= number_format($m['download_mb'], 1) ?> MB</span> · 
                        UL: <span class="fw-bold text-dark"><?= number_format($m['upload_mb'], 1) ?> MB</span>
                    </div>
                </div>
            </div>
        </div>
    <?php endforeach; ?>
    <?php if (!$metrics): ?>
        <div class="text-center py-5 text-muted">
            <i class="fa fa-info-circle fa-2x mb-3 opacity-25"></i>
            <p>No transactions recorded yet.</p>
        </div>
    <?php endif; ?>
</div>

<!-- Record Performance Metric Form -->
<div class="card border-0 shadow-sm mt-4 mb-5" id="metric-form-card">
    <div class="card-header bg-white border-bottom p-3">
        <h5 class="mb-0 fw-bold text-dark"><i class="fa fa-tachometer text-primary me-2"></i>Record Device Performance Reading</h5>
    </div>
    <div class="card-body p-4">
        <form action="metrics.php" method="POST">
            <input type="hidden" name="csrf" value="<?= csrf_token() ?>">

            <div class="row g-3">
                <div class="col-md-4">
                    <label class="form-label small text-muted mb-1">Target Device</label>
                    <select name="device_id" class="form-select" required>
                        <option value="">-- Choose Device --</option>
                        <?php foreach ($devices as $d): ?>
                            <option value="<?= $d['id'] ?>" <?= ($selectedDeviceId === (int)$d['id']) ? 'selected' : '' ?>>
                                <?= e($d['name']) ?> (<?= e($d['ip_address']) ?>)
                            </option>
                        <?php endforeach; ?>
                    </select>
                </div>
                <div class="col-md-2">
                    <label class="form-label small text-muted mb-1">Download (MB)</label>
                    <input type="number" step="0.01" min="0" name="download_mb" class="form-control" placeholder="0.00" required>
                </div>
                <div class="col-md-2">
                    <label class="form-label small text-muted mb-1">Upload (MB)</label>
                    <input type="number" step="0.01" min="0" name="upload_mb" class="form-control" placeholder="0.00" required>
                </div>
                <div class="col-md-2">
                    <label class="form-label small text-muted mb-1">Latency (ms)</label>
                    <input type="number" step="0.1" min="0" name="latency_ms" class="form-control" value="15.0">
                </div>
                <div class="col-md-2">
                    <label class="form-label small text-muted mb-1">Packet Loss (%)</label>
                    <input type="number" step="0.1" min="0" max="100" name="packet_loss_percent" class="form-control" value="0.0">
                </div>
            </div>

            <div class="mt-4 text-end">
                <button type="submit" class="btn btn-primary px-4 fw-semibold">
                    <i class="fa fa-check me-1"></i> Save Metric Reading
                </button>
            </div>
        </form>
    </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>

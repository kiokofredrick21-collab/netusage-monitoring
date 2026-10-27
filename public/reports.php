<?php
require_once __DIR__ . '/../includes/auth.php';

$from = $_GET['from'] ?? date('Y-m-01');
$to = $_GET['to'] ?? date('Y-m-d');
$params = [$from . ' 00:00:00', $to . ' 23:59:59'];

// Total bandwidth for the selected period
$stmtTotal = db()->prepare('SELECT COALESCE(SUM(download_mb + upload_mb), 0) FROM usage_metrics WHERE recorded_at BETWEEN ? AND ?');
$stmtTotal->execute($params);
$totalBandwidth = (float)$stmtTotal->fetchColumn();

// Top bandwidth consuming devices
$stmtTop = db()->prepare('SELECT d.name, SUM(m.download_mb + m.upload_mb) AS total_mb 
    FROM usage_metrics m 
    JOIN devices d ON d.id = m.device_id 
    WHERE m.recorded_at BETWEEN ? AND ? 
    GROUP BY d.id 
    ORDER BY total_mb DESC 
    LIMIT 5');
$stmtTop->execute($params);
$topDevices = $stmtTop->fetchAll();

// Detailed daily breakdown table
$sql = 'SELECT DATE(m.recorded_at) AS day, d.name AS device_name, 
        SUM(m.download_mb) AS download_mb, SUM(m.upload_mb) AS upload_mb, 
        AVG(m.latency_ms) AS latency_ms, AVG(m.packet_loss_percent) AS packet_loss 
        FROM usage_metrics m 
        JOIN devices d ON d.id = m.device_id 
        WHERE m.recorded_at BETWEEN ? AND ? 
        GROUP BY DATE(m.recorded_at), d.id 
        ORDER BY day DESC, d.name';
$stmt = db()->prepare($sql);
$stmt->execute($params);
$rows = $stmt->fetchAll();

// CSV Export
if (isset($_GET['export'])) {
    header('Content-Type: text/csv; charset=utf-8');
    header('Content-Disposition: attachment; filename="netusage-report-' . $from . '-to-' . $to . '.csv"');
    $out = fopen('php://output', 'w');
    fputcsv($out, ['Date', 'Device', 'Download MB', 'Upload MB', 'Total MB', 'Average Latency ms', 'Average Packet Loss %']);
    foreach ($rows as $r) {
        fputcsv($out, [
            $r['day'],
            $r['device_name'],
            $r['download_mb'],
            $r['upload_mb'],
            $r['download_mb'] + $r['upload_mb'],
            number_format($r['latency_ms'], 2),
            number_format($r['packet_loss'], 2)
        ]);
    }
    exit;
}

$title = 'Business Sales Reports';
require __DIR__ . '/../includes/header.php';
?>

<div class="mb-4">
    <h2 class="fw-bold text-dark">Business Sales Reports</h2>
    <p class="text-muted mb-0">Analyze your network's bandwidth consumption, usage trends, and system performance.</p>
</div>

<!-- Summary Row (Matching Figure 3.2.7) -->
<div class="row mb-4">
    <!-- Total Bandwidth Card (col-md-4) -->
    <div class="col-md-4 mb-4">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-body py-4 text-center d-flex flex-column justify-content-center">
                <div class="mb-2 text-success opacity-75">
                    <i class="fa fa-area-chart fa-2x"></i>
                </div>
                <h6 class="text-muted text-uppercase mb-1" style="font-size: 0.72rem; letter-spacing: 0.5px;">Total Bandwidth Monitored</h6>
                <h3 class="fw-bold mb-0 text-success"><?= number_format($totalBandwidth, 1) ?> MB</h3>
                <small class="text-muted mt-1"><?= e($from) ?> to <?= e($to) ?></small>
            </div>
        </div>
    </div>

    <!-- Top Performing / Consuming Devices (col-md-8) -->
    <div class="col-md-8 mb-4">
        <div class="card border-0 shadow-sm h-100">
            <div class="card-header bg-white border-bottom p-3">
                <h5 class="mb-0 fw-bold text-dark">Top Bandwidth Devices</h5>
            </div>
            <div class="card-body p-0">
                <div class="table-responsive">
                    <table class="table table-hover align-middle mb-0">
                        <thead class="table-light">
                            <tr>
                                <th class="ps-4">Device Name</th>
                                <th class="text-end pe-4" style="width: 1%; white-space: nowrap;">Total MB</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php if ($topDevices): ?>
                                <?php foreach ($topDevices as $td): ?>
                                    <tr>
                                        <td class="ps-4 fw-medium text-dark"><?= e($td['name']) ?></td>
                                        <td class="text-end pe-4">
                                            <span class="fw-bold text-dark"><?= number_format($td['total_mb'], 1) ?></span>
                                        </td>
                                    </tr>
                                <?php endforeach; ?>
                            <?php else: ?>
                                <tr>
                                    <td colspan="2" class="text-center py-4 text-muted opacity-75">No metric recordings found in the date range.</td>
                                </tr>
                            <?php endif; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Filter and Detailed Report Table -->
<div class="card border-0 shadow-sm mb-4">
    <div class="card-header bg-white border-bottom p-3 d-flex justify-content-between align-items-center flex-wrap gap-2">
        <h5 class="mb-0 fw-bold text-dark"><i class="fa fa-filter me-2 text-primary"></i>Daily Usage Breakdown</h5>
        <a class="btn btn-outline-primary btn-sm px-3" href="?from=<?= urlencode($from) ?>&to=<?= urlencode($to) ?>&export=1">
            <i class="fa fa-download me-1"></i> Export CSV
        </a>
    </div>
    <div class="card-body p-3">
        <form class="row g-2 align-items-end mb-3" method="GET">
            <div class="col-sm-4 col-md-3">
                <label class="form-label small text-muted mb-1">From Date</label>
                <input type="date" name="from" class="form-control form-control-sm" value="<?= e($from) ?>">
            </div>
            <div class="col-sm-4 col-md-3">
                <label class="form-label small text-muted mb-1">To Date</label>
                <input type="date" name="to" class="form-control form-control-sm" value="<?= e($to) ?>">
            </div>
            <div class="col-sm-4 col-md-2">
                <button class="btn btn-primary btn-sm w-100" type="submit">Apply Filters</button>
            </div>
        </form>

        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th>Date</th>
                        <th>Device</th>
                        <th>Download</th>
                        <th>Upload</th>
                        <th>Avg Latency</th>
                        <th>Avg Loss</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($rows as $r): ?>
                        <tr>
                            <td><?= e($r['day']) ?></td>
                            <td class="fw-bold text-dark"><?= e($r['device_name']) ?></td>
                            <td><?= number_format($r['download_mb'], 2) ?> MB</td>
                            <td><?= number_format($r['upload_mb'], 2) ?> MB</td>
                            <td><?= number_format($r['latency_ms'], 2) ?> ms</td>
                            <td><?= number_format($r['packet_loss'], 2) ?>%</td>
                        </tr>
                    <?php endforeach; ?>
                    <?php if (!$rows): ?>
                        <tr>
                            <td colspan="6" class="text-center py-4 text-muted">No data available for the selected period.</td>
                        </tr>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Recent Activity Banner (Matching Figure 3.2.7) -->
<div class="card border-0 shadow-sm mb-5">
    <div class="card-header bg-white border-bottom p-3 d-flex justify-content-between align-items-center">
        <h5 class="mb-0 fw-bold text-dark">Recent Activity</h5>
        <a href="metrics.php" class="btn btn-sm btn-outline-primary px-3">View Full Logs</a>
    </div>
    <div class="card-body p-4 text-center">
        <p class="text-muted mb-3">View detailed records of every transaction including Times, reference IDs, and performance values.</p>
        <a href="metrics.php" class="btn btn-primary px-4 shadow-sm">Access Transaction Ledger</a>
    </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>

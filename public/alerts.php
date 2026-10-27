<?php
require_once __DIR__ . '/../includes/auth.php';

// Handle alert resolution POST
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    verify_csrf();
    $id = (int)($_POST['id'] ?? 0);
    if ($id > 0) {
        $stmt = db()->prepare('UPDATE alerts SET is_resolved = 1, resolved_at = NOW() WHERE id = ?');
        $stmt->execute([$id]);
        $_SESSION['flash'] = 'Alert marked as resolved.';
    }
    redirect('alerts.php');
}

$alerts = db()->query('SELECT a.*, d.name AS device_name, d.ip_address 
    FROM alerts a 
    JOIN devices d ON d.id = a.device_id 
    ORDER BY a.is_resolved ASC, a.created_at DESC')->fetchAll();

$openCount = 0;
$resolvedCount = 0;
foreach ($alerts as $a) {
    if ($a['is_resolved']) $resolvedCount++;
    else $openCount++;
}

$title = 'Threshold Alerts Center';
require __DIR__ . '/../includes/header.php';
?>

<div class="mb-4 d-flex justify-content-between align-items-center flex-wrap gap-2">
    <div>
        <h2 class="fw-bold text-dark mb-0">Threshold Alerts Center</h2>
        <p class="text-muted mb-0">Monitor network anomalies, bandwidth threshold breaches, and outage incidents.</p>
    </div>
    <div class="d-flex gap-2">
        <span class="badge bg-danger fs-6 px-3 py-2"><?= $openCount ?> Unresolved</span>
        <span class="badge bg-success fs-6 px-3 py-2"><?= $resolvedCount ?> Resolved</span>
    </div>
</div>

<div class="card shadow-sm border-0 mb-5">
    <div class="card-header bg-white border-bottom p-3 d-flex justify-content-between align-items-center">
        <h5 class="mb-0 fw-bold text-dark"><i class="fa fa-bell-o text-danger me-2"></i>Incident Audit Trail</h5>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-dark">
                    <tr>
                        <th class="ps-3">Logged At</th>
                        <th>Device & IP</th>
                        <th>Incident Description</th>
                        <th>Severity</th>
                        <th>Status</th>
                        <th class="text-end pe-3">Action</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($alerts as $a): 
                        $dt = new DateTime($a['created_at']);
                    ?>
                        <tr>
                            <td class="ps-3 text-muted">
                                <div class="d-flex flex-column" style="line-height: 1.1;">
                                    <span class="fw-bold text-dark"><?= $dt->format('H:i:s') ?></span>
                                    <small style="font-size: 0.75rem;"><?= $dt->format('d/m/Y') ?></small>
                                </div>
                            </td>
                            <td>
                                <strong class="text-dark"><?= e($a['device_name']) ?></strong>
                                <small class="d-block text-muted"><code><?= e($a['ip_address']) ?></code></small>
                            </td>
                            <td><?= e($a['message']) ?></td>
                            <td>
                                <?php if ($a['severity'] === 'critical'): ?>
                                    <span class="badge bg-danger">Critical</span>
                                <?php elseif ($a['severity'] === 'warning'): ?>
                                    <span class="badge bg-warning text-dark">Warning</span>
                                <?php else: ?>
                                    <span class="badge bg-info text-dark">Info</span>
                                <?php endif; ?>
                            </td>
                            <td>
                                <?php if ($a['is_resolved']): ?>
                                    <span class="badge bg-success"><i class="fa fa-check me-1"></i>Resolved</span>
                                    <small class="d-block text-muted" style="font-size: 0.7rem;"><?= e($a['resolved_at']) ?></small>
                                <?php else: ?>
                                    <span class="badge bg-danger"><i class="fa fa-circle-o me-1"></i>Open</span>
                                <?php endif; ?>
                            </td>
                            <td class="text-end pe-3">
                                <?php if (!$a['is_resolved']): ?>
                                    <form method="POST" action="alerts.php" class="d-inline">
                                        <input type="hidden" name="csrf" value="<?= csrf_token() ?>">
                                        <input type="hidden" name="id" value="<?= $a['id'] ?>">
                                        <button type="submit" class="btn btn-sm btn-outline-success">
                                            <i class="fa fa-check me-1"></i> Resolve
                                        </button>
                                    </form>
                                <?php else: ?>
                                    <span class="text-muted small"><i class="fa fa-check-circle text-success"></i> Fixed</span>
                                <?php endif; ?>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                    <?php if (!$alerts): ?>
                        <tr>
                            <td colspan="6" class="text-center py-5 text-muted">
                                <i class="fa fa-check-circle fa-2x text-success mb-2 d-block"></i>
                                No system alerts recorded. All network devices are operating within normal parameters.
                            </td>
                        </tr>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<?php require __DIR__ . '/../includes/footer.php'; ?>

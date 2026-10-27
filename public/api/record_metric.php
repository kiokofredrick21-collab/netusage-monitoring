<?php
require_once __DIR__ . '/../../includes/auth.php';
header('Content-Type: application/json; charset=utf-8');

if (!user()) {
    http_response_code(401);
    echo json_encode(['error' => 'Authentication required']);
    exit;
}

$data = json_decode(file_get_contents('php://input'), true) ?: $_POST;

$device = (int)($data['device_id'] ?? 0);
$download = (float)($data['download_mb'] ?? 0);
$upload = (float)($data['upload_mb'] ?? 0);
$latency = (float)($data['latency_ms'] ?? 0);
$loss = (float)($data['packet_loss_percent'] ?? 0);

if (!$device) {
    http_response_code(422);
    echo json_encode(['error' => 'device_id is required']);
    exit;
}

$pdo = db();
$pdo->beginTransaction();

$stmt = $pdo->prepare('INSERT INTO usage_metrics (device_id, download_mb, upload_mb, latency_ms, packet_loss_percent) VALUES (?, ?, ?, ?, ?)');
$stmt->execute([$device, $download, $upload, $latency, $loss]);
$metricId = $pdo->lastInsertId();

$dStmt = $pdo->prepare('SELECT * FROM devices WHERE id = ?');
$dStmt->execute([$device]);
$dev = $dStmt->fetch();

$alertCreated = false;
if ($dev && $download > $dev['download_limit_mb']) {
    $pdo->prepare('INSERT INTO alerts (device_id, metric_id, alert_type, message, severity) VALUES (?, ?, ?, ?, ?)')
        ->execute([$device, $metricId, 'download_limit', "Download traffic ({$download} MB) exceeded cap", 'critical']);
    $alertCreated = true;
}

if ($dev && $upload > $dev['upload_limit_mb']) {
    $pdo->prepare('INSERT INTO alerts (device_id, metric_id, alert_type, message, severity) VALUES (?, ?, ?, ?, ?)')
        ->execute([$device, $metricId, 'upload_limit', "Upload traffic ({$upload} MB) exceeded cap", 'warning']);
    $alertCreated = true;
}

$pdo->prepare("UPDATE devices SET status = 'online', last_seen = NOW() WHERE id = ?")->execute([$device]);
$pdo->commit();

echo json_encode([
    'success' => true,
    'metric_id' => $metricId,
    'alert_created' => $alertCreated
]);

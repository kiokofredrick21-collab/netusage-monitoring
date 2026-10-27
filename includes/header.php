<?php
require_once __DIR__ . '/auth.php';
require_login();

$currentPage = basename($_SERVER['PHP_SELF']);
$activeAlertCount = 0;
try {
    $activeAlertCount = (int)db()->query('SELECT COUNT(*) FROM alerts WHERE is_resolved = 0')->fetchColumn();
} catch (Throwable $e) {}
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= e($title ?? 'Dashboard') ?> | <?= APP_NAME ?></title>
    <!-- Google Fonts: Montserrat -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;500;600;700&display=swap" rel="stylesheet">
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Font Awesome Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
    <!-- App Custom CSS -->
    <link rel="stylesheet" href="assets/css/app.css">
    <script defer src="assets/js/app.js"></script>
</head>
<body>

<!-- Navigation Bar (Template Style) -->
<nav class="navbar navbar-expand-lg navbar-white bg-white border-bottom sticky-top py-2">
    <div class="container-fluid px-4">
        <a class="navbar-brand fw-bold d-flex align-items-center" href="dashboard.php" style="font-size: 1.45rem;">
            <span class="brand-badge me-2"><i class="fa fa-wifi text-primary"></i></span>
            <span class="text-dark">Net-</span><span class="text-primary">Portal</span>
        </a>
        <button class="navbar-toggler border-0" type="button" data-bs-toggle="collapse" data-bs-target="#navbarContent" aria-controls="navbarContent" aria-expanded="false" aria-label="Toggle navigation">
            <span class="navbar-toggler-icon"></span>
        </button>

        <div class="collapse navbar-collapse" id="navbarContent">
            <ul class="navbar-nav me-auto mb-2 mb-lg-0 fw-semibold ms-3">
                <li class="nav-item">
                    <a class="nav-link <?= $currentPage === 'dashboard.php' ? 'text-primary active' : '' ?>" href="dashboard.php">
                        <i class="fa fa-dashboard me-1"></i> Dashboard
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $currentPage === 'devices.php' ? 'text-primary active' : '' ?>" href="devices.php">
                        <i class="fa fa-server me-1"></i> Devices
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $currentPage === 'metrics.php' ? 'text-primary active' : '' ?>" href="metrics.php">
                        <i class="fa fa-line-chart me-1"></i> Usage Metrics
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $currentPage === 'alerts.php' ? 'text-primary active' : '' ?>" href="alerts.php">
                        <i class="fa fa-exclamation-triangle me-1"></i> Alerts
                        <?php if ($activeAlertCount > 0): ?>
                            <span class="badge bg-danger rounded-pill ms-1" style="font-size: 0.65rem;"><?= $activeAlertCount ?></span>
                        <?php endif; ?>
                    </a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <?= $currentPage === 'reports.php' ? 'text-primary active' : '' ?>" href="reports.php">
                        <i class="fa fa-file-text-o me-1"></i> Reports
                    </a>
                </li>
            </ul>

            <!-- Compact Search -->
            <form class="d-flex ms-lg-3 my-2 my-lg-0 search-form-wrap" action="devices.php" method="GET" style="min-width: 300px;">
                <div class="input-group">
                    <input class="form-control form-control-sm bg-light border-secondary border-opacity-25" type="search" name="q" placeholder="Search devices, IP, type..." value="<?= e($_GET['q'] ?? '') ?>">
                    <button class="btn btn-sm btn-primary px-3" type="submit"><i class="fa fa-search"></i></button>
                </div>
            </form>

            <!-- User Info and Logout -->
            <div class="ms-lg-3 d-flex align-items-center mt-2 mt-lg-0">
                <span class="text-muted small me-3 text-nowrap"><i class="fa fa-user-circle me-1"></i> <?= e(user()['full_name'] ?? 'Admin') ?></span>
                <a href="logout.php" class="btn btn-sm btn-outline-secondary px-3">Logout</a>
            </div>
        </div>
    </div>
</nav>

<main class="container-fluid px-4 py-4 flex-grow-1">

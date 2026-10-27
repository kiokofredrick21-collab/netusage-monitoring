<?php
require_once __DIR__ . '/../includes/auth.php';

if (user()) {
    redirect('dashboard.php');
}

$error = null;
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    verify_csrf();
    $username = trim($_POST['username'] ?? '');
    $password = $_POST['password'] ?? '';
    
    if (attempt_login($username, $password)) {
        redirect('dashboard.php');
    }
    $error = 'Invalid username or password.';
}
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Login | Net-Portal</title>
    <!-- Google Fonts: Montserrat -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;500;600;700&display=swap" rel="stylesheet">
    <!-- Bootstrap 5 CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Font Awesome Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css">
    <link rel="stylesheet" href="assets/css/app.css">
    <style>
        body {
            background: #f0f2f5;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
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
        .login-logo {
            width: 70px;
            height: 70px;
            object-fit: contain;
            border-radius: 12px;
            background: rgba(13, 110, 253, 0.08);
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0 auto 16px;
            color: #0d6efd;
            font-size: 30px;
        }
    </style>
</head>
<body>

<div class="login-card">
    <div class="text-center mb-4">
        <div class="login-logo">
            <i class="fa fa-wifi"></i>
        </div>
        <h2 class="fw-bold mb-1"><span class="text-dark">Net-</span><span class="text-primary">Portal</span></h2>
        <p class="text-muted small mb-0">Network Usage Monitoring System</p>
    </div>

    <?php if ($error): ?>
        <div class="alert alert-danger py-2 small mb-3 text-center" role="alert">
            <i class="fa fa-exclamation-circle me-1"></i> <?= e($error) ?>
        </div>
    <?php endif; ?>

    <!-- Login Form -->
    <form action="index.php" method="POST">
        <input type="hidden" name="csrf" value="<?= csrf_token() ?>">

        <div class="mb-3">
            <label class="form-label small text-muted mb-1">Username</label>
            <div class="input-group">
                <span class="input-group-text bg-light border-end-0"><i class="fa fa-user text-muted"></i></span>
                <input type="text" name="username" class="form-control border-start-0 bg-light" placeholder="Enter username" required autofocus>
            </div>
        </div>

        <div class="mb-4">
            <label class="form-label small text-muted mb-1">Password</label>
            <div class="input-group">
                <span class="input-group-text bg-light border-end-0"><i class="fa fa-lock text-muted"></i></span>
                <input type="password" name="password" class="form-control border-start-0 bg-light" placeholder="Enter password" required>
            </div>
        </div>

        <div class="d-grid">
            <button type="submit" class="btn btn-primary py-2 fw-semibold">Sign In</button>
        </div>
    </form>

    <div class="text-center mt-4">
        <p class="text-muted small mb-1">© 2026 Net-Portal. All rights reserved.</p>
        <span class="badge bg-light text-secondary border fw-normal" style="font-size: 0.75rem;">Demo: admin / admin123</span>
    </div>
</div>

</body>
</html>

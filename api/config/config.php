<?php
// Database credentials — read from environment variables (set in Vercel dashboard)
// Falls back to hardcoded InfinityFree values for local/XAMPP use.
define('DB_HOST', getenv('DB_HOST') ?: 'sql313.infinityfree.com');
define('DB_NAME', getenv('DB_NAME') ?: 'if0_43395558_netusage');
define('DB_USER', getenv('DB_USER') ?: 'if0_43395558');
define('DB_PASS', getenv('DB_PASS') ?: 'IGATHufN3ISWG');
define('APP_NAME', 'NetUsage Hub');

date_default_timezone_set('Africa/Nairobi');

// Session: use cookies; Vercel serverless has an ephemeral /tmp filesystem
ini_set('session.save_path', sys_get_temp_dir());
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

function db(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $pdo = new PDO(
            'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
            DB_USER,
            DB_PASS,
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]
        );
    }
    return $pdo;
}

function e(?string $value): string {
    return htmlspecialchars($value ?? '', ENT_QUOTES, 'UTF-8');
}

function redirect(string $path): never {
    header('Location: /' . ltrim($path, '/'));
    exit;
}

function csrf_token(): string {
    if (empty($_SESSION['csrf'])) $_SESSION['csrf'] = bin2hex(random_bytes(32));
    return $_SESSION['csrf'];
}

function verify_csrf(): void {
    if (!hash_equals($_SESSION['csrf'] ?? '', $_POST['csrf'] ?? '')) {
        http_response_code(419);
        exit('Invalid request token. Please go back and try again.');
    }
}

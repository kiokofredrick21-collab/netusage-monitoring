<?php
if (!ob_get_level()) {
    ob_start();
}

// Database credentials — read from environment variables (set in Vercel dashboard)
define('DB_HOST', getenv('DB_HOST') ?: 'sql313.infinityfree.com');
define('DB_NAME', getenv('DB_NAME') ?: 'if0_43395558_netusage');
define('DB_USER', getenv('DB_USER') ?: 'if0_43395558');
define('DB_PASS', getenv('DB_PASS') ?: 'IGATHufN3ISWG');
define('APP_NAME', 'NetUsage Hub');

date_default_timezone_set('Africa/Nairobi');

/**
 * Serverless Cookie-Based Session Handler
 * Serializes and HMAC-signs $_SESSION data inside an HTTP-only cookie.
 * Solves the stateless nature of serverless containers where /tmp is not shared.
 */
class ServerlessCookieSessionHandler implements SessionHandlerInterface {
    private string $key;
    private string $cookieName;

    public function __construct(string $key = 'netusage_portal_secret_token_2026', string $cookieName = 'NETUSAGE_SESS') {
        $this->key = $key;
        $this->cookieName = $cookieName;
    }

    public function open(string $path, string $name): bool { return true; }
    public function close(): bool { return true; }

    public function read(string $id): string|false {
        if (!isset($_COOKIE[$this->cookieName])) return '';
        $parts = explode('.', $_COOKIE[$this->cookieName], 2);
        if (count($parts) !== 2) return '';
        [$payload, $hmac] = $parts;
        if (!hash_equals(hash_hmac('sha256', $payload, $this->key), $hmac)) return '';
        $data = base64_decode($payload, true);
        return $data !== false ? $data : '';
    }

    public function write(string $id, string $data): bool {
        if (!headers_sent()) {
            if (empty($data)) {
                setcookie($this->cookieName, '', [
                    'expires' => time() - 3600,
                    'path' => '/',
                    'httponly' => true,
                    'samesite' => 'Lax'
                ]);
            } else {
                $payload = base64_encode($data);
                $hmac = hash_hmac('sha256', $payload, $this->key);
                setcookie($this->cookieName, $payload . '.' . $hmac, [
                    'expires' => time() + 86400 * 7,
                    'path' => '/',
                    'httponly' => true,
                    'samesite' => 'Lax'
                ]);
            }
        }
        return true;
    }

    public function destroy(string $id): bool {
        if (!headers_sent()) {
            setcookie($this->cookieName, '', [
                'expires' => time() - 3600,
                'path' => '/',
                'httponly' => true,
                'samesite' => 'Lax'
            ]);
        }
        return true;
    }

    public function gc(int $max_lifetime): int|false { return 0; }
}

// Register the serverless cookie session handler if not already started
if (session_status() === PHP_SESSION_NONE && !headers_sent()) {
    session_set_save_handler(new ServerlessCookieSessionHandler(), true);
    session_start();
}

function db(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $pdo = new PDO(
            'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
            DB_USER,
            DB_PASS,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_TIMEOUT => 5
            ]
        );
    }
    return $pdo;
}

function e(?string $value): string {
    return htmlspecialchars($value ?? '', ENT_QUOTES, 'UTF-8');
}

function redirect(string $path): never {
    if (ob_get_level()) {
        ob_end_clean();
    }
    header('Location: /' . ltrim($path, '/'));
    exit;
}

function csrf_token(): string {
    if (empty($_SESSION['csrf'])) {
        $_SESSION['csrf'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf'];
}

function verify_csrf(): void {
    $sessionToken = $_SESSION['csrf'] ?? '';
    $postToken = $_POST['csrf'] ?? '';
    if (empty($sessionToken) || !hash_equals($sessionToken, $postToken)) {
        $_SESSION['csrf'] = bin2hex(random_bytes(32));
        $_SESSION['flash'] = 'Session or security token expired. Please try again.';
        if (basename($_SERVER['PHP_SELF'] ?? '') === 'index.php') {
            throw new RuntimeException('Session or security token expired. Please try again.');
        } else {
            redirect(basename($_SERVER['PHP_SELF'] ?? 'dashboard.php'));
        }
    }
}

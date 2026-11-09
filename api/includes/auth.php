<?php
require_once __DIR__ . '/../config/config.php';

function user(): ?array { return $_SESSION['user'] ?? null; }
function require_login(): void { if (!user()) redirect('index.php'); }

function attempt_login(string $username, string $password): bool {
    try {
        $stmt = db()->prepare('SELECT * FROM users WHERE username = ? LIMIT 1');
        $stmt->execute([$username]);
        $record = $stmt->fetch();
        if ($record && password_verify($password, $record['password_hash'])) {
            session_regenerate_id(true);
            $_SESSION['user'] = [
                'id' => $record['id'],
                'username' => $record['username'],
                'full_name' => $record['full_name'],
                'role' => $record['role']
            ];
            return true;
        }
    } catch (Throwable $e) {
        // If remote database is unreachable (e.g. InfinityFree blocking external Vercel connection)
        // allow the default administrator credentials to sign in for demonstration
        if ($username === 'admin' && $password === 'admin123') {
            session_regenerate_id(true);
            $_SESSION['user'] = [
                'id' => 1,
                'username' => 'admin',
                'full_name' => 'Brenda Chebet Chelule',
                'role' => 'admin',
                'demo_mode' => true
            ];
            $_SESSION['flash'] = 'Connected in Demo Mode: Using sample data because remote database is unreachable from Vercel.';
            return true;
        }
        throw $e;
    }
    return false;
}

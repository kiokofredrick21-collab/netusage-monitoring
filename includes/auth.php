<?php
require_once __DIR__ . '/../config/config.php';

function user(): ?array { return $_SESSION['user'] ?? null; }
function require_login(): void { if (!user()) redirect('index.php'); }
function attempt_login(string $username, string $password): bool {
    $stmt = db()->prepare('SELECT * FROM users WHERE username = ? LIMIT 1');
    $stmt->execute([$username]);
    $record = $stmt->fetch();
    if ($record && password_verify($password, $record['password_hash'])) {
        session_regenerate_id(true);
        $_SESSION['user'] = ['id' => $record['id'], 'username' => $record['username'], 'full_name' => $record['full_name'], 'role' => $record['role']];
        return true;
    }
    return false;
}

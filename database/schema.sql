CREATE DATABASE IF NOT EXISTS netusage_hub CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE netusage_hub;

CREATE TABLE users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(80) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(120) NOT NULL,
    role ENUM('admin','operator') NOT NULL DEFAULT 'admin',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE devices (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(120) NOT NULL,
    ip_address VARCHAR(45) NOT NULL UNIQUE,
    device_type VARCHAR(80) NOT NULL DEFAULT 'Router',
    location VARCHAR(120) NULL,
    status ENUM('online','offline','maintenance') NOT NULL DEFAULT 'offline',
    download_limit_mb DECIMAL(12,2) NOT NULL DEFAULT 5000,
    upload_limit_mb DECIMAL(12,2) NOT NULL DEFAULT 2000,
    last_seen DATETIME NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE usage_metrics (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    device_id INT UNSIGNED NOT NULL,
    download_mb DECIMAL(12,2) NOT NULL DEFAULT 0,
    upload_mb DECIMAL(12,2) NOT NULL DEFAULT 0,
    latency_ms DECIMAL(10,2) NOT NULL DEFAULT 0,
    packet_loss_percent DECIMAL(5,2) NOT NULL DEFAULT 0,
    recorded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_metric_device FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE,
    INDEX idx_metric_device_time (device_id, recorded_at)
) ENGINE=InnoDB;

CREATE TABLE alerts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    device_id INT UNSIGNED NOT NULL,
    metric_id BIGINT UNSIGNED NULL,
    alert_type VARCHAR(60) NOT NULL,
    message VARCHAR(255) NOT NULL,
    severity ENUM('info','warning','critical') NOT NULL DEFAULT 'warning',
    is_resolved TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at DATETIME NULL,
    CONSTRAINT fk_alert_device FOREIGN KEY (device_id) REFERENCES devices(id) ON DELETE CASCADE,
    CONSTRAINT fk_alert_metric FOREIGN KEY (metric_id) REFERENCES usage_metrics(id) ON DELETE SET NULL,
    INDEX idx_alert_status (is_resolved, created_at)
) ENGINE=InnoDB;

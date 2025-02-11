<?php
// Define the base path for the environment file
define('BASE_PATH', dirname(__DIR__));

// Read and parse the .env file
$envFilePath = BASE_PATH . '/.env';
$envData = [];
if (file_exists($envFilePath)) {
    $lines = file($envFilePath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        list($key, $value) = explode('=', $line, 2);
        // Trim whitespace and remove surrounding quotes
        $envData[trim($key)] = trim($value, " \t\n\r\0\x0B\"'");
    }
}

// Read current serial number and macOS version
$currentSerialNumber = file_exists(BASE_PATH . '/data/macos.sn') ? trim(file_get_contents(BASE_PATH . '/data/macos.sn')) : 'N/A';
$currentMacOSVersion = file_exists(BASE_PATH . '/data/macos.version') ? trim(file_get_contents(BASE_PATH . '/data/macos.version')) : 'N/A';

// Check Docker container status
$dockerStatus = [];
exec("docker compose -f " . BASE_PATH . "/docker-compose.yml ps", $dockerOutput);
foreach ($dockerOutput as $line) {
    if (trim($line) !== '') {
        $dockerStatus[] = trim($line);
    }
}

// Determine if any containers are running
$isRunning = count($dockerStatus) > 1; // More than 1 line indicates running
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <title>Environment Setup</title>
</head>
<body>
<div class="container mt-5">
    <h2>Environment Setup</h2>

    <div class="alert alert-info" role="alert">
        <strong>Current Serial Number:</strong> <?php echo htmlspecialchars($currentSerialNumber); ?><br>
        <strong>Current macOS Version:</strong> <?php echo htmlspecialchars($currentMacOSVersion); ?><br>
        <strong>Docker Status:</strong> <?php echo $isRunning ? 'Running' : 'Stopped'; ?><br>
        <?php if ($isRunning): ?>
            <a href="http://78.46.94.39:8006" target="_blank" class="btn btn-info">
                Open Virtual Machine
            </a>
        <?php endif; ?>
    </div>

    <form action="process.php" method="post">
        <div class="form-group">
            <label for="WIREGUARD_PRIVATE_KEY">WIREGUARD_PRIVATE_KEY</label>
            <input type="text" class="form-control" id="WIREGUARD_PRIVATE_KEY" name="WIREGUARD_PRIVATE_KEY" value="<?php echo htmlspecialchars($envData['WIREGUARD_PRIVATE_KEY'] ?? ''); ?>" required>
        </div>
        <div class="form-group">
            <label for="WIREGUARD_ADDRESSES">WIREGUARD_ADDRESSES</label>
            <input type="text" class="form-control" id="WIREGUARD_ADDRESSES" name="WIREGUARD_ADDRESSES" value="<?php echo htmlspecialchars($envData['WIREGUARD_ADDRESSES'] ?? ''); ?>" required>
        </div>
        <div class="form-group">
            <label for="WIREGUARD_ENDPOINT_IP">WIREGUARD_ENDPOINT_IP</label>
            <input type="text" class="form-control" id="WIREGUARD_ENDPOINT_IP" name="WIREGUARD_ENDPOINT_IP" value="<?php echo htmlspecialchars($envData['WIREGUARD_ENDPOINT_IP'] ?? ''); ?>" required>
        </div>
        <div class="form-group">
            <label for="WIREGUARD_ENDPOINT_PORT">WIREGUARD_ENDPOINT_PORT</label>
            <input type="text" class="form-control" id="WIREGUARD_ENDPOINT_PORT" name="WIREGUARD_ENDPOINT_PORT" value="<?php echo htmlspecialchars($envData['WIREGUARD_ENDPOINT_PORT'] ?? ''); ?>" required>
        </div>
        <div class="form-group">
            <label for="WIREGUARD_PUBLIC_KEY">WIREGUARD_PUBLIC_KEY</label>
            <input type="text" class="form-control" id="WIREGUARD_PUBLIC_KEY" name="WIREGUARD_PUBLIC_KEY" value="<?php echo htmlspecialchars($envData['WIREGUARD_PUBLIC_KEY'] ?? ''); ?>" required>
        </div>
        <div class="form-group">
            <label for="WIREGUARD_PRESHARED_KEY">WIREGUARD_PRESHARED_KEY</label>
            <input type="text" class="form-control" id="WIREGUARD_PRESHARED_KEY" name="WIREGUARD_PRESHARED_KEY" value="<?php echo htmlspecialchars($envData['WIREGUARD_PRESHARED_KEY'] ?? ''); ?>">
        </div>
        <div class="form-group">
            <label for="DEVICE_MODEL">DEVICE_MODEL</label>
            <input type="text" class="form-control" id="DEVICE_MODEL" name="DEVICE_MODEL" value="<?php echo htmlspecialchars($envData['DEVICE_MODEL'] ?? ''); ?>" required>
        </div>
        <div class="form-group">
            <label for="MACOS_VERSION">MACOS_VERSION</label>
            <select class="form-control" id="MACOS_VERSION" name="MACOS_VERSION" required>
                <option value="13" <?php echo (isset($envData['MACOS_VERSION']) && $envData['MACOS_VERSION'] == '13') ? 'selected' : ''; ?>>13</option>
                <option value="14" <?php echo (isset($envData['MACOS_VERSION']) && $envData['MACOS_VERSION'] == '14') ? 'selected' : ''; ?>>14</option>
                <option value="15" <?php echo (isset($envData['MACOS_VERSION']) && $envData['MACOS_VERSION'] == '15') ? 'selected' : ''; ?>>15</option>
            </select>
        </div>
        
        <!-- Separate Save Button -->
        <div class="mb-3">
            <button type="submit" name="action" value="save" class="btn btn-success"><i class="fas fa-save"></i> Save Config</button>
        </div>

        <!-- Action Buttons Group -->
        <div class="mb-3">
            <button type="submit" name="action" value="setup" class="btn btn-primary">
                <i class="fas fa-cog"></i> 
                Setup
            </button>
            <button type="submit" name="action" value="continue" class="btn btn-secondary">
                <i class="fas fa-arrow-right"></i> 
                Continue
            </button>
            <button type="submit" name="action" value="stop" class="btn btn-warning">
                <i class="fas fa-stop"></i> 
                Stop
            </button>
            <button type="submit" name="action" value="reset" class="btn btn-danger">
                <i class="fas fa-undo"></i> 
                Reset
            </button>
        </div>
    </form>
</div>
<script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.9.2/dist/umd/popper.min.js"></script>
<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
</body>
</html> 
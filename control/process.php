<?php
// Define the base path for the environment file
define('BASE_PATH', dirname(__DIR__));

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $envFilePath = BASE_PATH . '/.env';
    
    // Check the action
    $action = $_POST['action'];

    // Update the .env file with the submitted values
    $data = [
        "WIREGUARD_PRIVATE_KEY" => trim($_POST['WIREGUARD_PRIVATE_KEY'], " \t\n\r\0\x0B\"'"),
        "WIREGUARD_ADDRESSES" => trim($_POST['WIREGUARD_ADDRESSES'], " \t\n\r\0\x0B\"'"),
        "WIREGUARD_ENDPOINT_IP" => trim($_POST['WIREGUARD_ENDPOINT_IP'], " \t\n\r\0\x0B\"'"),
        "WIREGUARD_ENDPOINT_PORT" => trim($_POST['WIREGUARD_ENDPOINT_PORT'], " \t\n\r\0\x0B\"'"),
        "WIREGUARD_PUBLIC_KEY" => trim($_POST['WIREGUARD_PUBLIC_KEY'], " \t\n\r\0\x0B\"'"),
        "WIREGUARD_PRESHARED_KEY" => trim($_POST['WIREGUARD_PRESHARED_KEY'], " \t\n\r\0\x0B\"'"),
        "DEVICE_MODEL" => trim($_POST['DEVICE_MODEL'], " \t\n\r\0\x0B\"'"),
        "MACOS_VERSION" => trim($_POST['MACOS_VERSION'], " \t\n\r\0\x0B\"'"),
    ];

    // Write to the .env file in the correct format
    $envContent = "";
    foreach ($data as $key => $value) {
        $envContent .= "$key=\"$value\"\n"; // Format as key="value"
    }
    file_put_contents($envFilePath, $envContent);

    // Execute the appropriate bash script based on the button clicked
    switch ($action) {
        case 'setup':
            exec('bash ' . BASE_PATH . '/setup.sh'); // Run in detached mode
            break;
        case 'continue':
            exec('bash ' . BASE_PATH . '/continue.sh'); // Run in detached mode
            break;
        case 'reset':
            exec('bash ' . BASE_PATH . '/reset.sh'); // Run in detached mode
            break;
        case 'stop':
            exec("bash " . BASE_PATH . "/stop.sh"); // Execute stop.sh
            break;
        case 'save':
            // Just save the config, no action needed
            break;
    }

    // Redirect back to the form
    header('Location: index.php');
    exit();
}
?> 
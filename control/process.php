<?php
// Define the base path for the environment file
define('BASE_PATH', dirname(__DIR__));

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $envFilePath = BASE_PATH . '/.env';
    
    // Check the action
    $action = $_POST['action'];
    
    // Handle stopping the running script
    if ($action === 'stop') {
        if (file_exists(BASE_PATH . '/setup.pid')) {
            $pid = file_get_contents(BASE_PATH . '/setup.pid');
            posix_kill($pid, SIGINT); // Send SIGINT signal
            unlink(BASE_PATH . '/setup.pid'); // Remove PID file
            unlink(BASE_PATH . '/setup.log'); // Optionally remove log file
        } elseif (file_exists(BASE_PATH . '/continue.pid')) {
            $pid = file_get_contents(BASE_PATH . '/continue.pid');
            posix_kill($pid, SIGINT); // Send SIGINT signal
            unlink(BASE_PATH . '/continue.pid'); // Remove PID file
            unlink(BASE_PATH . '/continue.log'); // Optionally remove log file
        } elseif (file_exists(BASE_PATH . '/reset.pid')) {
            $pid = file_get_contents(BASE_PATH . '/reset.pid');
            posix_kill($pid, SIGINT); // Send SIGINT signal
            unlink(BASE_PATH . '/reset.pid'); // Remove PID file
            unlink(BASE_PATH . '/reset.log'); // Optionally remove log file
        }
        header('Location: index.php'); // Redirect back to the form
        exit();
    }
    
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
            exec('nohup bash ' . BASE_PATH . '/setup.sh > ' . BASE_PATH . '/setup.log 2>&1 & echo $!', $output);
            file_put_contents(BASE_PATH . '/setup.pid', trim($output[0])); // Save PID
            break;
        case 'continue':
            exec('nohup bash ' . BASE_PATH . '/continue.sh > ' . BASE_PATH . '/continue.log 2>&1 & echo $!', $output);
            file_put_contents(BASE_PATH . '/continue.pid', trim($output[0])); // Save PID
            break;
        case 'reset':
            exec('nohup bash ' . BASE_PATH . '/reset.sh > ' . BASE_PATH . '/reset.log 2>&1 & echo $!', $output);
            file_put_contents(BASE_PATH . '/reset.pid', trim($output[0])); // Save PID
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
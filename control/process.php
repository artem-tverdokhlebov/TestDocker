<?php
// Define the base path for the environment file
define('BASE_PATH', dirname(__DIR__));

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $envFilePath = BASE_PATH . '/.env';
    
    // Check the action
    $action = $_POST['action'];

    // Update the .env file with the submitted values only if the save action is triggered
    if ($action === 'save') {
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
    }

    // Execute the appropriate bash script based on the button clicked
    switch ($action) {
        case 'setup':
            exec('cd ' . BASE_PATH . ' && bash setup.sh 2>&1', $output, $return_var); // Capture output
            echo implode("\n", $output); // Display output
            break;
        case 'continue':
            exec('cd ' . BASE_PATH . ' && bash continue.sh 2>&1', $output, $return_var); // Capture output
            echo implode("\n", $output); // Display output
            break;
        case 'reset':
            exec('cd ' . BASE_PATH . ' && bash reset.sh 2>&1', $output, $return_var); // Capture output
            echo implode("\n", $output); // Display output
            break;
        case 'stop':
            exec("cd " . BASE_PATH . " && bash stop.sh 2>&1", $output, $return_var); // Capture output
            echo implode("\n", $output); // Display output
            break;
    }

    // Redirect back to the form
    header('Location: index.php');
    exit();
}
?> 
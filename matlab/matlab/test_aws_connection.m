% test_aws_connection.m
clear; clc;

%% Configuration
AWS_ENDPOINT = 'ssl://a8qm6pq22sdnt-ats.iot.us-east-1.amazonaws.com';
CERT_PATH = 'C:\Users\Magzh\Desktop\vehicle-control\aws-certs';

% Certificate files
certFile = fullfile(CERT_PATH, 'control-server-cert.pem');
keyFile = fullfile(CERT_PATH, 'control-server-private.key');
rootCA = fullfile(CERT_PATH, 'AmazonRootCA1.pem');

%% Create MQTT Client
fprintf('Connecting to AWS IoT Core...\n');
try
    client = mqttclient(AWS_ENDPOINT, ...
        'Port', 8883, ...
        'ClientID', 'matlab-test', ...
        'CARootCertificate', rootCA, ...
        'ClientCertificate', certFile, ...
        'ClientKey', keyFile);
    
    fprintf('✓ Connected successfully!\n');
    
    % Test publish
    fprintf('Publishing test message...\n');
    write(client, 'test/matlab', 'Hello from MATLAB!');
    fprintf('✓ Message published!\n');
    
    % Clean up
    clear client;
    fprintf('\n✓ Test complete! AWS IoT Core is ready.\n');
    
catch ME
    fprintf('✗ Connection failed:\n');
    fprintf('  %s\n', ME.message);
    fprintf('\nCheck:\n');
    fprintf('  1. Endpoint address correct?\n');
    fprintf('  2. Certificate files exist?\n');
    fprintf('  3. Certificate attached to policy?\n');
end
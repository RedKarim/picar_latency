% run_controller.m
clear; clc; close all;

%% Configuration
AWS_ENDPOINT = 'ssl://a8qm6pq22sdnt-ats.iot.us-east-1.amazonaws.com';
CERT_PATH = 'C:\Users\Magzh\Desktop\vehicle-control\aws-certs';  % Update this path

%% Add your algorithm functions to path
% Make sure all your functions are accessible
addpath('C:\Users\Magzh\Desktop\vehicle-control\matlab');  % Update this!

%% Check that your function exists
if ~exist('main_matlab.m', 'file')
    error('main_matlab.m not found! Please add it to MATLAB path');
end

if ~exist('Opt_method_second.m', 'file')
    error('Opt_method_second.m not found! Please add it to MATLAB path');
end

if ~exist('calculate_dt_evaluation_real.m', 'file')
    error('calculate_dt_evaluation_real.m not found! Please add it to MATLAB path');
end

if ~exist('calculate_interpolation_real.m', 'file')
    error('calculate_interpolation_real.m not found! Please add it to MATLAB path');
end

fprintf('✓ All required functions found\n\n');

%% Create controller
fprintf('=== Vehicle Intersection Controller ===\n');
fprintf('Real scale: 400m intersection, 0-50 km/h\n');
fprintf('Lab scale: 16.7m range, 0-2 m/s\n');
fprintf('Traffic: 15s green, 30s red\n\n');

try
    controller = AWSMQTTController(AWS_ENDPOINT, CERT_PATH);
    
    fprintf('System ready. Waiting for vehicles...\n');
    fprintf('Press Ctrl+C to stop\n\n');
    
    %% Main loop
    while true
        pause(1);  % Just keep running, callbacks handle everything
    end
    
catch ME
    fprintf('\nError: %s\n', ME.message);
    fprintf('Stack trace:\n');
    for k = 1:length(ME.stack)
        fprintf('  %s (line %d)\n', ME.stack(k).name, ME.stack(k).line);
    end
end

%% Cleanup
if exist('controller', 'var')
    controller.disconnect();
end
% test_main_matlab.m
clear; clc;

% Add your functions to path
addpath('path/to/your/functions');

% Test inputs (real scale)
Xh = 100;   % 100m before intersection
Vh = 13.89; % 50 km/h

fprintf('Testing main_matlab...\n');
fprintf('Input: Xh=%.1f m, Vh=%.2f m/s (%.1f km/h)\n\n', Xh, Vh, Vh*3.6);

tic;
[position, velocity_profile, acc] = Copy_of_main_matlab(Xh, Vh);
elapsed = toc;

fprintf('Output:\n');
fprintf('  Profile length: %d values\n', length(velocity_profile));
fprintf('  Time: %.3f seconds\n', elapsed);
fprintf('  First 10 values (m/s):\n    ');
fprintf('%.2f ', velocity_profile(1:min(10,length(velocity_profile))));
fprintf('\n');
fprintf('  Velocity range: %.2f -> %.2f m/s\n', ...
    min(velocity_profile), max(velocity_profile));

% Plot
figure;
subplot(3,1,1);
plot(position);
xlabel('Time step (0.1s)');
ylabel('Velocity (m/s)');
title('Velocity Profile (Real Scale)');
grid on;

subplot(3,1,2);
plot(velocity_profile * 3.6);
xlabel('Time step (0.1s)');
ylabel('Velocity (km/h)');
title('Velocity Profile (Real Scale)');
grid on;
subplot(3,1,3);
plot(acc);
xlabel('Time step (0.1s)');
ylabel('Velocity (km/h)');
title('Velocity Profile (Real Scale)');
grid on;
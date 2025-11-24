% AWSMQTTController.m
classdef AWSMQTTController < handle
    properties
        mqttClient
        broker
        clientID
        
        % Certificates
        certFile
        keyFile  
        rootCAFile
        
        % Scaling parameters
        SCALE_LENGTH = 400;        % 300m real -> 16.7m lab
        SCALE_VELOCITY = 50/3.6;   % 50 km/h -> 2 m/s (13.89 m/s -> 2 m/s)
        
        % Traffic light timing (matching your code)
        greenDuration = 15;       % seconds
        redDuration = 30;         % seconds
        
        % Current traffic state
        trafficLightState = 'green';
        timeToGreen = 15.0;       % Initial time to green
        
        % Intersection position (real scale)
        intersectionPosition = 400;  % meters (real scale)
        
        % Vehicle states
        vehicleStates
    end
    
    methods
        function obj = AWSMQTTController(awsEndpoint, certPath)
            obj.broker = awsEndpoint;
            obj.clientID = 'matlab_control_server';
            
            obj.certFile = fullfile(certPath, 'control-server-cert.pem');
            obj.keyFile = fullfile(certPath, 'control-server-private.key');
            obj.rootCAFile = fullfile(certPath, 'AmazonRootCA1.pem');
            
            obj.vehicleStates = containers.Map();
            
            obj.connectAWS();
            %obj.startTrafficLightSimulation();
        end
        
        function connectAWS(obj)
            obj.mqttClient = mqttclient(obj.broker, ...
                'Port', 8883, ...
                'ClientID', obj.clientID, ...
                'CARootCertificate', obj.rootCAFile, ...
                'ClientCertificate', obj.certFile, ...
                'ClientKey', obj.keyFile);
            
            fprintf('✓ Connected to AWS IoT Core: %s\n', obj.broker);
            
            % Subscribe to trigger messages
            subscribe(obj.mqttClient, 'vehicle/picar_vehicle_1/trigger', ...
                'Callback', @obj.onTriggerReceived);
            
            fprintf('✓ Subscribed to vehicle triggers\n\n');
        end
        %{
        function startTrafficLightSimulation(obj)
            % Simple traffic light cycle
            obj.trafficLightState = 'red';
            obj.timeToGreen = 10.0;
            
            t = timer('Period', 0.1, 'ExecutionMode', 'fixedRate', ...
                'TimerFcn', @(~,~) obj.updateTrafficLight());
            start(t);
            
            fprintf('🚦 Traffic light simulation started\n');
            fprintf('   Green duration: %d s\n', obj.greenDuration);
            fprintf('   Red duration: %d s\n', obj.redDuration);
            fprintf('   Initial state: RED (green in %.1f s)\n\n', obj.timeToGreen);
        end
        
        function updateTrafficLight(obj)
            if strcmp(obj.trafficLightState, 'red')
                obj.timeToGreen = obj.timeToGreen - 0.1;
                if obj.timeToGreen <= 0
                    obj.trafficLightState = 'green';
                    obj.timeToGreen = obj.greenDuration;
                    fprintf('🟢 Traffic light: GREEN (%d s)\n', obj.greenDuration);
                end
            else
                obj.timeToGreen = obj.timeToGreen - 0.1;
                if obj.timeToGreen <= 0
                    obj.trafficLightState = 'red';
                    obj.timeToGreen = obj.redDuration;
                    fprintf('🔴 Traffic light: RED (%d s)\n', obj.redDuration);
                end
            end
        end
        %}
        
        function onTriggerReceived(obj, topic, msg)
            % Called when vehicle reaches trigger point
            try
                data = jsondecode(char(msg));
                vehicleID = data.vehicle_id;
                
                fprintf('\n%s\n', repmat('=', 1, 70));
                fprintf('🚗 TRIGGER RECEIVED from %s\n', vehicleID);
                fprintf('%s\n', repmat('=', 1, 70));
                
                % Convert lab scale to real scale
                realState = obj.labToRealScale(data);
                
                fprintf('Vehicle State:\n');
                fprintf('  Lab scale:  x=%.2f m, v=%.3f m/s\n', ...
                    data.position.x, data.velocity);
                fprintf('  Real scale: x=%.1f m, v=%.2f m/s (%.1f km/h)\n', ...
                    realState.x, realState.v, realState.v * 3.6);
                fprintf('  Distance to intersection: %.1f m (real)\n', ...
                    realState.distance_to_intersection);
                
                fprintf('\nTraffic Light:\n');
                fprintf('  State: %s\n', upper(obj.trafficLightState));
                fprintf('  Time to green: %.1f s\n', obj.timeToGreen);
                
                % Run your optimization
                fprintf('\nRunning YOUR optimization (main_matlab)...\n');
                tic;
                [velocityProfile_real, metadata] = obj.runYourOptimization(realState);
                elapsed = toc;
                fprintf('  Optimization completed in %.3f seconds\n', elapsed);
                
                % Convert to lab scale
                velocityProfile_lab = velocityProfile_real / obj.SCALE_VELOCITY;
                
                fprintf('\nVelocity Profile (real scale):\n');
                fprintf('  Length: %d values\n', length(velocityProfile_real));
                fprintf('  Range: %.2f -> %.2f m/s (%.1f -> %.1f km/h)\n', ...
                    velocityProfile_real(1), velocityProfile_real(end), ...
                    velocityProfile_real(1)*3.6, velocityProfile_real(end)*3.6);
                
                fprintf('\nVelocity Profile (lab scale):\n');
                fprintf('  Range: %.3f -> %.3f m/s\n', ...
                    velocityProfile_lab(1), velocityProfile_lab(end));
                
                % Send to vehicle
                obj.sendVelocityProfile(vehicleID, velocityProfile_lab, metadata);
                
                fprintf('%s\n\n', repmat('=', 1, 70));
                
            catch ME
                fprintf('Error processing trigger: %s\n', ME.message);
                fprintf('Stack trace:\n');
                for k = 1:length(ME.stack)
                    fprintf('  File: %s, Line: %d, Function: %s\n', ...
                        ME.stack(k).file, ME.stack(k).line, ME.stack(k).name);
                end
            end
        end
        
        function realState = labToRealScale(obj, labData)
            % Convert PiCar measurements to real scale
            realState = struct();
            realState.vehicle_id = labData.vehicle_id;
            realState.timestamp = labData.timestamp;
            
            % Scale up: lab -> real
            realState.x = labData.position.x * 1;
            realState.v = labData.velocity * 1;
            
            % Distance to intersection (real scale)
            realState.distance_to_intersection = obj.intersectionPosition - realState.x;
        end
        
        function [velocityProfile, metadata] = runYourOptimization(obj, realState)
            % Run YOUR main_matlab function
            
            % Extract current state (real scale)
            %Xh = realState.x;  % Position (meters, real scale)
            %Vh = realState.v;  % Velocity (m/s, real scale)
            Xh = 100;
            Vh = 50/3.6;
            fprintf('  Input to main_matlab:\n');
            fprintf('    Xh = %.2f m\n', Xh);
            fprintf('    Vh = %.2f m/s (%.1f km/h)\n', Vh, Vh*3.6);
            fprintf('    Green time: %d s\n', obj.greenDuration);
            fprintf('    Red time: %d s\n', obj.redDuration);
            
            % Call YOUR function
            % [velocity] = main_matlab(Xh, Vh)
            % where velocity = vinit_type2 from your code
            [vinit_type2] = main_matlab(Xh, Vh);
            
            % vinit_type2 is your desired velocity profile (real scale)
            velocityProfile = vinit_type2;
            
            fprintf('  Output from main_matlab:\n');
            fprintf('    Profile length: %d values\n', length(velocityProfile));
            fprintf('    First 5 values: [%.2f, %.2f, %.2f, %.2f, %.2f] m/s\n', ...
                velocityProfile(1), velocityProfile(2), velocityProfile(3), ...
                velocityProfile(4), velocityProfile(5));
            
            % Metadata
            metadata = struct();
            metadata.method = 'MPC_optimization';
            metadata.green_duration = obj.greenDuration;
            metadata.red_duration = obj.redDuration;
            metadata.traffic_state = obj.trafficLightState;
            metadata.time_to_green = obj.timeToGreen;
            metadata.initial_position = Xh;
            metadata.initial_velocity = Vh;
        end
        
        function sendVelocityProfile(obj, vehicleID, labVelocityProfile, metadata)
            % Send velocity profile to PiCar (lab scale)
            
            command = struct();
            command.vehicle_id = vehicleID;
            command.timestamp = posixtime(datetime('now'));
            command.command_type = 'velocity_profile';
            
            % Traffic light info
            command.traffic_light = struct();
            command.traffic_light.state = obj.trafficLightState;
            command.traffic_light.time_to_green = obj.timeToGreen;
            command.traffic_light.green_duration = obj.greenDuration;
            command.traffic_light.red_duration = obj.redDuration;
            
            % Velocity profile (lab scale - desired velocities for IDM)
            command.velocity_profile = struct();
            command.velocity_profile.dt = 0.5;  % 10 Hz
            command.velocity_profile.values = labVelocityProfile;
            command.velocity_profile.start_time = command.timestamp;
            
            % Metadata
            command.metadata = metadata;
            
            % Publish to AWS IoT Core
            jsonMsg = jsonencode(command);
            topic = sprintf('vehicle/%s/command', vehicleID);
            write(obj.mqttClient, topic, jsonMsg);
            
            fprintf('\n✓ Sent velocity profile to %s\n', vehicleID);
            fprintf('  Topic: %s\n', topic);
            fprintf('  Profile: %d values over %.1f seconds\n', ...
                length(labVelocityProfile), length(labVelocityProfile)*0.5);
            fprintf('  Lab scale: [%.3f, %.3f, ..., %.3f] m/s\n', ...
                labVelocityProfile(1), labVelocityProfile(2), labVelocityProfile(end));
        end
        
        function disconnect(obj)
            if ~isempty(obj.mqttClient)
                clear obj.mqttClient;
                fprintf('Disconnected from AWS IoT Core\n');
            end
        end
    end
end
function [distance_q, velocity_q, acceleration_q] = calculate_interpolation_real(x, y)
    % Interpolate distance, velocity, and acceleration over total time steps defined in x
    % x - time durations per step (length T)
    % y - concatenated position, velocity, and acceleration values
    % Output:
    %   distance_q - interpolated distance values every 0.5 sec
    %   velocity_q - interpolated velocity values every 0.5 sec
    %   acceleration_q - interpolated acceleration values every 0.5 sec

    T = length(x);

    % Extract distances, velocities, and accelerations from y
    distance = y(1:T+1);                  % First T+1 values
    velocity = y(T+2:2*(T+1));            % Next T+1 values
    acceleration = y(2*(T+1)+1:end-2);    % Last T values

    % Total simulation time
    totalSteps = sum(x);

    % Build the time vectors
    t_distance = cumsum([0, x]);           % (T+1)
    t_velocity = cumsum([0, x]);           % (T+1)
    t_acceleration = cumsum([0, x(1:end-1)]); % (T)

    % Define query times every 0.5 seconds
    tq = 0:0.5:totalSteps;                 % <-- changed from 1:totalSteps

    % Linear interpolation
    distance_q = interp1(t_distance, distance, tq, 'linear', 'extrap');
    velocity_q = interp1(t_velocity, velocity, tq, 'linear', 'extrap');
    acceleration_q = interp1(t_acceleration, acceleration, tq, 'linear', 'extrap');

    % Extend the signals slightly (optional)
    add_distance = repmat(distance_q(end), 1, 10); % 10 * 0.5s = 5s extra
    add_velocity = repmat(velocity_q(end), 1, 10);
    add_acc = repmat(acceleration_q(end), 1, 10);

    distance_q = [distance_q, add_distance];
    velocity_q = [velocity_q, add_velocity];
    acceleration_q = [acceleration_q, add_acc];
end

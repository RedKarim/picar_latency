function dt = calculate_dt_evaluation_real(Tg, Tr)
    total_length = 20;

    % Fixed values
    
    fixed_green = [1, 1]; % Start of green
    fixed_green_end = [1]; % End of green
    fixed_red = [1, 1]; % Start of red
    fixed_red_end = [1,1]; % End of red

    fixed_len = length(fixed_green) + length(fixed_green_end) + ...
                length(fixed_red) + length(fixed_red_end); % = 6
    mid_len = total_length - fixed_len;

    Tg_mid = Tg - 3; % We already used [1,1,1]
    Tr_mid = Tr - 4; % We already used [1,1,1]

    % Calculate how many slots to give to green and red
    total_mid_time = Tg_mid + Tr_mid;
    green_slot_count = round((Tg_mid / total_mid_time) * mid_len);
    red_slot_count = mid_len - green_slot_count-2;

    % Distribute green and red middle times fairly
    green_middle = fair_distribution(Tg_mid, green_slot_count);
    red_middle = fair_distribution(Tr_mid, red_slot_count);

    % Assemble full sequence
    dt = [fixed_green, green_middle, fixed_green_end, ...
          fixed_red, red_middle, fixed_red_end];
    for i = total_length-1:total_length
        dt(i) = 1;
    end
    % Final validations
    %if length(dt) ~= 20
       % error("Length is not 20 — got: %d", length(dt));
    %end
    %if sum(dt) ~= Tg + Tr + 2
      %  error("Sum is not Tg + Tr + 2 — got: %d", sum(dt));
    %end
    % Original data

end

function out = fair_distribution(total, slots)
    % Distribute total over slots with no zeros
    out = ones(1, slots);  % ensure all values ≥ 1
    remaining = total - slots;  % subtract the initial 1s
    for i = 1:remaining
        out(mod(i - 1, slots) + 1) = out(mod(i - 1, slots) + 1) + 1;
    end
end



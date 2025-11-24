close all;
clear all;
clc;
Initializing;

init_plot; % initial plot

%type_solver = []; %This is variable which defines solver type 

Vehicle(N) = struct('x', 0, 'v', 0, 'a', 0, ...
                    'Aold', 0,'type_solver', 0, 'type_algo', 0);  % add more if needed
%% car data information and position and plot
%car_data = create_car_data(N); %% car data information
Vehicle = calculate_position(N); %% position and velocity for initial cars
x_positions = [Vehicle.x];
P = plot(x_positions,3,'sr');

Algo_chechk_cell = cell(180, 1);
Algo_chechk_cell2 = cell(180, 1);

%% initializing for plot
skip_cars = randi([2,3]);
x_plot = [];
v_plot = [];
a_plot = [];

gamma =  0.25;

%% prelim calculations
% calculate dt
%dT=calculate_dt(T, TrafficLightTimeGreen, TrafficLightTimeRed);

%dT=calculate_dt_final(T);
dT=calculate_dt_evaluation_real(TrafficLightTimeGreen, TrafficLightTimeRed);
[index_k, rem_k] = prelim_calculation(T, TrafficLightTimeGreen, TrafficLightTimeRed);
indK = index_k;

Jmax = 250;
xinit1 = [];
xinit2 = [];
vinit1 = [];
vinit2 = [];
ainit1 = [];
ainit2 = [];
xPred_solver1 = [];
k1 = 0;
k2 = 0;
xinit_type1 = [];
xinit_type2 = [];
car_data = create_car_data(Jmax, N); %% car data information
%tl_color_calc = zeros(1, Jmax);
tl_color_calc = traffic_light_calculation(Jmax, TrafficLightTimeGreen, TrafficLightTimeRed);
%tl_color_opt = traffic_light_calculation(sum(dT), TrafficLightTimeGreen, TrafficLightTimeRed);
count = 1;
totalCycleTime = TrafficLightTimeGreen + TrafficLightTimeRed;
remainingGreenTime = TrafficLightTimeGreen; % Initially, the full green time is remaining
remainingRedTime = TrafficLightTimeRed;     % Initially, the full red time is remaining
Vd1 = 0;
Vd2 = 0;
%% Model calculaation
for i=1:Jmax
    Algo_chechk_cell{i} = Vehicle.type_solver;
    currentTime = currentTime + 0.5;
    %% traffic light calculaation
    %traffic_light_calculation()
    if tl_color_calc(i) == color1(1) % Green light
        if currentTime >= TrafficLightTimeGreen
            tl_color_car = color(1); % Change to red
            currentTime = 0; % Reset current time
            indK = index_k; 
            
        else
            remainingGreenTime = TrafficLightTimeGreen - currentTime; % Calculate remaining green time
            % You can use remainingGreenTime as needed
        end
    elseif tl_color_calc(i) == color1(2) % Red light
        if currentTime >= TrafficLightTimeRed
            tl_color_car = color(2); % Change to green
            currentTime = 0; % Reset current time
            indK = index_k; 
            remainingRedTime = TrafficLightTimeRed;
        else
            remainingRedTime = TrafficLightTimeRed - currentTime; % Calculate remaining red time
            % You can use remainingRedTime as needed
        end
    end
    
    if tl_color_car == color(2) || tl_color_car == color(1) 
        rem_k = rem_k + dt;
        if rem_k == dT(indK)
            indK = indK - 1;
             rem_k = 0;
        end
    end

    
    %% MPC
    for n=1:N

        

        if Vehicle(n).x > Xj-5 && Vehicle(n).type_solver ~= 4
           Vehicle(n).type_solver = 3;
        end
    

        %% apply MPC
        if Vehicle(n).x > 100 && Vehicle(n).x < 580 && Vehicle(n).type_algo ~= 2 % apply MPC
            Vehicle(n).type_algo = 1;
        end

        %% reset after signal change
        if  mod(i, (TrafficLightTimeRed + TrafficLightTimeGreen)*2) == 1 && tl_color_calc(i) == 1 && Vehicle(n).type_solver ~= 0 && Vehicle(n).type_solver ~= 4 % reset after signal change
            if Vehicle(n).type_solver == 2
                Vehicle(n).type_solver = 0;
            else
                Vehicle(n).type_solver = 3;
            end

            firstSolver = 0;
            secondSolver = 0;
            k1 = 0;
            k2 = 0;
            

        end
        Algo_chechk_cell{i} = Vehicle.type_solver;
        %% implement algo
        if n == 1 && Vehicle(n).type_algo == 1 % first car IDM
             Vehicle(n).a = IDM(Vehicle(n).x, Vehicle(n).v, Vehicle(n).x+100, 14, Vd1, Vd2);

        elseif n > 1 && Vehicle(n).type_algo == 1 %IDM
            if length(xinit_type1) > 0 && Vehicle(n).type_solver == 1
                xinit1 = xinit_type1(k1:(k1+10));
                vinit1 = vinit_type1(k1:(k1+10));
                ainit1 = ainit_type1(k1:(k1+10));
                count = length(xinit_type1) - k1;
                ainit1(end+1) = count;
                k1 = k1+1;
                
                if mod(i,(TrafficLightTimeRed+TrafficLightTimeGreen)*2)>=(TrafficLightTimeRed+TrafficLightTimeGreen)*2-2
                    Vehicle(n).type_solver = 3;
                end
                if Vehicle(n).type_solver == 1
                    Vd1= vinit1(2);
                end
            else
                Vd1 = 0;
            end
            if length(xinit_type2) > 0  && Vehicle(n).type_solver == 2
                xinit2 = xinit_type2(k2:(k2+10));
                vinit2 = vinit_type2(k2:(k2+10));
                ainit2 = ainit_type2(k2:(k2+10));
                count2 = length(xinit_type2) - k2;
                ainit2(end+1) = ainit_type2(end);
                ainit2(end+1) = count2;
                
                k2 = k2+1;
                if mod(i,TrafficLightTimeRed+TrafficLightTimeGreen)>=(TrafficLightTimeRed+TrafficLightTimeGreen)*2-2
                    Vehicle(n).type_solver = 3;
                end
                if Vehicle(n).type_solver == 2
                    Vd2= vinit2(2);
                end
            else
                Vd2 = 0;
            end
            if Vd1~=0
                car_data(i).Vd1 = Vd1;
            end
            
                Vehicle(n).a = IDM(Vehicle(n).x, Vehicle(n).v, Vehicle(n-1).x, Vehicle(n-1).v, Vd1, Vd2);
            %end
        end

        %% Algo type for green
        if Vehicle(n).x > 100 && Vehicle(n).x < 350 && Vehicle(n).type_solver == 0  %Algo type for green
            if firstSolver == 0 && (n ==2 || (mod(n-1,13) == 0)) % && i < 180) || (mod(n,13) == 0 && i > 180))
                dT1 = calculate_dt_evaluation_real(ceil(remainingGreenTime), ceil(remainingRedTime));
                if i < 120
                    skip_cars = randi([2,2]);
                    chk = 0;
                elseif i >120 && i <270
                    skip_cars = randi([2,2]);  
                    chk = 1.5;
                elseif i >270 && i <420
                    skip_cars = randi([2,2]);  
                    chk = 2;
                else
                    skip_cars = randi([2,2]);  
                    chk = 2.5;
                end
                [Vehicle(n).a, x_pred1, solver] = Opt_method_first(Vehicle(n).x, Vehicle(n).v, 400, 0, dT1, chk);
                %[Vehicle(n).a, x_pred1, solver] = Opt_method_second(Vehicle(n).x, Vehicle(n).v, 400, 0, dT1);
                %Opt_method_first(Xh, Vh, Xp, Vp, index, index_k, a_previous, dT, tl_color_opt);
                Vehicle(n).type_solver = solver;
                [xinit_type1, vinit_type1, ainit_type1] = calculate_interpolation_real(dT1, x_pred1);
                firstSolver = 1;
                car_data(i).Vd1 = vinit_type1(2);
                
                k1 = 1;
                xPred_solver1 =x_pred1;
            end
            
            
            if firstSolver ~= 0 && secondSolver == 0
                firstSolverIndices = find([Vehicle.type_solver] == 1);
                
                validVehicles = [Vehicle.x] < Xj & [Vehicle.type_solver] == 0;
                vehicle_indices = find(validVehicles(firstSolverIndices:n));

                if length(vehicle_indices) >= (skip_cars) && remainingGreenTime ~= 4 && remainingRedTime >=17
                    dT2 = calculate_dt_evaluation_real(ceil(remainingGreenTime), ceil(remainingRedTime));
                    [Vehicle(n).a, x_pred2, solver] = Opt_method_second(Vehicle(n).x, Vehicle(n).v, 400-10*(skip_cars-2), 0, dT2);
                    [xinit_type2, vinit_type2, ainit_type2] = calculate_interpolation_real(dT2, x_pred2);
                    Vehicle(n).type_solver = solver;
                    secondSolver = 1;
                    k2 = 1;
                    vehicle_indices = 0;
                    if remainingGreenTime ==1 || remainingGreenTime ==0
                        ainit_type2(end) = 1;
                    else
                        ainit_type2(end) = 0;
                    end
                end
            end
            %Vehicle(n).type_solver = solver_decision(x_pred1, indK);
                      
        end


        
        end
        
    
    
   
    %% IDM stop
    for n = 2:N
         
            if (tl_color_calc(i) == 0 && mod(i,(TrafficLightTimeRed+TrafficLightTimeGreen)*2)<(TrafficLightTimeRed+TrafficLightTimeGreen)*2-2 && Vehicle(n).type_algo == 1 && Vehicle(n).x < 400 &&  Vehicle(n).type_solver == 0)
                if Vehicle(n-1).x > 400
                    Vehicle(n).a = min(Vehicle(n).a,IDM(Vehicle(n).x, Vehicle(n).v, 400, 0, Vd1, Vd2));
                elseif Vehicle(n-1).x <= 400
                    Vehicle(n).a = min(Vehicle(n).a,IDM(Vehicle(n).x, Vehicle(n).v, Vehicle(n-1).x, Vehicle(n).v, Vd1, Vd2));
                end
            end
        if Vehicle(n).type_solver == 1 
                Vehicle(n).a = IDM(Vehicle(n).x, Vehicle(n).v, 400, 0, Vd1, Vd2);
            %Vehicle(n).a = min(Vehicle(n).a,IDM(Vehicle(n).x, Vehicle(n).v, 400, 0, Vd1, Vd2));
            end
    end

   
    %% applying a(n)
    for n = 1:N
        Vehicle(n).a = gamma*(Vehicle(n).Aold)+(1-gamma)*( Vehicle(n).a); 
        Vehicle(n).Aold =  Vehicle(n).a;
        if Vehicle(n).a < -6
            Vehicle(n).a = -6;
        end
        if Vehicle(n).a >= 2.5
            Vehicle(n).a = 2.5;
        end
        
        Vehicle(n).x = Vehicle(n).x+Vehicle(n).v*dt+1/2*Vehicle(n).a*dt^2;
        Vehicle(n).v = Vehicle(n).v+Vehicle(n).a*dt;
        if Vehicle(n).v < 0
            Vehicle(n).v = 0;
        end
        %if i > 1
           % if car_data(i-1).distance(n) > Vehicle(n).x && algo_type == 2
               % Vehicle(n).x = car_data(i-1).distance(n);
            %end
        %end
        %if v()
    end
    
    %% Decision making 
    %{
    for n = 2:length(v)
        if algo_type ~= 1 && x(n) > 100 && x(n) < 400 && type_solver(n) == 3
           [a(n), x_pred1, x_val, fn1] = Opt_method_one(x(n), v(n), x(n-1), v(n-1), i, indK, stop_pos_2(n), a_previous, dT, tl_color_opt);
           type_solver(n) = solver_decision(x_pred1, indK, type_solver(n));
        end
    end
    %}
    
    
    
    %% plots
    
    
    x_plot(i) = Vehicle(2).x;
    v_plot(i) = Vehicle(2).v;
    a_plot(i) = Vehicle(2).a;
    solver_plot(i) = Vehicle(2).type_solver;
    car_data(i).acceleration = [Vehicle.a];
    car_data(i).velocity = [Vehicle.v];
    car_data(i).distance = [Vehicle.x];
    car_data(i).solver = [Vehicle.type_solver];
    
    if tl_color_calc(i) == 1
        color2 = [0, 1, 0];  % Green
    elseif tl_color_calc(i) == 0
        color2 = [1, 0, 0];  % Red
    else
        error('Invalid traffic light state');
    end


    figure(1)
    plot([Xj+20,Xj+20],[12,-6],'LineWidth',9,'Color',color2); %Plots traffic light for car
    hold on;

    x_positions = [Vehicle.x];
    delete(P); %Delete the previous Car
    P = plot(x_positions,3,'sr','MarkerFaceColor',[1 0 0]); % Plot Cars
    pause(0.1); %Delay time for ploting

    axis([0,500,-100,100]); %Sets limit for the plot

    i
    k1
end
%dT(end+1) = 0.5;
%x_pred1(end-1);
%x_val
J = 1:Jmax;
Tmax = 1:T;
Tmax1 = 1:T+1;
%X = x_pred1(1:T+1);
%V = x_pred1(T+2:2*(T+1));
%A = x_pred1(2*T+3:end-2);
%dT(end+1) = 1;
sum_dT= cumsum(dT);
figure(2)

    %plot(sum_dT, X(2:T+1),'.-','LineWidth',1.5,'Color','b' , 'DisplayName','car1');grid on;hold on;
    %plot(T,Y(:,1),'-r','LineWidth',1.5);grid on;hold on;
    plot(J, x_plot,'.-','LineWidth',1.5,'Color','b' , 'DisplayName','car1');grid on;hold on;
    %plot(J, x_plot2,'.-','LineWidth',1.5,'Color','r', 'DisplayName','car2');grid on;hold on;
    %plot(J, x_plot3,'.-','LineWidth',1.5,'Color','g', 'DisplayName','car3');grid on;hold on;
    %plot(J, x_plot4,'.-','LineWidth',1.5,'Color','black', 'DisplayName','car4)');grid on;hold on;
    axis([0, Jmax, 100, 500]); %Sets limit for the plot
    %axis([0, sum_dT(end), 200, 500]); %Sets limit for the plot
    %axis([0, sum_dT(end), 200, 500]); %Sets limit for the plot
    xlabel('Time (t)') 
    ylabel('Distance (m)') 
    title('Trajectory of cars')
    hold off

    legend
       
figure(3)
    %plot(sum_dT, V(2:T+1),'.-','LineWidth',1.5,'Color','b' , 'DisplayName','car1');grid on;hold on;
    %plot(T,Y(:,1),'-r','LineWidth',1.5);grid on;hold on;
    plot(J, v_plot,'.-','LineWidth',1.5,'Color','b', 'DisplayName','car1');grid on;hold on;
    %plot(J, v_plot2,'.-','LineWidth',1.5,'Color','r', 'DisplayName','car2');grid on;hold on;
    %plot(J, v_plot3,'.-','LineWidth',1.5,'Color','g', 'DisplayName','car3');grid on;hold on;
    %plot(J, v_plot4,'.-','LineWidth',1.5,'Color','black', 'DisplayName','car4');grid on;hold on;
    axis([0, Jmax, -2, 15]); %Sets limit for the plot
    %axis([0, sum_dT(end), -2, 15]); %Sets limit for the plot
    xlabel('Time (t)') 
    ylabel('Velocity (m/s)') 
    title('Velocity of cars')
    hold off

    legend
    %tl_color_car
figure(4)
    %plot(sum_dT, A,'.-','LineWidth',1.5,'Color','b' , 'DisplayName','car1');grid on;hold on;
    %plot(T,Y(:,1),'-r','LineWidth',1.5);grid on;hold on;
    plot(J, a_plot,'.-','LineWidth',1.5,'Color','b', 'DisplayName','car1');grid on;hold on;
    %plot(J, a_plot2,'.-','LineWidth',1.5,'Color','r', 'DisplayName','car2');grid on;hold on;
    %plot(J, a_plot3,'.-','LineWidth',1.5,'Color','g', 'DisplayName','car3');grid on;hold on;
    %plot(J, a_plot4,'.-','LineWidth',1.5,'Color','black', 'DisplayName','car4');grid on;hold on;
    axis([0, Jmax, -3, 3]); %Sets limit for the plot
    %axis([0, sum_dT(end), -3, 3]); %Sets limit for the plot
    xlabel('Time (t)') 
    ylabel('Acceleration (m/s^2)')
    title('Acceleration of cars')
    hold off

    legend
    %tl_color_car


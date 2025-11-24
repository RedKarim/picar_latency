function [x_star_first] = Opt_method_second(Xh, Vh, Xp, Vp, dT);
T = 20;

Umn= -1.5;Umx=3; 
%Umn
%T=10; %horizon
dt=dT;
cx=3*(T+1)-1; %% X,V and A total dimension
%ub=[]; lb=[];
lb=nan(cx,1);
ub=lb;
lb(1:T+1)=-Inf;  %% Position limits
ub(1:T+1)=Inf;
lb(T+2:2*T+2)=0; %% minimum speed
ub(T+2:2*T+2)=14; %% maximu speed
lb(2*T+3:end)=Umn; %% minimum acceleration
ub(2*T+3:end)=Umx; %% maximu acceleration

%lb(end)=0; %% minimum optimal distance
%ub(end)=20; %% maximu optimal distance
%% Equilatiy 
Ax=1.0; Bx=diag(dt); dt2=0.5*dt.^2;
Aeq= zeros(cx+2,cx+2);
diag_dt2 =diag(dt2);
T1=-eye(T+1); T1(2:end,1:T)=eye(T)*Ax+T1(2:end,1:T);
Aeq(1:T+1,1:T+1)=T1;Aeq(T+2:2*T+2,T+2:2*T+2)=T1;
Aeq(2:T+1,T+2:2*T+1)=Bx; 
Aeq(2:T+1,2*T+3:3*T+2)=diag_dt2;
Aeq(T+3:2*T+2,2*T+3:3*T+2)=Bx; 
xi=zeros(cx+2,1); x=xi;

Beq=zeros(cx+2,1); 

xi(1)=Xh;  xi(T+2)=Vh; 
Beq(1)=-Xh; Beq(T+2)=-Vh;
%XPT=[[Xp+((1:T)*Vp*dt(1:T))]];

XPT = zeros(1,T);

%% init after red siganl
Xp_init = Xp;
Vp_init = Vp;

chk = 0; 
k = 0;
%% XPT
for i = 1:T

   XPT(i) = Xp+Vp*sum(dt(1:i));
  
end
a0 = 0.1;

xi(2*(T+1)+1)=a0;
dTT=cumsum(dt);
%Aeq(end, :) = Aeq_last;
for J=1:T
    a0= xi(2*(T+1)+J);
    xi(J+1)= xi(J)+ xi(T+1+J)*dt(J)+0.5*a0*dt(J)^2;
    
    xi(T+1+J+1)=xi(T+1+J)+a0*dt(J);
    if xi(T+1+J+1) > 14
        xi(T+1+J+1) = 14;
    end
    if xi(T+1+J+1) < 0
        xi(T+1+J+1) = 0;
    end
    if xi(J+1) > XPT(J)
        xi(J+1) = XPT(J)-4;
        xi(T+1+J+1) = 0;
        xi(2*(T+1)+J)= 0;
        
        %Aeq(end, T+3+J+1:2*T-2) = 1;
        
    else
        xi(2*(T+1)+J+1)= a0;
    end 
    
    

end



%xi(2*(T+1)+1:end-1)=a0;


b=zeros(T+2,1);
%x(end,1) = 9;
b(1:T,1)=XPT-7; %% Gap with PV
b(1:3,1)=b(1:3,1)+4;  %% Gap with PV
%b(T+1) = Xj-9;
b(end, 1) = 430;
%b(end-1, 1) = 4;

A=zeros(T+2,cx+2); 
A(1:T,2:T+1)=eye(T);
A(1:T,T+3:2*T+2)=1*eye(T);
k = T -2;
A(end, k) = 1;
%A(end-1, T+1+k+1) = 1;
%b(end-2, 1) = 800;
%b(end-3, 1) = 800;
%x(end,1) = 9;
%Beq(end,1) = 400;
%Aeq(end, k+1) = 1;
%A(end-1, T+1+k+1) = 1;



%% Otpmize

options = optimoptions('fmincon', ...
    'Algorithm','sqp', ...
    'SpecifyObjectiveGradient', false, ...  % corresponds to GradObj
    'MaxFunctionEvaluations', 5000, ...
    'ConstraintTolerance',1e-4, ...   % Looser tolerance
    'OptimalityTolerance',1e-6, ...
    'Display','iter');
[x,fav,exitflag,output]=fmincon(@(x) ObjFn_before(x, dt, k),xi,A,b,Aeq,Beq,lb,ub, [], options);%,@NonLinCons,options
%acc = x(2*T+3);
%acc = x(2*T+3);
x_star_first = x;
%solver = 2;


%solver = type_solver;
end
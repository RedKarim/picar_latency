function [ Fn] = ObjFn_before(x, deltaT, k )
%OBJFN Summary of this function goes here
%   Detailed explanation goes here
%global T;
T =20;
%TrafficLightTimeGreen = 20;
%% Horizon
%gradF=0;
ind = k-2;
deltaT1 = deltaT(1:end-1);
deltaT2 = deltaT(end);



Verr=14.0-x(T+2:2*(T)+1); 
U=x(2*(T+1)+1:end-2);

Verr = diag(Verr.^2*deltaT);
U = diag(U.^2*deltaT);

Verr_sum = 0.4*sum(Verr);
U_sum = 15*sum(U);



Fn = Verr_sum + U_sum;
%{
% Compute gradient
gradF = zeros(size(x));

% Compute partial derivatives
for i = T+2:2*(T)
    gradF(i) = -2*0.8*Verr(i-T-1)*deltaT1(i-T-1);
end

for i = 2*(T+1)+1:numel(x)-1
    idx = i - 2*(T+1) - 1;  % Calculate the index
    if idx > 0  % Check if the index is positive
        gradF(i) = 2*25*U(idx)*deltaT1(idx);
    end
end

gradF(2*(T+1)) = -2*40*Verr2*deltaT2;
gradF(end) = 2*25*U2*deltaT2;
%}
end
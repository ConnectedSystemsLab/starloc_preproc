%% data generate
A = [1,2];
r = [-1,-3];
tdata = 3*rand(200,1);
tdata = sort(tdata); % Increasing times for easier plotting
noisedata = 0.05*randn(size(tdata)); % Artificial noise
ydata = A(1)*exp(r(1)*tdata) + A(2)*exp(r(2)*tdata) + noisedata;
% plot(tdata,ydata,'r*')
xlabel 't'
ylabel 'Response'

%% solve
A = optimvar('A',2);
r = optimvar('r',2);
fun = A(1)*exp(r(1)*tdata) + A(2)*exp(r(2)*tdata);
obj = sum((fun - ydata).^2);
lsqproblem = optimproblem("Objective",obj);
x0.A = [-50,3/2];
x0.r = [-1/2,-3/2];
[sol,fval] = solve(lsqproblem,x0);

figure
responsedata = evaluate(fun,sol);
plot(tdata,ydata,'r*',tdata,responsedata,'b-')
legend('Original Data','Fitted Curve')
xlabel 't'
ylabel 'Response'
title("Fitted Response")
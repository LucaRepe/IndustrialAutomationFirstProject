clear;
clc;

%% Parameters

% Defining the jobs
J = [1 2 3 4 5 6 7 8 9 10];

% Defining the processing times
P = [5 3 6 8 4 12 12 5 3 2];

% Defining the due dates
D = [12 60 16 15 9 15 32 20 18 18]; % 4 6 3 9 8 10 7 

% Defining the weights
W = [1 1 1 1.5 1 1 2 1 1.2 3];

% Big-M coefficient
M = 1000;

%% Variables

prob = optimproblem;

nJobs = length(J);
nMachines = 1;

S = optimvar('S', nJobs, nMachines, 'lowerbound',0);
C = optimvar('C', nJobs, nMachines, 'lowerbound',0);
T = optimvar('T', nJobs, nMachines, 'lowerbound',0);
X = optimvar('X', nJobs, nJobs, 'Type', 'integer', 'lowerbound',0, 'upperbound', 1);

%% Objective function

prob.Objective = W * T;

%% Constraints

% Completion time definition

count = 1;
completionTime = optimconstr(nJobs);

for i=1:nJobs
    completionTime(count) = C(i) == S(i) + P(i);
    count = count + 1;
end

prob.Constraints.completionTime = completionTime;


% Big-M one job at a time

count = 1;
bigM = optimconstr (nJobs*nJobs);

for i=1:nJobs
    for j=1:nJobs
        if i~=j
            bigM(count) = S(j) >= C(i) - M*(1-X(i,j));
            bigM(count+1) = S(i) >= C(j) - M*(X(i,j));
            count = count+2;
        end
    end
end

prob.Constraints.bigM = bigM;

% J1 before J3

job13constr = optimconstr(nMachines);
job13constr = S(3) >= C(1);

prob.Constraints.job13constr = job13constr;

% J9 before J10

job910constr = optimconstr(nMachines);
job910constr = S(10) >= C(9);

prob.Constraints.job910constr = job910constr;


%% Tardiness

count = 1;
tardiness = optimconstr(nJobs);

for j=1:nJobs
    tardiness(count) = T(j) == C(j) - D(j);
    count = count+1;
end

prob.Constraints.tardiness = tardiness;

%% Solution

show(prob);
[sol, cost, output] = solve(prob);
disp(sol);
disp("The cost is " + cost);
disp(output);

%% Gantt chart

[out, idx] = sort(sol.C, 'ascend');
ganttMatrix = zeros(nJobs,1);
for i = 1:nJobs
    ganttMatrix(i) = P(idx(i));
end
H = barh(1,ganttMatrix,'stacked');
% Display every second in the X axis
xticks(0:1:sum(P));
% Display red lines corresponding to the due dates
for i=1:length(D)
    if idx(i) == 4 || idx(i) == 6
        xl = xline(D(idx(i)),'--r',"D4 & D6" + string());
        xl.LabelHorizontalAlignment = 'left';
        continue;
    end
    if idx(i) == 9 || idx(i) == 10
        xl = xline(D(idx(i)),'--r',"D9 & D10" + string());
        xl.LabelHorizontalAlignment = 'left';
        continue;
    end
        xl = xline(D(idx(i)),'--r',"D" + string(idx(i)));
        xl.LabelHorizontalAlignment = 'left';
end
% Vertical lines
grid on;
if nJobs > 6
    H(8).FaceColor = 'g';
    H(9).FaceColor = 'y';
    H(10).FaceColor = 'b';
end
title('Gantt chart');
xlabel('Processing time');
ylabel('Job schedule');
% Printing of the labels in the charts
labelx = H(1).YEndPoints - 3.5;
labely = H(1).XEndPoints;
text(labelx, labely, "J" + string(idx(1)),'VerticalAlignment', 'middle');
for i = 1:nJobs
    labelx = H(i).YEndPoints + 0.5;
    labely = H(i).XEndPoints;
    if i ~= nJobs
        text(labelx, labely, "J" + string(idx(i+1)),'VerticalAlignment', 'middle');
    end
end

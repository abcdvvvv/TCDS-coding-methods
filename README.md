# Coding methods for HITCDS
This repository contains algorithms for generating separation matrices and column combination matrices of thermally coupled distillation systems (TCDS).
```MATLAB
% Calculate all feasible configurations (basic configurations)
N = 4;
BC = 18;
addpath("function\")
[feasibleMatrix,m] = structureNoCalc(N);
fprintf("%d feasible configurations found.",m-1)

%% Select a basic configuration
A = feasibleMatrix(:,:,BC);
disp(A)
%{
A18 = [1 1 1 1
       0 1 1 1
       0 0 1 1
       0 0 0 1];
%}

%% Convert A to colcombine (C)
colcombine = A2colcombine(A);
%{
C = {[4 5 6]}
    {[2 3]}
    {[1]}
%}

%% Compute intermediate variables
[feedstream,feedstreamSEN,seccombine,product] = simple_deploy0(N,A,colcombine,[],[],[]);
%{
feedstream =   [1	2	3	0
                2	4	5	5
                3	5	6	6
                4	7	8	3
                5	8	9	201
                7	9	10	4]

feedstreamSEN =[2	0	0	3
                3	1	1	0
                0	2	2	0]

seccombine =   {[7,8,9,10,11,12]	
                [3,4,5,6]	
                [1,2]}

product = [8 9 11 13];
%}
```
The latter section plots thermodynamically equivalent configurations.

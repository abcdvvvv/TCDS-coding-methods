function [validmatrix,m] = structureNoCalc(d)
%{
This script outputs the separation matrix for all basic 
configurations, stored in a variable called validmatrix.
%}
tic
m = 1;
A = zeros(d);
A(1,1) = 1;
A(:,d) = 1;
ii = 0;

while A(1,1) ~= 2
    ii = ii + 1;
    A(d-1,d-1) = A(d-1,d-1) + 1;
    for j = d - 1:-1:2
        for i = j:-1:1
            if A(i,j) == 2
                A(i,j) = 0;
                if i ~= 1
                    A(i-1,j) = A(i-1,j) + 1;
                else
                    A(j-1,j-1) = A(j-1,j-1) + 1;
                end
            end
        end
    end
    if sum(A,'all') < 2*d - 1
        continue
    end
    pass = checkIfFeasible(d,A);
    if pass == 1
        validmatrix(:,:,m) = A; %#ok<*AGROW>
        m = m + 1;
    end
    if mod(ii,1e6) == 0
        disp(ii/1e6)
    end
end

fprintf("Time elapsed %.4fs\n",toc)
end

function pass = checkIfFeasible(n,A)
pass = 1;
for j = 2:n
    if any(A(:,j))
        if j >= 3 && j <= n % check 1
            B1 = A(1:j,1:j);
        end
        if j >= 2 && j <= n - 2 % check 2
            B2 = A(:,j+1:end);
            a = (n - j):-1:1;
        end
        for i = 1:j
            if A(i,j) == 1
                if (j >= 2 && j <= n - 2) && (max(B2(i,:).*a) + max(diag(B2,-i).*a') < n - j + 1)
                    pass = 0;
                    return % check 2
                end
                if (i >= 2 && i <= j - 1) && (j >= 3 && j <= n)
                    if (sum(diag(B1,j-i)) + sum(B1(i,:)) - 2 <= 0)
                        pass = 0;
                        return % check 1
                    end
                end
            end
        end
    end
end
end
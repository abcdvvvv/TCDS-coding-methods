%{
This script outputs the separation matrix for all basic 
configurations, stored in a variable called validmatrix.
%}
clear validmatrix
tic
d = 6;
colNumber = d*(d-1)/2;
m = 1;

[J,I] = meshgrid(1:d-1);
idx0 = J.*(J-1)/2+I;
for j = 1:d-1
    for i = j+1:d
        idx0(i,j) = 1;
    end
end

% Enumerate a matrix A using binary encoding
for a = 0:2^(colNumber-1)-1
    p = dec2bin(a,colNumber-1);
    pp = double(p)-'0';
    pp = [0,pp];
    A = pp(idx0);
    A(1,1) = 1;
    A(:,d) = 1;
    pass = StructureNoCalc2(d,A);
    if pass == 1
        validmatrix(:,:,m) = A; %#ok<*SAGROW>
        % disp(A)
        m = m+1;
    end
end
toc

function pass = StructureNoCalc2(n,Aspecified)
A = Aspecified;
pass = 1;
for j = 3:n % check 1
    B = A(1:j,1:j);
    for i = 2:j-1
        if (B(i,j) == 1) && (sum(diag(B,j-i))+sum(B(i,:))-2*B(i,j) <= 0)
            pass = 0;
            break
        end
    end
    if pass == 0
        break
    end
end
if pass == 1
    for j = 2:n-2 % check 2
        B = A(:,j+1:end);
        a = (n-j):-1:1;
        for i = 1:j
            if (A(i,j) == 1) && (max(B(i,:).*a)+max(diag(B,-i).*a') < n-j+1)
                pass = 0;
                break
            end
        end
        if pass == 0
            break
        end
    end
end
end
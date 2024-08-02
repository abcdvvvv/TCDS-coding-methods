function C = A2colcombine(A)
n = size(A,1);
[j, i] = meshgrid(1:n);
B = j.*(j - 1)/2 + i;
B = triu(B).*A;
semi_C = [];

for j = n:-1:3
    for i = 2:j - 1
        temp = [];
        if B(i,j) > 0
            for k = 1:i - 1
                if B(i-k,j-k) > 0
                    temp(1) = B(i-k,j-k);
                    break
                end
            end
            if ~isempty(temp)
                for k = 1:j - i
                    if B(i,j-k) > 0
                        temp(2) = B(i,j-k);
                        semi_C(end+1,:) = temp;
                        break
                    end
                end
            end
        end
    end
end
disp(semi_C) % semi-column combination matrix

indp = find_missing_elements(B(:,1:n-1), semi_C);

C = {};
i = 1;
while ~isempty(semi_C)
    C{i} = [];
    left = 1;
    right = 1;
    while ~isempty(left)
        C{i} = [semi_C(left,1),C{i}];
        next = semi_C(left,1);
        if left ~= 1
            semi_C(left,:) = [];
        end
        left = find(semi_C(:,2) == next);
    end
    while ~isempty(right)
        C{i} = [C{i},semi_C(right,2)];
        next = semi_C(right,2);
        semi_C(right,:) = [];
        right = find(semi_C(:,1) == next);
    end
    i = i + 1;
end

for i = 1:length(indp)
    C = [C,{indp(i)}];
end

[~, sorted_indices] = sort(cellfun(@(x) x(1), C));
C = C(sorted_indices);
disp(C) % column combination matrix
end

function indp = find_missing_elements(A, B)
    A_flat = A(:);
    B_flat = B(:);
    A_flat = A_flat(A_flat ~= 0);
    [~, not_in_B] = ismember(A_flat, B_flat);
    indp = A_flat(not(not_in_B));
end
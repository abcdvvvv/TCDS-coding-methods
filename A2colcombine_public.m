Aspecified=validmatrix(:,:,18);
[j, i] = meshgrid(1:4);
B = j .* (j-1)/2 + i;
B = triu(B).*Aspecified;
N=4;
tempcombine=[];
for j=N:-1:3
    for i=2:j-1
        temp=[];
        if B(i,j)>0
            for k=1:i-1
                if B(i-k,j-k)>0
                    temp(1)=B(i-k,j-k);
                    break
                end
            end
            if ~isempty(temp)
                for k=1:j-i
                    if B(i,j-k)>0
                        temp(2)=B(i,j-k);
                        tempcombine(end+1,:)=temp;
                        break
                    end
                end
            end
        end
    end
end
tempcombine % semi-column comobination matrix

s=tempcombine;
a={};
i=1;
while ~isempty(s)
    a{i}=[];
    left=1;
    right=1;
    while ~isempty(left)
        a{i}=[s(left,1),a{i}];
        next=s(left,1);
        if left~=1
            s(left,:)=[];
        end
        left=find(s(:,2)==next);
    end
    while ~isempty(right)
        a{i}=[a{i},s(right,2)];
        next=s(right,2);
        s(right,:)=[];
        right=find(s(:,1)==next);
    end
    i=i+1;
end
a % column combination matrix
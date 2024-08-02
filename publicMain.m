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

%% Find all thermodynamically equivalent configurations and more operable configurations
[allps,seccombine_all,~,~,~] = enumerate_all(N,colcombine,feedstream,feedstreamSEN);
[possible_structure,seccombine2,p_out,total_cond,slide_rail] = enumerate(N,colcombine,feedstream,feedstreamSEN);
fprintf('More operable configuration = %d\n',size(possible_structure,1))
fprintf('Note that the same structure with different pressure distribution also counts.\n')

%% Remove configurations with the same structure but different pressure distribution
idx = [1:6, 10:15];
ps = possible_structure;
seccombine3 = {};
total_cond3 = [];
a = [];
b = {};
while ~isempty(ps)
    row = ps(1,:);
    row2 = seccombine2(1,:);
    row3 = total_cond(1,:);
    same_rows = ismember(ps(:,idx),row(idx),'rows');
    % Remove rows with the same y, yE from ps
    selected_rows = ps(same_rows,:);
    ps(same_rows,:) = []; seccombine2(same_rows,:) = []; total_cond(same_rows,:) = [];
    str = num2str(selected_rows(1,7:9),'(%d, %d, %d)');
    % If multiple rows are the same, combine their 7 to 9 columns
    if nnz(same_rows) > 1
        str = [str, sprintf(', (%d, %d, %d)',selected_rows(2:end,7:9)')];
    end
    a = [a; row(idx)];
    b = [b; {str}];
    seccombine3 = [seccombine3; row2];
    total_cond3 = [total_cond3; row3];
end
% Add lines that do not form part of a more operable configuration as well
[uniqueRowsB,idx2] = setdiff(allps(:,idx),a,'rows');
resultMatrix = [a; uniqueRowsB];
seccombine3 = [seccombine3; seccombine_all(idx2,:)];

for j = 1:size(seccombine3,1)
    C = seccombine3(j,:);
    resultString = '';
    for i = 1:3
        str = mat2str(C{i});
        if strcmp(str(1),'[')
            str = str(2:end-1);
        end
        if i < length(C)
            str = [str '; '];
        end
        resultString = [resultString str];
    end
    resultString = ['[' resultString ']'];
    seccombine4(j,1) = {resultString};
end

%% Plotting part 1
% Define where the generated images will be stored
save_path = fullfile('D:','plot_HITCDS',['BC',num2str(BC)],filesep);
if ~exist(save_path, 'dir')
    mkdir(save_path);
end
possible_structure = resultMatrix;
seccombine2 = seccombine3;

Width = 0.7;
Height = 1;
colInterval = 3.5;
vvc = [4 4 5 5 3 3 6 6 4 4 2 2]*Height;
H = ones(1,12);

if feedstream(2,1) == 0 && feedstream(4,1) ~= 0
    H(1) = 2;
    if feedstream(4,4) ~= 1
        H(8) = 2;
    end
end

if feedstream(3,1) == 0 && feedstream(6,1) ~= 0
    H(2) = 2;
    if feedstream(4,4) ~=3
        H(4) = 2;
    end
end

if feedstream(5,1) == 0
    H(4) = 2;
    H(8) = 2;
end
vvc(2:2:end) = vvc(2:2:end) - H(2:2:end);
H = H*Height;
coordinate = zeros(12,2);

%% Plotting part 2
close all
fig = figure;
for ii = 1:size(possible_structure,1)
    n = ii;
    row = 1;
    col = 1;

    for m = n:min(n+row*col-1,length(seccombine2))
        nexttile
        for i = 1:4
            text(-0.3,vvc(1)+Height*(1.5 - 0.6*i),char(64+i),'HorizontalAlignment','center','FontSize',12);
        end

        for j = 1:N - 1
            for k = seccombine2{m,j}
                rectangle('Position',[Width*(colInterval*(j - 1) + 1) vvc(k) Width H(k)],'LineWidth',1.5, ...
                    'EdgeColor',"k");
                text(Width*(colInterval*(j - 1) + 1)+0.5*Width,vvc(k)+0.5*H(k),num2str(k), ...
                    'HorizontalAlignment','center','VerticalAlignment','middle','FontSize',12);
                coordinate(k,:) = [Width*(colInterval*(j - 1) + 1) vvc(k)];
            end
        end

        hold on
        quiver(0,4*Height,Width,0,'LineWidth',1.5,'MaxHeadSize',0.5,"color","k","AutoScale","off")
        % Plotting thermally coupled flow arrows and submixtures related heat exchangers
        for k = 1:N*(N - 1)/2
            if ~isnan(slide_rail(k,1))
                sec1 = slide_rail(k,1);
                sec2 = slide_rail(k,2);
                sec4 = slide_rail(k,4);
                a = coordinate(sec2,1) > coordinate(sec1,1);
                quiver(coordinate(sec1,1)+a*Width,coordinate(sec1,2)+(1 - sec4)*H(sec1), ...
                    coordinate(sec2,1)-coordinate(sec1,1)+(-1)^a*Width,0,'LineWidth',1.5, ...
                    'MaxHeadSize',0.5,"color","k","AutoScale","off")
                if possible_structure(m,k) == 0
                    quiver(coordinate(sec2,1)+ ~a*Width,coordinate(sec2,2)+(1 - sec4)*H(sec2), ...
                        coordinate(sec1,1)-coordinate(sec2,1)+(-1)^ ~a*Width,0,'LineWidth',1.5, ...
                        'MaxHeadSize',0.5,"color","k","AutoScale","off")
                else
                    b = mod(k,2);
                    if a == 0,a = -1; end
                    rectangle('Position',[coordinate(sec1,1) + 0.5*a*Width, ...
                        coordinate(sec1,2) + (1 - sec4)*H(sec1) - 0.5*Width, Width, Width], ...
                        'Curvature',[1 1],'FaceColor','w','EdgeColor',[0.6* ~b,0,0.6*b],'LineWidth',1.5);
                end
            end
            
            if feedstream(5,4) == 201
                sec1 = 5;
                sec2 = 10;
                sec4 = 0;
                a = coordinate(sec2,1) > coordinate(sec1,1);
                quiver(coordinate(sec1,1)+a*Width,coordinate(sec1,2)+(1 - sec4)*H(sec1), ...
                    coordinate(sec2,1)-coordinate(sec1,1)+(-1)^a*Width,0,'LineWidth',1.5, ...
                    'MaxHeadSize',0.5,"color","k","AutoScale","off")
            end
        end

        % Plotting arrows and heat exchangers related to product stream
        for i = 1:size(feedstream,1)
            for j = 2:3
                if feedstream(i,j) >= 7
                    sec1 = 2*i - 3 + j;
                    prod = char(58+feedstream(i,j));
                    if (feedstream(i,j) == 8 || feedstream(i,j) == 9) && ...
                            find(cellfun(@(x) ismember(sec1,x),seccombine2(m,:))) == 2
                        ex = 0.5;
                    else
                        ex = 0;
                    end

                    b = 3 - j;
                    quiver(coordinate(sec1,1)+Width,coordinate(sec1,2)+b*H(sec1),Width*1.5,0, ...
                        'LineWidth',1.5,'MaxHeadSize',0.5,"color","k","AutoScale","off")
                    text(coordinate(sec1,1)+(3 - ex)*Width,coordinate(sec1,2)+b*H(sec1)+ex*Height, ...
                        prod,'HorizontalAlignment','center','FontSize',12);

                    if sum(feedstream(:,2:3) == feedstream(i,j),"all") == 1
                        rectangle('Position',[coordinate(sec1,1) + 0.5*Width, ...
                            coordinate(sec1,2) + b*H(sec1) - 0.5*Width, Width, Width],'Curvature',[1 1], ...
                            'FaceColor','w','EdgeColor',[~b,0,b],'LineWidth',1.5);
                    end
                end
            end
        end
        axis([-0.7 8 0 8],'equal');
        set(gca,'xtick',[],'xticklabel',[],'ytick',[],'yticklabel',[],'Box','on','Color','none')
        % text(1.1*Width,8*Height,num2str(possible_structure(m,7:9),'%d          '), ...
        %     'VerticalAlignment','middle','FontSize',12);
    end
    text(-0.5,7,['(' num2str(ii) ')'],'FontSize',18);
    % transparent output
    set(gcf,'color','none')
    set(gca,'color','none')
    set(gcf,'InvertHardCopy','off')

    exportgraphics(gcf,[save_path, num2str(BC),'-',num2str(n),'.tiff'],'Resolution',300) % tiff or png
    clf
end
close all
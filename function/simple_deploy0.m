function [feedstream,feedstreamSEN,seccombine,product] = ...
    simple_deploy0(N,A,colcombine,component,structure,CASE)
%{
Original TCDS with 0 1 for the presence of thermal links, robust simulation strategy, combine column.
spliter's numbering method is different from 1
This mode does not use design specifications
feedstream:
    col1: the number of the feedstream of column N.
    col2: the number of latter column when column top is thermally coupled, energy flow.
    col3: the number of latter column when column bottom is thermally coupled, energy flow.
    col4: The top (2n-1)/bottom (2n) of the column (SEN) from which the feed comes.
feedstreamSEN:
    col1: col n -> col N
    col2: top -> col n
    col3: bottom -> col n
    col4: 0 neither top nor bottom is a product stream; 1 top is a product; 2 bottom is a product;
          3 both top and bottom are products (only for merged C1 C2 C3).
product:
    col1: the serial number of stream to which the product corresponds
%}
% global aspen
% block = aspen.Tree.FindNode('\Data\Blocks\');
% stream = aspen.Tree.FindNode('\Data\Streams\');
colNumber = N*(N - 1)/2;
feedstream = zeros(colNumber,4);
feedstream(1,1) = 1;
feedstreamSEN = zeros(N-1,4);
product = zeros(1,N);
seccombine = cell(1,3);
[j, i] = meshgrid(1:4);
B = j.*(j - 1)/2 + i;
B = triu(B).*A;

%% Creating the basic structure and determining the connections between the upper and lower side
skip = zeros(colNumber,1);
for i = 1:length(colcombine)
    for j = 1:length(colcombine{i})
        p = colcombine{i}(j);
        seccombine{i} = [seccombine{i},2*p - 1,2*p];
        colname = ['C',num2str(i)];
        if j == 1
            % block.Elements.Add([colname,'!RADFRAC']);
            % block.FindNode([colname,'\Input\HYDRAULIC']).value='HYDRAULIC';
            % if p==1
            %     stream.Elements.Add('S1');
            %     block.FindNode([colname,'\Ports\F(IN)']).Elements.Add('S1');
            %     block.FindNode([colname,'\Input\FEED_CONVE2\S1']).value='ON-STAGE';
            %     stream.FindNode('S1\Input\PRES\MIXED').value=1;
            %     switch CASE
            %         case 1
            %             pause(0.5)
            %             stream.FindNode('S1\Input\MIXED_SPEC\MIXED').value='PV';
            %             stream.FindNode('S1\Input\VFRAC\MIXED').value=0;
            %             stream.FindNode(['S1\Input\FLOW\MIXED\',char(component(1))]).value=10;
            %             stream.FindNode(['S1\Input\FLOW\MIXED\',char(component(2))]).value=10;
            %             stream.FindNode(['S1\Input\FLOW\MIXED\',char(component(3))]).value=10;
            %             stream.FindNode(['S1\Input\FLOW\MIXED\',char(component(4))]).value=10;
            %         case 2
            %             stream.FindNode('S1\Input\TEMP\MIXED').value=101.5;
            %             stream.FindNode(['S1\Input\FLOW\MIXED\',char(component(1))]).value=3.54638349;
            %             stream.FindNode(['S1\Input\FLOW\MIXED\',char(component(2))]).value=26.14706472;
            %             stream.FindNode(['S1\Input\FLOW\MIXED\',char(component(3))]).value=242.0857544;
            %             stream.FindNode(['S1\Input\FLOW\MIXED\',char(component(4))]).value=26.08695652;
            %     end
            % end
            % stream.Elements.Add(['S',num2str(p*2)]);
            % stream.Elements.Add(['S',num2str(p*2+1)]);
            % block.FindNode([colname,'\Ports\B(OUT)']).Elements.Add(['S',num2str(p*2+1)]);
            % block.FindNode([colname,'\Input\NSTAGE']).value=500;
            % if i~=1
            %     for k=1:4*length(colcombine{i})-2
            %         block.FindNode([colname,'\Input\STAGE_PRES']).Elements.InsertRow(0, 0);
            %     end
            % end
        else
            % Bsteam=block.FindNode([colname,'\Ports\B(OUT)']).Elements.ItemName(0);
            % block.FindNode([colname,'\Ports\SP(OUT)']).Elements.Add(Bsteam);
            % stream.Elements.Add(['S',num2str(p*2+1)]);
            % block.FindNode([colname,'\Ports\B(OUT)']).Elements.Add(['S',num2str(p*2+1)]);
            skip(p) = 1;
        end
    end
end

%% establish a connection between the forward and backward column
for p = 1:colNumber
    [i,j] = find(B == p);
    if ~isempty(i)
        k1 = find(cellfun(@(x) any(x == p),colcombine));
        colname1 = ['C',num2str(k1)];
        for k = 1:N - j
            if B(i,j+k) > 0
                q = B(i,j+k);
                feedstream(p,2) = q;
                if j + k < N
                    k2 = find(cellfun(@(x) ismember(q,x),colcombine));
                    colname2 = ['C',num2str(k2)];
                    % if skip(p)==0
                    %     block.FindNode([colname2,'\Ports\F(IN)']).Elements.Add(['S',num2str(p*2)]);
                    %     block.FindNode([colname2,'\Input\FEED_CONVE2\S',num2str(p*2)]).value='ON-STAGE';
                    %     block.FindNode([colname1,'\Input\CONDENSER']).value='PARTIAL-V';
                    %     block.FindNode([colname1,'\Ports\VD(OUT)']).Elements.Add(['S',num2str(p*2)]);
                    % end

                    if isscalar(colcombine{k1}) || p == colcombine{k1}(1)
                        feedstream(q,1) = p*2;
                        feedstream(q,4) = 2*k1 - 1;
                        feedstreamSEN(k1,2) = k2;
                        feedstreamSEN(k2,1) = k1;
                    else
                        side_draw = find(colcombine{k1} == p) - 1;
                        feedstream(q,4) = str2double(num2str([k1, 0, side_draw],'%d'));
                        feedstreamSEN(k2,1) = feedstream(q,4);
                    end

                    % if p==colcombine{k1}(1)
                    %     HS=['S',num2str(p*2),'Q'];
                    %     HS1=['S',num2str(p*2),'Q1'];
                    %     HS2=['S',num2str(p*2),'Q2'];
                    %     spliter=['SP',num2str(p*2)];
                    %     stream.Elements.Add([HS,'!HEAT']);
                    %     stream.Elements.Add([HS1,'!HEAT']);
                    %     stream.Elements.Add([HS2,'!HEAT']);
                    %     block.Elements.Add([spliter,'!FSPLIT']);
                    %     block.FindNode([colname1,'\Ports\CHS(OUT)']).Elements.Add(HS);
                    %     block.FindNode([spliter,'\Ports\HS(IN)']).Elements.Add(HS);
                    %     block.FindNode([spliter,'\Ports\HS(OUT)']).Elements.Add(HS1);
                    %     block.FindNode([spliter,'\Ports\HS(OUT)']).Elements.Add(HS2);
                    %     block.FindNode([colname2,'\Ports\HS(IN)']).Elements.Add(HS1);
                    % end
                    break
                else
                    if p == colcombine{k1}(1)
                        product(1,i) = p*2;
                        % product(2,i)=q-colNumber;
                        feedstreamSEN(k1,4) = feedstreamSEN(k1,4) + 1;
                        % block.FindNode([colname1,'\Input\CONDENSER']).value='TOTAL';
                        % block.FindNode([colname1,'\Ports\LD(OUT)']).Elements.Add(['S',num2str(p*2)]);
                    end
                end
            end
        end
        for k = 1:N - j
            if B(i+k,j+k) > 0
                q = B(i+k,j+k);
                feedstream(p,3) = q;
                if j + k < N
                    k2 = find(cellfun(@(x) ismember(q,x),colcombine));
                    colname2 = ['C',num2str(k2)];
                    % block.FindNode([colname2,'\Ports\F(IN)']).Elements.Add(['S',num2str(p*2+1)]);
                    % block.FindNode([colname2,'\Input\FEED_CONVE2\S',num2str(p*2+1)]).value='ON-STAGE';

                    feedstream(q,1) = p*2 + 1;
                    if isscalar(colcombine{k1}) || p == colcombine{k1}(end)
                        feedstream(q,4) = 2*k1;
                        feedstreamSEN(k1,3) = k2;
                        feedstreamSEN(k2,1) = k1;
                    end

                    % if p==colcombine{k1}(end)
                    %     HS=['S',num2str(p*2+1),'Q'];
                    %     HS1=['S',num2str(p*2+1),'Q1'];
                    %     HS2=['S',num2str(p*2+1),'Q2'];
                    %     spliter=['SP',num2str(p*2+1)];
                    %     stream.Elements.Add([HS,'!HEAT']);
                    %     stream.Elements.Add([HS1,'!HEAT']);
                    %     stream.Elements.Add([HS2,'!HEAT']);
                    %     block.Elements.Add([spliter,'!FSPLIT']);
                    %     block.FindNode([colname1,'\Ports\RHS(OUT)']).Elements.Add(HS);
                    %     block.FindNode([spliter,'\Ports\HS(IN)']).Elements.Add(HS);
                    %     block.FindNode([spliter,'\Ports\HS(OUT)']).Elements.Add(HS1);
                    %     block.FindNode([spliter,'\Ports\HS(OUT)']).Elements.Add(HS2);
                    %     block.FindNode([colname2,'\Ports\HS(IN)']).Elements.Add(HS1);
                    % end
                    break
                else
                    product(1,i+k) = p*2 + 1;
                    % product(2,i+k)=q-colNumber;
                    if p == colcombine{k1}(end)
                        feedstreamSEN(k1,4) = feedstreamSEN(k1,4) + 2;
                    end
                end
            end
        end
    end
end

%% Setting the baseline for the D:F specification to the key component of the total feed + the distributed component
% for k=1:N-1
%     if feedstreamSEN(k,4)==0 || (structure==17 && k==2)
%         colname=['C',num2str(k)];
%         [i,j]=find(B==feedstream(colcombine{k}(1),2));
%         for m=i:i+N-j
%             block.FindNode([colname,'\Input\DB_COMPS']).Elements.InsertRow(0,m-i);
%             block.FindNode([colname,'\Input\DB_COMPS']).Elements.Item(m-i).value=component(m);
%         end
%     end
% end
% if structure==17
%     block.FindNode("C2\Input\DB_STREAMS").Element.InsertRow(0,0);
%     block.FindNode("C2\Input\DB_STREAMS\#0").value='S2';
% end
% aspen.Tree.FindNode("\Data\Setup\Model-Option\Input\TOLOL").value=1e-5;
% aspen.Save;

end
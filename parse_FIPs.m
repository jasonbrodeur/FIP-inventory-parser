% This is handy! https://www.rexegg.com/regex-quickstart.html
clearvars;
data_dir = 'D:\GDrive\Library\Maps, Data, GIS\Groups\OCUL Geo\FIP Digitization\2008 FIP inventory\2CdnFIPs18751975\';
fid = fopen([data_dir 'ON8.csv']);

record_num = 1;
rec_line = 1;
eof = feof(fid);
line_num = 0;
title = {}; descr = {}; notes = {}; ledger = {}; holdings = {};
while eof == 0
    tline = fgetl(fid); tline = strrep(tline,'"','');
    line_num = line_num+1;
    if isempty(tline)==1 || isempty(strrep(tline,' ',''))==1
        record_num = record_num+1;
        rec_line = 1;
        continue;
    end
    
    if rec_line == 1 % If we're on the first line of a record (assuming it contains the title)
        hdr = 'title';
        to_write = tline;
        right_col = 1;
        parse_flag=0; % No need for further parsing
        %     title{record_num,1}=to_write;
    elseif rec_line == 2 % Description
        if strcmp(tline(1:2),'  ')==1 || strcmp(tline(1:5),'1 map')==1 || strcmp(tline(1:7),'SHEETS:') ==1
            hdr = 'descr';
            to_write = strip(tline(1:end));
            right_col = 1;
            parse_flag=0; % No need for further parsing
            
        elseif strcmp(tline(1:6),'NOTES:')==1 || strcmp(tline(1:8),'HELD AT:')==1
            parse_flag = 1;
            disp(['2nd line issue. Line:' num2str(line_num) ' record:' num2str(record_num) ' Text: ' tline(1:10) '. Passed to parser.']);
            
        else
            hdr = 'title';
            to_write = [title{record_num,1} '. ' tline];
            disp(['2nd line issue. Line:' num2str(line_num) ' record:' num2str(record_num) ' Text: ' tline(1:10) '. Added to title.']);
            rec_line = rec_line-1;
            parse_flag=0; % No need for further parsing
            
        end
        %     descr{record_num,size(descr(record_num,:),2)+1}=to_write;
    else
        parse_flag = 1;
    end
    
    if parse_flag==1
        switch tline(1:3)
            case 'NOT'
                hdr = 'notes';
                to_write = tline(8:end);
                right_col = 1;
                %            notes{record_num,size(notes(record_num,:),2)+1}=to_write;
            case 'LED'
                hdr = 'ledger';
                to_write = tline(9:end);
                right_col = 1;
                %            ledger{record_num,size(ledger(record_num,:),2)+1}=to_write;
            case 'HEL'
                hdr = 'holdings';
                to_write = tline(10:end);
                right_col = 1;
                %            holdings{record_num,size(holdings(record_num,:),2)+1}=to_write;
            otherwise % case '   ' % switched this from '   ' to overwise after viewing all exceptions
                hdr = hdr;
                %            to_write = tline(4:end);
                
                to_write = strtrim(tline);
                right_col = right_col + 1;
                %        otherwise
                %            disp(['Found exception in first three characters of line: ' tline]);
                %            continue;
        end
    end
    % if size(eval(hdr),1)==record_num %if writing into an existing row
    % eval([hdr '{record_num,size(' hdr '(record_num,:),2)+1}=to_write;']);
    % else
    eval([hdr '{record_num,right_col}=to_write;']);
    % end
    
    rec_line = rec_line + 1;
    
    eof = feof(fid);
    
end

fclose(fid);

%% Shrink all cell arrays to remove rows with blank entries for 'title'

for i = 1:1:length(title)
    remove_ind(i,1) = isempty(title{i,1});
end
title(remove_ind==1,:)= [];
holdings(remove_ind==1,:)= [];
ledger(remove_ind==1,:)= [];
notes(remove_ind==1,:)= [];
descr(remove_ind==1,:)= [];

%% Pull out information from generated variables

for i = 1:1:length(title)
    tmp = strtrim(title{i,1});
    % Pull Scale from title:
    ind = strfind(tmp,'Scale');
    if isempty(ind)==1
        disp(['No match for scale at row ' num2str(i) ' . Skipping'])
        scale{i,1} = [];
    else
        tmp2 = tmp(ind:end);
        ind2 = strfind(tmp2,'.');
        scale{i,1} = strtrim(tmp2(6:ind2(1)-1));
    end
    
    % Pull location from title?
    %%% Pre-conditioning: 
   
    tmp = strrep(tmp,'Provincial Insurance Surveys, ','');
    tmp = strrep(tmp,'Lloyd�s Insurance Surveys ','');
    
    try
        if strcmpi(tmp(1:9),'Insurance')==1 || strcmpi(tmp(1:5),'Lloyd')==1 || strcmpi(tmp(1:5),'Atlas')==1
            ind_comma_tmp = strfind(tmp,',');
            ind_of_long = strfind(lower(tmp(1:ind_comma_tmp(1)-1)),' of the town of');
            if isempty(ind_of_long)==1
                ind_of_long = strfind(lower(tmp(1:ind_comma_tmp(1)-1)),' of the city of');
            end
            if isempty(ind_of_long)==1
                ind_of_long = strfind(lower(tmp(1:ind_comma_tmp(1)-1)),' of the village of');
            end
            if isempty(ind_of_long)==1
                ind_of_long = strfind(lower(tmp(1:ind_comma_tmp(1)-1)),' of part of');
            end
            if isempty(ind_of_long)==1
                ind_of_long = strfind(lower(tmp(1:ind_comma_tmp(1)-1)),' of the municipality of');
            end
            clear ind_comma_tmp
            ind_of = strfind(lower(tmp),' of ');
            if isempty(ind_of_long)==1
                tmp = tmp(ind_of(1)+4:end);
            else
                tmp = tmp(ind_of(2)+4:end);
            end
            ind_comma = strfind(tmp,',');
            place{i,1} = tmp(1:ind_comma(1)-1);
        elseif strcmpi(tmp(1:7),'City of')==1 
            ind_comma = strfind(tmp,',');
            place{i,1} = tmp(9:ind_comma(1)-1);
        elseif strcmpi(tmp(1:7),'Village of')==1 
            ind_comma = strfind(tmp,',');
            place{i,1} = tmp(9:ind_comma(1)-1);    
        elseif strcmp(tmp(1),'[')==1
            ind_rb = strfind(tmp,']');
            place{i,1} = tmp(1:ind_rb);
        else
            ind_comma = strfind(tmp,',');
            place{i,1} = tmp(1:ind_comma(1)-1);
        end
    catch
        disp(['Error parsing placename for record: ' num2str(i) '. Title: ' tmp]);
        place{i,1} = [];
    end
    clear tmp* ind*
    
    % Trim holdings
    if ~isempty(holdings{i,1})==1
    holdings{i,1} = strip(holdings{i,1});
    else
    holdings{i,1} = '';   
    end
        holdings{i,1} = strrep(holdings{i,1},'  ',' ');
    holdings{i,1} = strrep(holdings{i,1},' (','(');
    holdings{i,1} = strrep(holdings{i,1},'  (','(');
    
%     holdings{i,1} = regexprep(holdings{i,1},'/s[A-Z]','
%     holdings{i,1} = strrep(holdings{i,1},' ','; ');
%     holdings{i,1} = strrep(holdings{i,1},'; ; ','; ');
     holdings{i,1}(regexp(holdings{i,1},'\s[A-Z]')) = ';';
    
    % Condense description information into a single column
    tmp_desc = '';
    for j = 1:1:size(descr(i,:),2)
        if ~isempty(descr{i,j})==1
            if j ==1
            tmp_desc = descr{i,j};
            else
            tmp_desc = [tmp_desc '; ' descr{i,j}];
            end
        end
    end   
    descr{i,1} = strip(tmp_desc);
    clear tmp_desc;
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Now, break description into two separate fields -- 
    % a) 'Description' field will be distilled to contain only the number of sheets/plates. 
    % b) Make a new field called 'size' that contains the dimensions.

    ind_pl_sh = strfind(descr{i,1},'plate');
    if isempty(ind_pl_sh)==1
    ind_pl_sh = strfind(descr{i,1},'sheet');
    format{i,1} = 'sheet';
    else
    format{i,1} = 'plate';
    end
    
    if ~isempty(ind_pl_sh)==1
    tmp_str = descr{i,1}(1:ind_pl_sh); ind_bl = findstr(tmp_str,' ');
    num_items{i,1} = tmp_str(ind_bl(end-1)+1:ind_bl(end)-1);
    else
    num_items{i,1} = '';
    format{i,1} = '';
    end
    clear ind_pl_sh ind_bl tmp_str
    
    %%%%%%%% b) extract size
    ind_size_start = regexp(descr{i,1},';\s[1-9][1-9]');
    ind_size_end = regexp(descr{i,1},'\scm');

    if ~isempty(ind_size_start) && ~isempty(ind_size_end)
        dimensions{i,1} = strip(descr{i,1}(ind_size_start(1)+2:min(ind_size_end(1)+3,length(descr{i,1}))));
    if strcmp(dimensions{i,1}(end),'.')~=1
        dimensions{i,1}(end+1) = '.';
    end
    else
        dimensions{i,1} = '';
    end
    
    %%%%%%%%%%%%%% Condense notes information into a single column
    tmp_notes = '';
    for j = 1:1:size(notes(i,:),2)
        if ~isempty(notes{i,j})==1
            if j ==1
            tmp_notes = notes{i,j};
            else
            tmp_notes = [tmp_notes '; ' notes{i,j}];
            end
        end
    end
    notes{i,1} = strip(tmp_notes); clear tmp_notes;
%%%%%%%%%%%%%% Condense ledger information into a single column
    tmp_ledger = '';
    for j = 1:1:size(ledger(i,:),2)
        if ~isempty(ledger{i,j})==1
            if j ==1
            tmp_ledger = ledger{i,j};
            else
            tmp_ledger = [tmp_ledger '; ' ledger{i,j}];
            end
        end
    end
    ledger{i,1} = strip(tmp_ledger); clear tmp_ledger;
    
    %%%%%%%%%%%% Pull out the years within the 'title' text?
    tmp_str = title{i,1};
    ind_years = regexp(tmp_str,'\[1[8-9][0-9][0-9]\]'); 
    tmp_years = {};
    for k = 1:1:length(ind_years)
        tmp_years{size(tmp_years,1)+1,1} = tmp_str(ind_years(k):ind_years(k)+5);
    end
    ind_years = regexp(tmp_str,'(?<!\[)1[8-9][0-9][0-9]'); 
    for k = 1:1:length(ind_years)
        tmp_years{size(tmp_years,1)+1,1} = tmp_str(ind_years(k):ind_years(k)+3);
    end
    tmp_years = unique(tmp_years);
    if ~isempty(tmp_years)==1
years{i,1} = sprintf('%s;',tmp_years{:});
years{i,1} = years{i,1}(1:end-1);
    else
        years{i,1} = '';
    end
    clear tmp_str tmp_years ind_years
%     if ~isempty(descr{i,1})==1
%     descr{i,1} = strip(descr{i,1});
%     else
%     descr{i,1} = '';   
%     end
    % Reformat notes:
%     for j = 1:1:size(notes(i,:),2)
%        tmp =  
%         
%     end
end
    descr(:,2:end) = [];  

notes(:,2:end) = [];   
ledger(:,2:end) = [];   

%% Compile final output:
out = [title place years scale ledger holdings descr dimensions num_items format notes];
out = [{'Title','Place Name','Year','Scale','Ledger','Holdings','Full Description','Dimensions','Number of items','Format','Notes'};out];
xlswrite([data_dir 'ON8-clean.xls'],out);
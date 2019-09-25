% save copies of files in tmp folder, run the Content report to replace
% first line comments in file, then use this script to put back the erase
% first line comment

fn_cd brick
d = dir('tmp\*.m');
files = {d.name};

i = 1;
%%

for i = i:length(files)
    f = files{i};
	f2 = fullfile('tmp',f);
    disp(f)
    a = fn_readtext(f);
    b = fn_readtext(f2);
    if ~strcmp(a{1},b{1})
        % maybe is it the first line rather than the second that has been
        % modified... rectify because we know that all files are function,
        % not script
        a(1:2) = [b(1) a(1)];
    end
    if isequal(a([1 4:end]), b)
        % everything seems fine!
    elseif ~isequal(a([1 3:end]), b([1 3:end]))
        answer = questdlg(['Problem with ' f],'fix Contents','Edit','Skip','Edit');
        switch answer
            case 'Edit'
                edit(f)
                edit(f2)
            case ''
                break
        end
    elseif ~strcmp(a{2},b{2})
        x = fn_regexptokens(b{2},'^( *%)');
        c = [a(1:2); [x '---']; b(2:end)];
        show = char(c(1:5));
        answer = questdlg(show(:,1:min(end,70)),'fix Contents','Ok','Edit','Skip','Ok');
        switch answer
            case 'Ok'
                fn_savetext(c,f)
            case 'Edit'
                edit(f)
                edit(f2)
            case ''
                break
        end
    end
end

%% check files starting with comment

if eval('false')
        %% ()
    fn_cd brick
    d = dir('*.m');
    for i = 1:length(d)
        f = d(i).name;
    %     disp(f)
        a = fn_readtext(f);
        if any(a{1}=='%')
            edit(f)
        end
    end
end


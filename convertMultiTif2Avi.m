
fid = fopen('list2plot.txt');

directories = {};
while ~feof(fid)
directories{end+1} = fgetl(fid);
end
fclose(fid);


for ii = 1:numel(directories)
    tiffintoavi(directories{ii})
end
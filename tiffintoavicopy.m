% turn hdf5 into avi for presentations with white background
function tiffintoavi(directory)

frameRate = 30; % set frame rate of movie
useEveryNthFrame = 1; % set to only use every 2nd, 3rd, etc frame

if directory(end) == filesep
    directory = directory(1:end-1);
end
dd = strsplit(directory, filesep);
newmovie_name = [strrep(dd{end}, ' TIFF', ''), '.avi'];

fprintf('Directory %s will be converted in to the movie %s.\n', directory, newmovie_name)

% create a list of all the images in the directory
[file_list,~]=dirSearch(directory,'.tif');

%%
disp('Calculating the correct order of images.')
index_order = zeros(size(file_list));
for n = 1:numel(file_list)
    index_order(n) = str2double(n);
end
disp(numel(file_list));
%%
[~, ind_sort] = sort(index_order);
ordered_files = file_list(ind_sort);
%%
disp('Creating movies...')

%create the video object
aviobj = VideoWriter(newmovie_name);
% set frame rate
aviobj.FrameRate = frameRate;
open(aviobj);
%add to the v object the images
for n=1:useEveryNthFrame:numel(ordered_files)
    filename=ordered_files{n};
    disp(filename)
    frame=imread(filename);
    writeVideo(aviobj,double(frame)/255);
end
% close the video object, your first video is ready for Monday :)
close(aviobj);
%end
% script for loading HDF5 trajectory files, counting the number of worms
% i.e. tracks per frame, and plot it against frame progression

% set the root directory
% directory = ['/Volumes/behavgenom$/Pratheeban/MaskedVideos/' ...
%     'L1_early/15_07_07/'];
% directory = '/Volumes/behavgenom$/Pratheeban/Results/L1_early/15_07_07/';
directory = '/Users/serenading/Desktop/shared/data/recording 43/Results/recording 43.1 green 100-350 TIFF';

% get a list of trajectory files
[fileList, ~] = dirSearch(directory, '_trajectories.hdf5');



%% loop through files
for ii = 1:numel(fileList)
    
    % load current trajectory data
    trajData = h5read(fileList{ii}, '/plate_worms');
    
    % get the number of unique frames and remove invalid frames
    frameIDs = unique(trajData.frame_number)';
    frameIDs(frameIDs <= 0) = [];
    
    %create new figure
    figure
    hold on
    
    %create variable to hold y values for number of worms per frame
    numframes = numel(frameIDs);
    y = zeros(1,numframes);
   
    % loop through each frame in file
    for jj = 1:numframes
        
        %get the current frame
        CurrentFrame = trajData.frame_number == frameIDs(jj);
        
        % get the number of worm indices of that frame
        y(jj) = numel(trajData.worm_index_joined(CurrentFrame));
        
    end
    
    % plot trajectory
    plot(frameIDs, y)
    xlabel('frame number')
    ylabel ('number of worms')
    ylim([0,300])
    title ('number of worms per frame')
    
    fprintf 'press any button to continue to next file\n'
    waitforbuttonpress
    
end

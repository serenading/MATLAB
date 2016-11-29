% script for loading HDF5 trajectory files, calculating trajectories,
% and plotting the results on a single figure in different colours

% set the root directory
% directory = ['/Volumes/behavgenom$/Pratheeban/MaskedVideos/' ...
%     'L1_early/15_07_07/'];
% directory = '/Volumes/behavgenom$/Pratheeban/Results/L1_early/15_07_07/';
directory = '/Users/serenading/Desktop/shared/data/recording 40/Results/recording 40.2 green 100-200 TIFF';

% get a list of trajectory files
[fileList, ~] = dirSearch(directory, '_trajectories.hdf5');



%% loop through files
for ii = 1:numel(fileList)
    
    % load current trajectory data
    trajData = h5read(fileList{ii}, '/plate_worms');
    
    % get the IDs for each track and remove invalid tracks
    trackIDs = unique(trajData.worm_index_joined)';
    trackIDs(trackIDs <= 0) = [];
    
    %create new figure
    figure
    hold on

    % loop through trajectories in file
    for jj = 1:numel(trackIDs)
        
        % get the current track indices
        currentInds = trajData.worm_index_joined == trackIDs(jj);
        
        % get x and y coordinates for path features
        x = trajData.coord_x(currentInds);
        y = trajData.coord_y(currentInds);
        
        % plot trajectory
        plot(x, y)
    end
    
    axis equal
    xlabel('x coordinate')
    ylabel ('y coordinate')
    title ('worm trajectories')
    
    fprintf 'press any button to continue to next file\n'
    waitforbuttonpress
    
end
%%
fprintf 'press any button to close all figures\n'
waitforbuttonpress
close all

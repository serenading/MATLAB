% script for loading HDF5 trajectory files, counting the number of worms
% i.e. tracks per frame, and plot it against frame progression

% set the root directory
% directory = '/Volumes/behavgenom$/Pratheeban/Results/L1_early/15_07_07/';
directory = '/data2/shared/data/recording 31/Results/recording 31.4 green 100-350 TIFF';

% get a list of trajectory files
[fileList, ~] = dirSearch(directory, '_trajectories.hdf5');


%% loop through files
for ii = 1:numel(fileList)
    
    % load current trajectory data
    trajData = h5read(fileList{ii}, '/plate_worms');
    
    % plot histogram
    histogram(trajData.frame_number,'BinWidth',1,'DisplayStyle','stairs')
    
end

xlabel('frame number','FontSize',20)
ylabel('number of tracked objects','FontSize',20)
set(gca,'FontSize',15)
hold on
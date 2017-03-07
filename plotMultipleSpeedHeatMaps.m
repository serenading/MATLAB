main_dir = '/Users/sding/Documents/MATLAB/Figs/speeds/SpeedHeatMaps/IntensityThresholding/HA_40/';
files = dir([main_dir, '*.mat']);
figure
    
for ii = 1:numel(files)
    
    load(fullfile(main_dir, files(ii).name))
    subplot(3,4,ii)
    imagesc(speedmatrix)
    title(files(ii).name)
    set(gca,'YDir','normal')
end
    
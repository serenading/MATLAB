% script for loading HDF5 trajectory files, counting the number of worms
% i.e. tracks per frame, and plot it against frame progression

% retrieve the list of files to plot

fid = fopen('list_to_plot.txt');
sfpath = fgetl(fid);

% set counter for assigning line color
ii = 1;

while ischar(sfpath)
    disp(sfpath)
    
    % load current trajectory data
    trajData = h5read(sfpath,'/plate_worms');
    
    % plot histogram
    plotcolor = lines(15);
    histogram(trajData.frame_number,'BinWidth',9,'DisplayStyle','stairs','EdgeColor',plotcolor(ii,:),'Normalization','countdensity')  
    xlabel('frame number','FontSize',20)
    ylabel('number of tracked objects','FontSize',20)
    set(gca,'FontSize',15)
    hold on
    
    % go to the next file
    sfpath = fgetl(fid);
    ii = ii+1;
end

fclose(fid);
fprintf 'Done plotting\n'
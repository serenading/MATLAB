% calculate worm speeds from tracking data over a given range of frames

%% set variables
% directory should be set to the skeleton file for the appropriate movie
directory = '/data2/shared/data/twoColour/Results/recording58/recording58.1g100-350TIFF/recording58.1g_X1_skeletons.hdf5';
firstframe = 1;
NumberOfFrames = 20;
MaxSpeed = 51.3;

%% load trajectory data and loop through frames to calculate speed
skelTrajData = h5read(directory,'/trajectories_data');

% create a vector to loop through for each frame
FrameList = [firstframe:firstframe+NumberOfFrames];
ii = 1;
speedlist = cell(1,NumberOfFrames);

% loop through each frame
for ii = 1:numel(FrameList)
    
    % calculates the x, y positions and u, v displacement components
    currentFrameLogInd = skelTrajData.frame_number== FrameList(ii);
    nextFrameLogInd = skelTrajData.frame_number== FrameList(ii) + 1;
    wormInds = unique(skelTrajData.worm_index_joined(currentFrameLogInd));
    nWorms = numel(wormInds);
    % get positions
    x = skelTrajData.coord_x(currentFrameLogInd);
    y = skelTrajData.coord_y(currentFrameLogInd);
    % initialise displacements
    u = NaN(size(x));
    v = NaN(size(y));
    % calculate displacements, checking that there are no tracking errors
    if nnz(currentFrameLogInd)>nWorms
        warning(['Some worm(s) appear(s) more than once in frame ' num2str(FrameList(ii)) '. Cannot calculate speed.'])
    else
        % check which worms continute to next frame
        nextFrameWormLogInd = nextFrameLogInd&ismember(skelTrajData.worm_index_joined,wormInds); %returns logical indices for next frame that have the worm
        overlapLogInd = ismember(wormInds,skelTrajData.worm_index_joined(nextFrameLogInd)); %returns logical indices for worms that appear in both frames
        if nnz(nextFrameWormLogInd) > nnz(overlapLogInd)
            warning(['Some worm(s) from frame ' num2str(FrameList(ii)) ' appear(s) more than once in frame ' num2str(FrameList(ii)) '+1. Cannot calculate speed.'])
        else
            u(overlapLogInd) = skelTrajData.coord_x(nextFrameWormLogInd) - x(overlapLogInd);
            v(overlapLogInd) = skelTrajData.coord_y(nextFrameWormLogInd) - y(overlapLogInd);
            speed = sqrt(u.^2 + v.^2);
            if any(~overlapLogInd)
                disp([ num2str(nnz(~overlapLogInd)) ' of ' num2str(nWorms) ' worms did not appear in frame ' num2str(FrameList(ii)) '+1.'])
            end
            % add speed data to a cell
            speedlist{ii} = speed;
            ii = ii+1;
        end
    end
end

%% plot histogram
speedlist = vertcat(speedlist{:});
% convert speeds from pixel/frame to micron/frame
speedlistmicron = speedlist/19.5*100;
histogram(speedlistmicron,'BinWidth',0.5,'Normalization','Probability','EdgeColor','none')
xlim([0,MaxSpeed])
xlabel('speed (microns/frame)','FontSize',20)
ylabel('probability','FontSize',20)
t = title(strcat({directory(28:41)},{', frames '},{num2str(firstframe)},{'-'},{num2str(firstframe+NumberOfFrames)}));
set(gca,'FontSize',10)
set(t,'Fontsize',15)
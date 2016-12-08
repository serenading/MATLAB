% calculate worm speeds from tracking data over a given range of frames

%% set variables
directory = '/Users/sding/Desktop/new/data/Results/recording 37.4 green 100-350 TIFF/recording 37.4 green_X1_skeletons.hdf5';
firstframe = 300;
NumberOfFrames = 20;
MaxSpeed = 10;

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
histogram(speedlist,'BinWidth',0.1)
title(strcat({'recording '},{num2str((directory(end-28:end-24)))},{', frames '},{num2str(firstframe)},'-',{num2str(firstframe+NumberOfFrames)}))
xlim([0,MaxSpeed])
xlabel('speed (pixels/frame)','FontSize',20)
ylabel('incidence','FontSize',20)
set(gca,'FontSize',15)
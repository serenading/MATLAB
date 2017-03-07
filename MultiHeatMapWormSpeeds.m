% calculate worm speeds from tracking data from a list of files and save
% speeds over the entire length of the movie as individual matrices

%% set variables

% retrieve the list of files to plot, one line at a time
fid = fopen('list2plot.txt');
% set the number of frames used to generate each column of the heatmap
framespercol = 20;
% set maximum speed in microns per frame (=50 for movies at 9fps and =150
% for movies at 3 fps)
maxspeed = 50;

%% load trajectory file off the list, one at a time
directory = fgetl(fid);
while ischar(directory)
    disp(directory)
    skelTrajData = h5read(directory,'/trajectories_data');
    % determine total number of frames in the video
    totalframe = max(skelTrajData.frame_number);
    % determine total columns of frames inside the heatmap, ignoring the last
    % few frames that won't suffice for a full framebin
    totalcol = floor(totalframe / framespercol);
    % generate empty matrix to hold speed values for each column
    speedmatrix = zeros(100,totalcol);
    % set first frame
    firstframe = 1;
    % set first column number
    colnum = 1;
    
    %% loop through each column of pooled frames
    while colnum <= totalcol
        %% calculate speed for each column
        
        % create a vector to loop through for each frame
        FrameList = [firstframe:firstframe+framespercol];
        ii = 1;
        speedlist = cell(1,framespercol);
        
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
                elseif any(overlapLogInd)
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
        % compile speeds within the frame bin, i.e. 20 frames
        speedlist = vertcat(speedlist{:});
        % convert speeds from pixel/frame to micron/frame
        speedlistmicron = speedlist/19.5*100;
        % set maximum speed to 50 microns/frame
        removespeed = find(speedlistmicron>maxspeed);
        speedlistmicron(removespeed)=[];
        % retrieve the number of instances that fall within each speed bin
        h = histogram(speedlistmicron,'BinWidth',0.5,'NumBins',100,'Normalization','Probability');
        % add histogram values to the appropriate column of speed matrix
        speedmatrix(:,colnum) = h.Values';
        
        % go onto the next column
        colnum = colnum+1;
        firstframe = firstframe+framespercol;
    end
    
    %% save speedmatrix data
    % set name of speedmatrix file to be saved at the end
    matname = strcat({directory(38:41)},{'speed.mat'});
    save(char(matname),'speedmatrix')
    
    %% go to the next line/file
    directory = fgetl(fid);
end
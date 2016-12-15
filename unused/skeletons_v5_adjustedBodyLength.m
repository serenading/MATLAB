%% Script for extracting features, calculating statistics & plotting.


%% Get list of features files.

directory = '/Users/pnambyiah/Desktop/Worms/Results/';
% directory = '/Volumes/behavgenom_archive$/Pratheeban/Results/';
[fileList, ~] = dirSearch(directory, '_feat_manual.hdf5');

% Searches within directory for files ending in '_feat_ind.hdf5', outputs a
% matrix called fileList.  Each element in fileList is the path to a file.
% The function has have TWO output arguments (fileList and wormNames), so
% '~' is used to ignore wormNames.

%% label experiments

expName = cell(numel(fileList), 1);
% Creates empty cell array called expName.

for ii = 1:numel(fileList)
    
    slashInds = strfind(fileList{ii}, '/');
    % Gets slash positions in the file path. This will output 1, 9, 21 etc.
    % i.e. the index of the '/' in the file path.
    
    % expName{ii} = fileList{ii}(slashInds(5)+1:slashInds(6)-1); 
    expName{ii} = fileList{ii}(slashInds(6)+1:slashInds(7)-1); 
    % Search within each element in fileList for the string of characters
    % between slash index (5) and slash index (6), and populate the
    % appropriate row of expName with this string. This will be e.g.
    % 'L1_early'.
end

uniqueNames = unique(expName);
% List just the unique instances of experiment names, i.e. L1_early,
% L1_late, L2, L3, L4, New_Adult, Old_Adult.

%% Get feature list template from .csv file.

featureIndexes = struct();
featureList = {};
% Struct is for reference. Cell array will be used in the script below.

featureCount = 1;
fid = fopen('feature_list_standard.csv', 'r');
while 1
    feature = fgetl(fid);
    if ~ischar(feature), break, end
    
    featureList{end+1} = lower(feature);
    featureIndexes.(feature) = featureCount;
    featureCount = featureCount + 1;
end
% Reads line-by-line from the file above, and populates each line in the
% file into featureList. featureIndexes is also created, for reference.

fclose(fid);

%% Extract feature means.

% First create some matrices.
featMatTotal = [];
rowNames = cell(100,1);
rowCount = 1;
plateNumbers = zeros(3,1);

% Loop through files
for ii = 1:numel(fileList)
    
    disp(ii/numel(fileList));
    
    % Read the features.hdf5 file, and access the mean features dataset.
    featAvg = h5read(fileList{ii}, '/features_means'); 

    % Create a new matrix of size 'no. of worm IDs x no. of features'
    featMat = nan(numel(featAvg.worm_index), numel(featureList));
    
    % For each worm ID, assign to a stage name, and a plate number (i.e. a file). 
    for jj = 1:numel(featAvg.worm_index)
            rowNames{rowCount} = expName{ii};
            plateNumbers(rowCount) = ii;
            rowCount = rowCount + 1;
    end
    
    % Take each element in the template featureList, identify the
    % corresponding feature in featAvg, and populate that into featMat in
    % the correct column. The advantage of this is that if the features in
    % featAvg don't exactly match with the template, there will be an
    % error. Note the exact ORDER of features does not matter - the order
    % in featMat will be as the order in featureList, even if the order in
    % featAvg is different.
    for kk = 1:numel(featureList);
        featMat(:, kk) = featAvg.(featureList{kk});
    end
    
    % Now calibrate units. First pick appropriate pixelsPerMicron value for
    % magnification. Magnifications used & pixelsPerMicron are as follows:
    
    % L1_Early, L1_Late, L2 - mag x2.0, pixelsPerMicron 0.363
    % L3 - mag x1.6, pixelsPerMicron 0.289
    % L4 - mag x1.25, pixelsPerMicron 0.224
    % New_Adult & Old_Adult - mag x1, pixelsPerMicron 0.178
   
    temp = strncmp(expName{ii}, 'L1_', 3);
    if temp == 1;
        pixelsPerMicron = 0.363;
    end
    temp = strcmp(expName{ii}, 'L2');
    if temp == 1;
        pixelsPerMicron = 0.363;
    end
    temp = strcmp(expName{ii}, 'L3');
    if temp == 1;
        pixelsPerMicron = 0.289;
    end
    temp = strcmp(expName{ii}, 'L4');
    if temp == 1;
        pixelsPerMicron = 0.224;
    end
    temp = strcmp(expName{ii}, 'New_Adult');
    if temp == 1;
        pixelsPerMicron = 0.178;
    end
    temp = strcmp(expName{ii}, 'Old_Adult');
    if temp == 1
        pixelsPerMicron = 0.178;
    end

%   Now use the function convertUnits2 to convert featMat into values where
%   distance is in microns, not pixels. We assume that frame rate is
%   25Hz, and that other units are unchanged. See notes within
%   convertUnits2.
    featMatConv = convertUnits2(featMat, featureList, 'feature_list_standard.csv', pixelsPerMicron);
    
    % add current feature matrix to total
    featMatTotal = [featMatTotal; featMatConv];
    
end

%% adjust feature values for body lengths.

% copy feature values into new matrix.
featMatAdj = featMatTotal;

% decide which features need adjusting & gather those indices.
adjIndex = [191:194, 199:210, 363:442, 523:538, 651:654, 677, 686:689, ...
    698:701, 703, 705, 707, 709, 711, 713];

% divide the appropriate feature values by body length - only those
% feature values corresponding to the above indices are altered.
for ii = 1:numel(adjIndex);
    featMatAdj(:, adjIndex(ii)) = featMatTotal(:, adjIndex(ii))./featMatTotal(:,6);
end

%% remove trajectories with less than 5000 frames.

% dropInds = false(size(featMatAdj, 1), 1);
% for ii = 1:size(featMatAdj, 1);
%     if featMatAdj(ii,2) <5000;
%         dropInds(ii) = true;
%     end
% end
% 
% featMatAdj(dropInds, :) = [];
% rowNames(dropInds, :) = [];
% plateNumbers(dropInds, :) = [];



%% Calculate p values for all features.

for hh = 1:size(featMatAdj, 2);
    
    medianPlateFeature = nan(15,7);
    
    for ii = 1:numel(uniqueNames);
        % For each stage...
        
        stageInds = strcmp(rowNames, uniqueNames{ii}); 
        % Find logical indices of all worm IDs in this stage.
        
        plateNumThisStage = plateNumbers(stageInds); 
        % Find all plates in this stage.
        
        uniquePlateNumThisStage = unique(plateNumThisStage); 
        % List the unique plate numbers (i.e. 1:5, 6:10 etc.)
   
        featureByStage = featMatAdj(stageInds, hh);
        medianFeatureByStage = nanmedian(featureByStage);
        % List all feature values for this stage, and median value.
        
        for jj = 1:numel(uniquePlateNumThisStage);
            % For each plate...
            
            plateInds = find(plateNumbers == uniquePlateNumThisStage(jj));
            % Get current plate indices.
            
            featureByPlate = featMatAdj(plateInds,hh);
            % List all feature values for this plate.
            
            medianPlateFeature(jj,ii) = nanmedian(featureByPlate);   
            % Copy median feature value for this plate into table.     
        end  
        
    end
    
      % Statistical tests.
    for kk = 1:numel(uniqueNames);
        % For each stage...
        
        [h,p,ci,stats] = ttest2(medianPlateFeature(:,kk), medianPlateFeature(:,7), ...
            'Vartype', 'unequal');
        % Perform unpaired ttest comparing the individual plate median
        % values for this stage with those for Old_Adults. Assume that
        % variances are unequal. Tests the null hypothesis that the two
        % data samples are from populations with equal means. Outputs: h =
        % logical 0 (null hypothesis not rejected at 5% signficance) or 1
        % (null hypothesis rejected); p = p value; ci = confidence
        % intervals for DIFFERENCE in population means; stats = struct with
        % various stats values.
        
        statsTableA(hh,kk) = p;
        % Copy the p value into statsTable row 2.
    end
end
    
%% Reduce the total feature matrix to the features of interest

indexesWanted = [6,14,22,30,44,92,194,202,376,408,668,671,679,716,717];

reducedFeatureList = featureList(indexesWanted);
reducedFeatureIndexes = struct();

for ii = 1:numel(reducedFeatureList)
    feature = reducedFeatureList{ii};
    reducedFeatureIndexes.(feature) = indexesWanted(ii);
end
    
featMatReduced = featMatAdj(:, indexesWanted);


%% Calculate and plot stage-specific features.


for hh = 1:size(featMatReduced,2);
    % baseFig = 3*(hh-1); use this if plotting multiple figures for each
    % feature.
    
    
    ylimMin = min(featMatReduced(:,hh));
    ylimMax = max(featMatReduced(:,hh));
    % For each feature, create max & min axes (used later)
    
    medianPlateFeature = nan(15,7);
    
    for ii = 1:numel(uniqueNames);
        % For each stage...
        
        stageInds = strcmp(rowNames, uniqueNames{ii}); 
        % Find logical indices of all worm IDs in this stage.
        
        plateNumThisStage = plateNumbers(stageInds); 
        % Find all plates in this stage.
        
        uniquePlateNumThisStage = unique(plateNumThisStage); 
        % List the unique plate numbers (i.e. 1:5, 6:10 etc.)
   
        featureByStage = featMatReduced(stageInds, hh);
        medianFeatureByStage = nanmedian(featureByStage);
        % List all feature values for this stage, and median value.
        
        
        for jj = 1:numel(uniquePlateNumThisStage);
            % For each plate...
            
            plateInds = find(plateNumbers == uniquePlateNumThisStage(jj));
            % Get current plate indices.
            
            featureByPlate = featMatReduced(plateInds,hh);
            % List all feature values for this plate.
            
            medianPlateFeature(jj,ii) = nanmedian(featureByPlate);   
            % Copy median feature value for this plate into table.     
        end  
        
    end
    
    % Statistical tests.
    for kk = 1:numel(uniqueNames);
        % For each stage...
        
        statsTableB(1,kk) = nanmean(medianPlateFeature(:,kk));
        % Calculate mean of the individual plate median values, and copy to
        % statsTable in row 1.
        
        [h,p,ci,stats] = ttest2(medianPlateFeature(:,kk), medianPlateFeature(:,7), ...
            'Vartype', 'unequal');
        % Perform unpaired ttest comparing the individual plate median
        % values for this stage with those for Old_Adults. Assume that
        % variances are unequal. Tests the null hypothesis that the two
        % data samples are from populations with equal means. Outputs: h =
        % logical 0 (null hypothesis not rejected at 5% signficance) or 1
        % (null hypothesis rejected); p = p value; ci = confidence
        % intervals for DIFFERENCE in population means; stats = struct with
        % various stats values.
        
        statsTableB(2,kk) = p;
        % Copy the p value into statsTable row 2.

    end
    
    % Boxplot figure, with axes labels, title, and table with mean & p-value
    figure;
    boxplot(medianPlateFeature, 'colors', 'ymcrgbk', 'labels', {'early L1' 'late L1' 'L2' 'L3' 'L4' 'Young Adult' 'Mature Adult'});
    ylabel (strrep(reducedFeatureList{hh}, '_', '\_'));
    title ([strrep(reducedFeatureList{hh}, '_', '\_') '.  Datapoints are median values for each plate (n=5 for each stage)']);
    t = uitable('Data', statsTableB, 'RowName', {'mean', 'p-value'}, 'ColumnName', {'early L1', 'late L1', 'L2', 'L3', 'L4', 'Young Adult', 'Mature Adult'}, 'Position', [20 20 500 150]);
    t.Position = [0 0 700 60];
    t.BackgroundColor = [0 1 1];
     
end

%% remove features which pertain to size and length - for running a TSNE plot.

removeIndex = [1:30];
featMatAdj(:,removeIndex) = [];
featureListAdj = featureList;
featureListAdj(:,removeIndex) = [];


%% remove NAN values from feature matrix.

% drop any features that have too many NaNs
dropInds = false(size(featMatAdj, 2), 1);
for ii = 1:size(featMatAdj, 2)
    if sum(isnan(featMatAdj(:, ii))) > 0.5*size(featMatAdj, 1)
        dropInds(ii) = true;
    end
end
featMatNANdrop = featMatAdj;
featMatNANdrop(:, dropInds) = [];
featureListAdj(dropInds) = [];

% normalise the feature matrix
totalMean = nanmean(featMatNANdrop);
totalStd = nanstd(featMatNANdrop);
featMatNorm = (featMatNANdrop - repmat(totalMean, size(featMatNANdrop, 1), 1)) ...
    ./ repmat(totalStd, size(featMatNANdrop, 1), 1);


% drop outlier trajectories.
dropInds = [];
for ii = 1:size(featMatNorm, 1)
    if any(abs(featMatNorm(ii, :)) > 10)
        dropInds = [dropInds, ii];
    end
end

featMatNorm(dropInds, :) = [];
featMatTotal(dropInds, :) = [];
rowNamesAdj = rowNames;
rowNamesAdj(dropInds) = [];
plateNumbersAdj = plateNumbers;
plateNumbersAdj(dropInds) = [];


% impute NaN values to class means
for ii = 1:numel(uniqueNames)
    % get the indices of the current stage
    currentInds = find(strcmp(rowNamesAdj, uniqueNames{ii}));
    
    % loop through all the features
    for jj = 1:size(featMatNorm, 2)
        % get the indices for the current NaN features
        nanInds = isnan(featMatNorm(currentInds, jj));
        currentMean = nanmean(featMatNorm(currentInds, jj));
        if isnan(currentMean)
            disp('Warning: all values were NaN for this class')
            currentMean = 0;
        end
        featMatNorm(currentInds(nanInds), jj) = currentMean;
    end
end

%% run TSNE

figure

no_dims = 2;
initial_dims = 25;
[~, ~, numLabels] = unique(rowNamesAdj);
ydata = tsne(featMatNorm, numLabels, no_dims, initial_dims);

% featMatAdjNorm is just a normalised feature matrix (each row is a worm, each
% column is a feature). numLabels is a numerical class label which you?ve
% probably already worked out for your data (e.g. any L1 would be 1, L2
% would be 2, etc.)
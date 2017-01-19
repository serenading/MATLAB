% plot intensity distribution to work out the threshold for cutting off
% larve data

% set directory to the relevant skeleton file
directory = '/data2/shared/data/Results/recording 44.2 green 100-250 TIFF/recording 44.2 green_X1_skeletons.hdf5';
% load intensities data
BlobFeats = h5read(directory,'/blob_features');
% plot distribution
histogram(BlobFeats.intensity_mean)
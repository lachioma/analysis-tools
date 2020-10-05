

% Set folder:
folder_root_data = 'D:\data_test\';

disp(' ')
disp('  Select data files...')

[file,path] = uigetfile([folder_root_data  '*.oebin'],...
    'Select data file...');
filename_oebin = fullfile(path, file);

% List the elements present in a Open Ephys binary format:
Lc = list_open_ephys_binary(filename_oebin, 'continuous');
Le = list_open_ephys_binary(filename_oebin, 'events');

%%

index_
% Load data recorded by Open Ephys in binary format:
D = load_open_ephys_binary(filename_oebin, 'continuous', 1);
E = load_open_ephys_binary(filename_oebin, 'events', 1);

%%

figure
plot(D.Data(1,:))
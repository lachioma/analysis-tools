

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

idx_Lc_Neuropix_AP  = find(contains(Lc,'Neuropix') & contains(Lc,'.0'));
idx_Lc_Neuropix_LFP = find(contains(Lc,'Neuropix') & contains(Lc,'.1'));
idx_Lc_NIdaq        = find(contains(Lc,'NI-DAQ'));
idx_Le_Neuropix     = find(contains(Le,'Neuropix') & contains(Le,'.0'));
idx_Le_NIdaq        = find(contains(Le,'NI-DAQ'));

disp('  Loaded!')
disp(' ')
%%
% Load data recorded by Open Ephys in binary format:
D_AP  = load_open_ephys_binary(filename_oebin, 'continuous', idx_Lc_Neuropix_AP);
D_LFP = load_open_ephys_binary(filename_oebin, 'continuous', idx_Lc_Neuropix_LFP);
D_daq = load_open_ephys_binary(filename_oebin, 'continuous', idx_Lc_NIdaq);
%
E_NP  = load_open_ephys_binary(filename_oebin, 'events', idx_Le_Neuropix);
E_daq = load_open_ephys_binary(filename_oebin, 'events', idx_Le_NIdaq);

%%

figure
plot(D_AP.Data(1,:))
hold on
zeropads = find(D_AP.Data(1,:) == 0);
plot(zeropads, zeros(length(zeropads),1),'o')


% zeropads = find(D_AP.Data(1,:) == 0);
% length(D_AP.Timestamps) + length(zeropads)
length(D_AP.Timestamps) - length(D_AP.Data)

length(D_AP.Data) - find(D_AP.Data(1,:) > 0, 1,'last')

%%

figure
plot(D_daq.Data(1,:) * D_daq.Header.channels.bit_volts)

%% Make continuous timestamp vector from digital events

[t_vec, sync] = convert_TTLevents_to_continuous(E_daq);

function D = load_open_ephys_binary(jsonFile, type, index, varargin)
%function D = load_open_ephys_binary(oebinFile, type, index)
%
%Loads data recorded by Open Ephys in Binary format
%  oebinFile: The path for the structure.oebin json file
%  type: The type of data to load. Can be 'continuous', 'events' or
%  'spikes'
%  index: The index of the recorded element as appears in the oebin file
%(See also list_open_ephys_binary to extract recorded elements and indexes)
%
%Returns a structure with the header and relevant loaded data
%
%Example:
%D=load_open_ephys_binary('recording_1/structure.oebin','spikes',2)
%
%When loading continuous data, an optional fourth argument 'mmap' can be
%used:
%D=load_open_ephys_binary('recording_1/structure.oebin','continuous',1,'mmap')
%In this case, the Data member from the returned structure contains not an
%array with the data itself but a memory-mapped object of the file, which
%can be used to access its contents. This helps loading big-sized files, as
%it does not require loading the entire file in memory.
%In this case, the data may be accessed using the field D.Data.Data(1).mapped
%For example: D.Data.Data(1).mapped(chan,startSample:endSample)
%
%
%Limitations:
%-TEXT events are not supported by the NPY reading library, so their data
%will not load, but all other fields will.
%-Some metadata structures might not be supported by the NPY reading
%library. In this case the metadata will not be loaded
%In both cases a warning message will be displayed but the program will not
%fail
%
%
%This functions requires the functions readNPY and readNPYHeader 
%from npy-matlab package from kwik-team
%(https://github.com/kwikteam/npy-matlab)
%Requires minimum MATLAB version: R2016b

if isempty(index)
    disp('index is empty, nothing to load')
    D = [];
    return
end

if (exist('readNPY.m','file') == 0)
    error('OpenEphys:loadBinary:npyLibraryNotfound','readNPY not found. Please be sure that npy-matlab is accessible');
end

if (exist('readNPYheader.m','file') == 0)
    error('OpenEphys:loadBinary:npyLibraryNotfound','readNPYheader not found. Please be sure that npy-matlab is accessible');
end
if (nargin > 3 && strcmp(varargin{1},'mmap'))
    continuousmap = true;
else
    continuousmap = false;
end


json=jsondecode(fileread(jsonFile));

%Load appropriate header data from json
switch type
    case 'continuous'
        header=json.continuous(index);
    case 'spikes'
        header=json.spikes(index);
    case 'events'
        if (iscell(json.events))
            header=json.events{index}; 
        else
            header=json.events(index);
        end
    otherwise
        error('Data type not supported');
end

%Look for folder
f=java.io.File(jsonFile);
if (~f.isAbsolute())
    f=java.io.File(fullfile(pwd,jsonFile));
end
f=java.io.File(f.getParentFile(),fullfile(type, header.folder_name));
if(~f.exists())
    error('Data folder not found');
end
folder = char(f.getCanonicalPath());
D=struct();
D.Header = header;

% Get Open Ephys version
path_split = strsplit(folder,filesep);
% settings_xml_path = fullfile(path_split{1: find(contains(path_split, 'Record Node'))}, 'settings.xml');
settings_xml_ls = dir( fullfile(path_split{1: find(contains(path_split, 'Record Node'))}, 'settings??.xml') ); % it can be settings.xml, settings_2.xml, etc.
settings_xml_path = fullfile(settings_xml_ls.folder, settings_xml_ls.name);
t = fileread(settings_xml_path);
[~,ix1] = regexp(t, '<VERSION>');
[ix2]   = regexp(t, '</VERSION>');
ver_str = t(ix1+1:ix2-1);
ver_num = str2double(ver_str(1))*1 + str2double(ver_str(3))*0.1 + str2double(ver_str(5))*0.01;


% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
% Are you performing the synchronization of Imec and NI-Daq clocks offline?
% 
% This is critical for OpenEphys GUI version >= 0.6.x. 
% 
% Open Ephys will try to sync the two clocks online, even when using
% Arduino barcodes. However, the online sync is not accurate and will
% result in wrong extraction of barcodes from the slave (NI-daq) clock and
% misalignment of TTL events (e.g. sound events). In OpenEphys GUI version
% < 0.6.x, the synced timestamps were saved on a separate
% synchronized_timestamps.npy; however, from version 0.6.x, there is no
% separate files and timestamps.npy contains the synced timestamps.
% 
% web('https://open-ephys.github.io/gui-docs/Tutorials/Data-Synchronization.html')
% 
% Sync = 'online';
Sync = 'offline';
% 
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % 

switch type
    case 'continuous'
        % timestamps.npy changed in OpenEphys GUI version 0.6.x and
        % contains actual timestamps, whereas  versions < 0.6.x contained
        % sample numbers.
        if ver_num < 0.6
            D.SampleNumbers = readNPY(fullfile(folder,'timestamps.npy'));
            D.Timestamps    = double(D.SampleNumbers) / double(header.sample_rate);
        else
            if strcmp(Sync, 'online')
                D.Timestamps    = readNPY(fullfile(folder,'timestamps.npy'));
                D.SampleNumbers = readNPY(fullfile(folder,'sample_numbers.npy'));
            else
                D.SampleNumbers = readNPY(fullfile(folder,'sample_numbers.npy'));
                D.Timestamps    = double(D.SampleNumbers) / double(header.sample_rate);
            end
                
        end
        
        contFile=fullfile(folder,'continuous.dat');
        if (continuousmap)
            file=dir(contFile);
            samples=file.bytes/2/header.num_channels;
            D.Data=memmapfile(contFile,'Format',{'int16' [header.num_channels samples] 'mapped'});
        else
            file=fopen(contFile);
            D.Data=fread(file,[header.num_channels Inf],'int16');
            fclose(file);
        end
    case 'spikes'
        D.Timestamps = readNPY(fullfile(folder,'spike_times.npy'));
        D.Waveforms = readNPY(fullfile(folder,'spike_waveforms.npy'));
        D.ElectrodeIndexes = readNPY(fullfile(folder,'spike_electrode_indices.npy'));
        D.SortedIndexes = readNPY(fullfile(folder,'spike_clusters.npy'));
    case 'events'
        % timestamps.npy changed in OpenEphys GUI version 0.6.x and
        % contains actual timestamps, whereas  versions < 0.6.x contained
        % sample numbers.
        if ver_num < 0.6
            D.SampleNumbers = readNPY(fullfile(folder,'timestamps.npy'));
            D.Timestamps    = double(D.SampleNumbers) / double(header.sample_rate);
        else
            if strcmp(Sync, 'online')
                D.Timestamps    = readNPY(fullfile(folder,'timestamps.npy'));
                D.SampleNumbers = readNPY(fullfile(folder,'sample_numbers.npy'));
            else
                D.SampleNumbers = readNPY(fullfile(folder,'sample_numbers.npy'));
                D.Timestamps    = double(D.SampleNumbers) / double(header.sample_rate);
            end
        end
        f=java.io.File(folder);
        group=char(f.getName());
        if (strncmp(group,'TEXT',4))
            %D.Data = readNPY(fullfile(folder,'text.npy'));
            warning('TEXT files not supported by npy library');
        elseif (strncmp(group,'TTL',3))
            % channel_states.npy changed name to states.npy in OpenEphys GUI version 0.6.x
            if ver_num < 0.6
                states_file = fullfile(folder,'channel_states.npy');
            else
                states_file = fullfile(folder,'states.npy'); 
            end
            assert(isfile(states_file),'Neither ''states.npy'' nor ''channel_states.npy'' was found in %s', folder)
            D.Data = readNPY(states_file);
            wordfile = fullfile(folder,'full_words.npy');
            if (isfile(wordfile))
                D.FullWords = readNPY(wordfile);
            end
        elseif (strncmp(group,'BINARY',6))
           D.Data = readNPY(fullfile(folder,'data_array.npy'));
        end
        % channels.npy is generated only by OpenEphys GUI versions < 0.6.x
        if isfile(fullfile(folder,'channels.npy'))
            D.ChannelIndex = readNPY(fullfile(folder,'channels.npy'));
        else
            D.ChannelIndex = uint16(abs(D.Data));
        end
      
end

metadatafile = fullfile(folder,'metadata.npy');
if (isfile(metadatafile))
    try
    D.MetaData = readNPY(metadatafile);
    catch EX
        fprintf('WARNING: cannot read metadata file.\nData structure might not be supported.\n\nError message: %s\nTrace:\n',EX.message);
        for i=1:length(EX.stack)
            fprintf('File: %s Function: %s Line: %d\n',EX.stack(i).file,EX.stack(i).name,EX.stack(i).line);
        end
    end
end

disp('Data loaded!')
end
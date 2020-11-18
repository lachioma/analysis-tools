function [t_vec, ttl_vec] = convert_TTLevents_to_continuous(Timestamps, Data, TimestampsUnit, SamplingRate, PlotFigure)
% [t_vec, ttl_vec] = convert_TTLevents_to_continuous(Timestamps, Data, TimestampsUnit, SamplingRate)
%
% Make continuous timestamp vector from digital events.
% INPUT
% Timestamps    vector of timestamps in samples [0 1 2...] or 
%               in seconds [0 0.001 0.002...] corresponding to digital events Data.
%               N.B. it only contains time points when the TTL signal changed.
%               Data saved by Open Ephys (NI-DAQmx plugin) are in samples.
% Data          digital events [+1 or -1], given as changes in signal value
%               from 0 to 1 or 1 to 0
% TimestampsUnit  specify unit of timestamps (samples or seconds) [seconds]
% SamplingRate    sampling rate in Hz, used only for plotting.
%
%
% Alessandro La Chioma - ale.lach@gmail.com - 2020-10-12
%  --- updated 2020-11-18

if nargin < 5 || isempty(PlotFigure)
    PlotFigure = 0; % Hz
end
if nargin < 4 || isempty(SamplingRate)
    disp('SamplingRate not given, using SamplingRate = 1 (Hz)');
    SamplingRate = 1; % Hz
end
if nargin < 3 || isempty(TimestampsUnit)
    TimestampsUnit = 'seconds';
end

if contains(TimestampsUnit, 'sec','IgnoreCase',true)
    % Convert timestamps from seconds to samples:
    Timestamps = Timestamps*SamplingRate;
end
timestamps_continuous = [Timestamps(1) : Timestamps(end)]'; % samples (divide by E.Header.sample_rate to obtain seconds)
ttl_vec = false(Timestamps(end)-Timestamps(1)+1,1);

times_ev_rising  = Timestamps((Data > 0));
times_ev_falling = Timestamps((Data < 0));

if times_ev_falling(1) < times_ev_rising(1)
    times_ev_falling(1) = [];
end
if times_ev_rising(end) > times_ev_falling(end)
    times_ev_falling(end+1) = timestamps_continuous(end);
end

% Make data vector ttl_vec for all time points:
for e = 1:length(times_ev_rising)
    ts_inds = ((timestamps_continuous > times_ev_rising(e)-1e-6) & (timestamps_continuous < times_ev_falling(e)+1e-6));
    ttl_vec(ts_inds) = true;
end

% Get time vector in seconds:
t_vec = double(timestamps_continuous-timestamps_continuous(1)) / SamplingRate;

if PlotFigure
    figure;
    area(t_vec, ttl_vec)
end
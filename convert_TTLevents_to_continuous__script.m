
%% Load event file
filename_oebin = 'D:\data_test\2020-09-12_11-24-10\experiment3\recording1\structure.oebin';

% L = list_open_ephys_binary(filename_oebin, 'continuous');
% D = load_open_ephys_binary(filename_oebin, 'continuous', 1);
E = load_open_ephys_binary(filename_oebin, 'events', 1);

%% Make continuous timestamp vector

timestamps_continuous = [E.Timestamps(1) : E.Timestamps(end)]';
sync = false(E.Timestamps(end)-E.Timestamps(1)+1,1);

times_ev_rising  = E.Timestamps((E.Data > 0));
times_ev_falling = E.Timestamps((E.Data < 0));

if times_ev_falling(1) < times_ev_rising(1)
    times_ev_falling(1) = [];
end
if times_ev_rising(end) > times_ev_falling(end)
    times_ev_falling(end+1) = timestamps_continuous(end);
end
    
for e = 1:length(times_ev_rising)
    ts_inds = ((timestamps_continuous > times_ev_rising(e)-1e-6) & (timestamps_continuous < times_ev_falling(e)+1e-6));
    sync(ts_inds) = true;
end

figure;
plot(timestamps_continuous-timestamps_continuous(1), sync)
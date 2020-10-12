function [t_vec, sync] = convert_TTLevents_to_continuous(E)
% [t_vec, sync] = convert_from_events_to_continuous(E)
%
% Make continuous timestamp vector from digital events as saved by Open
% Ephys.
%
% Alessandro La Chioma - ale.lach@gmail.com - 2020-10-12

timestamps_continuous = [E.Timestamps(1) : E.Timestamps(end)]'; % samples (divide by E.Header.sample_rate to obtain seconds)
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

t_vec = double(timestamps_continuous-timestamps_continuous(1)) / E.Header.sample_rate;

figure;
area(t_vec, sync)
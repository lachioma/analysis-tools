function [shift, scaling, t_0, delay_per_hour, BCtimes_s_aligned] = align_barcodes( ...
            BCdecVals_m, BCdecVals_s, BCtimes_m, BCtimes_s, k)
% Convert timestamps of one clock (slave) to timestamps of another (master) clock.
% BCdecVals , BCtimes  : barcode decimal values and times of the master clock
% BCdecVals2, BCtimes2 : barcode decimal values and times of the slave clock

if nargin < 5
    k = 0;
end

Lia = ismember(BCdecVals_m, BCdecVals_s);
Lia2 = ismember(BCdecVals_s, BCdecVals_m);
BCshared_first_ind   = find(Lia, 1, 'first');
BCshared_last_ind    = find(Lia, 1, 'last');
BCshared_first_ind2  = find(Lia2, 1, 'first');
BCshared_last_ind2   = find(Lia2, 1, 'last');


% barcode_start_dtimes = BCtimes2(BCshared_first_ind2:BCshared_last_ind2) - BCtimes(BCshared_first_ind:BCshared_last_ind);
% figure; histogram(barcode_start_dtimes)
% title(['mean+-std = ' num2str(mean(barcode_start_dtimes)) ' +- ' num2str(std(barcode_start_dtimes))])

% shift = mean( BCtimes_m(BCshared_first_ind:BCshared_first_ind+k) - BCtimes_s(BCshared_first_ind2:BCshared_first_ind2+k) );
shift =  BCtimes_m(BCshared_first_ind) - BCtimes_s(BCshared_first_ind2) ;

t_0 = BCtimes_m(BCshared_first_ind); % t0 of master clock

int_last_first  = BCtimes_m(BCshared_last_ind-k:BCshared_last_ind)  - BCtimes_m(BCshared_first_ind);
int_last_first2 = BCtimes_s(BCshared_last_ind2-k:BCshared_last_ind2) - BCtimes_s(BCshared_first_ind2);

scaling = nanmean( int_last_first ./ int_last_first2 );
delay_per_hour = 60*60 - 60*60 * scaling; % sec/h


% barcode_start_times2_aligned = (barcode_start_times5 - barcode_start_times5(BCshared_first_ind2) ) * scaling + shift + barcode_start_times5(BCshared_first_ind2);
% barcode_start_times2_aligned = (barcode_start_times5 + shift ) * scaling;
BCtimes_s_aligned = (BCtimes_s + shift);
% BCtimes_s_aligned = (BCtimes_s_aligned - BCtimes_s_aligned(BCshared_first_ind2)) * scaling + BCtimes_s_aligned(BCshared_first_ind2);
BCtimes_s_aligned = (BCtimes_s_aligned - t_0) * scaling + t_0;

barcode_aligned_dtimes = BCtimes_s_aligned(BCshared_first_ind2:BCshared_last_ind2) - BCtimes_m(BCshared_first_ind:BCshared_last_ind);
figure; subplot(211), histogram(barcode_aligned_dtimes); subplot(212), plot(barcode_aligned_dtimes);
title(['mean+-std = ' num2str(mean(barcode_aligned_dtimes)) ' +- ' num2str(std(barcode_aligned_dtimes))])
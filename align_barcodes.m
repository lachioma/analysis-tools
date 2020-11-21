function [BCtimes2_aligned, shift, scaling, delay_per_hour] = align_barcodes( ...
            BCdecVals, BCdecVals2, BCtimes, BCtimes2, k)
% Convert timestamps of one clock (slave) to timestamps of another (master) clock.
% BCdecVals , BCtimes  : barcode decimal values and times of the master clock
% BCdecVals2, BCtimes2 : barcode decimal values and times of the slave clock

if nargin < 5
    k = 0;
end

Lia = ismember(BCdecVals, BCdecVals2);
Lia2 = ismember(BCdecVals2, BCdecVals);
BCshared_first_ind   = find(Lia, 1, 'first');
BCshared_last_ind    = find(Lia, 1, 'last');
BCshared_first_ind2  = find(Lia2, 1, 'first');
BCshared_last_ind2   = find(Lia2, 1, 'last');


% barcode_start_dtimes = BCtimes2(BCshared_first_ind2:BCshared_last_ind2) - BCtimes(BCshared_first_ind:BCshared_last_ind);
% figure; histogram(barcode_start_dtimes)
% title(['mean+-std = ' num2str(mean(barcode_start_dtimes)) ' +- ' num2str(std(barcode_start_dtimes))])

shift = mean( BCtimes(BCshared_first_ind:BCshared_first_ind+k) - BCtimes2(BCshared_first_ind2:BCshared_first_ind2+k) );
% shift =  barcode_start_times4(BCshared_first_ind) - barcode_start_times5(BCshared_first_ind2) ;

int_last_first  = BCtimes(BCshared_last_ind-k:BCshared_last_ind)  - BCtimes(BCshared_first_ind);
int_last_first2 = BCtimes2(BCshared_last_ind2-k:BCshared_last_ind2) - BCtimes2(BCshared_first_ind2);

scaling = nanmean( int_last_first ./ int_last_first2 );
delay_per_hour = 60*60 - 60*60 * scaling; % sec/h


% barcode_start_times2_aligned = (barcode_start_times5 - barcode_start_times5(BCshared_first_ind2) ) * scaling + shift + barcode_start_times5(BCshared_first_ind2);
% barcode_start_times2_aligned = (barcode_start_times5 + shift ) * scaling;
BCtimes2_aligned = (BCtimes2 + shift);
BCtimes2_aligned = (BCtimes2_aligned - BCtimes2_aligned(BCshared_first_ind2)) * scaling + BCtimes2_aligned(BCshared_first_ind2);

barcode_aligned_dtimes = BCtimes2_aligned(BCshared_first_ind2:BCshared_last_ind2) - BCtimes(BCshared_first_ind:BCshared_last_ind);
figure; subplot(211), histogram(barcode_aligned_dtimes); subplot(212), plot(barcode_aligned_dtimes);
title(['mean+-std = ' num2str(mean(barcode_aligned_dtimes)) ' +- ' num2str(std(barcode_aligned_dtimes))])
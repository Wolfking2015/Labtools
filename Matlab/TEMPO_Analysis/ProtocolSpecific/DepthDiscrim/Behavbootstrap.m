function [avg_pct_correct, CI] = BehavBootstrap(data, Protocol, Analysis, SpikeChan, SpikeChan2, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset,  StartEventBin, StopEventBin, PATH, FILE);   

TEMPO_Defs;		
Path_Defs;
ProtocolDefs;	%needed for all protocol specific functions - contains keywords - BJP 1/4/01

symbols = {'ko', 'kx'};
lines = {'k-' 'k--'};

% create a define for the upper bound of the threshold in the fit
FIT_THRESH_UB = 100;
FIT_SLOPE_UB = 10000;

%define for number of bootraps
NUM_BOOTSTRAPS = 1000;

%get the column of values of horiz. disparities in the dots_params matrix
h_disp = data.dots_params(DOTS_HDISP,:,PATCH1);
unique_hdisp = munique(h_disp');

%get the binocular correlations
binoc_corr = data.dots_params(DOTS_BIN_CORR, :, PATCH1);
unique_bin_corr = munique(binoc_corr');

%get the patch X-center location
x_ctr = data.dots_params(DOTS_AP_XCTR, :, PATCH1);
unique_x_ctr = munique(x_ctr');

%now, select trials that fall between BegTrial and EndTrial
trials = 1:length(binoc_corr);		
% a vector of trial indices
select_trials = ( (trials >= BegTrial) & (trials <= EndTrial) );

figure;
set(gcf,'PaperPosition', [.2 .2 8 10.7], 'position', [250 50 500 573], 'Name',...
'Psychometric Function');
subplot(2, 1, 2);

trial_outcomes = logical(data.misc_params(OUTCOME, :) == CORRECT)
pct_correct = []; N_obs = []; fit_data = [];
for j = 1:length(unique_x_ctr)
    for i=1:length(unique_bin_corr)
        trials = ((binoc_corr == unique_bin_corr(i)) & (x_ctr == unique_x_ctr(j))& select_trials);
        correct_trials = (trials & (data.misc_params(OUTCOME, :) == CORRECT) );
        pct_correct{j}(i) = sum(correct_trials)/sum(trials);
        N_obs(i) = sum(trials);
        % data for Weibull fit
        fit_data(i, 1) = unique_bin_corr(i);
        fit_data(i, 2) = pct_correct{j}(i);
        fit_data(i,3) = N_obs(i);
    end
    
    hold on;
    temp_pct = pct_correct{j}';
    handl(1) = plot(unique_bin_corr, temp_pct, symbols{j});
    hold off;
    
    %get the threshold
%    [monkey_alpha(j) monkey_beta(j)]= weibull_fit(fit_data);
    [monkey_alpha(j) monkey_beta(j)]= constrained_weibull_fit(fit_data, FIT_THRESH_UB,...
    FIT_SLOPE_UB);
    
    fit_x = unique_bin_corr(1):0.1: FIT_THRESH_UB;
    monkey_fit_y = weibull_curve(fit_x, [monkey_alpha(j) monkey_beta(j)]);
    
    hold on;
    plot(fit_x, monkey_fit_y, lines{j});
    hold off;

end

xlabel('Binocular Disparity (% deg)');
ylabel('Fraction Correct');

YLim([0.4 1]);
%comment out the next 2 lines if you want the plot to be on a LINEAR X-axis
set(gca, 'XScale', 'log');
XLim([1 FIT_THRESH_UB]);

%now, print out some useful information in the upper subplot
subplot(2, 1, 1);
PrintGeneralData(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);

start_time = find(data.event_data(1, :, 1) == VSTIM_ON_CD);
stop_time = find(data.event_data(1, :, 1) == VSTIM_OFF_CD);
stim_duration = stop_time - start_time

%now, print out some specific useful info.
xpos = 0; ypos = 10;
font_size = 11;
bump_size = 8;
for j = 1:length(unique_x_ctr)
    line = sprintf('Monkey: Xctr = %6.2f threshold = %6.3f %%, slope = %6.3f', unique_x_ctr(j), monkey_alpha(j), monkey_beta(j) );
    text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
end
line = sprintf('Disparity tested: %6.3f, %6.3f deg', h_disp(1), h_disp(2) );
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;
line = sprintf('Stimulus Duration: %5d', stim_duration );
text(xpos,ypos,line,'FontSize',font_size);		ypos = ypos - bump_size;


%start bootstrap here
bootstp_num = NUM_BOOTSTRAPS;
repetition = floor(length(trial_outcomes)/length(unique_bin_corr));
for j = 1:length(unique_x_ctr)
    for b = 1 : bootstp_num
        % bootstrap dataset first
        for k = 1 : length(unique_bin_corr)
            select_boot = logical( (binoc_corr == unique_bin_corr(k)) & (x_ctr == unique_x_ctr(j)) );
            behav_select = trial_outcomes(select_boot); % behavior data
            for m = 1 : repetition
                behav_select = behav_select( randperm(length(behav_select)) ); % behavior data
                behav_bootstrap(m) = behav_select(1);
            end
            psycho_correct_boot(b,k) = sum(behav_bootstrap) / length(behav_bootstrap);
        end
        
        %find the psychophysical threshold
        bootthr(b,j) = constrained_weibull_fit([unique_bin_corr psycho_correct_boot(b,:)' repetition.*ones(length(unique_bin_corr),1)],...
        FIT_THRESH_UB, FIT_SLOPE_UB);
        b
    end
j
    %sort the boothreshold
    sorted_bootthr = sort(bootthr(:,j))
    depth_bootthr_CI_lb(j) = sorted_bootthr(floor( bootstp_num*0.05/2 ));
    depth_bootthr_CI_ub(j) = sorted_bootthr(ceil( bootstp_num*(1-0.05/2)));
end


%write out all relevant parameters to a cumulative text file, GCD 8/08/01
outfile = [BASE_PATH 'ProtocolSpecific\DepthDiscrim\Psycho_depth_thr_all_CI.dat'];

printflag = 0;
if (exist(outfile, 'file') == 0)    %file does not yet exist
    printflag = 1;
end
fid = fopen(outfile, 'a');
if (printflag)
    fprintf(fid, 'FILE\t x_ctr\t behthr\t thrCI-lb\t thrCI-ub\t');
    fprintf(fid, '\r\n');
    printflag = 0;
end
for j = 1:length(unique_x_ctr)
    buff = sprintf('%s\t %6.2f\t %6.3f\t %6.3f\t %6.3f\t ', ...
        FILE, unique_x_ctr(j), monkey_alpha(j), depth_bootthr_CI_lb(j), depth_bootthr_CI_ub(j));
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');
end
fclose(fid);

%calculate confidence interval
%avg_pct_correct = mean(mean(bootthr))
%s = avg_pct_correct * (1-avg_pct_correct);
%t = tinv(0.05/2, length(bootthr));
%CI = s*t/sqrt(length(bootthr)-1)
%CI_lb = avg_pct_correct + CI
%CI_ub = avg_pct_correct - CI

%     % calculate ROC
%     fit_data_neuro_boot = [];
%     for k = 1 : length(unique_stim_type)
%         if i < (1+length(unique_heading))/2
%             Neuro_correct_boot{k}(i) =  rocN( resp_heading_boot{k}(i,:),resp_heading_boot{k}((1+length(unique_heading))/2,:),100 ); % compare to the 0 heading condition, which is straght ahead
%             Neuro_correct_boot{k}(i) = 1 - Neuro_correct_boot{k}(i); % turn proportion correct into rightward choice
%         else
%             Neuro_correct_boot{k}(i) =  rocN( resp_heading_boot{k}((1+length(unique_heading))/2,:), resp_heading_boot{k}(i+1,:),100 ); % compare to the 0 heading condition, which is straght ahead
%         end
%         if  resp_mat{k}(1) < resp_mat{k}(end)
%             % we don't know whether left heading is for sure smaller than right heading,thus ROC curve might be flipped above or below the unity line
%             % here we asume if left response larger than right response then asign the left to be preferred direction
%             Neuro_correct_boot{k}(i) = 1 - Neuro_correct_boot{k}(i);
%         end
%     end
%     % fit gaussian
%     for k = 1 : length(unique_stim_type)
%         neu_heading = unique_heading(unique_heading~=0);
%         beta = [0, 1.0];
%         [betafit_ne_boot{k},resids_ne_boot{k},J_ne_boot{k}] = nlinfit(neu_heading, Neuro_correct_boot{k}(:), 'cum_gaussfit', beta);  % fit data with least square
%         neu_thresh_boot(k,b) = betafit_ne_boot{k}(2);
%         [betafit_psy_boot{k},resids_psy_boot{k},J_psy_boot{k}] = nlinfit(unique_heading, psycho_correct_boot(k,:), 'cum_gaussfit', beta);  % fit data with least square
%         psy_thresh_boot(k,b) = betafit_psy_boot{k}(2);
%     end
% end
% % test confidence field
% bin_num = 100; % temporally set 100 bins
% for k = 1 : length(unique_stim_type)
%     hist_ne_boot(k,:) = hist( neu_thresh_boot(k,:), bin_num );  % for bootstrap
%     bin_ne_sum = 0;
%     n_ne = 0;
%     while ( bin_ne_sum < 0.05*sum( hist_ne_boot(k,:)) )   % define confidential value to be 0.05
%           n_ne = n_ne+1;
%           bin_ne_sum = bin_ne_sum + hist_ne_boot(k, n_ne) + hist_ne_boot(k, bin_num-n_ne+1);
%           neu_boot(k) = betafit_ne{k}(2) - min(neu_thresh_boot(k,:)) - n_ne * ( (max(neu_thresh_boot(k,:))-min(neu_thresh_boot(k,:))) / bin_num) ;    % calculate what value is thought to be significant different
%     end
%     hist_psy_boot(k,:) = hist( psy_thresh_boot(k,:), bin_num );  % psycho data
%     bin_psy_sum = 0;
%     n_psy = 0;
%     while ( bin_psy_sum < 0.05*sum( hist_psy_boot(k,:)) )   % define confidential value to be 0.05
%           n_psy = n_psy + 1;
%           bin_psy_sum = bin_psy_sum + hist_psy_boot(k, n_psy) + hist_psy_boot(k,bin_num-n_psy+1);
%           psy_boot(k) = betafit{k}(2) - min(psy_thresh_boot(k,:)) - n_psy * ( (max(psy_thresh_boot(k,:))-min(psy_thresh_boot(k,:))) / bin_num);
%     end
% end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
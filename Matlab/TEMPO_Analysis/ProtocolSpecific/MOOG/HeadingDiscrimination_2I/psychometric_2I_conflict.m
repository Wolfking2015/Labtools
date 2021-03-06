%-----------------------------------------------------------------------------------------------------------------------
%-- PSYCHOMETRIC_2I_conflict.m -- Plots psychometric function for 2-interval heading discrimination expt
%-- CRF, 2/21/06
%-- Adapted for cue-conflict blocks, 8/18/06
%-----------------------------------------------------------------------------------------------------------------------

function Psychometric_2I_conflict(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);

printfigs = 0;
closefigs = 0;
kurt = 0;
e_cell = 0;
plot_timecourse = 0;

TEMPO_Defs;
Path_Defs;
ProtocolDefs; %contains protocol specific keywords - 1/4/01 BJP

%get the column of values for azimuth and elevation and stim_type
temp_azimuth = data.moog_params(AZIMUTH,:,MOOG);
temp_elevation = data.moog_params(ELEVATION,:,MOOG);
temp_stim_type = data.moog_params(STIM_TYPE,:,MOOG);
temp_heading   = data.moog_params(HEADING,:,MOOG);
% temp_amplitude = data.moog_params(AMPLITUDE,:,MOOG);
temp_amplitude = data.moog_params(AMPLITUDE,:,CAMERAS);    % changed to cameras amplitude, to reflect actual AND simulated motion  -CRF 4/2007
temp_num_sigmas = data.moog_params(NUM_SIGMAS,:,MOOG);
temp_motion_coherence = data.moog_params(COHERENCE,:,MOOG);
temp_conflict_angle = data.moog_params(CONFLICT_ANGLE,:,MOOG);
temp_swap_flag = data.moog_params(SWAP_FLAG,:,MOOG);
temp_reward_flag = data.moog_params(REWARD_FLAG,:,MOOG);

%spike and event data
temp_spike_rates = data.spike_rates(SpikeChan,:); 
temp_spike_data = data.spike_data(SpikeChan,:);   % spike rasters
temp_event_data = squeeze(data.event_data);
temp_outcome = data.misc_params(OUTCOME,:);

trials = 1:length(temp_azimuth);		% a vector of trial indices
select_trials = (trials >= BegTrial) & (trials <= EndTrial);

%use the target luminance multiplier values to exclude 1-target trials
two_targs = data.targ_params(TARG_LUM_MULT,:,2) & data.targ_params(TARG_LUM_MULT,:,3);
select_trials = select_trials & two_targs;

azimuth = temp_azimuth(select_trials);
elevation = temp_elevation(select_trials);
stim_type = temp_stim_type(select_trials);
heading = temp_heading(select_trials);
amplitude= temp_amplitude(select_trials);
num_sigmas= temp_num_sigmas(select_trials);
motion_coherence = temp_motion_coherence(select_trials);
conflict_angle = temp_conflict_angle(select_trials);
outcome = temp_outcome(select_trials);
swap_flag = temp_swap_flag(select_trials);
reward_flag = temp_reward_flag(select_trials);
spike_rates = temp_spike_rates(select_trials);

unique_azimuth = munique(azimuth');
unique_elevation = munique(elevation');
unique_stim_type = munique(stim_type');
unique_heading = munique(heading');
unique_amplitude = munique(amplitude');
unique_num_sigmas = munique(num_sigmas');
unique_motion_coherence = munique(motion_coherence');
unique_conflict_angle = munique(conflict_angle');


if plot_timecourse
%---------------------------------------------------------------
% cumulative spike histogram with events superimposed
%---------------------------------------------------------------
sum_hist = zeros(1,5000);
for q = BegTrial:EndTrial
    sum_hist = sum_hist + temp_spike_data(q*5000-4999 : q*5000);
end

% figure;
% events_y = temp_event_data(:,1)*max(sum_hist)/(max(temp_event_data(:,1))+1);
% bar(sum_hist(1:4000)); hold on; plot(events_y,'rx');
% event_times = find(temp_event_data(:,1)>0); events_y_lim = ylim;
% for p = 1:length(event_times)
%     text(event_times(p), events_y(event_times(p)), num2str(temp_event_data(event_times(p),1)), 'Color', [1 0 0]);
% end

%---------------------------------------------------------------
% eye data
%---------------------------------------------------------------
for i = 1:EndTrial-BegTrial+1
    e1(i,:) = data.eye_data(1,:,BegTrial+i-1);
    e2(i,:) = data.eye_data(2,:,BegTrial+i-1);
end
% eye_x = mean(e1); eyeoffset_x = mean(eye_x(150:220)); eye_x = eye_x - eyeoffset_x;
% eye_y = mean(e2); eyeoffset_y = mean(eye_y(150:220)); eye_y = eye_y - eyeoffset_y;
eye_x = e1(1,:);  % TRIAL #1 (actually BegTrial) for now
eye_y = e2(1,:);

% figure;
% plot(eye_x); hold on; plot(eye_y,'r');


%---------------------------------------------------------------
% accelerometer data
%---------------------------------------------------------------
clear a5 a6
for i = 1:EndTrial-BegTrial+1
    a5(i,:) = data.eye_data(5,:,BegTrial+i-1);
    a6(i,:) = data.eye_data(6,:,BegTrial+i-1);
end
accel_FA = mean(a5); offset_FA = mean(accel_FA(150:220)); accel_FA = accel_FA - offset_FA;
accel_LR = mean(a6); offset_LR = mean(accel_LR(150:220)); accel_LR = accel_LR - offset_LR;

% convert from deg to volts to G, i.e., 100 deg = 20 v, 1.0 v = 1G, so 5 deg = 1G
%
%                               (need to calibrate first)
%
vel_LR = cumsum(accel_LR);
vel_FA = cumsum(accel_FA);

% figure;
% plot(accel_LR(1:650)); hold on; plot(accel_FA(1:650),'r');
% title('acceleration trace');
% figure; plot(vel_LR(1:650)); hold on; plot(vel_FA(1:650),'r');
% title('velocity trace');
% ---------------------------------------------------------------

% plot all of above
event_times = find(temp_event_data(:,BegTrial)>0);
% for e = 1:length(temp_event_data(1,:))
%     event_times(:,e) = find(temp_event_data(:,e)>0);
% end
event_codes = temp_event_data(event_times,BegTrial);
% event_codes(event_codes==2 | event_codes==12) = [];

figure; subplot(3,1,1);
bar(sum_hist); xlim([0 4000]);
if max(sum_hist) > 10
    ylim([0 10*round(1.25*max(sum_hist)/10)]);
end
events_ylim(1:length(event_codes)) = 10*round(1.25*max(sum_hist)/10); events_ylim = events_ylim';
hold on; plot([event_times event_times], [0 events_ylim(1)], 'r--');
for p = 2:length(event_times)
    if event_times(p) - event_times(p-1) < 25        
        events_ylim(p) = 0.92*events_ylim(p);
    end
end
text(event_times, 0.96*events_ylim, num2str(event_codes), 'Color', [1 0 0]);
events_txt(1,:) = ['1 = trial start  2 = fixation point on  3 = enter fix window  4 = stim on  5 = stim off      '];
events_txt(2,:) = ['6 = targets on  7 = exit fix window  8 = enter T1 window  9 = enter T2 window  10 = broke fix'];
events_txt(3,:) = ['11 = broke verg  12 = trial success  13 = reward delivered  15 = trial end                   '];
text(0,1.15*events_ylim(1),events_txt);

subplot(3,1,2);
plot(eye_x); hold on; plot(eye_y,'r'); xlim([0 800]);
temp_ylim = ylim; eye_ylim(1:length(event_codes)) = temp_ylim(2); eye_ylim = eye_ylim';
hold on; plot([event_times/5 event_times/5], [temp_ylim(1) eye_ylim(1)], 'r--');
for p = 2:length(event_times)
    if event_times(p) - event_times(p-1) < 25        
        eye_ylim(p) = 0.92*eye_ylim(p);
    end
end
text(event_times/5, 0.96*eye_ylim, num2str(event_codes), 'Color', [1 0 0]);

subplot(3,1,3);
plot(vel_FA(1:650)); hold on; plot(vel_LR(1:650),'k'); xlim([0 800]);
temp_ylim = ylim; acc_ylim(1:length(event_codes)) = temp_ylim(2); acc_ylim = acc_ylim';
hold on; plot([event_times/5 event_times/5], [temp_ylim(1) acc_ylim(1)], 'r--');
for p = 2:length(event_times)
    if event_times(p) - event_times(p-1) < 25
        acc_ylim(p) = 0.88*acc_ylim(p);
    end
end
text(event_times/5, 0.93*acc_ylim, num2str(event_codes), 'Color', [1 0 0]);

if printfigs
    print;
end
if closefigs;
    close;
end

%---------------------------------------------------------------
end %if plot_timecourse
%---------------------------------------------------------------

% based on vel traces above, set time windows for 1st and 2nd intervals (hard-coded for now)
time_window_1st = 1126:2250;
time_window_2nd = 2126:3250;
% then compute firing rate for each interval on each trial
for q = 1:length(azimuth)
    firing_rate_1st(q) = sum(temp_spike_data(q*5000-5000+time_window_1st(1) : q*5000-5000+time_window_1st(end))) / (length(time_window_1st)/1000);
    firing_rate_2nd(q) = sum(temp_spike_data(q*5000-5000+time_window_2nd(1) : q*5000-5000+time_window_2nd(end))) / (length(time_window_2nd)/1000);
    if swap_flag(q)
        firing_rate_ref(q) = firing_rate_2nd(q);  % reference heading
        firing_rate_comp(q) = firing_rate_1st(q); % comparison heading
    else
        firing_rate_ref(q) = firing_rate_1st(q);
        firing_rate_comp(q) = firing_rate_2nd(q);
    end
end


% ****************************************************************************************
% Enter parameters that vary for a given block
condition = conflict_angle;
con_txt = 'delta';
unique_condition = munique(condition');

condition_2 = motion_coherence;
con_txt_2 = 'coherence';
unique_condition_2 = munique(condition_2');
% ****************************************************************************************

if length(unique_stim_type) == 1
    one_repetition = length(unique_condition)*length(unique_condition_2)*length(unique_heading);
else % for all three conditions interleaved
    one_repetition = length(unique_condition)*length(unique_condition_2)*length(unique_heading) + ...  % combined
                     length(unique_condition_2)*length(unique_heading) + ...  % visual
                     length(unique_heading);  % vestibular
end
num_reps = floor( length(heading)/one_repetition ); % number of repetitions

if num_reps*one_repetition ~= length(azimuth)
    disp('********* WARNING: Extra trials included');
    disp(['********* Current EndTrial = ' num2str(EndTrial)]);
    disp(['********* But should be: ' num2str(num_reps*one_repetition)]);
    yesno = input('********* Continue? [enter = yes, 0 = no]');
    if ~isempty(yesno)
        return
    end
end

%determine for each trial whether monkey chooses leftward(target1) or rightward(target2)    
LEFT = 1;
RIGHT = 2;
choice = []; choice_true = [];
for n = 1 : length(azimuth)
    events = temp_event_data(:,n);
    events = events(events>0);  % all non-zero entries
    if swap_flag(n) % must reverse targets for swapped-interval trials (but retain actual choices in 'choice_true')  
        if (sum(events == IN_T2_WIN_CD) > 0)
            choice(n) = RIGHT;
            choice_true(n) = LEFT;
        elseif (sum(events == IN_T1_WIN_CD) > 0)
            choice(n) = LEFT;
            choice_true(n) = RIGHT;
        else
            disp('Neither T1 or T2 chosen.  This should not happen!  File must be bogus.');
            return;
        end
    else
        if (sum(events == IN_T1_WIN_CD) > 0)
            choice(n) = RIGHT;
            choice_true(n) = RIGHT;
        elseif (sum(events == IN_T2_WIN_CD) > 0)
            choice(n) = LEFT;
            choice_true(n) = LEFT;
        else
            disp('Neither T1 or T2 chosen.  This should not happen!  File must be bogus.');
            return;
        end
    end
end
choice = choice(select_trials);
choice_true = choice_true(select_trials);

% To match reward probability in ambiguous cue-conflict trials, compute
% percent correct on corresponding cues-consistent trials (when heading < 1/2 delta)
unambig_trials = (stim_type == 3) & (conflict_angle == 0) & (abs(heading) < abs(max(conflict_angle))/2);
% unambig_correct = (choice(unambig_trials) == RIGHT & heading(unambig_trials) > 0) | (choice(unambig_trials) == LEFT & heading(unambig_trials) < 0);
unambig_correct = outcome(unambig_trials)==0;
pct_correct_unambig = sum(unambig_correct) / length(unambig_correct)

% This will perform the entire analysis separately for normal and reversed-interval trials (t=0 and 1),
% as well as all trials pooled together (t=2)
norm_rev{1} = 'Normal'; norm_rev{2} = 'Reversed'; norm_rev{3} = 'AllTrials';

if swap_flag == 0
    repeat_analysis = 0;
    printflag = [printfigs 0 0];
elseif swap_flag == 1
    repeat_analysis = 1;
    printflag = [0 printfigs 0];
else
    repeat_analysis = 0:2;
    printflag = [printfigs printfigs printfigs];
end

% heading_true is the actual heading of the 2nd interval relative to the 1st, regardless of swap_flag
heading_true = heading;
heading_true(swap_flag == 1) = -heading_true(swap_flag == 1);

% for t = repeat_analysis
t = 2;

right_pct = []; right_pct_true = []; correct_pct = [];
for s = 1:length(unique_stim_type)
	for j = 1:length(unique_condition)  % <-- currently conflict_angle
        for k = 1:length(unique_condition_2)  % <-- currently coherence
            resp_all_headings = [];  % *see below
            for i = 1:length(unique_heading)
                if t == 2 % All Trials
                    trials_select = logical( (stim_type == unique_stim_type(s)) & (heading == unique_heading(i)) & (condition == unique_condition(j)) & (condition_2 == unique_condition_2(k)) );
                    trials_select_true = logical( (stim_type == unique_stim_type(s)) & (heading_true == unique_heading(i)) & (condition == unique_condition(j)) & (condition_2 == unique_condition_2(k)) );
                else % only Normal or Reversed trials
                    trials_select = logical( (swap_flag == t) & (stim_type == unique_stim_type(s)) & (heading == unique_heading(i)) & (condition == unique_condition(j)) & (condition_2 == unique_condition_2(k)) ) ;
                    trials_select_true = logical( (swap_flag == t) & (stim_type == unique_stim_type(s)) & (heading_true == unique_heading(i)) & (condition == unique_condition(j)) & (condition_2 == unique_condition_2(k)) ) ;
                end
                if sum(trials_select) == 0
                    right_pct{s,j,k}(i) = NaN;
                    right_pct_true{s,j,k}(i) = NaN;
                    correct_pct{s,j,k}(i) = NaN;
                    resp_mean_ref{s,j,k}(i) = NaN;
                    resp_mean_comp{s,j,k}(i) = NaN;
                    resp_std_ref{s,j,k}(i) = NaN;
                    resp_std_comp{s,j,k}(i) = NaN;
                else
                    right_trials = (trials_select & (choice == RIGHT) );
                    right_trials_true = (trials_select_true & (choice_true == RIGHT) );
                    right_pct{s,j,k}(i) = 1*sum(right_trials) / sum(trials_select);
                    right_pct_true{s,j,k}(i) = 1*sum(right_trials_true) / sum(trials_select_true);
                    if unique_heading(i) > 0
                        correct_pct{s,j,k}(i) = right_pct{s,j,k}(i);
                    else
                        correct_pct{s,j,k}(i) = 1 - right_pct{s,j,k}(i);
                    end
                    resp_mean_ref{s,j,k}(i) = mean(firing_rate_ref(trials_select));   % reference heading*
                    resp_mean_comp{s,j,k}(i) = mean(firing_rate_comp(trials_select)); % comparison heading
                    resp_std_ref{s,j,k}(i) = std(firing_rate_ref(trials_select));
                    resp_std_comp{s,j,k}(i) = std(firing_rate_comp(trials_select));
                    % *but since reference stimulus doesn't vary with heading, collapse across headings:
                    if t == 2 & sum(trials_select) ~= num_reps
                        disp('SOMETHING WRONG: see line 333');  % just a test to see if change below is correct (sum(trials_select) in place of num_reps) -- delete after a while if it works
                    end
                    if i == 1
                        resp_all_headings(1:sum(trials_select)) = firing_rate_ref(trials_select);
                    else
                        resp_all_headings(end+1:end+sum(trials_select)) = firing_rate_ref(trials_select);
                    end
                end
                fit_data_psycho_cum{s,j,k}(i,1) = unique_heading(i);
                fit_data_psycho_cum{s,j,k}(i,2) = right_pct{s,j,k}(i);
                fit_data_psycho_cum{s,j,k}(i,3) = sum(trials_select);
                fit_data_psycho_true{s,j,k}(i,1) = unique_heading(i);
                fit_data_psycho_true{s,j,k}(i,2) = right_pct_true{s,j,k}(i);
                fit_data_psycho_true{s,j,k}(i,3) = sum(trials_select_true);
            end
            % *continued
            if sum(trials_select) == 0
                ref_grand_mean{s,j,k} = NaN;
                ref_grand_std{s,j,k} = NaN;
            else
                ref_grand_mean{s,j,k} = mean(resp_all_headings);
                ref_grand_std{s,j,k} = std(resp_all_headings);
            end
        end
	end
end


% % % % % %NEW! Save choice data so it can be pooled into a single psychometric for
% % % % % %each monkey/coherence/conflict/stimtype (temporarily comment rest of script)
% % % % % save(['C:\Program Files\MATLAB\R2007a\work\monkey data\' FILE '.mat'], 'fit_data_psycho_cum', 'unique_condition', 'unique_condition_2');
% % % % % return





if kurt
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% TEMPORARY: Kurt's idea, plot what the monkey actually does (true right choices, comparing 2nd interval vs. 1st interval regardless of swap_flag)
	for s = 1:length(unique_stim_type)
        for j = 1:length(unique_condition)
            for k = 1:length(unique_condition_2)
                if fit_data_psycho_true{s,j,k}(1,3) == 0 % identifies and skips invalid condition combinations (e.g., vestibular only with a nonzero conflict angle)
                    Thresh_psy{s,j,k} = NaN;
                    Bias_psy{s,j,k} = NaN;
                    psy_perf{s,j,k} = [NaN , NaN];
                else
                    wichman_psy = pfit(fit_data_psycho_true{s,j,k},'plot_opt','no plot','shape','cumulative gaussian','n_intervals',1,'sens',0,'compute_stats','true','verbose','false');  
                    Thresh_psy{s,j,k} = wichman_psy.params.est(2);
                    Bias_psy{s,j,k} = wichman_psy.params.est(1);
                    psy_perf{s,j,k} = [wichman_psy.params.est(1),wichman_psy.params.est(2)];
                    Thresh_conf{s,j,k} = [wichman_psy.params.lims(1,2),wichman_psy.params.lims(4,2)];
                    Bias_conf{s,j,k} = [wichman_psy.params.lims(1,1),wichman_psy.params.lims(4,1)];
                end
            end
        end
	end
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

else

	%%%%%% use Wichman's MLE method to estimate threshold and bias
	for s = 1:length(unique_stim_type)
        for j = 1:length(unique_condition)
            for k = 1:length(unique_condition_2)
                if fit_data_psycho_cum{s,j,k}(1,3) == 0 % identifies and skips invalid condition combinations (e.g., vestibular only with a nonzero conflict angle)
                    Thresh_psy{s,j,k} = NaN;
                    Bias_psy{s,j,k} = NaN;
                    psy_perf{s,j,k} = [NaN , NaN];
                else
                    fit_data_psycho_cum{s,j,k}(isnan(fit_data_psycho_cum{s,j,k})) = 0;      % some protections against rare
                    fit_data_psycho_cum{s,j,k}((fit_data_psycho_cum{s,j,k}(:,3)==0),:) = 1; % cases of 0's and NaN's

                    wichman_psy = pfit(fit_data_psycho_cum{s,j,k},'plot_opt','no plot','shape','cumulative gaussian','n_intervals',1,'sens',0,'compute_stats','true','verbose','false');  
                    Thresh_psy{s,j,k} = wichman_psy.params.est(2);
                    Bias_psy{s,j,k} = wichman_psy.params.est(1);
                    psy_perf{s,j,k} = [wichman_psy.params.est(1),wichman_psy.params.est(2)];
                    Thresh_conf{s,j,k} = [wichman_psy.params.lims(1,2),wichman_psy.params.lims(4,2)];
                    Bias_conf{s,j,k} = [wichman_psy.params.lims(1,1),wichman_psy.params.lims(4,1)];
                end
            end
        end
	end
    
end

%--------------------------------------------------------------------------
% compute the predicted and actual weights/thresholds
for k = 1:length(unique_condition_2)
    Wves_actual_minus(k) = 1 - ((Bias_psy{3,1,k} - Bias_psy{3,2,k}) - (-unique_condition(1)/2)) / unique_condition(1);
    Wves_actual_plus(k) = 1 - ((Bias_psy{3,3,k} - Bias_psy{3,2,k}) - (-unique_condition(3)/2)) / unique_condition(3);
	Wves_actual(k) = (Wves_actual_minus(k) + Wves_actual_plus(k)) / 2;
	Wves_predicted(k) = Thresh_psy{2,2,k}^2/(Thresh_psy{1,2,1}^2+Thresh_psy{2,2,k}^2);
	thresh_predicted(k) = sqrt((Thresh_psy{2,2,k}^2*Thresh_psy{1,2,1}^2)/(Thresh_psy{2,2,k}^2+Thresh_psy{1,2,1}^2));
	thresh_actual_d0(k) = Thresh_psy{3,2,k};
	thresh_actual_all(k) = (Thresh_psy{3,1,k}+Thresh_psy{3,2,k}+Thresh_psy{3,3,k}) / 3;
	thresh_actual_pm(k) = (Thresh_psy{3,1,k}+Thresh_psy{3,3,k}) / 2;
	bias_delta0(k) = Bias_psy{3,2,k};
end

%--------------------------------------------------------------------------
% plot psychometric function here
h{1,1} = 'bo'; h{2,1} = 'b^'; h{3,1} = 'bs'; f{1} = 'b-';
h{1,2} = 'go'; h{2,2} = 'g^'; h{3,2} = 'gs'; f{2} = 'g-';
h{1,3} = 'ro'; h{2,3} = 'r^'; h{3,3} = 'rs'; f{3} = 'r-';
h{1,4} = 'co'; h{2,4} = 'c^'; h{3,4} = 'cs'; f{4} = 'c-';
h{1,5} = 'mo'; h{2,5} = 'm^'; h{3,5} = 'ms'; f{5} = 'm-';
h{1,6} = 'yo'; h{2,6} = 'y^'; h{3,6} = 'ys'; f{6} = 'y-';
h{1,7} = 'ko'; h{2,7} = 'k^'; h{3,7} = 'ks'; f{7} = 'k-';

if kurt
    right_pct = right_pct_true;
end

if (unique_stim_type == 3)  % for comb/conflict blocks, plot a separate figure for each value of coherence
    
    s = 1;
	for k = 1:length(unique_condition_2)
	    figure(k+1+10*t);
		set(k+1+10*t,'Position', [200*k,25 700,900], 'Name', 'Heading Discrimination-2I');
		axes('position',[0.2,0.25, 0.6,0.5] );
		% fit data with cumulative gaussian and plot both raw data and fitted curve
		legend_txt = [];
		
		% xi = min(unique_heading) : 0.1 : max(unique_heading);
		% instead, force x range to be symmetric about zero (for staircase)
		xi = -max(abs(unique_heading)) : 0.1 : max(abs(unique_heading));
		
		for j = 1:length(unique_condition)    % <-- currently conflict_angle
            figure(k+1+10*t);
            plot(unique_heading, right_pct{s,j,k}(:), h{k,j}, xi, cum_gaussfit(psy_perf{s,j,k}, xi),  f{j} );
            xlabel('Heading Angle');
            ylim([0,1]);
            ylabel('Percent Rightward Choices');
            hold on;
            legend_txt{j*2-1} = [num2str(unique_condition(j))];
            legend_txt{j*2} = [''];
        end
		
		% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% output some text of basic parameters in the figure
		axes('position',[0.2,0.8, 0.6,0.15] );
		xlim( [0,50] );
		ylim( [2,10] );
        text(0, 11, norm_rev{t+1});
		text(0, 10, FILE);
        text(15,11, ['amplitude = ' num2str(unique_amplitude)]);
		text(15,10, ['stimtype = ' num2str(unique_stim_type)]);
		text(30,10, ['azimuth = ' num2str(mean(unique_azimuth))]); % mean because actual 'azimuth' varies with conflict angle
		text(45,10, ['repeats = ' num2str(num_reps)]);
		text(0,8.3, con_txt);
		text(10,8.3, con_txt_2);
		text(20,8.3, 'bias');
		text(30,8.3, 'thresh');
		text(40,8.3, '%correct');
        text(0, 11, norm_rev{t+1});

        for j = 1:length(unique_condition)    % <-- currently conflict_angle
            text(0,8-j, num2str(unique_condition(j)));
            text(10,8-j,num2str(unique_condition_2(k)));
            text(20,8-j,num2str(Bias_psy{s,j,k}) );
            text(30,8-j,num2str(Thresh_psy{s,j,k}) );
            text(40,8-j,num2str(mean(correct_pct{s,j,k})) );
        end
	
        axis off;
        if printflag(t+1)
            print;
        end
        if closefigs
            close;
        end
    end

elseif (unique_stim_type == 1) | (unique_stim_type == 2)  % for visual only, put both coherences on the same figure
    
 	figure(2+10*t);
	set(2+10*t,'Position', [200,50 700,600], 'Name', 'Heading Discrimination-2I');
	axes('position',[0.2,0.25, 0.6,0.5] );
	% fit data with cumulative gaussian and plot both raw data and fitted curve
	legend_txt = [];
	
	% xi = min(unique_heading) : 0.1 : max(unique_heading);
	% instead, force x range to be symmetric about zero (for staircase)
	xi = -max(abs(unique_heading)) : 0.1 : max(abs(unique_heading));
	
    s = 1;
	for j = 1:length(unique_condition)    % <-- currently conflict_angle
        for k = 1:length(unique_condition_2)  % <-- currently coherence
            figure(2+10*t);
            plot(unique_heading, right_pct{s,j,k}(:), h{k,j},  xi, cum_gaussfit(psy_perf{s,j,k}, xi),  f{j} );
            xlabel('Heading Angle');   
            ylim([0,1]);
            ylabel('Percent Rightward Choices');
            hold on;
            legend_txt{j*2-1} = [num2str(unique_condition(j))];
            legend_txt{j*2} = [''];
        end
	end
	
	% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% output some text of basic parameters in the figure
	axes('position',[0.2,0.8, 0.6,0.15] );
	xlim( [0,50] );
	ylim( [2,10] );
    text(0, 11, norm_rev{t+1});
	text(0, 10, FILE);
    text(15,11, ['amplitude = ' num2str(unique_amplitude)]);
	text(15,10, ['stimtype = ' num2str(unique_stim_type)]);
	text(30,10, ['azimuth = ' num2str(mean(unique_azimuth))]); % mean, because actual 'AZIMUTH' varies with conflict angle
	text(45,10, ['repeats = ' num2str(num_reps)]);
	text(0,8.3, con_txt);
	text(10,8.3, con_txt_2);
	text(20,8.3, 'bias');
	text(30,8.3, 'thresh');
	text(40,8.3, '%correct');
	
    for j = 1:length(unique_condition)    % <-- currently conflict angle
        for k = 1:length(unique_condition_2)    % <-- currently coherence
            text(0,7-j*k, num2str(unique_condition(j)));
            text(10,7-j*k,num2str(unique_condition_2(k)));
            text(20,7-j*k,num2str(Bias_psy{s,j,k}) );
            text(30,7-j*k,num2str(Thresh_psy{s,j,k}) );
            text(40,7-j*k,num2str(mean(correct_pct{s,j,k})) );
        end
	end
	   
	axis off;
    if printflag(t+1)
        print;
    end
    if closefigs
        close;
    end

else % if all three conditions interleaved, plot on two figs for combined, one for vis and ves
    
    %first the single-cues
    for s = 1:2
        figure(2+1+10*t);
    	set(2+1+10*t,'Position', [200,50 700,600], 'Name', 'Heading Discrimination-2I');
    	if s == 1
            axes('position',[0.2,0.25, 0.6,0.5] );
        end
    	% fit data with cumulative gaussian and plot both raw data and fitted curve
    	legend_txt = [];
	
		% xi = min(unique_heading) : 0.1 : max(unique_heading);
		% instead, force x range to be symmetric about zero (for staircase)
		xi = -max(abs(unique_heading)) : 0.1 : max(abs(unique_heading));
        
        for j = 1:length(unique_condition)    % <-- currently conflict_angle
            for k = 1:length(unique_condition_2)  % <-- currently coherence
                figure(2+1+10*t);
                plot(unique_heading, right_pct{s,j,k}(:), h{k,s}, xi, cum_gaussfit(psy_perf{s,j,k}, xi), f{s});
                xlabel('Heading Angle');   
                ylim([0,1]);
                ylabel('Percent Rightward Choices');
                hold on;
                legend_txt{j*2-1} = [num2str(unique_condition(j))];
                legend_txt{j*2} = [''];
            end
		end
    end
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% output some text of basic parameters in the figure
	axes('position',[0.2,0.8, 0.6,0.15] );
	xlim( [0,50] );
	ylim( [2,10] );
    text(0, 11, norm_rev{t+1});
	text(0, 10, FILE);
    text(15,11, ['amplitude = ' num2str(unique_amplitude)]);
	text(15,10, ['stimtype = 1+2']);
	text(30,10, ['azimuth = ' num2str(mean(unique_azimuth))]); % mean, because actual 'AZIMUTH' varies with conflict angle
	text(45,10, ['repeats = ' num2str(num_reps)]);
	text(0,8.3, 'stimtype');
	text(10,8.3, con_txt_2);
	text(20,8.3, 'bias');
	text(30,8.3, 'thresh');
	text(40,8.3, '%correct');
    text(50,8.3, 'Wves-pred');
    for s = 1:2
		if s == 1
            text(0, 6, num2str(s));     
            text(10,6,['N/A']);
            text(20,6, num2str(Bias_psy{s,2,1}) );
            text(30,6, num2str(Thresh_psy{s,2,1}) );
            text(40,6, num2str(mean(correct_pct{s,2,1})) );
        else
            for k = 1:length(unique_condition_2)  % <-- currently coherence
                text(0, -1.5*k+5.5, num2str(s));
                text(10,-1.5*k+5.5, num2str(unique_condition_2(k)));
                text(20,-1.5*k+5.5, num2str(Bias_psy{s,2,k}) );
                text(30,-1.5*k+5.5, num2str(Thresh_psy{s,2,k}) );
                text(40,-1.5*k+5.5, num2str(mean(correct_pct{s,2,k})) );
                text(50,-1.5*k+5.5, num2str(Wves_predicted(k)) );
            end
        end
    end % end single cues

    axis off;
    if printflag(t+1)
        print;
    end
    if closefigs
        close;
    end
    
    % lastly, the combined
    s = 3;
    for k = 1:length(unique_condition_2)
        figure(s+k+10*t);
    	set(s+k+10*t,'Position', [200,50 700,600], 'Name', 'Heading Discrimination-2I');
    	axes('position',[0.2,0.25, 0.6,0.5] );
    	% fit data with cumulative gaussian and plot both raw data and fitted curve
    	legend_txt = [];
	
		% xi = min(unique_heading) : 0.1 : max(unique_heading);
		% instead, force x range to be symmetric about zero (for staircase)
		xi = -max(abs(unique_heading)) : 0.1 : max(abs(unique_heading));
        
		for j = 1:length(unique_condition)    % <-- currently conflict_angle
            figure(s+k+10*t);
            plot(unique_heading, right_pct{s,j,k}(:), h{k,j}, xi, cum_gaussfit(psy_perf{s,j,k}, xi),  f{j} );
            xlabel('Heading Angle');   
            ylim([0,1]);
            ylabel('Percent Rightward Choices');
            hold on;
            legend_txt{j*2-1} = [num2str(unique_condition(j))];
            legend_txt{j*2} = [''];
        end
		
		% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% output some text of basic parameters in the figure
		axes('position',[0.2,0.8, 0.6,0.15] );
		xlim( [0,50] );
		ylim( [2,10] );
        text(0, 11, norm_rev{t+1});
		text(0, 10, FILE);
        text(15,11, ['amplitude = ' num2str(unique_amplitude)]);
		text(15,10, ['stimtype = ' num2str(unique_stim_type(s))]);
		text(30,10, ['azimuth = ' num2str(mean(unique_azimuth))]); % mean, because actual 'AZIMUTH' varies with conflict angle
		text(45,10, ['repeats = ' num2str(num_reps)]);
		text(0,8.3, con_txt);
		text(8,8.3, con_txt_2);
		text(18,8.3, 'bias');
		text(28,8.3, 'thresh');
		text(37,8.3, '%correct');
        text(47,8.3, 'Wves-act');
        
        for j = 1:length(unique_condition)    % <-- currently conflict_angle
            text(0,8-j, num2str(unique_condition(j)));
            text(8,8-j,num2str(unique_condition_2(k)));
            text(18,8-j,num2str(Bias_psy{s,j,k}) );
            text(28,8-j,num2str(Thresh_psy{s,j,k}) );
            text(37,8-j,num2str(mean(correct_pct{s,j,k})) );
            if j == 1
                text(47,8-j,num2str(Wves_actual_minus(k)) );
            elseif j == 3
                text(47,8-j,num2str(Wves_actual_plus(k)) );
            else
                text(48,8-j,num2str(Wves_actual(k)) );
            end
        end
        
        axis off;
        if printflag(t+1)
            print;
        end
        if closefigs
            close;
        end
        
    end % end combined
    
end


if sum(spike_rates ~= 0) > length(spike_rates)/4
% ---------------------------------------------------------------------
% ---------------------------------------------------------------------
% ---------------------------------------------------------------------
% neural data
% ---------------------------------------------------------------------
% ---------------------------------------------------------------------
% ---------------------------------------------------------------------

% ---------------------------------------------------------------
% Measure spontaneous activity using intertrial interval (time before 'trial start')
% % % % for i = 1:EndTrial-BegTrial+1
% % % %     trial_event_times{i} = find(temp_event_data(:,i)>0);
% % % %     trial_event_codes{i} = temp_event_data(trial_event_times{i},i);
% % % %     if trial_event_codes{i}(1) == 1
% % % %         trial_start_times(i) = trial_event_times{i}(1);
% % % %     else  % sometimes (rarely) the 'start trial' event is missing, so just manually pick 500 for those
% % % %         trial_start_times(i) = 500;
% % % %     end
% % % %     trial_spon_rate(i) = sum(temp_spike_data( i*5000-4999 : i*5000-(5000-trial_start_times(i)) )) / (trial_start_times(i)/1000);
% % % % %     trial_spon_rate(i) = sum(temp_spike_data( (BegTrial+i-1)*5000-4999 : (BegTrial+i-1)*5000-(5000-trial_start_times(i)) )) / (trial_start_times(i)/1000); ?????
% % % % end
% % % % 
% % % % %FIX BegTrial ISSUE
% % % % 
% % % % for q = BegTrial:EndTrial
% % % %     sum_hist = sum_hist + temp_spike_data(q*5000-4999 : q*5000);
% % % % end
% ---------------------------------------------------------------

% start with just a plot of firing rate vs. heading for each stim/condition
% first the single-cues
H{1,1} = 'ro'; H{2,1} = 'b^';
H{1,2} = 'gx'; H{2,2} = 'cs';

figure(50*t+50);
set(50*t+50,'Position', [200,50 700,600], 'Name', 'Heading Discrimination-2I');
axes('position',[0.2,0.25, 0.6,0.5] );
legend_txt = [];

for s = 1:2
    for j = 1:length(unique_condition)    % <-- currently conflict_angle
        for k = 1:length(unique_condition_2)  % <-- currently coherence
            figure(50*t+50);
            errorbar(unique_heading, resp_mean_comp{s,j,k}(:), resp_std_comp{s,j,k}(:)/sqrt(num_reps), [H{s,k} '-']);
            if ~isnan(sum(resp_mean_comp{s,j,k}))
                if length(num2str(unique_condition(j))) > 1
                    legend_txt = [legend_txt ; 'stim ' num2str(unique_stim_type(s)) ', delta ' num2str(unique_condition(j)) ', coh ' num2str(unique_condition_2(k))];
                else
                    legend_txt = [legend_txt ; 'stim ' num2str(unique_stim_type(s)) ', delta  ' num2str(unique_condition(j)) ', coh ' num2str(unique_condition_2(k))];
                end
            end
            hold on;
%             errorbar(unique_heading, resp_mean_ref{s,j,k}(:), resp_std_ref{s,j,k}(:)/sqrt(num_reps), [H{s,k} ':']);
            errorbar(0, ref_grand_mean{s,j,k}, ref_grand_std{s,j,k}/sqrt(num_reps*length(unique_heading)), ['k' H{s,k}(2)]); 
            xlabel('Heading Angle');   
            ylabel('Firing Rate');
        end
	end
end

tempx = xlim; tempy = ylim;
text(tempx(2)/3, tempy(2)-(tempy(2)-tempy(1))/10, legend_txt);
legend_row = 0;
for s = 1:2
    for j = 1:length(unique_condition)    % <-- currently conflict_angle
        for k = 1:length(unique_condition_2)  % <-- currently coherence
            if ~isnan(sum(resp_mean_comp{s,j,k}))
                plot(tempx(2)/3.25, tempy(2)-(tempy(2)-tempy(1))/20 - legend_row*(tempy(2)-tempy(1))/18, H{s,k});
                legend_row = legend_row + 1;
            end
        end
    end
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% output some text of basic parameters in the figure
text(tempx(1), tempy(2) + 0.2*(tempy(2)-tempy(1)), norm_rev{t+1});
text(tempx(1), tempy(2) + 0.15*(tempy(2)-tempy(1)), FILE);
text(tempx(1) + 0.25*(tempx(2)-tempx(1)), tempy(2) + 0.2*(tempy(2)-tempy(1)), ['amplitude = ' num2str(unique_amplitude)]);
text(tempx(1) + 0.25*(tempx(2)-tempx(1)), tempy(2) + 0.15*(tempy(2)-tempy(1)), ['stimtype = ' num2str(unique_stim_type(1)) ',' num2str(unique_stim_type(2))]);
text(tempx(1) + 0.55*(tempx(2)-tempx(1)), tempy(2) + 0.15*(tempy(2)-tempy(1)), ['azimuth = ' num2str(mean(unique_azimuth))]); % mean, because actual 'AZIMUTH' varies with conflict angle
text(tempx(1) + 0.8*(tempx(2)-tempx(1)), tempy(2) + 0.15*(tempy(2)-tempy(1)), ['repeats = ' num2str(num_reps)]);

if printflag(t+1)
    print;
end
if closefigs
    close;
end

% then the combined
F{1} = 'bo';
F{2} = 'g^';
F{3} = 'rs';

s = 3;
for k = 1:length(unique_condition_2)   % <-- currently coherence
    figure(s+k+50*t+50);
	set(s+k+50*t+50,'Position', [200,50 700,600], 'Name', 'Heading Discrimination-2I');
	axes('position',[0.2,0.25, 0.6,0.5] );
	% fit data with cumulative gaussian and plot both raw data and fitted curve
	legend_txt = [];
    
	for j = 1:length(unique_condition)    % <-- currently conflict_angle
        figure(s+k+50*t+50);
        errorbar(unique_heading, resp_mean_comp{s,j,k}(:), resp_std_comp{s,j,k}(:)/sqrt(num_reps), [F{j} '-']);
        if ~isnan(sum(resp_mean_comp{s,j,k}))
            if length(num2str(unique_condition(j))) > 1
                legend_txt = [legend_txt ; 'stim ' num2str(unique_stim_type(s)) ', delta ' num2str(unique_condition(j)) ', coh ' num2str(unique_condition_2(k))];
            else
                legend_txt = [legend_txt ; 'stim ' num2str(unique_stim_type(s)) ', delta  ' num2str(unique_condition(j)) ', coh ' num2str(unique_condition_2(k))];
            end
        end
        hold on;
        % errorbar(unique_heading, resp_mean_ref{s,j,k}(:), resp_std_ref{s,j,k}(:)/sqrt(num_reps), [F{j} ':']);
        errorbar(0, ref_grand_mean{s,j,k}, ref_grand_std{s,j,k}/sqrt(num_reps*length(unique_heading)), ['k' F{j}(2)]); 
        xlabel('Heading Angle');   
        ylabel('Firing Rate');
    end
	
    tempx = xlim; tempy = ylim;
	text(tempx(2)/3, tempy(2)-(tempy(2)-tempy(1))/10, legend_txt);
	legend_row = 0;
    for j = 1:length(unique_condition)    % <-- currently conflict_angle
        if ~isnan(sum(resp_mean_comp{s,j,k}))
            plot(tempx(2)/3.25, tempy(2)-(tempy(2)-tempy(1))/20 - legend_row*(tempy(2)-tempy(1))/18, F{j});
            legend_row = legend_row + 1;
        end
    end
	
	% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% output some text of basic parameters in the figure
	
	text(tempx(1), tempy(2) + 0.2*(tempy(2)-tempy(1)), norm_rev{t+1});
	text(tempx(1), tempy(2) + 0.15*(tempy(2)-tempy(1)), FILE);
	text(tempx(1) + 0.25*(tempx(2)-tempx(1)), tempy(2) + 0.2*(tempy(2)-tempy(1)), ['amplitude = ' num2str(unique_amplitude)]);
	text(tempx(1) + 0.25*(tempx(2)-tempx(1)), tempy(2) + 0.15*(tempy(2)-tempy(1)), ['stimtype = ' num2str(unique_stim_type(s))]);
	text(tempx(1) + 0.55*(tempx(2)-tempx(1)), tempy(2) + 0.15*(tempy(2)-tempy(1)), ['azimuth = ' num2str(mean(unique_azimuth))]); % mean, because actual 'AZIMUTH' varies with conflict angle
	text(tempx(1) + 0.8*(tempx(2)-tempx(1)), tempy(2) + 0.15*(tempy(2)-tempy(1)), ['repeats = ' num2str(num_reps)]);
	
    if printflag(t+1)
        print;
    end
    if closefigs
        close;
    end
    
end % end combined


% % %TEMP: output firing rate data for Yong to test different weighted sum models
% % yongdata(1,:) = unique_heading';
% % j = 2;
% % k = 1;
% % for s = 1:3
% %     yongdata(s+1,:) = resp_mean_comp{s,j,k}(:)';
% % end
% % yongdata(5,:) = resp_mean_comp{1,2,1}(:)';
% % k = 2;
% % for s = 2:3
% %     yongdata(s+4,:) = resp_mean_comp{s,j,k}(:)';
% % end 
% % filename = ['yongdata_' FILE(1:8)];
% % coh = unique_condition_2;
% % save(filename, 'yongdata', 'coh');
% % 
% % yongdata


% -------------------------------------------------------------
% Neurometrics and CPs
% -------------------------------------------------------------
% resp_heading = [];
Z_Spikes_comp = firing_rate_comp;
Z_Spikes_ref = firing_rate_ref;
% z-score data for later cp analysis across headings
for s = 1:length(unique_stim_type)
	for j = 1:length(unique_condition)  % <-- currently conflict_angle
        for k = 1:length(unique_condition_2)  % <-- currently coherence
            for i = 1:length(unique_heading)
                select = logical( (heading == unique_heading(i)) & (condition_2 == unique_condition_2(k)) & (condition == unique_condition(j)) & (stim_type == unique_stim_type(s)) );
                if sum(select) > 0
                    z_dist_comp = firing_rate_comp(select);
                    z_dist_comp = (z_dist_comp - mean(z_dist_comp))/std(z_dist_comp);
                    Z_Spikes_comp(select) = z_dist_comp;
                    z_dist_ref = firing_rate_ref(select);
                    z_dist_ref = (z_dist_ref - mean(z_dist_ref))/std(z_dist_ref);
                    Z_Spikes_ref(select) = z_dist_ref;
                end
            end
        end
    end
end

Z_Spikes_comp_orig = Z_Spikes_comp; % keep a Z_Spikes unchanged for later use
Z_Spikes_ref_orig = Z_Spikes_ref; % keep a Z_Spikes unchanged for later use

% now group neuronal data into two groups according to monkey's choice
for s = 1:length(unique_stim_type)
	for j = 1:length(unique_condition)  % <-- currently conflict_angle
        for k = 1:length(unique_condition_2)  % <-- currently coherence
            for i = 1:length(unique_heading)
                select = logical( (heading == unique_heading(i)) & (condition_2 == unique_condition_2(k)) & (condition == unique_condition(j)) & (stim_type == unique_stim_type(s)) );
                resp_ref{s,j,k,i} = firing_rate_ref(select);
                resp_comp{s,j,k,i} = firing_rate_comp(select);

                % calculate CP, group data based on monkey's choice 
                resp_ref_left_choice{s,j,k,i} = firing_rate_ref(select & (choice == LEFT) );
                resp_ref_right_choice{s,j,k,i} = firing_rate_ref(select & (choice == RIGHT) );
                % calculate CP, group data based on monkey's choice 
                resp_comp_left_choice{s,j,k,i} = firing_rate_comp(select & (choice == LEFT) );
                resp_comp_right_choice{s,j,k,i} = firing_rate_comp(select & (choice == RIGHT) );

                if (length(resp_ref_left_choice{s,j,k,i}) < 3) | (length(resp_ref_right_choice{s,j,k,i}) < 3)   % make sure each condition has at least 3 data values
                    Z_Spikes_ref(select) = 9999;  % similar to NaN, just make a mark
                end
                if (length(resp_comp_left_choice{s,j,k,i}) < 3) | (length(resp_comp_right_choice{s,j,k,i}) < 3)   % make sure each condition has at least 3 data values
                    Z_Spikes_comp(select) = 9999;  % similar to NaN, just make a mark
                end
            end                         % SHOULD WE REALLY EXCLUDE HEADINGS WITH < 3 CHOICES FROM THE GRAND CP???  ASK YONG.
            % now across all data
            resp_ref_left_all{s,j,k} = Z_Spikes_ref( (condition_2 == unique_condition_2(k)) & (condition == unique_condition(j)) & (stim_type == unique_stim_type(s)) & (choice == LEFT) & (Z_Spikes_ref~=9999) ); 
            resp_ref_right_all{s,j,k} = Z_Spikes_ref( (condition_2 == unique_condition_2(k)) & (condition == unique_condition(j)) & (stim_type == unique_stim_type(s)) & (choice == RIGHT) & (Z_Spikes_ref~=9999) ); 
            resp_ref_all{s,j,k} = Z_Spikes_ref( (condition_2 == unique_condition_2(k)) & (condition == unique_condition(j)) & (stim_type == unique_stim_type(s)) & (Z_Spikes_ref~=9999) ); 
            % now across all data
            resp_comp_left_all{s,j,k} = Z_Spikes_comp( (condition_2 == unique_condition_2(k)) & (condition == unique_condition(j)) & (stim_type == unique_stim_type(s)) & (choice == LEFT) & (Z_Spikes_comp~=9999) ); 
            resp_comp_right_all{s,j,k} = Z_Spikes_comp( (condition_2 == unique_condition_2(k)) & (condition == unique_condition(j)) & (stim_type == unique_stim_type(s)) & (choice == RIGHT) & (Z_Spikes_comp~=9999) ); 
            resp_comp_all{s,j,k} = Z_Spikes_comp( (condition_2 == unique_condition_2(k)) & (condition == unique_condition(j)) & (stim_type == unique_stim_type(s)) & (Z_Spikes_comp~=9999) ); 
        end
    end
end

% --------------------------------------------------------------------------
% decide whether ves and vis is congruent tuning. Fit line by linear
% regression first and compare the sign of each condition to decide whether
% congruent or opposite, this is used to check whether congruent cells lead
% to better neuronal performance in combined condition, and vice versa
for s = 1:length(unique_stim_type)
	for j = 1:length(unique_condition)  % <-- currently conflict_angle
        for k = 1:length(unique_condition_2)  % <-- currently coherence
            [rr,pp] = corrcoef(unique_heading, resp_mean_comp{s,j,k}(:));  % only 'comparison' data are used (ref stim does not vary with 'heading')
            line_r{s,j,k} = rr(1,2);
            line_p{s,j,k} = pp(1,2);
        end
    end
end

%        s,j,k
% line_r{1,2,1} = ves only
% line_r{2,2,1} = vis only, low coh
% line_r{2,2,2} = vis only, high coh
% line_r{3,2,2} = combined, high coh, zero conflict

if sign(line_r{1,2,1}) == sign(line_r{2,2,2})
    tuning_sign_vis = 0; % congruent
else
    tuning_sign_vis = 180; % opposite
end
if sign(line_r{1,2,1}) == sign(line_r{3,2,2})
    tuning_sign_com = 0; % congruent
else
    tuning_sign_com = 180; % opposite
end
tuning_sign_p(1) = line_p{1,2,1};
tuning_sign_p(2) = line_p{2,2,2};
% run correlation between ves and vis
[rrr,ppp] = corrcoef(resp_mean_comp{1,2,1}(:),  resp_mean_comp{2,2,2}(:));
line2_r = rrr(1,2);
line2_p = ppp(1,2);

%------------------------------------------------------------------------
% now calculate propotion correct from area under ROC curves; distribution of responses
% to each comparison heading are compared to corresponding reference distribution
for s = 1:length(unique_stim_type)
	for j = 1:length(unique_condition)  % <-- currently conflict_angle
        for k = 1:length(unique_condition_2)  % <-- currently coherence
            for i = 1:length(unique_heading)
                trials_n = logical( (heading == unique_heading(i)) & (condition_2 == unique_condition_2(k)) & (condition == unique_condition(j)) & (stim_type == unique_stim_type(s)) );
                fit_data_neuro_cum{s,j,k}(i,3) = sum(trials_n);  % for later function fit use
                if sum(trials_n) > 0
                    if line_r{s,j,k} > 0  % compute percent rightward choices, assuming readout 'knows' pref dir of cell (i.e., + or - slope around straight ahead)
                        Neuro_correct{s,j,k}(i) = rocN(resp_comp{s,j,k,i}, resp_ref{s,j,k,i}, 100);
                    else 
                        Neuro_correct{s,j,k}(i) = rocN(resp_ref{s,j,k,i}, resp_comp{s,j,k,i}, 100);
                    end
                else
                    Neuro_correct{s,j,k}(i) = NaN;
                end
            end
        end
    end
end

% figure; plot(unique_heading,Neuro_correct{3,3,2},'o-');

% next the CPs
for s = 1:length(unique_stim_type)
	for j = 1:length(unique_condition)  % <-- currently conflict_angle
        for k = 1:length(unique_condition_2)  % <-- currently coherence
            for i = 1:length(unique_heading)
                if (length(resp_comp_left_choice{s,j,k,i}) >= 3) & (length(resp_comp_right_choice{s,j,k,i}) >= 3)
                    if line_r{s,j,k} > 0
                        CP_comp{s,j,k}(i) = rocN(resp_comp_right_choice{s,j,k,i}, resp_comp_left_choice{s,j,k,i}, 100);
                        CP_ref{s,j,k}(i) = rocN(resp_ref_right_choice{s,j,k,i}, resp_ref_left_choice{s,j,k,i}, 100);
                    else
                        CP_comp{s,j,k}(i) = rocN(resp_comp_left_choice{s,j,k,i}, resp_comp_right_choice{s,j,k,i}, 100);
                        CP_ref{s,j,k}(i) = rocN(resp_ref_left_choice{s,j,k,i}, resp_ref_right_choice{s,j,k,i}, 100);
                    end
                else
                    CP_comp{s,j,k}(i) = NaN;
                    CP_ref{s,j,k}(i) = NaN;
                end
            end
            if (length(resp_comp_left_all{s,j,k}) > 3) & (length(resp_comp_right_all{s,j,k}) > 3)
                if line_r{s,j,k} > 0
                    CP_comp_all{s,j,k} = rocN(resp_comp_right_all{s,j,k}, resp_comp_left_all{s,j,k}, 100);
                    CP_ref_all{s,j,k} = rocN(resp_ref_right_all{s,j,k}, resp_ref_left_all{s,j,k}, 100);
                else
                    CP_comp_all{s,j,k} = rocN(resp_comp_left_all{s,j,k}, resp_comp_right_all{s,j,k}, 100);
                    CP_ref_all{s,j,k} = rocN(resp_ref_left_all{s,j,k}, resp_ref_right_all{s,j,k}, 100);
                end
            else
                CP_comp_all{s,j,k} = NaN;
                CP_ref_all{s,j,k} = NaN;
            end
        end
    end
end

%--------------------------------------------------------------------------
% use Wichman's MLE method to estimate threshold and bias
for s = 1:length(unique_stim_type)
	for j = 1:length(unique_condition)  % <-- currently conflict_angle
        for k = 1:length(unique_condition_2)  % <-- currently coherence
            fit_data_neuro_cum{s,j,k}(:,1) = unique_heading;
            fit_data_neuro_cum{s,j,k}(:,2) = Neuro_correct{s,j,k};
            if fit_data_neuro_cum{s,j,k}(1,3) == 0 % identifies and skips invalid condition combinations (e.g., vestibular only with a nonzero conflict angle)
                Thresh_neu{s,j,k} = NaN;
                Bias_neu{s,j,k} = NaN;
                neu_perf{s,j,k} = [NaN,NaN];
            else
                wichman_neu = pfit(fit_data_neuro_cum{s,j,k}(:,:),'plot_opt','no plot','shape','cumulative gaussian','n_intervals',1,'FIX_LAMBDA',0.001,'sens',0,'compute_stats','false','verbose','false');
                Thresh_neu{s,j,k} = wichman_neu.params.est(2);
                % negative and positive infinite value means flat tuning
                if Thresh_neu{s,j,k}<0 | Thresh_neu{s,j,k}> 300
                    Thresh_neu{s,j,k} = 300;
                    wichman_neu.params.est(2) = 300;
                end
                Bias_neu{s,j,k} = wichman_neu.params.est(1);
                neu_perf{s,j,k} = [wichman_neu.params.est(1),wichman_neu.params.est(2)];
                Thresh_conf_neu{s,j,k} = [wichman_neu.params.lims(1,2),wichman_neu.params.lims(4,2)];
                Bias_conf_neu{s,j,k} = [wichman_neu.params.lims(1,1),wichman_neu.params.lims(4,1)];
            end
        end
    end
end

%--------------------------------------------------------------------------
% compute the predicted and actual weights/thresholds
for k = 1:length(unique_condition_2)
    Wves_actual_minus_neu(k) = 1 - ((Bias_neu{3,1,k} - Bias_neu{3,2,k}) - (-unique_condition(1)/2)) / unique_condition(1);
    Wves_actual_plus_neu(k) = 1 - ((Bias_neu{3,3,k} - Bias_neu{3,2,k}) - (-unique_condition(3)/2)) / unique_condition(3);
	Wves_actual_neu(k) = (Wves_actual_minus(k) + Wves_actual_plus(k)) / 2;
	Wves_predicted_neu(k) = Thresh_neu{2,2,k}^2/(Thresh_neu{1,2,1}^2+Thresh_neu{2,2,k}^2);
	thresh_predicted_neu(k) = sqrt((Thresh_neu{2,2,k}^2*Thresh_neu{1,2,1}^2)/(Thresh_neu{2,2,k}^2+Thresh_neu{1,2,1}^2));
	thresh_actual_d0_neu(k) = Thresh_neu{3,2,k};
	thresh_actual_all_neu(k) = (Thresh_neu{3,1,k}+Thresh_neu{3,2,k}+Thresh_neu{3,3,k}) / 3;
	thresh_actual_pm_neu(k) = (Thresh_neu{3,1,k}+Thresh_neu{3,3,k}) / 2;
	bias_delta0_neu(k) = Bias_neu{3,2,k};
end

%--------------------------------------------------------------------------
%do permutation to test the significance of CP_all{k}, re-calculate CP 1000 times
perm_num = 1000;
Z_Spikes_comp_perm = Z_Spikes_comp;
Z_Spikes_ref_perm = Z_Spikes_ref;
bin = 0.005;
x_bin = 0 : bin : 1;
for s = 1:length(unique_stim_type)
	for j = 1:length(unique_condition)  % <-- currently conflict_angle
        for k = 1:length(unique_condition_2)  % <-- currently coherence
            select = logical( (condition_2 == unique_condition_2(k)) & (condition == unique_condition(j)) & (stim_type == unique_stim_type(s)) & (Z_Spikes_comp~=9999) );
            
            if sum(select) > 0
                
                for n = 1 : perm_num
                    
                    % temperarilly only use near-threshold heading angles where monkey make a guess mainly
                    Z_Spikes_temp{s,j,k} = Z_Spikes_comp_perm(select);
                    Z_Spikes_temp{s,j,k} = Z_Spikes_temp{s,j,k}(randperm(length(Z_Spikes_temp{s,j,k})));   % permute spike_rates
                    Z_Spikes_comp_perm(select) = Z_Spikes_temp{s,j,k};    % now in spike_rates, the corresponding data were permuted already
                    % temperarilly only use near-threshold heading angles where monkey make a guess mainly
                    Z_Spikes_temp{s,j,k} = Z_Spikes_ref_perm(select);
                    Z_Spikes_temp{s,j,k} = Z_Spikes_temp{s,j,k}(randperm(length(Z_Spikes_temp{s,j,k})));   % permute spike_rates
                    Z_Spikes_ref_perm(select) = Z_Spikes_temp{s,j,k};    % now in spike_rates, the corresponding data were permuted already
                    
                    resp_comp_left_all_perm = Z_Spikes_comp_perm( (condition_2 == unique_condition_2(k)) & (condition == unique_condition(j)) & (stim_type == unique_stim_type(s)) & (choice == LEFT) & (Z_Spikes_comp~=9999) ); 
                    resp_comp_right_all_perm = Z_Spikes_comp_perm( (condition_2 == unique_condition_2(k)) & (condition == unique_condition(j)) & (stim_type == unique_stim_type(s)) & (choice == RIGHT) & (Z_Spikes_comp~=9999) ); 
                    resp_ref_left_all_perm = Z_Spikes_ref_perm( (condition_2 == unique_condition_2(k)) & (condition == unique_condition(j)) & (stim_type == unique_stim_type(s)) & (choice == LEFT) & (Z_Spikes_ref~=9999) ); 
                    resp_ref_right_all_perm = Z_Spikes_ref_perm( (condition_2 == unique_condition_2(k)) & (condition == unique_condition(j)) & (stim_type == unique_stim_type(s)) & (choice == RIGHT) & (Z_Spikes_ref~=9999) ); 
                    
                    if (length(resp_comp_left_all{s,j,k}) > 3) & (length(resp_comp_right_all{s,j,k}) > 3)
                        if line_r{s,j,k} > 0
                            CP_comp_all_perm{s,j,k}(n) = rocN(resp_comp_right_all_perm, resp_comp_left_all_perm, 100);
                            CP_ref_all_perm{s,j,k}(n) = rocN(resp_ref_right_all_perm, resp_ref_left_all_perm, 100);
                        else
                            CP_comp_all_perm{s,j,k}(n) = rocN(resp_comp_left_all_perm, resp_comp_right_all_perm, 100);
                            CP_ref_all_perm{s,j,k}(n) = rocN(resp_ref_left_all_perm, resp_ref_right_all_perm, 100);
                        end
                    else
                        CP_comp_all_perm{s,j,k}(n) = NaN;
                        CP_ref_all_perm{s,j,k}(n) = NaN;
                    end
                    
                    resp_comp_left_choice_perm = Z_Spikes_comp_perm( (condition_2 == unique_condition_2(k)) & (condition == unique_condition(j)) & (stim_type == unique_stim_type(s)) & (heading == unique_heading(find(unique_heading==0))) & (choice == LEFT) & (Z_Spikes_comp~=9999) );
                    resp_comp_right_choice_perm = Z_Spikes_comp_perm( (condition_2 == unique_condition_2(k)) & (condition == unique_condition(j)) & (stim_type == unique_stim_type(s)) & (heading == unique_heading(find(unique_heading==0))) & (choice == RIGHT) & (Z_Spikes_comp~=9999) );
                    resp_ref_left_choice_perm = Z_Spikes_ref_perm( (condition_2 == unique_condition_2(k)) & (condition == unique_condition(j)) & (stim_type == unique_stim_type(s)) & (heading == unique_heading(find(unique_heading==0))) & (choice == LEFT) & (Z_Spikes_ref~=9999) );
                    resp_ref_right_choice_perm = Z_Spikes_ref_perm( (condition_2 == unique_condition_2(k)) & (condition == unique_condition(j)) & (stim_type == unique_stim_type(s)) & (heading == unique_heading(find(unique_heading==0))) & (choice == RIGHT) & (Z_Spikes_ref~=9999) );

                    if (length(resp_comp_left_choice{s,j,k,find(unique_heading==0)}) >= 3) & (length(resp_comp_right_choice{s,j,k,find(unique_heading==0)}) >= 3)
                        if line_r{s,j,k} > 0
                            CP_comp_perm(n) = rocN(resp_comp_right_choice_perm, resp_comp_left_choice_perm, 100);
                            CP_ref_perm(n) = rocN(resp_ref_right_choice_perm, resp_ref_left_choice_perm, 100);
                        else
                            CP_comp_perm(n) = rocN(resp_comp_left_choice_perm, resp_comp_right_choice_perm, 100);
                            CP_ref_perm(n) = rocN(resp_ref_left_choice_perm, resp_ref_right_choice_perm, 100);
                        end
                    else
                        CP_comp_perm(n) = NaN;
                        CP_ref_perm(n) = NaN;
                    end
                    
                end  % n = 1:perm_num

                % now calculate p value or significant test
                if (length(resp_comp_left_all{s,j,k}) >= 3) & (length(resp_comp_right_all{s,j,k}) >= 3) 

                    hist_comp_perm(s,j,k,:) = hist(CP_comp_all_perm{s,j,k}(:), x_bin);  % for permutation
                    bin_sum = 0;
                    m = 0;
                    while ( m < (CP_comp_all{s,j,k}/bin) )
                        m = m+1;
                        bin_sum = bin_sum + hist_comp_perm(s,j,k,m);
                        if CP_comp_all{s,j,k} > 0.5                  % note it's two tail test
                            p_comp(s,j,k) = 2*(perm_num - bin_sum)/ perm_num;    % calculate p value for CP_all
                        else
                            p_comp(s,j,k) = 2* bin_sum / perm_num;
                        end
                    end
                    
                    hist_ref_perm(s,j,k,:) = hist(CP_ref_all_perm{s,j,k}(:), x_bin);  % for permutation
                    bin_sum = 0;
                    m = 0;
                    while ( m < (CP_ref_all{s,j,k}/bin) )
                        m = m+1;
                        bin_sum = bin_sum + hist_ref_perm(s,j,k,m);
                        if CP_ref_all{s,j,k} > 0.5                  % note it's two tail test
                            p_ref(s,j,k) = 2*(perm_num - bin_sum)/ perm_num;    % calculate p value for CP_all
                        else
                            p_ref(s,j,k) = 2* bin_sum / perm_num;
                        end
                    end
                    
                else
                    p_comp(s,j,k) = NaN;
                    p_ref(s,j,k) = NaN;
                end 
                
                % calculate p value for CP during straight ahead motion
                if length(resp_comp_left_choice{s,j,k,find(unique_heading==0)}) >= 3 & length(resp_comp_right_choice{s,j,k,find(unique_heading==0)}) >= 3
                    
                    hist_comp_perm(s,j,k,:) = hist( CP_comp_perm(:), x_bin );  % for permutation
                    bin_sum = 0;
                    m = 0;
                    while ( m < (CP_comp{s,j,k}(find(unique_heading==0))/bin) )
                         m = m+1;
                         bin_sum = bin_sum + hist_comp_perm(s,j,k,m);
                         if CP_comp{s,j,k}(find(unique_heading==0)) > 0.5                  % note it's two tail test
                            pp1 = 2*(perm_num - bin_sum)/ perm_num;    % calculate p value for CP_all
                         else
                            pp1 = 2* bin_sum / perm_num;
                         end
                    end
                    
                    hist_ref_perm(s,j,k,:) = hist( CP_ref_perm(:), x_bin );  % for permutation
                    bin_sum = 0;
                    m = 0;
                    while ( m < (CP_ref{s,j,k}(find(unique_heading==0))/bin) )
                         m = m+1;
                         bin_sum = bin_sum + hist_ref_perm(s,j,k,m);
                         if CP_ref{s,j,k}(find(unique_heading==0)) > 0.5                  % note it's two tail test
                            pp2 = 2*(perm_num - bin_sum)/ perm_num;    % calculate p value for CP_all
                         else
                            pp2 = 2* bin_sum / perm_num;
                         end
                    end
                    
                else % if < 3 
                    pp1 = NaN;
                    pp2 = NaN;
                end
                
                p_0_comp(s,j,k) = pp1;
                p_0_ref(s,j,k) = pp2;
                
            else % if sum(select) == 0
                p_comp(s,j,k) = NaN;
                p_ref(s,j,k) = NaN;
                p_0_comp(s,j,k) = NaN;
                p_0_ref(s,j,k) = NaN;
            end
            
		end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot neurometric function here
H{1,1} = 'ro'; H{2,1} = 'b^';
H{1,2} = 'gx'; H{2,2} = 'cs';

figure(50*t+50*2);
set(50*t+50*2,'Position', [200,50 700,600], 'Name', 'Heading Discrimination-2I');
axes('position',[0.2,0.25, 0.6,0.5] );
legend_txt = [];
xi = -max(abs(unique_heading)) : 0.1 : max(abs(unique_heading));

for s = 1:2
    for j = 1:length(unique_condition)    % <-- currently conflict_angle
        for k = 1:length(unique_condition_2)  % <-- currently coherence
            figure(50*t+50*2);
            plot(unique_heading, Neuro_correct{s,j,k}(:), H{s,k}, xi, cum_gaussfit(neu_perf{s,j,k}, xi),  [H{s,k}(1) '-'] );
            if ~isnan(sum(resp_mean_comp{s,j,k}))
                if length(num2str(unique_condition(j))) > 1
                    legend_txt = [legend_txt ; 'stim ' num2str(unique_stim_type(s)) ', delta ' num2str(unique_condition(j)) ', coh ' num2str(unique_condition_2(k))];
                else
                    legend_txt = [legend_txt ; 'stim ' num2str(unique_stim_type(s)) ', delta  ' num2str(unique_condition(j)) ', coh ' num2str(unique_condition_2(k))];
                end
            end
            hold on;
            xlabel('Heading Angle');   
            ylabel('Percent Rightward Choices (Neuro)');
        end
	end
end

ylim([0 1]);
tempx = xlim; tempy = ylim;
text(tempx(2)/3, tempy(1)+(tempy(2)-tempy(1))/9, legend_txt);
legend_row = 2;
for s = 1:2
    for j = 1:length(unique_condition)    % <-- currently conflict_angle
        for k = 1:length(unique_condition_2)  % <-- currently coherence
            if ~isnan(sum(resp_mean_comp{s,j,k}))
                plot(tempx(2)/3.25, tempy(1)+(tempy(2)-tempy(1))/18 + legend_row*(tempy(2)-tempy(1))/18, H{s,k});
                legend_row = legend_row - 1;
            end
        end
    end
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% output some text of basic parameters in the figure
text(tempx(1), tempy(2) + 0.3*(tempy(2)-tempy(1)), norm_rev{t+1});
text(tempx(1), tempy(2) + 0.25*(tempy(2)-tempy(1)), FILE);
text(tempx(1) + 0.25*(tempx(2)-tempx(1)), tempy(2) + 0.3*(tempy(2)-tempy(1)), ['amplitude = ' num2str(unique_amplitude)]);
text(tempx(1) + 0.25*(tempx(2)-tempx(1)), tempy(2) + 0.25*(tempy(2)-tempy(1)), ['stimtype = ' num2str(unique_stim_type(1)) ',' num2str(unique_stim_type(2))]);
text(tempx(1) + 0.55*(tempx(2)-tempx(1)), tempy(2) + 0.25*(tempy(2)-tempy(1)), ['azimuth = ' num2str(mean(unique_azimuth))]); % mean, because actual 'AZIMUTH' varies with conflict angle
text(tempx(1) + 0.8*(tempx(2)-tempx(1)), tempy(2) + 0.25*(tempy(2)-tempy(1)), ['repeats = ' num2str(num_reps)]);

% then the thresholds and biases
text(tempx(1) + 0.05*(tempx(2)-tempx(1)), tempy(2) + 0.19*(tempy(2)-tempy(1)), 'stimtype');
text(tempx(1) + 0.25*(tempx(2)-tempx(1)), tempy(2) + 0.19*(tempy(2)-tempy(1)), con_txt);
text(tempx(1) + 0.45*(tempx(2)-tempx(1)), tempy(2) + 0.19*(tempy(2)-tempy(1)), con_txt_2);
text(tempx(1) + 0.65*(tempx(2)-tempx(1)), tempy(2) + 0.19*(tempy(2)-tempy(1)), 'bias');
text(tempx(1) + 0.85*(tempx(2)-tempx(1)), tempy(2) + 0.19*(tempy(2)-tempy(1)), 'thresh');
data_row = 0;
for s = 1:2
    for j = 1:length(unique_condition)    % <-- currently conflict_angle
        for k = 1:length(unique_condition_2)  % <-- currently coherence
            if ~isnan(sum(resp_mean_comp{s,j,k}))
                text(tempx(1) + 0.05*(tempx(2)-tempx(1)), tempy(2) + (0.14-0.04*data_row)*(tempy(2)-tempy(1)), num2str(unique_stim_type(s)));
                text(tempx(1) + 0.25*(tempx(2)-tempx(1)), tempy(2) + (0.14-0.04*data_row)*(tempy(2)-tempy(1)), num2str(unique_condition(j)));
                text(tempx(1) + 0.45*(tempx(2)-tempx(1)), tempy(2) + (0.14-0.04*data_row)*(tempy(2)-tempy(1)), num2str(unique_condition_2(k)));
                text(tempx(1) + 0.65*(tempx(2)-tempx(1)), tempy(2) + (0.14-0.04*data_row)*(tempy(2)-tempy(1)), num2str(Bias_neu{s,j,k}) );
                text(tempx(1) + 0.85*(tempx(2)-tempx(1)), tempy(2) + (0.14-0.04*data_row)*(tempy(2)-tempy(1)), num2str(Thresh_neu{s,j,k}) );
                data_row = data_row + 1;
            end
        end
	end
end

if printflag(t+1)
    print;
end
if closefigs
    close;
end

% then the combined
F{1} = 'bo';
F{2} = 'g^';
F{3} = 'rs';

s = 3;
for k = 1:length(unique_condition_2)   % <-- currently coherence
    
    figure(s+k+50*t+50*2);
	set(s+k+50*t+50*2,'Position', [200,50 700,600], 'Name', 'Heading Discrimination-2I');
	axes('position',[0.2,0.25, 0.6,0.5] );
	% fit data with cumulative gaussian and plot both raw data and fitted curve
	legend_txt = [];
    
	for j = 1:length(unique_condition)    % <-- currently conflict_angle
        figure(s+k+50*t+50*2);
        plot(unique_heading, Neuro_correct{s,j,k}(:), F{j}, xi, cum_gaussfit(neu_perf{s,j,k}, xi),  [F{j}(1) '-']);
        if ~isnan(sum(resp_mean_comp{s,j,k}))
            if length(num2str(unique_condition(j))) > 1
                legend_txt = [legend_txt ; 'stim ' num2str(unique_stim_type(s)) ', delta ' num2str(unique_condition(j)) ', coh ' num2str(unique_condition_2(k))];
            else
                legend_txt = [legend_txt ; 'stim ' num2str(unique_stim_type(s)) ', delta  ' num2str(unique_condition(j)) ', coh ' num2str(unique_condition_2(k))];
            end
        end
        hold on;
        xlabel('Heading Angle');   
        ylabel('Percent Rightward Choices (Neuro)');
    end
    
    ylim([0 1]);
	tempx = xlim; tempy = ylim;
	text(tempx(2)/3, tempy(1)+(tempy(2)-tempy(1))/9, legend_txt);
	legend_row = 2;
    for j = 1:length(unique_condition)    % <-- currently conflict_angle
        if ~isnan(sum(resp_mean_comp{s,j,k}))
            plot(tempx(2)/3.25, tempy(1)+(tempy(2)-tempy(1))/18 + legend_row*(tempy(2)-tempy(1))/18, F{j});
            legend_row = legend_row - 1;
        end
    end
	
	% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% output some text of basic parameters in the figure
    text(tempx(1), tempy(2) + 0.3*(tempy(2)-tempy(1)), norm_rev{t+1});
	text(tempx(1), tempy(2) + 0.25*(tempy(2)-tempy(1)), FILE);
	text(tempx(1) + 0.25*(tempx(2)-tempx(1)), tempy(2) + 0.3*(tempy(2)-tempy(1)), ['amplitude = ' num2str(unique_amplitude)]);
	text(tempx(1) + 0.25*(tempx(2)-tempx(1)), tempy(2) + 0.25*(tempy(2)-tempy(1)), ['stimtype = ' num2str(unique_stim_type(3))]);
	text(tempx(1) + 0.55*(tempx(2)-tempx(1)), tempy(2) + 0.25*(tempy(2)-tempy(1)), ['azimuth = ' num2str(mean(unique_azimuth))]); % mean, because actual 'AZIMUTH' varies with conflict angle
	text(tempx(1) + 0.8*(tempx(2)-tempx(1)), tempy(2) + 0.25*(tempy(2)-tempy(1)), ['repeats = ' num2str(num_reps)]);
	
	% then the thresholds and biases
	text(tempx(1) + 0.05*(tempx(2)-tempx(1)), tempy(2) + 0.19*(tempy(2)-tempy(1)), 'stimtype');
	text(tempx(1) + 0.25*(tempx(2)-tempx(1)), tempy(2) + 0.19*(tempy(2)-tempy(1)), con_txt);
	text(tempx(1) + 0.45*(tempx(2)-tempx(1)), tempy(2) + 0.19*(tempy(2)-tempy(1)), con_txt_2);
	text(tempx(1) + 0.65*(tempx(2)-tempx(1)), tempy(2) + 0.19*(tempy(2)-tempy(1)), 'bias');
	text(tempx(1) + 0.85*(tempx(2)-tempx(1)), tempy(2) + 0.19*(tempy(2)-tempy(1)), 'thresh');
	data_row = 0;
    for j = 1:length(unique_condition)    % <-- currently conflict_angle
        if ~isnan(sum(resp_mean_comp{s,j,k}))
            text(tempx(1) + 0.05*(tempx(2)-tempx(1)), tempy(2) + (0.14-0.04*data_row)*(tempy(2)-tempy(1)), num2str(unique_stim_type(s)));
            text(tempx(1) + 0.25*(tempx(2)-tempx(1)), tempy(2) + (0.14-0.04*data_row)*(tempy(2)-tempy(1)), num2str(unique_condition(j)));
            text(tempx(1) + 0.45*(tempx(2)-tempx(1)), tempy(2) + (0.14-0.04*data_row)*(tempy(2)-tempy(1)), num2str(unique_condition_2(k)));
            text(tempx(1) + 0.65*(tempx(2)-tempx(1)), tempy(2) + (0.14-0.04*data_row)*(tempy(2)-tempy(1)), num2str(Bias_neu{s,j,k}) );
            text(tempx(1) + 0.85*(tempx(2)-tempx(1)), tempy(2) + (0.14-0.04*data_row)*(tempy(2)-tempy(1)), num2str(Thresh_neu{s,j,k}) );
            data_row = data_row + 1;
        end
	end
    
    if printflag(t+1)
        print;
    end
    if closefigs
        close;
    end
    
end % end combined


% % % Yong's
% % legend_txt = [];
% % for k = 1:length(unique_stim_type)
% %     xi = min(unique_heading) : 0.1 : max(unique_heading);   
% %     beta = [0, 1.0];
% %  %   plot data in logarithmical space instead of linspace
% %     plot(unique_heading, psycho_correct(k,:), h{k}, xi, cum_gaussfit(psy_perf{k}, xi),  f{k} );
% %     xlabel('Heading Angles');   
% %     ylim([0,1]);
% %     ylabel('Rightward Choices');
% %     hold on;
% %     legend_txt{k*2-1} = [num2str(unique_stim_type(k))];
% %     legend_txt{k*2} = [''];
% % %    also fit data with weibull function
% % %    [psycho_alpha(k) psycho_beta(k)]= weibull_fit(fit_data_psycho{k});
% % end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % plot psychometric, neurometric, CP over time
% % run the slide threshold over time, see whether performance fluctuate across time
% span = 5;  % calculate threshod every ? repeats;
% slide = 1;  % slide threshod with increment of ? repeats;
% BegTrial_shift = BegTrial;
% EndTrial_shift = BegTrial_shift + span*one_repetition-1;
% n=0;
% while EndTrial_shift <= EndTrial
%     n = n + 1;
%     select_trials_shift = ( (trials >= BegTrial_shift) & (trials <= EndTrial_shift) );
%     stim_type_shift = temp_stim_type( select_trials_shift );
%     heading_shift = temp_heading( select_trials_shift );
%     unique_stim_type_shift = munique(stim_type_shift');
%     unique_heading_shift = munique(heading_shift');
%     total_trials_shift = temp_total_trials( select_trials_shift);
%     spike_rates_shift = temp_spike_rates( select_trials_shift );
%     Z_Spikes_shift = Z_Spikes_Ori;
%     for k = 1:length(unique_stim_type)
%         for i = 1:length(unique_heading)
%              trials_shift =logical( (heading_shift == unique_heading(i)) & (stim_type_shift == unique_stim_type(k)) ) ;
%              trials_shift2 = logical( (trials >= BegTrial_shift-BegTrial) & (trials <= EndTrial_shift-BegTrial) );
%              trials_shift_CP = logical( (trials >= BegTrial) & (trials <= EndTrial_shift-BegTrial) );
%              trials_shift3 = logical( (heading == unique_heading(i)) & (stim_type == unique_stim_type(k)) ) ;
%              correct_trials_shift = (trials_shift & (total_trials_shift == CORRECT) );
%              % neural
%              resp_heading_shift{k,i} = spike_rates_shift(trials_shift );
%              % choice probability
%              resp_left_choice_shift{k,i} = spike_rates(trials_shift3 & trials_shift_CP & (choice == LEFT) );
%              resp_right_choice_shift{k,i} = spike_rates(trials_shift3 & trials_shift_CP & (choice == RIGHT) );
%              if (length(resp_left_choice_shift{k,i}) <= span*0.25) | (length(resp_right_choice_shift{k,i}) <= span*0.25)
%                  Z_Spikes_shift(trials_shift3 &trials_shift_CP) = 9999;
%              end
%              % make 'S' curve by using the rightward choice for y-axis
%              if ( unique_heading(i) < 0 )
%                  correct_rate_shift(i) = 1 - 1*sum(correct_trials_shift) / sum(trials_shift); 
%              else
%                  correct_rate_shift(i) = 1*sum(correct_trials_shift) / sum(trials_shift); 
%              end         
%          end
%          fit_data_psycho_cum_shift{k}(:, 1) = fit_data_psycho_cum{k}(:, 1);  
%          fit_data_psycho_cum_shift{k}(:, 2) = correct_rate_shift(:);
%          fit_data_psycho_cum_shift{k}(:, 3) = span;
%          [bb,tt] = cum_gaussfit_max1(fit_data_psycho_cum_shift{k});
%          psy_thresh_shift(k,n) = tt;
%          % for neuronal performence over time
%          for i = 1 : length(unique_heading)-1   % subtract the 0 heading
%              if i < (1+length(unique_heading))/2
%                  Neuro_correct_shift{k}(i) =  rocN( resp_heading_shift{k,(1+length(unique_heading))/2},resp_heading_shift{k,i},100 ); % compare to the 0 heading condition, which is straght ahead
%              else
%                  Neuro_correct_shift{k}(i) =  rocN( resp_heading_shift{k,(1+length(unique_heading))/2},resp_heading_shift{k,i+1},100 ); % compare to the 0 heading condition, which is straght ahead
%              end
%              if  resp_mat{k}(1) < resp_mat{k}(end)  
%                  Neuro_correct_shift{k}(i) = 1 - Neuro_correct_shift{k}(i);            
%              end  
%          end
%          fit_data_neu_cum_shift{k}(:, 1) = unique_heading(unique_heading~=0);  
%          fit_data_neu_cum_shift{k}(:, 2) = Neuro_correct_shift{k}(:);
%          fit_data_neu_cum_shift{k}(:, 3) = span;
%          [bbb,ttt] = cum_gaussfit_max1(fit_data_neu_cum_shift{k});
%          neu_thresh_shift(k,n) = ttt; 
%          % choice probability
%          resp_left_all_shift{k} = Z_Spikes_shift( trials_shift_CP & (stim_type == unique_stim_type(k)) & (choice == LEFT) & (Z_Spikes_shift~=9999) ); 
%          resp_right_all_shift{k} = Z_Spikes_shift( trials_shift_CP & (stim_type == unique_stim_type(k)) & (choice == RIGHT) & (Z_Spikes_shift~=9999) );
%          if (length(resp_left_all_shift{k}) <= span*0.25) | (length(resp_right_all_shift{k}) <= span*0.25)
%              CP_all_shift{k}(n) = NaN;
%          else
%              CP_all_shift{k}(n) = rocN( resp_left_all_shift{k},resp_right_all_shift{k},100 );
%          end
%          if  resp_mat{k}(1) < resp_mat{k}(end)  
%               CP_all_shift{k}(n) = 1 - CP_all_shift{k}(n);
%          end   
%     end   
%     BegTrial_shift = BegTrial_shift + slide*one_repetition;
%     EndTrial_shift = EndTrial_shift + slide*one_repetition; 
% end
% % plot psycho
% axes('position',[0.05,0.05, 0.26,0.15] );
% for k = 1:length(unique_stim_type)
%     plot(psy_thresh_shift(k,:), f{k});
%     hold on;
%     xlabel('Repetition');  
%     ylabel('Threshold');
%     xlim([1, n]);
%     ylim( [min(min(psy_thresh_shift(:,:))), max(max(psy_thresh_shift(:,:)))] );   
% end
% % plot neuro
% axes('position',[0.36,0.05, 0.26,0.15] );
% for k = 1:length(unique_stim_type)  
%     plot(neu_thresh_shift(k,:), f{k});
%     hold on;
%     xlabel('Repetition');  
%     ylabel('Threshold');
%     xlim([1, n]);
%     ylim( [min(min(neu_thresh_shift(:,:))), 100] );   % just cut off at 100 deg, don't trust too big numbers
% end
% % plot Choice Probability
% axes('position',[0.7,0.05, 0.26,0.15] );
% for k = 1:length(unique_stim_type)    
%     plot(CP_all_shift{k}(:), f{k});
%     hold on;
%     xlabel('Repetition');  
%     ylabel('CP');
%     xlim([1, n]);
%     ylim( [0, 1] );   
%     grid on;
% end
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % output some text of basic parameters in the figure
% axes('position',[0.05,0.8, 0.9,0.15] );
% xlim( [0,100] );
% ylim( [2,10] );
% text(0, 10, FILE);
% text(20,10,'coherence =');
% text(30,10,num2str(unique_motion_coherence) );
% text(45,10,'repetition =');
% text(55,10,num2str(repetition) ); 
% text(5,8, 'Psy: u      threshold        err           Neu:u         threshold         err              CP        p');
% text(0,8, 'stim');
% for k = 1:length(unique_stim_type)
%     text(0,8-k, num2str(unique_stim_type(k)));
%     text(5,8-k,num2str(Bias_psy{k} ));
%     text(12,8-k,num2str(Thresh_psy{k} ));
% %    text(20,8-k,num2str(psy_boot(k)) );
%     text(30,8-k,num2str(Bias_neu{k} ));
%     text(40,8-k,num2str(Thresh_neu{k} ));
%   %  text(50,8-k,num2str(neu_boot(k)) );
%     text(50,8-k,num2str(CP_all{k}') ); 
%     text(60,8-k,num2str(p{k}') );   
%  %   text(53,8-k,num2str(CP{k}(3:end-2)) );  % always show the middle angles, not the 24 and 8 
% end
% axis off;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% neural data output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sprint_txt = ['%s\t'];
% for i = 1 : 50 % this should be large enough to cover all the data that need to be exported
%      sprint_txt = [sprint_txt, ' %4.3f\t'];    
% end

% now must be adjusted when fields are added/changed
sprint_txt = ['%s\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%s\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t']; 

outfile = [BASE_PATH 'ProtocolSpecific\MOOG\HeadingDiscrimination_2I\Neurometric_2I_conflict.dat'];
createfile = 0;
if (exist(outfile, 'file') == 0)    %file does not yet exist
    createfile = 1;
end
fid = fopen(outfile, 'a');
if (createfile)
    fprintf(fid, 'FILE\t azimuth\t stim_type\t delta\t coherence\t bias\t bias_lower\t bias_upper\t thresh\t thresh_lower\t thresh_upper\t num_reps\t norm_rev\t CP_zero_comp\t p_zero_comp\t CP_all_comp\t p_all_comp\t CP_zero_ref\t p_zero_ref\t CP_all_ref\t p_all_ref');
    fprintf(fid, '\r\n');
end

% CP_comp{s,j,k}(unique_heading==0)
% p_0_comp(s,j,k)
% CP_comp_all{s,j,k}
% p_comp(s,j,k)
% CP_ref{s,j,k}(unique_heading==0)
% p_0_ref(s,j,k)
% CP_ref_all{s,j,k}
% p_ref(s,j,k)
% 
% CP_comp{s,j,k}(unique_heading==0), p_0_comp(s,j,k), CP_comp_all{s,j,k}, p_comp(s,j,k), CP_ref{s,j,k}(unique_heading==0), p_0_ref(s,j,k), CP_ref_all{s,j,k}, p_ref(s,j,k)
% CP_zero_comp\t p_zero_comp\t CP_all_comp\t p_all_comp\t CP_zero_ref\t p_zero_ref\t CP_all_ref\t p_all_ref\t

if length(unique_stim_type) == 1 % keep old way for any single stim type...
    
	for j = 1:length(unique_condition)
        for k = 1:length(unique_condition_2)   % MUST CHANGE THESE WHEN DIFFERENT CONDITIONS ARE VARIED!
			buff = sprintf(sprint_txt, FILE, mean(unique_azimuth), unique_stim_type, unique_condition(j), unique_condition_2(k), Bias_neu{s,j,k}, Bias_conf_neu{s,j,k}(1), Bias_conf_neu{s,j,k}(2), Thresh_neu{s,j,k}, Thresh_conf_neu{s,j,k}(1), Thresh_conf_neu{s,j,k}(2), num_reps, norm_rev{t+1}, CP_comp{s,j,k}(unique_heading==0), p_0_comp(s,j,k), CP_comp_all{s,j,k}, p_comp(s,j,k), CP_ref{s,j,k}(unique_heading==0), p_0_ref(s,j,k), CP_ref_all{s,j,k}, p_ref(s,j,k));
            fprintf(fid, '%s', buff);
            fprintf(fid, '\r\n');
        end
	end
    
else % ...but needs to change for all three stim types interleaved
    s = 1;
    buff = sprintf(sprint_txt, FILE, mean(unique_azimuth), unique_stim_type(s), unique_condition(2), unique_condition_2(1), Bias_neu{s,2,1}, Bias_conf_neu{s,2,1}(1), Bias_conf_neu{s,2,1}(2), Thresh_neu{s,2,1}, Thresh_conf_neu{s,2,1}(1), Thresh_conf_neu{s,2,1}(2), num_reps, norm_rev{t+1}, CP_comp{s,2,1}(unique_heading==0), p_0_comp(s,2,1), CP_comp_all{s,2,1}, p_comp(s,2,1), CP_ref{s,2,1}(unique_heading==0), p_0_ref(s,2,1), CP_ref_all{s,2,1}, p_ref(s,2,1));
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');

    s = 2;
    for k = 1:length(unique_condition_2)
        buff = sprintf(sprint_txt, FILE, mean(unique_azimuth), unique_stim_type(s), unique_condition(2), unique_condition_2(k), Bias_neu{s,2,k}, Bias_conf_neu{s,2,k}(1), Bias_conf_neu{s,2,k}(2), Thresh_neu{s,2,k}, Thresh_conf_neu{s,2,k}(1), Thresh_conf_neu{s,2,k}(2), num_reps, norm_rev{t+1}, CP_comp{s,2,k}(unique_heading==0), p_0_comp(s,2,k), CP_comp_all{s,2,k}, p_comp(s,2,k), CP_ref{s,2,k}(unique_heading==0), p_0_ref(s,2,k), CP_ref_all{s,2,k}, p_ref(s,2,k));
        fprintf(fid, '%s', buff);
        fprintf(fid, '\r\n');
    end
    
    s = 3;
    for j = 1:length(unique_condition)
        for k = 1:length(unique_condition_2)   % MUST CHANGE THESE WHEN DIFFERENT CONDITIONS ARE VARIED!
			buff = sprintf(sprint_txt, FILE, mean(unique_azimuth), unique_stim_type(s), unique_condition(j), unique_condition_2(k), Bias_neu{s,j,k}, Bias_conf_neu{s,j,k}(1), Bias_conf_neu{s,j,k}(2), Thresh_neu{s,j,k}, Thresh_conf_neu{s,j,k}(1), Thresh_conf_neu{s,j,k}(2), num_reps, norm_rev{t+1}, CP_comp{s,j,k}(unique_heading==0), p_0_comp(s,j,k), CP_comp_all{s,j,k}, p_comp(s,j,k), CP_ref{s,j,k}(unique_heading==0), p_0_ref(s,j,k), CP_ref_all{s,j,k}, p_ref(s,j,k));
            fprintf(fid, '%s', buff);
            fprintf(fid, '\r\n');
        end
	end

end

fclose(fid);

% lastly, write the predicted/actual weights and thresholds to a separate file
sprint_txt = ['%s\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t']; 
outfile = [BASE_PATH 'ProtocolSpecific\MOOG\HeadingDiscrimination_2I\Neurometric_2I_conflict2.dat'];
createfile = 0;
if (exist(outfile, 'file') == 0)    %file does not yet exist
    createfile = 1;
end
fid = fopen(outfile, 'a');
if (createfile)
    fprintf(fid, 'FILE\t coherence\t Wves_predicted\t Wves_actual_minus\t Wves_actual_plus\t Wves_actual\t thresh_predicted\t thresh_actual_d0\t thresh_actual_all\t thresh_actual_pm\t bias_delta0');
    fprintf(fid, '\r\n');
end
for k = 1:length(unique_condition_2)
	buff = sprintf(sprint_txt, FILE, unique_condition_2(k), Wves_predicted_neu(k), Wves_actual_minus_neu(k), Wves_actual_plus_neu(k), Wves_actual_neu(k), thresh_predicted_neu(k), thresh_actual_d0_neu(k), thresh_actual_all_neu(k), thresh_actual_pm_neu(k), bias_delta0_neu(k));
	fprintf(fid, '%s', buff);
	fprintf(fid, '\r\n');
end
fclose(fid);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


end % END if sum(spike_rates ~= 0) > 1/4 of num trials


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% behavioral data output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sprint_txt = ['%s\t'];
% for i = 1 : 50 % this should be large enough to cover all the data that need to be exported
%      sprint_txt = [sprint_txt, ' %4.3f\t'];    
% end

% now must be adjusted when fields are added/changed
sprint_txt = ['%s\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%s\t'];

outfile = [BASE_PATH 'ProtocolSpecific\MOOG\HeadingDiscrimination_2I\Psychometric_2I_conflict.dat'];
createfile = 0;
if (exist(outfile, 'file') == 0)    %file does not yet exist
    createfile = 1;
end
fid = fopen(outfile, 'a');
if (createfile)
    fprintf(fid, 'FILE\t azimuth\t stim_type\t delta\t coherence\t bias\t bias_lower\t bias_upper\t thresh\t thresh_lower\t thresh_upper\t pct_correct\t num_reps\t norm_rev');
    fprintf(fid, '\r\n');
end

if length(unique_stim_type) == 1 % keep old way for any single stim type...
    
	for j = 1:length(unique_condition)
        for k = 1:length(unique_condition_2)   % MUST CHANGE THESE WHEN DIFFERENT CONDITIONS ARE VARIED!
			buff = sprintf(sprint_txt, FILE, mean(unique_azimuth), unique_stim_type, unique_condition(j), unique_condition_2(k), Bias_psy{s,j,k}, Bias_conf{s,j,k}(1), Bias_conf{s,j,k}(2), Thresh_psy{s,j,k}, Thresh_conf{s,j,k}(1), Thresh_conf{s,j,k}(2), mean(correct_pct{s,j,k}), num_reps, norm_rev{t+1});
            fprintf(fid, '%s', buff);
            fprintf(fid, '\r\n');
        end
	end
    
else % ...but needs to change for all three stim types interleaved
    
    s = 1;
    buff = sprintf(sprint_txt, FILE, mean(unique_azimuth), unique_stim_type(s), unique_condition(2), unique_condition_2(1), Bias_psy{s,2,1}, Bias_conf{s,2,1}(1), Bias_conf{s,2,1}(2), Thresh_psy{s,2,1}, Thresh_conf{s,2,1}(1), Thresh_conf{s,2,1}(2), mean(correct_pct{s,2,1}), num_reps, norm_rev{t+1});
    fprintf(fid, '%s', buff);
    fprintf(fid, '\r\n');

    s = 2;
    for k = 1:length(unique_condition_2)
        buff = sprintf(sprint_txt, FILE, mean(unique_azimuth), unique_stim_type(s), unique_condition(2), unique_condition_2(k), Bias_psy{s,2,k}, Bias_conf{s,2,k}(1), Bias_conf{s,2,k}(2), Thresh_psy{s,2,k}, Thresh_conf{s,2,k}(1), Thresh_conf{s,2,k}(2), mean(correct_pct{s,2,k}), num_reps, norm_rev{t+1});
        fprintf(fid, '%s', buff);
        fprintf(fid, '\r\n');
    end
    
    s = 3;
    for j = 1:length(unique_condition)
        for k = 1:length(unique_condition_2)   % MUST CHANGE THESE WHEN DIFFERENT CONDITIONS ARE VARIED!
			buff = sprintf(sprint_txt, FILE, mean(unique_azimuth), unique_stim_type(s), unique_condition(j), unique_condition_2(k), Bias_psy{s,j,k}, Bias_conf{s,j,k}(1), Bias_conf{s,j,k}(2), Thresh_psy{s,j,k}, Thresh_conf{s,j,k}(1), Thresh_conf{s,j,k}(2), mean(correct_pct{s,j,k}), num_reps, norm_rev{t+1});
            fprintf(fid, '%s', buff);
            fprintf(fid, '\r\n');
        end
	end
    
end

fclose(fid);

% lastly, write the predicted/actual weights and thresholds to a separate file
sprint_txt = ['%s\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t']; 
outfile = [BASE_PATH 'ProtocolSpecific\MOOG\HeadingDiscrimination_2I\Psychometric_2I_conflict2.dat'];
createfile = 0;
if (exist(outfile, 'file') == 0)    %file does not yet exist
    createfile = 1;
end
fid = fopen(outfile, 'a');
if (createfile)
    fprintf(fid, 'FILE\t coherence\t Wves_predicted\t Wves_actual_minus\t Wves_actual_plus\t Wves_actual\t thresh_predicted\t thresh_actual_d0\t thresh_actual_all\t thresh_actual_pm\t bias_delta0');
    fprintf(fid, '\r\n');
end
for k = 1:length(unique_condition_2)
	buff = sprintf(sprint_txt, FILE, unique_condition_2(k), Wves_predicted(k), Wves_actual_minus(k), Wves_actual_plus(k), Wves_actual(k), thresh_predicted(k), thresh_actual_d0(k), thresh_actual_all(k), thresh_actual_pm(k), bias_delta0(k));
	fprintf(fid, '%s', buff);
	fprintf(fid, '\r\n');
end
fclose(fid);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% E-Cell output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if e_cell
    e_cell_psy_raw(:,1) = unique_heading;
    e_cell_psy_raw(:,2) = right_pct{2,2,1}';
    e_cell_psy_raw(:,3) = right_pct{2,2,2}';
    e_cell_psy_raw(:,4) = right_pct{1,2,1}';
    e_cell_psy_raw(:,5) = right_pct{3,1,1}';
    e_cell_psy_raw(:,6) = right_pct{3,2,1}';
    e_cell_psy_raw(:,7) = right_pct{3,3,1}';
    e_cell_psy_raw(:,8) = right_pct{3,1,2}';
    e_cell_psy_raw(:,9) = right_pct{3,2,2}';
    e_cell_psy_raw(:,10) = right_pct{3,3,2}';
    
    e_cell_psy_fit(:,1) = xi';
    e_cell_psy_fit(:,2) = cum_gaussfit(psy_perf{2,2,1}, xi)';
    e_cell_psy_fit(:,3) = cum_gaussfit(psy_perf{2,2,2}, xi)';
    e_cell_psy_fit(:,4) = cum_gaussfit(psy_perf{1,2,1}, xi)';
    e_cell_psy_fit(:,5) = cum_gaussfit(psy_perf{3,1,1}, xi)';
    e_cell_psy_fit(:,6) = cum_gaussfit(psy_perf{3,2,1}, xi)';
    e_cell_psy_fit(:,7) = cum_gaussfit(psy_perf{3,3,1}, xi)';
    e_cell_psy_fit(:,8) = cum_gaussfit(psy_perf{3,1,2}, xi)';
    e_cell_psy_fit(:,9) = cum_gaussfit(psy_perf{3,2,2}, xi)';
    e_cell_psy_fit(:,10) = cum_gaussfit(psy_perf{3,3,2}, xi)';
    
    e_cell_neu_raw(:,1) = unique_heading;
    e_cell_neu_raw(:,2) = Neuro_correct{2,2,1}';
    e_cell_neu_raw(:,3) = Neuro_correct{2,2,2}';
    e_cell_neu_raw(:,4) = Neuro_correct{1,2,1}';
    e_cell_neu_raw(:,5) = Neuro_correct{3,1,1}';
    e_cell_neu_raw(:,6) = Neuro_correct{3,2,1}';
    e_cell_neu_raw(:,7) = Neuro_correct{3,3,1}';
    e_cell_neu_raw(:,8) = Neuro_correct{3,1,2}';
    e_cell_neu_raw(:,9) = Neuro_correct{3,2,2}';
    e_cell_neu_raw(:,10) = Neuro_correct{3,3,2}';
    
    e_cell_neu_fit(:,1) = xi';
    e_cell_neu_fit(:,2) = cum_gaussfit(neu_perf{2,2,1}, xi)';
    e_cell_neu_fit(:,3) = cum_gaussfit(neu_perf{2,2,2}, xi)';
    e_cell_neu_fit(:,4) = cum_gaussfit(neu_perf{1,2,1}, xi)';
    e_cell_neu_fit(:,5) = cum_gaussfit(neu_perf{3,1,1}, xi)';
    e_cell_neu_fit(:,6) = cum_gaussfit(neu_perf{3,2,1}, xi)';
    e_cell_neu_fit(:,7) = cum_gaussfit(neu_perf{3,3,1}, xi)';
    e_cell_neu_fit(:,8) = cum_gaussfit(neu_perf{3,1,2}, xi)';
    e_cell_neu_fit(:,9) = cum_gaussfit(neu_perf{3,2,2}, xi)';
    e_cell_neu_fit(:,10) = cum_gaussfit(neu_perf{3,3,2}, xi)';
    

% put breakpoint here to grab e-cell data:
    sprint_txt = ['%s\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%4.3f\t', '%s\t'];
% 
% 	outfile = [BASE_PATH 'ProtocolSpecific\MOOG\HeadingDiscrimination_2I\Psychometric_2I_conflict_ecell.dat'];
% 	createfile = 0;
% 	if (exist(outfile, 'file') == 0)    %file does not yet exist
%         createfile = 1;
% 	end
% 	fid = fopen(outfile, 'a');
% 	if (createfile)
%         fprintf(fid, 'Heading\t PctRightVisLow\t PctRightVisHigh\t PctRightVes\t CombMinusLow\t CombZeroLow\t CombPlusLow\t CombMinusHigh\t CombZeroHigh\t CombPlusHigh\t');
%         fprintf(fid, '\r\n');
%     end
% 
%     for n = 1:length(e_cell_psy_raw(:,1))
%       	buff = sprintf(sprint_txt, e_cell_psy_raw(n,:));
%         fprintf(fid, '%s', buff);
%         fprintf(fid, '\r\n');
%     end
%     
%     for m = 1:length(e_cell_psy_fit(:,1))
%         buff = sprintf(sprint_txt, e_cell_psy_fit(n,:));
%         fprintf(fid, '%s', buff);
%         fprintf(fid, '\r\n');
%     end
%     fclose(fid);
    
end % e_cell


% end % END repeating entire analysis for normal and reversed-interval trials

return;
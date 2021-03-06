%-----------------------------------------------------------------------------------------------------------------------
% PlotVergenceData.m -- Analysis of vergence data for SimDistDispVerg
% paradigm
%-----------------------------------------------------------------------------------------------------------------------

function PlotVergenceData(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);

TEMPO_Defs;

symbols = {'ko' 'r*' 'go' 'mo' 'b*' 'r*' 'g*' 'c*'};
lines = {'k-' 'r--' 'g-' 'm-' 'b--' 'r--' 'g--' 'c--'};

%get the column of values of fixation distances
depth_fix_real = data.dots_params(DEPTH_FIX_REAL,:,PATCH2);

%get indices of any NULL conditions (for measuring spontaneous activity)
null_trials = logical( (depth_fix_real == data.one_time_params(NULL_VALUE)) );

unique_depth_fix_real = munique(depth_fix_real(~null_trials)');

%now, get the firing rates for all the trials
spike_rates = data.spike_rates(SpikeChan, :);

if (data.eye_calib_done)
    eye_positions = data.eye_positions_calibrated;
else
    eye_positions = data.eye_positions;
end

%now, remove trials from hor_disp and spike_rates that do not fall between BegTrial and EndTrial
trials = 1:length(depth_fix_real);		% a vector of trial indices
select_trials = ( (trials >= BegTrial) & (trials <= EndTrial) );

figure;
set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [250 150 500 473], 'Name', 'Vergence analysis');
subplot(2, 1, 2);

%%%DO ANALYSIS AND PLOTTING HERE

depth_fix_real = depth_fix_real(select_trials);
verg_hor = eye_positions(REYE_H, select_trials) - eye_positions(LEYE_H, select_trials);

near_verg_hor = verg_hor(find(depth_fix_real == 28.5));
mid_verg_hor  = verg_hor(find(depth_fix_real == 57));
far_verg_hor  = verg_hor(find(depth_fix_real == 114));

mean_verg_hor = [mean(near_verg_hor) mean(mid_verg_hor) mean(far_verg_hor)];
ideal_verg_hor = [-3.51816 0 1.75908]; %ideal angles according to Tempo, for 28.5 57 114 respectively
diff_verg_hor = mean_verg_hor - ideal_verg_hor;
stddev_verg_hor = [std(near_verg_hor) std(mid_verg_hor) std(far_verg_hor)];


errorbar([28.5 57 114], mean_verg_hor, stddev_verg_hor);
xlabel('fixation distance (cm)');
ylabel('horizontal vergence angle (deg)');
hold on;

str = sprintf('Err(28.5)=%1.2g',diff_verg_hor(1));
text (21, 2.8, str, 'FontSize', 8)
str = sprintf('Err(57)=%1.2g',diff_verg_hor(2));
text (49, 2.8, str, 'FontSize', 8)
str = sprintf('Err(114)=%1.2g',diff_verg_hor(3));
text (100, 2.8, str, 'FontSize', 8)

tol = 0.37310; %Based on 0.75 pseudo-degree wide vergence window.  
%plot lines on the graph marking the targets and the tolerances
line (23:33, ideal_verg_hor(1).*ones(11));
line (25:31, (ideal_verg_hor(1)+tol).*ones(7));
line (25:31, (ideal_verg_hor(1)-tol).*ones(7));
line (52:62, ideal_verg_hor(2).*ones(11));
line (54:60, (ideal_verg_hor(2)+tol).*ones(7));
line (54:60, (ideal_verg_hor(2)-tol).*ones(7));
line (109:119, ideal_verg_hor(3).*ones(11));
line (111:117, (ideal_verg_hor(3)+tol).*ones(7));
line (111:117, (ideal_verg_hor(3)-tol).*ones(7));


hold off;


%now, print out some useful information in the upper subplot
subplot(2, 1, 1);

PrintGeneralData(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);

return;


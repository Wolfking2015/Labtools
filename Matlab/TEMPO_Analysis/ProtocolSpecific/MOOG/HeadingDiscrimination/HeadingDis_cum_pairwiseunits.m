% % isolate more than 2 units from single unit recording data by offline
% spikesorting, analyze clustering structure and noise correlation among
% units --YG, 03/08
% %-----------------------------------------------------------------------------------------------------------------------
function HeadingDis_cum_pairwiseunits_yong(data, Protocol, Analysis, SpikeChan, StartEventBin, StopEventBin, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);
Path_Defs;
ProtocolDefs; %contains protocol specific keywords - 1/4/01 BJP

%get the column of values for azimuth and elevation and stim_type
temp_heading = data.moog_params(HEADING,:,MOOG);
temp_stim_type = data.moog_params(STIM_TYPE,:,MOOG);

%get indices of any NULL conditions (for measuring spontaneous activity
trials = 1:length(temp_heading);
select_trials= ( (trials >= BegTrial) & (trials <= EndTrial) ); 
heading = temp_heading(select_trials);
stim_type = temp_stim_type(select_trials);

unique_heading = munique(heading');
unique_stim_type = munique(stim_type');

% extract channel information
channelnum_temp = size(data.spike_rates);
channelnum = channelnum_temp(1,1); % how many channels

for c = 1 : channelnum - 4 %only use from 5th channel
    temp_spike_rates = data.spike_rates(c+4, :); 
    spike_rates = temp_spike_rates(~null_trials & select_trials);
    spike_rates_channel(c,:) = spike_rates;
    
%     repetition = floor( length(spike_rates) / (1+length(unique_azimuth)*length(unique_stim_type)) ); % take minimum repetition
% 
%     % creat basic matrix represents each response vector
%     resp = [];
%     for k=1:length(unique_stim_type)        
%         for i=1:length(unique_azimuth)
%             select = logical( (azimuth==unique_azimuth(i))  & (stim_type==unique_stim_type(k)) );
%             for j = 1 : repetition; 
%                 spike_temp = spike_rates(select);   
%                 resp_trial{k}(j, i) = spike_temp( j );  
%                 resp_trial_plot{k}(j,i) = resp_trial{k}(j, i);
%                 resp_trial_channel{k,c}(j, i) = resp_trial{k}(j, i);
%             end
%             resp(i, k) = mean(spike_rates(select));        
%             resp_std(i,k) = std(spike_rates(select));        
%             resp_err(i,k) = std(spike_rates(select)) / sqrt(repetition); 
%             
%             % z-score data for spike count correlation analysis
%             z_dist = spike_rates(select);
%             if std(z_dist)~=0 % there are cases that all values are 0 for a certain condition, e.g. m2c73r1, visual condition
%                z_dist = (z_dist - mean(z_dist))/std(z_dist);
%             else
%                 z_dist = 0;
%             end
%             Z_Spikes(select) = z_dist;            
%         end        
%     end    
%     Z_Spikes_channel(c,:) = Z_Spikes;
% 
%     % vectorsum and calculate preferred direction
%     % vectors must be symetric, otherwise there will be a bias both on
%     % preferred direction and the length of resultant vector
%     % the following is to get rid off non-symetric data, hard code temporally
%     if length(unique_azimuth) >8
%         resp_s(1,:) = resp(1,:);
%         resp_s(2,:) = resp(2,:);
%         resp_s(3,:) = resp(4,:);
%         resp_s(4,:) = resp(6,:);
%         resp_s(5,:) = resp(7,:);
%         resp_s(6,:) = resp(8,:);
%         resp_s(7,:) = resp(9,:);
%         resp_s(8,:) = resp(10,:);
%     else
%         resp_s(:,:) = resp(:,:);
%     end
%     unique_azimuth_s(1:8) = [0,45,90,135,180,225,270,315];
%     unique_elevation_s(1:8) = 0;  
%     resp_pair{c}(:,:) = resp(:,:);
%     resp_err_pair{c}(:,:) = resp_err(:,:);
%     
%     for k = 1: length(unique_stim_type)
%         [az(c,k), el(c,k), amp(c,k)] = vectorsumAngle(resp_s(:,k), unique_azimuth_s, unique_elevation_s);
%          p_1D(c,k) = anova1(resp_trial{k},'','off');        
%     end  
%     % congruency between stim type, this is only the regular correlation between two tuning curves 
%     [rr,pp] = corrcoef(resp(:,1),resp(:,2));
%     corrcoef_r_congruency(c) = rr(1,2);
%     corrcoef_p_congruency(c) = pp(1,2);
end
figure(2);
set(2,'Position', [5,15 980,650], 'Name', '1D Direction Tuning');
orient landscape;
set(0, 'DefaultAxesXTickMode', 'auto', 'DefaultAxesYTickMode', 'auto', 'DefaultAxesZTickMode', 'auto');
subplot(2,1,1);
plot(spike_rates_channel(1,:), 'b.');
subplot(2,1,2);
plot(spike_rates_channel(2,:), 'r.');

% now analyze noise correlation between units
pairnum = 0; % 1 comparison for 2 units, 3 comparisons for 3 units, 
for i = 1:channelnum -4-1;
    for j = 1:channelnum -4-i;
        pairnum = pairnum+1; 
        % noise correlation without seperating stim type
        [rr,pp] = corrcoef(Z_Spikes_channel(i,:),Z_Spikes_channel(i+j,:));
        noise_r_all(pairnum) = rr(1,2);
        noise_p_all(pairnum) = pp(1,2);  
        for k=1:length(unique_stim_type) % ananlyze noise correlation in different conditions, if find no difference, combine later
            select_stim = logical( stim_type==unique_stim_type(k) );
            % noise correlation with stim type seperated
            [rr,pp] = corrcoef(Z_Spikes_channel(i,select_stim),Z_Spikes_channel(i+j,select_stim));
            noise_r_stim(pairnum,k) = rr(1,2);
            noise_p_stim(pairnum,k) = pp(1,2);     
            % this is only the regular correlation between two tuning curves
            [rr,pp] = corrcoef(resp_pair{i}(:,k),resp_pair{i+j}(:,k));
            corrcoef_r_unit(pairnum,k) = rr(1,2);
            corrcoef_p_unit(pairnum,k) = pp(1,2);
        end
    end
end

%% ---------------------------------------------------------------------------------------
% Also, write out some summary data to a cumulative summary file
sprint_txt = ['%s\t'];
for i = 1 : 1000
     sprint_txt = [sprint_txt, ' %1.3f\t'];    
end

%buff = sprintf(sprint_txt, FILE, line_re(4,1),line_re(4,2), line_p(4,1),line_p(4,2),line_re_adjusted(4,1),line_re_adjusted(4,2), line_p_adjusted(4,1),line_p_adjusted(4,2) );
buff = sprintf(sprint_txt, FILE, noise_r_stim );

outfile = [BASE_PATH 'ProtocolSpecific\MOOG\HeadingDiscrimination\pairwiseunitsSUMUhighcoherence.dat'];
    
printflag = 0;
if (exist(outfile, 'file') == 0)    %file does not yet exist
    printflag = 1;
end
fid = fopen(outfile, 'a');
if (printflag)
    fprintf(fid, 'FILE\t        ThreshVeMU\t, ThreshViMU\t,ThreshComMU\t,CorrcoefVeSUMU\t,CorrcoefViSUMU\t,CorrcoefComSUMU\t,noiseVe\t,noiseVi\t,noiseCom\t');
    fprintf(fid, '\r\n');
end
fprintf(fid, '%s', buff);
fprintf(fid, '\r\n');
fclose(fid);

%---------------------------------------------------------------------------------------
%--------------------------------------------------------------------------
return;


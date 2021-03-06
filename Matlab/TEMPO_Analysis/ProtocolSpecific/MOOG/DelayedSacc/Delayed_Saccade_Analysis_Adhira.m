function Delayed_Saccade_Analysis_Adhira(data, Protocol, Analysis, SpikeChan, StartEventBin, StopEventBin, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);

TEMPO_Defs;
Path_Defs;
ProtocolDefs;

temp_azimuth = data.moog_params(AZIMUTH,:,MOOG);
temp_elevation = data.moog_params(ELEVATION,:,MOOG);
temp_stim_type = data.moog_params(STIM_TYPE,:,MOOG);
temp_heading   = data.moog_params(HEADING,:,MOOG);
temp_amplitude = data.moog_params(AMPLITUDE,:,MOOG);
temp_num_sigmas = data.moog_params(NUM_SIGMAS,:,MOOG);
temp_total_trials = data.misc_params(OUTCOME,:);
temp_spike_data = data.spike_data(SpikeChan,:);
temp_event_data = data.spike_data(2,:); %2
temp_spike_rates = data.spike_rates(SpikeChan,:);
temp_accel = data.eye_data(5,:,:);
temp_diode = data.eye_data(8,:,:);
temp_eyex = data.eye_data(1,:,:);
temp_eyey = data.eye_data(2,:,:);
accel = reshape(temp_accel, 1000, length(temp_total_trials));
diode = reshape(temp_diode, 1000, length(temp_total_trials));
eyex=reshape(temp_eyex, 1000, length(temp_total_trials));
eyey=reshape(temp_eyey, 1000, length(temp_total_trials));

%now, remove trials from direction and spike_rates that do not fall between BegTrial and EndTrial
trials = 1:length(temp_azimuth);		% vector of trial indices
select_trials = ((trials >= BegTrial) & (trials <= EndTrial));

stim_type = temp_stim_type(trials);
heading = temp_heading(trials);
amplitude= temp_amplitude(trials);
num_sigmas= temp_num_sigmas(trials);
total_trials = temp_total_trials(trials);
spike_rates = temp_spike_rates(trials);
unique_stim_type = munique(stim_type');
unique_heading = munique(heading');
unique_amplitude = munique(amplitude');
unique_num_sigmas = munique(num_sigmas');

% remove null trials, bad trials, and trials outside Begtrial~Engtrial
data_duration = length(temp_spike_data)/length(temp_azimuth); %usually 5000
spike_data_good = temp_spike_data;

% Each column is a new trial
spike_data = reshape(spike_data_good, data_duration, length(trials));
event_data = reshape(temp_event_data, data_duration, length(trials));

% timebin for plot PSTH
timebin=25; %ms
% length of data for each trial - usually 5000
data_length=length(temp_spike_data)/length(temp_total_trials);
% x-axis for PSTH
num_time_bins=1:(5000/timebin);

eye_disp = sqrt((eyex).^2+eyey.^2);
eye_pos = sqrt(diff(eyex).^2+diff(eyey).^2);
eye_vel = diff(eye_pos)/5;
eye_vel_x = diff(eyex)/5;
eye_vel_y = diff(eyey)/5;

%Get the target onset and saccade onset time points for each trial.
for i = 1:length(total_trials)

%     for j = 1:data_length
%         if (diode(j,i) > 2000)
%             targ_on_diode(i) = j*5;
%             break
%         end
%     end

    trial_begin = find(data.event_data(1,:,i) == TRIAL_START_CD);
    trial_over = find(data.event_data(1,:,i) == TRIAL_END_CD);
    stim_start_moog = find(data.event_data(1,:,i) == VSTIM_ON_CD);
    stim_over_moog = find(data.event_data(1,:,i) == SACCADE_BEGIN_CD);
    fix = find(data.event_data(1,:,i) == IN_FIX_WIN_CD);
    sacc_over = find(data.event_data(1,:,i) == SUCCESS_CD);
    if (isempty(trial_begin|trial_over) == 1)
        trial_begin = 1;
        trial_over = 5000;
    end
    trial_start(i)=trial_begin;
    trial_end(i)=trial_over;
    stim_start(i) = stim_start_moog;
    sacc_start(i)=stim_over_moog;
    sacc_end(i)=sacc_over;
    fix_start(i)=fix;

    target_onset_bin(i) = floor(stim_start(i)/timebin) + 1; %Using the photodiode timing instead of tempo
    saccade_onset_bin(i) = floor(sacc_start(i)/timebin) + 1;

    %     figure(10);
    %     plot(5*(fix_start(i)/5:sacc_end(i)/5), eye_pos(fix_start(i)/5:sacc_end(i)/5,i),'k');
    %     pause
    %     hold on

% Using eye velocity determine exact time of saccade onset (again, instead
% of the tempo markers)
%     for j = 1:5000
%         if (eye_vel(j,i) > 1)
%             saccade(i) = j*5;
%             break
%         end
%     end
end

for i = 1:length(total_trials)
    for j = 1:data_length
    if (event_data(j,i) == 1)
        stim_on_pulse(i) = j;
        break
    end
    end
end

%%%% Eye data plots %%%%
% for i = 1:length(total_trials)
% figure(12);
% plot(eyex(floor(fix_start(i)/5):floor(sacc_end(i)/5),i),eyey(floor(fix_start(i)/5):floor(sacc_end(i)/5),i),'k');
% % pause
% hold on
% end
% 
% for k=1: length(unique_heading)
%     figure(k+1)
%     for i=1:length(unique_amplitude)
%         select = logical( (heading==unique_heading(k)) & (amplitude==unique_amplitude(i)) );
%         act_found = find( select==1 );
%         for l = 1:length(act_found)
% %         subplot(length(unique_amplitude),1,i),plot(-500:5:250,eyex(floor(sacc_start(act_found(l))/5)-100:floor(sacc_start(act_found(l))/5)+50,act_found(l)),'k',-500:5:250,eyey(floor(sacc_start(act_found(l))/5)-100:floor(sacc_start(act_found(l))/5)+50,act_found(l)));
%         subplot(length(unique_amplitude),1,i),plot(-500:5:250,eye_vel_x(floor(sacc_start(act_found(l))/5)-100:floor(sacc_start(act_found(l))/5)+50,act_found(l)),'k',-500:5:250,eye_vel_y(floor(sacc_start(act_found(l))/5)-100:floor(sacc_start(act_found(l))/5)+50,act_found(l)));
%         title(['Target position: ', num2str(unique_heading(k))]);
%         legend('Eye velocity x','Eye velocity y');
%         hold on
%         end
%     end
% end
%%%%%%%%%%

%Realign data to target onset and saccade onset

for k=1: length(unique_amplitude)
    for i=1:length(unique_heading)

        select = logical( (heading==unique_heading(i)) & (amplitude==unique_amplitude(k)) );
        act_found = find( select==1 );

        targ_spike_bins{i,k}(:,:) = NaN(length(num_time_bins), length(act_found));
        targ_bin_start = min(target_onset_bin); %align all data to this bin number later
        targ_bin_end = max(target_onset_bin);

        sacc_spike_bins{i,k}(:,:) = NaN(length(num_time_bins), length(act_found));
        sacc_bin_start = min(saccade_onset_bin); %align all data to this bin number later
        sacc_bin_end = max(saccade_onset_bin);

        % Data for Time Bins
        for l = 1:length(act_found)
            % 4. Spike count in __ms time bins in each trial
            for j = 1:length(num_time_bins)
                spike_rate_bins{i,k}(j,l) = (sum(spike_data(timebin*(j-1)+1:timebin*j,act_found(l))))/(timebin/1000); %converted to spikes/s
            end

            % 5. Realign data by target onset and saccade onset
            targ_spike_bins{i,k}(1:targ_bin_start,l) = spike_rate_bins{i,k}((target_onset_bin(act_found(l))-targ_bin_start)+1:target_onset_bin(act_found(l)),l);
            targ_spike_bins{i,k}(targ_bin_start+1:targ_bin_start+length(num_time_bins)-targ_bin_end,l) = spike_rate_bins{i,k}(target_onset_bin(act_found(l))+1:target_onset_bin(act_found(l))+length(num_time_bins)-targ_bin_end,l);

            sacc_spike_bins{i,k}(1:sacc_bin_start,l) = spike_rate_bins{i,k}((saccade_onset_bin(act_found(l))-sacc_bin_start)+1:saccade_onset_bin(act_found(l)),l);
            sacc_spike_bins{i,k}(sacc_bin_start+1:sacc_bin_start+length(num_time_bins)-sacc_bin_end,l) = spike_rate_bins{i,k}(saccade_onset_bin(act_found(l))+1:saccade_onset_bin(act_found(l))+length(num_time_bins)-sacc_bin_end,l);
        end

        % ---------Data for Rasters------------

        targ_spike_raster{i,k}(:,:) = NaN(data_duration, length(act_found));
        targ_raster_start = min(stim_start); %align all data to this later
        targ_raster_end = max(stim_start);

        sacc_spike_raster{i,k}(:,:) = NaN(data_duration, length(act_found));
        sacc_raster_start = min(sacc_start); %align all data to this later
        sacc_raster_end = max(sacc_start);

        %         targ_diode{i,k}(:,:) = NaN(1000, length(act_found));

        for l = 1:length(act_found)

            %             for j = 1:data_duration
            spike_rate_raster{i,k}(:,l) = (spike_data(:,act_found(l)));
%             diode_adj{i,k}(:,l) = diode(:,act_found(l));
            %             end

            targ_spike_raster{i,k}(1:targ_raster_start,l) = spike_rate_raster{i,k}((stim_start(act_found(l))-targ_raster_start)+1:stim_start(act_found(l)),l);
            targ_spike_raster{i,k}(targ_raster_start+1:targ_raster_start+data_duration-targ_raster_end,l) = spike_rate_raster{i,k}(stim_start(act_found(l))+1:stim_start(act_found(l))+data_duration-targ_raster_end,l);

            sacc_spike_raster{i,k}(1:sacc_raster_start,l) = spike_rate_raster{i,k}((sacc_start(act_found(l))-sacc_raster_start)+1:sacc_start(act_found(l)),l);
            sacc_spike_raster{i,k}(sacc_raster_start+1:sacc_raster_start+data_duration-sacc_raster_end,l) = spike_rate_raster{i,k}(sacc_start(act_found(l))+1:sacc_start(act_found(l))+data_duration-sacc_raster_end,l);
% 
%             targ_diode{i,k}(1:targ_raster_start/5,l) = diode_adj{i,k}((targ_on_diode(act_found(l))/5-targ_raster_start/5)+1:targ_on_diode(act_found(l))/5,l);
%             targ_diode{i,k}(targ_raster_start/5+1:targ_raster_start/5+1000-targ_raster_end/5,l) = diode_adj{i,k}(targ_on_diode(act_found(l))/5+1:targ_on_diode(act_found(l))/5+1000-targ_raster_end/5,l);


            % x = data point, y = trial#
            % Multiply the whole data by trial#...
            spike_times_targ{i,k}(:,l) = targ_spike_raster{i,k}(:,l)*l*2;
            spike_times_sacc{i,k}(:,l) = sacc_spike_raster{i,k}(:,l)*l*2;
            spike_raster{i,k}(:,l) = spike_rate_raster{i,k}(:,l)*l*2;

        end
        %----- End rasters-----------

        % Average the spike rates over trials
        targ_average_spikes{i,k} = nanmean(targ_spike_bins{i,k}(:,:),2);
        sacc_average_spikes{i,k} = nanmean(sacc_spike_bins{i,k}(:,:),2);


    end
end

for i = 1:length(unique_heading)
    figure(i+1)
    for j  = 1:length(unique_amplitude)
        select = logical( (heading==unique_heading(i)) & (amplitude==unique_amplitude(j)) );
        act_found = find(select==1);
        for l = 1:length(act_found)
            %Target aligned
            subplot(length(unique_amplitude),2,2*j-1), plot(-50:500,spike_raster{i,j}((stim_start(act_found(l))-50:(stim_start(act_found(l)))+500),l),'k.');
            hold on
            %             subplot(4,2,2*j-1), plot(-100:5:200, .001*diode_adj{i,j}((targ_on_diode(act_found(l))/5-100/5:(targ_on_diode(act_found(l)))/5+200/5),l));
            subplot(length(unique_amplitude),2,2*j-1), plot(-50:timebin:500, targ_average_spikes{i,j}(targ_bin_start-50/timebin:targ_bin_start+500/timebin), 0,1:.5:40,'k');
            set(gca,'ylim',[0 100]);
            xlabel('Target onset');
            ylabel('Spikes/s');
            title(['Amplitude = ', num2str(unique_amplitude(j))]);

            %Tempo Saccade aligned
            subplot(length(unique_amplitude),2,j*2), plot(-300:200, spike_times_sacc{i,j}(sacc_raster_start-300:sacc_raster_start+200,l),'k.');
            hold on
            subplot(length(unique_amplitude),2,j*2), plot(-300:timebin:200,sacc_average_spikes{i,j}(sacc_bin_start-300/timebin:sacc_bin_start+200/timebin), 0,1:.5:40,'k')
            set(gca,'ylim',[0 100]);
            set(gca,'xlim',[-250 150]);
            xlabel('Saccade onset');
            ylabel('Spikes/s');
        end
    end
    ax = axes('position',[0,0,1,1],'visible','off');
    tx = text(0.45,0.95,['Heading = ',num2str(unique_heading(i))]);
    set(tx,'fontweight','bold');
    
    axes('position',[0,0,1,1],'visible','off');
    text(0.88,0.98,StopOffset);
    hold on

end


return;

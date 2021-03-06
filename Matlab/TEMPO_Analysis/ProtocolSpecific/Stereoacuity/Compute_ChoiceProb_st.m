%-----------------------------------------------------------------------------------------------------------------------
%-- Compute_ChoiceProb_st.m -- Uses ROC analysis to compute a choice probability for each different stimulus level
%--	GCD, 5/30/00
%-----------------------------------------------------------------------------------------------------------------------
function Compute_ChoiceProb_st(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);

	TEMPO_Defs;		%defns like IN_T1_WIN_CD
	ProtocolDefs;	%needed for all protocol specific functions - contains keywords - BJP 1/4/01
    Path_Defs;
   
    %disp('computing choice probabilities...');
   
    Pref_HDisp = data.one_time_params(PREFERRED_HDISP);
   
	%get the column of values of horiz. disparities in the dots_params matrix
    h_disp_p1 = data.dots_params(DOTS_HDISP,:,PATCH1);
    unique_hdisp_p1 = munique(h_disp_p1');
   
   	%get the column of values of horiz. disparities in the dots_params matrix
    h_disp_p4 = data.dots_params(DOTS_HDISP,:,PATCH4);
    unique_hdisp_p4 = munique(h_disp_p4');
   
    %compute the unsigned horizontal disparity
    unsigned_hdisp = abs(h_disp_p1-h_disp_p4);
    unsigned_hdisp = (round(10000 * unsigned_hdisp)) / 10000;
    unique_unsigned_hdisp = munique(unsigned_hdisp');
   
    %get the average eye positions to calculate vergence
    if (data.eye_calib_done == 1)
        Leyex_positions = data.eye_positions_calibrated(1, :);
        Leyey_positions = data.eye_positions_calibrated(2, :);
        Reyex_positions = data.eye_positions_calibrated(3, :);
        Reyey_positions = data.eye_positions_calibrated(4, :);
         
        vergence_h = Leyex_positions - Reyex_positions;
        vergence_v = Leyey_positions - Reyey_positions;
    else     
        Leyex_positions = data.eye_positions(1, :);
        Leyey_positions = data.eye_positions(2, :);
        Reyex_positions = data.eye_positions(3, :);
        Reyey_positions = data.eye_positions(4, :);
   
        vergence_h = Leyex_positions - Reyex_positions;
        vergence_v = Leyey_positions - Reyey_positions;
    end
   
    %now, get the firing rates for all the trials 
    spike_rates = data.spike_rates(SpikeChan, :);
    start_offset = -200; % start of calculation relative to stim onset, ms
    window_size = 200;  % window size, ms
    spike_rates = ComputeSpikeRates(data, length(h_disp_p1), StartCode, StartCode, start_offset+30, start_offset+window_size+30);
    spike_rates = spike_rates(1,:);
    
    %get indices of any NULL conditions (for measuring spontaneous activity
    null_trials = logical( (h_disp_p1 == data.one_time_params(NULL_VALUE)) );
   
    %now, select trials that fall between BegTrial and EndTrial
    trials = 1:length(h_disp_p1);		% a vector of trial indices
    select_trials = ( (trials >= BegTrial) & (trials <= EndTrial) );
   
    %now, determine the choice that was made for each trial, PREFERRED or NULL
    %by definition, a preferred choice will be made to Target1 and a null choice to Target 2
    %thus, look for the events IN_T1_WIN_CD and IN_T2_WIN_CD.  GCD, 5/30/2000
    num_trials = length(h_disp_p1);
    PREFERRED = 1;
    NULL = 2;
    for i=1:num_trials
        temp = data.event_data(1,:,i);
        events = temp(temp>0);  % all non-zero entries
        if (sum(events == IN_T1_WIN_CD) > 0)
            choice(i) = PREFERRED;
        elseif (sum(events == IN_T2_WIN_CD) > 0)
            choice(i) = NULL;
        else
            disp('Neither T1 or T2 chosen.  This should not happen!.  File must be bogus.');
        end        
    end
   
    %now, plot the spike distributions, sorted by choice, for each disparity level
    figure;
	set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [50 150 500 473], 'Name', 'Choice Probabilities');
    num_disp = length(unique_hdisp_p1);
    num_unsigned_disp = length(unique_unsigned_hdisp);
    choice_prob = [];
   
    for i=1:num_disp
	    subplot(num_unsigned_disp, 2, i);
	    pref_choices = ( (choice == PREFERRED) & (h_disp_p1 == unique_hdisp_p1(i)) );
   	    pref_dist{i} = spike_rates(pref_choices & select_trials);
	    null_choices = ( (choice == NULL) & (h_disp_p1 == unique_hdisp_p1(i)) );
   	    null_dist{i} = spike_rates(null_choices & select_trials);
         
        %plot the distributions.  This uses a function (in CommonTools) that I wrote.  GCD
        PlotTwoHists(pref_dist{i}, null_dist{i});
         
	    lbl = sprintf('%5.3f deg', unique_hdisp_p1(i)-unique_hdisp_p4(1) );
        ylabel(lbl);
         
        if ( (length(pref_dist{i}) > 0) & (length(null_dist{i}) > 0) )
         	choice_prob(i) = rocN(pref_dist{i}, null_dist{i}, 100);
   	        cp = sprintf('%5.2f', choice_prob(i));
      	    xl = XLim; yl = YLim;
            text(xl(2), yl(2)/2, cp);
        end
    end    
   
    str = sprintf('%s', FILE );
    xlabel(str);
      
    %pref_dist{i} and null_dist{i} are cell arrays that hold the preferred and null choice
    %distributions for each disparity.
    %NOW, we want to Z-score the distributions (preferred and null choices together) and combine across
    %disparities.  GCD, 8/10/00
    for i=1:num_disp
         %for each condition, combine the preferred and null choices into one dist., then find mean and std
         all_choices = []; mean_val = []; std_val = [];
         all_choices = [pref_dist{i}  null_dist{i}];
         mean_val = mean(all_choices);
         std_val = std(all_choices);
         %now use the mean_val and std_val to Z-score the original distributions and store separately
         Z_pref_dist{i} = (pref_dist{i} - mean_val)/std_val;
         Z_null_dist{i} = (null_dist{i} - mean_val)/std_val;         
    end      
   
    %Now, combine data across correlation to get a grand choice probability, and plot distributions again
    figure;
	set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [600 200 400 300], 'Name', 'Grand Choice Probability');
    Zpref_grand = []; Znull_grand = [];
    %combine data across correlations into grand distributions
    for i=1:num_disp
        if (min(length(Z_pref_dist{i}),length(Z_null_dist{i})) / max(length(Z_pref_dist{i}),length(Z_null_dist{i})) > 1/3)
            Zpref_grand = [Zpref_grand Z_pref_dist{i}];   
      	    Znull_grand = [Znull_grand Z_null_dist{i}];   
        end
    end
    PlotTwoHists(Zpref_grand, Znull_grand);
   
    %do permutation test to get P value for grand CP
    [grandCP, grandPval] = ROC_signif_test(Zpref_grand, Znull_grand);
    titl = sprintf('grand CP = %5.2f, P = %6.4f', grandCP, grandPval);
    title(titl);
   
    str = sprintf('%s', FILE );
    xlabel(str);
   
    CORRECT_FOR_VERGENCE = 1;
    if (CORRECT_FOR_VERGENCE)    
        %now, Z-score the spike rates for each signed disparity condition
        %These Z-scored responses will be used to remove the effects of vergence angle
        Z_Spikes = spike_rates;
        for i=1:num_disp        
                select = (h_disp_p1 == unique_hdisp_p1(i));
                z_dist = spike_rates(select);
                z_dist = (z_dist - mean(z_dist))/std(z_dist);
                Z_Spikes(select) = z_dist;           
        end
        %now, get the vergence data for each trial and regress this against Z_Spikes
        X_fit = [ones(length(vergence_h'),1) vergence_h'];
        [b, bint, r, rint, stats] = regress(Z_Spikes', X_fit);
        %stats
    
        figure;
        plot(vergence_h', Z_Spikes', 'ro');
        hold on;
        plot(vergence_h', r, 'go');
        Res_spike_rates = r';
    end

    %Now, combine data across disparities to get a grand choice probability, and plot distributions again
    figure;
	set(gcf,'PaperPosition', [.2 .2 8 10.7], 'Position', [600 200 400 300], 'Name', 'Grand Choice Probability');
    Zpref_grand = []; Znull_grand = [];
    for i=1:num_disp
        pref_choices = ( (choice == PREFERRED) & (h_disp_p1 == unique_hdisp_p1(i)) );
   	    pref_dist{i} = Res_spike_rates(pref_choices & select_trials);
	    null_choices = ( (choice == NULL) & (h_disp_p1 == unique_hdisp_p1(i)) );
   	    null_dist{i} = Res_spike_rates(null_choices & select_trials);
        if (min(length(pref_dist{i}),length(null_dist{i})) / max(length(pref_dist{i}),length(null_dist{i})) > 1/3)
            Zpref_grand = [Zpref_grand pref_dist{i}];   
      	    Znull_grand = [Znull_grand null_dist{i}];   
        end
    end
    PlotTwoHists(Zpref_grand, Znull_grand);
   
    %do permutation test to get P value for grand CP
    [grandCP_reg, grandPval_reg] = ROC_signif_test(Zpref_grand, Znull_grand);
    titl = sprintf('grand CP = %5.2f, P = %6.4f', grandCP_reg, grandPval_reg);
    title(titl);
   
    str = sprintf('%s regress', FILE );
    xlabel(str);
   
    %----------------------------------------------------------------------
    %now print out some summary parameters to a cumulative file
    str = sprintf('%s %6.4f %7.5f %6.4f %7.5f', FILE, grandCP, grandPval, grandCP_reg, grandPval_reg);      
    %disp(str);

    outfile = [BASE_PATH 'ProtocolSpecific\Stereoacuity\CPSummary.dat'];
    printflag = 0;
    if (exist(outfile, 'file') == 0)    %file does not yet exist
        printflag = 1;
    end
    fsummid = fopen(outfile, 'a');
    if (printflag)
        fprintf(fsummid, 'FILE\t\t grandCP\t grandP\t grandCPReg\t grandPReg\t');
        fprintf(fsummid, '\r\n');
        printflag = 0;
    end
    fprintf(fsummid, str);
    fprintf(fsummid, '\r\n');
    fclose(fsummid);

return;
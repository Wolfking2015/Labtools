%-----------------------------------------------------------------------------------------------------------------------
%-- DirectionTuningPlot_3D.m -- Plots response as a function of azimuth and elevation for MOOG 3D tuning expt
%--	GCD, 6/27/03
%-----------------------------------------------------------------------------------------------------------------------
function Direction2d_cue_conflict_fit(data, Protocol, Analysis, SpikeChan, StartCode, StopCode, BegTrial, EndTrial, StartOffset, StopOffset, PATH, FILE);

Path_Defs;
ProtocolDefs; %contains protocol specific keywords - 1/4/01 BJP

%get the column of values for azimuth and elevation and stim_type
temp_azimuth_moog = data.moog_params(HEADING,:,MOOG);
temp_azimuth_cam = data.moog_params(HEADING,:,CAMERAS);
temp_preferred_azimuth = data.moog_params(PREFERRED_AZIMUTH,:,MOOG);
temp_preferred_elevation = data.moog_params(PREFERRED_ELEVATION,:,CAMERAS);
preferred_azimuth = data.one_time_params(PREFERRED_AZIMUTH);
preferred_elevation = data.one_time_params(PREFERRED_ELEVATION);

% Grab coherence value for this experiment.
coherence = data.moog_params(COHERENCE,1,CAMERAS);

%now, get the firing rates for all the trials 
temp_spike_rates = data.spike_rates(SpikeChan, :);                                                                                                                             

%get indices of any NULL conditions (for measuring spontaneous activity
null_trials = logical( (temp_azimuth_moog == data.one_time_params(NULL_VALUE)) & (temp_azimuth_cam == data.one_time_params(NULL_VALUE)) );

% %now, remove trials from direction and spike_rates that do not fall between BegTrial and EndTrial
trials = 1:length(temp_azimuth_moog);		% a vector of trial indices
select_trials= ( (trials >= BegTrial) & (trials <= EndTrial) );

azimuth_moog = temp_azimuth_moog(~null_trials & select_trials);
azimuth_cam = temp_azimuth_cam(~null_trials & select_trials);
% elevation = temp_elevation(~null_trials & select_trials);

spike_rates = temp_spike_rates(~null_trials & select_trials);

unique_azimuth_moog = munique(azimuth_moog');
unique_azimuth_cam = munique(azimuth_cam');
% unique_elevation = munique(elevation');


%% ADD CODE HERE FOR PLOTTING
% create basic matrix represents each response vector    
resp = zeros( length(unique_azimuth_moog) , length(unique_azimuth_cam) );
resp_std = zeros( length(unique_azimuth_moog) , length(unique_azimuth_cam) );
resp_ste = zeros( length(unique_azimuth_moog) , length(unique_azimuth_cam) );
resp_trial = zeros( ...
    sum(select_trials) / ( length(unique_azimuth_moog)*length(unique_azimuth_cam) ), ...
    length(unique_azimuth_moog) , length(unique_azimuth_cam) );
for i=1:length(unique_azimuth_moog)
    for j=1:length(unique_azimuth_cam)
        select = logical( (azimuth_moog==unique_azimuth_moog(i)) & (azimuth_cam==unique_azimuth_cam(j)) );
        if (sum(select) > 0) 
            resp_trial(1:sum(select),i,j) = spike_rates(select);
            resp(i, j) = mean(spike_rates(select));
            resp_std(i,j) = std(spike_rates(select));
%             resp_ste(i,j) = resp_std(i,j) / sqrt(length(find( (azimuth_moog==unique_azimuth_moog(i)) & (azimuth_cam==unique_azimuth_cam(j)) )) );
            resp_ste(i,j) = resp_std(i,j) / sqrt( sum(select) );
        end
    end
end 

% the first one is the conflict dataset
resp_conflict = resp(2:length(unique_azimuth_moog), 2:length(unique_azimuth_cam) );
resp_trial_conflict = resp_trial( :, 2:length(unique_azimuth_moog), 2:length(unique_azimuth_cam) );
% Rearrange resp_trial_conflict for use with the anova2 function.
nrep_anova2 = size( resp_trial_conflict,1 );
% resp_trial_conflict_anova2 = zeros( nrep_anova2 * size( resp_trial_conflict, 3 ) , size( resp_trial_conflict, 2) );
% for i=1:nrep_anova2 % Number of reps
%     for j=1:size( resp_trial_conflict, 2) % MOOG
%         for k=1:size( resp_trial_conflict, 3 ) % cam
%             resp_trial_conflict_anova2( nrep_anova2*(k-1) + i , j ) = ...
%                 resp_trial_conflict(i,j,k);
%         end
%     end
% end
resp_trial_conflict_anova2 = transpose(reshape( permute(resp_trial_conflict,[2 1 3]), ...
    [ size(resp_trial_conflict,2) size(resp_trial_conflict,1)*size(resp_trial_conflict,3)]));

% the second is the moog control
resp_cam = resp( 1, 2 : length(unique_azimuth_cam) );
resp_cam_ste = resp_ste( 1, 2 : length(unique_azimuth_cam) );
resp_trial_cam = squeeze( resp_trial( :, 1, 2 : length(unique_azimuth_cam) ) );
% the third is the camera control
resp_ves = resp( 2:length(unique_azimuth_moog) , 1 );
resp_ves_ste = resp_ste( 2:length(unique_azimuth_moog) , 1 );
resp_trial_ves = squeeze( resp_trial( :, 2:length(unique_azimuth_moog) , 1 ) );

% Extract single cue tuning by averaging across the other motion cue.
% Vestibular
resp_conflict_ves = mean( resp_conflict,2);
% Visual
resp_conflict_vis = mean(resp_conflict',2);

% Compute the p values using ANOVA.
p_anova1_ves = anova1(resp_trial_ves,'','off');
p_anova1_cam = anova1(resp_trial_cam,'','off');
p_anova1_conflict = anova1( ...
    reshape(resp_trial_conflict,...
    [size(resp_trial_conflict,1) size(resp_trial_conflict,2)*size(resp_trial_conflict,3)]) ,...
    '','off');
p_anova2_conflict = anova2( resp_trial_conflict_anova2 , nrep_anova2 , 'off' );

% calculate spontaneous firing rate
spon_found = find(null_trials==1); 
spon_resp = mean(temp_spike_rates(spon_found));

% vector_num = length(unique_azimuth) * (length(unique_elevation)-2) + 2;
% %vector_num = 6 ;
%%

% Calculate center of mass.

% com_vis = mod( atan2( sum( sin( unique_azimuth_cam(2:end)*pi/180 ) .* resp_cam' ) , ...
%     sum( cos( unique_azimuth_cam(2:end)*pi/180 ) .* resp_cam' ) ) ...
%     + 2*pi , 2*pi ) * 180 / pi;
% com_ves = mod( atan2( sum( sin( unique_azimuth_moog(2:end)*pi/180 ) .* resp_ves ) , ...
%     sum( cos( unique_azimuth_moog(2:end)*pi/180 ) .* resp_ves ) ) ...
%     + 2*pi , 2*pi ) * 180 / pi;

[j1,j2]=pol2cart( unique_azimuth_cam(2:end)*pi/180 , resp_cam' );
com_vis=cart2pol( sum(j1), sum(j2) ) * 180/pi;

[j1,j2]=pol2cart( unique_azimuth_moog(2:end)*pi/180 , resp_ves );
com_ves=cart2pol( sum(j1), sum(j2) ) * 180/pi;

[j1,j2]=pol2cart( unique_azimuth_cam(2:end)*pi/180 , resp_conflict_vis );
com_conflict_vis=cart2pol( sum(j1), sum(j2) ) * 180/pi;

[j1,j2]=pol2cart( unique_azimuth_moog(2:end)*pi/180 , resp_conflict_ves );
com_conflict_ves=cart2pol( sum(j1), sum(j2) ) * 180/pi;


%%
% Fit the conflict data based on the two single cue responses. Compare
% different fitting methods.

% Subtract spontaneous rate for fitting.
conflict = resp_conflict - spon_resp;
visual = resp_cam - spon_resp;
vestibular = resp_ves - spon_resp;
% For chi2 testing.
conflict_trial = resp_trial_conflict - spon_resp;

% Turn the single cue data into grids for fitting the 2D conflict array.
[VES,VIS]=ndgrid( vestibular, visual );

% Set a few fitting parameters.
A=[]; B=[]; Aeq=[]; Beq=[]; NONLCON=[];
OPTIONS = optimset('fmincon');
OPTIONS = optimset('LargeScale', 'off', 'LevenbergMarquardt', 'on','MaxIter', 10000, 'Display', 'off');

% % One parameter fit using scaled product of visual and vestibular responses.
% fit1 = @(x) fullfit([ 0 0 0 0 x(1)]);
% error1 = @(x) sum( sum( ( fit1(x) - conflict ).^2 ) );
% es1 = [0.5]; % Initial weights
% LB1 = [-10]; % Weight lower bounds.
% UB1 = [10]; % Weight upper bounds.
% 
% weights1 = fmincon(error1,es1,A,B,Aeq,Beq,LB1,UB1, NONLCON, OPTIONS); % fminsearch
% error1_SSE = error1( weights1 );
% RMS1 = sqrt(error1_SSE) / sqrt( sum(sum( conflict.^2)) );
% prediction1 = fit1(weights1);
% 
% % Two parameter fit using weighted sum of visual and vestibular responses.
% fit2 = @(x) fullfit([ x(1) x(2) 0 0 0 ]);
% error2 = @(x) sum( sum( ( fit2(x) - conflict ).^2 ) );
% es2 = [0.5,0.5]; % Initial weights
% LB2 = [-10,-10]; % Weight lower bounds.
% UB2 = [10,10]; % Weight upper bounds.
% 
% weights2 = fmincon(error2,es2,A,B,Aeq,Beq,LB2,UB2, NONLCON, OPTIONS); % fminsearch
% error2_SSE = error2( weights2 );
% RMS2 = sqrt(error2_SSE) / sqrt( sum(sum( conflict.^2)) );
% prediction2 = fit2(weights2);
% 
% % Three parameter fit using weighted sum of visual and vestibular plus the
% % weighted product of them.
% fit3 = @(x) fullfit([ x(1) x(2) 0 0 x(3) ]);
% error3 = @(x) sum(sum( ( fit3(x) - conflict ).^2 ) );
% es3 = [0.5,0.5,0.5];  
% LB3 = [-10,-10,-10];
% UB3 = [10,10,10];
% 
% weights3 = fmincon(error3,es3,A,B,Aeq,Beq,LB3,UB3, NONLCON, OPTIONS); % fminsearch
% error3_SSE = error3( weights3 );
% RMS3 = sqrt(error3_SSE) / sqrt( sum(sum( conflict.^2)) );
% prediction3 = fit3(weights3);
% 
% % Four parameter fit using squares of single cue responses.
% fit4 = @(x) fullfit([ x(1) x(2) x(3) x(4) 0]);
% error4 = @(x)sum(sum( ( fit4(x) - conflict ).^2 ) );
% es4 = [0.5,0.5,0.5,0.5];  
% LB4 = [-10,-10,-10,-10];
% UB4 = [10,10,10,10];
% 
% weights4 = fmincon(error4,es4,A,B,Aeq,Beq,LB4,UB4, NONLCON, OPTIONS); % fminsearch
% error4_SSE = error4( weights4 );
% RMS4 = sqrt(error4_SSE) / sqrt( sum(sum( conflict.^2)) );
% prediction4 = fit4(weights4);
% 
% % Five parameter fit using squares and product of single cue responses.
% fit5 = @(x) fullfit(x);
% error5 = @(x)sum(sum( ( fit5(x) - conflict ).^2 ) );
% es5 = [0.5,0.5,0.5,0.5,0.5];  
% LB5 = [-10,-10,-10,-10,-10];
% UB5 = [10,10,10,10,10];
% 
% weights5 = fmincon(error5,es5,A,B,Aeq,Beq,LB5,UB5, NONLCON, OPTIONS); % fminsearch
% error5_SSE = error5( weights5 );
% RMS5 = sqrt(error5_SSE) / sqrt( sum(sum( conflict.^2)) );
% prediction5 = fit5(weights5);

% Define the most number of parameters to feed to the model.
minparams = 1;
maxparams = 6;

% Define the full fit function with linear, second order and interaction terms.
fullfit = @(w) w(1) + w(2)*VES + w(3)*VIS + w(4)*VES.^2 + w(5)*VIS.^2 + w(6)*(VES.*VIS);

% Define a related function for chi2 testing
% It takes a complex index x and a weight vector w.
fullfit_chi2 = @(x,w) subsref( fullfit(w), ...
    struct('type','()','subs', {{ sub2ind( size(VES), real(x),imag(x)) }} ) );

% Create an array used to test versions of this model with some
% coefficients set to zero.
fitselect = zeros(maxparams,maxparams,(maxparams-minparams+1));
% For the 1 parameter fit, select only the constant.
fitselect(1,1,1) = 1;
% For the 2 parameter fit, select only the constant and the cross term.
fitselect(1,1,2) = 1;
fitselect(2,6,2) = 1;
% For the 3 parameter fit, select only the constant and the two linear terms.
fitselect(1,1,3) = 1;
fitselect(2,2,3) = 1;
fitselect(3,3,3) = 1;
% For the 4 parameter fit, select the constant, the two linear terms and the cross term.
fitselect(1,1,4) = 1;
fitselect(2,2,4) = 1;
fitselect(3,3,4) = 1;
fitselect(4,6,4) = 1;
% For the 5 parameter fit, select the constant, the two linear terms and the squared terms.
fitselect(1,1,5) = 1;
fitselect(2,2,5) = 1;
fitselect(3,3,5) = 1;
fitselect(4,4,5) = 1;
fitselect(5,5,5) = 1;
% For the 6 parameter fit, select all terms.
fitselect(:,:,maxparams) = eye(maxparams);

clear weights error_SSE error_SST error_R2 RMS prediction chi2 chiP maxerr
for i=minparams:maxparams
    
    fit = @(w) fullfit( w * fitselect(1:i, : , i ) );
    fit_chi2 = @(x,w) fullfit_chi2( x, w * fitselect(1:i, : , i ) );
    sse = @(w) sum(sum( ( fit(w) - conflict ).^2 ) );
    es = 0.5 * ones(1,i);
    LB = -100 * ones(1,i);
    UB = 100 * ones(1,i);
    
    weights{i} = fmincon(sse,es,A,B,Aeq,Beq,LB,UB, NONLCON, OPTIONS); % fminsearch
    error_SSE{i} = sse( weights{i} );
    error_SST{i} = sum(sum( ( conflict - mean(mean( conflict ) ) ).^2 ) );
    error_R2{i} = 1 - error_SSE{i} / error_SST{i};
    RMS{i} = sqrt( error_SSE{i} ) / sqrt( sum(sum ( conflict.^2 ) ) );
    prediction{i} = fit( weights{i} );
    maxerr{i} = max( max( abs( conflict - prediction{i} ) ) );
    
    %[chi2, chiP] = Chi2_Test(datax, datay, funcname, params, num_free_params)
    [datax1,datax2]=ndgrid( 1:size(VES,1) , 1:size(VES,2) );
    datax = zeros(size(conflict_trial));
    for j=1:size(datax,1)
        datax(j,:,:) = shiftdim( datax1 + sqrt(-1) * datax2 , -1 );
    end
    datax=reshape(datax,[prod(size(conflict_trial)) 1]);
    [chi2{i}, chiP{i}] = Chi2_Test_MLM( datax, reshape(conflict_trial,[prod(size(conflict_trial)) 1]),...
        fit_chi2, weights{i}, i );
%     [chi2{i}, chiP{i}] = Chi2_Test( datax, reshape(conflict_trial,[prod(size(conflict_trial)) 1]),...
%         'fit_chi2', struct('func',fullfit_chi2,'weights',weights{i}*fitselect(1:i, : , i )) , i );
%     % chi-squared calculations
%     chi2{i} = sum(sum( ( conflict - prediction{i} ).^2 ./ prediction{i} ));
%     p_chi2gof{i} = 1 - chi2cdf( chi2{i} , ( prod(size(conflict)) - i ) );
    
end

% Do sequential F tests to compare fits with more parameters to the two
% parameter linear combination fit.

% I think that 64 is correct as the number of heading pairs, but I should
% double check with the bosses.

% % 3 weights versus 2 weights
% F_3_2 = ( (error2_SSE - error3_SSE) / ( length(weights3) - length(weights2) ) ) / ...
%     ( error3_SSE / ( prod(size(conflict)) - length(weights3) ) );
% P_3_2 = 1 - fcdf( F_3_2 , ( length(weights3) - length(weights2) ) , ( prod(size(conflict)) - length(weights3) ) );

% Compare each model to models with fewer coefficients.
for j=2:maxparams
    for i=1:(j-1)
                
        F{j,i} = ( ( error_SSE{i} - error_SSE{j} ) / ...
            ( ( j - i ) ) ) / ...
            ( error_SSE{j} / ( prod(size(conflict)) - j ) );
        P{j,i} = 1 - fcdf( F{j,i} , ...
            ( j - i ) , ...
            ( prod(size(conflict)) - j ) );

%         % Convert the number of parameters to strings.
%         is=num2str(i);
%         js=num2str(j);
%         % Compute the F statistic.
%         eval([ 'F_' js '_' is '=  ' ...
%             '( (error' is '_SSE - error' js '_SSE) / ' ...
%             '( length(weights' js ') - length(weights' is ') ) ) /' ...
%             '( error' js '_SSE / ( prod(size(conflict)) - length(weights' js ') ) );' ]);
%         % Get the corresponding P value for the F statistic.
%         eval([ 'P_' js '_' is '= 1 - fcdf( F_' js '_' is ' , '...
%             '( length(weights' js ') - length(weights' is ') ) , ' ...
%             '( prod(size(conflict)) - length(weights' js ') ) );' ]);
        
    end
end
%%

% Fit diagonals of data. In other words, fit each conflict angle
% separately.

% Rearrange trial-by-trial data for fitting.
ydata_all=zeros( size(resp_trial,1) , size(resp_trial,2)-1 , size(resp_trial,3)-1 );

thetas=unique_azimuth_cam(2:end);

% Loop through all visual motion directions
for k=1:(length(unique_azimuth_cam)-1)

    % Loop through all conflict angles
    for l=1:(length(unique_azimuth_cam)-1)

        % Calculate the visual motion direction.
        vist=(k-1)*45;
        % Calculate the conflict angle for ves_angle - vis_angle.
        conflictt=(l-1)*45;
        % Calculate the corresponding vestibular motion direction.
        vest= mod( vist + conflictt , 360 );

        ydata_all( :, k, l ) = ...
            resp_trial( :, unique_azimuth_moog == vest , unique_azimuth_cam == vist );

    end

end

ydata_all = ydata_all - spon_resp;

clear weights_d error_SSE_d error_SST_d error_R2_d RMS_d prediction_d maxerr_d chi2_d chiP_d
% Now loop through the conflict angles.
for n=1:size(ydata_all,3)

    % Shift the vestibular function used for fitting to match the conflict
    % angle.
    vestibular_r = circshift( vestibular, n-1 )';
    % Grab only the data for this conflict angle.
    conflict_r = squeeze( mean( ydata_all(:,:,n) ) );
    conflict_trial_r = ydata_all(:,:,n);

    % Define the full fit function with linear, second order and interaction terms.
    fullfit = @(w) w(1) + ...
        w(2)*vestibular_r + w(3)*visual + ...
        w(4)*vestibular_r.^2 + w(5)*visual.^2 + ...
        w(6)*(vestibular_r.*visual);

    % Define a related function for chi2 testing
    % It takes a complex index x and a weight vector w.
    fullfit_chi2 = @(x,w) subsref( fullfit(w), ...
        struct('type','()','subs', {{ sub2ind( size(vestibular_r), real(x),imag(x)) }} ) );

    for i=minparams:maxparams

        fit = @(w) fullfit( w * fitselect(1:i, : , i ) );
        fit_chi2 = @(x,w) fullfit_chi2( x, w * fitselect(1:i, : , i ) );
        sse = @(w) sum(sum( ( fit(w) - conflict_r ).^2 ) );
        es = 0.5 * ones(1,i);
        LB = -100 * ones(1,i);
        UB = 100 * ones(1,i);

        weights_d{n,i} = fmincon(sse,es,A,B,Aeq,Beq,LB,UB, NONLCON, OPTIONS); % fminsearch
        error_SSE_d{n,i} = sse( weights_d{n,i} );
        error_SST_d{n,i} = sum(sum( ( conflict_r - mean(mean( conflict_r ) ) ).^2 ) );
        error_R2_d{n,i} = 1 - error_SSE_d{n,i} / error_SST_d{n,i};
        RMS_d{n,i} = sqrt( error_SSE_d{n,i} ) / sqrt( sum(sum ( conflict_r.^2 ) ) );
        prediction_d{n,i} = fit( weights_d{n,i} );
        maxerr_d{n,i} = max( max( abs( conflict_r - prediction_d{n,i} ) ) );

        %[chi2, chiP] = Chi2_Test(datax, datay, funcname, params, num_free_params)
        %[datax1,datax2]=ndgrid( 1:size(VES,1) , 1:size(VES,2) );
        datax = zeros(size(conflict_trial_r));
        for j=1:size(datax,1)
            datax(j,:) = 1 + (1:size(conflict_trial_r,2)) * sqrt(-1);
        end
        datax=reshape(datax,[prod(size(conflict_trial_r)) 1]);
        [chi2_d{n,i}, chiP_d{n,i}] = Chi2_Test_MLM( ...
            datax, reshape(conflict_trial_r,[prod(size(conflict_trial_r)) 1]),...
            fit_chi2, weights_d{n,i}, i );
        %     [chi2{i}, chiP{i}] = Chi2_Test( datax, reshape(conflict_trial,[prod(size(conflict_trial)) 1]),...
        %         'fit_chi2', struct('func',fullfit_chi2,'weights',weights{i}*fitselect(1:i, : , i )) , i );
        %     % chi-squared calculations
        %     chi2{i} = sum(sum( ( conflict - prediction{i} ).^2 ./ prediction{i} ));
        %     p_chi2gof{i} = 1 - chi2cdf( chi2{i} , ( prod(size(conflict)) - i ) );

    end

%     figure(5);
%     subplot(3,1,1);
%     plot( thetas, vestibular_r );
%     subplot(3,1,2);
%     plot( thetas, visual );
%     subplot(3,1,3);
%     i=3; % Look at the linear sum fit.
%     fit = @(w) fullfit( w * fitselect(1:i, : , i ) );
%     plot( thetas, fit( weights_d{n,i} ), '-', thetas, conflict_trial, '.' );
%     pause;

    % Compare each model to models with fewer coefficients.
    for j=(minparams+1):maxparams
        for i=minparams:(j-1)

            F_d{n,j,i} = ( ( error_SSE_d{n,i} - error_SSE_d{n,j} ) / ...
                ( ( j - i ) ) ) / ...
                ( error_SSE_d{n,j} / ( prod(size(conflict_r)) - j ) );
            P_d{n,j,i} = 1 - fcdf( F_d{n,j,i} , ...
                ( j - i ) , ...
                ( prod(size(conflict_r)) - j ) );

            %         % Convert the number of parameters to strings.
            %         is=num2str(i);
            %         js=num2str(j);
            %         % Compute the F statistic.
            %         eval([ 'F_' js '_' is '=  ' ...
            %             '( (error' is '_SSE - error' js '_SSE) / ' ...
            %             '( length(weights' js ') - length(weights' is ') ) ) /' ...
            %             '( error' js '_SSE / ( prod(size(conflict)) - length(weights' js ') ) );' ]);
            %         % Get the corresponding P value for the F statistic.
            %         eval([ 'P_' js '_' is '= 1 - fcdf( F_' js '_' is ' , '...
            %             '( length(weights' js ') - length(weights' is ') ) , ' ...
            %             '( prod(size(conflict)) - length(weights' js ') ) );' ]);

        end
    end
    
end

%%

%------------------------------------------------------------------
% Define figure

figure(2);
clf(2,'reset');
set(2,'Position', [5,15 1200,900], 'Name', '3D Direction Tuning');

axes('position',[0.05,0.3,0.6,0.55]);
%contourf( unique_azimuth_moog(2:end) , unique_azimuth_cam(2:end) , resp_conflict );
contourf(unique_azimuth_cam(2:end), ...
    unique_azimuth_moog(2:end), ...
    resp_conflict(:,:)' );
h_cont=gca;
% The transpose is because x varies with column number and y varies with
% row number. I also plotted axes x=camera and y=moog.

% xlim([0 315]);
% ylim([0 315]);
ylabel('visual')
set(gca,'xlim', [ min(unique_azimuth_moog(2:end)) max(unique_azimuth_moog(2:end)) ], ...
    'ylim', [ min(unique_azimuth_cam(2:end)) max(unique_azimuth_cam(2:end)) ],...
    'xtick', unique_azimuth_cam(2:end),...
    'xticklabel',round(unique_azimuth_cam(2:end)),...
    'ytick', unique_azimuth_moog(2:end),...
    'yticklabel',round(unique_azimuth_moog(2:end)) );
text( max(get(gca,'xlim')), max(get(gca,'ylim')),...
    sprintf('ANOVA1 p=%0.5g  ANOVA2 p_{vestibular}=%0.4g p_{visual}=%0.4g p_{interaction}=%0.4g',...
    p_anova1_conflict,p_anova2_conflict(1),p_anova2_conflict(2),p_anova2_conflict(3)),...
    'HorizontalAlignment','right','VerticalAlignment','bottom');

% set(gca,'xtick',unique_azimuth_moog(2:end),'ytick',unique_azimuth_cam(2:end));
colorbar;
%view(90,270);

% x_axis = 0:45:315;
% Along the bottom (x-axis) of the contour plot, plot the moog-only
% control.
axes('position',[0.05,0.05,0.6,0.2]);
errorbar( unique_azimuth_moog(2:end) , resp_ves(:,:), resp_ves_ste(:,:) , 'o-');
set(gca,'xlim',[ min(unique_azimuth_moog(2:end)) max(unique_azimuth_moog(2:end)) ],...
    'xtick',unique_azimuth_moog(2:end) );
xlabel('vestibular');
set(gca,'xticklabel',round(unique_azimuth_moog(2:end)));
% Set width to match contour map.
pos_ves=get(gca,'position');
pos_cont=get(h_cont,'position');
set(gca,'position', [ pos_cont(1) pos_ves(2) pos_cont(3) pos_ves(4) ]);
% errorbar(x_axis,resp_cam , resp_cam_ste,  'o-');
% set(gca, 'xtick',[0,45,90,135,180,225,270,315]);
% xlabel('visual');
% xlim([0,315]);
text( max(get(gca,'xlim')), max(get(gca,'ylim')),...
    sprintf('COM=%0.1f ANOVA p=%0.5g',com_ves,p_anova1_ves),...
    'HorizontalAlignment','right','VerticalAlignment','top');

% To the right (y-axis) of the contour plot, plot the visual-only control.
axes('position',[0.7,0.3,0.2,0.55]);
errorbar( unique_azimuth_cam(2:end), resp_cam(:,:) , resp_cam_ste(:,:) , 'o-');
set(gca,'xlim',[ min(unique_azimuth_cam(2:end)) max(unique_azimuth_cam(2:end)) ], ...
    'xtick',unique_azimuth_cam(2:end),...
    'xticklabel',round(unique_azimuth_cam(2:end)),...
    'XAxisLocation','top');
xlabel('visual');
% Set position to align with contour map.
pos_cam=get(gca,'position');
pos_cont=get(h_cont,'position');
set(gca,'position', [ pos_cam(1) pos_cont(2) pos_cam(3) pos_cont(4) ]);
% errorbar(x_axis, resp_ves, resp_ves_ste, 'o-');
% xlim([0,315]);
%plot(resp_ves(:,:) , 'o-');
% set(gca, 'xtick',[0,45,90,135,180,225,270,315]);
view(90,270);
% xlabel('vestibular');
text( min(get(gca,'xlim')), max(get(gca,'ylim')),...
    sprintf('COM=%0.1f ANOVA p=%0.5g',com_vis,p_anova1_cam),...
    'HorizontalAlignment','right','VerticalAlignment','top','rotation',270)

% % calculate min and max firing rate, standard deviation, DSI, Vectorsum
% Min_resp(k) = min( min( resp_mat_tran(k,:,:)) );
% Max_resp(k) = max( max( resp_mat_tran(k,:,:)) );
% resp_std(k) = sum( sum(resp_mat_std(k,:,:)) ) / vector_num;  % notice that do not use mean here, its 26 vectors intead of 40
% M=squeeze(resp_mat(k,:,:));     % notice that here DSI should use resp_temp without 0 value set manually
% DSI_temp(k) = DSI(M,spon_resp,resp_std(k));
% N=squeeze(resp_mat(k,:,:));      % notice that here vectorsum should use resp_mat with 0 value set manually 
% [Azi, Ele, Amp] =vectorsum(N);
% Vec_sum{k}=[Azi, Ele, Amp];

% %-------------------------------------------------------------------
% %check significance of DSI and calculate p value
% perm_num=1000;
% bin = 0.005;
% spike_rates_perm = [];
% for n=1: perm_num 
%     for k=1:length(unique_condition_num)   
%         spike_rates_pe{k} = spike_rates( find( condition_num==unique_condition_num(k) ) );
%         spike_rates_pe{k} = spike_rates_pe{k}( randperm(length(spike_rates_pe{k})) );
%         spike_rates_perm=[spike_rates_perm,spike_rates_pe{k}];            % get the permuted spikerate to re-calculate DSI for each condition
%     end
% 
%     % re-creat a matrix similar as resp_mat              
%     resp_vector_perm = [];
%     for i=1:length(unique_azimuth)
%         for j=1:length(unique_elevation)
%             for k=1:length(unique_condition_num)
%                 select = logical( (azimuth==unique_azimuth(i)) & (elevation==unique_elevation(j)) & (condition_num==unique_condition_num(k)) );
%                 if (sum(select) > 0)
%                     resp_mat_perm(k,j,i) = mean(spike_rates_perm(select));
%                     resp_mat_perm_std(k,j,i) = std(spike_rates_perm(select));
%                 else
%                     resp_mat_perm(k,j,i) = 0;
%                     resp_mat_perm_std(k,j,i) = 0;
%                 end
%             end        
%         end
%     end
%     % re-calculate DSI now
%     for k=1: length(unique_condition_num)
%         resp_perm_std(k) = sum( sum(resp_mat_perm_std(k,:,:)) ) / vector_num; 
%         M_perm=squeeze(resp_mat_perm(k,:,:));
%         DSI_perm(k,n) = DSI(M_perm, spon_resp, resp_perm_std(k) );
%     end
%     
% end
% x_bin = 0 : bin : 1;
% for k = 1 : length(unique_condition_num)
%     histo(k,:) = hist( DSI_perm(k,:), x_bin );
%     bin_sum = 0;
%     n = 0;
%     while ( n < (DSI_temp(k)/bin) )
%           n = n+1;
%           bin_sum = bin_sum + histo(k, n);
%           p{k} = (perm_num - bin_sum)/ perm_num;    % calculate p value
%     end 
% end

%------------------------------------------------------------------

% Now show vectorsum, DSI, p and spontaneous at the top of figure
h_title{1}='conflict';
h_title{2}='vestibular';
h_title{3}='visual';
axes('position',[0.05,0.9, 0.9,0.05] );
xlim( [0,100] );
ylim( [0,3] );
h_spon = num2str(spon_resp);
text(0, 3, FILE);
text(15,3,'Spon');
text(30,3,'pre-azi');
text(35,3,'pre-ele');
for k=1:3
    h_text{k}=num2str( [spon_resp ] );
    text(0,3-k,h_title{k});
    text(15,3-k, h_text{k} );    
end
text(30, 0, num2str( preferred_azimuth ));
text(35, 0, num2str( preferred_elevation ));

axis off;

%---------------------------------------------------------------------------------------
%Also, write out some summary data to a cumulative summary file

% buff = sprintf('%s\t %4.2f\t   %4.3f\t   %4.3f\t   %4.3f\t   %4.3f\t  %4.3f\t  %4.3f\t  %6.3f\t  %6.3f\t  %6.3f\t  %6.3f\t  %6.3f\t  %6.3f\t  %6.3f\t  %6.3f\t  %6.3f\t  %2.4f\t  %2.4f\t  %2.4f\t  %1.3f\t  %1.3f\t  %1.3f\t  %2.4f\t  %2.4f\t  %2.4f\t', ...
%      FILE, spon_resp, Min_resp, Max_resp, Vec_sum{:}, DSI_temp, p{:} , resp_std );
% outfile = [BASE_PATH 'ProtocolSpecific\MOOG\DirectionTuningSum.dat'];
% printflag = 0;
% if (exist(outfile, 'file') == 0)    %file does not yet exist
%     printflag = 1;
% end
% fid = fopen(outfile, 'a');
% if (printflag)
%     fprintf(fid, 'FILE\t         SPon\t Veb_min\t Vis_min\t Comb_min\t Veb_max\t Vis_max\t Comb_max\t Veb_azi\t Veb_ele\t Veb_amp\t Vis_azi\t Vis_ele\t Vis_amp\t Comb_azi\t Comb_ele\t Comb_amp\t Veb_DSI\t Vis_DSI\t Comb_DSI\t Veb_P\t Vis_P\t Comb_P\t Veb_std\t Vis_std\t Comb_std\t');
%     fprintf(fid, '\r\n');
% end
% fprintf(fid, '%s', buff);
% fprintf(fid, '\r\n');
% fclose(fid);
% 
%---------------------------------------------------------------------------------------

% Plot model fits.
figure(3);
h1=subplot(6,2,1);
contourf(unique_azimuth_cam(2:end), ...
    unique_azimuth_moog(2:end), ...
    conflict' );
set(gca,'xlim', [ min(unique_azimuth_moog(2:end)) max(unique_azimuth_moog(2:end)) ], ...
    'ylim', [ min(unique_azimuth_cam(2:end)) max(unique_azimuth_cam(2:end)) ],...
    'xtick', unique_azimuth_cam(2:end),...
    'xticklabel',round(unique_azimuth_cam(2:end)),...
    'ytick', unique_azimuth_moog(2:end),...
    'yticklabel',round(unique_azimuth_moog(2:end)) );
colorbar;
title('Mean responses');

% Put the file name on there.
h2=subplot(6,2,3);
axis([0 1 -1 1]);
text(0, 0, FILE);
axis('off');

% Rescale subplots
pos1=get(h1,'position');
pos2=get(h2,'position');
set(h1,'position', [ pos1(1) pos1(2)-pos2(4)/2 pos1(3) pos1(4)+pos2(4)/2 ]);
set(h2,'position', [ pos2(1) pos2(2) pos2(3) pos2(4)*0.75 ]);
    
% Which subplots will hold graphs and which will hold values.
subgraph =  [2 5 6 9 10];
subvalues = [4 7 8 11 12];

for k=1:5
    h1=subplot(6,2, subgraph(k) );
    contourf(unique_azimuth_cam(2:end), ...
        unique_azimuth_moog(2:end), ...
        prediction{k}' );
    set(gca,'xlim', [ min(unique_azimuth_moog(2:end)) max(unique_azimuth_moog(2:end)) ], ...
        'ylim', [ min(unique_azimuth_cam(2:end)) max(unique_azimuth_cam(2:end)) ],...
        'xtick', unique_azimuth_cam(2:end),...
        'xticklabel',round(unique_azimuth_cam(2:end)),...
        'ytick', unique_azimuth_moog(2:end),...
        'yticklabel',round(unique_azimuth_moog(2:end)) );
    colorbar;
    title([num2str(k) ' parameter(s)']);
    
    % Print values on a plot below.
    h2=subplot(6,2,subvalues(k));
    axis([-1 3 -5 1])

    % error RMS
    text(2,0,'RMS');
    text(3,0,sprintf('%g',RMS{k}));

    % error SSE
    text(2,-1,'SSE');
    text(3,-1,sprintf('%g',error_SSE{k}));
    
    % error R^2
    text(2,-2,'R^2');
    text(3,-2,sprintf('%g',error_R2{k}));
    
    % chi-squared
    text(2,-3,'\chi^2');
    text(3,-3,sprintf('%g',chi2{k}));
    
    % chi-squared p value
    text(2,-4,'p_{\chi^2}');
    text(3,-4,sprintf('%g',chiP{k}));

    % p values compared to other models
    text(1,0,'p');
    for m=1:(k-1)
        text(1,-m, sprintf('%0.3g',P{k,m}));
    end
    
    % weights
    text(0,0,'weights');
    for m=1:k
        text(0,-m, sprintf('%0.3g',weights{k}(m)));
    end
    
    % labels
    for m=1:k
        text(-1,-m,sprintf('%g',m));
    end

    axis('off');
    
    % Rescale subplots
    pos1=get(h1,'position');
    pos2=get(h2,'position');
    set(h1,'position', [ pos1(1) pos1(2)-pos2(4)/2 pos1(3) pos1(4)+pos2(4)/2 ]);
    set(h2,'position', [ pos2(1) pos2(2) pos2(3) pos2(4)*0.75 ]);

end

% Make it big for printing.
set(3,'PaperPositionMode','manual','PaperPosition',[0 0 8.5 11]);
%%

save([BASE_PATH 'ProtocolSpecific\MOOG\Cueconflict2D\mat\fit\' FILE(1:end-4) '-' num2str(StartOffset) 'to' num2str(StopOffset) '.mat'], ...
    'FILE', 'coherence', 'nrep_anova2', ...
    'p_anova1_ves', 'p_anova1_cam', 'p_anova1_conflict', ...
    'p_anova2_conflict',...
    'com_ves', 'com_vis', 'com_conflict_ves', 'com_conflict_vis', ...
    'error_SSE', 'error_R2', 'chi2', 'chiP', 'RMS', 'maxerr', 'weights', ...
    'error_SSE_d', 'error_R2_d', 'chi2_d', 'chiP_d', 'RMS_d', 'maxerr_d', 'weights_d', ...
    'azimuth_cam','azimuth_moog',...
    'resp',...
    'resp_cam','resp_cam_ste',...
    'resp_conflict',...
    'resp_conflict_ves','resp_conflict_vis',...
    'resp_std','resp_ste',...
    'resp_trial','resp_trial_cam','resp_trial_conflict','resp_trial_ves',...
    'resp_ves','resp_ves_ste',...
    'spon_resp',...
    'unique_azimuth_cam','unique_azimuth_moog');

%%

% Write important values to a file.
sprint_txt = ['%s\t'];
for i = 1 : 500 % this should be large enough to cover all the data that need to be exported
     sprint_txt = [sprint_txt, ' %g\t'];   
end

outfile = [BASE_PATH 'ProtocolSpecific\MOOG\Cueconflict2D\ModelFit.dat'];
printflag = 0;
if (exist(outfile, 'file') == 0)    %file does not yet exist
    printflag = 1;
end
fid = fopen(outfile, 'a');
if (printflag)   % change headings here if diff conditions varied
    fprintf(fid, 'FILE\t coherence\t ntrials\t nreps\t ');
    fprintf(fid, 'p_anova1_ves\t p_anova1_vis\t p_anova1_conflict\t p_anova2_ves\t p_anova2_vis\t p_anova2_interaction\t ');
    fprintf(fid, 'com_ves\t com_vis\t com_conflict_ves\t com_conflict_vis\t ');
    fprintf(fid, 'model1_SSE\t model1_R2\t model1_chi2\t model1_chiP\t model1_RMS\t model1_maxerr\t model1_weight\t ');
    fprintf(fid, 'model2_SSE\t model2_R2\t model2_chi2\t model2_chiP\t model2_RMS\t model2_maxerr\t P_2_1\t model2_weight1\t model2_weight2\t ');
    fprintf(fid, 'model3_SSE\t model3_R2\t model3_chi2\t model3_chiP\t model3_RMS\t model3_maxerr\t P_3_1\t P_3_2\t model3_weight1\t model3_weight2\t model3_weight3\t ');
    fprintf(fid, 'model4_SSE\t model4_R2\t model4_chi2\t model4_chiP\t model4_RMS\t model4_maxerr\t P_4_1\t P_4_2\t P_4_3\t model4_weight1\t model4_weight2\t model4_weight3\t model4_weight4\t ');
    fprintf(fid, 'model5_SSE\t model5_R2\t model5_chi2\t model5_chiP\t model5_RMS\t model5_maxerr\t P_5_1\t P_5_2\t P_5_3\t P_5_4\t model5_weight1\t model5_weight2\t model5_weight3\t model5_weight4\t model5_weight5\t ');
    fprintf(fid, 'model1_SSE_d0\t model1_R2_d0\t model1_chi2_d0\t model1_chiP_d0\t model1_RMS_d0\t model1_maxerr_d0\t model1_weight_d0\t ');
    fprintf(fid, 'model2_SSE_d0\t model2_R2_d0\t model2_chi2_d0\t model2_chiP_d0\t model2_RMS_d0\t model2_maxerr_d0\t P_2_1_d0\t model2_weight1_d0\t model2_weight2_d0\t ');
    fprintf(fid, 'model3_SSE_d0\t model3_R2_d0\t model3_chi2_d0\t model3_chiP_d0\t model3_RMS_d0\t model3_maxerr_d0\t P_3_1_d0\t P_3_2_d0\t model3_weight1_d0\t model3_weight2_d0\t model3_weight3_d0\t ');
    fprintf(fid, 'model4_SSE_d0\t model4_R2_d0\t model4_chi2_d0\t model4_chiP_d0\t model4_RMS_d0\t model4_maxerr_d0\t P_4_1_d0\t P_4_2_d0\t P_4_3_d0\t model4_weight1_d0\t model4_weight2_d0\t model4_weight3_d0\t model4_weight4_d0\t ');
    fprintf(fid, 'model5_SSE_d0\t model5_R2_d0\t model5_chi2_d0\t model5_chiP_d0\t model5_RMS_d0\t model5_maxerr_d0\t P_5_1_d0\t P_5_2_d0\t P_5_3_d0\t P_5_4_d0\t model5_weight1_d0\t model5_weight2_d0\t model5_weight3_d0\t model5_weight4_d0\t model5_weight5_d0\t ');
    fprintf(fid, 'model1_SSE_d45\t model1_R2_d45\t model1_chi2_d45\t model1_chiP_d45\t model1_RMS_d45\t model1_maxerr_d45\t model1_weight_d45\t ');
    fprintf(fid, 'model2_SSE_d45\t model2_R2_d45\t model2_chi2_d45\t model2_chiP_d45\t model2_RMS_d45\t model2_maxerr_d45\t P_2_1_d45\t model2_weight1_d45\t model2_weight2_d45\t ');
    fprintf(fid, 'model3_SSE_d45\t model3_R2_d45\t model3_chi2_d45\t model3_chiP_d45\t model3_RMS_d45\t model3_maxerr_d45\t P_3_1_d45\t P_3_2_d45\t model3_weight1_d45\t model3_weight2_d45\t model3_weight3_d45\t ');
    fprintf(fid, 'model4_SSE_d45\t model4_R2_d45\t model4_chi2_d45\t model4_chiP_d45\t model4_RMS_d45\t model4_maxerr_d45\t P_4_1_d45\t P_4_2_d45\t P_4_3_d45\t model4_weight1_d45\t model4_weight2_d45\t model4_weight3_d45\t model4_weight4_d45\t ');
    fprintf(fid, 'model5_SSE_d45\t model5_R2_d45\t model5_chi2_d45\t model5_chiP_d45\t model5_RMS_d45\t model5_maxerr_d45\t P_5_1_d45\t P_5_2_d45\t P_5_3_d45\t P_5_4_d45\t model5_weight1_d45\t model5_weight2_d45\t model5_weight3_d45\t model5_weight4_d45\t model5_weight5_d45\t ');
    fprintf(fid, 'model1_SSE_d90\t model1_R2_d90\t model1_chi2_d90\t model1_chiP_d90\t model1_RMS_d90\t model1_maxerr_d90\t model1_weight_d90\t ');
    fprintf(fid, 'model2_SSE_d90\t model2_R2_d90\t model2_chi2_d90\t model2_chiP_d90\t model2_RMS_d90\t model2_maxerr_d90\t P_2_1_d90\t model2_weight1_d90\t model2_weight2_d90\t ');
    fprintf(fid, 'model3_SSE_d90\t model3_R2_d90\t model3_chi2_d90\t model3_chiP_d90\t model3_RMS_d90\t model3_maxerr_d90\t P_3_1_d90\t P_3_2_d90\t model3_weight1_d90\t model3_weight2_d90\t model3_weight3_d90\t ');
    fprintf(fid, 'model4_SSE_d90\t model4_R2_d90\t model4_chi2_d90\t model4_chiP_d90\t model4_RMS_d90\t model4_maxerr_d90\t P_4_1_d90\t P_4_2_d90\t P_4_3_d90\t model4_weight1_d90\t model4_weight2_d90\t model4_weight3_d90\t model4_weight4_d90\t ');
    fprintf(fid, 'model5_SSE_d90\t model5_R2_d90\t model5_chi2_d90\t model5_chiP_d90\t model5_RMS_d90\t model5_maxerr_d90\t P_5_1_d90\t P_5_2_d90\t P_5_3_d90\t P_5_4_d90\t model5_weight1_d90\t model5_weight2_d90\t model5_weight3_d90\t model5_weight4_d90\t model5_weight5_d90\t ');
    fprintf(fid, 'model1_SSE_d135\t model1_R2_d135\t model1_chi2_d135\t model1_chiP_d135\t model1_RMS_d135\t model1_maxerr_d135\t model1_weight_d135\t ');
    fprintf(fid, 'model2_SSE_d135\t model2_R2_d135\t model2_chi2_d135\t model2_chiP_d135\t model2_RMS_d135\t model2_maxerr_d135\t P_2_1_d135\t model2_weight1_d135\t model2_weight2_d135\t ');
    fprintf(fid, 'model3_SSE_d135\t model3_R2_d135\t model3_chi2_d135\t model3_chiP_d135\t model3_RMS_d135\t model3_maxerr_d135\t P_3_1_d135\t P_3_2_d135\t model3_weight1_d135\t model3_weight2_d135\t model3_weight3_d135\t ');
    fprintf(fid, 'model4_SSE_d135\t model4_R2_d135\t model4_chi2_d135\t model4_chiP_d135\t model4_RMS_d135\t model4_maxerr_d135\t P_4_1_d135\t P_4_2_d135\t P_4_3_d135\t model4_weight1_d135\t model4_weight2_d135\t model4_weight3_d135\t model4_weight4_d135\t ');
    fprintf(fid, 'model5_SSE_d135\t model5_R2_d135\t model5_chi2_d135\t model5_chiP_d135\t model5_RMS_d135\t model5_maxerr_d135\t P_5_1_d135\t P_5_2_d135\t P_5_3_d135\t P_5_4_d135\t model5_weight1_d135\t model5_weight2_d135\t model5_weight3_d135\t model5_weight4_d135\t model5_weight5_d135\t ');
    fprintf(fid, 'model1_SSE_d180\t model1_R2_d180\t model1_chi2_d180\t model1_chiP_d180\t model1_RMS_d180\t model1_maxerr_d180\t model1_weight_d180\t ');
    fprintf(fid, 'model2_SSE_d180\t model2_R2_d180\t model2_chi2_d180\t model2_chiP_d180\t model2_RMS_d180\t model2_maxerr_d180\t P_2_1_d180\t model2_weight1_d180\t model2_weight2_d180\t ');
    fprintf(fid, 'model3_SSE_d180\t model3_R2_d180\t model3_chi2_d180\t model3_chiP_d180\t model3_RMS_d180\t model3_maxerr_d180\t P_3_1_d180\t P_3_2_d180\t model3_weight1_d180\t model3_weight2_d180\t model3_weight3_d180\t ');
    fprintf(fid, 'model4_SSE_d180\t model4_R2_d180\t model4_chi2_d180\t model4_chiP_d180\t model4_RMS_d180\t model4_maxerr_d180\t P_4_1_d180\t P_4_2_d180\t P_4_3_d180\t model4_weight1_d180\t model4_weight2_d180\t model4_weight3_d180\t model4_weight4_d180\t ');
    fprintf(fid, 'model5_SSE_d180\t model5_R2_d180\t model5_chi2_d180\t model5_chiP_d180\t model5_RMS_d180\t model5_maxerr_d180\t P_5_1_d180\t P_5_2_d180\t P_5_3_d180\t P_5_4_d180\t model5_weight1_d180\t model5_weight2_d180\t model5_weight3_d180\t model5_weight4_d180\t model5_weight5_d180\t ');
    fprintf(fid, 'model1_SSE_d225\t model1_R2_d225\t model1_chi2_d225\t model1_chiP_d225\t model1_RMS_d225\t model1_maxerr_d225\t model1_weight_d225\t ');
    fprintf(fid, 'model2_SSE_d225\t model2_R2_d225\t model2_chi2_d225\t model2_chiP_d225\t model2_RMS_d225\t model2_maxerr_d225\t P_2_1_d225\t model2_weight1_d225\t model2_weight2_d225\t ');
    fprintf(fid, 'model3_SSE_d225\t model3_R2_d225\t model3_chi2_d225\t model3_chiP_d225\t model3_RMS_d225\t model3_maxerr_d225\t P_3_1_d225\t P_3_2_d225\t model3_weight1_d225\t model3_weight2_d225\t model3_weight3_d225\t ');
    fprintf(fid, 'model4_SSE_d225\t model4_R2_d225\t model4_chi2_d225\t model4_chiP_d225\t model4_RMS_d225\t model4_maxerr_d225\t P_4_1_d225\t P_4_2_d225\t P_4_3_d225\t model4_weight1_d225\t model4_weight2_d225\t model4_weight3_d225\t model4_weight4_d225\t ');
    fprintf(fid, 'model5_SSE_d225\t model5_R2_d225\t model5_chi2_d225\t model5_chiP_d225\t model5_RMS_d225\t model5_maxerr_d225\t P_5_1_d225\t P_5_2_d225\t P_5_3_d225\t P_5_4_d225\t model5_weight1_d225\t model5_weight2_d225\t model5_weight3_d225\t model5_weight4_d225\t model5_weight5_d225\t ');
    fprintf(fid, 'model1_SSE_d270\t model1_R2_d270\t model1_chi2_d270\t model1_chiP_d270\t model1_RMS_d270\t model1_maxerr_d270\t model1_weight_d270\t ');
    fprintf(fid, 'model2_SSE_d270\t model2_R2_d270\t model2_chi2_d270\t model2_chiP_d270\t model2_RMS_d270\t model2_maxerr_d270\t P_2_1_d270\t model2_weight1_d270\t model2_weight2_d270\t ');
    fprintf(fid, 'model3_SSE_d270\t model3_R2_d270\t model3_chi2_d270\t model3_chiP_d270\t model3_RMS_d270\t model3_maxerr_d270\t P_3_1_d270\t P_3_2_d270\t model3_weight1_d270\t model3_weight2_d270\t model3_weight3_d270\t ');
    fprintf(fid, 'model4_SSE_d270\t model4_R2_d270\t model4_chi2_d270\t model4_chiP_d270\t model4_RMS_d270\t model4_maxerr_d270\t P_4_1_d270\t P_4_2_d270\t P_4_3_d270\t model4_weight1_d270\t model4_weight2_d270\t model4_weight3_d270\t model4_weight4_d270\t ');
    fprintf(fid, 'model5_SSE_d270\t model5_R2_d270\t model5_chi2_d270\t model5_chiP_d270\t model5_RMS_d270\t model5_maxerr_d270\t P_5_1_d270\t P_5_2_d270\t P_5_3_d270\t P_5_4_d270\t model5_weight1_d270\t model5_weight2_d270\t model5_weight3_d270\t model5_weight4_d270\t model5_weight5_d270\t ');
    fprintf(fid, 'model1_SSE_d315\t model1_R2_d315\t model1_chi2_d315\t model1_chiP_d315\t model1_RMS_d315\t model1_maxerr_d315\t model1_weight_d315\t ');
    fprintf(fid, 'model2_SSE_d315\t model2_R2_d315\t model2_chi2_d315\t model2_chiP_d315\t model2_RMS_d315\t model2_maxerr_d315\t P_2_1_d315\t model2_weight1_d315\t model2_weight2_d315\t ');
    fprintf(fid, 'model3_SSE_d315\t model3_R2_d315\t model3_chi2_d315\t model3_chiP_d315\t model3_RMS_d315\t model3_maxerr_d315\t P_3_1_d315\t P_3_2_d315\t model3_weight1_d315\t model3_weight2_d315\t model3_weight3_d315\t ');
    fprintf(fid, 'model4_SSE_d315\t model4_R2_d315\t model4_chi2_d315\t model4_chiP_d315\t model4_RMS_d315\t model4_maxerr_d315\t P_4_1_d315\t P_4_2_d315\t P_4_3_d315\t model4_weight1_d315\t model4_weight2_d315\t model4_weight3_d315\t model4_weight4_d315\t ');
    fprintf(fid, 'model5_SSE_d315\t model5_R2_d315\t model5_chi2_d315\t model5_chiP_d315\t model5_RMS_d315\t model5_maxerr_d315\t P_5_1_d315\t P_5_2_d315\t P_5_3_d315\t P_5_4_d315\t model5_weight1_d315\t model5_weight2_d315\t model5_weight3_d315\t model5_weight4_d315\t model5_weight5_d315\t ');
    fprintf(fid, '\r\n');
end
buff = sprintf( sprint_txt, ...
    FILE, coherence, prod(size(select_trials)), nrep_anova2, ...
    p_anova1_ves, p_anova1_cam, p_anova1_conflict, ...
    p_anova2_conflict(1),p_anova2_conflict(2),p_anova2_conflict(3),...
    com_ves, com_vis, com_conflict_ves, com_conflict_vis, ...
    error_SSE{1}, error_R2{1}, chi2{1}, chiP{1}, RMS{1}, maxerr{1}, weights{1}(1), ...
    error_SSE{2}, error_R2{2}, chi2{2}, chiP{2}, RMS{2}, maxerr{2}, P{2,1}, weights{2}(1), weights{2}(2), ...
    error_SSE{3}, error_R2{3}, chi2{3}, chiP{3}, RMS{3}, maxerr{3}, P{3,1}, P{3,2}, weights{3}(1), weights{3}(2), weights{3}(3), ...
    error_SSE{4}, error_R2{4}, chi2{4}, chiP{4}, RMS{4}, maxerr{4}, P{4,1}, P{4,2}, P{4,3}, weights{4}(1), weights{4}(2), weights{4}(3), weights{4}(4), ...
    error_SSE{5}, error_R2{5}, chi2{5}, chiP{5}, RMS{5}, maxerr{5}, P{5,1}, P{5,2}, P{5,3}, P{5,4}, weights{5}(1), weights{5}(2), weights{5}(3), weights{5}(4), weights{5}(5), ...
    error_SSE_d{1,1}, error_R2_d{1,1}, chi2_d{1,1}, chiP_d{1,1}, RMS_d{1,1}, maxerr_d{1,1}, weights_d{1,1}(1), ...
    error_SSE_d{1,2}, error_R2_d{1,2}, chi2_d{1,2}, chiP_d{1,2}, RMS_d{1,2}, maxerr_d{1,2}, P_d{1,2,1}, weights_d{1,2}(1), weights_d{1,2}(2), ...
    error_SSE_d{1,3}, error_R2_d{1,3}, chi2_d{1,3}, chiP_d{1,3}, RMS_d{1,3}, maxerr_d{1,3}, P_d{1,3,1}, P_d{1,3,2}, weights_d{1,3}(1), weights_d{1,3}(2), weights_d{1,3}(3), ...
    error_SSE_d{1,4}, error_R2_d{1,4}, chi2_d{1,4}, chiP_d{1,4}, RMS_d{1,4}, maxerr_d{1,4}, P_d{1,4,1}, P_d{1,4,2}, P_d{1,4,3}, weights_d{1,4}(1), weights_d{1,4}(2), weights_d{1,4}(3), weights_d{1,4}(4), ...
    error_SSE_d{1,5}, error_R2_d{1,5}, chi2_d{1,5}, chiP_d{1,5}, RMS_d{1,5}, maxerr_d{1,5}, P_d{1,5,1}, P_d{1,5,2}, P_d{1,5,3}, P_d{1,5,4}, weights_d{1,5}(1), weights_d{1,5}(2), weights_d{1,5}(3), weights_d{1,5}(4), weights_d{1,5}(5), ...
    error_SSE_d{2,1}, error_R2_d{2,1}, chi2_d{2,1}, chiP_d{2,1}, RMS_d{2,1}, maxerr_d{2,1}, weights_d{2,1}(1), ...
    error_SSE_d{2,2}, error_R2_d{2,2}, chi2_d{2,2}, chiP_d{2,2}, RMS_d{2,2}, maxerr_d{2,2}, P_d{2,2,1}, weights_d{2,2}(1), weights_d{2,2}(2), ...
    error_SSE_d{2,3}, error_R2_d{2,3}, chi2_d{2,3}, chiP_d{2,3}, RMS_d{2,3}, maxerr_d{2,3}, P_d{2,3,1}, P_d{2,3,2}, weights_d{2,3}(1), weights_d{2,3}(2), weights_d{2,3}(3), ...
    error_SSE_d{2,4}, error_R2_d{2,4}, chi2_d{2,4}, chiP_d{2,4}, RMS_d{2,4}, maxerr_d{2,4}, P_d{2,4,1}, P_d{2,4,2}, P_d{2,4,3}, weights_d{2,4}(1), weights_d{2,4}(2), weights_d{2,4}(3), weights_d{2,4}(4), ...
    error_SSE_d{2,5}, error_R2_d{2,5}, chi2_d{2,5}, chiP_d{2,5}, RMS_d{2,5}, maxerr_d{2,5}, P_d{2,5,1}, P_d{2,5,2}, P_d{2,5,3}, P_d{2,5,4}, weights_d{2,5}(1), weights_d{2,5}(2), weights_d{2,5}(3), weights_d{2,5}(4), weights_d{2,5}(5), ...
    error_SSE_d{3,1}, error_R2_d{3,1}, chi2_d{3,1}, chiP_d{3,1}, RMS_d{3,1}, maxerr_d{3,1}, weights_d{3,1}(1), ...
    error_SSE_d{3,2}, error_R2_d{3,2}, chi2_d{3,2}, chiP_d{3,2}, RMS_d{3,2}, maxerr_d{3,2}, P_d{3,2,1}, weights_d{3,2}(1), weights_d{3,2}(2), ...
    error_SSE_d{3,3}, error_R2_d{3,3}, chi2_d{3,3}, chiP_d{3,3}, RMS_d{3,3}, maxerr_d{3,3}, P_d{3,3,1}, P_d{3,3,2}, weights_d{3,3}(1), weights_d{3,3}(2), weights_d{3,3}(3), ...
    error_SSE_d{3,4}, error_R2_d{3,4}, chi2_d{3,4}, chiP_d{3,4}, RMS_d{3,4}, maxerr_d{3,4}, P_d{3,4,1}, P_d{3,4,2}, P_d{3,4,3}, weights_d{3,4}(1), weights_d{3,4}(2), weights_d{3,4}(3), weights_d{3,4}(4), ...
    error_SSE_d{3,5}, error_R2_d{3,5}, chi2_d{3,5}, chiP_d{3,5}, RMS_d{3,5}, maxerr_d{3,5}, P_d{3,5,1}, P_d{3,5,2}, P_d{3,5,3}, P_d{3,5,4}, weights_d{3,5}(1), weights_d{3,5}(2), weights_d{3,5}(3), weights_d{3,5}(4), weights_d{3,5}(5), ...
    error_SSE_d{4,1}, error_R2_d{4,1}, chi2_d{4,1}, chiP_d{4,1}, RMS_d{4,1}, maxerr_d{4,1}, weights_d{4,1}(1), ...
    error_SSE_d{4,2}, error_R2_d{4,2}, chi2_d{4,2}, chiP_d{4,2}, RMS_d{4,2}, maxerr_d{4,2}, P_d{4,2,1}, weights_d{4,2}(1), weights_d{4,2}(2), ...
    error_SSE_d{4,3}, error_R2_d{4,3}, chi2_d{4,3}, chiP_d{4,3}, RMS_d{4,3}, maxerr_d{4,3}, P_d{4,3,1}, P_d{4,3,2}, weights_d{4,3}(1), weights_d{4,3}(2), weights_d{4,3}(3), ...
    error_SSE_d{4,4}, error_R2_d{4,4}, chi2_d{4,4}, chiP_d{4,4}, RMS_d{4,4}, maxerr_d{4,4}, P_d{4,4,1}, P_d{4,4,2}, P_d{4,4,3}, weights_d{4,4}(1), weights_d{4,4}(2), weights_d{4,4}(3), weights_d{4,4}(4), ...
    error_SSE_d{4,5}, error_R2_d{4,5}, chi2_d{4,5}, chiP_d{4,5}, RMS_d{4,5}, maxerr_d{4,5}, P_d{4,5,1}, P_d{4,5,2}, P_d{4,5,3}, P_d{4,5,4}, weights_d{4,5}(1), weights_d{4,5}(2), weights_d{4,5}(3), weights_d{4,5}(4), weights_d{4,5}(5), ...
    error_SSE_d{5,1}, error_R2_d{5,1}, chi2_d{5,1}, chiP_d{5,1}, RMS_d{5,1}, maxerr_d{5,1}, weights_d{5,1}(1), ...
    error_SSE_d{5,2}, error_R2_d{5,2}, chi2_d{5,2}, chiP_d{5,2}, RMS_d{5,2}, maxerr_d{5,2}, P_d{5,2,1}, weights_d{5,2}(1), weights_d{5,2}(2), ...
    error_SSE_d{5,3}, error_R2_d{5,3}, chi2_d{5,3}, chiP_d{5,3}, RMS_d{5,3}, maxerr_d{5,3}, P_d{5,3,1}, P_d{5,3,2}, weights_d{5,3}(1), weights_d{5,3}(2), weights_d{5,3}(3), ...
    error_SSE_d{5,4}, error_R2_d{5,4}, chi2_d{5,4}, chiP_d{5,4}, RMS_d{5,4}, maxerr_d{5,4}, P_d{5,4,1}, P_d{5,4,2}, P_d{5,4,3}, weights_d{5,4}(1), weights_d{5,4}(2), weights_d{5,4}(3), weights_d{5,4}(4), ...
    error_SSE_d{5,5}, error_R2_d{5,5}, chi2_d{5,5}, chiP_d{5,5}, RMS_d{5,5}, maxerr_d{5,5}, P_d{5,5,1}, P_d{5,5,2}, P_d{5,5,3}, P_d{5,5,4}, weights_d{5,5}(1), weights_d{5,5}(2), weights_d{5,5}(3), weights_d{5,5}(4), weights_d{5,5}(5), ...
    error_SSE_d{6,1}, error_R2_d{6,1}, chi2_d{6,1}, chiP_d{6,1}, RMS_d{6,1}, maxerr_d{6,1}, weights_d{6,1}(1), ...
    error_SSE_d{6,2}, error_R2_d{6,2}, chi2_d{6,2}, chiP_d{6,2}, RMS_d{6,2}, maxerr_d{6,2}, P_d{6,2,1}, weights_d{6,2}(1), weights_d{6,2}(2), ...
    error_SSE_d{6,3}, error_R2_d{6,3}, chi2_d{6,3}, chiP_d{6,3}, RMS_d{6,3}, maxerr_d{6,3}, P_d{6,3,1}, P_d{6,3,2}, weights_d{6,3}(1), weights_d{6,3}(2), weights_d{6,3}(3), ...
    error_SSE_d{6,4}, error_R2_d{6,4}, chi2_d{6,4}, chiP_d{6,4}, RMS_d{6,4}, maxerr_d{6,4}, P_d{6,4,1}, P_d{6,4,2}, P_d{6,4,3}, weights_d{6,4}(1), weights_d{6,4}(2), weights_d{6,4}(3), weights_d{6,4}(4), ...
    error_SSE_d{6,5}, error_R2_d{6,5}, chi2_d{6,5}, chiP_d{6,5}, RMS_d{6,5}, maxerr_d{6,5}, P_d{6,5,1}, P_d{6,5,2}, P_d{6,5,3}, P_d{6,5,4}, weights_d{6,5}(1), weights_d{6,5}(2), weights_d{6,5}(3), weights_d{6,5}(4), weights_d{6,5}(5), ...
    error_SSE_d{7,1}, error_R2_d{7,1}, chi2_d{7,1}, chiP_d{7,1}, RMS_d{7,1}, maxerr_d{7,1}, weights_d{7,1}(1), ...
    error_SSE_d{7,2}, error_R2_d{7,2}, chi2_d{7,2}, chiP_d{7,2}, RMS_d{7,2}, maxerr_d{7,2}, P_d{7,2,1}, weights_d{7,2}(1), weights_d{7,2}(2), ...
    error_SSE_d{7,3}, error_R2_d{7,3}, chi2_d{7,3}, chiP_d{7,3}, RMS_d{7,3}, maxerr_d{7,3}, P_d{7,3,1}, P_d{7,3,2}, weights_d{7,3}(1), weights_d{7,3}(2), weights_d{7,3}(3), ...
    error_SSE_d{7,4}, error_R2_d{7,4}, chi2_d{7,4}, chiP_d{7,4}, RMS_d{7,4}, maxerr_d{7,4}, P_d{7,4,1}, P_d{7,4,2}, P_d{7,4,3}, weights_d{7,4}(1), weights_d{7,4}(2), weights_d{7,4}(3), weights_d{7,4}(4), ...
    error_SSE_d{7,5}, error_R2_d{7,5}, chi2_d{7,5}, chiP_d{7,5}, RMS_d{7,5}, maxerr_d{7,5}, P_d{7,5,1}, P_d{7,5,2}, P_d{7,5,3}, P_d{7,5,4}, weights_d{7,5}(1), weights_d{7,5}(2), weights_d{7,5}(3), weights_d{7,5}(4), weights_d{7,5}(5), ...
    error_SSE_d{8,1}, error_R2_d{8,1}, chi2_d{8,1}, chiP_d{8,1}, RMS_d{8,1}, maxerr_d{8,1}, weights_d{8,1}(1), ...
    error_SSE_d{8,2}, error_R2_d{8,2}, chi2_d{8,2}, chiP_d{8,2}, RMS_d{8,2}, maxerr_d{8,2}, P_d{8,2,1}, weights_d{8,2}(1), weights_d{8,2}(2), ...
    error_SSE_d{8,3}, error_R2_d{8,3}, chi2_d{8,3}, chiP_d{8,3}, RMS_d{8,3}, maxerr_d{8,3}, P_d{8,3,1}, P_d{8,3,2}, weights_d{8,3}(1), weights_d{8,3}(2), weights_d{8,3}(3), ...
    error_SSE_d{8,4}, error_R2_d{8,4}, chi2_d{8,4}, chiP_d{8,4}, RMS_d{8,4}, maxerr_d{8,4}, P_d{8,4,1}, P_d{8,4,2}, P_d{8,4,3}, weights_d{8,4}(1), weights_d{8,4}(2), weights_d{8,4}(3), weights_d{8,4}(4), ...
    error_SSE_d{8,5}, error_R2_d{8,5}, chi2_d{8,5}, chiP_d{8,5}, RMS_d{8,5}, maxerr_d{8,5}, P_d{8,5,1}, P_d{8,5,2}, P_d{8,5,3}, P_d{8,5,4}, weights_d{8,5}(1), weights_d{8,5}(2), weights_d{8,5}(3), weights_d{8,5}(4), weights_d{8,5}(5) ...
    );
fprintf(fid, '%s', buff);
fprintf(fid, '\r\n');
fclose(fid);

return;
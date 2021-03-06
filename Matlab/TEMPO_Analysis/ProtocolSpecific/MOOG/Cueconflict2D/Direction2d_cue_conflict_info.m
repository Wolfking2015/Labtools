%-----------------------------------------------------------------------------------------------------------------------
%-- Direction2d_cue_conflict_info.m -- Fit tuning curves and perform
%information anaylsis
%--	MLM, 8/8/2007
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


%%

% Rearrange trial-by-trial data for fitting.
ydata_all=zeros( size(resp_trial,1) , size(resp_trial,2)-1 , size(resp_trial,3)-1 + 2);

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


% Tack on vestibular only.
ydata_all(:,:,end-1) = resp_trial_ves;
% Tack on visual only
ydata_all(:,:,end) = resp_trial_cam;

%%

% Calculate a fit to the data.

X0_all=zeros( 6, size(ydata_all,3) );
X_all=zeros( 6, size(ydata_all,3) );
yfit_all=zeros( length(unique_azimuth_moog(2:end)) , size(ydata_all,3) );

% options = optimset('MaxFunEvals', 10000, 'MaxIter', 5000, 'LargeScale', 'off', 'LevenbergMarquardt', 'on', 'Display', 'off');
options = optimset('MaxFunEvals', 5000, 'MaxIter', 1000, 'LargeScale', 'off', 'LevenbergMarquardt', 'on', 'Display', 'off');
A = []; b = []; Aeq = []; beq = []; nonlcon = [];

xdata = unique_azimuth_moog(2:end) * pi / 180;

% Define the function for fitting.
% Function #4: Charlie Special (variant wrapped gaussian that can also be sinusoidal)
% 6 params: X = [A mu sigma K K-sig DC]

fit = @(X) X(1) * ( exp(-2*(1-cos(xdata-X(2)))/(X(5)*X(3))^2) + ...
    X(4)*exp(-2*(1-cos(xdata-X(2)-pi))/X(3)^2) ) + X(6);

% model = ' Charlie Special ';
% 16 params:
% X = [ A1  mu-s  sigma1  K1  K_sig1  DC1
%       A2  mu    sigma2  K2  K_sig2  DC2
%       A3  mu+s  sigma3  K3  K_sig3  DC3  ], where s = 22.5 for eye
%       and 0 for head

% Loop through all single cue and all offsets for combined.
for n=1:size(ydata_all,3)

    ydata=ydata_all(:,:,n);
    % Define the error in the fit based on the  current data.
    sse = @(X) sum(sum( ( ones(size(ydata,1),1) * reshape(fit(X),1,prod(size(xdata))) - ydata ).^2 ) );

    LB = [ 0.001 -2*pi pi/6 0 0.5 0 ];   % lower bounds

    UB = [ 1.5*(max(max(ydata)) - min(min(ydata))) 2*pi 2*pi 0.95 0.95 0.8*max(max(ydata)) ];   % upper bounds

    % initial parameter guesses
    X0 = [];

    % A = peak-trough modulation
    X0(1) = max(max(ydata)) - min(min(ydata));
    if X0(1) < 1
        X0(1) = 1;
    end

    % mu = azimuth of max response
    [junk1,junk2] = find( ydata == max(max(ydata)) );
    max_azi = xdata( junk2(1) );
    X0(2) = max_azi;

    % DC = min response
    X0(6) = min(min(ydata));

    % search for best starting values of sigma, K, and K-sig
    N = 40;
    min_err = 9999999999999999.99;
    x3range = LB(3) : (UB(3)-LB(3))/N : UB(3);
    x4range = LB(4) : (UB(4)-LB(4))/N : UB(4);
    x5range = LB(5) : (UB(5)-LB(5))/N : UB(5);
    for i = 1:N
        x3temp = x3range(i);
        if x3temp == 0
            x3temp = 0.0001;
        end
        for j = 1:N
            x4temp = x4range(j);
            for h = 1:N
                x5temp = x5range(h);
                if x5temp == 0
                    x5temp = 0.0001;
                end
                x_temp = [X0(1) X0(2) x3temp x4temp x5temp X0(6)];
                error = sse(x_temp);
                if (error < min_err)
                    x3min = x3temp; x4min = x4temp; x5min = x5temp;
                    min_err = error;
                end
            end
        end
    end
    X0(3) = x3min; X0(4) = x4min; X0(5) = x5min;



    % fit multiple times with some jitter in the initial params
    N_reps = 15;
    wiggle = 0.3;
    min_err = 9999999999999999.99;
    for j=1:N_reps

        %         FILE
        %         j

        rand_factor = rand(size(X0)) * wiggle + (1-wiggle/2); % ranges from 1-wiggle/2 -> 1 + wiggle/2
        temp_X0 = X0 .* rand_factor;

        testpars = fmincon(sse, temp_X0, A, b, Aeq, beq, LB, UB, nonlcon, options);
        err = sse(testpars);
        if (err < min_err)
            testpars_min = testpars;
            min_err = err;
        end

    end

    % Get the parameters used and the fit itself.
    X = testpars_min;
    yfit = fit(X);

    X0_all(:,n)=X0;
    X_all(:,n)=X;
    yfit_all(:,n)=yfit;

    figure(3);
    plot( xdata, yfit, 'r-', ones(size(ydata,1),1)*xdata' , ydata, '.');
    %     pause;

    % Calculate some goodness of fit measures.
    sserr(n) = sse(X);
    ymean = mean(ydata);
    [coeftmp, Ptmp]=corrcoef( ymean, yfit );
    r(n)=coeftmp(1,2);
    p(n)=Ptmp(1,2);

    % Now have fitting parameters X, the seed used to find them X0 and the
    % fit calculated at the data points yfit.

    % R^2's using means, but need to parse and avg the data first
    %     for k = 1:length(unique_condition_num)
    %         for i = 1:length(unique_azimuth)
    %             ydata_stacked{n}(i+length(unique_azimuth)*(k-1)) = mean(ydata_merged{n}((k-1)*repetitions+1:k*repetitions,i));
    %             yfit_head_stacked{n}(i+length(unique_azimuth)*(k-1)) = mean(yfit_head{n}((k-1)*repetitions+1:k*repetitions,i));
    %             yfit_eye_stacked{n}(i+length(unique_azimuth)*(k-1)) = mean(yfit_eye{n}((k-1)*repetitions+1:k*repetitions,i));
    %         end
    %     end
    %
    %     clear coef P;
    %     [coef,P] = corrcoef(ydata_stacked{n},yfit_head_stacked{n});
    %     R_head(n) = coef(1,2);
    %     rsquared_head(n) = coef(1,2)^2;
    %     p_fit_head(n) = P(1,2);
    %
    %     clear coef P;
    %     [coef,P] = corrcoef(ydata_stacked{n},yfit_eye_stacked{n});
    %     R_eye(n) = coef(1,2);
    %     rsquared_eye(n) = coef(1,2)^2;
    %     p_fit_eye(n) = P(1,2);
    %
    %     %    for partial correlation, need corrcoef between eye and head themselves
    %     clear coef P;
    %     [coef,P] = corrcoef(yfit_head_stacked{n},yfit_eye_stacked{n});
    %     R_headeye(n) = coef(1,2);
    %     rsquared_headeye(n) = coef(1,2)^2;
    %     partialcorr_head(n) = (R_head(n) - R_eye(n) * R_headeye(n)) / sqrt( (1-rsquared_eye(n)) * (1-rsquared_headeye(n)) );
    %     partialcorr_eye(n) = (R_eye(n) - R_head(n) * R_headeye(n)) / sqrt( (1-rsquared_head(n)) * (1-rsquared_headeye(n)) );
    %     partialZ_head(n) = 0.5 * log((1+partialcorr_head(n))/(1-partialcorr_head(n))) / (1/sqrt(length(unique_azimuth)*length(unique_condition_num)-3));
    %     partialZ_eye(n) = 0.5 * log((1+partialcorr_eye(n))/(1-partialcorr_eye(n))) / (1/sqrt(length(unique_azimuth)*length(unique_condition_num)-3));

end

%%

% Calculate variance to mean ratios using a linear fit to the log(data).

vmr_all = zeros( 2, size(ydata_all,3) );

% Loop through all single cue and all offsets for combined.
for n=1:size(ydata_all,3)

    ydata=ydata_all(:,:,n);

    ymean = mean(ydata);
    ymean(ymean==0)=1;
    yvar=var(ydata);
    yvar(yvar==0)=1;
    vmr_all(:,n) = polyfit( log10(ymean), log10(yvar),1 );

    % A little plotting code to investigate whether the fit looks good.
    figure(4);
    subplot(2,1,1);
    plot(ymean,yvar,'.', sort(ymean), 10.^( polyval(vmr_all(:,n), sort(log10(ymean))) ) , 'r-' );
    subplot(2,1,2);
    plot( log10(ymean), log10(yvar), '.', sort(log10(ymean)) , polyval(vmr_all(:,n), sort(log10(ymean))), 'r-');
    %     pause;


end

% Calculate the mean to variance ratio with all data lumped.
ydata_lump = reshape( ydata_all , [ size(ydata_all,1) size(ydata_all,2)*size(ydata_all,3) ] );
ymean = mean( ydata_lump , 1 );
ymean(ymean==1)=1;
yvar = var( ydata_lump , 1 );
yvar(yvar==0)=1;
vmr_lump = polyfit( log10(ymean) , log10(yvar), 1 );

%%

% Now calculate information based on the fit above.

% Define the points to look as 1 degree steps.
azi=(0:1:359) * pi/180;

% Fisher array
fisher=zeros( length(azi) , size(ydata_all,3) );
slope=zeros( length(azi) , size(ydata_all,3) );
variance=zeros( length(azi) , size(ydata_all,3) );
variance_lump=zeros( length(azi) , size(ydata_all,3) );
fisher_lump=zeros( length(azi) , size(ydata_all,3) );

% dtheta defines the step size for calculating the derivative. Use 1/100
% degree.
dtheta=0.01 * pi/180;

maxabsslope=zeros(1,size(ydata_all,3));
theta_maxabsslope=zeros(1,size(ydata_all,3));
maxfisher=zeros(1,size(ydata_all,3));
theta_maxfisher=zeros(1,size(ydata_all,3));
maxfisher_lump=zeros(1,size(ydata_all,3));
theta_maxfisher_lump=zeros(1,size(ydata_all,3));

clear G Gprime sigmasquared I_F
for n=1:size(ydata_all,3)

    % The fit modified Gaussian
    G{n} = @(theta) X_all(1,n) * ( exp(-2*(1-cos(theta-X_all(2,n)))/(X_all(5,n)*X_all(3,n))^2) + ...
        X_all(4,n)*exp(-2*(1-cos(theta-X_all(2,n)-pi))/X_all(3,n)^2) ) + X_all(6,n);
    % Its derivative
    Gprime{n} = @(theta) X_all(1,n) * ( exp(-2*(1-cos(theta-X_all(2,n)))/(X_all(5,n)*X_all(3,n))^2) .* ...
        2./(X_all(5,n)*X_all(3,n))^2 .* ( -sin( theta-X_all(2,n) ) ) + ...
        X_all(4,n) * exp(-2*(1-cos(theta-X_all(2,n)-pi))/X_all(3,n)^2) .* ...
        2./((X_all(3,n))^2) .* ( -sin( theta-X_all(2,n)-pi ) ) );
   
%     Gprime_n{n} = @(theta) ( G{n}( theta + dtheta/2 ) - G{n}( theta - dtheta/2 ) ) / dtheta;
%     figure(7);
%     plot(azi,G{n}(azi), azi, Gprime_n{n}(azi), 'b:', azi, Gprime{n}(azi), 'r-.')
%     pause;
    
    variance(:,n) = 10.^ (log10( G{n}(azi) )*vmr_all(1,n)+vmr_all(2,n) );

    slope(:,n) = Gprime{n}( azi );

    [maxabsslope(n),ind]=max( abs(slope(:,n)) );
    theta_maxabsslope(n) = azi( ind );

    fisher(:,n) = (slope(:,n).^2) ./ variance(:,n);

    [maxfisher(n),ind]=max( fisher(:,n) );
    theta_maxfisher(n) = azi( ind );
    
    % Now real calculations with vmr calculated for whole cell at once.
    sigmasquared{n} = @( theta ) 10.^ ( log10( G{n}( theta ) )*vmr_lump(1) + vmr_lump(2) );
    
    I_F{n} = @(theta) ( Gprime{n}( theta ) ).^2 ./ sigmasquared{n}( theta );

    variance_lump(:,n) = sigmasquared{n}( azi );
    fisher_lump(:,n) = I_F{n}( azi );
    
    [maxfisher_lump(n),ind]=max( fisher_lump(:,n) );
    theta_maxfisher_lump(n) = azi( ind );   

    figure(5);
    plot(azi,slope(:,n),...
        azi,G{n}(azi),...
        azi,variance_lump(:,n),...
        azi,fisher_lump(:,n),...
        (0:45:315)/180*pi, ydata_all(:,:,n),'.');
    
end

% The information has two peaks due to symmetry.
% Choose each peak so that all peaks are close to one another.
raddist = @(t1,t2) mod( t1-t2 + pi , 2*pi) - pi;
for n=1:size(ydata_all,3)

    t=theta_maxfisher(n);
    if n==1
        tcmp=pi;
    else
        tcmp=theta_maxfisher(1);
    end

    mu1=X_all(2,n);
    mu2=mod( mu1 + pi , 2*pi );

    dist1 = abs(raddist(t,mu1));
    dist2 = abs(raddist(t,mu2));
    if dist1 < dist2
        mu=mu1;
    else
        mu=mu2;
    end

    t1 = mod( mu - abs( mod(t-mu,2*pi) ) , 2*pi );
    t2 = mod( mu + abs( mod(t-mu,2*pi) ) , 2*pi );

    dist1 = abs(raddist(t1,tcmp ));
    dist2 = abs(raddist(t2,tcmp ));

    if dist1 < dist2
        theta_maxfisher(n)=t1;
    else
        theta_maxfisher(n)=t2;
    end

end

% The information has two peaks due to symmetry.
% Choose each peak so that all peaks are close to one another.
raddist = @(t1,t2) mod( t1-t2 + pi , 2*pi) - pi;
for n=1:size(ydata_all,3)

    t=theta_maxfisher_lump(n);
    if n==1
        tcmp=pi;
    else
        tcmp=theta_maxfisher_lump(1);
    end

    mu1=X_all(2,n);
    mu2=mod( mu1 + pi , 2*pi );

    dist1 = abs(raddist(t,mu1));
    dist2 = abs(raddist(t,mu2));
    if dist1 < dist2
        mu=mu1;
    else
        mu=mu2;
    end

    t1 = mod( mu - abs( mod(t-mu,2*pi) ) , 2*pi );
    t2 = mod( mu + abs( mod(t-mu,2*pi) ) , 2*pi );

    dist1 = abs(raddist(t1,tcmp ));
    dist2 = abs(raddist(t2,tcmp ));

    if dist1 < dist2
        theta_maxfisher_lump(n)=t1;
    else
        theta_maxfisher_lump(n)=t2;
    end

end

% % Grab the greatest vestibular only information, and compare across other cases.
% [maxfisher_ves,ind]=max( fisher(:,1) );
% theta_maxfisher_ves=azi(ind) * 180/pi;
% fisher_maxfisher_ves = fisher( ind, : );
%
% % Grab the greatest visual only information, and compare across other
% % cases.
% [maxfisher_vis,ind]=max( fisher(:,2) );
% % Shift the combined matrix to align on visual instead of vestibular.
% fisher_vis=fisher;
% for n=3:size(fisher,2)
%     fisher_vis(:,n)=circshift( fisher(:,n), 45*(n-3) );
% end
% theta_maxfisher_vis=azi(ind) * 180/pi;
% fisher_maxfisher_vis = fisher( ind, : );

% Grab the greatest congruent information and compare across other cases.

% Grab the greatest opposite information and compare across other cases.

% Grab the greatest information in combined overall and compare across
% other cases.

figure(6);
plot( azi * 180/pi, fisher );
% legend({'0','45','90','135','180','225','270','315','Vestibular','Visual'});
hold on;
plot( theta_maxfisher * 180/pi, maxfisher, '.' );
hold off;


%%

save([BASE_PATH 'ProtocolSpecific\MOOG\Cueconflict2D\mat\fisher\' FILE(1:end-4) '.mat'], ...
    'X0_all','X_all',...
    'azi','coherence',...
    'dtheta','fisher','fisher_lump',...
    'maxabsslope','maxfisher','maxfisher_lump',...
    'nrep_anova2',...
    'resp',...
    'resp_cam','resp_cam_ste','resp_conflict','resp_std','resp_ste',...
    'resp_trial','resp_trial_cam','resp_trial_conflict','resp_trial_conflict_anova2',...
    'resp_trial_ves','resp_ves','resp_ves_ste',...
    'theta_maxabsslope','theta_maxfisher','theta_maxfisher_lump',...
    'unique_azimuth_cam','unique_azimuth_moog',...
    'vmr_all','vmr_lump',...
    'ydata_all','ydata_lump','yfit_all',...
    'slope','variance_lump',...
    'G','Gprime','sigmasquared','I_F');

%%

% Write important values to a file.
sprint_txt = ['%s\t'];
for i = 1 : 200 % this should be large enough to cover all the data that need to be exported
    sprint_txt = [sprint_txt, ' %g\t'];
end

outfile = [BASE_PATH 'ProtocolSpecific\MOOG\Cueconflict2D\Fisher_lump.dat'];
printflag = 0;
if (exist(outfile, 'file') == 0)    %file does not yet exist
    printflag = 1;
end
fid = fopen(outfile, 'a');
if (printflag)   % change headings here if diff conditions varied
    fprintf(fid, 'FILE\t coherence\t ');
    fprintf(fid, 'A_0\t mu_0\t sigma_0\t K_0\t Ksigma_0\t DC_0\t ');
    fprintf(fid, 'A_45\t mu_45\t sigma_45\t K_45\t Ksigma_45\t DC_45\t ');
    fprintf(fid, 'A_90\t mu_90\t sigma_90\t K_90\t Ksigma_90\t DC_90\t ');
    fprintf(fid, 'A_135\t mu_135\t sigma_135\t K_135\t Ksigma_135\t DC_135\t ');
    fprintf(fid, 'A_180\t mu_180\t sigma_180\t K_180\t Ksigma_180\t DC_180\t ');
    fprintf(fid, 'A_225\t mu_225\t sigma_225\t K_225\t Ksigma_225\t DC_225\t ');
    fprintf(fid, 'A_270\t mu_270\t sigma_270\t K_270\t Ksigma_270\t DC_270\t ');
    fprintf(fid, 'A_315\t mu_315\t sigma_315\t K_315\t Ksigma_315\t DC_315\t ');
    fprintf(fid, 'A_ves\t mu_ves\t sigma_ves\t K_ves\t Ksigma_ves\t DC_ves\t ');
    fprintf(fid, 'A_vis\t mu_vis\t sigma_vis\t K_vis\t Ksigma_vis\t DC_vis\t ');
    fprintf(fid, 'sserr_0\t r_0\t p_0\t ');
    fprintf(fid, 'sserr_45\t r_45\t p_45\t ');
    fprintf(fid, 'sserr_90\t r_90\t p_90\t ');
    fprintf(fid, 'sserr_135\t r_135\t p_135\t ');
    fprintf(fid, 'sserr_180\t r_180\t p_180\t ');
    fprintf(fid, 'sserr_225\t r_225\t p_225\t ');
    fprintf(fid, 'sserr_270\t r_270\t p_270\t ');
    fprintf(fid, 'sserr_315\t r_315\t p_315\t ');
    fprintf(fid, 'sserr_ves\t r_ves\t p_ves\t ');
    fprintf(fid, 'sserr_vis\t r_vis\t p_vis\t ');
    fprintf(fid, 'vmr1_0\t vmr2_0\t ');
    fprintf(fid, 'vmr1_45\t vmr2_45\t ');
    fprintf(fid, 'vmr1_90\t vmr2_90\t ');
    fprintf(fid, 'vmr1_135\t vmr2_135\t ');
    fprintf(fid, 'vmr1_180\t vmr2_180\t ');
    fprintf(fid, 'vmr1_225\t vmr2_225\t ');
    fprintf(fid, 'vmr1_270\t vmr2_270\t ');
    fprintf(fid, 'vmr1_315\t vmr2_315\t ');
    fprintf(fid, 'vmr1_ves\t vmr2_ves\t ');
    fprintf(fid, 'vmr1_vis\t vmr2_vis\t ');
    fprintf(fid, 'vmr1_lump\t vmr2_lump\t ');
    fprintf(fid, 'maxfisher_0\t theta_maxfisher_0\t ');
    fprintf(fid, 'maxfisher_45\t theta_maxfisher_45\t ');
    fprintf(fid, 'maxfisher_90\t theta_maxfisher_90\t ');
    fprintf(fid, 'maxfisher_135\t theta_maxfisher_135\t ');
    fprintf(fid, 'maxfisher_180\t theta_maxfisher_180\t ');
    fprintf(fid, 'maxfisher_225\t theta_maxfisher_225\t ');
    fprintf(fid, 'maxfisher_270\t theta_maxfisher_270\t ');
    fprintf(fid, 'maxfisher_315\t theta_maxfisher_315\t ');
    fprintf(fid, 'maxfisher_ves\t theta_maxfisher_ves\t ');
    fprintf(fid, 'maxfisher_vis\t theta_maxfisher_vis\t ');
    fprintf(fid, 'maxfisher_lump_0\t theta_maxfisher_lump_0\t ');
    fprintf(fid, 'maxfisher_lump_45\t theta_maxfisher_lump_45\t ');
    fprintf(fid, 'maxfisher_lump_90\t theta_maxfisher_lump_90\t ');
    fprintf(fid, 'maxfisher_lump_135\t theta_maxfisher_lump_135\t ');
    fprintf(fid, 'maxfisher_lump_180\t theta_maxfisher_lump_180\t ');
    fprintf(fid, 'maxfisher_lump_225\t theta_maxfisher_lump_225\t ');
    fprintf(fid, 'maxfisher_lump_270\t theta_maxfisher_lump_270\t ');
    fprintf(fid, 'maxfisher_lump_315\t theta_maxfisher_lump_315\t ');
    fprintf(fid, 'maxfisher_lump_ves\t theta_maxfisher_lump_ves\t ');
    fprintf(fid, 'maxfisher_lump_vis\t theta_maxfisher_lump_vis\t ');
    fprintf(fid, '\r\n');
end
buff = sprintf( sprint_txt, ...
    FILE, coherence, ...
    X_all(1,1), X_all(2,1), X_all(3,1), X_all(4,1), X_all(5,1), X_all(6,1), ...
    X_all(1,2), X_all(2,2), X_all(3,2), X_all(4,2), X_all(5,2), X_all(6,2), ...
    X_all(1,3), X_all(2,3), X_all(3,3), X_all(4,3), X_all(5,3), X_all(6,3), ...
    X_all(1,4), X_all(2,4), X_all(3,4), X_all(4,4), X_all(5,4), X_all(6,4), ...
    X_all(1,5), X_all(2,5), X_all(3,5), X_all(4,5), X_all(5,5), X_all(6,5), ...
    X_all(1,6), X_all(2,6), X_all(3,6), X_all(4,6), X_all(5,6), X_all(6,6), ...
    X_all(1,7), X_all(2,7), X_all(3,7), X_all(4,7), X_all(5,7), X_all(6,7), ...
    X_all(1,8), X_all(2,8), X_all(3,8), X_all(4,8), X_all(5,8), X_all(6,8), ...
    X_all(1,9), X_all(2,9), X_all(3,9), X_all(4,9), X_all(5,9), X_all(6,9), ...
    X_all(1,10), X_all(2,10), X_all(3,10), X_all(4,10), X_all(5,10), X_all(6,10), ...
    sserr(1), r(1), p(1), ...
    sserr(2), r(2), p(2), ...
    sserr(3), r(3), p(3), ...
    sserr(4), r(4), p(4), ...
    sserr(5), r(5), p(5), ...
    sserr(6), r(6), p(6), ...
    sserr(7), r(7), p(7), ...
    sserr(8), r(8), p(8), ...
    sserr(9), r(9), p(9), ...
    sserr(10), r(10), p(10), ...
    vmr_all(1,1), vmr_all(2,1), ...
    vmr_all(1,2), vmr_all(2,2), ...
    vmr_all(1,3), vmr_all(2,3), ...
    vmr_all(1,4), vmr_all(2,4), ...
    vmr_all(1,5), vmr_all(2,5), ...
    vmr_all(1,6), vmr_all(2,6), ...
    vmr_all(1,7), vmr_all(2,7), ...
    vmr_all(1,8), vmr_all(2,8), ...
    vmr_all(1,9), vmr_all(2,9), ...
    vmr_all(1,10), vmr_all(2,10), ...
    vmr_lump(1), vmr_lump(2), ...
    maxfisher(1), theta_maxfisher(1), ...
    maxfisher(2), theta_maxfisher(2), ...
    maxfisher(3), theta_maxfisher(3), ...
    maxfisher(4), theta_maxfisher(4), ...
    maxfisher(5), theta_maxfisher(5), ...
    maxfisher(6), theta_maxfisher(6), ...
    maxfisher(7), theta_maxfisher(7), ...
    maxfisher(8), theta_maxfisher(8), ...
    maxfisher(9), theta_maxfisher(9), ...
    maxfisher(10), theta_maxfisher(10), ...
    maxfisher_lump(1), theta_maxfisher_lump(1), ...
    maxfisher_lump(2), theta_maxfisher_lump(2), ...
    maxfisher_lump(3), theta_maxfisher_lump(3), ...
    maxfisher_lump(4), theta_maxfisher_lump(4), ...
    maxfisher_lump(5), theta_maxfisher_lump(5), ...
    maxfisher_lump(6), theta_maxfisher_lump(6), ...
    maxfisher_lump(7), theta_maxfisher_lump(7), ...
    maxfisher_lump(8), theta_maxfisher_lump(8), ...
    maxfisher_lump(9), theta_maxfisher_lump(9), ...
    maxfisher_lump(10), theta_maxfisher_lump(10) ...
    );
fprintf(fid, '%s', buff);
fprintf(fid, '\r\n');
fclose(fid);

return;
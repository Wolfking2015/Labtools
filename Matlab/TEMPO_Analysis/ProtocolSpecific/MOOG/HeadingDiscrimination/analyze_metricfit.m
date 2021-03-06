% fit and plot examples of psychometric functions 
% -GY
clear;
aa=dlmread('metric.txt');
dim=size(aa);

fit_data_psycho_cum(:, 1) = aa(:,1);  
fit_data_psycho_cum(:, 2) = aa(:,2);  
fit_data_psycho_cum(:, 3) = aa(:,3);   

%calculate threshold
wichman_psy = pfit(fit_data_psycho_cum,'plot_opt','no plot','shape','cumulative gaussian','n_intervals',1,'FIX_LAMBDA',0.001,'sens',0,'compute_stats','false','verbose','false'); 
% wichman_psy = pfit(fit_data_psycho_cum,'plot_opt','no plot','shape','cumulative gaussian','n_intervals',1,'FIX_LAMBDA',0.2,'sens',0,'compute_stats','false','verbose','false'); 
Thresh_psy = wichman_psy.params.est(2);
Bias_psy = wichman_psy.params.est(1);
psy_perf = [wichman_psy.params.est(1),wichman_psy.params.est(2)];

% [bb,tt] = cum_gaussfit_max1(fit_data_psycho_cum);
% Thresh_psy = tt;
% Bias_psy = bb;
% psy_perf =[bb,tt];

% logistic fit
% yy(:,1) = aa(:,1);
% %yy{k}(count,2) = unique_condition(n);
% yy(:,2) = aa(:,2).*aa(:,3);
% yy(:,3) = aa(:,3);  
% [b, dev, stats] = glmfit(yy(:,1), [yy(:,2) yy(:,3)],'binomial','link','probit');
% % first, the no-stim case
% Bias_psy = (norminv(0.5)-b(1))/b(2);		% 50 pct PD threshold
% Thresh_psy = abs( norminv(0.84)/b(2) );
% psy_perf = [Bias_psy Thresh_psy];
% threshold(k,1) = (log(0.84/0.16)-bias(k,1)) / slope(k,1);  %
% threshold corresponds to 84% this is for logit fit instead of probit

        
% fit curve
xi = aa(1,1) : 0.1 : aa(end,1);   
beta = [0, 1.0];
yi = cum_gaussfit(psy_perf, xi);

output(:,1) = xi';
output(:,2) = yi';

dlmwrite('metricoutput.txt',output);

% calculated summed error
yi_error = cum_gaussfit(psy_perf, fit_data_psycho_cum(:, 1));
yy = fit_data_psycho_cum(:, 2);
y_error = sum( (yi_error-yy).^2 );
y_error

Thresh_psy
Bias_psy
% plot figure
figure(2);
plot(fit_data_psycho_cum(:, 1), fit_data_psycho_cum(:, 2), 'bo');
hold on;
plot(xi, yi, 'r-');
ylim([0 1]);
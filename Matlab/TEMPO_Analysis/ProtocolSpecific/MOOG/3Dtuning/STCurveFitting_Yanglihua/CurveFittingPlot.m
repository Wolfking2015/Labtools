function CurveFit=CurveFittingPlot(FILE,Plane,Azi_3D,Ele_3D,Azi_temp,Ele_temp,Step,x_time,x_stop,StepMatrix,StdMatrix,SpikeCount_Trial,p_peak,Value_peak,TimeIndex_peak,p_trough,Value_trough,TimeIndex_trough,Sti)

% Step=100;
Azi_3D=[0:45:315];Ele_3D=[-90:45:90];
[AziGrid,EleGrid]=meshgrid(Azi_3D,Ele_3D);
% x_timeL=[0:-Step*0.001:-0.5];x_timeL=fliplr(x_timeL);x_timeL=x_timeL(1:end-1);
% % x_timeR=[0:Step*0.001:2.1];%
% x_timeR=[0:Step*0.001:2.5];
% x_time=[x_timeL x_timeR];
t=[0:Step*0.001:x_time(end)];
clear StartIndex; StartIndex=find(x_time==0);
clear XAzi Ytime;[XAzi,Ytime] = meshgrid([0 45 90 135 180 225 270 315 0 45 90 135 180 225 270 315 0 45 90 135 180 225 270 315 0  0],[0:Step*0.001:max(t)]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%get the space time data for different plane (only for vestibular condition)
for i=1:length(Azi_temp)
    clear RowIndex ColIndex; [RowIndex, ColIndex]=find(AziGrid==Azi_temp(i) & EleGrid==Ele_temp(i));
    PSTH_tempPlane(i,:)=StepMatrix{Sti}(RowIndex,ColIndex,:); %PSTH_tempPlane(i,:)=StepMatrix{1}(RowIndex,ColIndex,:);
    
    p_peak_tempPlane(i,1)=p_peak{Sti}(RowIndex,ColIndex);%循环产生的数依次放在数组中
    p_trough_tempPlane(i,1)=p_trough{Sti}(RowIndex,ColIndex);
    PeakValue_tempPlane(i,1)=Value_peak{Sti}(RowIndex,ColIndex);
    TroughValue_tempPlane(i,1)=Value_trough{Sti}(RowIndex,ColIndex);
    PeakTimeIndex(i,1)=TimeIndex_peak{Sti}(RowIndex,ColIndex);
    if x_time(PeakTimeIndex)>2 %2是x_time中的第26个数，只要PeakTimeIndex<26,x_time(PeakTimeIndex)<2
        p_peak_tempPlane(i,1)=NaN;%保证峰值在2s时间内
    else
    end
    TroughTimeIndex(i,1)=TimeIndex_trough{Sti}(RowIndex,ColIndex);
    if x_time(TroughTimeIndex(i,1))>2
        p_trough_tempPlane(i,1)=NaN;
    else
    end
    clear tempdata; tempdata=[SpikeCount_Trial{Sti,RowIndex,ColIndex}]';
    
    if i>1
        tempdata0=zeros(size(spacetime_data_trial,1),size(spacetime_data_trial,3));
        %都凑成5*24的矩阵，如果有的重复次数是4，第五行补零。问题是是按照i=1的时候定义以后矩阵的大小，万一第一次的重复次数只有4，以后有5，怎么办？？
        
        tempdata0(1:size(tempdata,1),:)=tempdata(:,StartIndex:end);
        spacetime_data_trial(:,i,:)=tempdata0;
    else
        spacetime_data_trial(:,i,:)=tempdata(:,StartIndex:end);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Check the temporal modulation
clear Index_Sig; Index_Sig=find(p_peak_tempPlane<0.01);
p_peak_tempPlane;
k=0;
for i=1:length(Index_Sig)-1
    for j=i+1:length(Index_Sig)
        k=k+1;
        DiffDir_Peak(k,1)=Angle3D_paired(Azi_temp(Index_Sig(i)),Azi_temp(Index_Sig(j)), Ele_temp(Index_Sig(i)),Ele_temp(Index_Sig(j)));
        %         aa=[Azi_temp(Index_Sig(i)),Azi_temp(Index_Sig(j)), Ele_temp(Index_Sig(i)),Ele_temp(Index_Sig(j))];
    end
end
if length(Index_Sig)>=2 & min(DiffDir_Peak)<=50
    Modulation_Peak=1;
else
    Modulation_Peak=0;
end

clear Index_Sig; Index_Sig=find(p_trough_tempPlane<0.01);
k=0;
for i=1:length(Index_Sig)-1
    for j=i+1:length(Index_Sig)
        k=k+1;
        DiffDir_Trough(k,1)=Angle3D_paired(Azi_temp(Index_Sig(i)),Azi_temp(Index_Sig(j)), Ele_temp(Index_Sig(i)),Ele_temp(Index_Sig(j)));
        
        %         bb=[i,j,k,Azi_temp(Index_Sig(i)),Azi_temp(Index_Sig(j)), Ele_temp(Index_Sig(i)),Ele_temp(Index_Sig(j))];
    end
end
if length(Index_Sig)>=2 & min(DiffDir_Trough)<=50
    Modulation_Trough=1;
else
    Modulation_Trough=0;
end
if Modulation_Peak==0 & Modulation_Trough==0
    CurveFit=[];
    return;
else
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot the original space-time figure;
for i=1:size(spacetime_data_trial,1)
    clear tempdata; tempdata=squeeze(spacetime_data_trial(i,:,:));
    %     tempdata(9,:)=tempdata(1,:);
    tempdata=reshape(tempdata,1,size(tempdata,1)*size(tempdata,2));
    spacetime_data_re(i,:)=tempdata;%    spacetime_data_re(i,:)=tempdata*1000/Step;
    Direction_re(i,:)=reshape(XAzi,1,size(tempdata,1)*size(tempdata,2));
    time_re(i,:)=reshape(Ytime,1,size(tempdata,1)*size(tempdata,2));
end
spacetime_data=reshape(mean(spacetime_data_re),length(Azi_temp),length(t));
%%%%%%%%%%%%%%%%%
% Do the Two-way ANOVA to see whether the space-time data has a significant structure
clear currentdata; currentdata=[];
for i=1:size(spacetime_data_trial,2)
    clear tempdata;tempdata=squeeze(spacetime_data_trial(:,i,:));
    currentdata=cat(1,currentdata,tempdata);
end
[p_anova_2way,tbl,stats] = anova2(currentdata,size(spacetime_data_trial,1),'off');

if p_anova_2way(1)>0.01 | p_anova_2way(2)>0.01 | p_anova_2way(3)>0.01
    CurveFit=[];
    return;
end

% % FigureIndex=2;
% % figure(FigureIndex);set(FigureIndex,'Position', [50,50 1200,800], 'Name', 'CurveFitting');orient landscape;
% % text(-0.1,1.06,[FILE '  ' Plane]); axis off;
excel11=[FILE '  ' Plane];
% % clear XAzi Ytime;[XAzi,Ytime] = meshgrid([0:45:360],[0:Step*0.001:max(t)]);
% % figure(FigureIndex);axes('position',[0.05 0.77 0.17 0.15]);%subplot('position', [0.1 0.7 0.22 0.22]);
% % contourf(XAzi,Ytime,spacetime_data');
% % % caxis([0 120]);
% % colorbar;
% % set(gca, 'xtick', [] );set(gca, 'XTickMode','manual');
% % set(gca, 'xtick',[0:90:360]);set(gca, 'xticklabel','0|90|180|270|360');
% % set(gca, 'ytick', [] ); set(gca, 'YTickMode','manual');
% % set(gca, 'ytick',[0:0.5:max(t)]);
% % set(gca, 'yticklabel','0|0.5|1|1.5|2|2.5');% set(gca, 'ydir','reverse');
% % xlabel('Azimuth, X (deg)');  ylabel('Time (sec)');title('raw data');%改变横纵坐标的标示
out=[];
% % out = 'Two-way ANOVA: p(Time) | p(Space) | p(Space*Time) ';
% % out = strvcat(out, sprintf('--------------------------------------------------------------------------------------------------------'));
clear OutputValue;OutputValue=p_anova_2way;
CurveFit.excel2=OutputValue;
CurveFit.excel4=max(t);
% % out=strvcat(out, sprintf('              %7.3f  | %7.3f |  %7.3f  ', OutputValue));
% % figure(FigureIndex);axes('position',[0.26 0.74 0.25 0.25]); set(gca,'box','off','visible','off');
% % text(-0.08,1,out,'fontsize',8,'fontname','courier','horizontalalignment','left','verticalalignment','top');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Do the curve fitting
%Model1: Velocity only
allow_negative=0;
global model_use
model_use=1;
[spacefit_Vel,vect_Vel,r_squared_Vel,CI_Vel,cor_Vel] = MSF_Vel_fit(spacetime_data,Azi_temp,Ele_temp,Step*0.001,allow_negative);

% % figure(FigureIndex);axes('position',[0.05 0.53 0.17 0.15]);
% % contourf(XAzi,Ytime,spacefit_Vel',10);%caxis([0 120]);
% % colorbar;
% % set(gca, 'xtick', [] );set(gca, 'XTickMode','manual');
% % set(gca, 'xtick',[0:90:360]);set(gca, 'xticklabel','0|90|180|270|360');
% % set(gca, 'ytick', [] ); set(gca, 'YTickMode','manual');
% % set(gca, 'ytick',[0:0.5:max(t)]);
% % set(gca, 'yticklabel','0|0.5|1|1.5|2|2.5');% set(gca, 'ydir','reverse');
% % ylabel('Time (sec)');title('model: Vel  ');%xlabel('Azimuth, X (deg)');

error_surf = spacetime_data - spacefit_Vel;
err_Vel = cosnlin_err(vect_Vel);
% % figure(FigureIndex);axes('position',[0.26 0.53 0.17 0.15]);%subplot('position', [0.1 0.7 0.22 0.22]);
% % contourf(XAzi,Ytime,error_surf');
% % % caxis([0 120]);
% % colorbar;
% % set(gca, 'xtick', [] );set(gca, 'XTickMode','manual');
% % set(gca, 'xtick',[0:90:360]);set(gca, 'xticklabel','0|90|180|270|360');
% % set(gca, 'ytick', [] ); set(gca, 'YTickMode','manual');
% % set(gca, 'ytick',[0:0.5:max(t)]);
% % set(gca, 'yticklabel','0|0.5|1|1.5|2|2.5');% set(gca, 'ydir','reverse');
% % %axis off;
% % title({[ 'Err: ' num2str(err_Vel, '%0.2f') ]},  'FontSize', 10);

% Do chi-square goodness of fit test
%model 1
global xdata tdata
xtdata = [xdata;tdata];
model_use=1;
[chi2_Vel, chi2P_Vel] = Chi2_Test_3D(xtdata, spacetime_data_re, 'funccosnlin', vect_Vel, length(vect_Vel));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Model 2: Velocity + Acceleration
model_use=2;
[spacefit_VelAcc,vect_VelAcc,r_squared_VelAcc,CI_VelAcc,cor_VelAcc] = MSF_VelAcc_fit(spacetime_data, vect_Vel,Step*0.001,allow_negative);

% % figure(FigureIndex);axes('position',[0.05 0.31 0.17 0.15]);
% % contourf(XAzi,Ytime,spacefit_VelAcc');%caxis([0 120]);
% % colorbar;
% % set(gca, 'xtick', [] );set(gca, 'XTickMode','manual');
% % set(gca, 'xtick',[0:90:360]);set(gca, 'xticklabel','0|90|180|270|360');
% % set(gca, 'ytick', [] ); set(gca, 'YTickMode','manual');
% % set(gca, 'ytick',[0:0.5:max(t)]);
% % set(gca, 'yticklabel','0|0.5|1|1.5|2|2.5');% set(gca, 'ydir','reverse');
% % ylabel('Time (sec)');title('model: Vel + Acc ');%xlabel('Azimuth, X (deg)');

error_surf = spacetime_data - spacefit_VelAcc;
err_VelAcc = cosnlin_err(vect_VelAcc);
% % figure(FigureIndex);axes('position',[0.26 0.31 0.17 0.15]);
% % contourf(XAzi,Ytime,error_surf'); %caxis([0 120]);
% % colorbar;
% % set(gca, 'xtick', [] );set(gca, 'XTickMode','manual');
% % set(gca, 'xtick',[0:90:360]);set(gca, 'xticklabel','0|90|180|270|360');
% % set(gca, 'ytick', [] ); set(gca, 'YTickMode','manual');
% % set(gca, 'ytick',[0:0.5:max(t)]);
% % set(gca, 'yticklabel','0|0.5|1|1.5|2|2.5');% set(gca, 'ydir','reverse');
% % % axis off;
% % title({[ 'Err: ' num2str(err_VelAcc, '%0.2f') ]},  'FontSize', 10);

% Do chi-square goodness of fit test
[chi2_VelAcc, chi2P_VelAcc] = Chi2_Test_3D(xtdata, spacetime_data_re, 'funccosnlin', vect_VelAcc, length(vect_VelAcc));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Model 3: Velocity + Acceleration + Position
% % model_use=3;

% % [spacefit_VelAccPos,vect_VelAccPos,r_squared_VelAccPos,CI_VelAccPos,cor_VelAccPos] = MSF_VelAccPos_fit(spacetime_data, vect_VelAcc,Step*0.001,allow_negative);
% % figure(FigureIndex);axes('position',[0.05 0.09 0.17 0.15]);%subplot('position', [0.1 0.7 0.22 0.22]);
% % contourf(XAzi,Ytime,spacefit_VelAccPos',10);%caxis([0 120]);
% % colorbar;
% % set(gca, 'xtick', [] );set(gca, 'XTickMode','manual');
% % set(gca, 'xtick',[0:90:360]);set(gca, 'xticklabel','0|90|180|270|360');
% % set(gca, 'ytick', [] ); set(gca, 'YTickMode','manual');
% % set(gca, 'ytick',[0:0.5:max(t)]);
% % set(gca, 'yticklabel','0|0.5|1|1.5|2|2.5');% set(gca, 'ydir','reverse');
% % xlabel('Azimuth, X (deg)');
% % ylabel('Time (sec)');title('model: Vel + Acc + Pos');

% % error_surf = spacetime_data - spacefit_VelAccPos;
% % err_VelAccPos = cosnlin_err(vect_VelAccPos);
% % figure(FigureIndex);axes('position',[0.26 0.09 0.17 0.15]);
% % contourf(XAzi,Ytime,error_surf'); %caxis([0 120]);
% % colorbar;
% % set(gca, 'xtick', [] );set(gca, 'XTickMode','manual');
% % set(gca, 'xtick',[0:90:360]);set(gca, 'xticklabel','0|90|180|270|360');
% % set(gca, 'ytick', [] ); set(gca, 'YTickMode','manual');
% % set(gca, 'ytick',[0:0.5:max(t)]);
% % set(gca, 'yticklabel','0|0.5|1|1.5|2|2.5');% set(gca, 'ydir','reverse');
% % % axis off;
% % title({[ 'Err: ' num2str(err_VelAccPos, '%0.2f') ]},  'FontSize', 10);% axis off;

% mode 3
% % [chi2_VelAccPos, chi2P_VelAccPos] = Chi2_Test_3D(xtdata, spacetime_data_re, 'funccosnlin', vect_VelAccPos, length(vect_VelAccPos));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % out=[];
% % out = 'CurveFitting:    R0 |  Amp  |  n  | muAzi |  muT  | sigmaT |  DC2  | wVel  |ThetaAcc|  wAcc | ThetaPos | wPos';
% % out = strvcat(out, sprintf('------------------------------------------------------------------------------------------------------------'));
% % clear OutputValue;OutputValue=vect_Vel;
% % OutputValue(4)=OutputValue(4)*180/pi;
% % out=strvcat(out, sprintf('Vel Model:     %4.1f | %5.1f |%4.1f |%6.1f | %4.3f | %6.3f |%6.3f', OutputValue));

clear OutputValue;OutputValue=vect_VelAcc;
OutputValue(4)=OutputValue(4)*180/pi;
% OutputValue(9)=OutputValue(9)*180/pi;
CurveFit.excel3= vect_VelAcc(9);%现在9为权重

% % out=strvcat(out, sprintf('Vel+Acc Model: %4.1f | %5.1f |%4.1f |%6.1f | %4.3f | %6.3f |%6.3f |%6.3f | %6.1f  ', OutputValue));


% % clear OutputValue; OutputValue=[vect_VelAccPos(1:9) 1-vect_VelAccPos(8) vect_VelAccPos(10:11)];
% % OutputValue(4)=OutputValue(4)*180/pi;
% % OutputValue(9)=OutputValue(9)*180/pi;
% % OutputValue(11)=OutputValue(11)*180/pi;
% % out=strvcat(out, sprintf('Vel+Acc+Pos  : %4.1f | %5.1f |%4.1f |%6.1f | %4.3f | %6.3f |%6.3f |%6.3f | %6.1f |%6.3f | %6.1f   |%6.3f', OutputValue));
% % figure(FigureIndex);axes('position',[0.26 0.69 0.25 0.25]); set(gca,'box','off','visible','off');
% % text(-0.08,1,out,'fontsize',8,'fontname','courier','horizontalalignment','left','verticalalignment','top');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Performing regression to get R^2 and p-values for F-test
Data_Raw=reshape(spacetime_data,size(spacetime_data,1)*size(spacetime_data,2),1);
Data_Vel=reshape(spacefit_Vel,size(spacefit_Vel,1)*size(spacefit_Vel,2),1);
Data_VelAcc=reshape(spacefit_VelAcc,size(spacefit_VelAcc,1)*size(spacefit_VelAcc,2),1);
% % Data_VelAccPos=reshape(spacefit_VelAccPos,size(spacefit_VelAccPos,1)*size(spacefit_VelAccPos,2),1);

clear X1;X1 = [ones(size(Data_Vel,1),1) Data_Vel];%X1 = [ones(808,1) Data_Vel];% y_fit = [ones(length(y_fit),1) y_fit];
[b_Vel,bint,r_Vel,rint,stats_Vel] = regress(Data_Raw,X1,0.05);
clear X1;X1 = [ones(size(Data_VelAcc,1),1) Data_VelAcc];
[b_VelAcc,bint,r_VelAcc,rint,stats_VelAcc] = regress(Data_Raw,X1,0.05);
% % clear X1;X1 = [ones(size(Data_VelAccPos,1),1) Data_VelAccPos];
% % [b_VelAccPos,bint,r_VelAccPos,rint,stats_VelAccPos] = regress(Data_Raw,X1,0.05);

Ftest_1vs2=[(err_Vel-err_VelAcc)/(length(vect_VelAcc)-length(vect_Vel))]/[err_VelAcc/(size(spacetime_data,1)*size(spacetime_data,2)-length(vect_VelAcc))];
p_1vs2=1-fcdf(Ftest_1vs2,length(vect_VelAcc)-length(vect_Vel),size(spacetime_data,1)*size(spacetime_data,2)-length(vect_VelAcc));

% % Ftest_2vs3=[(err_VelAcc-err_VelAccPos)/(length(vect_VelAccPos)-length(vect_VelAcc))]/[err_VelAccPos/(size(spacetime_data,1)*size(spacetime_data,2)-length(vect_VelAccPos))];
% % p_2vs3=1-fcdf(Ftest_2vs3,length(vect_VelAccPos)-length(vect_VelAcc),size(spacetime_data,1)*size(spacetime_data,2)-length(vect_VelAccPos));

% do AIC test
AIC_1vs2=size(spacetime_data,1)*size(spacetime_data,2)*log(err_VelAcc/err_Vel)+2*(length(vect_VelAcc)-length(vect_Vel));
% % AIC_2vs3=size(spacetime_data,1)*size(spacetime_data,2)*log(err_VelAccPos/err_VelAcc)+2*(length(vect_VelAccPos)-length(vect_VelAcc));
% % AIC_1vs3=size(spacetime_data,1)*size(spacetime_data,2)*log(err_VelAccPos/err_Vel)+2*(length(vect_VelAccPos)-length(vect_Vel));

% % out=[];
% out = 'Goodness of fitting:  r2 (Vel) | r2 (VelAcc)| r2 (VelAccPos) | Ftest(1vs2) | p(1vs2)  | Ftest(2vs3) | p(2vs3)';
% % out = 'Goodness of fit: r2(Vel) | r2(V+A)| r2(V+A+P) | F(1vs2) | p(1vs2)  | F(2vs3) | p(2vs3) | AIC(1vs2) | AIC(2vs3)';
% % out = strvcat(out, sprintf('--------------------------------------------------------------------------------------------------------'));
% % clear OutputValue;OutputValue=[r_squared_Vel r_squared_VelAcc r_squared_VelAccPos Ftest_1vs2 p_1vs2 Ftest_2vs3 p_2vs3 AIC_1vs2 AIC_2vs3];
% % out=strvcat(out, sprintf('                  %6.3f | %6.3f |  %6.3f   | %6.3f  |  %6.3f  |  %6.3f |  %6.3f | %9.3f |  %6.3f ', OutputValue));
% % figure(FigureIndex);axes('position',[0.26 0.60 0.25 0.25]); set(gca,'box','off','visible','off');
% % text(-0.08,1,out,'fontsize',8,'fontname','courier','horizontalalignment','left','verticalalignment','top');

% % out=[];
% % out = 'Goodness of fit: Chi2(V) |  p(V) | Chi2(VA)|  p(VA) | Chi2(VAP) | p(VAP) ';
% % out = strvcat(out, sprintf('---------------------------------------------------------------------------------'));
% % clear OutputValue;OutputValue=[chi2_Vel chi2P_Vel chi2_VelAcc chi2P_VelAcc chi2_VelAccPos chi2P_VelAccPos];
% % out=strvcat(out, sprintf('             %9.1f   | %5.3f | %7.1f |  %5.3f | %8.1f  | %6.3f   ', OutputValue));
% % figure(FigureIndex);axes('position',[0.26 0.55 0.25 0.25]); set(gca,'box','off','visible','off');
% % text(-0.08,1,out,'fontsize',8,'fontname','courier','horizontalalignment','left','verticalalignment','top');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% order in which the directions are plotted
plot_col = [1 1 1 1 1 2 2 2 3 3 3 4 4 4 5 5 5 6 6 6 7 7 7 8 8 8];
plot_row = [5 4 3 2 1 4 3 2 4 3 2 4 3 2 4 3 2 4 3 2 4 3 2 4 3 2];

x_start = [0, 0];
% x_stop =  [2, 2];
y_marker=[0,1.1*max(max(spacetime_data))];

xscale = [0.8 0.77 0.68 0.52 0.5 0.52 0.68 0.77];
yscale = [0.34 0.49 0.64 0.49 0.34 0.19 0.04 0.19];

% xscale = [0.8 0.77 0.65 0.52 0.5 0.52 0.65 0.77];
% yscale = [0.35 0.5 0.65 0.5 0.35 0.2 0.05 0.2];

%get the curve fitting results for each direction
clear model_Vel; model_Vel=zeros(length(Azi_temp),length(x_time));
model_Vel(:,1:StartIndex-1) = NaN; model_Vel(:,StartIndex:length(x_time))=spacefit_Vel(1:26,:);
clear model_VelAcc; model_VelAcc=zeros(length(Azi_temp),length(x_time));
model_VelAcc(:,1:StartIndex-1) = NaN; model_VelAcc(:,StartIndex:length(x_time))=spacefit_VelAcc(1:26,:);
% % clear model_VelAccPos; model_VelAccPos=zeros(length(Azi_temp),length(x_time));
% % model_VelAccPos(:,1:StartIndex-1) = NaN; model_VelAccPos(:,StartIndex:length(x_time))=spacefit_VelAccPos(1:8,:);

%Plot the PSTH, superimposed with curve fitting
% for i=1:length(Azi_temp)
%     i;
%     axes('position',[xscale(i) yscale(i) 0.16 0.10]);
%     bar(x_time,PSTH_tempPlane(i,:),1.0);hold on;%bar(x_time, count_y{i,j,k});    hold on;
for i=1:length(Azi_temp)
    excel5{i}=PSTH_tempPlane(i,:);
end

CurveFit.PSTH_tempPlane=PSTH_tempPlane;
CurveFit.model_VelAcc=model_VelAcc;

CurveFit.excel14=excel5{1};
CurveFit.excel15=excel5{2};
CurveFit.excel16=excel5{3};
CurveFit.excel17=excel5{4};
CurveFit.excel18=excel5{5};
CurveFit.excel19=excel5{6};
CurveFit.excel20=excel5{7};
CurveFit.excel21=excel5{8};
CurveFit.excel22=excel5{9};
CurveFit.excel23=excel5{10};
CurveFit.excel24=excel5{11};
CurveFit.excel25=excel5{12};
CurveFit.excel26=excel5{13};
CurveFit.excel27=excel5{14};
CurveFit.excel28=excel5{15};
CurveFit.excel29=excel5{16};
CurveFit.excel30=excel5{17};
CurveFit.excel31=excel5{18};
CurveFit.excel32=excel5{19};
CurveFit.excel33=excel5{20};
CurveFit.excel34=excel5{21};
CurveFit.excel35=excel5{22};
CurveFit.excel36=excel5{23};
CurveFit.excel37=excel5{24};
CurveFit.excel38=excel5{25};
CurveFit.excel39=excel5{26};

% %      if temp_p_peak <0.01 & x_time(PeakTimeIndex(i,1))<2
% %          plot(x_time(PeakTimeIndex(i,1)), PSTH_tempPlane(i,PeakTimeIndex(i,1)),'ro','LineWidth',2.0);hold on;
% %      end
CurveFit.excel40= zeros(1,26);
CurveFit.excel41=zeros(1,26);
for i=1:length(Azi_temp)
    if p_peak_tempPlane(i,1) <0.01 & x_time(PeakTimeIndex(i,1))<2
        CurveFit.excel40(i)=x_time(PeakTimeIndex(i,1));
        CurveFit.excel41(i)=PSTH_tempPlane(i,PeakTimeIndex(i,1));
    end
end

CurveFit.excel42=zeros(1,26);
CurveFit.excel43=zeros(1,26);
for i=1:length(Azi_temp)
    if p_trough_tempPlane(i,1) <0.01 & x_time(TroughTimeIndex(i,1))<2
        CurveFit.excel42(i)=x_time(TroughTimeIndex(i,1));%波峰所在的时间
        CurveFit.excel43(i)= PSTH_tempPlane(i,TroughTimeIndex(i,1));
    end
end

% % clear temp_p_trough; temp_p_trough=p_trough_tempPlane(i,1);
% % % %      if temp_p_trough <0.01 & x_time(TroughTimeIndex(i,1))<2
% % % %          plot(x_time(TroughTimeIndex(i,1)), PSTH_tempPlane(i,TroughTimeIndex(i,1)),'go','LineWidth',2.0);hold on;
% % % %      end
% % if  temp_p_trough <0.01 & x_time(TroughTimeIndex(i,1))<2
% %     Curve.excel42=x_time(TroughTimeIndex(i,1));
% %     Curve.excel43=PSTH_tempPlane(i,TroughTimeIndex(i,1));
% % end

figure(4)
subplot(5,8,4)
yvale_temp=[PSTH_tempPlane;model_VelAcc];
yvale=max(max(yvale_temp));
bar(x_time,PSTH_tempPlane(25,:),1.0);hold on
plot(x_time,model_VelAcc(25,:), 'g', 'LineWidth', 2);hold on;
xlim([-0.5,2.3]);
ylim([0 yvale]);
for i=1:24
subplot(5,8,8+i)
bar(x_time,PSTH_tempPlane(i,:),1.0);hold on
plot(x_time,model_VelAcc(i,:), 'g', 'LineWidth', 2);hold on;
xlim([-0.5,2.3]);
ylim([0 yvale]);
end
subplot(5,8,36)
bar(x_time,PSTH_tempPlane(26,:),1.0);hold on
plot(x_time,model_VelAcc(26,:), 'g', 'LineWidth', 2);hold on;
xlim([-0.5,2.3]);
ylim([0 yvale]);
if (max(t)==2.3)
    time_end=29;
else (max(t)==1.3)
    time_end=19;
end
PSTH_all=PSTH_tempPlane(:,6:time_end);
A=PSTH_all(:);
model_VA=model_VelAcc(:,6:time_end);
B=model_VA(:);
[R,P]=corrcoef(A,B);
R=R(1,2);
P=P(1,2);
CurveFit.R=R;
CurveFit.P=P;

figure(5)
subplot(121)
contourf(PSTH_all);
subplot(122)
contourf(model_VA);
% %     plot(x_time,model_Vel(i,:),'r','LineWidth',2); hold on;
% %     plot(x_time,model_VelAcc(i,:), 'g', 'LineWidth', 2);hold on;
% %     plot(x_time,model_VelAccPos(i,:),'c','LineWidth',2);hold on;
% %
% %     plot( x_start, y_marker, 'k-','LineWidth',2);hold on;
% %     plot( x_stop,  y_marker, 'k-','LineWidth',2);hold on;
% %     xlim([-0.5,2.5]);    ylim([0,1.2*max(max(spacetime_data))]);
% %
% %     set(gca, 'xtick', [] );set(gca, 'XTickMode','manual');
% %     set(gca, 'xtick',[-0.5:0.5:2.5]);
% %     set( gca, 'xticklabel', '-0.5|0|0.5|1|1.5|2|2.5');
% %     set( gca, 'yticklabel', ' ' );
% %     title({['azi=' num2str(Azi_temp(i)) '; Ele=' num2str(Ele_temp(i))]}, 'FontSize', 8);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Output some data for further analysis
% CurveFit.excel1=excel1;
% CurveFit.excel2=excel2;
%CurveFit.excel3=excel3;

% CurveFit.spacetime_data=spacetime_data;
% CurveFit.Modulation_Peak=Modulation_Peak;
% CurveFit.Modulation_Trough=Modulation_Trough;

% CurveFit.PeakValue=PeakValue_tempPlane;
% CurveFit.TroughValue=TroughValue_tempPlane;
% CurveFit.p_peak=p_peak_tempPlane;
% CurveFit.p_trough=p_trough_tempPlane;
%
% CurveFit.p_anova_2way=p_anova_2way;
%
% CurveFit.spacefit_Vel=spacefit_Vel;
% CurveFit.spacefit_VelAcc=spacefit_VelAcc;
% % CurveFit.spacetime_VelAccPos=spacefit_VelAccPos;
% CurveFit.vect_Vel=vect_Vel;
% CurveFit.vect_VelAcc=vect_VelAcc;
% % CurveFit.vect_VelAccPos=vect_VelAccPos;
% CurveFit.CI_Vel=CI_Vel;
% CurveFit.CI_VelAcc=CI_VelAcc;
% % CurveFit.CI_VelAccPos=CI_VelAccPos;

% CurveFit.cor_Vel=cor_Vel;
% CurveFit.cor_VelAcc=cor_VelAcc;
% % CurveFit.cor_VelAccPos=cor_VelAccPos;

% CurveFit.stats_Vel=stats_Vel;
% CurveFit.stats_VelAcc=stats_VelAcc;
% % CurveFit.stats_VelAccPos=stats_VelAccPos;
% CurveFit.err_Vel=err_Vel;
% CurveFit.err_VelAcc=err_VelAcc;
% % CurveFit.err_VelAccPos=err_VelAccPos;
% CurveFit.r_squared_Vel=r_squared_Vel;
% CurveFit.r_squared_VelAcc=r_squared_VelAcc;
% % CurveFit.r_squared_VelAccPos=r_squared_VelAccPos;
% CurveFit.Ftest_1vs2=Ftest_1vs2;
% CurveFit.p_1vs2=p_1vs2;
% % CurveFit.Ftest_2vs3=Ftest_2vs3;
% % CurveFit.p_2vs3=p_2vs3;

% CurveFit.AIC_1vs2=AIC_1vs2;
% % CurveFit.AIC_2vs3=AIC_2vs3;

% CurveFit.chi2_Vel=chi2_Vel;% CurveFit.Rchi2_Vel=RChi2_Vel;
% CurveFit.chi2P_Vel=chi2P_Vel;% CurveFit.dof_Vel=dof_Vel;
% CurveFit.chi2_VelAcc=chi2_VelAcc;% CurveFit.Rchi2_VelAcc=RChi2_VelAcc;
% CurveFit.chi2P_VelAcc=chi2P_VelAcc;%CurveFit.dof_VelAcc=dof_VelAcc;
% % CurveFit.chi2_VelAccPos=chi2_VelAccPos;%CurveFit.Rchi2_VelAccPos=RChi2_VelAccPos;
% % CurveFit.chi2P_VelAccPos=chi2P_VelAccPos;%CurveFit.dof_VelAccPos=dof_VelAccPos;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Save the figure
% OutputPath=['C:\Aihua\z_TempOutputs\'];
% figure(FigureIndex);
% set(gcf, 'PaperOrientation', 'portrait');
% saveas(gcf,[OutputPath FILE(1:end-4) '_CurveFitting.png'],'png');
% close(FigureIndex);
%
% %Save the Data
% SaveFileName=[OutputPath FILE(1:end-4) '_CurveFit'];
% save(SaveFileName,'CurveFit'); clear SaveFileName;


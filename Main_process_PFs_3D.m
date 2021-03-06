function Main_process_PFs_3D(nameofdataset,folder,savefolder,pix,VisQ,view_PFs)

% pix=0.734; % pixel size, nm

if isempty(savefolder)
    mkdir(strcat(folder,'\Results'));
    savefolder=strcat(folder,'\Results');
end

%% Converting raw PF tracings data from iMOD in .dat format
fnames = dir(strcat(folder,'\*.dat'));

X=[];
Z=[];
Y=[];
global_MT_num=[];
MT_prev_max(1)=0;
Max_num_dots=100;

ii=1;
while isempty(strfind(fnames(ii).name,'start')) %for each POINT file in folder
    
    % read data from POINT file
    fid=fopen([strcat(folder,'\'),fnames(ii).name]);
    fnames(ii).name;
    tline = fgetl(fid);
    tlines = cell(0,1);
    while ischar(tline)
        tlines{end+1,1} = tline;
        tline = fgetl(fid);
    end
    fclose(fid);
    clear info_lines;
    for i=1:length(tlines)
        info_lines(i)=length(str2num(tlines{i}))>3;
    end
    PFinfo1=tlines(info_lines); % cell array 
    PFinfo=str2num(cell2mat(PFinfo1)); % regular array
    Coordinates1=tlines(~info_lines); % cell array 
    Coordinates=str2num(cell2mat(Coordinates1)); % regular array
      
    % record data START and POINT files to matrices
    k=0;
    PFnum(ii)=length(PFinfo(:,1));
    if ii>1
        MT_prev_max(ii)=max(global_MT_num);
    end
    MT_nums=transpose(PFinfo(:,5))+MT_prev_max(ii);
    global_MT_num=[global_MT_num MT_nums];
    x=zeros(Max_num_dots,PFnum(ii));
    z=zeros(Max_num_dots,PFnum(ii));
    y=zeros(Max_num_dots,PFnum(ii));
    for j=1:PFnum(ii)
        num=k+1:k+PFinfo(j,1);
        k=k+PFinfo(j,1);
        x(1:PFinfo(j,1),j)=Coordinates(num,1);
        z(1:PFinfo(j,1),j)=Coordinates(num,2);
        y(1:PFinfo(j,1),j)=Coordinates(num,3);
    end
    X=[X x];
    Z=[Z z];
    Y=[Y y];
    
    if length(fnames)>ii
        ii=ii+1;
    else
        break;
    end
end

% create pf2src
mkdir([folder,'_processed_coordinates']);
writetable(table(X),[folder,'_processed_coordinates\x.txt'],'Delimiter','\t','WriteVariableNames',0);
writetable(table(Z),[folder,'_processed_coordinates\z.txt'],'Delimiter','\t','WriteVariableNames',0);
writetable(table(Y),[folder,'_processed_coordinates\y.txt'],'Delimiter','\t','WriteVariableNames',0);

Xt_raw=X;
Yt_raw=Y;
Zt_raw=Z;

%delete empty columns
sz=size(Yt_raw);
jexl=[];
for j=1:sz(2)
    if sum(Xt_raw(:,j))==0
       jexl=[jexl j];
    end
end
Xt_raw(:,jexl)=[];
Yt_raw(:,jexl)=[];
Zt_raw(:,jexl)=[];

Xt_raw(1,:)=[];
Yt_raw(1,:)=[];
Zt_raw(1,:)=[];


%determine the number of points (kmax) for each PF
Nz=(abs(Xt_raw)+abs(Yt_raw)+abs(Zt_raw))~=0;
maxk0=sum(Nz,1);
J=length(maxk0); %number of protofilaments in the dataset
maxk0(find(maxk0==0))=1;

%bring first point to origin
for j=1:length(maxk0)
    if abs(Xt_raw(1,j)+Yt_raw(1,j)) > abs(Xt_raw(maxk0(j),j)+Yt_raw(maxk0(j),j))
        Xt_raw(1:maxk0(j),j)=flip(Xt_raw(1:maxk0(j),j));
        Yt_raw(1:maxk0(j),j)=flip(Yt_raw(1:maxk0(j),j));
        Zt_raw(1:maxk0(j),j)=flip(Zt_raw(1:maxk0(j),j));
    end
    Xt_raw(1:maxk0(j),j)=Xt_raw(1:maxk0(j),j)-Xt_raw(1,j);
    Yt_raw(1:maxk0(j),j)=Yt_raw(1:maxk0(j),j)-Yt_raw(1,j);
    Zt_raw(1:maxk0(j),j)=Zt_raw(1:maxk0(j),j)-Zt_raw(1,j);
end

%orient PF to be in the 1st quadrant
for j=1:J
    XCOM=mean(Xt_raw(1:maxk0(j),j));
    YCOM=mean(Yt_raw(1:maxk0(j),j));
    ZCOM=mean(Zt_raw(1:maxk0(j),j));
    Xt0(:,j)=Xt_raw(:,j)*sign(XCOM);
    Yt0(:,j)=Yt_raw(:,j)*sign(YCOM);
    Zt0(:,j)=Zt_raw(:,j)*sign(ZCOM);
end

%correct for rear initial tracing shift from origin
Xt1=Xt0;
Yt1=Yt0;
Zt1=Zt0;
maxk1=maxk0;
for j=1:J
    if (Xt0(2,j)<-5)||(abs(Zt0(2,j))>50)||(Yt0(2,j)<-5)
        %set origin to the second point
        Xt1(1:maxk0(j),j)=Xt0(1:maxk0(j),j)-Xt0(2,j);
        Yt1(1:maxk0(j),j)=Yt0(1:maxk0(j),j)-Yt0(2,j);
        Zt1(1:maxk0(j),j)=Zt0(1:maxk0(j),j)-Zt0(2,j);
        %remove the first point
        Xt1(1:maxk0(j)-1,j)=Xt1(2:maxk0(j),j);
        Xt1(maxk0(j),j)=0;
        Yt1(1:maxk0(j)-1,j)=Yt1(2:maxk0(j),j);
        Yt1(maxk0(j),j)=0;
        Zt1(1:maxk0(j)-1,j)=Zt1(2:maxk0(j),j);
        Zt1(maxk0(j),j)=0;
        maxk1(j)=maxk0(j)-1;
    end
end
J=length(maxk1); %number of protofilaments in the dataset
%%
%fill in tracing gaps by interpolation 
[Xt,Yt,Zt,maxk]=InterpolateGappedTracings_fixed(Xt1,Yt1,Zt1,maxk1);
Xt=pix*Xt;
Yt=pix*Yt;
Zt=pix*Zt;
J=length(maxk);

%keep PF parts that deviate from MT wall
jexl=[];
for j=1:J
    if sum(Xt_raw(:,j))==0
       jexl=[jexl j];
    end
end
Xt_raw(:,jexl)=[];
Yt_raw(:,jexl)=[];
Zt_raw(:,jexl)=[];
    
%% plot all PFs before smoothing
figure
for j=1:length(maxk)
    plot3(Xt(1:maxk(j),j),Yt(1:maxk(j),j),Zt(1:maxk(j),j),'k-');
    hold on
end
axis equal
view(-30,10)
get(gca,'XLim');
hT2=title(nameofdataset);
hx=xlabel('x, nm');
hy=ylabel('y, nm');
hz=zlabel('distance along MT axis, nm');
hx.FontSize=16;
hy.FontSize=16;
hz.FontSize=14;
hT2.FontSize=14;
set(gca,'fontsize',14)
get(0,'Factory');
set(0,'defaultfigurecolor',[1 1 1]);

%% calculate PF lengths
[L, ~]=PF_lengths_sub(Xt, Yt, Zt, maxk1);

fig_len=figure;
lenbins=(0:(max(L)+10)/20:max(L)+10);
histogram(L, lenbins);
[Nlen,len_edges]=histcounts(L,lenbins);
len_bin_middles=(len_edges(1:end-1)+len_edges(2:end))/2;
hT2=title(['PF lengths: ',nameofdataset]);
xlabel('PF length,nm');
ylabel('Number of PFs');
hT2.FontSize=16;
hx.FontSize=14;
hy.FontSize=14;
set(gca,'fontsize',14)

saveas(fig_len,[savefolder,'\histlength.jpeg']);
dlmwrite([savefolder,'\hist_PF_length.txt'],[len_bin_middles' Nlen'],'delimiter','\t','newline','pc');
dlmwrite([savefolder,'\MeanL_StdL_numL.txt'], [mean(L) std(L) length(L)],'delimiter','\t','newline','pc');
disp([mean(L) std(L) length(L)]);

%% smooth PFs
smoothwind=10;
addwall=smoothwind;
cuttips=0;
[Xt1, Yt1, Zt1, maxk1]=filter_PFs(Xt, Yt, Zt, maxk, smoothwind,2,addwall,cuttips);
J=length(maxk1);

%% view individual PFs before smoothing (optional)
if view_PFs==1
    figure
    for j=1:length(maxk)
        plot3(Xt(1:maxk(j),j),Yt(1:maxk(j),j),Zt(1:maxk(j),j),'go-');
        hold off
        axis square
        grid minor;
        NumTicks = 9;
        scL = get(gca,'XLim');
        set(gca,'XTick',linspace(scL(1),scL(2),NumTicks))
        set(gca,'YTick',linspace(scL(1),scL(2),NumTicks))
        title(['PF # ',num2str(j)]);
        axis square
        grid minor;        
        waitforbuttonpress
    end
end

%% plot all PFs after smoothing
fig_PFs2=figure;
for j=1:length(maxk1)
    plot3(Xt1(1:maxk1(j),j),Yt1(1:maxk1(j),j),Zt1(1:maxk1(j),j),'k-');
    hold on
end
axis equal
view(-30,10)
hT2=title(nameofdataset);
hx=xlabel('x, nm');
hy=ylabel('y, nm');
hz=zlabel('distance along MT axis, nm');
hx.FontSize=16;
hy.FontSize=16;
hz.FontSize=14;
hT2.FontSize=14;
set(gca,'fontsize',14)
saveas(fig_PFs2,[savefolder,'\plot_PFs.jpeg']);

%% plot average PF shapes
plotshape=0;
if plotshape==1
    Xt_lin=[];
    Yt_lin=[];
    Zt_lin=[];
    for j=1:J
        Xt_lin=[Xt_lin transpose(Xt1(1:maxk1(j),j))];
        Yt_lin=[Yt_lin transpose(Yt1(1:maxk1(j),j))];
        Zt_lin=[Zt_lin transpose(Zt1(1:maxk1(j),j))];
    end
    xbinranges=linspace(min(min([Xt,Yt]))-1,max(max([Xt,Yt]))+1,20);
    [~,xind]= histc(Xt_lin,xbinranges);

    for i=1:length(xbinranges)
        index_i=(xind==i);
        X_average(i)=mean(Xt_lin(index_i));
        X_SEM(i)=std(Xt_lin(index_i))/sqrt(sum(index_i));
        Y_average(i)=mean(Yt_lin(index_i));
        Y_SEM(i)=std(Yt_lin(index_i))/sqrt(sum(index_i));
        Z_average(i)=mean(Zt_lin(index_i));
        Z_SEM(i)=std(Zt_lin(index_i))/sqrt(sum(index_i));
    end
    fig_avshapex=figure;
    errorbar(X_average,Z_average,Z_SEM,'r-');
    fig_avshapey=figure;
    errorbar(Y_average,Z_average,Z_SEM,'r-');
    saveas(fig_avshapex,[savefolder,'\average_PF_shapex.jpeg']);
    saveas(fig_avshapey,[savefolder,'\average_PF_shapey.jpeg']);
end

%% histogram of all PF angles, initial angles
smoothwind=10;
addwall=smoothwind;
cuttips=0;
[Xt1, Yt1, Zt1, maxk1]=filter_PFs(Xt, Yt, Zt, maxk, smoothwind,2,addwall,cuttips);
J=length(maxk1);

[dA,~,~]=find_angles_sub_test(Xt1,Yt1,Zt1,maxk1); %deg/dimer

%pool all angles across all PFs
dA_all=[];
for j=1:J
    dA_all=[dA_all (dA(1:maxk1(j)-2,j))'];
end

curvbins=(-30:1:90);
[N_dA_all,curv_edges]=histcounts(dA_all,curvbins);

curv_bin_middles=(curv_edges(1:end-1)+curv_edges(2:end))/2;

fig_ang=figure;

histogram(dA_all,curvbins);
hT1=title(['All angles: ', nameofdataset]);
hx1=xlabel('Angle,deg/dimer');
hy1=ylabel('Occurence');
hT1.FontSize=14;
hx1.FontSize=14;
hy1.FontSize=14;
set(gca,'fontsize',14)


dlmwrite([savefolder,'\Ang-ALL_mean_med_SD_N.txt'],[mean(dA_all(abs(dA_all)<180))...
    median(dA_all(abs(dA_all)<180)) std(dA_all(abs(dA_all)<180))...
    length(dA_all(abs(dA_all)<180))],'delimiter','\t','newline','pc');
dlmwrite([savefolder,'\hist_ang-all.txt'],[curv_bin_middles' N_dA_all'],'delimiter','\t','newline','pc');

saveas(fig_ang,[savefolder,'\angles.jpeg']);

%% mean angle as a function of position along PF
%smooth data with moving average filter with trimmed ends
smoothwind2=3;
addwall=0;
cuttips=1;
[Xt2, Yt2, Zt2, maxk2]=filter_PFs(Xt, Yt, Zt, maxk, smoothwind2,1,addwall,cuttips);
[dA2,dL,dB2]=find_angles_sub_test(Xt2,Yt2,Zt2,maxk2); %deg/dimer

disp('Mean curvature, deg/dimer')
nanmean(sum(dA2,2,'omitnan')./sum(isnan(dA2)==0 & dA2~=0,2))
disp('Mean helix angle per nm, deg')
nanmean(sum(dB2,2,'omitnan')./sum(isnan(dB2)==0 & dB2~=0,2))

[meancurvfromtip, stdcurvfromtip, Dist_along_PF]=find_angle_vs_position_test(dA2,dL,maxk2);
err=stdcurvfromtip(1:length(Dist_along_PF));

Xfit=Dist_along_PF;
Zfit=meancurvfromtip(1:length(Dist_along_PF));
Efit=err;
Xfit(isnan(err)==1)=[];
Zfit(isnan(err)==1)=[];
Efit(isnan(err)==1)=[];

[f,~] = fit(Xfit',Zfit','sl*x+x0','Weights',1./Efit.^2,'StartPoint',[1 1]);

xnum=(0:1:80);
figure
errorbar(Dist_along_PF,meancurvfromtip(1:length(Dist_along_PF)),stdcurvfromtip(1:length(Dist_along_PF)));
h=errorbar(Xfit,Zfit,Efit);
hold on
plot(xnum,f(xnum),'k-','LineWidth',1);

h.LineWidth=2;
h.Color=[1 0 0];
h.Marker='.';
h.MarkerSize=5;
grid on
hT1=title(['Aligned by tip: ', nameofdataset]);
hx1=xlabel('Distance from tip, nm');
hy1=ylabel('Angle,deg/dimer');
hT1.FontSize=14;
hx1.FontSize=14;
hy1.FontSize=14;
set(gca,'fontsize',14)

dlmwrite([savefolder,'\ang_vs_tip.txt'],[Dist_along_PF',...
    (meancurvfromtip(1:length(Dist_along_PF)))',...
    (stdcurvfromtip(1:length(Dist_along_PF)))'],'delimiter','\t','newline','pc');
dlmwrite([savefolder,'\ang_vs_tip_fit.txt'],[xnum' (f(xnum))],'delimiter','\t','newline','pc');

%% view 3D PFs
curv=[];
if VisQ==1
    figure('Units','normalized','Position',[0.12 0.15 0.8 0.7])
    for p=1:J
        Coord = [Xt2(:,p),Yt2(:,p),Zt2(:,p)];
        finpoint = find(sum(Coord~=0,2)>0,1,'last');
        Coord = Coord(1:finpoint,:);
        if size(Coord,1)>3
            
            [L2,R2,K2] = curvature(Coord);
            curv(2:length(R2)-1,p)=1./R2(2:length(R2)-1)/pi*180;
            
            subplot(2,2,[1,3])
            h = plot3(Coord(:,1),Coord(:,2),Coord(:,3));
            grid on;
            axis equal
            set(h,'marker','.','MarkerSize',12,'Color',[0.7,0.7,0.7],'LineWidth',1.5);
            xlabel x
            ylabel y
            zlabel z
            hold on
            r=plot3(Xt(2:finpoint+1,p),Yt(2:finpoint+1,p),Zt(2:finpoint+1,p));
            set(r,'Color',[0.3,0.3,0.3],'LineWidth',1);
            quiver3(Coord(:,1),Coord(:,2),Coord(:,3),K2(:,1),K2(:,2),K2(:,3));
            legend('Smoothed PF curve','Raw PF curve','Curvature vector',...
                'Location','northwest','FontSize',10,'EdgeColor','none')
            hold off
            
            subplot(2,2,2)
            plot(L2(2:size(Coord,1)-2),dB2(2:size(Coord,1)-2,p),'.-','MarkerSize',10,'LineWidth',1)
            xlabel('Length along PF, nm', 'FontSize', 12)
            ylabel('Helix angle (from pix to pix), deg', 'FontSize', 12)
            
            subplot(2,2,4)
            plot(L2(2:length(R2)-1),curv(2:length(R2)-1,p),'.-','MarkerSize',10,'LineWidth',1)
            xlabel('Length along PF, nm', 'FontSize', 12)
            ylabel('Curvature, deg/nm', 'FontSize', 12)
            
            pause
        end
    end
end

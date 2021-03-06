function demo
%% experimental settings
N=64; % window length
mRange=2:2:N; % sample size per window
numExp=1e2; % number of experiment
var_threshold = 0.05; % threshold for data training
tRange=0:.5:100; % threshold for hit/false alarm rate
%% load data
cpuFilename = 'cpuv4.txt';
s = load(cpuFilename);
write_data = s(:,4);
[L,~]=size(s);

% remove spike from the data
pspike = [139,1323,2501,3681,4855,7219];
write_data_noSpike = write_data;
write_data_noSpike(pspike) = (write_data(pspike-1)+write_data(pspike+1))/2;

pspike = ceil(pspike/N);
%% plot the original data
figure('Position', [100, 100, 500, 200]);plot(write_data)
axis([0 7.4e3 -100 1200])
xlabel('Time in second')
ylabel('Number of sectors written')
%%
hitRate=[];
falseAlarm=[];
for m=mRange     
    hit = zeros(1,length(tRange));
    fa = zeros(1,length(tRange));
    for n=1:numExp
        Gm = randn(m,N);
        Ph = GS(Gm')'; % sampling matrix
        %% use no spike data for training
        % apply compressive sampling for each window of length N
        st=1;ed=N;
        sample_noSpike = [];
        while ed<=L
            % sensing
            sample_noSpike = [sample_noSpike; Ph * write_data_noSpike(st:ed)];
            st=st+N;ed=ed+N;
        end
        % training        
        [Q sample_mean] = DataTraining(sample_noSpike,var_threshold,m);
        %% detect spikes in write_data which contains spikes        
        projections = [];
        st=1;ed=N;
        while ed<=L
            % testData: result of applying compressed sensing for each
            % window of length N
            testData = Ph * write_data(st:ed);
            % projection residual
            res = ProjectionResidual(testData,Q,sample_mean);
            projections = [projections res];
            st=st+N;ed=ed+N;
        end   
        %% calculate hit rate and false alarm rate        
        pp = 1;
        for t=tRange
            p = find(projections>t);
            % hit rate
            TD = intersect(p,pspike); 
            hit(pp) = hit(pp)+ length(TD)/length(pspike);
            % false alarm rate
            if ~isempty(p)
                fa(pp) = fa(pp)+1-length(TD)/length(p);
            end
            pp = pp+1;
        end
    end
    hitRate = [hitRate; hit/numExp];
    falseAlarm = [falseAlarm; fa/numExp];
end
%% plotting result of hit rate versus the sample size when false alarm rate
%% is fixed
fa=.005; % specify the fixed false alarm rate
hit =[];m=[];
for i=1:16
    p=find(falseAlarm(i,:)<=fa);
    if ~isempty(p)
        hit=[hit hitRate(i,p(1))];
        m=[m 2*i];
    end
end
m=m/N*100;
figure('Position', [100, 100, 500, 200]);plot(m,hit);
axis([min(m) max(m) 0 1])
xlabel('Sample size (as a percentage)')
ylabel('Hit rate')
% title(['False alarm = ' num2str(fa)])
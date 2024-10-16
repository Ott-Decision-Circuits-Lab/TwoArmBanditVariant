function AnalysisFigure = TwoArmBanditVariant_Cued(DataFile)
% Matching Analysis Function
% Developed by Antonio Lee @ BCCN Berlin
% Version 2.0 ~ April 2024

if nargin < 1
    global BpodSystem
    if isempty(BpodSystem) || isempty(BpodSystem.Data)
        [datafile, datapath] = uigetfile('\\ottlabfs.bccn-berlin.pri\ottlab\data\');
        load(fullfile(datapath, datafile));
        SessionDateTime = datapath(end-15:end-1);
    else
        SessionData = BpodSystem.Data;
        [~, name, ~] = fileparts(BpodSystem.Path.CurrentDataFile);
        SessionDateTime = name(end-14:end);
    end
elseif ischar(DataFile) || isstring(DataFile)
    load(DataFile);
    SessionDateTime = DataFile(end-18:end-4);
elseif isstruct(DataFile)
    SessionData = DataFile;

    % mismatch in time saved in .mat and the time used as file name
    SessionDateTime = strcat(datestr(SessionData.Info.SessionDate, 'yyyymmdd'), '_000000');
else
    disp('Error: Unknown input format. No further analysis can be performed.')
    return
end

if ~isfield(SessionData, 'SettingsFile')
    disp('Error: The selected file does not have the field "SettingsFile". No further Matching Analysis is performed.')
    AnalysisFigure = [];
    return
elseif ~isfield(SessionData.SettingsFile.GUIMeta, 'RiskType')
    disp('Error: The selected SessionFile may not be a TwoArmBanditVariant session. No further Matching Analysis is performed.')
    AnalysisFigure = [];
    return
% elseif ~strcmpi(SessionData.SettingsFile.GUIMeta.RiskType.String{SessionData.SettingsFile.GUI.RiskType}, 'Cued')
%     disp('Error: The selected SessionData is not a Cued session. No further Cued Analysis is performed.')
%     AnalysisFigure = [];
%     return
end

%% Load related data to local variabels
RatID = str2double(SessionData.Info.Subject);
if isnan(RatID)
    RatID = -1;
end
RatName = num2str(RatID);
% %%The following three lines doesn't not work, as the timestamp documented
% in the SessionData may not be the same as the one being used for saving
% Date = datestr(SessionData.Info.SessionDate, 'yyyymmdd');

nTrials = SessionData.nTrials;
if nTrials < 50
    disp('nTrial < 50. Impossible for analysis.')
    AnalysisFigure = [];
    return
end
ChoiceLeft = SessionData.Custom.TrialData.ChoiceLeft(1:nTrials);
Baited = SessionData.Custom.TrialData.Baited(:, 1:nTrials);
IncorrectChoice = SessionData.Custom.TrialData.IncorrectChoice(1:nTrials);
NoDecision = SessionData.Custom.TrialData.NoDecision(1:nTrials);
NoTrialStart = SessionData.Custom.TrialData.NoTrialStart(1:nTrials);
BrokeFixation = SessionData.Custom.TrialData.BrokeFixation(1:nTrials);
EarlyWithdrawal = SessionData.Custom.TrialData.EarlyWithdrawal(1:nTrials);
StartNewTrial = SessionData.Custom.TrialData.StartNewTrial(1:nTrials);
SkippedFeedback = SessionData.Custom.TrialData.SkippedFeedback(1:nTrials);
Rewarded = SessionData.Custom.TrialData.Rewarded(1:nTrials);

SampleTime = SessionData.Custom.TrialData.SampleTime(1:nTrials);
MoveTime = SessionData.Custom.TrialData.MoveTime(1:nTrials);
FeedbackWaitingTime = SessionData.Custom.TrialData.FeedbackWaitingTime(1:nTrials);
% FeedbackDelay = SessionData.Custom.TrialData.FeedbackDelay(1:nTrials);
% FeedbackWaitingTime = rand(nTrials,1)*10; %delete this
% FeedbackWaitingTime = FeedbackWaitingTime';  %delete this
% FeedbackDelay = rand(nTrials,1)*10; %delete this
% FeedbackDelay= FeedbackDelay'; 

RewardProb = SessionData.Custom.TrialData.RewardProb(:, 1:nTrials);
LightLeft = SessionData.Custom.TrialData.LightLeft(1:nTrials);
LightLeftRight = [LightLeft; 1-LightLeft]; 
ChoiceLeftRight = [ChoiceLeft; 1-ChoiceLeft]; 

BlockNumber = SessionData.Custom.TrialData.BlockNumber(:, 1:nTrials);
BlockTrialNumber = SessionData.Custom.TrialData.BlockTrialNumber(:, 1:nTrials);

% for files before April 2023, no DrinkingTime is available
try
    DrinkingTime = SessionData.Custom.TrialData.DrinkingTime(1:nTrials);
catch
    DrinkingTime = nan(1, nTrials);
end

LeftFeedbackDelayGraceTime = [];
RightFeedbackDelayGraceTime = [];
FirstDrinkingTime = [];
LatestRewardTimestamp = [];
for iTrial = 1:nTrials
    if ChoiceLeft(iTrial) == 1
        LeftFeedbackDelayGraceTime = [LeftFeedbackDelayGraceTime;...
                                      SessionData.RawEvents.Trial{iTrial}.States.LInGrace(:,2) -...
                                      SessionData.RawEvents.Trial{iTrial}.States.LInGrace(:,1)];
    elseif ChoiceLeft(iTrial) == 0
        RightFeedbackDelayGraceTime = [RightFeedbackDelayGraceTime;...
                                       SessionData.RawEvents.Trial{iTrial}.States.RInGrace(:,2) -...
                                       SessionData.RawEvents.Trial{iTrial}.States.RInGrace(:,1)];
    end
    
    FirstDrinkingTime = [FirstDrinkingTime SessionData.RawEvents.Trial{iTrial}.States.Drinking(1,1)];
    if iTrial == 1
        LatestRewardTimestamp(iTrial) = 0;
    elseif isnan(SessionData.RawEvents.Trial{iTrial-1}.States.Drinking(1,1))
        LatestRewardTimestamp(iTrial) = LatestRewardTimestamp(iTrial-1);
    else
        LatestRewardTimestamp(iTrial) = SessionData.RawEvents.Trial{iTrial-1}.States.Drinking(1,1) + SessionData.TrialStartTimestamp(iTrial-1);
    end
end
LatestRewardTime = SessionData.TrialStartTimestamp - LatestRewardTimestamp;

LeftFeedbackDelayGraceTime = LeftFeedbackDelayGraceTime(~isnan(LeftFeedbackDelayGraceTime))';
LeftFeedbackDelayGraceTime = LeftFeedbackDelayGraceTime(LeftFeedbackDelayGraceTime < SessionData.SettingsFile.GUI.FeedbackDelayGrace - 0.0001);
RightFeedbackDelayGraceTime = RightFeedbackDelayGraceTime(~isnan(RightFeedbackDelayGraceTime))';
RightFeedbackDelayGraceTime = RightFeedbackDelayGraceTime(RightFeedbackDelayGraceTime < SessionData.SettingsFile.GUI.FeedbackDelayGrace - 0.0001);

%% Common plots regardless of task design/ risk type
% colour palette for events (suitable for most colourblind people)
scarlet = [254, 60, 60]/255; % for incorrect sign, contracting with azure
denim = [31, 54, 104]/255; % mainly for unsuccessful trials
azure = [0, 162, 254]/255; % for rewarded sign

neon_green = [26, 255, 26]/255; % for NotBaited
neon_purple = [168, 12, 180]/255; % for SkippedBaited

sand = [225, 190 106]/255; % for left-right
turquoise = [64, 176, 166]/255;
LRPalette = [sand; turquoise];

carrot = [230, 97, 0]/255; % explore
violet = [93, 58, 155]/255; % exploit

% colour palette for cues: (1- P(r)) * 128 + 127
% P(0) = white; P(1) = smoky gray
RewardProbCategories = unique(RewardProb);
CuedPalette = ((1 - RewardProbCategories) * [128 128 128])/255;

% create figure
AnalysisFigure = figure('Position', [   0    0 1191  842],... % DIN A3, 72 ppi (window will crop it to _ x 1024, same as disp resolution)
                        'NumberTitle', 'off',...
                        'Name', strcat(RatName, '_', SessionDateTime, '_Cued'),...
                        'MenuBar', 'none',...
                        'Resize', 'off');

FrameAxes = axes(AnalysisFigure, 'Position', [0 0 1 1]); % spacer for correct saving dimension
set(FrameAxes,...
    'XTick', [],...
    'YTick', [],...
    'XColor', 'w',...
    'YColor', 'w')

%% Figure Info
FigureInfoAxes = axes(AnalysisFigure, 'Position', [0.01    0.96    0.48    0.01]);
set(FigureInfoAxes,...
    'XTick', [],...
    'YTick', [],...
    'XColor', 'w',...
    'YColor', 'w')

FigureTitle = strcat(RatName, '_', SessionDateTime, '_Cued');

FigureTitleText = text(FigureInfoAxes, 0, 0,...
                       FigureTitle,...
                       'FontSize', 14,...
                       'FontWeight','bold',...
                       'Interpreter', 'none');

%% NotBaited Waiting Time (TI) per cue across session
TrialTIAxes = axes(AnalysisFigure, 'Position', [0.01    0.82    0.37    0.11]);
hold(TrialTIAxes, 'on');
if ~isempty(ChoiceLeft) && ~all(isnan(ChoiceLeft))
    if any(isnan(LightLeft)) % usually 2-arm task
        TrialRewardProb = max(RewardProb .* ChoiceLeftRight, [], 1);
    else % usually 1-arm task
        TrialRewardProb = max(RewardProb .* LightLeftRight, [], 1);
    end
    
    NotBaited = any(~Baited .* ChoiceLeftRight, 1) & (IncorrectChoice ~= 1); 

    for i = 1:length(RewardProbCategories)
        % NotBaited invested time per cue across session
        CueSortedNotBaitedIdx = find(NotBaited & TrialRewardProb == RewardProbCategories(i));
        TrialTIPlot(i) = plot(TrialTIAxes, CueSortedNotBaitedIdx, FeedbackWaitingTime(CueSortedNotBaitedIdx),...
                              'Marker', '.',...
                              'MarkerSize', 4,...
                              'MarkerEdgeColor', 1-CuedPalette(i,:),...
                              'Color', CuedPalette(i,:));

        [RValue, PValue] = corrcoef(TrialTIPlot(i).XData, TrialTIPlot(i).YData);
        CueSortedNotBaitedRvalue(i) = RValue(1, 2);
        CueSortedNotBaitedPValue(i) = PValue(1, 2);

        Label{i} = sprintf('P(r) = %3.1f\nR = %5.2f\np = %6.3f',...
                           RewardProbCategories(i),...
                           CueSortedNotBaitedRvalue(i),...
                           CueSortedNotBaitedPValue(i));
    end

    for i = 1:length(RewardProbCategories) % plot all NotBaited first for legend
        % Incorrect invested time per Trial RewardProb (not Choice RewardProb) across session
        CueSortedIncorrectChoiceIdx = find(IncorrectChoice == 1 & TrialRewardProb == RewardProbCategories(i));
        if isempty(CueSortedIncorrectChoiceIdx)
            continue
        end
        TrialIncorrectChoiceTIPlot(i) = plot(TrialTIAxes, CueSortedIncorrectChoiceIdx, FeedbackWaitingTime(CueSortedIncorrectChoiceIdx),...
                                             'Marker', '.',...
                                             'MarkerSize', 4,...
                                             'MarkerEdgeColor', scarlet .* CuedPalette(i,:),...
                                             'LineStyle', 'none');
        
    end
    
    TrialTILegend = legend(TrialTIAxes, Label,...
                           'Position', [0.01    0.73    0.37    0.05],...
                           'NumColumns', 2);

    set(TrialTIAxes,...
        'TickDir', 'out',...
        'YLim', [0, max(1, SessionData.SettingsFile.GUI.FeedbackDelayMax * 1.5)],...
        'YAxisLocation', 'right',...
        'FontSize', 10);
    ylabel(TrialTIAxes, sprintf('NotBaited\nWaiting Time (s)'))
    % title('Block switching behaviour')
end

%% L-R Cued TI
LRCueTIAxes = axes(AnalysisFigure, 'Position', [0.46    0.82    0.11    0.11]);
hold(LRCueTIAxes, 'on')

for i = 1:length(RewardProbCategories)
    CueSortedNotBaitedIdx = TrialTIPlot(i).XData;
    LeftCueSortedIdx = CueSortedNotBaitedIdx(ChoiceLeft(CueSortedNotBaitedIdx) == 1);
    LeftCueSortedTI = FeedbackWaitingTime(LeftCueSortedIdx);
    
    RightCueSortedIdx = CueSortedNotBaitedIdx(ChoiceLeft(CueSortedNotBaitedIdx) == 0);
    RightCueSortedTI = FeedbackWaitingTime(RightCueSortedIdx);

    LeftCueSortedTISwarmchart(i) = swarmchart(LRCueTIAxes,...
                                              -0.05 + RewardProbCategories(i) * ones(size(LeftCueSortedTI)),...
                                              LeftCueSortedTI,...
                                              'Marker', '.',...
                                              'MarkerEdgeColor', sand,...
                                              'XJitter', 'density',...
                                              'XJitterWidth', 0.1);

    RightCueSortedTISwarmchart(i) = swarmchart(LRCueTIAxes,...
                                               0.05 + RewardProbCategories(i) * ones(size(RightCueSortedTI)),...
                                               RightCueSortedTI,...
                                               'Marker', '.',...
                                               'MarkerEdgeColor', turquoise,...
                                               'XJitter', 'density',...
                                               'XJitterWidth', 0.1);
end

set(LRCueTIAxes,...
    'TickDir', 'out',...
    'FontSize', 10);
xlabel(LRCueTIAxes, 'Reward Probability')

%% Reward rate decay rate (Tau) estimation using low reward prob (more data points)
RewardMagnitude = SessionData.Custom.TrialData.RewardMagnitude(:, 1:nTrials);
RewardedMagnitude = sum(RewardMagnitude .* ChoiceLeftRight) .* Rewarded;
RewardedMagnitude(isnan(RewardedMagnitude)) = 0;

TrialStartTimestamp = SessionData.TrialStartTimestamp(:, 1:nTrials) - SessionData.TrialStartTimestamp(1);
TrialTimeDuration = [0 diff(TrialStartTimestamp)];

TimeReward = nan(1, nTrials);
for iTrial = 1:nTrials
    statetimes = SessionData.RawEvents.Trial{iTrial}.States;
    if ChoiceLeft(iTrial) == 1
        TimeReward(iTrial) = statetimes.WaterL(1,1);
    elseif ChoiceLeft(iTrial) == 0
        TimeReward(iTrial) = statetimes.WaterR(1,1);
    end
end

AbsTimeReward = TrialStartTimestamp + TimeReward;

TimeDiffFromLast20Rewards = [];
RewardedHistory = [];
for iTrialBack = 1:20
    TimeDiffFromLast20Rewards(iTrialBack, :) = TrialStartTimestamp(21:nTrials) - AbsTimeReward(21-iTrialBack:nTrials-iTrialBack);
    RewardedHistory(iTrialBack, :) = Rewarded(21-iTrialBack:nTrials-iTrialBack);
end

LowRewardProbTITrial = NotBaited & TrialRewardProb == RewardProbCategories(1);
ValidTrial = LowRewardProbTITrial;
ValidTrial(1:20) = false;

Tau = 5:5:100;
LowRewardProbTI = FeedbackWaitingTime(ValidTrial);
RValue = [];
PValue = [];
for iTau = 1:length(Tau)
    DiscountedReward = RewardedHistory .* exp(-TimeDiffFromLast20Rewards/Tau(iTau));
    DiscountedReward(isnan(DiscountedReward)) = 0;
    EstimatedRewardRate = sum(DiscountedReward, 1);
    [R,P] = corrcoef(EstimatedRewardRate(ValidTrial(21:end)), LowRewardProbTI);
    RValue(iTau) = R(1, 2);
    PValue(iTau) = P(1, 2);
end

TITauEstimationAxes = axes(AnalysisFigure, 'Position', [0.01    0.53    0.17    0.15]);
hold(TITauEstimationAxes, 'on')

TITauRValueLine = line(TITauEstimationAxes,...
                       'XData', Tau,...
                       'YData', RValue,...
                       'Color', [1, 1, 1] * 0.8,...
                       'LineStyle', '-');

TITauPValueLine = line(TITauEstimationAxes,...
                       'XData', Tau(PValue<0.05),...
                       'YData', RValue(PValue<0.05),...
                       'Color', [1, 1, 1] * 0,...
                       'LineStyle', 'none',...
                       'Marker', '*');

set(TITauEstimationAxes,...
    'TickDir', 'out',...
    'YAxisLocation', 'right',...
    'FontSize', 10)
xlabel(TITauEstimationAxes, '\tau (s)')
ylabel(TITauEstimationAxes, 'R Value')
title(TITauEstimationAxes, 'NotBaited Waiting Time')

%% Cued-sorted TI against background reward rate (trial^-1)
RewardedHistory = 0;
for iTrial = 1:nTrials-1
    RewardedHistory(iTrial+1) = RewardedHistory(iTrial) * exp(-TrialTimeDuration(iTrial+1)/Tau(9)) + RewardedMagnitude(iTrial);
end

TIRewardRateAxes = axes(AnalysisFigure, 'Position', [0.01    0.32    0.17    0.15]);
hold(TIRewardRateAxes, 'on')

for iRewardProb = 1:length(RewardProbCategories)
    TITrial = NotBaited & TrialRewardProb == RewardProbCategories(iRewardProb);
    
    TIRewardRateScatter{iRewardProb} = scatter(TIRewardRateAxes,...
                                               RewardedHistory(TITrial),...
                                               FeedbackWaitingTime(TITrial),...
                                               'Marker', '.',...
                                               'MarkerEdgeColor', CuedPalette(iRewardProb, :),...
                                               'SizeData', 8);
end

set(TIRewardRateAxes,...
    'TickDir', 'out',...
    'YAxisLocation', 'right',...
    'FontSize', 10)
xlabel(TIRewardRateAxes, 'Reward Rate')
ylabel(TIRewardRateAxes, 'NotBaited Waiting Time (s)')

%% Model prediction of NotBaited Invested Time
%{
PredictedNotBaitedInvestedTimeAxes = axes(AnalysisFigure, 'Position', [0.09    0.09    0.18    0.16]);
hold(PredictedNotBaitedInvestedTimeAxes, 'on');

if ~isempty(ChoiceLeft) && ~all(isnan(ChoiceLeft))
    % Estimated Reward Rate is defined here as geometrically weighted
    % rewarded trial history
    DiscountRate = 1-exp(-1); % arbitary
    HistoryKernelLength = 10; % with RewardRate ~<= 20% trials, only once in six trials is rewarded
    Kernel = DiscountRate.^(0:HistoryKernelLength-1);
    Rewards = Rewarded == 1;
    for i = 1:HistoryKernelLength
        RewardedHistory(i, :) = [zeros(1, i) Rewards(1:end-i)];
    end
    
    EstimatedRewardRate = Kernel * RewardedHistory;
    ConsumedWaterPercentage = cumsum(Rewarded == 1)./sum(Rewarded==1);

    XData = [TrialRewardProb; ConsumedWaterPercentage; EstimatedRewardRate]';
    GLM = fitglm(XData(NotBaited, :), FeedbackWaitingTime(NotBaited)',...
                 'reciprocal(y) ~ 1 + x1*x3 + x2',...
                 'Distribution', 'gamma') % use normal for now, but gamma may be better for non-zero
    
    % Plot prediction based on current best model
    PredictedNotBaitedInvestedTimeSwarmchart = [];
    for i = 1:length(RewardProbCategories)
        Predictor = XData(NotBaited' & XData(:,1)==RewardProbCategories(i), :);
        PredictedTI = predict(GLM, Predictor);
        PredictedNotBaitedInvestedSwarmchart(i) = ...
            swarmchart(PredictedNotBaitedInvestedTimeAxes,...
                       Predictor(:,1), PredictedTI,...
                       'Marker', '.',...
                       'MarkerEdgeColor', CuedPalette(i,:),...
                       'XJitter', 'density',...
                       'XJitterWidth', 0.15);
    end
    
    set(PredictedNotBaitedInvestedTimeAxes,...
        'TickDir', 'out',...
        'XLim', [0, 1],...
        'YLim', [0, max(1, SessionData.SettingsFile.GUI.FeedbackDelayMax * 1.5)],...
        'FontSize', 10);
    % title('NotBaited Invested Time', 'FontSize', 12)
    xlabel(PredictedNotBaitedInvestedTimeAxes,...
           'Reward Prob',...
           'FontSize', 12,...
           'FontWeight', 'bold')
    ylabel(PredictedNotBaitedInvestedTimeAxes,...
           sprintf('Predicted NotBaited\nInvested Time (s)'),...
           'FontSize', 12,...
           'FontWeight', 'bold')
    
    PredictedNotBaitedInvestedTimeBoxchart = ...
        boxchart(PredictedNotBaitedInvestedTimeAxes,...
                 XData(NotBaited, 1), predict(GLM, XData(NotBaited, :)));
    set(PredictedNotBaitedInvestedTimeBoxchart,...
        'BoxWidth', 0.05,...
        'BoxFaceColor', 'k',...
        'BoxFaceAlpha', 0,...
        'MarkerStyle', 'none',...
        'LineWidth', 0.2);
    
    disp('YOu aRE fuNNy.')
%}

%                 FeedbackWaitingTimeStats = grpstats(NotBaitedTrialData,...
%                                                     'TrialRewardProb', {'mean', 'std'},...
%                                                     'DataVars', 'FeedbackWaitingTime',...
%                                                     'VarNames', {'Pr', 'Count', 'Mean', 'Std'});
%                 
%                 FeedbackWaitingTimeStatsText = [];
%                 for i = 1:length(FeedbackWaitingTimeStats.Pr)
%                     FeedbackWaitingTimeStatsText(i) = text(FeedbackWaitingTimeAxes, RewardProbCategories(i), FeedbackWaitingTimeAxes.YLim(2) * -0.4,...
%                                                            sprintf('%3.0f\n%5.3f\n%5.3f',...
%                                                                    FeedbackWaitingTimeStats.Count(i),...
%                                                                    FeedbackWaitingTimeStats.Mean(i),...
%                                                                     FeedbackWaitingTimeStats.Std(i)),...
%                                                            'FontSize', 10,...
%                                                            'HorizontalAlignment', 'center');
%                 end
%                 FeedbackWaitingTimeStatsText(i+1) = text(FeedbackWaitingTimeAxes, 0, FeedbackWaitingTimeAxes.YLim(2) * -0.4,...
%                                                          sprintf('Count\nMean\nStd'),...
%                                                          'FontSize', 10,...
%                                                          'HorizontalAlignment', 'right');
end

%{
%%%%% Trying things out %%%%%
%% Inter-reward interval across session
TrialInterRewardIntervalHandle = axes(FigHandle, 'Position', [0.01    0.50    0.48    0.09]);
hold(TrialInterRewardIntervalHandle, 'on');
if ~isempty(ChoiceLeft) && ~all(isnan(ChoiceLeft))
    FirstDrinkingTimestamp = FirstDrinkingTime + SessionData.TrialStartTimestamp;
    InterRewardInterval = FirstDrinkingTimestamp(RewardedndxTrial(2:end)) - FirstDrinkingTimestamp(RewardedndxTrial(1:end-1));
    InterRewardInterval = [FirstDrinkingTimestamp(RewardedndxTrial(1)) InterRewardInterval];
    TrialInterRewardIntervalPlotHandle = plot(TrialInterRewardIntervalHandle, RewardedndxTrial, InterRewardInterval,...
                                              'Marker', '.',...
                                              'MarkerSize', 4,...
                                              'MarkerEdgeColor', azure,...
                                              'LineStyle', 'none');
    
    set(TrialInterRewardIntervalHandle,...
        'TickDir', 'in',...
        'Xlim', TrialOverviewHandle.XLim,...
        'XTickLabel', [],...
        'XAxisLocation', 'bottom',...
        'YLim', [0, 350],...
        'YAxisLocation', 'right',...
        'FontSize', 10);
    ylabel('Inter-reward Time (s)')
end

%% Correlation between weighted reward history and NotBaited Invested Time
InvestedTimeRewardRateAxes = axes(FigHandle, 'Position', [0.07    0.09    0.18    0.16]);
hold(InvestedTimeRewardRateAxes, 'on');

if ~isempty(ChoiceLeft) && ~all(isnan(ChoiceLeft))
    % Estimated Reward Rate is defined here as geometrically weighted
    % rewarded trial history
    DiscountRate = 0.9; % arbitary
    HistoryKernelLength = 10; % with RewardRate ~<= 20% trials, only once in six trials is rewarded
    Kernel = flip(DiscountRate.^(0:HistoryKernelLength-1));
    RewardedHistory = repmat(Rewarded == 1, HistoryKernelLength, 1);
    TrialCueHistory = repmat(TrialRewardProb, HistoryKernelLength, 1);
    for i = 1:HistoryKernelLength
        RewardedHistory(i, :) = circshift(RewardedHistory(i, :), HistoryKernelLength + 1 - i);
        RewardedHistory(i, 1:HistoryKernelLength + 1 - i) = 0;
        
        TrialCueHistory(i, :) = circshift(TrialCueHistory(i, :), HistoryKernelLength - i);
        TrialCueHistory(i, 1:HistoryKernelLength - i) = 0;
    end
    
    EstimatedRewardRate = Kernel * RewardedHistory;
    EstimatedRewardLandscape = Kernel * TrialCueHistory;
    
    for i = 1:length(RewardProbCategories)
        CueSortedNotBaitedIdx = find(TrialDataTable.NotBaited & TrialDataTable.TrialRewardProb == RewardProbCategories(i));
        NotBaitedInvestedTimeRewardRateScatterPlot(i) = scatter(InvestedTimeRewardRateAxes, EstimatedRewardRate(CueSortedNotBaitedIdx), FeedbackWaitingTime(CueSortedNotBaitedIdx), 16,...
                                                                'Marker', 'o',...
                                                                'MarkerEdgeColor', 1-CuedPalette(i,:),...
                                                                'MarkerFaceColor', CuedPalette(i,:));
        
%                 CueSortedIncorrectChoiceIdx = find(TrialDataTable.IncorrectChoice == 1 & TrialDataTable.TrialRewardProb == RewardProbCategories(i));
%                 if isempty(CueSortedIncorrectChoiceIdx)
%                     continue
%                 end
%                 IncorrectChoiceInvestedTimeRewardRateScatterPlot(i) = plot(TrialInvestedTimeHandle, CueSortedIncorrectChoiceIdx, TrialDataTable.FeedbackWaitingTime(CueSortedIncorrectChoiceIdx),...
%                                                                      'Marker', '.',...
%                                                                      'MarkerEdgeColor', scarlet .* CuedPalette(i,:),...
%                                                                      'LineStyle', 'none');
    end
end

set(InvestedTimeRewardRateAxes,...
    'XLim', [-0.5 5],...
    'YLim', [0, max(1, SessionData.SettingsFile.GUI.FeedbackDelayMax * 1.5)],...
    'FontSize', 10)
xlabel('Estimated Reward Rate', 'FontSize', 12, 'FontWeight', 'bold')
ylabel('NotBaited Invested Time(s)', 'FontSize', 12, 'FontWeight', 'bold')
disp('YOu aRE fuNNy.')
%}

%{
if model
    %% psychometric
    PsychometricAxes = axes(AnalysisFigure, 'Position', [0.23    0.56    0.15    0.11]);
    hold(PsychometricAxes, 'on')
    
    set(PsychometricAxes,...
        'FontSize', 10,...
        'XLim', [-5 5],...
        'YLim', [0, 100],...
        'YAxisLocation', 'right')
    title(PsychometricAxes, 'Psychometric')
    xlabel('log(odds)')
    ylabel('Left Choices (%)')
    
    % Choice Psychometric
    ValidTrial = ~isnan(ChoiceLeft); % and EarlyWithdrawal is always 0
    NotBaitedLogOdds = LogOdds(ValidTrial);
    NotBaitedChoice = ChoiceLeft(ValidTrial);
    dvbin = linspace(-max(abs(NotBaitedLogOdds)), max(abs(NotBaitedLogOdds)), 10);
    [xdata, ydata, error] = BinData(NotBaitedLogOdds, NotBaitedChoice, dvbin);
    vv = ~isnan(xdata) & ~isnan(ydata) & ~isnan(error);
    
    ChoicePsychometricErrorBar = errorbar(PsychometricAxes, xdata(vv), ydata(vv)*100, error(vv)*100,...
                                          'LineStyle', 'none',...
                                          'LineWidth', 1.5,...
                                          'Color', 'k',...
                                          'Marker', 'o',...
                                          'MarkerEdgeColor', 'k');
    
    PsychometricGLM = fitglm(NotBaitedLogOdds, NotBaitedChoice(:), 'Distribution', 'binomial');
    PsychometricGLMPlot = plot(PsychometricAxes, xdata, predict(PsychometricGLM, xdata)*100, '-', 'Color', [.5,.5,.5], 'LineWidth', 0.5);
    
    %% Coefficient of Lau-Glimcher GLM
    ModelCoefficientAxes = axes(AnalysisFigure, 'Position', [0.04    0.56    0.15    0.11]);
    hold(ModelCoefficientAxes, 'on');
    
    set(ModelCoefficientAxes, 'FontSize', 10)
    xlabel(ModelCoefficientAxes, 'iTrial back');
    ylabel(ModelCoefficientAxes, 'Coeff.');
    title(ModelCoefficientAxes, 'GLM Fitted Coefficients')
    
    xdata = 1:HistoryKernelSize;
    ydataChoice = LauGlimcherGLM.Coefficients.Estimate(2:1+HistoryKernelSize);
    ydataReward = LauGlimcherGLM.Coefficients.Estimate(7:1+2*HistoryKernelSize);
    intercept = LauGlimcherGLM.Coefficients.Estimate(1);

    ChoiceHistoryCoefficientPlot = plot(ModelCoefficientAxes, xdata, ydataChoice', '-k');
    RewardHistoryCoefficientPlot = plot(ModelCoefficientAxes, xdata, ydataReward', '--k');
    InterceptPlot = plot(ModelCoefficientAxes, xdata, intercept.*ones(size(xdata)), '-.k');
    
    ModelCoefficientLegend = legend(ModelCoefficientAxes, {'Choice (L/R=±1)', 'Reward (L/R=±1)', 'Intercept'},...
                                    'Position', [0.15    0.62    0.12    0.05],...
                                    'NumColumns', 1,...
                                    'Box', 'off');
    
    %% Residual Histogram
    ResidualHistogramAxes = axes(AnalysisFigure, 'Position', [0.04    0.36    0.15    0.11]);
    ResidualHistogram = plotResiduals(LauGlimcherGLM, 'Histogram');
    
    %% Residual Histogram
    ResidualLaggedAxes = axes(AnalysisFigure, 'Position', [0.23    0.36    0.15    0.11]);
    ResidualLagged = plotResiduals(LauGlimcherGLM, 'lagged', 'Marker', '.', 'MarkerSize', 1);
    
    %% Residual Histogram
    ResidualFittedAxes = axes(AnalysisFigure, 'Position', [0.04    0.19    0.15    0.11]);
    ResidualFitted = plotResiduals(LauGlimcherGLM, 'fitted', 'Marker', '.', 'MarkerSize', 1);
    
    %% Residual Histogram
    ResidualProbabilityAxes = axes(AnalysisFigure, 'Position', [0.23    0.19    0.15    0.11]);
    ResidualProbability = plotResiduals(LauGlimcherGLM, 'Probability', 'Marker', '.', 'MarkerSize', 1);
    
    if ~all(isnan(FeedbackWaitingTime))
        %% Time Investment (TI) (only NotBaited Waiting Time) across session 
        TrialTIAxes = axes(AnalysisFigure, 'Position', [0.45    0.82    0.37    0.11]);
        hold(TrialTIAxes, 'on');
        
        NotBaited = any(~Baited .* ChoiceLeftRight, 1) & (IncorrectChoice ~= 1);
        Exploit = ChoiceLeft == (LogOdds'>0);
        
        ExploringTITrial = NotBaited & ~Exploit;
        ExploitingTITrial = NotBaited & Exploit;
        ExploringTI = FeedbackWaitingTime(ExploringTITrial);
        ExploitingTI = FeedbackWaitingTime(ExploitingTITrial);
        
        % NotBaited invested time per explore/exploit across session
        TrialExploringTIPlot = plot(TrialTIAxes, idxTrial(ExploringTITrial), ExploringTI,...
                                    'Marker', '.',...
                                    'MarkerSize', 4,...
                                    'MarkerEdgeColor', carrot,...
                                    'Color', 'none');
        
        TrialExploitingTIPlot = plot(TrialTIAxes, idxTrial(ExploitingTITrial), ExploitingTI,...
                                     'Marker', '.',...
                                     'MarkerSize', 4,...
                                     'MarkerEdgeColor', violet,...
                                     'Color', 'none');
        
        VevaiometryLegend = legend(TrialTIAxes, {'Explore', 'Exploit'},...
                                   'Box', 'off',...
                                   'Position', [0.75    0.90    0.05    0.03]);

        set(TrialTIAxes,...
            'TickDir', 'out',...
            'XLim', BlockSwitchAxes.XLim,...
            'YLim', [0, max(1, SessionData.SettingsFile.GUI.FeedbackDelayMax * 1.5)],...
            'YAxisLocation', 'right',...
            'FontSize', 10);
        ylabel('Invested Time (s)')
        % title('Block switching behaviour')
        
        %% plot vevaiometric      
        VevaiometricAxes = axes(AnalysisFigure, 'Position', [0.88    0.82    0.10    0.11]);
        hold(VevaiometricAxes, 'on')
        
        ExploringLogOdds = LogOdds(ExploringTITrial);
        ExploitingLogOdds = LogOdds(ExploitingTITrial);
        
        ExploringTrialTIScatter = scatter(VevaiometricAxes, ExploringLogOdds, ExploringTI,...
                                          'Marker', '.',...
                                          'MarkerEdgeColor', carrot,...
                                          'SizeData', 18);
        
        ExploitingTrialTIScatter = scatter(VevaiometricAxes, ExploitingLogOdds, ExploitingTI,...
                                           'Marker', '.',...
                                           'MarkerEdgeColor', violet,...
                                           'SizeData', 18);
    
        [ExploreLineXData, ExploreLineYData] = Binvevaio(ExploringLogOdds, ExploringTI, 10);
        [ExploitLineXData, ExploitLineYData] = Binvevaio(ExploitingLogOdds, ExploitingTI, 10);
        
        ExplorePlot = plot(VevaiometricAxes, ExploreLineXData, ExploreLineYData,...
                           'Color', carrot,...
                           'LineWidth', 2);       
        
        ExploitPlot = plot(VevaiometricAxes, ExploitLineXData, ExploitLineYData,...
                           'Color', violet,...
                           'LineWidth', 2);
        
        set(VevaiometricAxes,...
            'FontSize', 10,...
            'YAxisLocation', 'right',...
            'XLim', [-5 5],...
            'YLim', [0 SessionData.SettingsFile.GUI.FeedbackDelayMax * 1.5])
        title(VevaiometricAxes, 'Vevaiometric');
        xlabel(VevaiometricAxes, 'log(odds)');
        % ylabel(VevaiometricAxes, 'Invested Time (s)');
        
        %% Psychometrics of NotBaited Choice with High- and Low-time investment (TI)
        % Time investment is limited to NotBaited trials
        TISortedPsychometricAxes = axes(AnalysisFigure, 'Position', [0.45    0.56    0.15    0.11]);
        hold(TISortedPsychometricAxes, 'on')
        
        TI = FeedbackWaitingTime(NotBaited);
        TImed = median(TI, "omitnan");
        HighTITrial = FeedbackWaitingTime>TImed & NotBaited;
        LowTITrial = FeedbackWaitingTime<=TImed & NotBaited;
        
        [xdata, ydata, error] = BinData(LogOdds(HighTITrial), ChoiceLeft(HighTITrial), dvbin);
        vv = ~isnan(xdata) & ~isnan(ydata) & ~isnan(error);
    
        HighTIErrorBar = errorbar(TISortedPsychometricAxes, xdata(vv), ydata(vv)*100, error(vv)*100,...
                                  'LineStyle', 'none',...
                                  'LineWidth', 1,...
                                  'Marker', 'o',...
                                  'MarkerFaceColor', 'none',...
                                  'MarkerEdgeColor', 'k',...
                                  'Color', 'k');
    
        [xdata, ydata, error] = BinData(LogOdds(LowTITrial), ChoiceLeft(LowTITrial), dvbin);
        vv = ~isnan(xdata) & ~isnan(ydata) & ~isnan(error);
    
        LowTIErrorBar = errorbar(TISortedPsychometricAxes, xdata(vv), ydata(vv)*100, error(vv)*100,...
                                 'LineStyle', 'none',...
                                 'LineWidth', 1,...
                                 'Marker', 'o',...
                                 'MarkerFaceColor', 'none',...
                                 'MarkerEdgeColor', [0.5 0.5 0.5],...
                                 'Color', [0.5 0.5 0.5]);
        
        HighTIGLM = fitglm(LogOdds(HighTITrial), ChoiceLeft(HighTITrial), 'Distribution', 'binomial');
        HighTIGLMPlot = plot(TISortedPsychometricAxes, xdata, predict(HighTIGLM, xdata)*100,...
                             'Marker', 'none',...
                             'Color', 'k',...
                             'LineWidth', 0.5);
    
        LowTIGLM = fitglm(LogOdds(LowTITrial), ChoiceLeft(LowTITrial), 'Distribution', 'binomial');
        LowTIGLMPlot = plot(TISortedPsychometricAxes, xdata, predict(LowTIGLM, xdata)*100,...
                            'Marker', 'none',...
                            'Color', [0.5, 0.5, 0.5],...
                            'LineWidth', 0.5);
        
        TIPsychometricLegend = legend(TISortedPsychometricAxes, {'High TI','Low TI'},...
                                      'Box', 'off',...
                                      'Position', [0.55    0.57    0.05    0.03]);
        
        set(TISortedPsychometricAxes,...
            'FontSize', 10,...
            'XLim', [-5 5],...
            'YLim', [0, 100])
        title(TISortedPsychometricAxes, 'TI Sorted Psychometric')
        xlabel('log(odds)')
        % ylabel('Left Choices (%)')
        
        %% callibration plot
        CalibrationAxes = axes(AnalysisFigure, 'Position', [0.66    0.56    0.15    0.11]);
        hold(CalibrationAxes, 'on')
        
        Correct = Exploit(NotBaited); %'correct'
        edges = linspace(min(TI), max(TI), 8);
        
        [xdata, ydata, error] = BinData(TI, Correct, edges);
        vv = ~isnan(xdata) & ~isnan(ydata) & ~isnan(error);
        CalibrationErrorBar = errorbar(CalibrationAxes,...
                                       xdata(vv), ydata(vv)*100, error(vv),...
                                       'LineWidth', 2, ...
                                       'Color', 'k');
        
        set(CalibrationAxes,...
            'FontSize', 10,...
            'XLim', [0 SessionData.SettingsFile.GUI.FeedbackDelayMax * 1.5])
        % title(CalibrationHandle, 'Calibration');
        xlabel(CalibrationAxes, 'Invested Time (s)');
        ylabel(CalibrationAxes, 'Exploit Ratio (%)');
        
        %% Time Investment (TI) (only NotBaited Waiting Time) across session 
        LRTrialTIAxes = axes(AnalysisFigure, 'Position', [0.45    0.36    0.37    0.11]);
        hold(LRTrialTIAxes, 'on');
        
        % Smoothed NotBaited invested time per left/right across session
        LeftTITrial = NotBaited & ChoiceLeft==1;
        RightTITrial = NotBaited & ChoiceLeft==0;
        LeftTI = FeedbackWaitingTime(LeftTITrial);
        RightTI = FeedbackWaitingTime(RightTITrial);
        
        TrialLeftTIPlot = plot(LRTrialTIAxes, idxTrial(LeftTITrial), smooth(LeftTI),...
                               'LineStyle', 'none',...
                               'Marker', '.',...
                               'MarkerSize', 4,...
                               'MarkerEdgeColor', sand);
        
        TrialRightTIPlot = plot(LRTrialTIAxes, idxTrial(RightTITrial), smooth(RightTI),...
                                'LineStyle', 'none',...
                                'Marker', '.',...
                                'MarkerSize', 4,...
                                'MarkerEdgeColor', turquoise);
        
        LRVevaiometryLegend = legend(LRTrialTIAxes, {'Left', 'Right'},...
                                     'Box', 'off',...
                                     'Position', [0.75    0.44    0.05    0.03]);

        set(LRTrialTIAxes,...
            'TickDir', 'out',...
            'XLim', BlockSwitchAxes.XLim,...
            'YLim', [0, max(1, SessionData.SettingsFile.GUI.FeedbackDelayMax * 1.5)],...
            'YAxisLocation', 'right',...
            'FontSize', 10);
        ylabel('Invested Time (s)')
        % title('Block switching behaviour')
        
        %% plot vevaiometric (L/R sorted residuals = abs(ChoiceLeft - P({ChoiceLeft}^))
        LRVevaiometricAxes = axes(AnalysisFigure, 'Position', [0.88    0.36    0.10    0.11]);
        hold(LRVevaiometricAxes, 'on')
        
        AbsModelResiduals = abs(LauGlimcherGLM.Residuals.Raw);
        
        LeftAbsResidual = AbsModelResiduals(LeftTITrial);
        RightAbsResidual = AbsModelResiduals(RightTITrial);
        
        LeftScatter = scatter(LRVevaiometricAxes, LeftAbsResidual, LeftTI,...
                              'Marker', '.',...
                              'MarkerEdgeColor', sand,...
                              'SizeData', 18);
        
        RighScatter = scatter(LRVevaiometricAxes, RightAbsResidual, RightTI,...
                              'Marker', '.',...
                              'MarkerEdgeColor', turquoise,...
                              'SizeData', 18);
    
        [LeftLineXData, LeftLineYData] = Binvevaio(LeftAbsResidual, LeftTI, 10);
        [RightLineXData, RightLineYData] = Binvevaio(RightAbsResidual, RightTI, 10);
        
        LeftPlot = plot(LRVevaiometricAxes, LeftLineXData, LeftLineYData,...
                        'Color', sand,...
                        'LineWidth', 2);       
        
        RightPlot = plot(LRVevaiometricAxes, RightLineXData, RightLineYData,...
                         'Color', turquoise,...
                         'LineWidth', 2);
        
        set(LRVevaiometricAxes,...
            'FontSize', 10,...
            'XLim', [0 1],...
            'YLim', [0 SessionData.SettingsFile.GUI.FeedbackDelayMax * 1.5])
        title(LRVevaiometricAxes, 'LRVevaiometric');
        xlabel(LRVevaiometricAxes, 'abs(Residuals)');
        
    end
end

DataFolder = OttLabDataServerFolderPath;
RatName = SessionData.Info.Subject;
% %%The following lines doesn't not work, as the timestamp documented
% in the SessionData may not be the same as the one being used for saving
% SessionDate = string(datetime(SessionData.Info.SessionDate), 'yyyyMMdd')';
% SessionTime = string(datetime(SessionData.Info.SessionStartTime_UTC), 'HHmmSS')';
% SessionDateTime = strcat(SessionDate, '_', SessionTime);
DataPath = strcat(DataFolder, RatName, '\bpod_session\', SessionDateTime, '\',...
                  RatName, '_TwoArmBanditVariant_', SessionDateTime, '_Cued.png');
exportgraphics(AnalysisFigure, DataPath);

DataPath = strcat(DataFolder, RatName, '\bpod_graph\',...
                  RatName, '_TwoArmBanditVariant_', SessionDateTime, '_Cued.png');
exportgraphics(AnalysisFigure, DataPath);

close(AnalysisFigure)

end % function
%}
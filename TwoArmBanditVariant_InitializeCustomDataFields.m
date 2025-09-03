function TwoArmBanditVariant_InitializeCustomDataFields(iTrial)
%{ 
Initializing trial data
%}

global BpodSystem
global TaskParameters

if iTrial == 1
    BpodSystem.Data.Custom.TrialData = struct(); % initializing .TrialData
end

TrialData = BpodSystem.Data.Custom.TrialData;

%% Pre-stimulus delivery
TrialData.NoTrialStart(iTrial) = true; % true = no state StartCIn; false = with state StartCIn.
% from 20240105, NoTrialStart has an independent state then rely on
% StartCIn

TrialData.TimeCenterPoke(iTrial) = NaN; % Time when CIn

TrialData.BrokeFixation(iTrial) = NaN; % NaN = no state StartCIn; true = with state BrokeFixation; false = with state Sampling
TrialData.StimDelay(iTrial) = TaskParameters.GUI.StimDelay;
switch TaskParameters.GUIMeta.StimDelayDistribution.String{TaskParameters.GUI.StimDelayDistribution}
    case 'Fix'
        % can still be adjusted by changing TaskParameters.GUI.StimDelayMin
        
    case 'AutoIncr'
        if iTrial > 1
            History = 50; % Rat: History = 50
            Crit = 0.8; % Rat: Crit = 0.8
            ConsiderTrials = max(1,iTrial-History):1:iTrial-1;
            ConsiderTrials = ConsiderTrials(~isnan(TrialData.BrokeFixation(ConsiderTrials))); % exclude trials did not start
            NotBrokeFixationRate = sum(~TrialData.BrokeFixation(ConsiderTrials))/length(ConsiderTrials);
            
            if NotBrokeFixationRate > Crit
                if TrialData.BrokeFixation(iTrial-1) == false % If last trial is not BrokeFixation nor NaN (e.g. NoTrialStart)
                    TrialData.StimDelay(iTrial) = TrialData.StimDelay(iTrial) + TaskParameters.GUI.StimDelayIncrStepSize; % StimulusDelay increased
                end
            elseif NotBrokeFixationRate < Crit/2
                if TrialData.BrokeFixation(iTrial-1) == true % If last trial is Broke Fixation (and not NaN)
                    TrialData.StimDelay(iTrial) = TrialData.StimDelay(iTrial) - TaskParameters.GUI.StimDelayDecrStepSize; % StimulusDelay decreased
                end
            end
        end
        
    case 'TruncExp'
        TrialData.StimDelay(iTrial) = TruncatedExponential(TaskParameters.GUI.StimDelayMin, TaskParameters.GUI.StimDelayMax, TaskParameters.GUI.StimDelayTau);
    
    case 'Uniform'
        TrialData.StimDelay(iTrial) = TaskParameters.GUI.StimDelayMin + rand*(TaskParameters.GUI.StimDelayMax - TaskParameters.GUI.StimDelayMin);
        
    case 'Beta'
        %% !!to be implemented!!
end

if TrialData.StimDelay(iTrial) > TaskParameters.GUI.StimDelayMax % allow adjustment even if StimDelayAutoIncr is off
    TrialData.StimDelay(iTrial) = TaskParameters.GUI.StimDelayMax;
elseif TrialData.StimDelay(iTrial) < TaskParameters.GUI.StimDelayMin
    TrialData.StimDelay(iTrial) = TaskParameters.GUI.StimDelayMin;
end

TaskParameters.GUI.StimDelay = TrialData.StimDelay(iTrial);
TrialData.StimWaitingTime(iTrial) = NaN; % Time that stayed CenterPortIn for StimDelay

%% Peri-stimulus delivery and Pre-decision
TrialData.SamplingGrace(1,iTrial) = NaN; % old GracePeriod, row is for the n-th time the state is entered, column is for the time in this State
TrialData.EarlyWithdrawal(iTrial) = NaN; % NaN = no state Sampling; true = with state EarlyWithdrawal; false = with state StillSampling
TrialData.SampleTime(iTrial) = NaN; % Time that stayed CenterPortIn for sampling, from stimulus starts

% TrialData.SingleSidePokeEnabled(iTrial) = TaskParameters.GUI.SingleSidePoke;
TrialData.LightLeft(iTrial) = NaN; % if true, 1-arm bandit with left poke being correct
if TaskParameters.GUI.SingleSidePoke
    TrialData.LightLeft(iTrial) = rand < 0.5;
end

%% Peri-decision and pre-outcome
TrialData.NoDecision(iTrial) = NaN; % True if no decision made
TrialData.MoveTime(iTrial) = NaN; % from CenterPortOut to SidePortIn(or re-CenterPortIn for StartNewTrial), old MT

% TrialData.StartNewTrialEnabled(iTrial) = TaskParameters.GUI.StartNewTrial; % if false TaskParameters.GUI.StartNewTrial is off;
TrialData.StartNewTrial(iTrial) = NaN; % only concern state 'StartNewTrial'
TrialData.StartNewTrialSuccessful(iTrial) = NaN; % concern state 'StartNewTrialTimeOut'

TrialData.TimeChoice(iTrial) = NaN;
TrialData.ChoiceLeft(iTrial) = NaN; % True if a choice is made to the left poke (also include incorrect choice)
TrialData.IncorrectChoice(iTrial) = NaN; % True if the choice is incorrect (only for 1-arm bandit/GUI.SingleSidePoke);
% basically = LigthLeft & ChoiceLeft; doesn't necessary in the state of
% IncorrectChoice (may end up in SkippedFeedback first)

TrialData.FeedbackDelay(iTrial) = TaskParameters.GUI.FeedbackDelay;
switch TaskParameters.GUIMeta.FeedbackDelayDistribution.String{TaskParameters.GUI.FeedbackDelayDistribution}
    case 'Fix'
        % can still be adjusted by changing TaskParameters.GUI.FeedbackDelayMin
        
    case 'AutoIncr'
        if iTrial > 1
            History = 50; % Rat: History = 50
            Crit = 0.8; % Rat: Crit = 0.8
            ConsiderTrials = max(1, iTrial-History):1:iTrial-1;
            ConsiderTrials = ConsiderTrials(~isnan(TrialData.ChoiceLeft(ConsiderTrials))); % exclude trials did not Choice
            NotSkippedFeedbackRate = sum(~TrialData.SkippedFeedback(ConsiderTrials))/length(ConsiderTrials);
            
            if NotSkippedFeedbackRate > Crit
                if TrialData.SkippedFeedback(iTrial-1) == false % If last trial is not Skipped Feedback nor NaN (e.g. NoDecision)
                    TrialData.FeedbackDelay(iTrial) = TrialData.FeedbackDelay(iTrial) + TaskParameters.GUI.FeedbackDelayIncrStepSize; % FeedbackDelay increased
                end
            elseif NotSkippedFeedbackRate < Crit/2
                if TrialData.SkippedFeedback(iTrial-1) == true % If last trial is Skipped Feedback (and not NaN)
                    TrialData.FeedbackDelay(iTrial) = TrialData.FeedbackDelay(iTrial) - TaskParameters.GUI.FeedbackDelayDecrStepSize; % FeedbackDelay decreased
                end
            end
        end
        
    case 'TruncExp'
        TrialData.FeedbackDelay(iTrial) = TruncatedExponential(TaskParameters.GUI.FeedbackDelayMin, TaskParameters.GUI.FeedbackDelayMax, TaskParameters.GUI.FeedbackDelayTau);
        
        switch TaskParameters.GUIMeta.RiskType.String{TaskParameters.GUI.RiskType}
            case 'CuedBlockTau'
                if TrialData.BlockNumber(iTrial) > 1
                    if mod(TrialData.BlockNumber(iTrial), 2) == 0 % longer ITI
                        BlockFeedbackDelayTau = 2.5;
                    else
                        BlockFeedbackDelayTau = 1;
                    end
                    BlockFeedbackDelayMax = TaskParameters.GUI.FeedbackDelayMin + 5 * BlockFeedbackDelayTau; % exp(-5) < 0.01
                    TrialData.FeedbackDelay(iTrial) = TruncatedExponential(TaskParameters.GUI.FeedbackDelayMin, BlockFeedbackDelayMax, BlockFeedbackDelayTau);
                end
        end

    case 'Beta'
        %% !!to be implemented!!
end

if TrialData.FeedbackDelay(iTrial) > TaskParameters.GUI.FeedbackDelayMax % allow adjustment even if StimDelayAutoIncr is off
    TrialData.FeedbackDelay(iTrial) = TaskParameters.GUI.FeedbackDelayMax;
elseif TrialData.FeedbackDelay(iTrial) < TaskParameters.GUI.FeedbackDelayMin
    TrialData.FeedbackDelay(iTrial) = TaskParameters.GUI.FeedbackDelayMin;
end
TaskParameters.GUI.FeedbackDelay = TrialData.FeedbackDelay(iTrial);

TrialData.FeedbackGrace(1, iTrial) = NaN; % first index for the number of time the state is entered
TrialData.FeedbackWaitingTime(iTrial) = NaN; % Time spend to wait for feedback
TrialData.TimeSkippedFeedback(iTrial) = NaN;
TrialData.SkippedFeedback(iTrial) = NaN; % True if SkippedFeedback
TrialData.TITrial(iTrial) = NaN; % True if it is included in TimeInvestment

%% Peri-outcome
TrialData.RewardProb(:, iTrial) = [NaN, NaN]';
TrialData.BlockNumber(iTrial) = NaN; % only adjust if RiskType is Block
TrialData.BlockTrialNumber(iTrial) = NaN; % only adjust if RiskType is Block
TrialData.RewardCueLeft(:, iTrial) = [NaN, NaN]'; % only adjust if RiskType is Cued
TrialData.RewardCueRight(:, iTrial) = [NaN, NaN]'; % only adjust if RiskType is Cued

switch TaskParameters.GUIMeta.RiskType.String{TaskParameters.GUI.RiskType}
    case 'Fix'
        TrialData.RewardProb(1,iTrial) = TaskParameters.GUI.RewardProbLeft;
        TrialData.RewardProb(2,iTrial) = TaskParameters.GUI.RewardProbRight;
        
    case 'BlockRand'
        if iTrial == 1
            TrialData.BlockNumber(iTrial) = 1;
            TrialData.BlockTrialNumber(iTrial) = 1;
            TaskParameters.GUI.BlockLen = randi([TaskParameters.GUI.BlockLenMin, TaskParameters.GUI.BlockLenMax]);
            TaskParameters.GUI.NextBlockTrialNumber = TaskParameters.GUI.BlockLen + 1;
            TrialData.RewardProb(:,iTrial) = randi([TaskParameters.GUI.RewardProbMin, TaskParameters.GUI.RewardProbMax],2,1);
        else
            TrialData.BlockNumber(iTrial) = TrialData.BlockNumber(iTrial-1);
            TrialData.BlockTrialNumber(iTrial) = TrialData.BlockTrialNumber(iTrial-1) + 1;
            TrialData.RewardProb(:,iTrial) = TrialData.RewardProb(:, iTrial-1);
            if TrialData.BlockTrialNumber(iTrial) > TaskParameters.GUI.BlockLen
                TrialData.BlockNumber(iTrial) = TrialData.BlockNumber(iTrial-1) + 1;
                TrialData.BlockTrialNumber(iTrial) = 1;
                TaskParameters.GUI.BlockLen = randi([TaskParameters.GUI.BlockLenMin, TaskParameters.GUI.BlockLenMax]);
                TaskParameters.GUI.NextBlockTrialNumber = (iTrial-1) + TaskParameters.GUI.BlockLen + 1;
                TrialData.RewardProb(:, iTrial) = randi([TaskParameters.GUI.RewardProbMin, TaskParameters.GUI.RewardProbMax],2,1);
            end
        end

    case 'BlockRandHolding'
        RewardProbCategories = [0.1, 0.2, 0.4];
        if iTrial == 1
            TrialData.BlockNumber(iTrial) = 1;
            TrialData.BlockTrialNumber(iTrial) = 1;
            TaskParameters.GUI.BlockLen = randi([TaskParameters.GUI.BlockLenMin, TaskParameters.GUI.BlockLenMax]);
            TaskParameters.GUI.NextBlockTrialNumber = TaskParameters.GUI.BlockLen + 1;
            TrialData.RewardProb(:,iTrial) = RewardProbCategories(randi([1, 3], 2, 1));
        else
            TrialData.BlockNumber(iTrial) = TrialData.BlockNumber(iTrial-1);
            TrialData.BlockTrialNumber(iTrial) = TrialData.BlockTrialNumber(iTrial-1) + 1;
            TrialData.RewardProb(:,iTrial) = TrialData.RewardProb(:, iTrial-1);
            if TrialData.BlockTrialNumber(iTrial) > TaskParameters.GUI.BlockLen
                TrialData.BlockNumber(iTrial) = TrialData.BlockNumber(iTrial-1) + 1;
                TrialData.BlockTrialNumber(iTrial) = 1;
                TaskParameters.GUI.BlockLen = randi([TaskParameters.GUI.BlockLenMin, TaskParameters.GUI.BlockLenMax]);
                TaskParameters.GUI.NextBlockTrialNumber = (iTrial-1) + TaskParameters.GUI.BlockLen + 1;
                TrialData.RewardProb(:, iTrial) = RewardProbCategories(randi([1, 3], 2, 1));
            end
        end

    case 'BlockFix'
        if iTrial == 1
            TrialData.BlockNumber(iTrial) = 1;
            TrialData.BlockTrialNumber(iTrial) = 1;
            TaskParameters.GUI.BlockLen = randi([TaskParameters.GUI.BlockLenMin, TaskParameters.GUI.BlockLenMax]);
            TaskParameters.GUI.NextBlockTrialNumber = TaskParameters.GUI.BlockLen + 1;
            TrialData.RewardProb(:,iTrial) = [TaskParameters.GUI.RewardProbMin, TaskParameters.GUI.RewardProbMax]';
            if rand < 0.5
                TrialData.RewardProb(:,iTrial) = flip(TrialData.RewardProb(:, iTrial));
            end
        else
            TrialData.BlockNumber(iTrial) = TrialData.BlockNumber(iTrial-1);
            TrialData.BlockTrialNumber(iTrial) = TrialData.BlockTrialNumber(iTrial-1) + 1;
            TrialData.RewardProb(:,iTrial) = TrialData.RewardProb(:, iTrial-1);
            if TrialData.BlockTrialNumber(iTrial) > TaskParameters.GUI.BlockLen
                TrialData.BlockNumber(iTrial) = TrialData.BlockNumber(iTrial-1) + 1;
                TrialData.BlockTrialNumber(iTrial) = 1;
                TaskParameters.GUI.BlockLen = randi([TaskParameters.GUI.BlockLenMin, TaskParameters.GUI.BlockLenMax]);
                TaskParameters.GUI.NextBlockTrialNumber = (iTrial-1) + TaskParameters.GUI.BlockLen + 1;
                TrialData.RewardProb(:, iTrial) = flip(TrialData.RewardProb(:, iTrial-1));
            end
        end
        
    case 'BlockFixHolding'
        if iTrial == 1
            TrialData.BlockNumber(iTrial) = 1;
            TrialData.BlockTrialNumber(iTrial) = 1;
            TaskParameters.GUI.BlockLen = randi([TaskParameters.GUI.BlockLenMin, TaskParameters.GUI.BlockLenMax]);
            TaskParameters.GUI.NextBlockTrialNumber = TaskParameters.GUI.BlockLen + 1;
            TrialData.RewardProb(:, iTrial) = [TaskParameters.GUI.RewardProbMin, TaskParameters.GUI.RewardProbMax]';
            if rand < 0.5
                TrialData.RewardProb(:,iTrial) = flip(TrialData.RewardProb(:, iTrial));
            end
        else
            TrialData.BlockNumber(iTrial) = TrialData.BlockNumber(iTrial-1);
            TrialData.BlockTrialNumber(iTrial) = TrialData.BlockTrialNumber(iTrial-1) + 1;
            TrialData.RewardProb(:,iTrial) = TrialData.RewardProb(:,iTrial-1);
            if TrialData.BlockTrialNumber(iTrial) > TaskParameters.GUI.BlockLen
                TrialData.BlockNumber(iTrial) = TrialData.BlockNumber(iTrial-1) + 1;
                TrialData.BlockTrialNumber(iTrial) = 1;
                TaskParameters.GUI.BlockLen = randi([TaskParameters.GUI.BlockLenMin, TaskParameters.GUI.BlockLenMax]);
                TaskParameters.GUI.NextBlockTrialNumber = (iTrial-1) + TaskParameters.GUI.BlockLen + 1;
                TrialData.RewardProb(:, iTrial) = flip(TrialData.RewardProb(:, iTrial-1));
            end
        end
        
    case 'Cued'
        NoOfValidCue = min([size(TaskParameters.GUI.ToneRiskTable.ToneStartFreq, 1), size(TaskParameters.GUI.ToneRiskTable.ToneEndFreq, 1), size(TaskParameters.GUI.ToneRiskTable.ToneCuedRewardProbability, 1)]);
        CueLeftIdx = randi(NoOfValidCue);
        CueRightIdx = randi(NoOfValidCue);
        TrialData.RewardCueLeft(:,iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneStartFreq(CueLeftIdx), TaskParameters.GUI.ToneRiskTable.ToneEndFreq(CueLeftIdx)]';
        TrialData.RewardCueRight(:,iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneStartFreq(CueRightIdx), TaskParameters.GUI.ToneRiskTable.ToneEndFreq(CueRightIdx)]';
        TrialData.RewardProb(:,iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneCuedRewardProbability(CueLeftIdx), TaskParameters.GUI.ToneRiskTable.ToneCuedRewardProbability(CueRightIdx)]';
        
    %{
    based on BlockFixHolding with Risk and Cues based on the GUI.ToneRiskTable,
    suggested cued are up sweep and down sweep
    in SingleSidePoke, based on block structure to assign reward prob and
    thus cues
    %}
    case 'BlockCued'
        if iTrial == 1
            TrialData.BlockNumber(iTrial) = 1;
            TrialData.BlockTrialNumber(iTrial) = 1;
            TaskParameters.GUI.BlockLen = randi([TaskParameters.GUI.BlockLenMin, TaskParameters.GUI.BlockLenMax]);
            TaskParameters.GUI.NextBlockTrialNumber = TaskParameters.GUI.BlockLen + 1;
            
            if TaskParameters.GUI.SingleSidePoke
                TrialData.RewardProb(:,iTrial) =  [TaskParameters.GUI.ToneRiskTable.ToneCuedRewardProbability(1), TaskParameters.GUI.ToneRiskTable.ToneCuedRewardProbability(1)]';
                TrialData.RewardCueLeft(:,iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneStartFreq(1), TaskParameters.GUI.ToneRiskTable.ToneEndFreq(1)]';
                TrialData.RewardCueRight(:,iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneStartFreq(1), TaskParameters.GUI.ToneRiskTable.ToneEndFreq(1)]';
                if rand < 0.5
                    TrialData.RewardProb(:,iTrial) =  [TaskParameters.GUI.ToneRiskTable.ToneCuedRewardProbability(2), TaskParameters.GUI.ToneRiskTable.ToneCuedRewardProbability(2)]';
                    TrialData.RewardCueLeft(:,iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneStartFreq(2), TaskParameters.GUI.ToneRiskTable.ToneEndFreq(2)]';
                    TrialData.RewardCueRight(:,iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneStartFreq(2), TaskParameters.GUI.ToneRiskTable.ToneEndFreq(2)]';
                end
            else
                TrialData.RewardProb(:, iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneCuedRewardProbability(1), TaskParameters.GUI.ToneRiskTable.ToneCuedRewardProbability(2)]';
                TrialData.RewardCueLeft(:,iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneStartFreq(1), TaskParameters.GUI.ToneRiskTable.ToneEndFreq(1)]';
                TrialData.RewardCueRight(:,iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneStartFreq(2), TaskParameters.GUI.ToneRiskTable.ToneEndFreq(2)]';
                if rand < 0.5
                    TrialData.RewardProb(:,iTrial) = flip(TrialData.RewardProb(:, iTrial));
                    TrialData.RewardCueLeft(:,iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneStartFreq(2), TaskParameters.GUI.ToneRiskTable.ToneEndFreq(2)]';
                    TrialData.RewardCueRight(:,iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneStartFreq(1), TaskParameters.GUI.ToneRiskTable.ToneEndFreq(1)]';
                end
            end
        else
            TrialData.BlockNumber(iTrial) = TrialData.BlockNumber(iTrial-1);
            TrialData.BlockTrialNumber(iTrial) = TrialData.BlockTrialNumber(iTrial-1) + 1;
            TrialData.RewardProb(:,iTrial) = TrialData.RewardProb(:,iTrial-1);
            TrialData.RewardCueLeft(:,iTrial) = TrialData.RewardCueLeft(:,iTrial-1);
            TrialData.RewardCueRight(:,iTrial) = TrialData.RewardCueRight(:,iTrial-1);
            if TrialData.BlockTrialNumber(iTrial) > TaskParameters.GUI.BlockLen
                TrialData.BlockNumber(iTrial) = TrialData.BlockNumber(iTrial-1) + 1;
                TrialData.BlockTrialNumber(iTrial) = 1;
                TaskParameters.GUI.BlockLen = randi([TaskParameters.GUI.BlockLenMin, TaskParameters.GUI.BlockLenMax]);
                TaskParameters.GUI.NextBlockTrialNumber = (iTrial-1) + TaskParameters.GUI.BlockLen + 1;
                if TaskParameters.GUI.SingleSidePoke
                    RewardProbOptions = TaskParameters.GUI.ToneRiskTable.ToneCuedRewardProbability(1:2);
                    RewardToneStartOptions = TaskParameters.GUI.ToneRiskTable.ToneStartFreq(1:2);
                    RewardToneEndOptions = TaskParameters.GUI.ToneRiskTable.ToneEndFreq(1:2);
                    NewBlockRewardProbIdx = RewardProbOptions ~= TrialData.RewardProb(1, iTrial-1);
                    NewBlockRewardProb = sum(RewardProbOptions' * NewBlockRewardProbIdx);
                    NewStartTone = sum(RewardToneStartOptions' * NewBlockRewardProbIdx);
                    NewEndTone = sum(RewardToneEndOptions' * NewBlockRewardProbIdx);
                    TrialData.RewardProb(:, iTrial) = [NewBlockRewardProb, NewBlockRewardProb]';
                    TrialData.RewardCueLeft(:,iTrial) = [NewStartTone NewEndTone]';
                    TrialData.RewardCueRight(:,iTrial) = [NewStartTone NewEndTone]';
                else
                    TrialData.RewardProb(:, iTrial) = flip(TrialData.RewardProb(:, iTrial-1));
                    TrialData.RewardCueLeft(:,iTrial) = TrialData.RewardCueRight(:,iTrial-1);
                    TrialData.RewardCueRight(:,iTrial) = TrialData.RewardCueLeft(:,iTrial-1);
                end
            end
        end
        
    %{
    Only consider first 2 cues, in the future, a separate protocol shall be
    made to give a full range of cross modality cueing different aspects in
    value-based decision making. Here is only a temporary version for quick
    experimental testing
    %}
    case 'CuedBlockRatio'
        if iTrial == 1
            TrialData.BlockNumber(iTrial) = 1;
            TrialData.BlockTrialNumber(iTrial) = 1;
            TaskParameters.GUI.BlockLen = randi([TaskParameters.GUI.BlockLenMin, TaskParameters.GUI.BlockLenMax]);
            TaskParameters.GUI.NextBlockTrialNumber = TaskParameters.GUI.BlockLen + 1;
            TrialData.CueRatio(iTrial) = 0.5;
        else
            TrialData.BlockNumber(iTrial) = TrialData.BlockNumber(iTrial-1);
            TrialData.BlockTrialNumber(iTrial) = TrialData.BlockTrialNumber(iTrial-1) + 1;
            TrialData.CueRatio(iTrial) = TrialData.CueRatio(iTrial-1);
            if TrialData.BlockTrialNumber(iTrial) > TaskParameters.GUI.BlockLen
                TrialData.BlockNumber(iTrial) = TrialData.BlockNumber(iTrial-1) + 1;
                TrialData.BlockTrialNumber(iTrial) = 1;
                TaskParameters.GUI.BlockLen = randi([TaskParameters.GUI.BlockLenMin, TaskParameters.GUI.BlockLenMax]);
                TaskParameters.GUI.NextBlockTrialNumber = (iTrial-1) + TaskParameters.GUI.BlockLen + 1;
                if mod(TrialData.BlockNumber(iTrial), 2) == 1
                    TrialData.CueRatio(iTrial) = 0.35; % more Cue 2 (usually P_{low} = 0.1)
                else
                    TrialData.CueRatio(iTrial) = 0.65; % more Cue 1 (usually P_{high} = 0.8)
                end
            end
        end
        
        CueLeftIdx = (rand > TrialData.CueRatio(iTrial)) + 1;
        CueRightIdx = (rand > TrialData.CueRatio(iTrial)) + 1;
        TrialData.RewardCueLeft(:,iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneStartFreq(CueLeftIdx), TaskParameters.GUI.ToneRiskTable.ToneEndFreq(CueLeftIdx)]';
        TrialData.RewardCueRight(:,iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneStartFreq(CueRightIdx), TaskParameters.GUI.ToneRiskTable.ToneEndFreq(CueRightIdx)]';
        TrialData.RewardProb(:,iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneCuedRewardProbability(CueLeftIdx), TaskParameters.GUI.ToneRiskTable.ToneCuedRewardProbability(CueRightIdx)]';

    case 'CuedBlockITI'
        NoOfValidCue = min([size(TaskParameters.GUI.ToneRiskTable.ToneStartFreq, 1), size(TaskParameters.GUI.ToneRiskTable.ToneEndFreq, 1), size(TaskParameters.GUI.ToneRiskTable.ToneCuedRewardProbability, 1)]);
        CueLeftIdx = randi(NoOfValidCue);
        CueRightIdx = randi(NoOfValidCue);
        TrialData.RewardCueLeft(:,iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneStartFreq(CueLeftIdx), TaskParameters.GUI.ToneRiskTable.ToneEndFreq(CueLeftIdx)]';
        TrialData.RewardCueRight(:,iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneStartFreq(CueRightIdx), TaskParameters.GUI.ToneRiskTable.ToneEndFreq(CueRightIdx)]';
        TrialData.RewardProb(:,iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneCuedRewardProbability(CueLeftIdx), TaskParameters.GUI.ToneRiskTable.ToneCuedRewardProbability(CueRightIdx)]';
        
        if iTrial == 1
            TrialData.BlockNumber(iTrial) = 1;
            TrialData.BlockTrialNumber(iTrial) = 1;
            TaskParameters.GUI.BlockLen = randi([TaskParameters.GUI.BlockLenMin, TaskParameters.GUI.BlockLenMax]);
            TaskParameters.GUI.NextBlockTrialNumber = TaskParameters.GUI.BlockLen + 1;
        else
            TrialData.BlockNumber(iTrial) = TrialData.BlockNumber(iTrial-1);
            TrialData.BlockTrialNumber(iTrial) = TrialData.BlockTrialNumber(iTrial-1) + 1;
            if TrialData.BlockTrialNumber(iTrial) > TaskParameters.GUI.BlockLen
                TrialData.BlockNumber(iTrial) = TrialData.BlockNumber(iTrial-1) + 1;
                TrialData.BlockTrialNumber(iTrial) = 1;
                TaskParameters.GUI.BlockLen = randi([TaskParameters.GUI.BlockLenMin, TaskParameters.GUI.BlockLenMax]);
                TaskParameters.GUI.NextBlockTrialNumber = (iTrial-1) + TaskParameters.GUI.BlockLen + 1;
            end
        end

    case 'CuedBlockTau'
        NoOfValidCue = min([size(TaskParameters.GUI.ToneRiskTable.ToneStartFreq, 1), size(TaskParameters.GUI.ToneRiskTable.ToneEndFreq, 1), size(TaskParameters.GUI.ToneRiskTable.ToneCuedRewardProbability, 1)]);
        CueLeftIdx = randi(NoOfValidCue);
        CueRightIdx = randi(NoOfValidCue);
        TrialData.RewardCueLeft(:,iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneStartFreq(CueLeftIdx), TaskParameters.GUI.ToneRiskTable.ToneEndFreq(CueLeftIdx)]';
        TrialData.RewardCueRight(:,iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneStartFreq(CueRightIdx), TaskParameters.GUI.ToneRiskTable.ToneEndFreq(CueRightIdx)]';
        TrialData.RewardProb(:,iTrial) = [TaskParameters.GUI.ToneRiskTable.ToneCuedRewardProbability(CueLeftIdx), TaskParameters.GUI.ToneRiskTable.ToneCuedRewardProbability(CueRightIdx)]';
        
        if iTrial == 1
            TrialData.BlockNumber(iTrial) = 1;
            TrialData.BlockTrialNumber(iTrial) = 1;
            TaskParameters.GUI.BlockLen = randi([TaskParameters.GUI.BlockLenMin, TaskParameters.GUI.BlockLenMax]);
            TaskParameters.GUI.NextBlockTrialNumber = TaskParameters.GUI.BlockLen + 1;
        else
            TrialData.BlockNumber(iTrial) = TrialData.BlockNumber(iTrial-1);
            TrialData.BlockTrialNumber(iTrial) = TrialData.BlockTrialNumber(iTrial-1) + 1;
            if TrialData.BlockTrialNumber(iTrial) > TaskParameters.GUI.BlockLen
                TrialData.BlockNumber(iTrial) = TrialData.BlockNumber(iTrial-1) + 1;
                TrialData.BlockTrialNumber(iTrial) = 1;
                TaskParameters.GUI.BlockLen = randi([TaskParameters.GUI.BlockLenMin, TaskParameters.GUI.BlockLenMax]);
                TaskParameters.GUI.NextBlockTrialNumber = (iTrial-1) + TaskParameters.GUI.BlockLen + 1;
            end
        end
end

TaskParameters.GUI.RewardProbActualLeft = TrialData.RewardProb(1,iTrial);
TaskParameters.GUI.RewardProbActualRight = TrialData.RewardProb(2,iTrial);

%{ Should not adjust RewardProb in 1-arm task as some codes use (i-1)th values
% if TrialData.LightLeft(iTrial) == 1 
%     TrialData.RewardProb(2,iTrial) = 0;
% elseif TrialData.LightLeft(iTrial) == 0
%     TrialData.RewardProb(1,iTrial) = 0;
% end}

TrialData.Baited(:, iTrial) = rand(2, 1) < TrialData.RewardProb(:, iTrial); % only logicals 
switch TaskParameters.GUIMeta.RiskType.String{TaskParameters.GUI.RiskType}
    case 'BlockRandHolding'
        if TrialData.BlockTrialNumber(iTrial) ~= 1
            if isnan(TrialData.ChoiceLeft(iTrial-1))
                TrialData.Baited(:, iTrial) = TrialData.AvailableReward(:, iTrial-1);
            else
                TrialData.Baited(:, iTrial) = TrialData.Baited(:, iTrial) | TrialData.AvailableReward(:, iTrial-1);
            end
        end
    
    case 'BlockFixHolding'
        if TrialData.BlockTrialNumber(iTrial) ~= 1
            if isnan(TrialData.ChoiceLeft(iTrial-1))
                TrialData.Baited(:, iTrial) = TrialData.AvailableReward(:, iTrial-1);
            else
                TrialData.Baited(:, iTrial) = TrialData.Baited(:, iTrial) | TrialData.AvailableReward(:, iTrial-1);
            end
        end
        
    case 'BlockCued' % for 2-arm version, it can has Holding as a guide for matching (not used at the moment)
        if ~TaskParameters.GUI.SingleSidePoke && TrialData.BlockTrialNumber(iTrial) ~= 1
            if isnan(TrialData.ChoiceLeft(iTrial-1))
                TrialData.Baited(:, iTrial) = TrialData.AvailableReward(:, iTrial-1);
            else
                TrialData.Baited(:, iTrial) = TrialData.Baited(:, iTrial) | TrialData.AvailableReward(:, iTrial-1);
            end
        end
    
end

if TaskParameters.GUI.ExpressedAsExpectedValue
    TrialData.Baited(:, iTrial) = true(2, 1);
end

if TrialData.LightLeft(iTrial) == 1 % i.e. SingleSidePoke is true; holding will be overwritten
    TrialData.Baited(2, iTrial) = false; % Non light-guided one being irrelevant
elseif TrialData.LightLeft(iTrial) == 0
    TrialData.Baited(1, iTrial) = false;
end

TrialData.AvailableReward(:, iTrial) = TrialData.Baited(:,iTrial); % Before trial, the two variables is the same. Only changed after the trial

TrialData.RewardMagnitude(:, iTrial) = [TaskParameters.GUI.RewardAmount, TaskParameters.GUI.RewardAmount]'; % first index is for left or right poke
if TaskParameters.GUI.OUReward % hardcode: tau = 20 trials, variance = RewMag / tau
    if iTrial == 1
        TrialData.SupposedRewardMagnitude(iTrial) = TaskParameters.GUI.RewardAmount;
    % elseif isnan(TrialData.ChoiceLeft(iTrial-1))
    % TrialData.SupposedRewardMagnitude(iTrial) = TrialData.SupposedRewardMagnitude(iTrial-1);
    else
        TrialData.SupposedRewardMagnitude(iTrial) =...
            TrialData.SupposedRewardMagnitude(iTrial-1)...
            + 1 / 20 * (TaskParameters.GUI.RewardAmount - TrialData.SupposedRewardMagnitude(iTrial-1))...
            + (TaskParameters.GUI.RewardAmount / 20) * randn();
    end

    TrialData.RewardMagnitude(:, iTrial) = [1; 1] * TrialData.SupposedRewardMagnitude(iTrial);
end

if TrialData.LightLeft(iTrial) == 1 % adjustment by SingleSidePoke, i.e. 1-arm bandit
    TrialData.RewardMagnitude(2, iTrial) = 0;
elseif TrialData.LightLeft(iTrial) == 0
    TrialData.RewardMagnitude(1, iTrial) = 0;
end

if TaskParameters.GUI.ExpressedAsExpectedValue
    TrialData.RewardMagnitude(:, iTrial) = TrialData.RewardMagnitude(:, iTrial).* TrialData.RewardProb(:, iTrial);
else
    TrialData.RewardMagnitude(:, iTrial) = TrialData.RewardMagnitude(:, iTrial).* TrialData.Baited(:, iTrial);
end

TrialData.RewardMagnitudeL(iTrial) = TrialData.RewardMagnitude(1, iTrial);
TrialData.RewardMagnitudeR(iTrial) = TrialData.RewardMagnitude(2, iTrial);

TrialData.Rewarded(iTrial) = NaN; % true if a non-zero reward is delivered, NaN if no choice made

TrialData.TimeReward(iTrial) = NaN;
TrialData.TimeNotBaitedFeedback(iTrial) = NaN;
TrialData.DrinkingTime(iTrial) = NaN;

%% optogenetics stimulation
%% Ch3
TrialData.Ch3StopBlockNumber(iTrial) = Nan;
TrialData.Ch3StopBlockTrialNumber(iTrial) = Nan;

if strcmpi(TaskParameters.GUIMeta.Ch3StopBlock.String{TaskParameters.GUI.Ch3StopBlock}, 'NotToRiskBlock') % need to draw new block
    if iTrial == 1
        TrialData.Ch3StopBlockNumber(iTrial) = 1;
        TrialData.Ch3StopBlockTrialNumber(iTrial) = 1;
        TaskParameters.GUI.Ch3StopBlockLen = randi([TaskParameters.GUI.Ch3StopBlockRangeMin, TaskParameters.GUI.Ch3StopBlockRangeMax]); % internal, not shown
        TaskParameters.GUI.Ch3StopNextBlockTrialNumber = TaskParameters.GUI.Ch3StopBlockLen + 1; % internal, not shown
    else
        TrialData.Ch3StopBlockNumber(iTrial) = TrialData.Ch3StopBlockNumber(iTrial-1);
        TrialData.Ch3StopBlockTrialNumber(iTrial) = TrialData.Ch3StopBlockTrialNumber(iTrial-1) + 1;
        if TrialData.Ch3StopBlockTrialNumber(iTrial) > TaskParameters.GUI.Ch3StopBlockLen
            TrialData.Ch3StopBlockNumber(iTrial) = TrialData.Ch3StopBlockNumber(iTrial-1) + 1;
            TrialData.Ch3StopBlockTrialNumber(iTrial) = 1;
            TaskParameters.GUI.Ch3StopBlockLen = randi([TaskParameters.GUI.Ch3StopBlockRangeMin, TaskParameters.GUI.Ch3StopBlockRangeMax]);
            TaskParameters.GUI.Ch3StopNextBlockTrialNumber = (iTrial-1) + TaskParameters.GUI.Ch3StopBlockLen + 1;
        end
    end
end

TrialData.Ch3PhasicBlockNumber(iTrial) = Nan;
TrialData.Ch3PhasicBlockTrialNumber(iTrial) = Nan;

if strcmpi(TaskParameters.GUIMeta.Ch3PhasicBlock.String{TaskParameters.GUI.Ch3PhasicBlock}, 'NotToRiskBlock') % need to draw new block
    if iTrial == 1
        TrialData.Ch3PhasicBlockNumber(iTrial) = 1;
        TrialData.Ch3PhasicBlockTrialNumber(iTrial) = 1;
        TaskParameters.GUI.Ch3PhasicBlockLen = randi([TaskParameters.GUI.Ch3PhasicBlockRangeMin, TaskParameters.GUI.Ch3PhasicBlockRangeMax]); % internal, not shown
        TaskParameters.GUI.Ch3PhasicNextBlockTrialNumber = TaskParameters.GUI.Ch3PhasicBlockLen + 1; % internal, not shown
    else
        TrialData.Ch3PhasicBlockNumber(iTrial) = TrialData.Ch3PhasicBlockNumber(iTrial-1);
        TrialData.Ch3PhasicBlockTrialNumber(iTrial) = TrialData.Ch3PhasicBlockTrialNumber(iTrial-1) + 1;
        if TrialData.Ch3PhasicBlockTrialNumber(iTrial) > TaskParameters.GUI.Ch3PhasicBlockLen
            TrialData.Ch3PhasicBlockNumber(iTrial) = TrialData.Ch3PhasicBlockNumber(iTrial-1) + 1;
            TrialData.Ch3PhasicBlockTrialNumber(iTrial) = 1;
            TaskParameters.GUI.Ch3PhasicBlockLen = randi([TaskParameters.GUI.Ch3PhasicBlockRangeMin, TaskParameters.GUI.Ch3PhasicBlockRangeMax]);
            TaskParameters.GUI.Ch3PhasicNextBlockTrialNumber = (iTrial-1) + TaskParameters.GUI.Ch3PhasicBlockLen + 1;
        end
    end
end

TrialData.Ch3TonicTrain{iTrial} = Nan; % only for Poisson train
TrialData.Ch3TonicBlockNumber(iTrial) = Nan;
TrialData.Ch3TonicBlockTrialNumber(iTrial) = Nan;

if strcmpi(TaskParameters.GUIMeta.Ch3TonicBlock.String{TaskParameters.GUI.Ch3TonicBlock}, 'NotToRiskBlock') % need to draw new block
    if iTrial == 1
        TrialData.Ch3TonicBlockNumber(iTrial) = 1;
        TrialData.Ch3TonicBlockTrialNumber(iTrial) = 1;
        TaskParameters.GUI.Ch3TonicBlockLen = randi([TaskParameters.GUI.Ch3TonicBlockRangeMin, TaskParameters.GUI.Ch3TonicBlockRangeMax]); % internal, not shown
        TaskParameters.GUI.Ch3TonicNextBlockTrialNumber = TaskParameters.GUI.Ch3TonicBlockLen + 1; % internal, not shown
    else
        TrialData.Ch3TonicBlockNumber(iTrial) = TrialData.Ch3TonicBlockNumber(iTrial-1);
        TrialData.Ch3TonicBlockTrialNumber(iTrial) = TrialData.Ch3TonicBlockTrialNumber(iTrial-1) + 1;
        if TrialData.Ch3TonicBlockTrialNumber(iTrial) > TaskParameters.GUI.Ch3TonicBlockLen
            TrialData.Ch3TonicBlockNumber(iTrial) = TrialData.Ch3TonicBlockNumber(iTrial-1) + 1;
            TrialData.Ch3TonicBlockTrialNumber(iTrial) = 1;
            TaskParameters.GUI.Ch3TonicBlockLen = randi([TaskParameters.GUI.Ch3TonicBlockRangeMin, TaskParameters.GUI.Ch3TonicBlockRangeMax]);
            TaskParameters.GUI.Ch3TonicNextBlockTrialNumber = (iTrial-1) + TaskParameters.GUI.Ch3TonicBlockLen + 1;
        end
    end
end

TrialData.WaitCInCh3Trigger(iTrial) = false;
TrialData.CInC3Trigger(iTrial) = false;
TrialData.SInCh3Trigger(iTrial) = false;
TrialData.WaterSCh3Trigger(iTrial) = false;
TrialData.SkippedFeedbackCh3Trigger(iTrial) = false;
TrialData.Ch3TonicCarriedForward(iTrial) = false; % mainly to check if WaitCIn needed reinstate tonic/basically ITICh3Tonic

if TaskParameters.GUIMeta.WaitCInCh3Percentage > (rand * 100)
    Ch3Key = TaskParameters.GUIMeta.WaitCInCh3Train.String{TaskParameters.GUI.WaitCInCh3Train};
    BlockKey = strcat('Ch3', Ch3Key, 'Block');
    switch TaskParameters.GUIMeta.(BlockKey).String{TaskParameters.GUI.(BlockKey)}
        case 'NoBlock'
            TrialData.WaitCInCh3Trigger(iTrial) = true;

        case 'ToRiskBlock' % always calculate, maybe for future need to sample block transition based on rand
            BlockTrialNumberKey = strcat('Ch3', Ch3Key, 'BlockTrialNumberKey');
            BlockRangeMaxKey = strcat('Ch3', Ch3Key, 'BlockRangeMaxKey');
            BlockRangeMinKey = strcat('Ch3', Ch3Key, 'BlockRangeMinKey');
            NextBlockTrialNumberKey = strcat('Ch3', Ch3Key, 'NextBlockTrialNumber');

            if TrialData.(BlockTrialNumberKey)(iTrial) < TaskParameters.GUI.(BlockRangeMaxKey)... % 80th (as 1st block) + 10 = 89
               || iTrial >= TaskParameters.GUI.(NextBlockTrialNumberKey) + TaskParameters.GUI.(BlockRangeMinKey) % 90th >= 100(1st trial after block) + (-10)
                TrialData.WaitCInCh3Trigger(iTrial) = true;
            end

        case 'NotToRiskBlock' % always 2nd block
            BlockTrialNumberKey = strcat('Ch3', Ch3Key, 'BlockTrialNumberKey');
            if mod(TrialData.(BlockTrialNumberKey)(iTrial), 2) == 0
                TrialData.WaitCInCh3Tonic(iTrial) = true;
            end

    end
end

if TaskParameters.GUIMeta.CInCh3Percentage > (rand * 100)
    Ch3Key = TaskParameters.GUIMeta.CInCh3Train.String{TaskParameters.GUI.CInCh3Train};
    BlockKey = strcat('Ch3', Ch3Key, 'Block');
    switch TaskParameters.GUIMeta.(BlockKey).String{TaskParameters.GUI.(BlockKey)}
        case 'NoBlock'
            TrialData.CInCh3Trigger(iTrial) = true;

        case 'ToRiskBlock' % always calculate, maybe for future need to sample block transition based on rand
            BlockTrialNumberKey = strcat('Ch3', Ch3Key, 'BlockTrialNumberKey');
            BlockRangeMaxKey = strcat('Ch3', Ch3Key, 'BlockRangeMaxKey');
            BlockRangeMinKey = strcat('Ch3', Ch3Key, 'BlockRangeMinKey');
            NextBlockTrialNumberKey = strcat('Ch3', Ch3Key, 'NextBlockTrialNumber');

            if TrialData.(BlockTrialNumberKey)(iTrial) < TaskParameters.GUI.(BlockRangeMaxKey)... % 80th (as 1st block) + 10 = 89
               || iTrial >= TaskParameters.GUI.(NextBlockTrialNumberKey) + TaskParameters.GUI.(BlockRangeMinKey) % 90th >= 100(1st trial after block) + (-10)
                TrialData.CInCh3Trigger(iTrial) = true;
            end

        case 'NotToRiskBlock' % always 2nd block
            BlockTrialNumberKey = strcat('Ch3', Ch3Key, 'BlockTrialNumberKey');
            if mod(TrialData.(BlockTrialNumberKey)(iTrial), 2) == 0
                TrialData.CInCh3Tonic(iTrial) = true;
            end
            
    end
end

if TaskParameters.GUIMeta.SInCh3Percentage > (rand * 100)
    Ch3Key = TaskParameters.GUIMeta.SInCh3Train.String{TaskParameters.GUI.SInCh3Train};
    BlockKey = strcat('Ch3', Ch3Key, 'Block');
    switch TaskParameters.GUIMeta.(BlockKey).String{TaskParameters.GUI.(BlockKey)}
        case 'NoBlock'
            TrialData.SInCh3Trigger(iTrial) = true;

        case 'ToRiskBlock' % always calculate, maybe for future need to sample block transition based on rand
            BlockTrialNumberKey = strcat('Ch3', Ch3Key, 'BlockTrialNumberKey');
            BlockRangeMaxKey = strcat('Ch3', Ch3Key, 'BlockRangeMaxKey');
            BlockRangeMinKey = strcat('Ch3', Ch3Key, 'BlockRangeMinKey');
            NextBlockTrialNumberKey = strcat('Ch3', Ch3Key, 'NextBlockTrialNumber');

            if TrialData.(BlockTrialNumberKey)(iTrial) < TaskParameters.GUI.(BlockRangeMaxKey)... % 80th (as 1st block) + 10 = 89
               || iTrial >= TaskParameters.GUI.(NextBlockTrialNumberKey) + TaskParameters.GUI.(BlockRangeMinKey) % 90th >= 100(1st trial after block) + (-10)
                TrialData.SInCh3Trigger(iTrial) = true;
            end

        case 'NotToRiskBlock' % always 2nd block
            BlockTrialNumberKey = strcat('Ch3', Ch3Key, 'BlockTrialNumberKey');
            if mod(TrialData.(BlockTrialNumberKey)(iTrial), 2) == 0
                TrialData.SInCh3Tonic(iTrial) = true;
            end
            
    end
end

if TaskParameters.GUIMeta.WaterSCh3Percentage > (rand * 100)
    Ch3Key = TaskParameters.GUIMeta.WaterSCh3Train.String{TaskParameters.GUI.WaterSCh3Train};
    BlockKey = strcat('Ch3', Ch3Key, 'Block');
    switch TaskParameters.GUIMeta.(BlockKey).String{TaskParameters.GUI.(BlockKey)}
        case 'NoBlock'
            TrialData.WaterSCh3Trigger(iTrial) = true;

        case 'ToRiskBlock' % always calculate, maybe for future need to sample block transition based on rand
            BlockTrialNumberKey = strcat('Ch3', Ch3Key, 'BlockTrialNumberKey');
            BlockRangeMaxKey = strcat('Ch3', Ch3Key, 'BlockRangeMaxKey');
            BlockRangeMinKey = strcat('Ch3', Ch3Key, 'BlockRangeMinKey');
            NextBlockTrialNumberKey = strcat('Ch3', Ch3Key, 'NextBlockTrialNumber');

            if TrialData.(BlockTrialNumberKey)(iTrial) < TaskParameters.GUI.(BlockRangeMaxKey)... % 80th (as 1st block) + 10 = 89
               || iTrial >= TaskParameters.GUI.(NextBlockTrialNumberKey) + TaskParameters.GUI.(BlockRangeMinKey) % 90th >= 100(1st trial after block) + (-10)
                TrialData.WaterSCh3Trigger(iTrial) = true;
            end

        case 'NotToRiskBlock' % always 2nd block
            BlockTrialNumberKey = strcat('Ch3', Ch3Key, 'BlockTrialNumberKey');
            if mod(TrialData.(BlockTrialNumberKey)(iTrial), 2) == 0
                TrialData.WaterSCh3Tonic(iTrial) = true;
            end
            
    end
end

if TaskParameters.GUIMeta.SkippedFeedbackCh3Percentage > (rand * 100)
    Ch3Key = TaskParameters.GUIMeta.SkippedFeedbackCh3Train.String{TaskParameters.GUI.SkippedFeedbackCh3Train};
    BlockKey = strcat('Ch3', Ch3Key, 'Block');
    switch TaskParameters.GUIMeta.(BlockKey).String{TaskParameters.GUI.(BlockKey)}
        case 'NoBlock'
            TrialData.SkippedFeedbackCh3Trigger(iTrial) = true;

        case 'ToRiskBlock' % always calculate, maybe for future need to sample block transition based on rand
            BlockTrialNumberKey = strcat('Ch3', Ch3Key, 'BlockTrialNumberKey');
            BlockRangeMaxKey = strcat('Ch3', Ch3Key, 'BlockRangeMaxKey');
            BlockRangeMinKey = strcat('Ch3', Ch3Key, 'BlockRangeMinKey');
            NextBlockTrialNumberKey = strcat('Ch3', Ch3Key, 'NextBlockTrialNumber');

            if TrialData.(BlockTrialNumberKey)(iTrial) < TaskParameters.GUI.(BlockRangeMaxKey)... % 80th (as 1st block) + 10 = 89
               || iTrial >= TaskParameters.GUI.(NextBlockTrialNumberKey) + TaskParameters.GUI.(BlockRangeMinKey) % 90th >= 100(1st trial after block) + (-10)
                TrialData.SkippedFeedbackCh3Trigger(iTrial) = true;
            end

        case 'NotToRiskBlock' % always 2nd block
            BlockTrialNumberKey = strcat('Ch3', Ch3Key, 'BlockTrialNumberKey');
            if mod(TrialData.(BlockTrialNumberKey)(iTrial), 2) == 0
                TrialData.SkippedFeedbackCh3Tonic(iTrial) = true;
            end
            
    end
end

%% Ch4
TrialData.Ch3StopBlockNumber(iTrial) = Nan;
TrialData.Ch3StopBlockTrialNumber(iTrial) = Nan;

if strcmpi(TaskParameters.GUIMeta.Ch3StopBlock.String{TaskParameters.GUI.Ch3StopBlock}, 'NotToRiskBlock') % need to draw new block
    if iTrial == 1
        TrialData.Ch3StopBlockNumber(iTrial) = 1;
        TrialData.Ch3StopBlockTrialNumber(iTrial) = 1;
        TaskParameters.GUI.Ch3StopBlockLen = randi([TaskParameters.GUI.Ch3StopBlockRangeMin, TaskParameters.GUI.Ch3StopBlockRangeMax]); % internal, not shown
        TaskParameters.GUI.Ch3StopNextBlockTrialNumber = TaskParameters.GUI.Ch3StopBlockLen + 1; % internal, not shown
    else
        TrialData.Ch3StopBlockNumber(iTrial) = TrialData.Ch3StopBlockNumber(iTrial-1);
        TrialData.Ch3StopBlockTrialNumber(iTrial) = TrialData.Ch3StopBlockTrialNumber(iTrial-1) + 1;
        if TrialData.Ch3StopBlockTrialNumber(iTrial) > TaskParameters.GUI.Ch3StopBlockLen
            TrialData.Ch3StopBlockNumber(iTrial) = TrialData.Ch3StopBlockNumber(iTrial-1) + 1;
            TrialData.Ch3StopBlockTrialNumber(iTrial) = 1;
            TaskParameters.GUI.Ch3StopBlockLen = randi([TaskParameters.GUI.Ch3StopBlockRangeMin, TaskParameters.GUI.Ch3StopBlockRangeMax]);
            TaskParameters.GUI.Ch3StopNextBlockTrialNumber = (iTrial-1) + TaskParameters.GUI.Ch3StopBlockLen + 1;
        end
    end
end

TrialData.Ch3PhasicBlockNumber(iTrial) = Nan;
TrialData.Ch3PhasicBlockTrialNumber(iTrial) = Nan;

if strcmpi(TaskParameters.GUIMeta.Ch3PhasicBlock.String{TaskParameters.GUI.Ch3PhasicBlock}, 'NotToRiskBlock') % need to draw new block
    if iTrial == 1
        TrialData.Ch3PhasicBlockNumber(iTrial) = 1;
        TrialData.Ch3PhasicBlockTrialNumber(iTrial) = 1;
        TaskParameters.GUI.Ch3PhasicBlockLen = randi([TaskParameters.GUI.Ch3PhasicBlockRangeMin, TaskParameters.GUI.Ch3PhasicBlockRangeMax]); % internal, not shown
        TaskParameters.GUI.Ch3PhasicNextBlockTrialNumber = TaskParameters.GUI.Ch3PhasicBlockLen + 1; % internal, not shown
    else
        TrialData.Ch3PhasicBlockNumber(iTrial) = TrialData.Ch3PhasicBlockNumber(iTrial-1);
        TrialData.Ch3PhasicBlockTrialNumber(iTrial) = TrialData.Ch3PhasicBlockTrialNumber(iTrial-1) + 1;
        if TrialData.Ch3PhasicBlockTrialNumber(iTrial) > TaskParameters.GUI.Ch3PhasicBlockLen
            TrialData.Ch3PhasicBlockNumber(iTrial) = TrialData.Ch3PhasicBlockNumber(iTrial-1) + 1;
            TrialData.Ch3PhasicBlockTrialNumber(iTrial) = 1;
            TaskParameters.GUI.Ch3PhasicBlockLen = randi([TaskParameters.GUI.Ch3PhasicBlockRangeMin, TaskParameters.GUI.Ch3PhasicBlockRangeMax]);
            TaskParameters.GUI.Ch3PhasicNextBlockTrialNumber = (iTrial-1) + TaskParameters.GUI.Ch3PhasicBlockLen + 1;
        end
    end
end

TrialData.Ch3TonicTrain{iTrial} = Nan; % only for Poisson train
TrialData.Ch3TonicBlockNumber(iTrial) = Nan;
TrialData.Ch3TonicBlockTrialNumber(iTrial) = Nan;

if strcmpi(TaskParameters.GUIMeta.Ch3TonicBlock.String{TaskParameters.GUI.Ch3TonicBlock}, 'NotToRiskBlock') % need to draw new block
    if iTrial == 1
        TrialData.Ch3TonicBlockNumber(iTrial) = 1;
        TrialData.Ch3TonicBlockTrialNumber(iTrial) = 1;
        TaskParameters.GUI.Ch3TonicBlockLen = randi([TaskParameters.GUI.Ch3TonicBlockRangeMin, TaskParameters.GUI.Ch3TonicBlockRangeMax]); % internal, not shown
        TaskParameters.GUI.Ch3TonicNextBlockTrialNumber = TaskParameters.GUI.Ch3TonicBlockLen + 1; % internal, not shown
    else
        TrialData.Ch3TonicBlockNumber(iTrial) = TrialData.Ch3TonicBlockNumber(iTrial-1);
        TrialData.Ch3TonicBlockTrialNumber(iTrial) = TrialData.Ch3TonicBlockTrialNumber(iTrial-1) + 1;
        if TrialData.Ch3TonicBlockTrialNumber(iTrial) > TaskParameters.GUI.Ch3TonicBlockLen
            TrialData.Ch3TonicBlockNumber(iTrial) = TrialData.Ch3TonicBlockNumber(iTrial-1) + 1;
            TrialData.Ch3TonicBlockTrialNumber(iTrial) = 1;
            TaskParameters.GUI.Ch3TonicBlockLen = randi([TaskParameters.GUI.Ch3TonicBlockRangeMin, TaskParameters.GUI.Ch3TonicBlockRangeMax]);
            TaskParameters.GUI.Ch3TonicNextBlockTrialNumber = (iTrial-1) + TaskParameters.GUI.Ch3TonicBlockLen + 1;
        end
    end
end

TrialData.WaitCInCh3Trigger(iTrial) = false;
TrialData.CInC3Trigger(iTrial) = false;
TrialData.SInCh3Trigger(iTrial) = false;
TrialData.WaterSCh3Trigger(iTrial) = false;
TrialData.SkippedFeedbackCh3Trigger(iTrial) = false;
TrialData.Ch3TonicCarriedForward(iTrial) = false; % mainly to check if WaitCIn needed reinstate tonic/basically ITICh3Tonic

if TaskParameters.GUIMeta.WaitCInCh3Percentage > (rand * 100)
    Ch3Key = TaskParameters.GUIMeta.WaitCInCh3Train.String{TaskParameters.GUI.WaitCInCh3Train};
    BlockKey = strcat('Ch3', Ch3Key, 'Block');
    switch TaskParameters.GUIMeta.(BlockKey).String{TaskParameters.GUI.(BlockKey)}
        case 'NoBlock'
            TrialData.WaitCInCh3Trigger(iTrial) = true;

        case 'ToRiskBlock' % always calculate, maybe for future need to sample block transition based on rand
            BlockTrialNumberKey = strcat('Ch3', Ch3Key, 'BlockTrialNumberKey');
            BlockRangeMaxKey = strcat('Ch3', Ch3Key, 'BlockRangeMaxKey');
            BlockRangeMinKey = strcat('Ch3', Ch3Key, 'BlockRangeMinKey');
            NextBlockTrialNumberKey = strcat('Ch3', Ch3Key, 'NextBlockTrialNumber');

            if TrialData.(BlockTrialNumberKey)(iTrial) < TaskParameters.GUI.(BlockRangeMaxKey)... % 80th (as 1st block) + 10 = 89
               || iTrial >= TaskParameters.GUI.(NextBlockTrialNumberKey) + TaskParameters.GUI.(BlockRangeMinKey) % 90th >= 100(1st trial after block) + (-10)
                TrialData.WaitCInCh3Trigger(iTrial) = true;
            end

        case 'NotToRiskBlock' % always 2nd block
            BlockTrialNumberKey = strcat('Ch3', Ch3Key, 'BlockTrialNumberKey');
            if mod(TrialData.(BlockTrialNumberKey)(iTrial), 2) == 0
                TrialData.WaitCInCh3Tonic(iTrial) = true;
            end

    end
end

if TaskParameters.GUIMeta.CInCh3Percentage > (rand * 100)
    Ch3Key = TaskParameters.GUIMeta.CInCh3Train.String{TaskParameters.GUI.CInCh3Train};
    BlockKey = strcat('Ch3', Ch3Key, 'Block');
    switch TaskParameters.GUIMeta.(BlockKey).String{TaskParameters.GUI.(BlockKey)}
        case 'NoBlock'
            TrialData.CInCh3Trigger(iTrial) = true;

        case 'ToRiskBlock' % always calculate, maybe for future need to sample block transition based on rand
            BlockTrialNumberKey = strcat('Ch3', Ch3Key, 'BlockTrialNumberKey');
            BlockRangeMaxKey = strcat('Ch3', Ch3Key, 'BlockRangeMaxKey');
            BlockRangeMinKey = strcat('Ch3', Ch3Key, 'BlockRangeMinKey');
            NextBlockTrialNumberKey = strcat('Ch3', Ch3Key, 'NextBlockTrialNumber');

            if TrialData.(BlockTrialNumberKey)(iTrial) < TaskParameters.GUI.(BlockRangeMaxKey)... % 80th (as 1st block) + 10 = 89
               || iTrial >= TaskParameters.GUI.(NextBlockTrialNumberKey) + TaskParameters.GUI.(BlockRangeMinKey) % 90th >= 100(1st trial after block) + (-10)
                TrialData.CInCh3Trigger(iTrial) = true;
            end

        case 'NotToRiskBlock' % always 2nd block
            BlockTrialNumberKey = strcat('Ch3', Ch3Key, 'BlockTrialNumberKey');
            if mod(TrialData.(BlockTrialNumberKey)(iTrial), 2) == 0
                TrialData.CInCh3Tonic(iTrial) = true;
            end
            
    end
end

if TaskParameters.GUIMeta.SInCh3Percentage > (rand * 100)
    Ch3Key = TaskParameters.GUIMeta.SInCh3Train.String{TaskParameters.GUI.SInCh3Train};
    BlockKey = strcat('Ch3', Ch3Key, 'Block');
    switch TaskParameters.GUIMeta.(BlockKey).String{TaskParameters.GUI.(BlockKey)}
        case 'NoBlock'
            TrialData.SInCh3Trigger(iTrial) = true;

        case 'ToRiskBlock' % always calculate, maybe for future need to sample block transition based on rand
            BlockTrialNumberKey = strcat('Ch3', Ch3Key, 'BlockTrialNumberKey');
            BlockRangeMaxKey = strcat('Ch3', Ch3Key, 'BlockRangeMaxKey');
            BlockRangeMinKey = strcat('Ch3', Ch3Key, 'BlockRangeMinKey');
            NextBlockTrialNumberKey = strcat('Ch3', Ch3Key, 'NextBlockTrialNumber');

            if TrialData.(BlockTrialNumberKey)(iTrial) < TaskParameters.GUI.(BlockRangeMaxKey)... % 80th (as 1st block) + 10 = 89
               || iTrial >= TaskParameters.GUI.(NextBlockTrialNumberKey) + TaskParameters.GUI.(BlockRangeMinKey) % 90th >= 100(1st trial after block) + (-10)
                TrialData.SInCh3Trigger(iTrial) = true;
            end

        case 'NotToRiskBlock' % always 2nd block
            BlockTrialNumberKey = strcat('Ch3', Ch3Key, 'BlockTrialNumberKey');
            if mod(TrialData.(BlockTrialNumberKey)(iTrial), 2) == 0
                TrialData.SInCh3Tonic(iTrial) = true;
            end
            
    end
end

if TaskParameters.GUIMeta.WaterSCh3Percentage > (rand * 100)
    Ch3Key = TaskParameters.GUIMeta.WaterSCh3Train.String{TaskParameters.GUI.WaterSCh3Train};
    BlockKey = strcat('Ch3', Ch3Key, 'Block');
    switch TaskParameters.GUIMeta.(BlockKey).String{TaskParameters.GUI.(BlockKey)}
        case 'NoBlock'
            TrialData.WaterSCh3Trigger(iTrial) = true;

        case 'ToRiskBlock' % always calculate, maybe for future need to sample block transition based on rand
            BlockTrialNumberKey = strcat('Ch3', Ch3Key, 'BlockTrialNumberKey');
            BlockRangeMaxKey = strcat('Ch3', Ch3Key, 'BlockRangeMaxKey');
            BlockRangeMinKey = strcat('Ch3', Ch3Key, 'BlockRangeMinKey');
            NextBlockTrialNumberKey = strcat('Ch3', Ch3Key, 'NextBlockTrialNumber');

            if TrialData.(BlockTrialNumberKey)(iTrial) < TaskParameters.GUI.(BlockRangeMaxKey)... % 80th (as 1st block) + 10 = 89
               || iTrial >= TaskParameters.GUI.(NextBlockTrialNumberKey) + TaskParameters.GUI.(BlockRangeMinKey) % 90th >= 100(1st trial after block) + (-10)
                TrialData.WaterSCh3Trigger(iTrial) = true;
            end

        case 'NotToRiskBlock' % always 2nd block
            BlockTrialNumberKey = strcat('Ch3', Ch3Key, 'BlockTrialNumberKey');
            if mod(TrialData.(BlockTrialNumberKey)(iTrial), 2) == 0
                TrialData.WaterSCh3Tonic(iTrial) = true;
            end
            
    end
end

if TaskParameters.GUIMeta.SkippedFeedbackCh3Percentage > (rand * 100)
    Ch3Key = TaskParameters.GUIMeta.SkippedFeedbackCh3Train.String{TaskParameters.GUI.SkippedFeedbackCh3Train};
    BlockKey = strcat('Ch3', Ch3Key, 'Block');
    switch TaskParameters.GUIMeta.(BlockKey).String{TaskParameters.GUI.(BlockKey)}
        case 'NoBlock'
            TrialData.SkippedFeedbackCh3Trigger(iTrial) = true;

        case 'ToRiskBlock' % always calculate, maybe for future need to sample block transition based on rand
            BlockTrialNumberKey = strcat('Ch3', Ch3Key, 'BlockTrialNumberKey');
            BlockRangeMaxKey = strcat('Ch3', Ch3Key, 'BlockRangeMaxKey');
            BlockRangeMinKey = strcat('Ch3', Ch3Key, 'BlockRangeMinKey');
            NextBlockTrialNumberKey = strcat('Ch3', Ch3Key, 'NextBlockTrialNumber');

            if TrialData.(BlockTrialNumberKey)(iTrial) < TaskParameters.GUI.(BlockRangeMaxKey)... % 80th (as 1st block) + 10 = 89
               || iTrial >= TaskParameters.GUI.(NextBlockTrialNumberKey) + TaskParameters.GUI.(BlockRangeMinKey) % 90th >= 100(1st trial after block) + (-10)
                TrialData.SkippedFeedbackCh3Trigger(iTrial) = true;
            end

        case 'NotToRiskBlock' % always 2nd block
            BlockTrialNumberKey = strcat('Ch3', Ch3Key, 'BlockTrialNumberKey');
            if mod(TrialData.(BlockTrialNumberKey)(iTrial), 2) == 0
                TrialData.SkippedFeedbackCh3Tonic(iTrial) = true;
            end
            
    end
end

%% 
BpodSystem.Data.Custom.TrialData = TrialData;

end
function TwoArmBanditVariant_UpdateCustomDataFields(iTrial)

global BpodSystem
global TaskParameters

% data structure references
RawData = BpodSystem.Data.RawData;
RawEvents = BpodSystem.Data.RawEvents;
TrialStates = RawEvents.Trial{iTrial}.States;
TrialData = BpodSystem.Data.Custom.TrialData;

BpodSystem.Data.TrialTypes(iTrial) = 1; %??

%% OutcomeRecord
% Go through the states visited this trial and 
idxStatesVisited = RawData.OriginalStateData{iTrial};
TrialStateNames = RawData.OriginalStateNamesByNumber{iTrial};
StatesThisTrial = TrialStateNames(idxStatesVisited);

%% Pre-stimulus delivery
if ~any(strcmp('NoTrialStart', StatesThisTrial)) % for RestartInvalidTrial, one may start CIn, looped back with BF/EW, then NoTrialStart
    TrialData.NoTrialStart(iTrial) = false;
end

if any(strcmp('StartCIn', StatesThisTrial)) % for RestartInvalidTrial, one may start CIn, looped back with BF/EW, then NoTrialStart
    TrialData.TimeCenterPoke(iTrial) = TrialStates.StartCIn(end, 1); % last one should be the actual one for the trial
end

if any(strcmp('BrokeFixation', StatesThisTrial))
    TrialData.BrokeFixation(iTrial) = true;
elseif any(strcmp('Sampling', StatesThisTrial))
    TrialData.BrokeFixation(iTrial) = false;
end

% Get total amount of time spent waiting for stimulus
if any(strcmp('StimulusDelay', StatesThisTrial))
    WaitBegin = TrialStates.StimulusDelay(end, 1); % last one should be the actual one
    WaitEnd = TrialStates.StimulusDelay(end, 2); 
    TrialData.StimWaitingTime(iTrial) = WaitEnd - WaitBegin;
end

%% Peri-stimulus delivery and Pre-decision
% Compute length of SamplingGrace, i.e. Grace Period for Center pokes
if any(strcmp('SamplingGrace', StatesThisTrial))
    RegisteredWithdrawals = TrialStates.SamplingGrace;

    for iExit = 1:size(RegisteredWithdrawals, 1) % one may enter SamplingGrace multiple time, i_exit is the number of time
        ExitTime = RegisteredWithdrawals(iExit, 1);
        ReturnTime = RegisteredWithdrawals(iExit, 2);
        TrialData.SamplingGrace(iExit, iTrial) = ReturnTime - ExitTime;
    end
end  

if any(strcmp('EarlyWithdrawal', StatesThisTrial))
    TrialData.EarlyWithdrawal(iTrial) = true;
elseif any(strcmp('StillSampling', StatesThisTrial))
    TrialData.EarlyWithdrawal(iTrial) = false;
end

% Get total amount of time spent sampling
if any(strcmp('Sampling', StatesThisTrial)) % Not From StimulusDelay
    SamplingBegin = TrialStates.Sampling(end, 1);
    if any(strcmp('StillSampling', StatesThisTrial))
        SamplingEnd = TrialStates.StillSampling(end, 2);
    elseif any(strcmp('EarlyWithdrawal', StatesThisTrial))
        SamplingEnd = TrialStates.SamplingGrace(end, end);
    else
        SamplingEnd = TrialStates.Sampling(end, end);
    end
    TrialData.SampleTime(iTrial) = SamplingEnd - SamplingBegin;
end

%% Peri-decision and pre-outcome
if any(strcmp('NoDecision', StatesThisTrial))
    TrialData.NoDecision(iTrial) = true;
elseif any(strcmp('StartNewTrial', StatesThisTrial)) || any(strcmp('StartLIn', StatesThisTrial)) || any(strcmp('StartRIn', StatesThisTrial))
    TrialData.NoDecision(iTrial) = false;
end

if any(strcmp('WaitSIn', StatesThisTrial))
    TrialData.MoveTime(iTrial) = TrialStates.WaitSIn(1, 2) - TrialStates.WaitSIn(1, 1); % from CenterPortOut to SidePortIn, old MT confirmed
end

% TrialData.StartNewTrialEnabled(iTrial) = TaskParameters.GUI.StartNewTrial; % if false TaskParameters.GUI.StartNewTrial is off;
if any(strcmp('StartNewTrial', StatesThisTrial))
    TrialData.StartNewTrial(iTrial) = true; % only concern state 'StartNewTrialTimeOut'
    TrialData.StartNewTrialSuccessful(iTrial) = false;
elseif any(strcmp('StartLIn', StatesThisTrial)) || any(strcmp('StartRIn', StatesThisTrial))
    TrialData.StartNewTrial(iTrial) = false;
end

if any(strcmp('StartNewTrialTimeOut', StatesThisTrial))
    TrialData.StartNewTrialSuccessful(iTrial) = true;
end

if any(strcmp('StartLIn', StatesThisTrial))
    TrialData.TimeChoice(iTrial) = TrialStates.StartLIn(1,1);
    TrialData.ChoiceLeft(iTrial) = true; % True if a choice is made to the left poke (also include incorrect choice)
elseif any(strcmp('StartRIn', StatesThisTrial))
    TrialData.TimeChoice(iTrial) = TrialStates.StartRIn(1,1);
    TrialData.ChoiceLeft(iTrial) = false; % True if a choice is made to the left poke (also include incorrect choice)
end

if ~isnan(TrialData.LightLeft(iTrial))
    if any(strcmp('StartLIn', StatesThisTrial)) || any(strcmp('StartRIn', StatesThisTrial))
        TrialData.IncorrectChoice(iTrial) = TrialData.ChoiceLeft(iTrial)~=TrialData.LightLeft(iTrial); % True if the choice is incorrect (only for 1-arm bandit/GUI.SingleSidePoke); basically = LigthLeft & ChoiceLeft
    end
end

RegisteredWithdrawals = [];
if any(strcmp('LInGrace', StatesThisTrial))
    RegisteredWithdrawals = TrialStates.LInGrace;
elseif any(strcmp('RInGrace', StatesThisTrial))
    RegisteredWithdrawals = TrialStates.RInGrace;
end
if ~isempty(RegisteredWithdrawals)
    for iExit = 1:size(RegisteredWithdrawals, 1) % one may enter SamplingGrace multiple time, i_exit is the number of time
        ExitTime = RegisteredWithdrawals(iExit, 1);
        ReturnTime = RegisteredWithdrawals(iExit, 2);
        TrialData.FeedbackGrace(iExit, iTrial) = (ReturnTime - ExitTime);
    end
end

if any(strcmp('StartLIn', StatesThisTrial))
    WaitBegin = TrialStates.StartLIn(1, 1);
    WaitEnd = TrialStates.LIn(end, 2);
    TrialData.FeedbackWaitingTime(iTrial) = WaitEnd - WaitBegin;
elseif any(strcmp('StartRIn',StatesThisTrial))
    WaitBegin = TrialStates.StartRIn(1, 1);
    WaitEnd = TrialStates.RIn(end, 2);
    TrialData.FeedbackWaitingTime(iTrial) = WaitEnd - WaitBegin;
end

if any(strcmp('SkippedFeedback',StatesThisTrial))
    TrialData.TimeSkippedFeedback(iTrial) = TrialStates.SkippedFeedback(1, 1);
    TrialData.SkippedFeedback(iTrial) = true; % True if SkippedFeedback
elseif any(strcmp('WaterL',StatesThisTrial)) || any(strcmp('WaterR',StatesThisTrial)) || any(strcmp('IncorrectChoice',StatesThisTrial))
   TrialData.SkippedFeedback(iTrial) = false;
end

if TaskParameters.GUI.CatchTrial && ~isnan(TrialData.ChoiceLeft(iTrial)) % if a choice is made (no matter SingleSidePoke) 
    TrialData.TITrial(iTrial) = false; % True if it is included in TimeInvestment
    if TrialData.IncorrectChoice(iTrial) == 1 % Catch 1: incorrect choice
        TrialData.TITrial(iTrial) = true;
    elseif TrialData.Baited(2-TrialData.ChoiceLeft(iTrial), iTrial) == 0 % Catch 2: choice made is not baited
        TrialData.TITrial(iTrial) = true;
    elseif TrialData.SkippedFeedback(iTrial) && TrialData.Baited(2-TrialData.ChoiceLeft(iTrial), iTrial) == 1 % Catch 3: Choice made is baited, but Skipped Feedback
        TrialData.TITrial(iTrial) = true;
    end
end

%% Peri-outcome
if any(strcmp('WaterL', StatesThisTrial)) || any(strcmp('WaterR', StatesThisTrial)) % if a choice is made (no matter SingleSidePoke) 
    TrialData.Rewarded(iTrial) = true;
elseif ~isnan(TrialData.ChoiceLeft(iTrial)) % either incorrect, not baited, or skipped
    TrialData.Rewarded(iTrial) = false;
end    
    
if TrialData.Rewarded(iTrial) == true % No change if Skipped Feedback
    if TrialData.ChoiceLeft(iTrial) == 1
        TrialData.AvailableReward(1, iTrial) = false;
    elseif TrialData.ChoiceLeft(iTrial) == 0
        TrialData.AvailableReward(2, iTrial) = false;
    end
end

if TrialData.Rewarded(iTrial) == true
    if any(strcmp('WaterL', StatesThisTrial))
        TrialData.TimeReward(iTrial) = TrialStates.WaterL(1, 1);
    elseif any(strcmp('WaterR', StatesThisTrial))
        TrialData.TimeReward(iTrial) = TrialStates.WaterR(1, 1);
    end
end

NotBaitedAction = TaskParameters.GUIMeta.NotBaitedFeedback.String{TaskParameters.GUI.NotBaitedFeedback};
if NotBaitedAction == "WhiteNoise" || NotBaitedAction == "Beep"
    TrialData.TimeNotBaitedFeedback(iTrial) = TrialStates.NotBaited(1, 1);
end

if TrialData.Rewarded(iTrial) == true
    DrinkingBegin = TrialStates.Drinking(1, 1);
    DrinkingEnd = TrialStates.Drinking(end, 2); 
    TrialData.DrinkingTime(iTrial) = DrinkingEnd - DrinkingBegin;
end

%% opto carry forward
if TrialData.SkippedFeedback(iTrial) == true
    EndingTriggerType = 'SkippedFeedback';
elseif TrialData.Rewarded(iTrial) == true
    EndingTriggerType = 'WaterS';
elseif ~isnan(TrialData.ChoiceLeft(iTrial))
    EndingTriggerType = 'SIn';
elseif ~TrialData.NoTrialStart(iTrial) % so it can't be first BF then NTS
    EndingTriggerType = 'CIn';
else
    EndingTriggerType = 'WaitCIn';
end

Channels = {'Ch3', 'Ch4'};
for iChannel = 1:length(Channels)
    ChannelName = Channels{iChannel};

    EndKey = strcat(EndingTriggerType, ChannelName, 'End');
    TrainKey = strcat(EndingTriggerType, ChannelName, 'Train');
    TonicCarriedForwardKey = strcat(Channel, 'TonicCarriedForward');
    TriggerKey = strcat(EndingTriggerType, ChannelName, 'Trigger');
    TonicSuppressedKey = strcat(EndingTriggerType, ChannelName, 'TonicSuppressed');
    
    if ~strcmpi(TaskParameters.GUIMeta.(EndKey).String{TaskParameters.GUI.(EndKey)}, 'Tonic')...
       || ~strcmpi(TaskParameters.GUIMeta.(TrainKey).String{TaskParameters.GUI.(TrainKey)}, 'Tonic')
        TrialData.(TonicCarriedForwardKey)(iTrial) = false;
    elseif strcmpi(TaskParameters.GUIMeta.(TrainKey).String{TaskParameters.GUI.(TrainKey)}, 'Tonic')...
           && ~TrialData.(TriggerKey)(iTrial)...
           && ~TrialData.(TonicSuppressedKey)(iTrial)
        TrialData.(TonicCarriedForwardKey)(iTrial) = false;
    else
        TrialData.(TonicCarriedForwardKey)(iTrial) = true;
    end
end

BpodSystem.Data.Custom.TrialData = TrialData;
end
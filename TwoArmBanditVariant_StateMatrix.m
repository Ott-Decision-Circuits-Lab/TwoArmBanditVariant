function sma = TwoArmBanditVariant_StateMatrix(iTrial)

global BpodSystem
global TaskParameters

TrialData = BpodSystem.Data.Custom.TrialData;

%% Define ports
LeftPort = floor(mod(TaskParameters.GUI.Ports_LMR/100, 10));
CenterPort = floor(mod(TaskParameters.GUI.Ports_LMR/10, 10));
RightPort = mod(TaskParameters.GUI.Ports_LMR, 10);

LeftPortOut = strcat('Port', num2str(LeftPort), 'Out');
CenterPortOut = strcat('Port', num2str(CenterPort), 'Out');
RightPortOut = strcat('Port', num2str(RightPort), 'Out');

LeftPortIn = strcat('Port', num2str(LeftPort), 'In');
CenterPortIn = strcat('Port', num2str(CenterPort), 'In');
RightPortIn = strcat('Port', num2str(RightPort), 'In');

LeftLight = strcat('PWM', num2str(LeftPort));
CenterLight = strcat('PWM', num2str(CenterPort));
RightLight = strcat('PWM', num2str(RightPort));

LeftValve = 2^(LeftPort - 1);
CenterValve = 2^(CenterPort - 1);
RightValve = 2^(RightPort - 1);

%% Calculate value time for ports in different situations
LeftValveTime  = GetValveTimes(TrialData.RewardMagnitude(1, iTrial), LeftPort);
RightValveTime  = GetValveTimes(TrialData.RewardMagnitude(2, iTrial), RightPort);

%% OptoTable
OptoTable = table('Size', [4, 4],...
                  'VariableTypes', {'double', 'double', 'double', 'double'},...
                  'VariableNames', {'None', 'Stop', 'Tonic', 'Phasic'},...
                  'RowNames', {'None', 'Stop', 'Tonic', 'Phasic'},...
                  'DimensionNames', {'Ch3', 'Ch4'}); % row = ch3, column = ch4

OptoTable(:, :) = num2cell(reshape([63, 10:24], 4, 4)'); % Profile Index 64: reserved for no playback, i.e. 'None' on all channels

OptoWhiteNoiseTable = table('Size', [3, 3],...
                            'VariableTypes', {'double', 'double', 'double'},...
                            'VariableNames', {'None', 'Stop', 'Tonic'},...
                            'RowNames', {'None', 'Stop', 'Tonic'},...
                            'DimensionNames', {'Ch3', 'Ch4'}); % row = ch3, column = ch4

OptoWhiteNoiseTable(:, :) = num2cell(reshape([2, 25:32], 3, 3)'); % Profile Index 3: NoDecision usually with WhiteNoise

Opto500HzTable = table('Size', [3, 3],...
                        'VariableTypes', {'double', 'double', 'double'},...
                        'VariableNames', {'None', 'Stop', 'Tonic'},...
                        'RowNames', {'None', 'Stop', 'Tonic'},...
                        'DimensionNames', {'Ch3', 'Ch4'}); % row = ch3, column = ch4

Opto500HzTable(:, :) = num2cell(reshape([6, 33:40], 3, 3)'); % Profile Index 7: NotBaited, only it will have 500Hz beep

Opto1kHzTable = table('Size', [4, 4],...
                      'VariableTypes', {'double', 'double', 'double', 'double'},...
                      'VariableNames', {'None', 'Stop', 'Tonic', 'Phasic'},...
                      'RowNames', {'None', 'Stop', 'Tonic', 'Phasic'},...
                      'DimensionNames', {'Ch3', 'Ch4'}); % row = ch3, column = ch4

Opto1kHzTable(:, :) = num2cell(reshape([5, 41:55], 4, 4)');  % Profile Index 6: SkippedFeedback, it usually has 1kHz beep

%% Set up state matrix    
sma = NewStateMatrix();

%% PreITI
PreITIAction = {};
if isfield(TaskParameters.GUI, 'Wire1VideoTrigger')
    switch TaskParameters.GUIMeta.Wire1VideoTrigger.String{TaskParameters.GUI.Wire1VideoTrigger}
        case 1 % None

        case 2 % Investment

        case 3 % All
            PreITIAction =	[PreITIAction, {'WireState', 1}];
    end
            
end
if isfield(BpodSystem.ModuleUSB, 'WavePlayer1') % if also WavePlayer -> opto
    WaitCInCh3Train = TaskParameters.GUIMeta.WaitCInCh3Train.String{TaskParameters.GUI.WaitCInCh3Train};
    WaitCInCh3Key = WaitCInCh3Train;
    if ~TrialData.WaitCInCh3Trigger(iTrial)
        WaitCInCh3Key = 'None';
    end

    WaitCInCh4Train = TaskParameters.GUIMeta.WaitCInCh4Train.String{TaskParameters.GUI.WaitCInCh4Train};
    WaitCInCh4Key = WaitCInCh4Train;
    if ~TrialData.WaitCInCh4Trigger(iTrial)
        WaitCInCh4Key = 'None';
    end
    
    PreITIAction = [PreITIAction, {'WavePlayer1', ['P', OptoTable{WaitCInCh3Key, WaitCInCh4Key}]}];
end
sma = AddState(sma,...
               'Name', 'PreITI',...
               'Timer', TaskParameters.GUI.PreITI,...
               'StateChangeConditions', {'Tup', 'WaitCIn'},...
               'OutputActions', PreITIAction);

%% WaitCIN
sma = AddState(sma,...
               'Name', 'WaitCIn',...
               'Timer', TaskParameters.GUI.WaitCInMax,...
               'StateChangeConditions', {CenterPortIn, 'StartCIn',...
                                         'Tup', 'NoTrialStart'},...
               'OutputActions', {CenterLight, 255});

%% NoTrialStart
NoTrialStartAction = {};
if isfield(BpodSystem.ModuleUSB, 'WavePlayer1') % if also WavePlayer -> opto
    WaitCInCh3End = TaskParameters.GUIMeta.WaitCInCh3End.String{TaskParameters.GUI.WaitCInCh3End};
    WaitCInCh3EndKey = WaitCInCh3End;
    if strcmpi(WaitCInCh3End, 'Tonic')...
       && ~TaskParameters.GUI.Ch3RepeatedTonicTrigger...
       && strcmpi(WaitCInCh3Train, 'Tonic')
        WaitCInCh3EndKey = 'None';
    end
    
    WaitCInCh4End = TaskParameters.GUIMeta.WaitCInCh4End.String{TaskParameters.GUI.WaitCInCh4End};
    WaitCInCh4EndKey = WaitCInCh4End;
    if strcmpi(WaitCInCh4End, 'Tonic')...
       && ~TaskParameters.GUI.Ch4RepeatedTonicTrigger...
       && strcmpi(WaitCInCh4Train, 'Tonic')
        WaitCInCh4EndKey = 'None';
    end
    
    NoTrialStartAction = [NoTrialStartAction, {'WavePlayer1', ['P', OptoTable{WaitCInCh3EndKey, WaitCInCh4EndKey}]}];
end
sma = AddState(sma,...
               'Name', 'NoTrialStart',...
               'Timer', 0,...
               'StateChangeConditions', {'Tup', 'ITI'},...
               'OutputActions', NoTrialStartAction);

%% StartCIn
%{
dev note: technically this state is affected by WaitCInCh3End & WaitCInCh4End
but also this is a dummy state and the CIn comes immediately, thus does not
make sense to take care of the WaitCInCh3/4End
%}
sma = SetGlobalTimer(sma, 1, TaskParameters.GUI.StimulusTime + TaskParameters.GUI.StimDelay); % used to track centre poke grace period

sma = AddState(sma,...
               'Name', 'StartCIn',... % dummy state for trigger GlobalTimer1
               'Timer', 0,...
               'StateChangeConditions', {'Tup', 'StimulusDelay',...
                                         'GlobalTimer1_End', 'StillSampling'},...
               'OutputActions', {'GlobalTimerTrig', 1});

%% StimulusDelay
StimulusDelayAction = {};
if isfield(BpodSystem.ModuleUSB, 'WavePlayer1') % if also WavePlayer -> opto
    CInCh3Train = TaskParameters.GUIMeta.CInCh3Train.String{TaskParameters.GUI.CInCh3Train};
    CInCh3Key = CInCh3Train;
    if ~TrialData.CInCh3Trigger(iTrial)
        CInCh3Key = 'None';
    end

    CInCh4Train = TaskParameters.GUIMeta.CInCh4Train.String{TaskParameters.GUI.CInCh4Train};
    CInCh4Key = CInCh4Train;
    if ~TrialData.CInCh4Trigger(iTrial)
        CInCh4Key = 'None';
    end

    StimulusDelayAction = [StimulusDelayAction, {'WavePlayer1', ['P', OptoTable{CInCh3Key, CInCh4Key}]}];
end
sma = AddState(sma,...
               'Name', 'StimulusDelay',...
               'Timer', TaskParameters.GUI.StimDelay,...
               'StateChangeConditions', {'Tup', 'Sampling',...
                                         CenterPortOut, 'BrokeFixation',...
                                         'GlobalTimer1_End', 'StillSampling'},...
               'OutputActions', StimulusDelayAction);

%% CInEndOpto
CInEndOpto = {};
CInEndOptoWhiteNoise = {};
if isfield(BpodSystem.ModuleUSB, 'WavePlayer1') % if also WavePlayer -> opto
    CInCh3End = TaskParameters.GUIMeta.CInCh3End.String{TaskParameters.GUI.CInCh3End};
    CInCh3EndKey = CInCh3End;
    if strcmpi(CInCh3End, 'Tonic')...
       && ~TaskParameters.GUI.Ch3RepeatedTonicTrigger...
       && strcmpi(CInCh3Train, 'Tonic')
        CInCh3EndKey = 'None';
    end

    CInCh4End = TaskParameters.GUIMeta.CInCh4End.String{TaskParameters.GUI.CInCh4End};
    CInCh4EndKey = CInCh4End;
    if strcmpi(CInCh4End, 'Tonic')...
       && ~TaskParameters.GUI.Ch4RepeatedTonicTrigger...
       && strcmpi(CInCh4Train, 'Tonic')
        CInCh4EndKey = 'None';
    end

    CInEndOpto = {'WavePlayer1', ['P', OptoTable{CInCh3EndKey, CInCh4EndKey}]};
    CInEndOptoWhiteNoise = {'WavePlayer1', ['P', OptoWhiteNoiseTable{CInCh3EndKey, CInCh4EndKey}]};
end

%% BrokeFixation
TupStateChange = 'ITI';
if TaskParameters.GUI.RenewBrokeFixation
    TupStateChange = 'WaitCIn';
end
BrokeFixationAction = {};
switch TaskParameters.GUIMeta.BrokeFixationFeedback.String{TaskParameters.GUI.BrokeFixationFeedback}
    case 'None' % only opto adjustment
        BrokeFixationAction = [BrokeFixationAction, CInEndOpto];
        
    case 'WhiteNoise' % sound + opto
        if isfield(BpodSystem.ModuleUSB, 'HiFi1') % prioritize HiFi for sound
            BrokeFixationAction = [BrokeFixationAction, {'HiFi1', ['P' 0]}];
            BrokeFixationAction = [BrokeFixationAction, CInEndOpto];

        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            BrokeFixationAction = [BrokeFixationAction, CInEndOptoWhiteNoise];

        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No BrokeFixation WhiteNoise is played.');
        else
            disp('Neither HiFi nor analog module is setup. No BrokeFixation WhiteNoise is played.');
        end
        
end
sma = AddState(sma,...
               'Name', 'BrokeFixation',...
               'Timer', TaskParameters.GUI.BrokeFixationTimeOut,...
               'StateChangeConditions', {'Tup', TupStateChange},...
               'OutputActions', BrokeFixationAction);

%% Sampling
SamplingAction = {};
switch TaskParameters.GUIMeta.RiskType.String{TaskParameters.GUI.RiskType}
    case 'Fix' % no adjustmnet needed
        
    case 'BlockRand' % no adjustmnet needed

    case 'BlockRandHolding' % no adjustmnet needed
        
    case 'BlockFix' % no adjustmnet needed
     
    case 'BlockFixHolding' % no adjustmnet needed
        
    case 'Cued'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1')
            SamplingAction = {'HiFi1', ['P' 7]};
        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            SamplingAction = {'WavePlayer1', ['P' 7]};
        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No Sampling Cued is played.');
        else
            disp('Neither HiFi nor analog module is setup. No Sampling Cued is played.');
        end

    case 'BlockCued'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1')
            SamplingAction = {'HiFi1', ['P' 7]};
        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            SamplingAction = {'WavePlayer1', ['P' 7]};
        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No Sampling Cued is played.');
        else
            disp('Neither HiFi nor analog module is setup. No Sampling Cued is played.');
        end

    case 'CuedBlockRatio'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1')
            SamplingAction = {'HiFi1', ['P' 7]};
        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            SamplingAction = {'WavePlayer1', ['P' 7]};
        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No Sampling Cued is played.');
        else
            disp('Neither HiFi nor analog module is setup. No Sampling Cued is played.');
        end

    case 'CuedBlockITI'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1')
            SamplingAction = {'HiFi1', ['P' 7]};
        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            SamplingAction = {'WavePlayer1', ['P' 7]};
        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No Sampling Cued is played.');
        else
            disp('Neither HiFi nor analog module is setup. No Sampling Cued is played.');
        end

    case 'CuedBlockTau'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1')
            SamplingAction = {'HiFi1', ['P' 7]};
        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            SamplingAction = {'WavePlayer1', ['P' 7]};
        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No Sampling Cued is played.');
        else
            disp('Neither HiFi nor analog module is setup. No Sampling Cued is played.');
        end
end
sma = AddState(sma,...
               'Name', 'Sampling',...
               'Timer', TaskParameters.GUI.StimulusTime,...
               'StateChangeConditions', {'Tup', 'StillSampling',...
                                         CenterPortOut, 'SamplingGrace',...
                                         'GlobalTimer1_End', 'StillSampling'},...
               'OutputActions', SamplingAction);

%% SamplingGrace
%{
dev note: technically, this is affected by CInCh3End and CInCh4End but
because it may just be poke flickering, it's better to do it at
EarlyWithdrawal
%}
sma = AddState(sma,...
               'Name', 'SamplingGrace',...
               'Timer', TaskParameters.GUI.SamplingGrace,...
               'StateChangeConditions', {CenterPortIn, 'Sampling',...
                                         'Tup', 'EarlyWithdrawal',...
                                         'GlobalTimer1_End', 'EarlyWithdrawal',...
                                         LeftPortIn, 'EarlyWithdrawal',...
                                         RightPortIn, 'EarlyWithdrawal'},...
               'OutputActions', {});

%% EarlyWithdrawal
TupStateChange = 'ITI';
if TaskParameters.GUI.RenewEarlyWithdrawal
    TupStateChange = 'WaitCIn';
end
EarlyWithdrawalAction = {};
switch TaskParameters.GUIMeta.EarlyWithdrawalFeedback.String{TaskParameters.GUI.EarlyWithdrawalFeedback}
    case 'None'
        EarlyWithdrawalAction = [EarlyWithdrawalAction, CInEndOpto];

    case 'WhiteNoise'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1') % prioritize HiFi for sound
            EarlyWithdrawalAction = [EarlyWithdrawalAction, {'HiFi1', ['P' 1]}];
            EarlyWithdrawalAction = [EarlyWithdrawalAction, CInEndOpto];
            
        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            EarlyWithdrawalAction = [EarlyWithdrawalAction, CInEndOptoWhiteNoise];

        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No EarlyWithdrawal WhiteNoise will be played.');
        else
            disp('Neither HiFi nor analog module is setup. No EarlyWithdrawal WhiteNoise will be played.');
        end
        
end
sma = AddState(sma,...
               'Name', 'EarlyWithdrawal',...
               'Timer', TaskParameters.GUI.EarlyWithdrawalTimeOut,...
               'StateChangeConditions', {'Tup', TupStateChange},...
               'OutputActions', EarlyWithdrawalAction);

%% LightValue
CInStateChange = 'WaitSIn';
CenterLightValue = 0;
if TaskParameters.GUI.StartNewTrialEnable
    CInStateChange = 'StartNewTrial';
    CenterLightValue = 255;
end

LeftLightValue = 255;
RightLightValue = 255;
if TrialData.LightLeft(iTrial) == true
    RightLightValue = 0;
elseif TrialData.LightLeft(iTrial) == false
    LeftLightValue = 0;
end

%% StillSampling
sma = SetGlobalTimer(sma, 2, TaskParameters.GUI.ChoiceDeadline); % used to track side poke grace period

sma = AddState(sma,...
               'Name', 'StillSampling',... % dummy state for trigger GlobalTimer2
               'Timer', TaskParameters.GUI.ChoiceDeadline,...
               'StateChangeConditions', {'Tup', 'NoDecision',...
                                         CenterPortOut, 'WaitSIn',...
                                         'GlobalTimer2_End', 'NoDecision'},...
               'OutputActions', {'GlobalTimerTrig', 2,...
                                 LeftLight, LeftLightValue,...
                                 RightLight, RightLightValue...
                                 CenterLight, CenterLightValue});

%% WaitSIn
WaitSInAction = {LeftLight, LeftLightValue,...
                 RightLight, RightLightValue...
                 CenterLight, CenterLightValue};
WaitSInAction = [WaitSInAction, CInEndOpto];
sma = AddState(sma,...
               'Name', 'WaitSIn',...
               'Timer', TaskParameters.GUI.ChoiceDeadline,...
               'StateChangeConditions', {'Tup', 'NoDecision',...
                                         'GlobalTimer2_End', 'NoDecision',...
                                         CenterPortIn, CInStateChange,...
                                         LeftPortIn, 'StartLIn',...
                                         RightPortIn, 'StartRIn'},...
               'OutputActions', WaitSInAction);
                  
%% NoDecision
NoDecisionAction = {};
switch TaskParameters.GUIMeta.NoDecisionFeedback.String{TaskParameters.GUI.NoDecisionFeedback}
    case 'None'
        NoDecisionAction = [NoDecisionAction, CInEndOpto];
        
    case 'WhiteNoise'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1')
            NoDecisionAction = [NoDecisionAction, {'HiFi1', ['P' 2]}];
            NoDecisionAction = [NoDecisionAction, CInEndOpto];

        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            NoDecisionAction = [NoDecisionAction, CInEndOptoWhiteNoise];

        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No NoDecision WhiteNoise will be played.');
        else
            disp('Neither HiFi nor analog module is setup. No NoDecision WhiteNoise will be played.');
        end
        
end
sma = AddState(sma,...
               'Name', 'NoDecision',...
               'Timer', TaskParameters.GUI.NoDecisionTimeOut,...
               'StateChangeConditions', {'Tup','ITI'},...
               'OutputActions', NoDecisionAction);

%% StartNewTrial
sma = AddState(sma,...
               'Name', 'StartNewTrial',...
               'Timer', TaskParameters.GUI.StartNewTrialHoldingTime,...
               'StateChangeConditions', {'Tup', 'StartNewTrialTimeOut',...
                                         CenterPortOut, 'WaitSIn'},... %'GlobalTimer2_End', 'NoDecision'!?
               'OutputActions', {CenterLight, 255});

%% StartNewTrialTimeOut
StartNewTrialAction = {};
switch TaskParameters.GUIMeta.StartNewTrialFeedback.String{TaskParameters.GUI.StartNewTrialFeedback}
    case 'None' % no adjustmnet needed
        
    case 'WhiteNoise'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1')
            StartNewTrialAction = {'HiFi1', ['P' 3]};
        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            StartNewTrialAction = {'WavePlayer1', ['P' 3]};
        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No StartNewTrial WhiteNoise will be played.');
        else
            disp('Neither HiFi nor analog module is setup. No StartNewTrial WhiteNoise will be played.');
        end
        
    case 'Beep'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1')
            StartNewTrialAction = {'HiFi1', ['P' 3]};
        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            StartNewTrialAction = {'WavePlayer1', ['P' 3]};
        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No StartNewTrial Beep will be played.');
        else
            disp('Neither HiFi nor analog module is setup. No StartNewTrial Beep will be played.');
        end
        
end
sma = AddState(sma,...
               'Name', 'StartNewTrialTimeOut',...
               'Timer', TaskParameters.GUI.StartNewTrialTimeOut,...
               'StateChangeConditions', {'Tup', 'ITI'},...
               'OutputActions', StartNewTrialAction);

%% SInOpto
SInOpto = {};
if isfield(BpodSystem.ModuleUSB, 'WavePlayer1') % if also WavePlayer -> opto
    SInCh3Train = TaskParameters.GUIMeta.SInCh3Train.String{TaskParameters.GUI.SInCh3Train};
    SInCh3Key = SInCh3Train;
    if ~TrialData.SInCh3Trigger(iTrial)
        SInCh3Key = 'None';
    end
    
    SInCh4Train = TaskParameters.GUIMeta.SInCh4Train.String{TaskParameters.GUI.SInCh4Train};
    SInCh4Key = SInCh4Train;
    if ~TrialData.SInCh4Trigger(iTrial)
        SInCh4Key = 'None';
    end

    SInOpto = {'WavePlayer1', ['P', OptoTable{SInCh3Key, SInCh4Key}]};
end

%% FeedbackDelay
FeedbackDelayLeft = TrialData.FeedbackDelay(iTrial);
FeedbackDelayRight = TrialData.FeedbackDelay(iTrial);
if TaskParameters.GUI.CatchTrial
    if TrialData.Baited(1, iTrial) == 0
        FeedbackDelayLeft = 30; % Catch 2: Unbaited Trial
    end
    
    if TrialData.Baited(2, iTrial) == 0
        FeedbackDelayRight = 30; % Catch 2: Unbaited Trial
    end
    
    if TrialData.LightLeft(iTrial) == 1 % Catch 1: incorrect side Trial
        FeedbackDelayRight = 30; % hard-code?
    elseif  TrialData.LightLeft(iTrial) == 0 % only not lighted side adjusted
        FeedbackDelayLeft = 30;
    end
end

%% StartLIn
%{
dev note: again, this is where SInCh3Train and SInCh4Train should start.
But it is cleaner to do it in the next state
%}
sma = SetGlobalTimer(sma, 3, FeedbackDelayLeft); % used to track side poke grace period

LInStateChange = 'WaterL';
if TrialData.Baited(1, iTrial) == false
    LInStateChange = 'NotBaited';
end
if TrialData.LightLeft(iTrial) == false % Incorrect Choice overwrite Baited 
    LInStateChange = 'IncorrectChoice';
end
sma = AddState(sma,...
               'Name', 'StartLIn',... % dummy state for trigger GlobalTimer3
               'Timer', 0,...
               'StateChangeConditions', {'Tup', 'LIn',...
                                         'GlobalTimer3_End', LInStateChange},...
               'OutputActions',{'GlobalTimerTrig', 3,...
                                LeftLight, LeftLightValue});

%% LIn
LInAction = {LeftLight, LeftLightValue};
LInAction = [LInAction, SInOpto];
sma = AddState(sma,...
               'Name', 'LIn',...
               'Timer', FeedbackDelayLeft,...
               'StateChangeConditions', {'Tup', LInStateChange,...
                                         'GlobalTimer3_End', LInStateChange,...
                                         LeftPortOut,'LInGrace'},...
               'OutputActions', LInAction);

%% LInGrace
sma = AddState(sma,...
               'Name', 'LInGrace',...
               'Timer', TaskParameters.GUI.FeedbackDelayGrace,...
               'StateChangeConditions', {LeftPortIn, 'LIn',...
                                         'Tup', 'SkippedFeedback',...
                                         'GlobalTimer3_End', 'SkippedFeedback',...
                                         CenterPortIn, 'SkippedFeedback',...
                                         RightPortIn, 'SkippedFeedback'},...
               'OutputActions', {LeftLight, LeftLightValue});

%% StartRIn
sma = SetGlobalTimer(sma, 4, FeedbackDelayRight); % used to track side poke grace period

RInStateChange = 'WaterR';
if TrialData.Baited(2, iTrial) == false
    RInStateChange = 'NotBaited';
end
if TrialData.LightLeft(iTrial) == true % Incorrect Choice overwrite Baited 
    RInStateChange = 'IncorrectChoice';
end
sma = AddState(sma,...
               'Name', 'StartRIn',... % dummy state for trigger GlobalTimer3
               'Timer', 0,...
               'StateChangeConditions', {'Tup', 'RIn',...
                                         'GlobalTimer4_End', RInStateChange},...
               'OutputActions',{'GlobalTimerTrig', 4,...
                                 RightLight, RightLightValue});

%% RIn
RInAction = {RightLight, RightLightValue};
RInAction = [RInAction, SInOpto];
sma = AddState(sma,...
               'Name', 'RIn',...
               'Timer', FeedbackDelayRight,...
               'StateChangeConditions', {'Tup', RInStateChange,...
                                         'GlobalTimer4_End', RInStateChange,...
                                         RightPortOut,'RInGrace'},...
               'OutputActions', RInAction);

%% RInGrace
sma = AddState(sma,...
               'Name', 'RInGrace',...
               'Timer', TaskParameters.GUI.FeedbackDelayGrace,...
               'StateChangeConditions', {RightPortIn, 'RIn',...
                                         'Tup', 'SkippedFeedback',...
                                         'GlobalTimer4_End', 'SkippedFeedback',...
                                         CenterPortIn, 'SkippedFeedback',...
                                         LeftPortIn, 'SkippedFeedback'},...
               'OutputActions', {RightLight, RightLightValue});

%% SInOptoEnd (for IncorrectChoice and NotBaited)
SInEndOpto = {};
SInEndOptoWhiteNoise = {};
SInEndOpto500Hz = {};
if isfield(BpodSystem.ModuleUSB, 'WavePlayer1') % if also WavePlayer -> opto
    SInCh3End = TaskParameters.GUIMeta.SInCh3End.String{TaskParameters.GUI.SInCh3End};
    SInCh3EndKey = SInCh3End;
    if strcmpi(SInCh3End, 'Tonic')...
       && ~TaskParameters.GUI.Ch3RepeatedTonicTrigger...
       && strcmpi(SInCh3Train, 'Tonic')
        SInCh3EndKey = 'None';
    end

    SInCh4End = TaskParameters.GUIMeta.SInCh4End.String{TaskParameters.GUI.SInCh4End};
    SInCh4EndKey = SInCh4End;
    if strcmpi(SInCh4End, 'Tonic')...
       && ~TaskParameters.GUI.Ch4RepeatedTonicTrigger...
       && strcmpi(SInCh4Train, 'Tonic')
        SInCh4EndKey = 'None';
    end

    SInEndOpto = {'WavePlayer1', ['P', OptoTable{SInCh3EndKey, SInCh4EndKey}]};
    SInEndOptoWhiteNoise = {'WavePlayer1', ['P', OptoWhiteNoiseTable{SInCh3EndKey, SInCh4EndKey}]};
    SInEndOpto500Hz = {'WavePlayer1', ['P', Opto500HzTable{SInCh3EndKey, SInCh4EndKey}]};
end

%% IncorrectChoice
IncorrectChoiceAction = {};
switch TaskParameters.GUIMeta.IncorrectChoiceFeedback.String{TaskParameters.GUI.IncorrectChoiceFeedback}
    case 'None'
        IncorrectChoiceAction = [IncorrectChoiceAction, SInEndOpto];

    case 'WhiteNoise'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1')
            IncorrectChoiceAction = [IncorrectChoiceAction, {'HiFi1', ['P' 4]}];
            IncorrectChoiceAction = [IncorrectChoiceAction, SInEndOpto];
            
        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            IncorrectChoiceAction = [IncorrectChoiceAction, SInEndOptoWhiteNoise];

        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No IncorrecChoice WhiteNoise will be played.');
        else
            disp('Neither HiFi nor analog module is setup. No IncorrecChoice WhiteNoise will be played.');
        end
        
end
sma = AddState(sma,...
               'Name', 'IncorrectChoice',...
               'Timer', TaskParameters.GUI.IncorrectChoiceTimeOut,...
               'StateChangeConditions', {'Tup', 'ITI'},...
               'OutputActions', IncorrectChoiceAction);

%% NotBaited
NotBaitedAction = {};
switch TaskParameters.GUIMeta.NotBaitedFeedback.String{TaskParameters.GUI.NotBaitedFeedback}
    case 'None'
        NotBaitedAction = [NotBaitedAction, SInEndOpto];
        
    case 'WhiteNoise'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1')
            NotBaitedAction = [NotBaitedAction, {'HiFi1', ['P' 6]}];
            NotBaitedAction = [NotBaitedAction, SInEndOpto];
            
        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            NotBaitedAction = [NotBaitedAction, SInEndOptoWhiteNoise];
        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No NotBaited WhiteNoise will be played.');
        else
            disp('Neither HiFi nor analog module is setup. No NotBaited WhiteNoise will be played.');
        end
        
    case 'Beep'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1')
            NotBaitedAction = [NotBaitedAction, {'HiFi1', ['P' 6]}];
            NotBaitedAction = [NotBaitedAction, SInEndOpto];
            
        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            NotBaitedAction = [NotBaitedAction, SInEndOpto500Hz];

        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No NotBaited Beep will be played.');
        else
            disp('Neither HiFi nor analog module is setup. No NotBaited Beep will be played.');
        end
        
end
sma = AddState(sma,...
               'Name', 'NotBaited',...
               'Timer', TaskParameters.GUI.NotBaitedTimeOut,...
               'StateChangeConditions', {'Tup', 'ITI'},...
               'OutputActions', NotBaitedAction);

%% WaterSOpto
WaterSOpto = {};
if isfield(BpodSystem.ModuleUSB, 'WavePlayer1') % if also WavePlayer -> opto
    WaterSCh3Train = TaskParameters.GUIMeta.WaterSCh3Train.String{TaskParameters.GUI.WaterSCh3Train};
    WaterSCh3Key = WaterSCh3Train;
    if ~TrialData.WaterSCh3Trigger(iTrial)
        WaterSCh3Key = 'None';
    end

    WaterSCh4Train = TaskParameters.GUIMeta.WaterSCh4Train.String{TaskParameters.GUI.WaterSCh4Train};
    WaterSCh4Key = WaterSCh4Train;
    if ~TrialData.WaterSCh4Trigger(iTrial)
        WaterSCh4Key = 'None';
    end

    WaterSOpto = {'WavePlayer1', ['P', OptoTable{WaterSCh3Key, WaterSCh4Key}]};
end

%% WaterL
WaterLAction = {'ValveState', LeftValve};
if (TrialData.WaterSCh3Trigger(iTrial) && TaskParameters.GUI.Ch3RewardReplacement)...
   || (TrialData.WaterSCh4Trigger(iTrial) && TaskParameters.GUI.Ch4RewardReplacement)
    WaterLAction = WaterSOpto;
else
    WaterLAction = [WaterLAction, WaterSOpto];
end
sma = AddState(sma,...
               'Name', 'WaterL',...
               'Timer', LeftValveTime,...
               'StateChangeConditions', {'Tup', 'Drinking'},...
               'OutputActions', WaterLAction);

%% WaterR
WaterRAction = {'ValveState', RightValve};
if (TrialData.WaterSCh3Trigger(iTrial) && TaskParameters.GUI.Ch3RewardReplacement)...
   || (TrialData.WaterSCh4Trigger(iTrial) && TaskParameters.GUI.Ch4RewardReplacement)
    WaterRAction = WaterSOpto;
else
    WaterRAction = [WaterRAction, WaterSOpto];
end
sma = AddState(sma,...
               'Name', 'WaterR',...
               'Timer', RightValveTime,...
               'StateChangeConditions', {'Tup', 'Drinking'},...
               'OutputActions', WaterRAction);

%% Drinking
DrinkingAction = {};
if isfield(BpodSystem.ModuleUSB, 'WavePlayer1') % if also WavePlayer -> opto
    WaterSCh3End = TaskParameters.GUIMeta.WaterSCh3End.String{TaskParameters.GUI.WaterSCh3End};
    WaterSCh3EndKey = WaterSCh3End;
    if strcmpi(WaterSCh3End, 'Tonic')...
       && ~TaskParameters.GUI.Ch3RepeatedTonicTrigger...
       && strcmpi(WaterSCh3Train, 'Tonic')
        WaterSCh3EndKey = 'None';
    end

    WaterSCh4End = TaskParameters.GUIMeta.WaterSCh4End.String{TaskParameters.GUI.WaterSCh4End};
    WaterSCh4EndKey = WaterSCh4End;
    if strcmpi(WaterSCh4End, 'Tonic')...
       && ~TaskParameters.GUI.Ch4RepeatedTonicTrigger...
       && strcmpi(WaterSCh4Train, 'Tonic')
        WaterSCh4EndKey = 'None';
    end

    DrinkingAction = {'WavePlayer1', ['P', OptoTable{WaterSCh3EndKey, WaterSCh4EndKey}]};
end
sma = AddState(sma,...
               'Name', 'Drinking',... % serve as time buffer before next trial start
               'Timer', 0,...
               'StateChangeConditions', {LeftPortOut, 'DrinkingGrace',...
                                         RightPortOut, 'DrinkingGrace'},...
               'OutputActions', DrinkingAction);

%% DrinkingGrace
DrinkingGraceTimer = TaskParameters.GUI.DrinkingGraceTime;
sma = AddState(sma,...
               'Name', 'DrinkingGrace',... % serve as time buffer before next trial start
               'Timer', DrinkingGraceTimer,...
               'StateChangeConditions', {LeftPortIn, 'Drinking',...
                                         RightPortIn, 'Drinking',...
                                         'Tup', 'ITI'},...
               'OutputActions', {});

%% SkippedFeedback
SkippedFeedbackAction  = {};
if isfield(BpodSystem.ModuleUSB, 'WavePlayer1') % if also WavePlayer -> opto
    SkippedFeedbackCh3Train = TaskParameters.GUIMeta.SkippedFeedbackCh3Train.String{TaskParameters.GUI.SkippedFeedbackCh3Train};
    SkippedFeedbackCh3Key = SkippedFeedbackCh3Train;
    if ~TrialData.SkippedFeedbackCh3Trigger(iTrial)
        SkippedFeedbackCh3Key = 'None';
    end

    SkippedFeedbackCh4Train = TaskParameters.GUIMeta.SkippedFeedbackCh4Train.String{TaskParameters.GUI.SkippedFeedbackCh4Train};
    SkippedFeedbackCh4Key = SkippedFeedbackCh4Train;
    if ~TrialData.SkippedFeedbackCh4Trigger(iTrial)
        SkippedFeedbackCh4Key = 'None';
    end
    
end
switch TaskParameters.GUIMeta.SkippedFeedbackFeedback.String{TaskParameters.GUI.SkippedFeedbackFeedback}
    case 'None'
        SkippedFeedbackAction = [SkippedFeedbackAction, {'WavePlayer1', ['P', OptoTable{SkippedFeedbackCh3Key, SkippedFeedbackCh4Key}]}];

    case 'WhiteNoise'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1')
            SkippedFeedbackAction = {'HiFi1', ['P' 5]};
            SkippedFeedbackAction = [SkippedFeedbackAction, {'WavePlayer1', ['P', OptoTable{SkippedFeedbackCh3Key, SkippedFeedbackCh4Key}]}];

        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            SkippedFeedbackAction = [SkippedFeedbackAction, {'WavePlayer1', ['P', OptoWhiteNoiseTable{SkippedFeedbackCh3Key, SkippedFeedbackCh4Key}]}];
        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No SkippedFeedback WhiteNoise will be played.');
        else
            disp('Neither HiFi nor analog module is setup. No SkippedFeedback WhiteNoise will be played.');
        end
        
    case 'Beep'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1')
            SkippedFeedbackAction = {'HiFi1', ['P' 5]};
            SkippedFeedbackAction = [SkippedFeedbackAction, {'WavePlayer1', ['P', OptoTable{SkippedFeedbackCh3Key, SkippedFeedbackCh4Key}]}];
            
        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            SkippedFeedbackAction = [SkippedFeedbackAction, {'WavePlayer1', ['P', Opto1kHzTable{SkippedFeedbackCh3Key, SkippedFeedbackCh4Key}]}];
        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No SkippedFeedback Beep will be played.');
        else
            disp('Neither a HiFi nor analog module is setup. No SkippedFeedback Beep will be played.');
        end
        
end
sma = AddState(sma,...
               'Name', 'SkippedFeedback',...
               'Timer', TaskParameters.GUI.SkippedFeedbackTimeOut,...
               'StateChangeConditions', {'Tup', 'EndSkippedFeedback'},...
               'OutputActions', SkippedFeedbackAction);

%% EndSkippedFeedback
% dummy state for SkippedFeedbackCh3End/Ch4End
%{
SkippedFeedback CANNOT followed by ITI or it SkippedFeedbackCh3End/Ch4End will directly change ITI
(and thus the EventXCh3End will not be carried over)
%}
EndSkippedFeedbackAction = {};
if isfield(BpodSystem.ModuleUSB, 'WavePlayer1') % if also WavePlayer -> opto
    SkippedFeedbackCh3End = TaskParameters.GUIMeta.SkippedFeedbackCh3End.String{TaskParameters.GUI.SkippedFeedbackCh3End};
    SkippedFeedbackCh3EndKey = SkippedFeedbackCh3End;
    if strcmpi(SkippedFeedbackCh3End, 'Tonic')...
       && ~TaskParameters.GUI.Ch3RepeatedTonicTrigger...
       && strcmpi(SkippedFeedbackCh3Train, 'Tonic')
        SkippedFeedbackCh3EndKey = 'None';
    end

    SkippedFeedbackCh4End = TaskParameters.GUIMeta.SkippedFeedbackCh4End.String{TaskParameters.GUI.SkippedFeedbackCh4End};
    SkippedFeedbackCh4EndKey = SkippedFeedbackCh4End;
    if strcmpi(SkippedFeedbackCh4End, 'Tonic')...
       && ~TaskParameters.GUI.Ch4RepeatedTonicTrigger...
       && strcmpi(SkippedFeedbackCh4Train, 'Tonic')
        SkippedFeedbackCh4EndKey = 'None';
    end

    EndSkippedFeedbackAction = {'WavePlayer1', ['P', OptoTable{SkippedFeedbackCh3EndKey, SkippedFeedbackCh4EndKey}]};
end
sma = AddState(sma,...
               'Name', 'EndSkippedFeedback',...
               'Timer', 0,...
               'StateChangeConditions', {'Tup', 'ITI'},...
               'OutputActions', EndSkippedFeedbackAction);

%% ITI
ITITimer = TaskParameters.GUI.ITI;
if TaskParameters.GUI.VI
    ITITimer = min([exprnd(TaskParameters.GUI.ITI), TaskParameters.GUI.ITI * 5]); % exp(-5) = 0.0067
end
switch TaskParameters.GUIMeta.RiskType.String{TaskParameters.GUI.RiskType}
    case 'CuedBlockITI'
        if mod(TrialData.BlockNumber(iTrial), 2) == 0 % longer ITI
            ITITimer = TaskParameters.GUI.ITI * 1.5;
        end
end
sma = AddState(sma,...
               'Name', 'ITI',...
               'Timer', ITITimer,...
               'StateChangeConditions',{'Tup', 'exit'},...
               'OutputActions',{});

end % StateMatrix
function TaskParameters = TwoArmBanditVariant_SetupGUI()

global BpodSystem

%% Task parameters
TaskParameters = BpodSystem.ProtocolSettings;

if isempty(fieldnames(TaskParameters))
    %% general
    TaskParameters.GUI.SessionDescription = 'First risk task'; % free space to document setting purposes
    TaskParameters.GUIMeta.SessionDescription.Style = 'edittext';
    
    TaskParameters.GUI.Ports_LMR = '123'; % bpod port number for poke connection
    TaskParameters.GUI.EphysSession = false;
    TaskParameters.GUIMeta.EphysSession.Style = 'checkbox';
    TaskParameters.GUI.Wire1VideoTrigger = 1;
    TaskParameters.GUIMeta.Wire1VideoTrigger.Style = 'popupmenu';
    TaskParameters.GUIMeta.Wire1VideoTrigger.String = {'None', 'Investment', 'All'};

    TaskParameters.GUI.PreITI = 0.5; % before wait_Cin
    TaskParameters.GUI.WaitCInMax = 20; % max waiting time for C_in before a new trial starts, useful to track progress
    
    TaskParameters.GUI.ChoiceDeadline = 10; % max waiting time for S_in after stimuli
    TaskParameters.GUI.NoDecisionTimeOut = 1; % (s) where subject chooses the side poke without light
    TaskParameters.GUI.NoDecisionFeedback = 1; % feedback for NoDecision
    TaskParameters.GUIMeta.NoDecisionFeedback.Style = 'popupmenu';
    TaskParameters.GUIMeta.NoDecisionFeedback.String = {'None', 'WhiteNoise'};
    
    TaskParameters.GUI.SingleSidePoke = false;
    TaskParameters.GUIMeta.SingleSidePoke.Style = 'checkbox'; % old light-guided
    TaskParameters.GUI.IncorrectChoiceTimeOut = 1; % (s), for single-side poke settings only, where subject chooses the side poke without light
    TaskParameters.GUI.IncorrectChoiceFeedback = 1; % feedback for IncorrectChoice
    TaskParameters.GUIMeta.IncorrectChoiceFeedback.Style = 'popupmenu';
    TaskParameters.GUIMeta.IncorrectChoiceFeedback.String = {'None', 'WhiteNoise'};
  
    TaskParameters.GUI.StartNewTrialEnable = false; % check if starting a new trial by C_in after stimulus
    TaskParameters.GUIMeta.StartNewTrialEnable.Style = 'checkbox';
    TaskParameters.GUI.StartNewTrialHoldingTime = 0.35; % time required to trigger starting a new trial
    TaskParameters.GUI.StartNewTrialFeedback = 1; % feedback for successful StartNewTrial
    TaskParameters.GUIMeta.StartNewTrialFeedback.Style = 'popupmenu';
    TaskParameters.GUIMeta.StartNewTrialFeedback.String = {'None', 'WhiteNoise', 'Beep'};
    TaskParameters.GUI.StartNewTrialTimeOut = 3; % (s), for the case where subject starts a new trial by choosing the centre poke after stimulus
    %{it may need an extra GracePeriod for the decision of starting a new task}
    
    TaskParameters.GUI.ITI = 3; % end of trial ITI
    TaskParameters.GUI.VI = false; % exprnd based on ITI
    TaskParameters.GUIMeta.VI.Style = 'checkbox';
    
    TaskParameters.GUIPanels.General = {'SessionDescription', 'Ports_LMR', 'EphysSession',...
                                        'Wire1VideoTrigger',...
                                        'PreITI', 'WaitCInMax', 'ChoiceDeadline',...
                                        'NoDecisionTimeOut', 'NoDecisionFeedback',...
                                        'SingleSidePoke',...
                                        'IncorrectChoiceTimeOut', 'IncorrectChoiceFeedback',...
                                        'StartNewTrialEnable', 'StartNewTrialHoldingTime',...
                                        'StartNewTrialFeedback', 'StartNewTrialTimeOut',...
                                        'ITI', 'VI'};
    
    %% StimDelay
    TaskParameters.GUI.StimDelayMin = 0; % lower boundary for autoincrementing stimulus delay time, for all
    TaskParameters.GUI.StimDelayMax = 0; % upper boundary for autoincrementing stimulus delay time
    
    TaskParameters.GUI.StimDelay = TaskParameters.GUI.StimDelayMin; % current stimulus delay time
    TaskParameters.GUIMeta.StimDelay.Style = 'text';
    
    TaskParameters.GUI.StimDelayDistribution = 1;
    TaskParameters.GUIMeta.StimDelayDistribution.Style = 'popupmenu';
    TaskParameters.GUIMeta.StimDelayDistribution.String = {'Fix', 'AutoIncr', 'TruncExp', 'Uniform', 'Beta'};
    %{
    Fix = fix time
    AutoIncr = incremental along session
    TruncExp = random drawn within a range with prob distribution based on TrucExp
    Beta = like TruncExp, but with beta distribution
    %}
    
    TaskParameters.GUI.StimDelayIncrStepSize = 0.01; % step size for autoincrementing stimulus delay time, for AutoIncr only
    TaskParameters.GUI.StimDelayDecrStepSize = 0.01;
    TaskParameters.GUI.StimDelayTau = 0.05; % step size for StimDelay, only for TruncExp
    TaskParameters.GUI.StimDelayAlpha = 0.05; % step size for StimDelay, only for Beta
    TaskParameters.GUI.StimDelayBeta = 0.05; % step size for StimDelay, only for Beta
    
    TaskParameters.GUI.BrokeFixationTimeOut = 2; % (s), penalty for C_out before stimulus starts
    TaskParameters.GUI.BrokeFixationFeedback = 1; % feedback for BrokeFixation
    TaskParameters.GUIMeta.BrokeFixationFeedback.Style = 'popupmenu';
    TaskParameters.GUIMeta.BrokeFixationFeedback.String = {'None', 'WhiteNoise'};
    
    TaskParameters.GUI.RenewBrokeFixation = false; % if true, BrokeFixation state transits to WaitCIn instead of ITI
    TaskParameters.GUIMeta.RenewBrokeFixation.Style = 'checkbox';

    TaskParameters.GUI.StimulusTime = 0.35; % legnth of stimulus reception, also how long the animal is required to sample (to avoid random decision)
    
    TaskParameters.GUI.SamplingGrace = 0; % allowance for brief C_out and then C_in, for flickering action/device
    TaskParameters.GUI.EarlyWithdrawalTimeOut = 1; % penalty for C_out before stimulus delivery ends
    TaskParameters.GUI.EarlyWithdrawalFeedback = 1; % feedback for EarlyWithdrawal
    TaskParameters.GUIMeta.EarlyWithdrawalFeedback.Style = 'popupmenu';
    TaskParameters.GUIMeta.EarlyWithdrawalFeedback.String = {'None', 'WhiteNoise'};
    
    TaskParameters.GUI.RenewEarlyWithdrawal = false; % if true, EarlyWithdrawal state transits to WaitCIn instead of ITI
    TaskParameters.GUIMeta.RenewEarlyWithdrawal.Style = 'checkbox';
    
    TaskParameters.GUIPanels.Sampling = {'StimDelay', 'StimDelayDistribution',...
                                         'StimDelayMin', 'StimDelayMax',...
                                         'StimDelayIncrStepSize', 'StimDelayDecrStepSize',...
                                         'StimDelayTau', 'StimDelayAlpha', 'StimDelayBeta',...
                                         'BrokeFixationTimeOut', 'BrokeFixationFeedback',...
                                         'RenewBrokeFixation',...
                                         'StimulusTime', 'SamplingGrace',...
                                         'EarlyWithdrawalTimeOut', 'EarlyWithdrawalFeedback',...
                                         'RenewEarlyWithdrawal'};
                                     
    %% FeedbackDelay, original named "Side Ports" ("waiting for feedback(either reward or punishment)")
    TaskParameters.GUI.FeedbackDelayDistribution = 1;
    TaskParameters.GUIMeta.FeedbackDelayDistribution.Style = 'popupmenu';
    TaskParameters.GUIMeta.FeedbackDelayDistribution.String = {'Fix', 'AutoIncr', 'TruncExp', 'Beta'};
    %{
    Fix = fix time
    AutoIncr = incremental along session
    TruncExp = random drawn within a range with prob distribution based on TrucExp
    Beta = like TruncExp, but with beta distribution
    %}

    TaskParameters.GUI.FeedbackDelayMin = 0; % lower boundary for FeedbackDelay; after (i+1)th value is created, it is used to bound the value
    TaskParameters.GUI.FeedbackDelayMax = 0; % upper boundary for FeedbackDelay
    
    TaskParameters.GUI.FeedbackDelayIncrStepSize = 0.01; % step size for FeedbackDelay, only for AutoIncr
    TaskParameters.GUI.FeedbackDelayDecrStepSize = 0.01; % step size for FeedbackDelay, only for AutoIncr
    TaskParameters.GUI.FeedbackDelayTau = 0.05; % step size for FeedbackDelay, only for TruncExp
    TaskParameters.GUI.FeedbackDelayAlpha = 0.05; % step size for FeedbackDelay, only for Beta
    TaskParameters.GUI.FeedbackDelayBeta = 0.05; % step size for FeedbackDelay, only for Beta
    
    TaskParameters.GUI.FeedbackDelay = TaskParameters.GUI.FeedbackDelayMin; % current FeedbackDelay
    TaskParameters.GUIMeta.FeedbackDelay.Style = 'text';
    TaskParameters.GUI.FeedbackDelayGrace = 0; 
    
    TaskParameters.GUI.SkippedFeedbackTimeOut = 0;
    TaskParameters.GUI.SkippedFeedbackFeedback = 1; % feedback for SkippedFeedback
    TaskParameters.GUIMeta.SkippedFeedbackFeedback.Style = 'popupmenu';
    TaskParameters.GUIMeta.SkippedFeedbackFeedback.String = {'None', 'WhiteNoise', 'Beep'};
    
    TaskParameters.GUI.CatchTrial = false; % Is the (incorrect/unbaited) trial caught for time investment?
    TaskParameters.GUIMeta.CatchTrial.Style = 'checkbox';
    
    TaskParameters.GUI.NotBaitedTimeOut = 0.10;
    TaskParameters.GUI.NotBaitedFeedback = 1; % feedback for SkippedFeedback
    TaskParameters.GUIMeta.NotBaitedFeedback.Style = 'popupmenu';
    TaskParameters.GUIMeta.NotBaitedFeedback.String = {'None', 'WhiteNoise', 'Beep'};
    
    TaskParameters.GUI.DrinkingGraceTime = 0.5;
    
    TaskParameters.GUIPanels.FeedbackDelay = {'FeedbackDelayDistribution',...
                                              'FeedbackDelayMin', 'FeedbackDelayMax',...
                                              'FeedbackDelayIncrStepSize', 'FeedbackDelayDecrStepSize',...
                                              'FeedbackDelayTau', 'FeedbackDelayAlpha', 'FeedbackDelayBeta',...
                                              'FeedbackDelay', 'FeedbackDelayGrace',...
                                              'SkippedFeedbackTimeOut', 'SkippedFeedbackFeedback',...
                                              'CatchTrial', 'NotBaitedTimeOut', 'NotBaitedFeedback',...
                                              'DrinkingGraceTime'};
                                      
    %% Reward and RewardProb
    TaskParameters.GUI.RewardAmount = 30; % (ul), baseline value for reward (adjusted by ExpressedAsExpectedValue)
    TaskParameters.GUI.OUReward = false; % new in 20250617
    TaskParameters.GUIMeta.OUReward.Style = 'checkbox';
    TaskParameters.GUI.ExpressedAsExpectedValue = false; %
    TaskParameters.GUIMeta.ExpressedAsExpectedValue.Style = 'checkbox'; % if true, reward probability = 1 while reward amount discounted by the set probability
    
    TaskParameters.GUI.RiskType = 1;
    TaskParameters.GUIMeta.RiskType.Style = 'popupmenu';
    TaskParameters.GUIMeta.RiskType.String = {'Fix', 'BlockRand', 'BlockFix', 'BlockFixHolding',...
                                              'Cued', 'BlockCued', 'CuedBlockRatio', 'CuedBlockITI',...
                                              'CuedBlockTau', 'BlockRandHolding'};
    %{
    decide how reward probability is expressed:
    Fix, based on RewardProbLeft value to express fix RewardProb
    BlockRand, randomly draw a value between Min and Max and assign
    BlockFix, based on Max and Min and reverse L-R value
    Cue, cued by Tone
    %}
    
    TaskParameters.GUI.RewardProbLeft = 0.5; % Reward Probability of Left Poke, only for Fix in RiskType
    TaskParameters.GUI.RewardProbRight = 0.5; % Reward Probability of Left Poke, only for Fix in RiskType
    
    TaskParameters.GUI.BlockLenMin = 100; % lower boundart of BlockLen, only for Block in RiskType
    TaskParameters.GUI.BlockLenMax = 150; % upper boundart of BlockLen, only for Block in RiskType
    TaskParameters.GUI.BlockLen = TaskParameters.GUI.BlockLenMin; % draw from the range confined as above, uniform distribution
    TaskParameters.GUIMeta.BlockLen.Style = 'text';
    TaskParameters.GUI.NextBlockTrialNumber = TaskParameters.GUI.BlockLen; % the trial, where the next block starts
    TaskParameters.GUIMeta.NextBlockTrialNumber.Style = 'text';
    
    TaskParameters.GUI.RewardProbMax = 1; % upper boundary of reward probability, only for Block in RiskType
    TaskParameters.GUI.RewardProbMin = 0.4; % lower boundary of reward probability, only for Block in RiskType
      
    TaskParameters.GUI.ToneRiskTable.ToneStartFreq = [2 5 10 20]'; % (kHz), only for Cue in RiskType
    TaskParameters.GUI.ToneRiskTable.ToneEndFreq = [2 5 10 20]'; % (kHz), features for sweep, only for Cue in RiskType
    TaskParameters.GUI.ToneRiskTable.ToneCuedRewardProbability = [0.5, 0.6, 0.7, 0.8]'; % reward probability of corresponding tone, only for Cue in RiskType
    TaskParameters.GUIMeta.ToneRiskTable.Style = 'table';
    TaskParameters.GUIMeta.ToneRiskTable.String = 'Tone cued reward probability';
    TaskParameters.GUIMeta.ToneRiskTable.ColumnLabel = {'StartFreq', 'EndFreq', 'RewardProb'};

    TaskParameters.GUI.RewardProbActualLeft = TaskParameters.GUI.RewardProbLeft; % Reward Probability of Left Poke, for all RiskType
    TaskParameters.GUIMeta.RewardProbActualLeft.Style = 'text';
    TaskParameters.GUI.RewardProbActualRight = TaskParameters.GUI.RewardProbRight; % Reward Probability of Right Poke, for all RiskType
    TaskParameters.GUIMeta.RewardProbActualRight.Style = 'text';
  
    TaskParameters.GUIPanels.Reward = {'ToneRiskTable','RewardAmount', 'OUReward', 'ExpressedAsExpectedValue','RiskType',...
                                       'RewardProbLeft','RewardProbRight','BlockLenMin',...
                                       'BlockLenMax','BlockLen','NextBlockTrialNumber',...
                                       'RewardProbMax','RewardProbMin',...
                                       'RewardProbActualLeft','RewardProbActualRight',};
    
    %% Photometry
    %photometry general
    TaskParameters.GUI.Photometry = 0;
    TaskParameters.GUIMeta.Photometry.Style = 'checkbox';
    
    TaskParameters.GUI.DbleFibers = 0;
    TaskParameters.GUIMeta.DbleFibers.Style = 'checkbox';
    TaskParameters.GUIMeta.DbleFibers.String = 'Auto';
    
    TaskParameters.GUI.Isobestic405 = 0;
    TaskParameters.GUIMeta.Isobestic405.Style = 'checkbox';
    TaskParameters.GUIMeta.Isobestic405.String = 'Auto';
    
    TaskParameters.GUI.RedChannel = 1;
    TaskParameters.GUIMeta.RedChannel.Style = 'checkbox';
    TaskParameters.GUIMeta.RedChannel.String = 'Auto';
    
    TaskParameters.GUIPanels.PhotometryRecording = {'Photometry', 'DbleFibers', 'Isobestic405', 'RedChannel'};
    
    %% plot photometry
    TaskParameters.GUI.TimeMin = -1;
    TaskParameters.GUI.TimeMax = 15;
    TaskParameters.GUI.NidaqMin = -5;
    TaskParameters.GUI.NidaqMax = 10;
    TaskParameters.GUI.SidePokeIn = 1;
	TaskParameters.GUIMeta.SidePokeIn.Style = 'checkbox';
    
    TaskParameters.GUI.SidePokeLeave = 1;
	TaskParameters.GUIMeta.SidePokeLeave.Style = 'checkbox';
    
    TaskParameters.GUI.RewardDelivery = 1;
	TaskParameters.GUIMeta.RewardDelivery.Style = 'checkbox';
    
    TaskParameters.GUI.BaselineBegin = 0.5;
    TaskParameters.GUI.BaselineEnd = 1.8;
    TaskParameters.GUIPanels.PhotometryPlot = {'TimeMin', 'TimeMax', 'NidaqMin', 'NidaqMax',...
                                               'SidePokeIn', 'SidePokeLeave', 'RewardDelivery',...
                                               'BaselineBegin', 'BaselineEnd'};
    
    %% Nidaq and Photometry
    TaskParameters.GUI.PhotometryVersion = 1;
    TaskParameters.GUI.Modulation = 1;
    TaskParameters.GUIMeta.Modulation.Style = 'checkbox';
    TaskParameters.GUIMeta.Modulation.String = 'Auto';
    
	TaskParameters.GUI.NidaqDuration = 4;
    TaskParameters.GUI.NidaqSamplingRate = 6100;
    TaskParameters.GUI.DecimateFactor = 610;
    
    TaskParameters.GUI.LED1_Name = 'Fiber1 470-A1';
    TaskParameters.GUIMeta.LED1_Name.Style = 'edittext';
    TaskParameters.GUI.LED1_Amp = 1;
    TaskParameters.GUI.LED1_Freq = 211;
    
    TaskParameters.GUI.LED2_Name = 'Fiber1 405 / 565';
    TaskParameters.GUIMeta.LED2_Name.Style = 'edittext';
    TaskParameters.GUI.LED2_Amp = 5;
    TaskParameters.GUI.LED2_Freq = 531;
    
    TaskParameters.GUI.LED1b_Name = 'Fiber2 470-mPFC';
    TaskParameters.GUIMeta.LED1b_Name.Style = 'edittext';
    TaskParameters.GUI.LED1b_Amp = 2;
    TaskParameters.GUI.LED1b_Freq = 531;

    TaskParameters.GUIPanels.PhotometryNidaq = {'PhotometryVersion', 'Modulation', 'NidaqDuration',...
                                                'NidaqSamplingRate', 'DecimateFactor',...
                                                'LED1_Name', 'LED1_Amp', 'LED1_Freq',...
                                                'LED2_Name', 'LED2_Amp', 'LED2_Freq',...
                                                'LED1b_Name', 'LED1b_Amp', 'LED1b_Freq'};
    
    %% rig-specific
    TaskParameters.GUI.nidaqDev = 'Dev2';
    TaskParameters.GUIMeta.nidaqDev.Style = 'edittext';

    TaskParameters.GUIPanels.PhotometryRig = {'nidaqDev'};
    
    %% Optogenetics
    % AOM Ch3 train <- usually reserved for blue light
    TaskParameters.GUI.Ch3Looped = 0; % need to set AOM master setting <- useful for non-stop tonic stimulation, or any playback > 20s x 50kHz
	TaskParameters.GUIMeta.Ch3Looped.Style = 'checkbox';
    
    TaskParameters.GUI.Ch3StopBlock = 1;
    TaskParameters.GUIMeta.Ch3StopBlock.Style = 'popupmenu';
    TaskParameters.GUIMeta.Ch3StopBlock.String = {'NoBlock', 'ToRiskBlock', 'NotToRiskBlock'};
    TaskParameters.GUI.Ch3StopBlockRangeMin = 0;
    TaskParameters.GUI.Ch3StopBlockRangeMax = 0;
    %{
    NoBlock: ignore BlockRange, only base on trigger percentage
    ToRiskBlock: Relative to the Block structure of task, -1 = 1st block
    before block change, +1 = 1st block after block change
    NotToRiskBlock: separate block structure than the task block
    %}

    TaskParameters.GUI.Ch3RepeatedTonicTrigger = 0; % if a tonic is playing, 0 = no trigger is made upon another tonic
	TaskParameters.GUIMeta.Ch3RepeatedTonicTrigger.Style = 'checkbox';

    TaskParameters.GUI.Ch3TonicPoisson = 0; % typically not compatible with Uninterrupted cos that statistics is not accurately Poisson
	TaskParameters.GUIMeta.Ch3TonicPoisson.Style = 'checkbox';
    
    TaskParameters.GUI.Ch3TonicVoltage = 0;
    TaskParameters.GUI.Ch3TonicTrainFreq = 5; % in Hz
    TaskParameters.GUI.Ch3TonicPulseNumber = 20; % in second
    TaskParameters.GUI.Ch3TonicPulseWidth = 0.010; % in second
    
    TaskParameters.GUI.Ch3TonicBlock = 1;
    TaskParameters.GUIMeta.Ch3TonicBlock.Style = 'popupmenu';
    TaskParameters.GUIMeta.Ch3TonicBlock.String = {'NoBlock', 'ToRiskBlock', 'NotToRiskBlock'};
    TaskParameters.GUI.Ch3TonicBlockRangeMin = 0;
    TaskParameters.GUI.Ch3TonicBlockRangeMax = 0;
    %{
    NoBlock: ignore BlockRange, only base on trigger percentage
    ToRiskBlock: Relative to the Block structure of task, -1 = 1st block
    before block change, +1 = 1st block after block change
    NotToRiskBlock: separate block structure than the task block
    %}

    TaskParameters.GUI.Ch3PhasicVoltage = 0;
    TaskParameters.GUI.Ch3PhasicTrainFreq = 30; % in Hz
    TaskParameters.GUI.Ch3PhasicPulseNumber = 15; % in second
    TaskParameters.GUI.Ch3PhasicPulseWidth = 0.010; % in second
    
    TaskParameters.GUI.Ch3PhasicBlock = 1;
    TaskParameters.GUIMeta.Ch3PhasicBlock.Style = 'popupmenu';
    TaskParameters.GUIMeta.Ch3PhasicBlock.String = {'NoBlock', 'ToRiskBlock', 'NotToRiskBlock'};
    TaskParameters.GUI.Ch3PhasicBlockRangeMin = 0;
    TaskParameters.GUI.Ch3PhasicBlockRangeMax = 0;
    %{
    NoBlock: ignore BlockRange, only base on trigger percentage
    ToRiskBlock: Relative to the Block structure of task, -1 = 1st block
    before block change, +1 = 1st block after block change
    NotToRiskBlock: separate block structure than the task block
    %}

    TaskParameters.GUIPanels.AOMCh3Train = {'Ch3Looped', 'Ch3StopBlock', 'Ch3StopBlockRangeMin', 'Ch3StopBlockRangeMax',...
                                            'Ch3RepeatedTonicTrigger', 'Ch3TonicPoisson',...
                                            'Ch3TonicVoltage', 'Ch3TonicTrainFreq', 'Ch3TonicPulseNumber', 'Ch3TonicPulseWidth',...
                                            'Ch3TonicBlock', 'Ch3TonicBlockRangeMin', 'Ch3TonicBlockRangeMax',...
                                            'Ch3PhasicVoltage', 'Ch3PhasicTrainFreq', 'Ch3PhasicPulseNumber', 'Ch3PhasicPulseWidth',...
                                            'Ch3PhasicBlock', 'Ch3PhasicBlockRangeMin', 'Ch3PhasicBlockRangeMax'};

    %% AOM Ch3 Trigger
    TaskParameters.GUI.WaitCInCh3Percentage = 0; % either play something or ignore, i.e. 'None'
    TaskParameters.GUI.WaitCInCh3Train = 1; % usually for non-stop continuous tonic stimulation
    TaskParameters.GUIMeta.WaitCInCh3Train.Style = 'popupmenu';
    TaskParameters.GUIMeta.WaitCInCh3Train.String = {'Stop', 'Tonic', 'Phasic'};
    TaskParameters.GUI.WaitCInCh3End = 2; % next state ('NoTrialStart') hard stop playback (not for StartCIN will anyway trigger something)
	TaskParameters.GUIMeta.WaitCInCh3End.Style = 'popupmenu';
    TaskParameters.GUIMeta.WaitCInCh3End.String = {'None', 'Stop', 'Tonic'};
    
    TaskParameters.GUI.CInCh3Percentage = 0;
    TaskParameters.GUI.CInCh3Train = 1; % usually for tonic
    TaskParameters.GUIMeta.CInCh3Train.Style = 'popupmenu';
    TaskParameters.GUIMeta.CInCh3Train.String = {'Stop', 'Tonic', 'Phasic'};
    TaskParameters.GUI.CInCh3End = 2; % next state ('EW', 'BF', 'ND', or 'WaitSIn') hard stop playback <- always all needs a stop
	TaskParameters.GUIMeta.CInCh3End.Style = 'popupmenu';
    TaskParameters.GUIMeta.CInCh3End.String = {'None', 'Stop', 'Tonic'};
    
    TaskParameters.GUI.SInCh3Percentage = 0;
    TaskParameters.GUI.SInCh3Train = 1;
    TaskParameters.GUIMeta.SInCh3Train.Style = 'popupmenu';
    TaskParameters.GUIMeta.SInCh3Train.String = {'Stop', 'Tonic', 'Phasic'};
    TaskParameters.GUI.SInCh3End = 2; % next state ('IncorrectChoice' or 'NotBaited') hard stop playback (not for WaterS nor SkippedFeedback cos they have their own trigger)
	TaskParameters.GUIMeta.SInCh3End.Style = 'popupmenu';
    TaskParameters.GUIMeta.SInCh3End.String = {'None', 'Stop', 'Tonic'};
    
    TaskParameters.GUI.WaterSCh3Percentage = 0;
    TaskParameters.GUI.Ch3RewardReplacement = 0;
    TaskParameters.GUIMeta.Ch3RewardReplacement.Style = 'checkbox';
    TaskParameters.GUI.WaterSCh3Train = 1; % usually for phasic
    TaskParameters.GUIMeta.WaterSCh3Train.Style = 'popupmenu';
    TaskParameters.GUIMeta.WaterSCh3Train.String = {'Stop', 'Tonic', 'Phasic'};
    TaskParameters.GUI.WaterSCh3End = 2; % next state ('Drinking') hard stop playback
	TaskParameters.GUIMeta.WaterSCh3End.Style = 'popupmenu';
    TaskParameters.GUIMeta.WaterSCh3End.String = {'None', 'Stop', 'Tonic'};

    TaskParameters.GUI.SkippedFeedbackCh3Percentage = 0;
    TaskParameters.GUI.SkippedFeedbackCh3Train = 1; % usually for phasic
    TaskParameters.GUIMeta.SkippedFeedbackCh3Train.Style = 'popupmenu';
    TaskParameters.GUIMeta.SkippedFeedbackCh3Train.String = {'Stop', 'Tonic', 'Phasic'};
    TaskParameters.GUI.SkippedFeedbackCh3End = 2; % next state ('ITI') hard stop playback <- usually longer than SB-TimeOut
	TaskParameters.GUIMeta.SkippedFeedbackCh3End.Style = 'popupmenu';
    TaskParameters.GUIMeta.SkippedFeedbackCh3End.String = {'None', 'Stop', 'Tonic'};

    TaskParameters.GUIPanels.AOMCh3Trigger = {'WaitCInCh3Percentage', 'WaitCInCh3Train', 'WaitCInCh3End',...
                                              'CInCh3Percentage', 'CInCh3Train', 'CInCh3End',...
                                              'SInCh3Percentage', 'SInCh3Train', 'SInCh3End',...
                                              'WaterSCh3Percentage', 'Ch3RewardReplacement', 'WaterSCh3Train', 'WaterSCh3End',...
                                              'SkippedFeedbackCh3Percentage', 'SkippedFeedbackCh3Train', 'SkippedFeedbackCh3End'};

    %% AOM Ch4 train <- usually reserved for red light
    TaskParameters.GUI.Ch4Looped = 0; % need to set AOM master setting <- useful for non-stop tonic stimulation, or any playback > 20s x 50kHz
	TaskParameters.GUIMeta.Ch4Looped.Style = 'checkbox';
    
    TaskParameters.GUI.Ch4StopBlock = 1;
    TaskParameters.GUIMeta.Ch4StopBlock.Style = 'popupmenu';
    TaskParameters.GUIMeta.Ch4StopBlock.String = {'NoBlock', 'ToRiskBlock', 'NotToRiskBlock'};
    TaskParameters.GUI.Ch4StopBlockRangeMin = 0;
    TaskParameters.GUI.Ch4StopBlockRangeMax = 0;
    %{
    NoBlock: ignore BlockRange, only base on trigger percentage
    ToRiskBlock: Relative to the Block structure of task, -1 = 1st block
    before block change, +1 = 1st block after block change
    NotToRiskBlock: separate block structure than the task block
    %}

    TaskParameters.GUI.Ch4RepeatedTonicTrigger = 0;
	TaskParameters.GUIMeta.Ch4RepeatedTonicTrigger.Style = 'checkbox';
    
    TaskParameters.GUI.Ch4TonicPoisson = 0;
	TaskParameters.GUIMeta.Ch4TonicPoisson.Style = 'checkbox';
    
    TaskParameters.GUI.Ch4TonicVoltage = 0;
    TaskParameters.GUI.Ch4TonicTrainFreq = 5; % in Hz
    TaskParameters.GUI.Ch4TonicPulseNumber = 20; % in second    
    TaskParameters.GUI.Ch4TonicPulseWidth = 0.010; % in second
    
    TaskParameters.GUI.Ch4TonicBlock = 1;
    TaskParameters.GUIMeta.Ch4TonicBlock.Style = 'popupmenu';
    TaskParameters.GUIMeta.Ch4TonicBlock.String = {'NoBlock', 'ToRiskBlock', 'NotToRiskBlock'};
    TaskParameters.GUI.Ch4TonicBlockRangeMin = 0;
    TaskParameters.GUI.Ch4TonicBlockRangeMax = 0;
    %{
    NoBlock: ignore BlockRange, only base on trigger percentage
    ToRiskBlock: Relative to the Block structure of task, -1 = 1st block
    before block change, +1 = 1st block after block change
    NotToRiskBlock: separate block structure than the task block
    %}

    TaskParameters.GUI.Ch4PhasicVoltage = 0;
    TaskParameters.GUI.Ch4PhasicTrainFreq = 30; % in Hz
    TaskParameters.GUI.Ch4PhasicPulseNumber = 15; % in second
    TaskParameters.GUI.Ch4PhasicPulseWidth = 0.010; % in second
    
    TaskParameters.GUI.Ch4PhasicBlock = 1;
    TaskParameters.GUIMeta.Ch4PhasicBlock.Style = 'popupmenu';
    TaskParameters.GUIMeta.Ch4PhasicBlock.String = {'NoBlock', 'ToRiskBlock', 'NotToRiskBlock'};
    TaskParameters.GUI.Ch4PhasicBlockRangeMin = 0;
    TaskParameters.GUI.Ch4PhasicBlockRangeMax = 0;
    %{
    NoBlock: ignore BlockRange, only base on trigger percentage
    ToRiskBlock: Relative to the Block structure of task, -1 = 1st block
    before block change, +1 = 1st block after block change
    NotToRiskBlock: separate block structure than the task block
    %}

    TaskParameters.GUIPanels.AOMCh4Train = {'Ch4Looped', 'Ch4StopBlock', 'Ch4StopBlockRangeMin', 'Ch4StopBlockRangeMax',...
                                            'Ch4RepeatedTonicTrigger', 'Ch4TonicPoisson',...
                                            'Ch4TonicVoltage', 'Ch4TonicTrainFreq', 'Ch4TonicPulseNumber', 'Ch4TonicPulseWidth',...
                                            'Ch4TonicBlock', 'Ch4TonicBlockRangeMin', 'Ch4TonicBlockRangeMax',...
                                            'Ch4PhasicVoltage', 'Ch4PhasicTrainFreq', 'Ch4PhasicPulseNumber', 'Ch4PhasicPulseWidth',...
                                            'Ch4PhasicBlock', 'Ch4PhasicBlockRangeMin', 'Ch4PhasicBlockRangeMax'};

    %% AOM Ch4 Trigger
    TaskParameters.GUI.WaitCInCh4Percentage = 0;
    TaskParameters.GUI.WaitCInCh4Train = 1; % usually for non-stop continuous tonic stimulation
    TaskParameters.GUIMeta.WaitCInCh4Train.Style = 'popupmenu';
    TaskParameters.GUIMeta.WaitCInCh4Train.String = {'Stop', 'Tonic', 'Phasic'};
    TaskParameters.GUI.WaitCInCh4End = 2; % next state ('NoTrialStart' or 'StartCIn') hard stop playback
	TaskParameters.GUIMeta.WaitCInCh4End.Style = 'popupmenu';
    TaskParameters.GUIMeta.WaitCInCh4End.String = {'None', 'Stop', 'Tonic'};
    
    TaskParameters.GUI.CInCh4Percentage = 0;
    TaskParameters.GUI.CInCh4Train = 1; % usually for tonic
    TaskParameters.GUIMeta.CInCh4Train.Style = 'popupmenu';
    TaskParameters.GUIMeta.CInCh4Train.String = {'Stop', 'Tonic', 'Phasic'};
    TaskParameters.GUI.CInCh4End = 2; % next state ('EW', 'BF', 'ND', or 'WaitSIn') hard stop playback <- always all needs a stop
	TaskParameters.GUIMeta.CInCh4End.Style = 'popupmenu';
    TaskParameters.GUIMeta.CInCh4End.String = {'None', 'Stop', 'Tonic'};
    
    TaskParameters.GUI.SInCh4Percentage = 0;
    TaskParameters.GUI.SInCh4Train = 1;
    TaskParameters.GUIMeta.SInCh4Train.Style = 'popupmenu';
    TaskParameters.GUIMeta.SInCh4Train.String = {'Stop', 'Tonic', 'Phasic'};
    TaskParameters.GUI.SInCh4End = 2; % next state ('Water', 'IncorrectChoice', 'SkippedFeedback', or 'NotBaited') hard stop playback
	TaskParameters.GUIMeta.SInCh4End.Style = 'popupmenu';
    TaskParameters.GUIMeta.SInCh4End.String = {'None', 'Stop', 'Tonic'};
    
    TaskParameters.GUI.WaterSCh4Percentage = 0;
    TaskParameters.GUI.Ch4RewardReplacement = 0;
    TaskParameters.GUIMeta.Ch4RewardReplacement.Style = 'checkbox';
    TaskParameters.GUI.WaterSCh4Train = 1; % usually for phasic
    TaskParameters.GUIMeta.WaterSCh4Train.Style = 'popupmenu';
    TaskParameters.GUIMeta.WaterSCh4Train.String = {'Stop', 'Tonic', 'Phasic'};
    TaskParameters.GUI.WaterSCh4End = 2; % next state ('Drinking') hard stop playback
	TaskParameters.GUIMeta.WaterSCh4End.Style = 'popupmenu';
    TaskParameters.GUIMeta.WaterSCh4End.String = {'None', 'Stop', 'Tonic'};

    TaskParameters.GUI.SkippedFeedbackCh4Percentage = 0;
    TaskParameters.GUI.SkippedFeedbackCh4Train = 1; % usually for phasic
    TaskParameters.GUIMeta.SkippedFeedbackCh4Train.Style = 'popupmenu';
    TaskParameters.GUIMeta.SkippedFeedbackCh4Train.String = {'Stop', 'Tonic', 'Phasic'};
    TaskParameters.GUI.SkippedFeedbackCh4End = 2; % next state ('ITI') hard stop playback <- usually longer than SB-TimeOut
	TaskParameters.GUIMeta.SkippedFeedbackCh4End.Style = 'popupmenu';
    TaskParameters.GUIMeta.SkippedFeedbackCh4End.String = {'None', 'Stop', 'Tonic'};

    TaskParameters.GUIPanels.AOMCh4Trigger = {'WaitCInCh4Percentage', 'WaitCInCh4Train', 'WaitCInCh4End',...
                                              'CInCh4Percentage', 'CInCh4Train', 'CInCh4End',...
                                              'SInCh4Percentage', 'SInCh4Train', 'SInCh4End',...
                                              'WaterSCh4Percentage', 'Ch4RewardReplacement', 'WaterSCh4Train', 'WaterSCh4End',...
                                              'SkippedFeedbackCh4Percentage', 'SkippedFeedbackCh4Train', 'SkippedFeedbackCh4End'};
    
    %% GUI figure
    TaskParameters.GUITabs.General = {'General', 'Sampling', 'Reward', 'FeedbackDelay'};
    TaskParameters.GUITabs.Photometry = {'PhotometryRecording', 'PhotometryNidaq', 'PhotometryPlot', 'PhotometryRig'};
    TaskParameters.GUITabs.Optogenetics = {'AOMCh3Train', 'AOMCh3Trigger', 'AOMCh4Train', 'AOMCh4Trigger'};
       
    TaskParameters.GUI = orderfields(TaskParameters.GUI);
    TaskParameters.Figures.OutcomePlot.Position = [100, 100, 800, 600];
end
BpodParameterGUI('init', TaskParameters);

end  % End function
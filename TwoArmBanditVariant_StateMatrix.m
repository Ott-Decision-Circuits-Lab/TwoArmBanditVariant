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

%% Set up state matrix    
sma = NewStateMatrix();

%% PreITI
PreITIAction = {};
if isfield(TaskParameters.GUI, 'Wire1VideoTrigger')
    switch TaskParameters.GUIMeta.Wire1VideoTrigger.String{TaskParameters.GUI.Wire1VideoTrigger}
        case 1 % None

        case 2 % Investment

        case 3 % All
            PreITIAction =	{'WireState', 1};
    end
            
end
if isfield(BpodSystem.ModuleUSB, 'WavePlayer1') % if also WavePlayer -> opto
    if TrialData.WaitCInCh3Phasic(iTrial)
        if TrialData.WaitCInCh4Phasic(iTrial)
            PreITIAction =	[PreITIAction, {'WavePlayer1', ['P' 28]}]; % phasic ch3, phasic ch4
        elseif TrialData.WaitCInCh4Tonic(iTrial)
            if TaskParameters.GUI.Ch4RepeatedTonicTrigger || iTrial == 1 || ~TrialData.Ch4TonicCarriedForward(iTrial-1)
                PreITIAction =	[PreITIAction, {'WavePlayer1', ['P' 27]}]; % phasic ch3, tonic ch4
            else
                PreITIAction =	[PreITIAction, {'WavePlayer1', ['P' 25]}]; % phasic ch3, no stop ch4
            end
        else
            PreITIAction =	[PreITIAction, {'WavePlayer1', ['P' 26]}]; % phasic ch3, hard stop ch4
        end
    elseif TrialData.WaitCInCh3Tonic(iTrial)
        if TaskParameters.GUI.Ch3RepeatedTonicTrigger || iTrial == 1 || ~TrialData.Ch3TonicCarriedForward(iTrial-1)
            if TrialData.WaitCInCh4Phasic(iTrial)
                PreITIAction =	[PreITIAction, {'WavePlayer1', ['P' 24]}]; % tonic ch3, phasic ch4
            elseif TrialData.WaitCInCh4Tonic(iTrial)
                if TaskParameters.GUI.Ch4RepeatedTonicTrigger || iTrial == 1 || ~TrialData.Ch4TonicCarriedForward(iTrial-1)
                    PreITIAction =	[PreITIAction, {'WavePlayer1', ['P' 23]}]; % tonic ch3, tonic ch4
                else
                    PreITIAction =	[PreITIAction, {'WavePlayer1', ['P' 21]}]; % tonic ch3, no stop ch4
                end
            else
                PreITIAction =	[PreITIAction, {'WavePlayer1', ['P' 22]}]; % tonic ch3, hard stop ch4
            end
        else
            if TrialData.WaitCInCh4Phasic(iTrial)
                PreITIAction =	[PreITIAction, {'WavePlayer1', ['P' 31]}]; % no stop ch3, phasic ch4
            elseif TrialData.WaitCInCh4Tonic(iTrial)
                if TaskParameters.GUI.Ch4RepeatedTonicTrigger || iTrial == 1 || ~TrialData.Ch4TonicCarriedForward(iTrial-1)
                    PreITIAction =	[PreITIAction, {'WavePlayer1', ['P' 29]}]; % no stop ch3, tonic ch4
                else
                    % no stop ch3, no stop ch4, i.e. do nothing
                end
            else
                PreITIAction =	[PreITIAction, {'WavePlayer1', ['P' 34]}];  % no stop ch3, hard stop ch4
            end
        end
    else
        if TrialData.WaitCInCh4Phasic(iTrial)
            PreITIAction =	[PreITIAction, {'WavePlayer1', ['P' 32]}]; % hard stop ch3, phasic ch4
        elseif TrialData.WaitCInCh4Tonic(iTrial)
            if TaskParameters.GUI.Ch4RepeatedTonicTrigger || iTrial == 1 || ~TrialData.Ch4TonicCarriedForward(iTrial-1)
                PreITIAction =	[PreITIAction, {'WavePlayer1', ['P' 30]}]; % hard stop ch3, tonic ch4
            else
                PreITIAction =	[PreITIAction, {'WavePlayer1', ['P' 33]}]; % hard stop ch3, no stop ch4
            end
        else
            PreITIAction =	[PreITIAction, {'WavePlayer1', ['P' 20]}]; % hard stop ch3, hard stop ch4
        end
    end
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
    switch TaskParameters.GUIMeta.WaitCInCh3End.String{TaskParameters.GUI.WaitCInCh3End}
        case 'None'
            switch TaskParameters.GUIMeta.WaitCInCh4End.String{TaskParameters.GUI.WaitCInCh4End}
                case 'None'
                    % no stop ch3, no stop ch4, i.e. do nothing
    
                case 'Stop'
                    NoTrialStartAction = {'WavePlayer1', ['P' 34]}; % no stop ch3, hard stop ch4
    
                case 'Tonic'
                    if TaskParameters.GUI.Ch4RepeatedTonicTrigger || ~TrialData.WaitCInCh4Tonic(iTrial)
                        NoTrialStartAction = {'WavePlayer1', ['P' 29]}; % no stop ch3, tonic ch4
                    else
                        % no stop ch3, no stop ch4, i.e. do nothing
                    end
            end
    
        case 'Stop'
            switch TaskParameters.GUIMeta.WaitCInCh4End.String{TaskParameters.GUI.WaitCInCh4End}
                case 'None'
                    NoTrialStartAction = {'WavePlayer1', ['P' 33]}; % hard stop ch3, no stop ch4
    
                case 'Stop'
                    NoTrialStartAction = {'WavePlayer1', ['P' 20]}; % hard stop ch3, hard stop ch4
    
                case 'Tonic'
                    if TaskParameters.GUI.Ch4RepeatedTonicTrigger || ~TrialData.WaitCInCh4Tonic(iTrial)
                        NoTrialStartAction = {'WavePlayer1', ['P' 30]}; % hard stop ch3, tonic ch4
                    else
                        NoTrialStartAction = {'WavePlayer1', ['P' 33]}; % hard stop ch3, no stop ch4
                    end
            end
    
        case 'Tonic'
            if TaskParameters.GUI.Ch3RepeatedTonicTrigger || ~TrialData.WaitCInCh3Tonic(iTrial)
                switch TaskParameters.GUIMeta.WaitCInCh4End.String{TaskParameters.GUI.WaitCInCh4End}
                    case 'None'
                        NoTrialStartAction = {'WavePlayer1', ['P' 21]}; % tonic ch3, no stop ch4
        
                    case 'Stop'
                        NoTrialStartAction = {'WavePlayer1', ['P' 22]}; % tonic ch3, hard stop ch4
        
                    case 'Tonic'
                        if TaskParameters.GUI.Ch4RepeatedTonicTrigger || ~TrialData.WaitCInCh4Tonic(iTrial)
                            NoTrialStartAction = {'WavePlayer1', ['P' 23]}; % tonic ch3, tonic ch4
                        else
                            NoTrialStartAction = {'WavePlayer1', ['P' 21]}; % tonic ch3, no stop ch4
                        end
                end
            else
                switch TaskParameters.GUIMeta.WaitCInCh4End.String{TaskParameters.GUI.WaitCInCh4End}
                    case 'None'
                        % no stop ch3, no stop ch4, i.e. do nothing
        
                    case 'Stop'
                        NoTrialStartAction = {'WavePlayer1', ['P' 34]}; % no stop ch3, hard stop ch4
        
                    case 'Tonic'
                        if TaskParameters.GUI.Ch4RepeatedTonicTrigger || ~TrialData.WaitCInCh4Tonic(iTrial)
                            NoTrialStartAction = {'WavePlayer1', ['P' 29]}; % no stop ch3, tonic ch4
                        else
                            % no stop ch3, no stop ch4, i.e. do nothing
                        end
                end
            end
    
    end
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
    if TrialData.CInCh3Phasic(iTrial)
        if TrialData.CInCh4Phasic(iTrial)
            StimulusDelayAction = [StimulusDelayAction, {'WavePlayer1', ['P' 28]}]; % phasic ch3, phasic ch4
        elseif TrialData.CInCh4Tonic(iTrial)
            if TaskParameters.GUI.Ch4RepeatedTonicTrigger || ~TrialData.WaitCInCh4Tonic(iTrial)
                StimulusDelayAction = [StimulusDelayAction, {'WavePlayer1', ['P' 27]}]; % phasic ch3, tonic ch4
            else
                StimulusDelayAction = [StimulusDelayAction, {'WavePlayer1', ['P' 25]}]; % phasic ch3, no stop ch4
            end
        else
            StimulusDelayAction = [StimulusDelayAction, {'WavePlayer1', ['P' 26]}]; % phasic ch3, hard stop ch4
        end
    elseif TrialData.CInCh3Tonic(iTrial)
        if TaskParameters.GUI.Ch3RepeatedTonicTrigger || ~TrialData.WaitCInCh3Tonic(iTrial)
            if TrialData.CInCh4Phasic(iTrial)
                StimulusDelayAction = [StimulusDelayAction, {'WavePlayer1', ['P' 24]}]; % tonic ch3, phasic ch4
            elseif TrialData.CInCh4Tonic(iTrial)
                if TaskParameters.GUI.Ch4RepeatedTonicTrigger || ~TrialData.WaitCInCh4Tonic(iTrial)
                    StimulusDelayAction = [StimulusDelayAction, {'WavePlayer1', ['P' 23]}]; % tonic ch3, tonic ch4
                else
                    StimulusDelayAction = [StimulusDelayAction, {'WavePlayer1', ['P' 21]}]; % tonic ch3, no stop ch4
                end
            else
                StimulusDelayAction = [StimulusDelayAction, {'WavePlayer1', ['P' 22]}]; % tonic ch3, hard stop ch4
            end
        else
            if TrialData.CInCh4Phasic(iTrial)
                StimulusDelayAction = [StimulusDelayAction, {'WavePlayer1', ['P' 31]}]; % no stop ch3, phasic ch4
            elseif TrialData.CInCh4Tonic(iTrial)
                if TaskParameters.GUI.Ch4RepeatedTonicTrigger || ~TrialData.WaitCInCh4Tonic(iTrial)
                    StimulusDelayAction = [StimulusDelayAction, {'WavePlayer1', ['P' 29]}]; % no stop ch3, tonic ch4
                else
                    % no stop ch3, no stop ch4, i.e. do nothing
                end
            else
                StimulusDelayAction = [StimulusDelayAction, {'WavePlayer1', ['P' 34]}];  % no stop ch3, hard stop ch4
            end
        end
    else
        if TrialData.CInCh4Phasic(iTrial)
            StimulusDelayAction = [StimulusDelayAction, {'WavePlayer1', ['P' 32]}]; % hard stop ch3, phasic ch4
        elseif TrialData.CInCh4Tonic(iTrial)
            if TaskParameters.GUI.Ch4RepeatedTonicTrigger || ~TrialData.WaitCInCh4Tonic(iTrial)
                StimulusDelayAction = [StimulusDelayAction, {'WavePlayer1', ['P' 30]}]; % hard stop ch3, tonic ch4
            else
                StimulusDelayAction = [StimulusDelayAction, {'WavePlayer1', ['P' 33]}]; % hard stop ch3, no stop ch4
            end
        else
            StimulusDelayAction = [StimulusDelayAction, {'WavePlayer1', ['P' 20]}]; % hard stop ch3, hard stop ch4
        end
    end
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
switch TaskParameters.GUIMeta.CInCh3End.String{TaskParameters.GUI.CInCh3End}
    case 'None'
        switch TaskParameters.GUIMeta.CInCh4End.String{TaskParameters.GUI.CInCh4End}
            case 'None'
                % no stop ch3, no stop ch4, i.e. do nothing

            case 'Stop'
                CInEndOpto = {'WavePlayer1', ['P' 34]}; % no stop ch3, hard stop ch4

            case 'Tonic'
                if TaskParameters.GUI.Ch4RepeatedTonicTrigger || ~TrialData.CInCh4Tonic(iTrial)
                    CInEndOpto = {'WavePlayer1', ['P' 29]}; % no stop ch3, tonic ch4
                else
                    % no stop ch3, no stop ch4, i.e. do nothing
                end
        end

    case 'Stop'
        switch TaskParameters.GUIMeta.CInCh4End.String{TaskParameters.GUI.CInCh4End}
            case 'None'
                CInEndOpto = {'WavePlayer1', ['P' 33]}; % hard stop ch3, no stop ch4

            case 'Stop'
                CInEndOpto = {'WavePlayer1', ['P' 20]}; % hard stop ch3, hard stop ch4

            case 'Tonic'
                if TaskParameters.GUI.Ch4RepeatedTonicTrigger || ~TrialData.CInCh4Tonic(iTrial)
                    CInEndOpto = {'WavePlayer1', ['P' 30]}; % hard stop ch3, tonic ch4
                else
                    CInEndOpto = {'WavePlayer1', ['P' 33]}; % hard stop ch3, no stop ch4
                end
        end

    case 'Tonic'
        if TaskParameters.GUI.Ch3RepeatedTonicTrigger || ~TrialData.CInCh3Tonic(iTrial)
            switch TaskParameters.GUIMeta.CInCh4End.String{TaskParameters.GUI.CInCh4End}
                case 'None'
                    CInEndOpto = {'WavePlayer1', ['P' 21]}; % tonic ch3, no stop ch4
    
                case 'Stop'
                    CInEndOpto = {'WavePlayer1', ['P' 22]}; % tonic ch3, hard stop ch4
    
                case 'Tonic'
                    if TaskParameters.GUI.Ch4RepeatedTonicTrigger || ~TrialData.CInCh4Tonic(iTrial)
                        CInEndOpto = {'WavePlayer1', ['P' 23]}; % tonic ch3, tonic ch4
                    else
                        CInEndOpto = {'WavePlayer1', ['P' 21]}; % tonic ch3, no stop ch4
                    end
            end
        else
            switch TaskParameters.GUIMeta.CInCh4End.String{TaskParameters.GUI.CInCh4End}
                case 'None'
                    % no stop ch3, no stop ch4, i.e. do nothing
    
                case 'Stop'
                    CInEndOpto = {'WavePlayer1', ['P' 34]}; % no stop ch3, hard stop ch4
    
                case 'Tonic'
                    if TaskParameters.GUI.Ch4RepeatedTonicTrigger || ~TrialData.CInCh4Tonic(iTrial)
                        CInEndOpto = {'WavePlayer1', ['P' 29]}; % no stop ch3, tonic ch4
                    else
                        % no stop ch3, no stop ch4, i.e. do nothing
                    end
            end
        end
end % end switch

CInEndOptoWhiteNoise = {};
switch TaskParameters.GUIMeta.CInCh3End.String{TaskParameters.GUI.CInCh3End}
    case 'None'
        switch TaskParameters.GUIMeta.CInCh4End.String{TaskParameters.GUI.CInCh4End}
            case 'None'
                CInEndOptoWhiteNoise = {'WavePlayer1', ['P' 0]}; % no stop ch3, no stop ch4, i.e. do nothing

            case 'Stop'
                CInEndOptoWhiteNoise = {'WavePlayer1', ['P' 42]}; % no stop ch3, hard stop ch4

            case 'Tonic'
                if TaskParameters.GUI.Ch4RepeatedTonicTrigger || ~TrialData.CInCh4Tonic(iTrial)
                    CInEndOptoWhiteNoise = {'WavePlayer1', ['P' 39]}; % no stop ch3, tonic ch4
                else
                    CInEndOptoWhiteNoise = {'WavePlayer1', ['P' 0]}; % no stop ch3, no stop ch4, i.e. do nothing
                end
        end

    case 'Stop'
        switch TaskParameters.GUIMeta.CInCh4End.String{TaskParameters.GUI.CInCh4End}
            case 'None'
                CInEndOptoWhiteNoise = {'WavePlayer1', ['P' 41]}; % hard stop ch3, no stop ch4

            case 'Stop'
                CInEndOptoWhiteNoise = {'WavePlayer1', ['P' 35]}; % hard stop ch3, hard stop ch4

            case 'Tonic'
                if TaskParameters.GUI.Ch4RepeatedTonicTrigger || ~TrialData.CInCh4Tonic(iTrial)
                    CInEndOptoWhiteNoise = {'WavePlayer1', ['P' 40]}; % hard stop ch3, tonic ch4
                else
                    CInEndOptoWhiteNoise = {'WavePlayer1', ['P' 41]}; % hard stop ch3, no stop ch4
                end
        end

    case 'Tonic'
        if TaskParameters.GUI.Ch3RepeatedTonicTrigger || ~TrialData.CInCh3Tonic(iTrial)
            switch TaskParameters.GUIMeta.CInCh4End.String{TaskParameters.GUI.CInCh4End}
                case 'None'
                    CInEndOptoWhiteNoise = {'WavePlayer1', ['P' 36]}; % tonic ch3, no stop ch4
    
                case 'Stop'
                    CInEndOptoWhiteNoise = {'WavePlayer1', ['P' 37]}; % tonic ch3, hard stop ch4
    
                case 'Tonic'
                    if TaskParameters.GUI.Ch4RepeatedTonicTrigger || ~TrialData.CInCh4Tonic(iTrial)
                        CInEndOptoWhiteNoise = {'WavePlayer1', ['P' 38]}; % tonic ch3, tonic ch4
                    else
                        CInEndOptoWhiteNoise = {'WavePlayer1', ['P' 36]}; % tonic ch3, no stop ch4
                    end
            end
        else
            switch TaskParameters.GUIMeta.CInCh4End.String{TaskParameters.GUI.CInCh4End}
                case 'None'
                    CInEndOptoWhiteNoise = {'WavePlayer1', ['P' 0]}; % no stop ch3, no stop ch4, i.e. do nothing
    
                case 'Stop'
                    CInEndOptoWhiteNoise = {'WavePlayer1', ['P' 42]}; % no stop ch3, hard stop ch4
    
                case 'Tonic'
                    if TaskParameters.GUI.Ch4RepeatedTonicTrigger || ~TrialData.CInCh4Tonic(iTrial)
                        CInEndOptoWhiteNoise = {'WavePlayer1', ['P' 39]}; % no stop ch3, tonic ch4
                    else
                        CInEndOptoWhiteNoise = {'WavePlayer1', ['P' 0]}; % no stop ch3, no stop ch4, i.e. do nothing
                    end
            end
        end

end % end switch

%% BrokeFixation
TupStateChange = 'ITI';
if TaskParameters.GUI.RenewBrokeFixation
    TupStateChange = 'WaitCIn';
end
BrokeFixationAction = {};
switch TaskParameters.GUIMeta.BrokeFixationFeedback.String{TaskParameters.GUI.BrokeFixationFeedback}
    case 'None' % only opto adjustment
        if isfield(BpodSystem.ModuleUSB, 'WavePlayer1') % if also WavePlayer -> opto
            BrokeFixationAction = [BrokeFixationAction, CInEndOpto];
        end % end if
        
    case 'WhiteNoise' % sound + opto
        if isfield(BpodSystem.ModuleUSB, 'HiFi1') % prioritize HiFi for sound
            BrokeFixationAction = [BrokeFixationAction, {'HiFi1', ['P' 0]}];

            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1') % if also WavePlayer -> opto
               BrokeFixationAction = [BrokeFixationAction, CInEndOpto];
            end
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

%% 
TupStateChange = 'ITI';
if TaskParameters.GUI.RenewEarlyWithdrawal
    TupStateChange = 'WaitCIn';
end
EarlyWithdrawalAction = {};
switch TaskParameters.GUIMeta.EarlyWithdrawalFeedback.String{TaskParameters.GUI.EarlyWithdrawalFeedback}
    case 'None'
        if isfield(BpodSystem.ModuleUSB, 'WavePlayer1') % if also WavePlayer -> opto
            EarlyWithdrawalAction = [EarlyWithdrawalAction, CInEndOpto];
        end % end if

    case 'WhiteNoise'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1') % prioritize HiFi for sound
            EarlyWithdrawalAction = [EarlyWithdrawalAction, {'HiFi1', ['P' 1]}];

            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                EarlyWithdrawalAction = [EarlyWithdrawalAction, CInEndOpto];
            end
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

%% StillSampling
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

%% WaitSin
WaitSInAction = {LeftLight, LeftLightValue,...
                 RightLight, RightLightValue...
                 CenterLight, CenterLightValue};
switch TaskParameters.GUIMeta.EarlyWithdrawalFeedback.String{TaskParameters.GUI.EarlyWithdrawalFeedback}
    case 'None'
        if isfield(BpodSystem.ModuleUSB, 'WavePlayer1') % if also WavePlayer -> opto
            WaitSInAction = [WaitSInAction, CInEndOpto];
        end % end if

    case 'WhiteNoise'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1') % prioritize HiFi for sound
            WaitSInAction = [WaitSInAction, {'HiFi1', ['P' 1]}];

            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                WaitSInAction = [WaitSInAction, CInEndOpto];
            end
        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            WaitSInAction = [WaitSInAction, CInEndOptoWhiteNoise];
        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No EarlyWithdrawal WhiteNoise will be played.');
        else
            disp('Neither HiFi nor analog module is setup. No EarlyWithdrawal WhiteNoise will be played.');
        end
        
end
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
        if isfield(BpodSystem.ModuleUSB, 'WavePlayer1') % if also WavePlayer -> opto
            NoDecisionAction = [NoDecisionAction, CInEndOpto];
        end % end if

    case 'WhiteNoise'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1')
            NoDecisionAction = [NoDecisionAction, {'HiFi1', ['P' 2]}];
            
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                NoDecisionAction = [NoDecisionAction, CInEndOpto];
            end
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
    if TrialData.SInCh3Phasic(iTrial)
        if TrialData.SInCh4Phasic(iTrial)
            SInOpto = {'WavePlayer1', ['P' 28]}; % phasic ch3, phasic ch4
        elseif TrialData.SInCh4Tonic(iTrial)
            if TaskParameters.GUI.Ch4RepeatedTonicTrigger ||...
               strcmpi(TaskParameters.GUIMeta.CInCh4End.String{TaskParameters.GUI.CInCh4End}, 'Stop') ||...
               strcmpi(TaskParameters.GUIMeta.CInCh4End.String{TaskParameters.GUI.CInCh4End}, 'None') &&...
               ~TrialData.CInCh4Tonic(iTrial)
                SInOpto = {'WavePlayer1', ['P' 27]}; % phasic ch3, tonic ch4
            else
                SInOpto = {'WavePlayer1', ['P' 25]}; % phasic ch3, no stop ch4
            end
        else
            SInOpto = {'WavePlayer1', ['P' 26]}; % phasic ch3, hard stop ch4
        end
    elseif TrialData.SInCh3Tonic(iTrial)
        if TaskParameters.GUI.Ch3RepeatedTonicTrigger ||...
           strcmpi(TaskParameters.GUIMeta.CInCh3End.String{TaskParameters.GUI.CInCh3End}, 'Stop') ||...
           strcmpi(TaskParameters.GUIMeta.CInCh3End.String{TaskParameters.GUI.CInCh3End}, 'None') &&...
           ~TrialData.CInCh4Tonic(iTrial)
            if TrialData.SInCh4Phasic(iTrial)
                SInOpto = {'WavePlayer1', ['P' 24]}; % tonic ch3, phasic ch4
            elseif TrialData.SInCh4Tonic(iTrial)
                if TaskParameters.GUI.Ch4RepeatedTonicTrigger ||...
                   strcmpi(TaskParameters.GUIMeta.CInCh4End.String{TaskParameters.GUI.CInCh4End}, 'Stop') ||...
                   strcmpi(TaskParameters.GUIMeta.CInCh4End.String{TaskParameters.GUI.CInCh4End}, 'None') &&...
                   ~TrialData.CInCh4Tonic(iTrial)
                    SInOpto = {'WavePlayer1', ['P' 23]}; % tonic ch3, tonic ch4
                else
                    SInOpto = {'WavePlayer1', ['P' 21]}; % tonic ch3, no stop ch4
                end
            else
                SInOpto = {'WavePlayer1', ['P' 22]}; % tonic ch3, hard stop ch4
            end
        else
            if TrialData.SInCh4Phasic(iTrial)
                SInOpto = {'WavePlayer1', ['P' 31]}; % no stop ch3, phasic ch4
            elseif TrialData.SInCh4Tonic(iTrial)
                if TaskParameters.GUI.Ch4RepeatedTonicTrigger ||...
                   strcmpi(TaskParameters.GUIMeta.CInCh4End.String{TaskParameters.GUI.CInCh4End}, 'Stop') ||...
                   strcmpi(TaskParameters.GUIMeta.CInCh4End.String{TaskParameters.GUI.CInCh4End}, 'None') &&...
                   ~TrialData.CInCh4Tonic(iTrial)
                    SInOpto = {'WavePlayer1', ['P' 29]}; % no stop ch3, tonic ch4
                else
                    % no stop ch3, no stop ch4, i.e. do nothing
                end
            else
                SInOpto = {'WavePlayer1', ['P' 34]};  % no stop ch3, hard stop ch4
            end
        end
    else
        if TrialData.SInCh4Phasic(iTrial)
            SInOpto = {'WavePlayer1', ['P' 32]}; % hard stop ch3, phasic ch4
        elseif TrialData.SInCh4Tonic(iTrial)
            if TaskParameters.GUI.Ch4RepeatedTonicTrigger ||...
               strcmpi(TaskParameters.GUIMeta.CInCh4End.String{TaskParameters.GUI.CInCh4End}, 'Stop') ||...
               strcmpi(TaskParameters.GUIMeta.CInCh4End.String{TaskParameters.GUI.CInCh4End}, 'None') &&...
               ~TrialData.CInCh4Tonic(iTrial)
                SInOpto = {'WavePlayer1', ['P' 30]}; % hard stop ch3, tonic ch4
            else
                SInOpto = {'WavePlayer1', ['P' 33]}; % hard stop ch3, no stop ch4
            end
        else
            SInOpto = {'WavePlayer1', ['P' 20]}; % hard stop ch3, hard stop ch4
        end
    end
end

%% LIn
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

sma = SetGlobalTimer(sma, 3, FeedbackDelayLeft); % used to track side poke grace period

LInStateChange = 'WaterL';
if TrialData.Baited(1, iTrial) == false
    LInStateChange = 'NotBaited';
end
if TrialData.LightLeft(iTrial) == false % Incorrect Choice overwrite Baited 
    LInStateChange = 'IncorrectChoice';
end
sma = AddState(sma, 'Name', 'StartLIn',... % dummy state for trigger GlobalTimer3
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'LIn',...
                              'GlobalTimer3_End', LInStateChange},...
    'OutputActions',{'GlobalTimerTrig', 3, LeftLight, LeftLightValue});

sma = AddState(sma, 'Name', 'LIn',...
    'Timer', FeedbackDelayLeft,...
    'StateChangeConditions', {'Tup', LInStateChange,...
                              'GlobalTimer3_End', LInStateChange,...
                              LeftPortOut,'LInGrace'},...
    'OutputActions', {LeftLight, LeftLightValue});

sma = AddState(sma, 'Name', 'WaterL',...
    'Timer', LeftValveTime,...
    'StateChangeConditions', {'Tup', 'Drinking'},...
    'OutputActions', {'ValveState', LeftValve});

sma = AddState(sma, 'Name', 'LInGrace',...
    'Timer', TaskParameters.GUI.FeedbackDelayGrace,...
    'StateChangeConditions', {LeftPortIn, 'LIn',...
                              'Tup', 'SkippedFeedback',...
                              'GlobalTimer3_End', 'SkippedFeedback',...
                              CenterPortIn, 'SkippedFeedback',...
                              RightPortIn, 'SkippedFeedback'},...
    'OutputActions', {LeftLight, LeftLightValue});

sma = SetGlobalTimer(sma, 4, FeedbackDelayRight); % used to track side poke grace period

RInStateChange = 'WaterR';
if TrialData.Baited(2, iTrial) == false
    RInStateChange = 'NotBaited';
end
if TrialData.LightLeft(iTrial) == true % Incorrect Choice overwrite Baited 
    RInStateChange = 'IncorrectChoice';
end
sma = AddState(sma, 'Name', 'StartRIn',... % dummy state for trigger GlobalTimer3
    'Timer', 0,...
    'StateChangeConditions', {'Tup', 'RIn',...
                              'GlobalTimer4_End', RInStateChange},...
    'OutputActions',{'GlobalTimerTrig', 4, RightLight, RightLightValue});

sma = AddState(sma, 'Name', 'RIn',...
    'Timer', FeedbackDelayRight,...
    'StateChangeConditions', {'Tup', RInStateChange,...
                              'GlobalTimer4_End', RInStateChange,...
                              RightPortOut,'RInGrace'},...
    'OutputActions', {RightLight, RightLightValue});

sma = AddState(sma, 'Name', 'WaterR',...
    'Timer', RightValveTime,...
    'StateChangeConditions', {'Tup', 'Drinking'},...
    'OutputActions', {'ValveState', RightValve});

sma = AddState(sma, 'Name', 'RInGrace',...
    'Timer', TaskParameters.GUI.FeedbackDelayGrace,...
    'StateChangeConditions', {RightPortIn, 'RIn',...
                              'Tup', 'SkippedFeedback',...
                              'GlobalTimer4_End', 'SkippedFeedback',...
                              CenterPortIn, 'SkippedFeedback',...
                              LeftPortIn, 'SkippedFeedback'},...
    'OutputActions', {RightLight, RightLightValue});

IncorrectChoiceAction = {};
switch TaskParameters.GUIMeta.IncorrectChoiceFeedback.String{TaskParameters.GUI.IncorrectChoiceFeedback}
    case 'None' % no adjustmnet needed
        
    case 'WhiteNoise'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1')
            IncorrectChoiceAction = {'HiFi1', ['P' 4]};
        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            IncorrectChoiceAction = {'WavePlayer1', ['P' 4]};
        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No IncorrecChoice WhiteNoise will be played.');
        else
            disp('Neither HiFi nor analog module is setup. No IncorrecChoice WhiteNoise will be played.');
        end
        
end
sma = AddState(sma, 'Name', 'IncorrectChoice',...
    'Timer', TaskParameters.GUI.IncorrectChoiceTimeOut,...
    'StateChangeConditions', {'Tup', 'ITI'},...
    'OutputActions', IncorrectChoiceAction);

SkippedFeedbackAction = {};
switch TaskParameters.GUIMeta.SkippedFeedbackFeedback.String{TaskParameters.GUI.SkippedFeedbackFeedback}
    case 'None' % no adjustmnet needed
        
    case 'WhiteNoise'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1')
            SkippedFeedbackAction = {'HiFi1', ['P' 5]};
        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            SkippedFeedbackAction = {'WavePlayer1', ['P' 5]};
        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No SkippedFeedback WhiteNoise will be played.');
        else
            disp('Neither HiFi nor analog module is setup. No SkippedFeedback WhiteNoise will be played.');
        end
        
    case 'Beep'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1')
            SkippedFeedbackAction = {'HiFi1', ['P' 5]};
        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            SkippedFeedbackAction = {'WavePlayer1', ['P' 5]};
        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No SkippedFeedback Beep will be played.');
        else
            disp('Neither a HiFi nor analog module is setup. No SkippedFeedback Beep will be played.');
        end
        
end
sma = AddState(sma, 'Name', 'SkippedFeedback',...
    'Timer', TaskParameters.GUI.SkippedFeedbackTimeOut,...
    'StateChangeConditions', {'Tup', 'ITI'},...
    'OutputActions', SkippedFeedbackAction);

NotBaitedAction = {};
switch TaskParameters.GUIMeta.NotBaitedFeedback.String{TaskParameters.GUI.NotBaitedFeedback}
    case 'None' % no adjustmnet needed
        
    case 'WhiteNoise'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1')
            NotBaitedAction = {'HiFi1', ['P' 6]};
        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            NotBaitedAction = {'WavePlayer1', ['P' 6]};
        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No NotBaited WhiteNoise will be played.');
        else
            disp('Neither HiFi nor analog module is setup. No NotBaited WhiteNoise will be played.');
        end
        
    case 'Beep'
        if isfield(BpodSystem.ModuleUSB, 'HiFi1')
            NotBaitedAction = {'HiFi1', ['P' 6]};
        elseif isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            NotBaitedAction = {'WavePlayer1', ['P' 6]};
        elseif BpodSystem.EmulatorMode
            disp('BpodSystem is in EmulatorMode. No NotBaited Beep will be played.');
        else
            disp('Neither HiFi nor analog module is setup. No NotBaited Beep will be played.');
        end
        
end
sma = AddState(sma, 'Name', 'NotBaited',...
    'Timer', TaskParameters.GUI.NotBaitedTimeOut,...
    'StateChangeConditions', {'Tup', 'ITI'},...
    'OutputActions', NotBaitedAction);

sma = AddState(sma, 'Name', 'Drinking',... % serve as time buffer before next trial start
    'Timer', 0,...
    'StateChangeConditions', {LeftPortOut, 'DrinkingGrace',...
                              RightPortOut, 'DrinkingGrace'},...
    'OutputActions', {});

DrinkingGraceTimer = TaskParameters.GUI.DrinkingGraceTime;
sma = AddState(sma, 'Name', 'DrinkingGrace',... % serve as time buffer before next trial start
    'Timer', DrinkingGraceTimer,...
    'StateChangeConditions', {LeftPortIn, 'Drinking',...
                              RightPortIn, 'Drinking',...
                              'Tup', 'ITI'},...
    'OutputActions', {});

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
sma = AddState(sma, 'Name', 'ITI',...
    'Timer', ITITimer,...
    'StateChangeConditions',{'Tup', 'exit'},...
    'OutputActions',{});

end % StateMatrix
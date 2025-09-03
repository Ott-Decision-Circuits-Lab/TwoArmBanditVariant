function TwoArmBanditVariant_LoadWaveform(Player, Mode, iTrial)
% BrokeFixationSound   -> Sound Index 1
% EarlyWithdrawalSound -> 2
% NoDecisionSound      -> 3
% StartNewTrialSound   -> 4
% IncorrectChoiceSound -> 5
% SkippedFeedbackSound -> 6
% NotBaitedFeedbackSound -> 7}
% Sound/profile Index 8-10 are reserved for trial-dependent waveform (Max index for HiFi: 20; for Analog: 64)
% Sound/profile Index 11 onwards are for optogenetics waveform (only for AOM)
% Sound Index 20/64 should be none, i.e. no action

global BpodSystem
global TaskParameters

if nargin < 3
    iTrial = 0;
end

% load auditory stimuli
fs = Player.SamplingRate;

switch Mode
    case 'TrialIndependent'
        %%
        SoundIndex = 1;
        BrokeFixationSound = [];
        if isfield(TaskParameters.GUI, 'BrokeFixationTimeOut') && TaskParameters.GUI.BrokeFixationTimeOut > 0
            switch TaskParameters.GUIMeta.BrokeFixationFeedback.String{TaskParameters.GUI.BrokeFixationFeedback}
                case 'None' % no adjustment

                case 'WhiteNoise'
                    BrokeFixationSound = rand(1, fs*TaskParameters.GUI.BrokeFixationTimeOut)*2 - 1;
            end
        end

        if ~isempty(BrokeFixationSound)
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                Player.loadWaveform(SoundIndex, BrokeFixationSound);
                Player.TriggerProfiles(SoundIndex, 1:2) = SoundIndex;
            elseif isfield(BpodSystem.ModuleUSB, 'HiFi1')
                Player.load(SoundIndex, BrokeFixationSound);
            end
        end

        %%
        SoundIndex = 2;
        EarlyWithdrawalSound = [];
        if isfield(TaskParameters.GUI, 'EarlyWithdrawalTimeOut') && TaskParameters.GUI.EarlyWithdrawalTimeOut > 0
            switch TaskParameters.GUIMeta.EarlyWithdrawalFeedback.String{TaskParameters.GUI.EarlyWithdrawalFeedback}
                case 'None' % no adjustment

                case 'WhiteNoise'
                    EarlyWithdrawalSound = rand(1, fs*TaskParameters.GUI.EarlyWithdrawalTimeOut)*2 - 1;
            end
        end

        if ~isempty(EarlyWithdrawalSound)
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                Player.loadWaveform(SoundIndex, EarlyWithdrawalSound);
                Player.TriggerProfiles(SoundIndex, 1:2) = SoundIndex;
            elseif isfield(BpodSystem.ModuleUSB, 'HiFi1')
                Player.load(SoundIndex, EarlyWithdrawalSound);
            end
        end

        %%
        SoundIndex = 3;
        NoDecisionSound = [];
        if isfield(TaskParameters.GUI, 'NoDecisionTimeOut') && TaskParameters.GUI.NoDecisionTimeOut > 0
            switch TaskParameters.GUIMeta.NoDecisionFeedback.String{TaskParameters.GUI.NoDecisionFeedback}
                case 'None' % no adjustment

                case 'WhiteNoise'
                    NoDecisionSound = rand(1, fs*TaskParameters.GUI.NoDecisionTimeOut)*2 - 1;
            end
        end

        if ~isempty(NoDecisionSound)
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                Player.loadWaveform(SoundIndex, NoDecisionSound);
                Player.TriggerProfiles(SoundIndex, 1:2) = SoundIndex;
            elseif isfield(BpodSystem.ModuleUSB, 'HiFi1')
                Player.load(SoundIndex, NoDecisionSound);
            end
        end

        %%
        SoundIndex = 4;
        StartNewTrialSound = [];
        if isfield(TaskParameters.GUI, 'StartNewTrialTimeOut') && TaskParameters.GUI.StartNewTrialTimeOut > 0
            switch TaskParameters.GUIMeta.StartNewTrialFeedback.String{TaskParameters.GUI.StartNewTrialFeedback}
                case 'None' % no adjustment

                case 'WhiteNoise'
                    StartNewTrialSound = rand(1, fs*TaskParameters.GUI.StartNewTrialTimeOut)*2 - 1;
               
                case 'Beep' % 1k Hz
                    StartNewTrialSound = GenerateRiskCue(fs, TaskParameters.GUI.StartNewTrialTimeOut, 'Freq', 1, 1);

            end
        end

        if ~isempty(StartNewTrialSound)
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                Player.loadWaveform(SoundIndex, StartNewTrialSound);
                Player.TriggerProfiles(SoundIndex, 1:2) = SoundIndex;
            elseif isfield(BpodSystem.ModuleUSB, 'HiFi1')
                Player.load(SoundIndex, StartNewTrialSound);
            end
        end

        %%
        SoundIndex = 5;
        IncorrectChoiceSound = [];
        if isfield(TaskParameters.GUI, 'IncorrectChoiceTimeOut') && TaskParameters.GUI.IncorrectChoiceTimeOut > 0
            switch TaskParameters.GUIMeta.IncorrectChoiceFeedback.String{TaskParameters.GUI.IncorrectChoiceFeedback}
                case 'None' % no adjustment

                case 'WhiteNoise'
                    IncorrectChoiceSound = rand(1, fs*TaskParameters.GUI.IncorrectChoiceTimeOut)*2 - 1;
            end
        end

        if ~isempty(IncorrectChoiceSound)
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                Player.loadWaveform(SoundIndex, IncorrectChoiceSound);
                Player.TriggerProfiles(SoundIndex, 1:2) = SoundIndex;
            elseif isfield(BpodSystem.ModuleUSB, 'HiFi1')
                Player.load(SoundIndex, IncorrectChoiceSound);
            end
        end

        %%
        SoundIndex = 6;
        SkippedFeedbackSound = [];
        if isfield(TaskParameters.GUI, 'SkippedFeedbackTimeOut') && TaskParameters.GUI.SkippedFeedbackTimeOut > 0
            switch TaskParameters.GUIMeta.SkippedFeedbackFeedback.String{TaskParameters.GUI.SkippedFeedbackFeedback}
                case 'None' % no adjustment

                case 'WhiteNoise'
                    SkippedFeedbackSound = rand(1, fs*TaskParameters.GUI.SkippedFeedbackTimeOut)*2 - 1;
                    
                case 'Beep' % 1k Hz
                    SkippedFeedbackSound = GenerateRiskCue(fs, TaskParameters.GUI.SkippedFeedbackTimeOut, 'Freq', 1, 1);

            end
        end

        if ~isempty(SkippedFeedbackSound)
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                Player.loadWaveform(SoundIndex, SkippedFeedbackSound);
                Player.TriggerProfiles(SoundIndex, 1:2) = SoundIndex;
            elseif isfield(BpodSystem.ModuleUSB, 'HiFi1')
                Player.load(SoundIndex, SkippedFeedbackSound);
            end
        end
        
        %%
        SoundIndex = 7;
        NotBaitedSound = [];
        if isfield(TaskParameters.GUI, 'NotBaitedTimeOut') && TaskParameters.GUI.NotBaitedTimeOut > 0
            switch TaskParameters.GUIMeta.NotBaitedFeedback.String{TaskParameters.GUI.NotBaitedFeedback}
                case 'None' % no adjustment

                case 'WhiteNoise'
                    NotBaitedSound = rand(1, fs*TaskParameters.GUI.NotBaitedTimeOut)*2 - 1;
                    
                case 'Beep' % 0.5k Hz
                    NotBaitedSound = GenerateRiskCue(fs, TaskParameters.GUI.NotBaitedTimeOut, 'Freq', 0.5, 0.5);
            end
        end

        if ~isempty(NotBaitedSound)
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                Player.loadWaveform(SoundIndex, NotBaitedSound);
                Player.TriggerProfiles(SoundIndex, 1:2) = SoundIndex;
            elseif isfield(BpodSystem.ModuleUSB, 'HiFi1')
                Player.load(SoundIndex, NotBaitedSound);
            end
        end
        
        %%
        HardStop = 0;
        if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
            Player.loadWaveform(64, HardStop);
        elseif isfield(BpodSystem.ModuleUSB, 'HiFi1')
            Player.load(20, HardStop);
        end

    case 'TrialDependent'
        switch TaskParameters.GUIMeta.RiskType.String{TaskParameters.GUI.RiskType}
            case "Cued"
                TrialData = BpodSystem.Data.Custom.TrialData;
                StimulusTime = TaskParameters.GUI.StimulusTime;
                                
                SoundIndex = 8;
                LeftSound = [];
                RightSound = [];
                if StimulusTime > 0
                    LeftSound = GenerateRiskCue(fs, StimulusTime, 'Freq', TrialData.RewardCueLeft(1,iTrial), TrialData.RewardCueLeft(2,iTrial));
                    RightSound = GenerateRiskCue(fs, StimulusTime, 'Freq', TrialData.RewardCueRight(1,iTrial), TrialData.RewardCueRight(2,iTrial));
                else
                    disp('StimulusTime in GUI should be a positive number. Empty track will be loaded.')
                end
                
                if TrialData.LightLeft(iTrial) == 0
                    LeftSound = [0];
                elseif TrialData.LightLeft(iTrial) == 1
                    RightSound = [0];
                end

                if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                    Player.loadWaveform(SoundIndex, LeftSound);
                    Player.loadWaveform(SoundIndex+1, RightSound);
                    Player.TriggerProfiles(SoundIndex, 1:2) = [SoundIndex SoundIndex+1];
                elseif isfield(BpodSystem.ModuleUSB, 'HiFi1')
                    Player.load(SoundIndex, [LeftSound; RightSound]);
                end

            case 'BlockCued'
                TrialData = BpodSystem.Data.Custom.TrialData;
                StimulusTime = TaskParameters.GUI.StimulusTime;
                                
                SoundIndex = 8;
                LeftSound = [];
                RightSound = [];
                if StimulusTime > 0
                    LeftSound = GenerateRiskCue(fs, StimulusTime, 'Freq', TrialData.RewardCueLeft(1,iTrial), TrialData.RewardCueLeft(2,iTrial));
                    RightSound = GenerateRiskCue(fs, StimulusTime, 'Freq', TrialData.RewardCueRight(1,iTrial), TrialData.RewardCueRight(2,iTrial));
                else
                    disp('StimulusTime in GUI should be a positive number. Empty track will be loaded.')
                end
                
                if TrialData.LightLeft(iTrial) == 0
                    LeftSound = [0];
                elseif TrialData.LightLeft(iTrial) == 1
                    RightSound = [0];
                end

                if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                    Player.loadWaveform(SoundIndex, LeftSound);
                    Player.loadWaveform(SoundIndex+1, RightSound);
                    Player.TriggerProfiles(SoundIndex, 1:2) = [SoundIndex SoundIndex+1];
                elseif isfield(BpodSystem.ModuleUSB, 'HiFi1')
                    Player.load(SoundIndex, [LeftSound; RightSound]);
                end
            
            case "CuedBlockRatio"
                TrialData = BpodSystem.Data.Custom.TrialData;
                StimulusTime = TaskParameters.GUI.StimulusTime;
                                
                SoundIndex = 8;
                LeftSound = [];
                RightSound = [];
                if StimulusTime > 0
                    LeftSound = GenerateRiskCue(fs, StimulusTime, 'Freq', TrialData.RewardCueLeft(1,iTrial), TrialData.RewardCueLeft(2,iTrial));
                    RightSound = GenerateRiskCue(fs, StimulusTime, 'Freq', TrialData.RewardCueRight(1,iTrial), TrialData.RewardCueRight(2,iTrial));
                else
                    disp('StimulusTime in GUI should be a positive number. Empty track will be loaded.')
                end
                
                if TrialData.LightLeft(iTrial) == 0
                    LeftSound = [0];
                elseif TrialData.LightLeft(iTrial) == 1
                    RightSound = [0];
                end

                if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                    Player.loadWaveform(SoundIndex, LeftSound);
                    Player.loadWaveform(SoundIndex+1, RightSound);
                    Player.TriggerProfiles(SoundIndex, 1:2) = [SoundIndex SoundIndex+1];
                elseif isfield(BpodSystem.ModuleUSB, 'HiFi1')
                    Player.load(SoundIndex, [LeftSound; RightSound]);
                end
                
            case "CuedBlockITI"
                TrialData = BpodSystem.Data.Custom.TrialData;
                StimulusTime = TaskParameters.GUI.StimulusTime;
                                
                SoundIndex = 8;
                LeftSound = [];
                RightSound = [];
                if StimulusTime > 0
                    LeftSound = GenerateRiskCue(fs, StimulusTime, 'Freq', TrialData.RewardCueLeft(1,iTrial), TrialData.RewardCueLeft(2,iTrial));
                    RightSound = GenerateRiskCue(fs, StimulusTime, 'Freq', TrialData.RewardCueRight(1,iTrial), TrialData.RewardCueRight(2,iTrial));
                else
                    disp('StimulusTime in GUI should be a positive number. Empty track will be loaded.')
                end
                
                if TrialData.LightLeft(iTrial) == 0
                    LeftSound = [0];
                elseif TrialData.LightLeft(iTrial) == 1
                    RightSound = [0];
                end

                if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                    Player.loadWaveform(SoundIndex, LeftSound);
                    Player.loadWaveform(SoundIndex+1, RightSound);
                    Player.TriggerProfiles(SoundIndex, 1:2) = [SoundIndex SoundIndex+1];
                elseif isfield(BpodSystem.ModuleUSB, 'HiFi1')
                    Player.load(SoundIndex, [LeftSound; RightSound]);
                end

            case "CuedBlockTau"
                TrialData = BpodSystem.Data.Custom.TrialData;
                StimulusTime = TaskParameters.GUI.StimulusTime;
                                
                SoundIndex = 8;
                LeftSound = [];
                RightSound = [];
                if StimulusTime > 0
                    LeftSound = GenerateRiskCue(fs, StimulusTime, 'Freq', TrialData.RewardCueLeft(1,iTrial), TrialData.RewardCueLeft(2,iTrial));
                    RightSound = GenerateRiskCue(fs, StimulusTime, 'Freq', TrialData.RewardCueRight(1,iTrial), TrialData.RewardCueRight(2,iTrial));
                else
                    disp('StimulusTime in GUI should be a positive number. Empty track will be loaded.')
                end
                
                if TrialData.LightLeft(iTrial) == 0
                    LeftSound = [0];
                elseif TrialData.LightLeft(iTrial) == 1
                    RightSound = [0];
                end

                if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                    Player.loadWaveform(SoundIndex, LeftSound);
                    Player.loadWaveform(SoundIndex+1, RightSound);
                    Player.TriggerProfiles(SoundIndex, 1:2) = [SoundIndex SoundIndex+1];
                elseif isfield(BpodSystem.ModuleUSB, 'HiFi1')
                    Player.load(SoundIndex, [LeftSound; RightSound]);
                end
        end

    case 'Opto'
        %% Ch3
        if TaskParameters.GUI.Ch3Looped == 1
            Player.LoopDuration(3) = 20000; % 1hr = 3600s; 20000 > 5hr
            Player.LoopMode{3} = 'On';
        end

        % tonic
        SoundIndex = 11;
        TonicTrain = [];
        
        Voltage = TaskParameters.GUI.Ch3TonicVoltage;
        PulseNumber = TaskParameters.GUI.Ch3TonicPulseNumber;
        TrainFreq = TaskParameters.GUI.Ch3TonicTrainFreq;
        PulseWidth = TaskParameters.GUI.Ch3TonicPulseWidth;
        if all([Voltage, PulseNumber, TrainFreq, PulseWidth] > 0)
            if TaskParameters.GUI.Ch3TonicPoisson
                TonicTrain = Voltage * GeneratePoissonClickTrain(TrainFreq, PulseNumber ./ TrainFreq, fs, PulseWidth * fs);
                BpodSystem.Data.Custom.TrialData.Ch3TonicTrain{iTrial} = TonicTrain;
            else
                TonicTrain = Voltage * GenerateRegularClickTrain(TrainFreq, PulseNumber ./ TrainFreq, fs, PulseWidth * fs);
            end
        end

        if ~isempty(TonicTrain)
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                Player.loadWaveform(SoundIndex, TonicTrain);
            end
        end
        
        % phasic
        SoundIndex = 12;
        PhasicTrain = [];
        
        Voltage = TaskParameters.GUI.Ch3PhasicVoltage;
        PulseNumber = TaskParameters.GUI.Ch3PhasicPulseNumber;
        TrainFreq = TaskParameters.GUI.Ch3PhasicTrainFreq;
        PulseWidth = TaskParameters.GUI.Ch3PhasicPulseWidth;
        if all([Voltage, PulseNumber, TrainFreq, PulseWidth] > 0)
            PhasicTrain = Voltage * GenerateRegularClickTrain(TrainFreq, PulseNumber ./ TrainFreq, fs, PulseWidth * fs);
        end

        if ~isempty(PhasicTrain)
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                Player.loadWaveform(SoundIndex, PhasicTrain);
            end
        end

        %% Ch4
        if TaskParameters.GUI.Ch4Looped == 1
            Player.LoopDuration(4) = 20000; % 1hr = 3600s; 20000 > 5hr
            Player.LoopMode{4} = 'On';
        end

        % tonic
        SoundIndex = 13;
        TonicTrain = [];
        
        Voltage = TaskParameters.GUI.Ch4TonicVoltage;
        PulseNumber = TaskParameters.GUI.Ch4TonicPulseNumber;
        TrainFreq = TaskParameters.GUI.Ch4TonicTrainFreq;
        PulseWidth = TaskParameters.GUI.Ch4TonicPulseWidth;
        if all([Voltage, PulseNumber, TrainFreq, PulseWidth] > 0)
            if TaskParameters.GUI.Ch4TonicPoisson
                TonicTrain = Voltage * GeneratePoissonClickTrain(TrainFreq, PulseNumber ./ TrainFreq, fs, PulseWidth * fs);
                BpodSystem.Data.Custom.TrialData.Ch4TonicTrain{iTrial} = TonicTrain;
            else
                TonicTrain = Voltage * GenerateRegularClickTrain(TrainFreq, PulseNumber ./ TrainFreq, fs, PulseWidth * fs);
            end
        end

        if ~isempty(TonicTrain)
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                Player.loadWaveform(SoundIndex, TonicTrain);
            end
        end
        
        % phasic
        SoundIndex = 14;
        PhasicTrain = [];
        
        Voltage = TaskParameters.GUI.Ch4PhasicVoltage;
        PulseNumber = TaskParameters.GUI.Ch4PhasicPulseNumber;
        TrainFreq = TaskParameters.GUI.Ch4PhasicTrainFreq;
        PulseWidth = TaskParameters.GUI.Ch4PhasicPulseWidth;
        if all([Voltage, PulseNumber, TrainFreq, PulseWidth] > 0)
            PhasicTrain = Voltage * GenerateRegularClickTrain(TrainFreq, PulseNumber ./ TrainFreq, fs, PulseWidth * fs);
        end

        if ~isempty(PhasicTrain)
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                Player.loadWaveform(SoundIndex, PhasicTrain);
            end
        end
        
        %% opto + sound
        % opto-white noise
        % usually when opto (final setting), no white noise is used in
        % BrokeFixation, EarlyWithdrawl, IncorrectChoice. Even if so, 0.5s
        % is enough to signal error (e.g. Cued + Early Withdrawl)
        SoundIndex = 15;
        OptoWhiteNoise = rand(1, fs * 0.5) * 2 - 1;

        if ~isempty(OptoWhiteNoise)
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                Player.loadWaveform(SoundIndex, OptoWhiteNoise);
            end
        end
        
        % opto-0.5kHz
        % usually for NotBaited Feedback (in non-final settings). 0.1s is the usualy setting 
        SoundIndex = 16;
        OptoNotBaitedSound = GenerateRiskCue(fs, 0.1, 'Freq', 0.5, 0.5);
        
        if ~isempty(OptoNotBaitedSound)
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                Player.loadWaveform(SoundIndex, OptoNotBaitedSound);
            end
        end
        
        % opto-1kHz
        % usually for SkippedFeedback (in final settings, and StartNewTrialSound). 0.1s is the usualy setting 
        SoundIndex = 17;
        OptoSkippedFeedbackSound = GenerateRiskCue(fs, 0.1, 'Freq', 1, 1);

        if ~isempty(OptoSkippedFeedbackSound)
            if isfield(BpodSystem.ModuleUSB, 'WavePlayer1')
                Player.loadWaveform(SoundIndex, OptoSkippedFeedbackSound);
            end
        end
        
        %% trigger profile
        % only opto
        x = [0, 64, 11, 12];
        y = [0, 64, 13, 14];
        [X, Y] = meshgrid(x, y);
        x = reshape(X, 1, []);
        y = reshape(Y, 1, []);

        Player.TriggerProfiles(11:25, 3) = x(2:end);
        Player.TriggerProfiles(11:25, 4) = y(2:end);
                                              
        % opto + white noise
        p = reshape(X(1:3, 1:3), 1, []);
        q = reshape(Y(1:3, 1:3), 1, []);

        Player.TriggerProfiles(26:33, 1:2) = 15;
        Player.TriggerProfiles(26:33, 3) = p(2:end);
        Player.TriggerProfiles(26:33, 4) = q(2:end);
        
        % opto + 0.5kHz (only fore NotBaited)
        Player.TriggerProfiles(34:41, 1:2) = 16;
        Player.TriggerProfiles(34:41, 3) = p(2:end);
        Player.TriggerProfiles(34:41, 4) = q(2:end);
        
        % opto + 1kHz (only for SkippedFeedback)
        Player.TriggerProfiles(42:56, 1:2) = 17;
        Player.TriggerProfiles(42:56, 3) = x(2:end);
        Player.TriggerProfiles(42:56, 4) = y(2:end);
        
end % switch
end % function
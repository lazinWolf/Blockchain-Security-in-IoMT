classdef edgeSensor < handle
    properties
        DeviceID
        PatientID
        IsMalicious 
        AssignedFog
        PacketCount = 0 % Used to simulate Smart APT Attacks
    end
    
    methods
        function obj = edgeSensor(devID, patID, isMalicious, assignedFog)
            obj.DeviceID = devID; 
            obj.PatientID = patID;
            obj.IsMalicious = isMalicious; 
            obj.AssignedFog = assignedFog;
        end
        
        function [mqttFrame, vitalsPlaintext, ecgWave, isAttacked] = generateTransmission(obj, config)
            % Increment internal counter
            obj.PacketCount = obj.PacketCount + 1;
            isAttacked = false;
            
            % 1. GENERATE SENSOR READINGS (Normal State)
            vitalsPlaintext = struct('HR', randi([70, 85]), 'SpO2', randi([95, 100]), 'Temp', 36.5 + rand());
            
            % Generate Synthetic P-Q-R-S-T Medical Wave (15 data points)
            basePQRST = [0, 0.1, 0.15, 0, -0.2, 1.8, -0.4, 0, 0.1, 0.25, 0.3, 0.1, 0, 0, 0];
            ecgWave = basePQRST + (rand(1, 15) * 0.05 - 0.025); % Add subtle baseline noise
            
            % 2. THREAT INJECTION (Advanced Persistent Threat - APT)
            % The malicious node waits for 3 packets to trick the Fog into building 
            % a "normal" Z-Score baseline, AND THEN it attacks.
            if obj.IsMalicious && obj.PacketCount > 3 && rand() > 0.5
                isAttacked = true;
                
                if rand() > 0.5
                    % Obvious Attack (Complete Spoof, blocked by Rule Filter)
                    vitalsPlaintext.HR = 280; 
                    vitalsPlaintext.SpO2 = 20; 
                    ecgWave(6) = 4.5; % Massive Fibrillation Spike
                else
                    % Subtle Attack (Bypasses rules, gets caught by Z-Score AI)
                    vitalsPlaintext.HR = 130; 
                    ecgWave(6) = 2.5; % Elevated Spike
                end
            end
            
            % 3. ENCRYPT DATA & GENERATE METADATA (Data Foundation)
            packet = struct();
            packet.RecordID   = cryptoUtils.generateRecordID();
            packet.PatientID  = obj.PatientID;
            packet.Timestamp  = string(datetime('now'));
            packet.CipherText = cryptoUtils.simulateEncrypt(vitalsPlaintext);
            
            % 4. HAND OFF TO NETWORK LAYER (Clean separation!)
            topicStr = sprintf('hospital/icuw/fog%d/%s/vitals', obj.AssignedFog, obj.PatientID);
            mqttFrame = mqttProtocol.wrap(packet, topicStr, config);
        end
    end
end
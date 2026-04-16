classdef edgeSensor < handle
    properties
        DeviceID
        PatientID
        IsMalicious 
        AssignedFog 
    end
    
    methods
        function obj = edgeSensor(devID, patID, isMalicious, assignedFog)
            obj.DeviceID = devID; obj.PatientID = patID;
            obj.IsMalicious = isMalicious; obj.AssignedFog = assignedFog;
        end
        
        function [mqttFrame, vitalsPlaintext, ecgWave, isAttacked] = generateTransmission(obj, config)
            % 1. GENERATE BIOLOGY / SENSOR READINGS
            vitalsPlaintext = struct('HR', randi([70, 85]), 'SpO2', randi([95, 100]), 'Temp', 36.5 + rand());
            ecgWave = 0.5 * rand(1, 10); ecgWave(5) = 4.0 + rand();
            isAttacked = false;
            
            if obj.IsMalicious && rand() > 0.5
                isAttacked = true;
                if rand() > 0.5
                    vitalsPlaintext.HR = 280; vitalsPlaintext.SpO2 = 20; % Obvious Attack
                else
                    vitalsPlaintext.HR = 130; % Subtle Attack (Statistically anomalous)
                end
                ecgWave(5) = 18.0;              
            end
            
            % 2. ENCRYPT DATA & GENERATE METADATA (Data Foundation)
            packet = struct();
            packet.RecordID   = cryptoUtils.generateRecordID();
            packet.PatientID  = obj.PatientID;
            packet.Timestamp  = string(datetime('now'));
            packet.CipherText = cryptoUtils.simulateEncrypt(vitalsPlaintext);
            
            % 3. HAND OFF TO NETWORK LAYER (Clean separation!)
            topicStr = sprintf('hospital/icuw/fog%d/%s/vitals', obj.AssignedFog, obj.PatientID);
            mqttFrame = mqttProtocol.wrap(packet, topicStr, config);
        end
    end
end
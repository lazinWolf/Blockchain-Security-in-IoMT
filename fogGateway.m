classdef fogGateway < handle
    properties
        OffChainDB
        PatientHistory
    end
    
    methods
        function obj = fogGateway()
            obj.OffChainDB = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.PatientHistory = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end
        
        function [isSafe, dataHash, alertReason] = processData(obj, frame, config)
            alertReason = "None";
            
            % 1. NETWORK LAYER UNWRAP (Clean separation!)
            [isValid, packet, ~, ~] = mqttProtocol.unwrap(frame);
            if ~isValid
                isSafe = false; dataHash = ""; alertReason = "Invalid Network Protocol"; return;
            end
            
            % 2. DECRYPT APPLICATION DATA
            try
                vitals = cryptoUtils.simulateDecrypt(packet.CipherText);
            catch
                isSafe = false; dataHash = ""; alertReason = "Decryption Failed"; return;
            end
            
            % 3. Z-SCORE ANOMALY DETECTION
            patID = packet.PatientID;
            if vitals.HR < 30 || vitals.HR > 220 || vitals.SpO2 < 50
                isSafe = false; dataHash = ""; alertReason = "Rule Threshold Violation"; return;
            end
            
            if isKey(obj.PatientHistory, patID) && length(obj.PatientHistory(patID)) >= 3
                hist = obj.PatientHistory(patID);
                mu = mean(hist); sig = max(std(hist), 1); % Prevent div by zero
                zScore = abs(vitals.HR - mu) / sig;
                
                if zScore > config.zScoreThreshold
                    isSafe = false; dataHash = ""; 
                    alertReason = sprintf("Z-Score Anomaly (Z=%.2f, Baseline=%.1f)", zScore, mu);
                    return;
                end
            end
            
            % Update baseline
            if ~isKey(obj.PatientHistory, patID); obj.PatientHistory(patID) = []; end
            hist = [obj.PatientHistory(patID), vitals.HR];
            if length(hist) > config.historyWindow; hist = hist(2:end); end
            obj.PatientHistory(patID) = hist;
            
            % 4. SECURE OFF-CHAIN STORAGE & HASHING
            isSafe = true;
            obj.OffChainDB(packet.RecordID) = packet;
            dataHash = hash256(strcat(packet.RecordID, packet.CipherText));
        end
        
        function functionalErasure(obj)
            remove(obj.OffChainDB, keys(obj.OffChainDB));
            remove(obj.PatientHistory, keys(obj.PatientHistory));
        end
    end
end
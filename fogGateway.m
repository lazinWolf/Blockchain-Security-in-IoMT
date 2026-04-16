classdef fogGateway < handle
    properties
        OffChainDB
    end
    
    methods
        function obj = fogGateway()
            obj.OffChainDB = containers.Map('KeyType', 'double', 'ValueType', 'any');
        end
        
        function [isSafe, dataHash] = processData(obj, timeStep, vitals, patientID)
            % 1. RULE-BASED FILTER (Anomaly Detection)
            % Check if data falls within survivable human boundaries.
            % If an attacker spoofs the sensor with garbage values, block it.
            hrSafe   = (vitals.HR >= 30 && vitals.HR <= 220);
            spo2Safe = (vitals.SpO2 >= 50 && vitals.SpO2 <= 100);
            tempSafe = (vitals.Temp >= 30.0 && vitals.Temp <= 43.0);
            
            if ~(hrSafe && spo2Safe && tempSafe)
                isSafe = false; dataHash = "";
                return; % Drop malicious/corrupted packet
            end
            
            % 2. DPDP Off-Chain Storage (Data Minimization)
            isSafe = true;
            obj.OffChainDB(timeStep) = struct('Patient', patientID, 'Data', vitals);
            
            % 3. Cryptographic Hashing
            dataString = sprintf('Time:%d_Patient:%s_HR:%d_SpO2:%d_Temp:%.1f', ...
                                 timeStep, patientID, vitals.HR, vitals.SpO2, vitals.Temp);
            dataHash = hash256(dataString); % Using updated hash256
        end
        
        function functionalErasure(obj)
            remove(obj.OffChainDB, keys(obj.OffChainDB));
        end
    end
end
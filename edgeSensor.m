%% --- edgeSensor.m ---
classdef edgeSensor < handle
    properties
        DeviceID
        PatientID
        IsMalicious 
        AssignedFog 
    end
    
    methods
        function obj = edgeSensor(devID, patID, isMalicious, assignedFog)
            obj.DeviceID = devID;
            obj.PatientID = patID;
            obj.IsMalicious = isMalicious;
            obj.AssignedFog = assignedFog;
        end
        
        function [vitals, ecgWave, isAttacked] = readVitals(obj)
            % FORCE INITIALIZATION: Tell MATLAB 'vitals' is a struct immediately
            vitals = struct('HR', 0, 'SpO2', 0, 'Temp', 0);
            isAttacked = false;
            
            % 1. Generate normal Clinical Vitals
            vitals.HR   = randi([60, 100]);     
            vitals.SpO2 = randi([95, 100]);     
            vitals.Temp = 36.5 + rand();        
            
            % 2. Generate a 10-point visual ECG wave array
            ecgWave = 0.5 * rand(1, 10);
            ecgWave(5) = 4.0 + rand(); % QRS Peak
            
            % 3. Malicious Injection (Spoofing)
            if obj.IsMalicious && rand() > 0.5
                isAttacked = true;
                vitals.HR   = 280;              
                vitals.SpO2 = 20;               
                vitals.Temp = 46.0;             
                ecgWave(5) = 18.0;              
            end
        
        end
    end
end
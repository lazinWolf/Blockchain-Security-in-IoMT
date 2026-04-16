classdef securityTester < handle
    properties
        Fogs
        Cloud
    end
    
    methods
        function obj = securityTester(fogs, cloud)
            obj.Fogs = fogs;
            obj.Cloud = cloud;
        end
        
        %% 🔐 Tamper
        function [msg, beforeHR, afterHR] = tamperData(obj, fogIdx, key)
            fog = obj.Fogs{fogIdx};
            
            if ~isKey(fog.OffChainDB, key)
                msg = "Invalid key selected.";
                beforeHR = []; afterHR = [];
                return;
            end
            
            record = fog.OffChainDB(key);
            beforeHR = record.Data.HR;
            
            % Tamper
            record.Data.HR = beforeHR + 50;
            afterHR = record.Data.HR;
            
            fog.OffChainDB(key) = record;
            
            msg = sprintf("Tampered record t=%d (Fog %d)", key, fogIdx);
        end
        
        %% 🔍 Verify (search-based, correct)
        function msg = verifyData(obj, fogIdx, key)
            fog = obj.Fogs{fogIdx};
            
            if ~isKey(fog.OffChainDB, key)
                msg = "Data not found (possibly deleted).";
                return;
            end
            
            record = fog.OffChainDB(key);
            
            % Recompute hash
            dataString = sprintf('Time:%d_Patient:%s_HR:%d_SpO2:%d_Temp:%.1f', ...
                key, record.Patient, record.Data.HR, ...
                record.Data.SpO2, record.Data.Temp);
            
            newHash = hash256(dataString);
            
            % Search blockchain
            found = false;
            for i = 1:length(obj.Cloud.Chain)
                if strcmp(obj.Cloud.Chain(i).DataHash, newHash)
                    found = true;
                    break;
                end
            end
            
            if found
                msg = sprintf("✔ VERIFIED t=%d (Fog %d)\nHash: %s", ...
                    key, fogIdx, newHash(1:12));
            else
                msg = sprintf("🚨 TAMPERING DETECTED t=%d (Fog %d)\nNew Hash: %s", ...
                    key, fogIdx, newHash(1:12));
            end
        end
        
        %% 🧹 Delete
        function msg = deleteData(obj, fogIdx, key)
            fog = obj.Fogs{fogIdx};
            
            if isKey(fog.OffChainDB, key)
                remove(fog.OffChainDB, key);
                msg = sprintf("Deleted record t=%d (Fog %d, off-chain)", key, fogIdx);
            else
                msg = "Data already deleted.";
            end
        end
    end
end
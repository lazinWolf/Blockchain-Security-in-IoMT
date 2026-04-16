classdef securityTester < handle
    properties
        Fogs
        Cloud
    end
    
    methods
        function obj = securityTester(fogs, cloud)
            obj.Fogs = fogs; obj.Cloud = cloud;
        end
        
        function [msg, beforeHR, afterHR] = tamperData(obj, fogIdx, recordID)
            fog = obj.Fogs{fogIdx};
            if ~isKey(fog.OffChainDB, recordID)
                msg = "Invalid key selected."; beforeHR = []; afterHR = []; return;
            end
            
            % 1. Extract and Decrypt
            packet = fog.OffChainDB(recordID);
            vitals = cryptoUtils.simulateDecrypt(packet.CipherText);
            beforeHR = vitals.HR;
            
            % 2. Tamper Data
            vitals.HR = beforeHR + 50; 
            afterHR = vitals.HR;
            
            % 3. Re-Encrypt and Save
            packet.CipherText = cryptoUtils.simulateEncrypt(vitals);
            fog.OffChainDB(recordID) = packet;
            
            msg = sprintf("Tampered record %s (Fog %d)", recordID(1:8), fogIdx);
        end
        
        function msg = verifyData(obj, fogIdx, recordID)
            fog = obj.Fogs{fogIdx};
            if ~isKey(fog.OffChainDB, recordID)
                msg = "Data not found (possibly deleted)."; return;
            end
            
            packet = fog.OffChainDB(recordID);
            
            % Re-hash RecordID + CipherText to check against blockchain
            dataString = strcat(packet.RecordID, packet.CipherText);
            newHash = hash256(dataString);
            
            found = false;
            for i = 1:length(obj.Cloud.Chain)
                if strcmp(obj.Cloud.Chain(i).DataHash, newHash)
                    found = true; break;
                end
            end
            
            if found
                msg = sprintf("✔ VERIFIED %s\nHash: %s", recordID(1:8), newHash(1:12));
            else
                msg = sprintf("🚨 TAMPERING DETECTED %s\nNew Hash: %s", recordID(1:8), newHash(1:12));
            end
        end
        
        function msg = deleteData(obj, fogIdx, recordID)
            fog = obj.Fogs{fogIdx};
            if isKey(fog.OffChainDB, recordID)
                remove(fog.OffChainDB, recordID);
                msg = sprintf("Deleted record %s (Fog %d)", recordID(1:8), fogIdx);
            else
                msg = "Data already deleted.";
            end
        end
    end
end
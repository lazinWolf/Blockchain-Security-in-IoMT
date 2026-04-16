classdef securityUI < handle
    properties
        Tester, Fig, LogBox, RecordDropdown, FogDropdown, MetricsLabel
        verifyCount = 0, tamperDetected = 0, deleteCount = 0
    end
    
    methods
        function obj = securityUI(tester)
            obj.Tester = tester;
            obj.Fig = figure('Name','Security Testing Panel', 'Position',[300 200 520 450]);
            
            uicontrol('Style','text','String','Fog:', 'Position',[20 410 50 20]);
            fogLabels = arrayfun(@(i) sprintf('Fog %d', i), 1:length(obj.Tester.Fogs), 'UniformOutput', false);
            obj.FogDropdown = uicontrol('Style','popupmenu', 'Position',[70 410 100 25], 'String', fogLabels, 'Callback', @(~,~) obj.refreshRecords());
            
            uicontrol('Style','text','String','Record:', 'Position',[200 410 60 20]);
            obj.RecordDropdown = uicontrol('Style','popupmenu', 'Position',[260 410 120 25]);
            
            obj.MetricsLabel = uicontrol('Style','text', 'Position',[20 370 460 30], 'HorizontalAlignment','left', 'FontWeight','bold');
            obj.LogBox = uicontrol('Style','listbox', 'Position',[20 20 480 300], 'FontName','Courier', 'FontSize',10);
            
            uicontrol('Style','pushbutton','String','Tamper', 'Position',[20 330 140 30], 'Callback', @(~,~) obj.runTamper());
            uicontrol('Style','pushbutton','String','Verify', 'Position',[190 330 140 30], 'Callback', @(~,~) obj.runVerify());
            uicontrol('Style','pushbutton','String','Delete', 'Position',[360 330 140 30], 'Callback', @(~,~) obj.runDelete());
            
            obj.refreshRecords(); obj.updateMetrics();
        end
        
        function refreshRecords(obj)
            fogIdx = obj.FogDropdown.Value;
            keysList = obj.Tester.Fogs{fogIdx}.OffChainDB.keys;
            if isempty(keysList)
                obj.RecordDropdown.String = {'No Data'};
                obj.RecordDropdown.UserData = {};
            else
                % Show first 8 chars of UUID in UI, but store full UUID in UserData
                obj.RecordDropdown.String = cellfun(@(k) k(1:8), keysList, 'UniformOutput', false);
                obj.RecordDropdown.UserData = keysList;
            end
        end
        
        function [recordID, fogIdx] = getSelection(obj)
            fogIdx = obj.FogDropdown.Value;
            keysList = obj.RecordDropdown.UserData;
            if isempty(keysList)
                recordID = []; 
            else
                recordID = keysList{obj.RecordDropdown.Value}; 
            end
        end
        
        function log(obj, msg); obj.LogBox.String = [obj.LogBox.String; string(msg)]; end
        
        function updateMetrics(obj)
            total = length(obj.Tester.Fogs{obj.FogDropdown.Value}.OffChainDB.keys);
            obj.MetricsLabel.String = sprintf('Records: %d | Verified: %d | Tampered: %d | Deleted: %d', ...
                total, obj.verifyCount, obj.tamperDetected, obj.deleteCount);
        end
        
        function runTamper(obj)
            [recID, fogIdx] = obj.getSelection(); if isempty(recID); return; end
            [msg, b, a] = obj.Tester.tamperData(fogIdx, recID);
            obj.log(msg); obj.log(sprintf("HR: %d -> %d", b, a));
        end
        
        function runVerify(obj)
            [recID, fogIdx] = obj.getSelection(); if isempty(recID); return; end
            msg = obj.Tester.verifyData(fogIdx, recID); obj.log(msg);
            obj.verifyCount = obj.verifyCount + 1;
            if contains(msg, "TAMPERING"); obj.tamperDetected = obj.tamperDetected + 1; end
            obj.updateMetrics();
        end
        
        function runDelete(obj)
            [recID, fogIdx] = obj.getSelection(); if isempty(recID); return; end
            obj.log(obj.Tester.deleteData(fogIdx, recID));
            obj.deleteCount = obj.deleteCount + 1;
            obj.refreshRecords(); obj.updateMetrics();
        end
    end
end
classdef securityUI < handle
    properties
        Tester
        Fig
        LogBox
        RecordDropdown
        FogDropdown
        MetricsLabel
        
        % Metrics
        verifyCount = 0
        tamperDetected = 0
        deleteCount = 0
    end
    
    methods
        function obj = securityUI(tester)
            obj.Tester = tester;
            
            obj.Fig = figure('Name','Security Testing Panel', ...
                'Position',[300 200 520 450]);
            
            %% --- Fog Selector ---
            uicontrol('Style','text','String','Fog:', ...
                'Position',[20 410 50 20]);
            
            fogLabels = arrayfun(@(i) sprintf('Fog %d', i), ...
                1:length(obj.Tester.Fogs), 'UniformOutput', false);
            
            obj.FogDropdown = uicontrol('Style','popupmenu', ...
                'Position',[70 410 100 25], ...
                'String', fogLabels, ...
                'Callback', @(~,~) obj.refreshRecords());
            
            %% --- Record Selector ---
            uicontrol('Style','text','String','Record:', ...
                'Position',[200 410 60 20]);
            
            obj.RecordDropdown = uicontrol('Style','popupmenu', ...
                'Position',[260 410 120 25]);
            
            %% --- Metrics Display ---
            obj.MetricsLabel = uicontrol('Style','text', ...
                'Position',[20 370 460 30], ...
                'HorizontalAlignment','left', ...
                'FontWeight','bold');
            
            %% --- Log Box ---
            obj.LogBox = uicontrol('Style','listbox', ...
                'Position',[20 20 480 300], ...
                'FontName','Courier', ...
                'FontSize',10);
            
            %% --- Buttons ---
            uicontrol('Style','pushbutton','String','Tamper', ...
                'Position',[20 330 140 30], ...
                'Callback', @(~,~) obj.runTamper());
            
            uicontrol('Style','pushbutton','String','Verify', ...
                'Position',[190 330 140 30], ...
                'Callback', @(~,~) obj.runVerify());
            
            uicontrol('Style','pushbutton','String','Delete', ...
                'Position',[360 330 140 30], ...
                'Callback', @(~,~) obj.runDelete());
            
            obj.refreshRecords();
            obj.updateMetrics();
        end
        
        %% 🔄 Refresh Records
        function refreshRecords(obj)
            fogIdx = obj.FogDropdown.Value;
            fog = obj.Tester.Fogs{fogIdx};
            keysList = fog.OffChainDB.keys;
            
            if isempty(keysList)
                obj.RecordDropdown.String = {'No Data'};
                return;
            end
            
            labels = cellfun(@(k) sprintf('t=%d', k), keysList, ...
                'UniformOutput', false);
            
            obj.RecordDropdown.String = labels;
        end
        
        %% 🎯 Get Selection
        function [key, fogIdx] = getSelection(obj)
            fogIdx = obj.FogDropdown.Value;
            fog = obj.Tester.Fogs{fogIdx};
            keysList = fog.OffChainDB.keys;
            
            if isempty(keysList)
                key = [];
                return;
            end
            
            idx = obj.RecordDropdown.Value;
            key = keysList{idx};
        end
        
        %% 📝 Logging
        function log(obj, msg)
            current = obj.LogBox.String;
            obj.LogBox.String = [current; string(msg)];
            drawnow;
        end
        
        %% 📊 Update Metrics Display
        function updateMetrics(obj)
            fogIdx = obj.FogDropdown.Value;
            total = length(obj.Tester.Fogs{fogIdx}.OffChainDB.keys);
            
            obj.MetricsLabel.String = sprintf( ...
                'Records: %d | Verified: %d | Tampered: %d | Deleted: %d', ...
                total, obj.verifyCount, obj.tamperDetected, obj.deleteCount);
        end
        
        %% 🔐 Tamper
        function runTamper(obj)
            [key, fogIdx] = obj.getSelection();
            
            if isempty(key)
                obj.log("No valid record.");
                return;
            end
            
            obj.log("----- TAMPER -----");
            
            [msg, beforeHR, afterHR] = obj.Tester.tamperData(fogIdx, key);
            
            obj.log(msg);
            obj.log(sprintf("HR: %d → %d", beforeHR, afterHR));
            obj.log("------------------");
        end
        
        %% 🔍 Verify
        function runVerify(obj)
            [key, fogIdx] = obj.getSelection();
            
            if isempty(key)
                obj.log("No valid record.");
                return;
            end
            
            obj.log("----- VERIFY -----");
            
            msg = obj.Tester.verifyData(fogIdx, key);
            obj.log(msg);
            
            % Update metrics
            obj.verifyCount = obj.verifyCount + 1;
            if contains(msg, "TAMPERING")
                obj.tamperDetected = obj.tamperDetected + 1;
            end
            
            obj.updateMetrics();
            obj.log("------------------");
        end
        
        %% 🧹 Delete
        function runDelete(obj)
            [key, fogIdx] = obj.getSelection();
            
            if isempty(key)
                obj.log("No valid record.");
                return;
            end
            
            obj.log("----- DELETE -----");
            
            msg = obj.Tester.deleteData(fogIdx, key);
            obj.log(msg);
            
            obj.deleteCount = obj.deleteCount + 1;
            
            obj.refreshRecords();
            obj.updateMetrics();
            
            obj.log("------------------");
        end
    end
end
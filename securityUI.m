classdef securityUI < handle
    properties
        Tester, Fig, LogBox, RecordDropdown, FogDropdown, MetricsLabel
        TotalRecords = 0, VerifiedCount = 0, TamperedCount = 0, DeletedCount = 0
    end
    
    methods
        function obj = securityUI(tester)
            obj.Tester = tester;
            obj.Fig = figure('Name','V2.1 Security Command Center', 'Position',[300 200 550 480], 'Color', 'w');
            
            % Dropdowns
            uicontrol('Style','text','String','Select Fog:', 'Position',[20 440 80 20], 'BackgroundColor', 'w', 'FontWeight', 'bold');
            fogLabels = {'[ALL FOGS]'};
            for i=1:length(obj.Tester.Fogs); fogLabels{end+1} = sprintf('Fog %d', i); end
            obj.FogDropdown = uicontrol('Style','popupmenu', 'Position',[100 440 120 25], 'String', fogLabels, 'Callback', @(~,~) obj.refreshRecords());
            
            uicontrol('Style','text','String','Select Record:', 'Position',[240 440 90 20], 'BackgroundColor', 'w', 'FontWeight', 'bold');
            obj.RecordDropdown = uicontrol('Style','popupmenu', 'Position',[330 440 200 25]);
            
            % Metrics Panel
            obj.MetricsLabel = uicontrol('Style','text', 'Position',[20 390 510 30], 'BackgroundColor', [0.9 0.9 0.9], ...
                'HorizontalAlignment','center', 'FontWeight','bold', 'FontSize', 10);
            
            % Log Box
            obj.LogBox = uicontrol('Style','listbox', 'Position',[20 60 510 310], 'FontName','Courier', 'FontSize',10, ...
                'BackgroundColor', 'k', 'ForegroundColor', 'c');
            
            % Buttons
            uicontrol('Style','pushbutton','String','🚨 Tamper DB', 'Position',[20 20 160 30], 'Callback', @(~,~) obj.runTamper());
            uicontrol('Style','pushbutton','String','🛡️ Verify via Blockchain', 'Position',[195 20 160 30], 'Callback', @(~,~) obj.runVerify());
            uicontrol('Style','pushbutton','String','🗑️ GDPR Delete', 'Position',[370 20 160 30], 'Callback', @(~,~) obj.runDelete());
            
            obj.refreshRecords(); 
        end
        
        function refreshRecords(obj)
            val = obj.FogDropdown.Value;
            compiledList = {}; % Struct array holding {RecordID, FogIdx}
            
            if val == 1 % ALL FOGS SELECTED
                for f = 1:length(obj.Tester.Fogs)
                    keys = obj.Tester.Fogs{f}.OffChainDB.keys;
                    for k = 1:length(keys); compiledList{end+1} = struct('ID', keys{k}, 'Fog', f); end
                end
            else % SPECIFIC FOG SELECTED
                f = val - 1;
                keys = obj.Tester.Fogs{f}.OffChainDB.keys;
                for k = 1:length(keys); compiledList{end+1} = struct('ID', keys{k}, 'Fog', f); end
            end
            
            obj.TotalRecords = length(compiledList);
            
            if isempty(compiledList)
                obj.RecordDropdown.String = {'-- No Data Found --'};
                obj.RecordDropdown.UserData = {};
            else
                % Display string format: "Fog 3 | a8f9c1..."
                displayStrings = cellfun(@(x) sprintf('Fog %d | %s', x.Fog, x.ID(1:8)), compiledList, 'UniformOutput', false);
                obj.RecordDropdown.String = displayStrings;
                obj.RecordDropdown.UserData = compiledList; % Store underlying data
                obj.RecordDropdown.Value = 1; % Reset selection to top
            end
            obj.updateMetrics();
        end
        
        function selectedNode = getSelection(obj)
            list = obj.RecordDropdown.UserData;
            if isempty(list); selectedNode = []; else; selectedNode = list{obj.RecordDropdown.Value}; end
        end
        
        function log(obj, msg)
            obj.LogBox.String = [obj.LogBox.String; string(msg)];
            set(obj.LogBox, 'Value', length(obj.LogBox.String)); % Auto-scroll to bottom
        end
        
        function updateMetrics(obj)
            obj.MetricsLabel.String = sprintf('Active Records: %d  |  Verified: %d  |  Tampered: %d  |  Deleted: %d', ...
                obj.TotalRecords, obj.VerifiedCount, obj.TamperedCount, obj.DeletedCount);
        end
        
        function runTamper(obj)
            sel = obj.getSelection(); if isempty(sel); return; end
            [msg, b, a] = obj.Tester.tamperData(sel.Fog, sel.ID);
            obj.log(msg); obj.log(sprintf("   -> HR Altered: %d to %d (Re-encrypted)", b, a));
            obj.TamperedCount = obj.TamperedCount + 1; obj.updateMetrics();
        end
        
        function runVerify(obj)
            sel = obj.getSelection(); if isempty(sel); return; end
            msg = obj.Tester.verifyData(sel.Fog, sel.ID); obj.log(msg);
            obj.VerifiedCount = obj.VerifiedCount + 1; obj.updateMetrics();
        end
        
        function runDelete(obj)
            sel = obj.getSelection(); if isempty(sel); return; end
            obj.log(obj.Tester.deleteData(sel.Fog, sel.ID));
            obj.DeletedCount = obj.DeletedCount + 1;
            obj.refreshRecords(); % Will auto-update metrics
        end
    end
end
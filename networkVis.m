classdef networkVis < handle
    properties
        AxECG, AxNet, LogBox, BlockTable, HGraph
        Logs = {}
        NumEdge, NumFog, NumCloud
        
        % Continuous ECG Tracking
        GlobalTime = 0
        ECGBuffer_X = []
        ECGBuffer_Y = []
    end
    
    methods
        function obj = networkVis(numEdge, numFog, numCloud, sensors)
            obj.NumEdge = numEdge; obj.NumFog = numFog; obj.NumCloud = numCloud;
            
            % 1. MAIN FIGURE SETUP (Dark Cyber-Medical Theme)
            fig = figure('Name', 'IoMT Blockchain Security Dashboard (v2.1)', ...
                'Color', [0.08 0.08 0.1], 'Position', [50, 50, 1450, 850]);
            
            % 2. SPATIAL NETWORK TOPOLOGY (Left-to-Right Flow)
            s = []; t = []; names = {}; x_coords = []; y_coords =[];
            
            % Y-Spacing logic
            yEdge = linspace(10, 1, numEdge);
            yFog  = linspace(8, 3, numFog);
            yCloud= linspace(6, 5, numCloud);
            
            % Build Edge Nodes
            for i = 1:numEdge
                names{end+1} = sprintf('E%d', i);
                x_coords(end+1) = 1; y_coords(end+1) = yEdge(i);
                s(end+1) = i; 
                t(end+1) = numEdge + sensors{i}.AssignedFog; 
            end
            
            % Build Fog Nodes
            for i = 1:numFog
                names{end+1} = sprintf('FOG %d', i);
                x_coords(end+1) = 4; y_coords(end+1) = yFog(i);
                for c = 1:numCloud
                    s(end+1) = numEdge + i; t(end+1) = numEdge + numFog + c;
                end
            end
            
            % Build Cloud Nodes
            for i = 1:numCloud
                names{end+1} = sprintf('CLOUD %d', i);
                x_coords(end+1) = 7; y_coords(end+1) = yCloud(i);
                s(end+1) = numEdge + numFog + i;
                % Link clouds together for PBFT representation
                if i == numCloud
                    t(end+1) = numEdge + numFog + 1;
                else
                    t(end+1) = numEdge + numFog + i + 1; 
                end
            end
            
            % Plot Network
            obj.AxNet = subplot(4, 4, [2:4, 6:8, 10:12]); hold(obj.AxNet, 'on'); 
            set(obj.AxNet, 'Color', [0.08 0.08 0.1], 'XColor', 'none', 'YColor', 'none');
            title(obj.AxNet, 'Live Topology: Edge → Fog → Cloud', 'Color', 'w', 'FontSize', 14);
            
            netGraph = digraph(s, t, [], names);
            obj.HGraph = plot(obj.AxNet, netGraph, 'XData', x_coords, 'YData', y_coords, ...
                'NodeFontSize', 9, 'NodeFontWeight', 'bold', 'NodeLabelColor', 'w', ...
                'MarkerSize', 16, 'LineWidth', 1.2, 'EdgeColor', [0.3 0.3 0.35], 'EdgeAlpha', 0.5);
            
            % Color Nodes
            for i = 1:numEdge
                if sensors{i}.IsMalicious
                    highlight(obj.HGraph, i, 'NodeColor', [0.7 0.1 0.1]); % Dark Red
                else
                    highlight(obj.HGraph, i, 'NodeColor', [0.2 0.6 0.3]); % Green
                end
            end
            highlight(obj.HGraph, numEdge+1 : numEdge+numFog, 'NodeColor', [0.85 0.45 0.10], 'MarkerSize', 22); % Orange Fog
            highlight(obj.HGraph, numEdge+numFog+1 : numEdge+numFog+numCloud, 'NodeColor', [0.1 0.5 0.8], 'MarkerSize', 26); % Blue Cloud
            
            % 3. LIVE ECG MONITOR
            obj.AxECG = subplot(4, 4, [1, 5, 9]); hold(obj.AxECG, 'on'); 
            set(obj.AxECG, 'Color', 'k', 'XColor', [0.3 0.3 0.3], 'YColor', [0.3 0.3 0.3], 'GridColor', [0 1 0], 'GridAlpha', 0.2);
            title(obj.AxECG, 'Real-Time ECG Feed', 'Color', 'w', 'FontSize', 12);
            ylim(obj.AxECG, [-1.5 5.5]); ylabel(obj.AxECG, 'mV');
            grid(obj.AxECG, 'on');
            
            % 4. TERMINAL LOG BOX
            subplot(4, 4, [13, 14]); axis off;
            obj.LogBox = uicontrol('Style', 'listbox', 'Units', 'normalized', 'Position', [0.02 0.02 0.45 0.22], ...
                'FontSize', 10, 'FontName', 'Consolas', 'BackgroundColor', [0.05 0.05 0.05], ...
                'ForegroundColor', [0.2 0.9 0.2]); % Hacker Green text
            
            % 5. BLOCKCHAIN LEDGER TABLE
            subplot(4, 4, [15, 16]); axis off;
            obj.BlockTable = uitable('Units', 'normalized', 'Position', [0.49 0.02 0.49 0.22], ...
                'ColumnName', {'Block', 'Time', 'Data Hash (Ciphertext)', 'Prev Hash'}, ...
                'ColumnWidth', {45, 75, 230, 230}, 'RowName', [], ...
                'BackgroundColor', [0.1 0.1 0.1; 0.15 0.15 0.15], 'ForegroundColor', [0.4 0.8 1.0], ...
                'FontName', 'Consolas');
        end
        
        function plotLiveWave(obj, ecgWave, isAttacked)
            % Append to continuous buffer
            len = length(ecgWave);
            xVals = obj.GlobalTime : obj.GlobalTime + len - 1;
            
            obj.ECGBuffer_X = [obj.ECGBuffer_X, xVals];
            obj.ECGBuffer_Y = [obj.ECGBuffer_Y, ecgWave];
            
            % Keep only last 150 points for scrolling effect
            if length(obj.ECGBuffer_X) > 150
                obj.ECGBuffer_X = obj.ECGBuffer_X(end-149:end);
                obj.ECGBuffer_Y = obj.ECGBuffer_Y(end-149:end);
            end
            
            cla(obj.AxECG); % Clear axis
            if isAttacked
                plot(obj.AxECG, obj.ECGBuffer_X, obj.ECGBuffer_Y, 'r', 'LineWidth', 2.0);
            else
                plot(obj.AxECG, obj.ECGBuffer_X, obj.ECGBuffer_Y, 'Color', [0 1 0.5], 'LineWidth', 1.5);
            end
            
            obj.GlobalTime = obj.GlobalTime + len;
            xlim(obj.AxECG, [max(0, obj.GlobalTime-150), max(150, obj.GlobalTime)]);
        end
        
        function printLog(obj, msg)
            obj.Logs{end+1} = msg;
            if length(obj.Logs) > 15; obj.Logs(1) = []; end % Keep last 15 lines
            set(obj.LogBox, 'String', obj.Logs, 'Value', length(obj.Logs)); % Auto-scroll to bottom
        end
        
        function updateLedger(obj, chain)
            numBlocks = length(chain);
            tableData = cell(numBlocks, 4);
            for i = 1:numBlocks
                tableData{i, 1} = chain(i).Index;
                tsStr = char(chain(i).Timestamp);
                tableData{i, 2} = tsStr(12:19); % Show only HH:mm:ss for space
                tableData{i, 3} = char(chain(i).DataHash);
                tableData{i, 4} = char(chain(i).PrevHash);
            end
            % Show newest blocks at the top
            set(obj.BlockTable, 'Data', flipud(tableData));
        end
        
        function animateFlow(obj, sourceEdgeIdx, targetFogIdx, isSafe)
            actualFogIdx = obj.NumEdge + targetFogIdx;
            
            % 1. Edge to Fog Transmission
            highlight(obj.HGraph, sourceEdgeIdx, actualFogIdx, 'EdgeColor', [1 0.8 0], 'LineWidth', 3); % Yellow transmit
            drawnow; pause(0.15);
            
            if ~isSafe
                % Blocked at Fog
                highlight(obj.HGraph, actualFogIdx, 'NodeColor', 'r', 'MarkerSize', 28);
                highlight(obj.HGraph, sourceEdgeIdx, actualFogIdx, 'EdgeColor', 'r', 'LineWidth', 4);
                drawnow; pause(0.4); 
                
                % Reset
                highlight(obj.HGraph, actualFogIdx, 'NodeColor', [0.85 0.45 0.10], 'MarkerSize', 22);
                highlight(obj.HGraph, sourceEdgeIdx, actualFogIdx, 'EdgeColor', [0.3 0.3 0.35], 'LineWidth', 1.2);
            else
                % Passed Fog, Hash sent to Cloud
                cloudIdx = obj.NumEdge + obj.NumFog + 1 : obj.NumEdge + obj.NumFog + obj.NumCloud;
                
                highlight(obj.HGraph, sourceEdgeIdx, actualFogIdx, 'EdgeColor', [0 1 0.5], 'LineWidth', 2);
                highlight(obj.HGraph, actualFogIdx, cloudIdx, 'EdgeColor', [0 1 1], 'LineWidth', 3); % Cyan Hash send
                drawnow; pause(0.15);
                
                % Cloud Consensus Ring Animation
                if obj.NumCloud > 1
                    highlight(obj.HGraph, cloudIdx, cloudIdx([2:end, 1]), 'EdgeColor', [0.8 0.2 0.8], 'LineWidth', 4); % Purple PBFT
                    drawnow; pause(0.2);
                    highlight(obj.HGraph, cloudIdx, cloudIdx([2:end, 1]), 'EdgeColor', [0.3 0.3 0.35], 'LineWidth', 1.2);
                end
                
                % Reset All
                highlight(obj.HGraph, actualFogIdx, cloudIdx, 'EdgeColor', [0.3 0.3 0.35], 'LineWidth', 1.2);
                highlight(obj.HGraph, sourceEdgeIdx, actualFogIdx, 'EdgeColor', [0.3 0.3 0.35], 'LineWidth', 1.2);
            end
        end
    end
end
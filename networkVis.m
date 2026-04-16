%% --- networkVis.m ---
classdef networkVis < handle
    properties
        AxECG, AxNet, LogBox, BlockTable, HGraph, Logs = {}
        NumEdge, NumFog, NumCloud
        GlobalTime = 0
    end
    
    methods
        function obj = networkVis(numEdge, numFog, numCloud, sensors)
            obj.NumEdge = numEdge; obj.NumFog = numFog; obj.NumCloud = numCloud;
            
            % 1. Setup Dark Theme Figure
            fig = figure('Name', 'IoMT Network Spatial Visualizer', 'Color', [0.1 0.1 0.1], 'Position', [50, 50, 1400, 800]);
            
            % 2. Dynamic Network Topology Generation (ALGORITHMIC EDGES)
            s = []; t = []; names = {}; x_coords = []; y_coords =[];
            xEdgeVals = linspace(1, 10, numEdge);
            xFogVals = linspace(3, 8, numFog);
            xCloudVals = linspace(2, 9, numCloud);
            
            % Edge Nodes (Y = 1) -> Algorithmic assignment to Fog
            for i = 1:numEdge
                names{end+1} = sprintf('E%d', i);
                x_coords(end+1) = xEdgeVals(i); y_coords(end+1) = 1;
                s(end+1) = i; 
                t(end+1) = numEdge + sensors{i}.AssignedFog; % PERFECT SYNC WITH LOGIC
            end
            
            % Fog Nodes (Y = 3) -> Broadcast to all Clouds
            for i = 1:numFog
                names{end+1} = sprintf('FOG %d', i);
                x_coords(end+1) = xFogVals(i); y_coords(end+1) = 3;
                for c = 1:numCloud
                    s(end+1) = numEdge + i; t(end+1) = numEdge + numFog + c;
                end
            end
            
            % Cloud Nodes (Y = 5) -> P2P Consensus Ring
            for i = 1:numCloud
                names{end+1} = sprintf('CLOUD %d', i);
                x_coords(end+1) = xCloudVals(i); y_coords(end+1) = 5;
                s(end+1) = numEdge + numFog + i;
                if i == numCloud
                    t(end+1) = numEdge + numFog + 1;
                else
                    t(end+1) = numEdge + numFog + i + 1; 
                end
            end
            
            % 3. Draw Spatial Graph (Right Side)
            obj.AxNet = subplot(4, 4, [2:4, 6:8, 10:12]); hold(obj.AxNet, 'on'); axis(obj.AxNet, 'off');
            title(obj.AxNet, 'Spatial Network Topology', 'Color', 'w', 'FontSize', 14);
            
            netGraph = digraph(s, t, [], names);
            obj.HGraph = plot(obj.AxNet, netGraph, 'XData', x_coords, 'YData', y_coords, ...
                'NodeFontSize', 10, 'NodeFontWeight', 'bold', 'NodeLabelColor', 'w', ...
                'MarkerSize', 15, 'LineWidth', 1.0, 'EdgeColor', [0.4 0.4 0.4]);
            
            % Color Nodes
            for i = 1:numEdge
                if sensors{i}.IsMalicious
                    highlight(obj.HGraph, i, 'NodeColor', [0.8 0 0]); 
                else
                    highlight(obj.HGraph, i, 'NodeColor', [0.47 0.67 0.19]); 
                end
            end
            highlight(obj.HGraph, numEdge+1 : numEdge+numFog, 'NodeColor', [0.85 0.33 0.10]); 
            highlight(obj.HGraph, numEdge+numFog+1 : numEdge+numFog+numCloud, 'NodeColor', [0 0.45 0.74]); 
            
            % 4. Live ECG Panel (Top Left)
            obj.AxECG = subplot(4, 4, [1, 5, 9]); hold(obj.AxECG, 'on'); 
            set(obj.AxECG, 'Color', 'k', 'XColor', 'w', 'YColor', 'w');
            title(obj.AxECG, 'Live Sensor Transmission', 'Color', 'w', 'FontSize', 12);
            ylim(obj.AxECG, [-2 20]); ylabel(obj.AxECG, 'ECG (mV)');
            
            % 5. Terminal Log UI (Bottom Left)
            subplot(4, 4, [13, 14]); axis off;
            obj.LogBox = uicontrol('Style', 'listbox', 'Units', 'normalized', 'Position', [0.02 0.02 0.45 0.22], ...
                'FontSize', 11, 'BackgroundColor', 'k', 'ForegroundColor', [0 1 0]);
            
            % 6. Live Blockchain Ledger Table (Bottom Right)
            subplot(4, 4, [15, 16]); axis off;
            obj.BlockTable = uitable('Units', 'normalized', 'Position', [0.50 0.02 0.48 0.22], ...
                'ColumnName', {'Block', 'Time', 'Data Hash (SHA-256)', 'Prev Hash'}, ...
                'ColumnWidth', {50, 80, 220, 220}, 'RowName', [], ...
                'BackgroundColor', [0.1 0.1 0.1; 0.15 0.15 0.15], 'ForegroundColor', 'c');
        end
        
        function plotLiveWave(obj, ecgWave, isAttacked)
            % Animate the 10-point wave scrolling across the screen
            startT = obj.GlobalTime;
            xVals = startT : startT+9;
            
            if isAttacked
                plot(obj.AxECG, xVals, ecgWave, 'r', 'LineWidth', 2);
                plot(obj.AxECG, xVals(5), ecgWave(5), 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8);
            else
                plot(obj.AxECG, xVals, ecgWave, 'c', 'LineWidth', 1.5);
            end
            
            obj.GlobalTime = obj.GlobalTime + 10;
            xlim(obj.AxECG, [max(0, obj.GlobalTime-100), max(100, obj.GlobalTime)]);
        end
        
        function printLog(obj, msg)
            disp(msg); % Terminal Output
            obj.Logs{end+1} = msg;
            if length(obj.Logs) > 10; obj.Logs(1) = []; end
            set(obj.LogBox, 'String', obj.Logs, 'Value', length(obj.Logs));
        end
        
        function updateLedger(obj, chain)
            % Convert the blockchain struct array into a cell array for the UI table
            numBlocks = length(chain);
            tableData = cell(numBlocks, 4);
            
            for i = 1:numBlocks
                tableData{i, 1} = chain(i).Index;
                
                % CONVERT STRINGS TO CHARS: Fixes the 'set Data' error
                % 1. Timestamp (converted to char)
                tsStr = char(chain(i).Timestamp);
                tableData{i, 2} = tsStr(1:min(10, end)); 
                
                % 2. DataHash (converted to char)
                tableData{i, 3} = char(chain(i).DataHash);
                
                % 3. PrevHash (converted to char)
                tableData{i, 4} = char(chain(i).PrevHash);
            end
            
            % Flip the data so the newest blocks appear at the top
            set(obj.BlockTable, 'Data', flipud(tableData));
        end
        
        function animateFlow(obj, sourceEdgeIdx, targetFogIdx, isSafe)
            actualFogIdx = obj.NumEdge + targetFogIdx;
            
            % 1. Edge -> Fog Pulse (Green)
            highlight(obj.HGraph, sourceEdgeIdx, actualFogIdx, 'EdgeColor', 'g', 'LineWidth', 4);
            pause(0.15);
            
            if ~isSafe
                % MALWARE DETECTED: Fog Node turns Red
                highlight(obj.HGraph, actualFogIdx, 'NodeColor', 'r', 'MarkerSize', 25);
                t_alert = text(obj.AxNet, obj.HGraph.XData(actualFogIdx), obj.HGraph.YData(actualFogIdx)-0.4, ...
                    '⚠ BLOCKED', 'Color', 'r', 'FontSize', 12, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
                pause(0.5); delete(t_alert);
                highlight(obj.HGraph, actualFogIdx, 'NodeColor', [0.85 0.33 0.10], 'MarkerSize', 15);
            else
                % DATA SAFE: Fog -> Cloud Broadcast (Cyan)
                cloudIdx = obj.NumEdge + obj.NumFog + 1 : obj.NumEdge + obj.NumFog + obj.NumCloud;
                highlight(obj.HGraph, actualFogIdx, cloudIdx, 'EdgeColor', 'c', 'LineWidth', 3);
                pause(0.15);
                
                % Cloud -> Cloud Consensus Pulse (Magenta)
                highlight(obj.HGraph, cloudIdx, cloudIdx([2:end, 1]), 'EdgeColor', 'm', 'LineWidth', 4);
                pause(0.3);
                
                % Reset Cloud Ring
                highlight(obj.HGraph, cloudIdx, cloudIdx([2:end, 1]), 'EdgeColor', [0.4 0.4 0.4], 'LineWidth', 1);
                % Reset Fog-Cloud Broadcast lines
                highlight(obj.HGraph, actualFogIdx, cloudIdx, 'EdgeColor', [0.4 0.4 0.4], 'LineWidth', 1);
            end
            
            % Reset the initial Edge -> Fog pulse line
            highlight(obj.HGraph, sourceEdgeIdx, actualFogIdx, 'EdgeColor', [0.4 0.4 0.4], 'LineWidth', 1);
        end
    end
end
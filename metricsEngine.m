classdef metricsEngine < handle
    properties
        TotalPackets = 0; TotalAttacks = 0;
        CaughtByRule = 0; CaughtByZScore = 0;
        
        OffChainBytes = 0; OnChainBytes = 0;
        EdgeLatencies = []; FogLatencies = [];
        
        % For Time-Series plotting
        HistoryOffChain = []; HistoryOnChain = [];
    end
    
    methods
        function logEdge(obj, latency_ms, isAttacked)
            obj.TotalPackets = obj.TotalPackets + 1;
            obj.EdgeLatencies(end+1) = latency_ms;
            if isAttacked; obj.TotalAttacks = obj.TotalAttacks + 1; end
        end
        
        function logFog(obj, latency_ms, isSafe, alertReason, frame)
            obj.FogLatencies(end+1) = latency_ms;
            
            if ~isSafe
                if contains(alertReason, "Rule"); obj.CaughtByRule = obj.CaughtByRule + 1;
                elseif contains(alertReason, "Z-Score"); obj.CaughtByZScore = obj.CaughtByZScore + 1; end
            else
                payloadBytes = length(frame.Payload.CipherText) + length(frame.Payload.RecordID);
                obj.OffChainBytes = obj.OffChainBytes + frame.HeaderBytes + payloadBytes;
                obj.OnChainBytes = obj.OnChainBytes + 32; 
            end
            
            % Track cumulative growth
            obj.HistoryOffChain(end+1) = obj.OffChainBytes;
            obj.HistoryOnChain(end+1) = obj.OnChainBytes;
        end
        
        function generateReport(obj)
            % Clean up any massive spikes (e.g., initial MATLAB compilation delays)
            cleanEdge = min(obj.EdgeLatencies, mean(obj.EdgeLatencies) + 3*std(obj.EdgeLatencies));
            cleanFog = min(obj.FogLatencies, mean(obj.FogLatencies) + 3*std(obj.FogLatencies));
            
            fig = figure('Name', 'V2.1 Metrics Dashboard', 'Color', 'w', 'Position', [100, 100, 1200, 400]);
            
            % Plot 1: Cumulative Storage (Area Chart)
            subplot(1, 3, 1);
            x = 1:length(obj.HistoryOffChain);
            fill([x, fliplr(x)], [obj.HistoryOffChain, zeros(1, length(x))], [0.2 0.6 0.8], 'FaceAlpha', 0.5, 'EdgeColor', 'none'); hold on;
            fill([x, fliplr(x)], [obj.HistoryOnChain, zeros(1, length(x))], [0.8 0.2 0.2], 'FaceAlpha', 0.8, 'EdgeColor', 'none');
            legend('Off-Chain DB (Raw JSON)', 'On-Chain (Blockchain Hashes)', 'Location', 'northwest');
            xlabel('Packets Processed'); ylabel('Cumulative Storage (Bytes)'); title('Hybrid Storage Growth'); grid on;
            
            % Plot 2: Computation Latency
            subplot(1, 3, 2);
            plot(1:obj.TotalPackets, cleanEdge, '-o', 'Color', [0 0.45 0.74], 'LineWidth', 1.5, 'MarkerSize', 4); hold on;
            plot(1:obj.TotalPackets, cleanFog, '-s', 'Color', [0.85 0.33 0.1], 'LineWidth', 1.5, 'MarkerSize', 4);
            xlabel('Packet Sequence'); ylabel('Latency (ms)'); title('Device Compute Overhead');
            legend('Edge (Crypt/Wrap)', 'Fog (AI/Hash)', 'Location', 'northeast'); grid on;
            
            % Plot 3: Threat Mitigation Pie Chart
            subplot(1, 3, 3);
            safeCount = max(0, obj.TotalPackets - obj.TotalAttacks);
            labels = {}; data = []; colors = [];
            
            if safeCount > 0; data(end+1)=safeCount; labels{end+1}='Safe/Valid'; colors = [colors; 0.47 0.67 0.19]; end
            if obj.CaughtByRule > 0; data(end+1)=obj.CaughtByRule; labels{end+1}='Rule-Blocked'; colors = [colors; 0.85 0.33 0.1]; end
            if obj.CaughtByZScore > 0; data(end+1)=obj.CaughtByZScore; labels{end+1}='AI-Blocked'; colors = [colors; 0.49 0.18 0.56]; end
            
            if ~isempty(data)
                p = pie(data);
                title('Threat Mitigation Breakdown');
                % Apply custom professional colors
                colormap(colors);
                for i = 2:2:length(p); p(i).FontSize = 10; p(i).FontWeight = 'bold'; end
            end
        end
    end
end
classdef metricsEngine < handle
    properties
        TotalPackets = 0
        TotalAttacks = 0
        
        % Security Stats
        CaughtByRule = 0
        CaughtByZScore = 0
        CaughtByCrypto = 0
        
        % Storage Stats (Change #4)
        OffChainBytes = 0
        OnChainBytes = 0
        
        % Latency/Compute Stats (Arrays to track over time)
        EdgeLatencies = []
        FogLatencies = []
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
                if contains(alertReason, "Rule Threshold")
                    obj.CaughtByRule = obj.CaughtByRule + 1;
                elseif contains(alertReason, "Z-Score")
                    obj.CaughtByZScore = obj.CaughtByZScore + 1;
                elseif contains(alertReason, "Decryption")
                    obj.CaughtByCrypto = obj.CaughtByCrypto + 1;
                end
            else
                % Storage Tracking (Change #4)
                % Off-chain: JSON Ciphertext + UUID + MQTT Headers
                payloadBytes = length(frame.Payload.CipherText) + length(frame.Payload.RecordID);
                obj.OffChainBytes = obj.OffChainBytes + frame.HeaderBytes + payloadBytes;
                
                % On-chain: SHA-256 hash is always 256 bits (32 bytes)
                obj.OnChainBytes = obj.OnChainBytes + 32; 
            end
        end
        
        function generateReport(obj)
            % Print to console
            fprintf('\n=================================================\n');
            fprintf('📊 SIMULATION METRICS REPORT\n');
            fprintf('=================================================\n');
            fprintf('Network Traffic   : %d Packets Transmitted\n', obj.TotalPackets);
            fprintf('Attacks Generated : %d Malicious Injections\n', obj.TotalAttacks);
            fprintf('Anomalies Blocked : %d (Rules: %d | Z-Score: %d)\n', ...
                (obj.CaughtByRule + obj.CaughtByZScore), obj.CaughtByRule, obj.CaughtByZScore);
            fprintf('Avg Edge Compute  : %.2f ms (Encryption & Framing)\n', mean(obj.EdgeLatencies));
            fprintf('Avg Fog Compute   : %.2f ms (Decryption, AI, Hashing)\n', mean(obj.FogLatencies));
            fprintf('Storage Saved     : %.2f KB (Off-Chain: %d B | On-Chain: %d B)\n', ...
                (obj.OffChainBytes - obj.OnChainBytes)/1024, obj.OffChainBytes, obj.OnChainBytes);
            fprintf('=================================================\n\n');
            
            % Generate Visual Dashboard
            fig = figure('Name', 'Simulation Metrics Dashboard', 'Color', 'w', 'Position', [150, 150, 1000, 400]);
            
            % Plot 1: Storage Comparison
            subplot(1, 3, 1);
            b = bar([1, 2], [obj.OffChainBytes, obj.OnChainBytes], 'FaceColor', 'flat');
            b.CData(1,:) = [0.2 0.6 0.8]; b.CData(2,:) = [0.8 0.2 0.2];
            set(gca, 'XTickLabel', {'Off-Chain (Fog)', 'On-Chain (Cloud)'});
            ylabel('Storage Size (Bytes)'); title('Hybrid Storage Optimization');
            grid on;
            
            % Plot 2: Latency Benchmark
            subplot(1, 3, 2);
            plot(1:obj.TotalPackets, obj.EdgeLatencies, '-o', 'LineWidth', 1.5, 'DisplayName', 'Edge (Crypt)');
            hold on;
            plot(1:obj.TotalPackets, obj.FogLatencies, '-s', 'LineWidth', 1.5, 'DisplayName', 'Fog (AI+Hash)');
            xlabel('Packet Sequence'); ylabel('Latency (ms)'); title('Computational Overhead');
            legend('Location', 'best'); grid on;
            
            % Plot 3: Threat Detection
            subplot(1, 3, 3);
            pie([obj.CaughtByRule, obj.CaughtByZScore, max(0.001, obj.TotalPackets - obj.TotalAttacks)], ...
                {'Rule-Based', 'Z-Score AI', 'Normal/Safe'});
            title('Threat Detection Distribution');
        end
    end
end
classdef mqttBroker < handle
    properties
        Subscriptions % Map of Topic Patterns -> Fog Objects
        Config
        Metrics % Reference to MetricsEngine
        UI      % Reference to Visualizer
        Cloud   % Reference to Blockchain
    end
    
    methods
        function obj = mqttBroker(config, metricsEngine, ui, cloud)
            obj.Subscriptions = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.Config = config;
            obj.Metrics = metricsEngine;
            obj.UI = ui;
            obj.Cloud = cloud;
        end
        
        function subscribe(obj, topicFilter, subscriberObj)
            % Register a Fog node to a specific topic pattern (e.g., 'hospital/icuw/fog1/#')
            obj.Subscriptions(topicFilter) = subscriberObj;
        end
        
        function publish(obj, activeSensorIdx, mqttFrame)
            topic = mqttFrame.Topic;
            
            keysList = keys(obj.Subscriptions);
            delivered = false;
            
            for i = 1:length(keysList)
                subPattern = keysList{i};
                
                % FIX: Remove ONLY the '#' so the trailing slash remains.
                % e.g., 'hospital/icuw/fog1/' (This stops fog1 from matching fog10)
                baseTopic = strrep(subPattern, '#', ''); 
                
                if startsWith(topic, baseTopic)
                    targetFog = obj.Subscriptions(subPattern);
                    delivered = true;
                    
                    % 1. FOG PROCESSES DATA
                    tic; 
                    [isSafe, dataHash, alertReason] = targetFog.processData(mqttFrame, obj.Config);
                    fogLatency = toc * 1000;
                    
                    obj.Metrics.logFog(fogLatency, isSafe, alertReason, mqttFrame);
                    
                    % 2. CLOUD & LOGGING
                    if ~isSafe
                        obj.UI.printLog(sprintf('    >> [SECURITY ALERT] Dropped: %s', alertReason));
                    else
                        obj.UI.printLog(sprintf('    >> [FOG] Z-Score OK. Overhead: %d bytes. Hash -> %s', ...
                            mqttFrame.HeaderBytes, dataHash(1:8)));
                        
                        obj.Cloud.addBlock(dataHash);
                        obj.UI.updateLedger(obj.Cloud.Chain);
                    end
                    
                    % FIX: Safely extract the exact Fog number using regex tokens
                    tokens = regexp(topic, 'fog(\d+)/', 'tokens', 'once');
                    fogIdx = str2double(tokens{1});
                    
                    % Trigger UI Animation
                    obj.UI.animateFlow(activeSensorIdx, fogIdx, isSafe);
                end
            end
            
            if ~delivered
                obj.UI.printLog(sprintf('[BROKER] Message on topic %s had no subscribers. Dropped.', topic));
            end
        end
    end
end
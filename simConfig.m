function config = SimConfig()
    config = struct();
    
    % Network Topology
    config.numEdgeNodes     = 12;  
    config.numFogNodes      = 5;   
    config.numCloudNodes    = 1;   
    config.numTimeSteps     = 30;  
    config.maliciousPercent = 40;  
    
    % MQTT Protocol Specs
    config.mqttQoS          = 1;   % At least once delivery
    config.mqttBaseHeader   = 2;   % 2 bytes fixed header
    
    % AI / Statistical Anomaly Detection
    config.zScoreThreshold  = 3.0; % > 3 standard deviations = Anomaly
    config.historyWindow    = 5;   % Keep last 5 safe readings to calculate baseline
end
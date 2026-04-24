function config = simConfig()
    config = struct();
    
    % Network Topology
    config.numEdgeNodes     = 100;  
    config.numFogNodes      = 20;   
    config.numCloudNodes    = 1;   
    config.numTimeSteps     = 30;  
    config.maliciousPercent = 40;  
    
    % MQTT Protocol Specs
    config.mqttQoS          = 1;   % At least once delivery
    config.mqttBaseHeader   = 2;   % 2 bytes fixed header
    
    % AI / Statistical Anomaly Detection
    config.zScoreThreshold  = 3.0; % > 3 std = Anomaly
    config.historyWindow    = 5;   % last n readings baseline
end
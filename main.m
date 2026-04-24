clc; clear; close all;

%% 1. INITIALIZATION 
config = simConfig(); % Ensure this matches your filename (simConfig vs SimConfig)
metrics = metricsEngine();

fprintf('--- INITIALIZING NETWORK ---\n');
fprintf('Edge Nodes: %d | Fog Nodes: %d | Cloud Nodes: %d\n', config.numEdgeNodes, config.numFogNodes, config.numCloudNodes);
fprintf('Malicious Node Probability: %d%%\n\n', config.maliciousPercent);

% Init Edge
sensors = cell(1, config.numEdgeNodes);
for i = 1:config.numEdgeNodes
    isMal = (rand() * 100) < config.maliciousPercent; 
    assignedFog = mod(i-1, config.numFogNodes) + 1; 
    sensors{i} = edgeSensor(sprintf('DEV_%d', i), sprintf('PAT_%d', i), isMal, assignedFog);
end

% Init Fog & Cloud
fogs = cell(1, config.numFogNodes);
for i = 1:config.numFogNodes; fogs{i} = fogGateway(); end
cloud = cloudBlockchain();

% Init UI
ui = networkVis(config.numEdgeNodes, config.numFogNodes, config.numCloudNodes, sensors);

%% 1.1 SETUP MQTT BROKER (PUB/SUB)
broker = mqttBroker(config, metrics, ui, cloud);

% Fogs SUBSCRIBE to the Broker
for i = 1:config.numFogNodes
    % Fog i subscribes to all vitals coming to its assigned gateway
    topicFilter = sprintf('hospital/icuw/fog%d/#', i);
    broker.subscribe(topicFilter, fogs{i});
end

%% 2. RUN SIMULATION LOOP
ui.printLog('[SYSTEM] Network Online. Commencing MQTT Data Flow...');

% --- JVM WARMUP (Prevents Latency Spike on Packet 1) ---
cryptoUtils.generateRecordID();
cryptoUtils.simulateEncrypt(struct('HR', 75, 'SpO2', 98, 'Temp', 36.5));
java.security.MessageDigest.getInstance('SHA-256');
% -------------------------------------------------------

for t = 1:config.numTimeSteps
    activeSensorIdx = randi([1, config.numEdgeNodes]);
    activeSensor = sensors{activeSensorIdx};
    
    % --- TIER 1: EDGE MQTT TRANSMISSION ---
    tic; % START EDGE TIMER
    [mqttFrame, vitalsPlaintext, ecgWave, isAttacked] = activeSensor.generateTransmission(config);
    edgeLatency = toc * 1000; % Convert to ms
    
    metrics.logEdge(edgeLatency, isAttacked); % LOG METRICS
    ui.plotLiveWave(ecgWave, isAttacked);
    
    shortUUID = mqttFrame.Payload.RecordID(1:8);
    topic = mqttFrame.Topic;
    
    if isAttacked
        ui.printLog(sprintf('[-] %s PUBLISHED Spoofed MQTT [%s] on %s', activeSensor.DeviceID, shortUUID, topic));
    else
        ui.printLog(sprintf('[+] %s PUBLISHED Secure MQTT [%s] on %s', activeSensor.DeviceID, shortUUID, topic));
    end
    
    % --- TIER 2 & 3: MQTT BROKER ROUTES THE MESSAGE ---
    % The Broker automatically triggers the Fog evaluation, Blockchain logic, and UI animations.
    broker.publish(activeSensorIdx, mqttFrame);
    
    drawnow; pause(0.5); 
end

%% 3. GENERATE RESULTS REPORT
metrics.generateReport();

%% 4. SECURITY TEST PANEL
tester = securityTester(fogs, cloud);
secUI  = securityUI(tester);
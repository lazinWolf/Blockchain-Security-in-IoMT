clc; clear; close all;

%% 1. INITIALIZATION 
config = simConfig();
metrics = metricsEngine(); % Initialize the new Metrics Engine

fprintf('--- INITIALIZING NETWORK ---\n');
fprintf('Edge Nodes: %d | Fog Nodes: %d | Cloud Nodes: %d\n', config.numEdgeNodes, config.numFogNodes, config.numCloudNodes);
fprintf('Malicious Node Probability: %d%%\n\n', config.maliciousPercent);

sensors = cell(1, config.numEdgeNodes);
for i = 1:config.numEdgeNodes
    isMal = (rand() * 100) < config.maliciousPercent; 
    assignedFog = mod(i-1, config.numFogNodes) + 1; 
    sensors{i} = edgeSensor(sprintf('DEV_%d', i), sprintf('PAT_%d', i), isMal, assignedFog);
end

fogs = cell(1, config.numFogNodes);
for i = 1:config.numFogNodes; fogs{i} = fogGateway(); end

cloud = cloudBlockchain();
ui    = networkVis(config.numEdgeNodes, config.numFogNodes, config.numCloudNodes, sensors);

%% 2. RUN SIMULATION LOOP
ui.printLog('[SYSTEM] Network Online. Commencing MQTT Data Flow...');

for t = 1:config.numTimeSteps
    activeSensorIdx = randi([1, config.numEdgeNodes]);
    activeSensor = sensors{activeSensorIdx};
    targetFog = fogs{activeSensor.AssignedFog};
    
    % --- TIER 1: EDGE MQTT TRANSMISSION ---
    tic; % START EDGE TIMER
    [mqttFrame, vitalsPlaintext, ecgWave, isAttacked] = activeSensor.generateTransmission(config);
    edgeLatency = toc * 1000; % Convert to ms
    
    metrics.logEdge(edgeLatency, isAttacked); % LOG METRICS
    
    ui.plotLiveWave(ecgWave, isAttacked);
    shortUUID = mqttFrame.Payload.RecordID(1:8);
    topic = mqttFrame.Topic;
    
    if isAttacked
        ui.printLog(sprintf('[-] %s sent Spoofed MQTT [%s] on %s', activeSensor.DeviceID, shortUUID, topic));
    else
        ui.printLog(sprintf('[+] %s sent Secure MQTT [%s] on %s', activeSensor.DeviceID, shortUUID, topic));
    end
    
    % --- TIER 2: FOG Z-SCORE & GATEKEEPER ---
    tic; % START FOG TIMER
    [isSafe, dataHash, alertReason] = targetFog.processData(mqttFrame, config);
    fogLatency = toc * 1000; % Convert to ms
    
    metrics.logFog(fogLatency, isSafe, alertReason, mqttFrame); % LOG METRICS
    
    if ~isSafe
        ui.printLog(sprintf('    >> [SECURITY ALERT] Dropped: %s', alertReason));
    else
        ui.printLog(sprintf('    >> [FOG %d] Z-Score OK. Overhead: %d bytes. Broadcast Hash -> %s', ...
            activeSensor.AssignedFog, mqttFrame.HeaderBytes, dataHash(1:8)));
        
        % --- TIER 3: CLOUD BLOCKCHAIN ---
        cloud.addBlock(dataHash);
        ui.updateLedger(cloud.Chain);
    end
    
    ui.animateFlow(activeSensorIdx, activeSensor.AssignedFog, isSafe);
    drawnow; pause(0.5); 
end

%% 3. GENERATE RESULTS REPORT
metrics.generateReport();

%% 4. SECURITY TEST PANEL
tester = securityTester(fogs, cloud);
secUI  = securityUI(tester);
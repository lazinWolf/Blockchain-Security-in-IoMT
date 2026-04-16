
% main.m

clc; clear; close all;

%% 1. CONFIGURABLE PARAMETERS
numEdgeNodes     = 12;  % Total number of IoMT Sensors
maliciousPercent = 40;  % Percentage of sensors that are hacked
numFogNodes      = 5;   % Number of Hospital Gateways
numCloudNodes    = 1;   % Number of Blockchain Consensus Nodes
numTimeSteps     = 30;  % Total simulation ticks

fprintf('--- INITIALIZING NETWORK ---\n');
fprintf('Edge Nodes: %d | Fog Nodes: %d | Cloud Nodes: %d\n', numEdgeNodes, numFogNodes, numCloudNodes);
fprintf('Malicious Node Probability: %d%%\n\n', maliciousPercent);

%% 2. Initialize System Components (Algorithmic Load Balancing)
sensors = cell(1, numEdgeNodes);
for i = 1:numEdgeNodes
    isMal = (rand() * 100) < maliciousPercent; 
    
    % ALGORITHMIC ASSIGNMENT: Round-robin distribution to Fog Gateways
    % e.g., if 4 fogs: Sensor 1->Fog 1, Sensor 5->Fog 1, Sensor 6->Fog 2
    assignedFog = mod(i-1, numFogNodes) + 1; 
    
    sensors{i} = edgeSensor(sprintf('DEV_%d', i), sprintf('PAT_%d', i), isMal, assignedFog);
end

fogs = cell(1, numFogNodes);
for i = 1:numFogNodes; fogs{i} = fogGateway(); end

cloud = cloudBlockchain();
ui    = networkVis(numEdgeNodes, numFogNodes, numCloudNodes, sensors);

%% 3. Run Simulation Loop
ui.printLog('[SYSTEM] Network Online. Commencing Data Flow...');

for t = 1:numTimeSteps
    
    % Pick a random sensor to transmit its 10-millisecond packet
    activeSensorIdx = randi([1, numEdgeNodes]);
    activeSensor = sensors{activeSensorIdx};
    
    % Follow ALGORITHMIC route to the Fog node
    targetFogIdx = activeSensor.AssignedFog;
    targetFog = fogs{targetFogIdx};
    
    % --- TIER 1: EDGE GENERATES DATA ---
    [vitals, ecgWave, isAttacked] = activeSensor.readVitals();
    vitalStr = sprintf('HR:%d SpO2:%d Temp:%.1f', vitals.HR, vitals.SpO2, vitals.Temp);
    
    % Update Live Wave UI
    ui.plotLiveWave(ecgWave, isAttacked);
    
    if isAttacked
        ui.printLog(sprintf('[-] t=%d | %s (HACKED) sent SPOOFED payload [%s] -> FOG %d', t, activeSensor.DeviceID, vitalStr, targetFogIdx));
    else
        ui.printLog(sprintf('[+] t=%d | %s (Honest) sent valid vitals [%s] -> FOG %d', t, activeSensor.DeviceID, vitalStr, targetFogIdx));
    end
    
    % --- TIER 2: FOG RULE-BASED GATEKEEPER ---
    [isSafe, dataHash] = targetFog.processData(t, vitals, activeSensor.PatientID);
    
    if ~isSafe
        ui.printLog(sprintf('    >> [SECURITY ALERT] FOG %d Rule-Filter dropped invalid payload! Ledger Protected.', targetFogIdx));
    else
        ui.printLog(sprintf('    >> [FOG %d] Vitals OK. DB Updated. Broadcast Hash -> %s...', targetFogIdx, dataHash(1:8)));
        
        % --- TIER 3: CLOUD BLOCKCHAIN ---
        cloud.addBlock(dataHash);
        ui.printLog(sprintf('    >> [CLOUD] PBFT Consensus Reached. Block %d Secured.', cloud.Chain(end).Index));

        ui.updateLedger(cloud.Chain);
    end
    
    % Animate the topology Flow
    ui.animateFlow(activeSensorIdx, targetFogIdx, isSafe);
    drawnow;
    pause(0.5); 
end

%% 4. SECURITY TEST PANEL
tester = securityTester(fogs, cloud);
secUI  = securityUI(tester);

%% 5. Post-Simulation Legal Event (India DPDP Act)
ui.printLog('------------------------------------------------');
ui.printLog('[POLICY EVENT] ABDM Compliance: Executing DPDP Erasure for all Fog Nodes...');
for i = 1:numFogNodes; fogs{i}.functionalErasure(); end
ui.printLog('[SUCCESS] Raw medical data completely deleted. Blockchain remains intact.');
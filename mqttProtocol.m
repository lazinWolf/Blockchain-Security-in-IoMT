classdef mqttProtocol
    methods (Static)
        function frame = wrap(payload, topicStr, config)
            % Wraps the application payload into an MQTT v3.1.1 Frame
            frame = struct();
            frame.Protocol     = 'MQTT';
            frame.Topic        = topicStr;
            frame.QoS          = config.mqttQoS;
            frame.HeaderBytes  = config.mqttBaseHeader + length(topicStr);
            frame.Payload      = payload; % The encrypted packet goes inside
        end
        
        function [isValid, payload, topic, headerBytes] = unwrap(frame)
            % Simulates a network gateway extracting the payload from the frame
            if isfield(frame, 'Protocol') && strcmp(frame.Protocol, 'MQTT')
                isValid     = true;
                payload     = frame.Payload;
                topic       = frame.Topic;
                headerBytes = frame.HeaderBytes;
            else
                isValid     = false;
                payload     = [];
                topic       = "";
                headerBytes = 0;
            end
        end
    end
end
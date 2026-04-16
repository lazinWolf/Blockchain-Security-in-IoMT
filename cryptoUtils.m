classdef cryptoUtils
    methods (Static)
        function uuid = generateRecordID()
            % Generates a true universally unique identifier (UUID) via Java
            uuid = char(java.util.UUID.randomUUID().toString());
        end
        
        function cipherText = simulateEncrypt(vitals)
            % Converts struct to JSON, then to Base64 (Simulating Encryption)
            jsonStr = jsonencode(vitals);
            encoder = java.util.Base64.getEncoder();
            cipherText = char(encoder.encodeToString(uint8(jsonStr)));
        end
        
        function vitals = simulateDecrypt(cipherText)
            % Decodes Base64 back to JSON, then to struct (Simulating Decryption)
            decoder = java.util.Base64.getDecoder();
            jsonStr = char(decoder.decode(java.lang.String(cipherText))');
            vitals = jsondecode(jsonStr);
        end
    end
end
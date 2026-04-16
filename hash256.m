%% --- hash256.m ---
function hashStr = hash256(dataInput)
    % Uses SHA-256 hashing
    dataChar = char(string(dataInput));
    engine = java.security.MessageDigest.getInstance('SHA-256');
    engine.update(uint8(dataChar));
    hashBytes = typecast(engine.digest, 'uint8');
    hashStr = lower(dec2hex(hashBytes)');
    hashStr = hashStr(:)'; 
end
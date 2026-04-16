classdef cloudBlockchain < handle
    properties
        Chain
    end
    
    methods
        function obj = cloudBlockchain()
            genesis = struct('Index', 1, 'Timestamp', string(datetime('now')), ...
                             'DataHash', 'GENESIS', 'PrevHash', '0000000000000000');
            obj.Chain = genesis;
        end
        
        function addBlock(obj, incomingHash)
            prevBlock = obj.Chain(end);
            newBlock = struct('Index', prevBlock.Index + 1, ...
                              'Timestamp', string(datetime('now')), ...
                              'DataHash', incomingHash, ...
                              'PrevHash', hash256(prevBlock.DataHash));
            obj.Chain(end+1) = newBlock;
        end
    end
end
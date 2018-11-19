function [transmitTime] = findTransTime_BD(channels,activeChannel)

% Initialize the transmitting time
transmitTime=zeros(1,32);

% Calculate the transmitting time of each satellite using interpolations
for Nr = 1: length(activeChannel)
    %
    switch channels(activeChannel(Nr)).CH_B1I(1).navType
        case 'B1I_D2'
            transmitTime(channels(activeChannel(Nr)).CH_B1I(1).PRNID) = ...
                channels(activeChannel(Nr)).CH_B1I(1).SOW + ...
                channels(activeChannel(Nr)).CH_B1I(1).SubFrame_N * 3/5 + ...
                channels(activeChannel(Nr)).CH_B1I(1).Word_N * 0.6/10 + ...
                channels(activeChannel(Nr)).CH_B1I(1).Bit_N * 0.06/30 + ...
                channels(activeChannel(Nr)).CH_B1I(1).T1ms_N * 0.001 + ...
                channels(activeChannel(Nr)).CH_B1I(1).LO_CodPhs/channels(activeChannel(Nr)).CH_B1I(1).LO_Fcode0;
            
        case 'B1I_D1'
            transmitTime(channels(activeChannel(Nr)).CH_B1I(1).PRNID) = ...
                channels(activeChannel(Nr)).CH_B1I(1).SOW + ...
                channels(activeChannel(Nr)).CH_B1I(1).Word_N * 6/10 + ...
                channels(activeChannel(Nr)).CH_B1I(1).Bit_N * 0.6/30 + ...
                channels(activeChannel(Nr)).CH_B1I(1).T1ms_N * 0.001 + ...
                channels(activeChannel(Nr)).CH_B1I(1).LO_CodPhs/channels(activeChannel(Nr)).CH_B1I(1).LO_Fcode0;
            
    end
end

end


% for Nr = 1: length(activeChannel)
%     %
%     if channels(Nr).CH_B1I.PRNID <=5
%         transmitTime(Nr)=channels(activeChannel(Nr)).CH_B1I.SOW + ...
%              + mod(channels(activeChannel(Nr)).CH_B1I.T1ms_N,2) * 0.001 ...
%             + channels(activeChannel(Nr)).CH_B1I.Bit_N *  0.6/300 + ...
%             channels(activeChannel(Nr)).CH_B1I.LO_CodPhs/channels(activeChannel(Nr)).CH_B1I.LO_Fcode0;
%     else
%         transmitTime(Nr)=channels(activeChannel(Nr)).CH_B1I.SOW ...% + channels(activeChannel(Nr)).CH_B1I.SubFrame_N * 6 ...
%            + mod(channels(activeChannel(Nr)).CH_B1I.T1ms_N,20) * 0.001 + channels(activeChannel(Nr)).CH_B1I.Bit_N * 6/300  ...
%             +  channels(activeChannel(Nr)).CH_B1I.LO_CodPhs/channels(activeChannel(Nr)).CH_B1I.LO_Fcode0;
%     end
% end
% end
classdef webRF < handle
    %webRF Class wrapper for the webRF PA.
    % http://dpdcompetition.com/rfweblab/
    
    properties
        RMSin
        RMSout
        Idc
        Vdc
        PAPR
        synchronization
        add_fake_iq_imbalance
        add_fake_lo_leakage
        K1
        K2
        lo
        P_LO
    end
    
    methods
        function obj = webRF(dbm_power, add_fake_iq_imbalance, add_fake_lo_leakage)
            %webRF Construct an instance of this class
            if nargin == 0
                dbm_power = -24;
                add_fake_iq_imbalance = 0;
                add_fake_lo_leakage = 0;
            end
            
            if nargin == 1
                add_fake_iq_imbalance = 0;
                add_fake_lo_leakage = 0;
            end
            
            obj.RMSin = dbm_power;
            obj.add_fake_iq_imbalance = add_fake_iq_imbalance;
            obj.add_fake_lo_leakage = add_fake_lo_leakage;
            obj.synchronization.sub_sample = 1;
            
            % I/Q mismatch parameters:
            gm = 1.07; pm = 5/180*pi;
            K1 = 0.5*(1+gm*exp(1i*pm)); K2 = 0.5*(1-gm*exp(1i*pm));
            % scale the mismatch parameters so that signal power is unchanged
            scIQ = 1/sqrt(abs(K1)^(2)+abs(K2)^(2));
            obj.K1 = scIQ*K1; obj.K2 = scIQ*K2;
            
            % LO leakage parameter:
            lo = 1+1.234i;
            obj.lo = lo/abs(lo); % normalized
            obj.P_LO = -30; % power of LO leakage signal relative to signal power (in [dB])
        end
        
        function y = transmit(obj, x)
            %transmit. Take input signal, x, and broadcast it through the
            %RFWebLab PA.
            %
            %Args:
            %   -x: column vector. Will be normalized in RFWebLab function
            %
            %Returns:
            %   -y: column vector result from sending x through the PA. Y
            %   is normalized to be the same ||.||2 norm as x.
            
            if length(x) > 1000000
                warning('Too long for webRF.');
            end
            
            %% Add buffer 0s to the end of the signal
            length_input = length(x);
            pa_in = [x; zeros(100,1)];
            
            %% Add Fake Imparirments
            % IQ modulator output signal:
            if obj.add_fake_iq_imbalance
                pa_in = obj.K1*pa_in + obj.K2*conj(pa_in);
            end
            if obj.add_fake_lo_leakage
                LO = sqrt(10^(obj.P_LO/10)*mean(abs(pa_in).^2))*obj.lo; % LO leakage
                pa_in = pa_in + LO;
            end
            
            %% Transmit
            [y, obj.RMSout, obj.Idc, obj.Vdc, obj.PAPR] = RFWebLab_PA_meas_v1_1(pa_in, obj.RMSin);
            fprintf('    PAPR out = %f\n', obj.PAPR);
            
            %% Synchronize
            % Need something to guarantee same as input length and aligned in TD.
            y = [y(7:end)];
            y = y(1:length_input);
            
            % Normalize
            y = y * norm(x) / norm(y);
            if  obj.synchronization.sub_sample
                [delay, coeff, y] = cyclosync(y, x);
                %Set up a LS estimation for figuring out a subsample delay.
                X = [y [0; y(1:end-1)]];
                coeffs = (X'*X) \ (X'*x);
                y = X*coeffs;
            end
        end
    end
end
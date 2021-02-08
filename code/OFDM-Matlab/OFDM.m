classdef OFDM
    %OFDM Class for an OFDM signal.
    %
    %	Author:	Chance Tarver (2018)
    %		tarver.chance@gmail.com
    %
    properties
        nSubcarriers
        subcarrier_spacing
        constellation
        symbol_alphabet
        cp_length
        nSymbols
        fft_size
        sampling_rate
    end
    
    properties (Constant, Hidden)  
        constellation_library = {'QPSK','16QAM','64QAM'};
        constellaton_order=[4 16 64];
    end
    
    methods
        function obj = OFDM(params)
            %OFDM Construct an instance of this class. Will create an OFDM
            %signal in the frequency and time domain. Will also upsample for PA
            %
            % Args:
            %    params: struct with all the settings.
            %
            %	Author:	Chance Tarver (2018)
            %		tarver.chance@gmail.com
            %
            
            obj.nSubcarriers =  params.nSubcarriers;
            obj.subcarrier_spacing = params.subcarrier_spacing;
            obj.constellation = params.constellation;
            obj.cp_length = params.cp_length;
            obj.nSymbols = params.nSymbols;
            
            obj.fft_size = 2^ceil(log2(obj.nSubcarriers));
            obj.sampling_rate = obj.subcarrier_spacing * obj.fft_size;
            obj.symbol_alphabet = obj.QAM_Alphabet(obj.constellation);
        end
        
        
        function [out, fd_symbols] = use(obj)
            %use. Use the modulator.
            
            % TODO: add option to input data.
            
            % Create random symbols on the constellation
            fd_symbols = zeros(obj.nSubcarriers, obj.nSymbols);
            fd_symbols = obj.symbol_alphabet(ceil(length(obj.symbol_alphabet) ...
                * rand(size(fd_symbols))));
            
            % iterate over symbols.
            out = zeros(obj.fft_size + obj.cp_length, obj.nSymbols);
            for i = 1:obj.nSymbols
                td_waveform = obj.frequency_to_time_domain(fd_symbols(:, i));
                out(:, i) = obj.add_cyclic_prefic(td_waveform);
            end
            out = out(:); % Make into a single column
        end
        
        
        function out = add_cyclic_prefic(obj, in)
            out = zeros(length(in) + obj.cp_length, 1);
            out(obj.cp_length + 1:end) = in;
            out(1: obj.cp_length) = in(end-obj.cp_length+1:end); 
        end
        
        
        function out = remove_cyclic_prefix(obj, in)
           out = in(obj.cp_length+1:end); 
        end
        
        
        function out = frequency_to_time_domain(obj, in)
            %frequency_to_time_domain Method that can be used to perform the
            %IDFT to go to the time domain signal for OFDM. It will
            %zero pad according to LTE standards. No CP is used.
            %
            % Args:
            %     in:  vector of subcarriers to perform IDFT on.
            %
            %	Author:	Chance Tarver (2018)
            %		tarver.chance@gmail.com
            %
            
            ifft_input = zeros(obj.fft_size, 1);
            ifft_input(2:obj.nSubcarriers/2 + 1) = in(obj.nSubcarriers/2 + 1:end);
            ifft_input(end - obj.nSubcarriers/2 + 1 :end) = in(1:obj.nSubcarriers/2);
            out = ifft(ifft_input);  
        end
        
        
        function out = demod(obj, in)
            %demod. Method to demodulate the time domain signal back into the
            %original data.
            %
            % This assumes the input data here is the same length as the
            % original and that everything is synchronized properly.
            
            resource_grid = zeros(obj.nSubcarriers, obj.nSymbols);
            symbol_length = obj.fft_size + obj.cp_length;
            
            for i = 0:obj.nSymbols-1
               td_symbol = in(symbol_length*i + 1: symbol_length*(i+1));
               td = obj.remove_cyclic_prefix(td_symbol);
               fd = obj.time_domain_to_frequency(td);
               resource_grid(:,i+1) = fd;
            end
            out = resource_grid;
        end
        
        
        function out = time_domain_to_frequency(obj, in)
            %time_domain_to_frequency Method that can be used to perform the
            %DFT to go to the frequency domain signal for OFDM. It assumes
            %zero padding according to LTE standards. No CP is used. Only the
            %occupied subcarriers are returned.
            %
            % Args:
            %     in:  time domain vector to perform DFT on.
            %
            %	Author:	Chance Tarver (2018)
            %		tarver.chance@gmail.com
            %
            
            fftout = fft(in);
            
            out = zeros(obj.nSubcarriers, 1);
            out(1:obj.nSubcarriers/2) = fftout(end - obj.nSubcarriers/2 + 1:end);
            out(obj.nSubcarriers/2+1:end) = fftout(2:obj.nSubcarriers/2+1);
        end
        
        function evm = calculate_evm(obj, rx_signal, original_signal)
            error = rx_signal - original_signal;
            error = error(:); %Convert to vector
            
            original_signal = original_signal(:);
            evm = 100 * norm(error) / norm(original_signal);
        end
        
        function alphabet = QAM_Alphabet(obj, ModulationType)
            %QAM_Alphabet Function to create an alphabet of points of the
            %constellation
            
            %Set up some dictionaries
            modulation_dictionary = containers.Map(obj.constellation_library, ...
                obj.constellaton_order);
            
            MQAM = modulation_dictionary(ModulationType);
            
            alphaMqam = -(sqrt(MQAM)-1):2:(sqrt(MQAM)-1);
            A = repmat(alphaMqam,sqrt(MQAM),1);
            B = flipud(A');
            const_qam = A+1j*B;
            const_qam = const_qam(:);
            alphabet = const_qam;
        end
    end
end

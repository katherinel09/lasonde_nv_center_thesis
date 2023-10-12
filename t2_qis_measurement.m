global SPINAPI_DLL_NAME
SPINAPI_DLL_NAME = 'spinapi64';
% 
% function rabi_oscillation(t_delay)
% Set internal clock frequency (MHz)
CLOCK_FREQ = 0.001; %\\0.001;

% define a microsecond
us_second = 100000000; 

% define output addresses
laser_on_only = 0b1001; 
microwave_on_only = 0b0010;
both_off = 0x00;

% Adds path to the folder that contains all PulseBlaster functions
% This folder is located in the PulseBlaster MATLAB GUI package
addpath('C:\Matlab experiment code\PulseBlasterMatGUI_2017-0111_64\Matlab_SpinAPI\');
addpath('C:\Users\Top Spin\Desktop\cleveland-qis\');

% Loads spinapi64 library and both headers: spinapi.h and pulseblaster.h
if ~libisloaded('spinapi64') 
% All files are located in SpinAPI folder
loadlibrary('C:\SpinCore\SpinAPI\lib\spinapi64.dll', ...
            'C:\SpinCore\SpinAPI\include\spinapi.h', 'addheader',...
            'C:\SpinCore\SpinAPI\include\pulseblaster.h');
end

% Selects first PulseBlaster
pb_select_board(0);

% Initializes PulseBlaster
pb_init();

% Set Clock Frequency (MHz) to 100 MHz
pb_core_clock(CLOCK_FREQ);

% Retrieve firmware ID and prints in Command Window    
firm_id = pb_get_firmware_id();
dev_id = bitshift(bitand(firm_id,hex2dec('FF00')),-8);
rev_id = bitand(firm_id,hex2dec('00FF'));
firmware_ID = sprintf('%d - %d', dev_id, rev_id)

% Start programming
pb_start_programming('PULSE_PROGRAM');
PI_pulse_length = 0.7968; %ns
half_pi_pulse_length = PI_pulse_length/2;
% 

for t_delay=0.1:0.1:10
    % First, turn the laser on for 5 us
    pb_inst_pbonly(laser_on_only, 0, 0, 5*us_second);
    
    % Second, turn off everything for 500 us
    pb_inst_pbonly(both_off, 0,0, 2*us_second);
    
    % Third, turn on microwave for 5 us
    pb_inst_pbonly(microwave_on_only,0,0,half_pi_pulse_length*us_second); 
    pb_inst_pbonly(both_off, 0,0, t_delay*us_second);

    pb_inst_pbonly(microwave_on_only,0,0,PI_pulse_length*us_second); 
    pb_inst_pbonly(both_off, 0,0, t_delay*us_second);

    pb_inst_pbonly(microwave_on_only,0,0,half_pi_pulse_length*us_second); 

    % Trigger the QIS to take in signal
    % Fourth, turn off both for t_padding = 2 us
    pb_inst_pbonly(both_off, 0, 0, 1*us_second);

    % Call the python script to capture a single frame
    pyrunfile('C:\Users\Top Spin\Desktop\cleveland-qis\kat_matlab.py');
    
    pb_inst_pbonly(both_off, 0, 0, 1*us_second);

    % Fifth, turn on the laser for 5 us to readout
    pb_inst_pbonly(laser_on_only, 0, 0, 5*us_second);
    
    % Finally, turn off both and for 1000 us and reset
    pb_inst_pbonly(0,0,0,1000*us_second);
end

pb_inst_pbonly(0,0,0,1000*us_second);

% Close communication with PulseBlaster
pb_stop_programming();
pb_stop();
pb_start();
pb_close(); 

% Unload the library
unloadlibrary('spinapi64');
% end
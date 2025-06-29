% ---------------------- Parameter Definition ----------------------------
fc = 1e6;                    % Carrier frequency in Hz (1 MHz)
Rs = 1e3;                    % Symbol rate in Hz (1 kHz)
samples_per_symbol = 10000; % Number of samples to represent one symbol
Fs = Rs * samples_per_symbol; % Sampling frequency derived from Rs
Ts = 1 / Fs;                 % Sampling period (inverse of Fs)

% ------------------------ Input Data Setup ------------------------------
mat = [1 0 1 0 1 1 0 0 1 1 0 1 1 1 0 1];  % Binary input data
sigl = 2 * mat - 1;                      % Convert binary to bipolar format (-1, +1)
len = length(sigl);                      % Total number of bits/symbols

% ------------------------ Time Vector ----------------------------------
T_total = len / Rs;                      % Total transmission time
t = 0 : Ts : T_total - Ts;               % Time vector based on sampling rate

% ------------------------ Carrier Generation ----------------------------
carrier = sin(2 * pi * fc * t);          % Carrier signal with fc = 1 MHz

% ------------------------ PSK Modulation -------------------------------
bit_len = length(t) / len;               % Samples per bit
z = zeros(1, length(t));                 % Initialize modulated signal
sig = zeros(1, length(t));               % Initialize baseband signal

for i = 1:len
    idx_start = floor((i - 1) * bit_len) + 1;
    idx_end = floor(i * bit_len);
    z(idx_start:idx_end) = carrier(idx_start:idx_end) * sigl(i); % Modulate
    sig(idx_start:idx_end) = sigl(i);                             % Baseband
end

sig_plot = sig;
sig_plot(sig_plot < 0) = 0;              % Convert to unipolar for visualization

% ------------------------ Plot Data Sequence ----------------------------
figure;
subplot(3,1,1);
stairs(sig_plot, 'LineWidth', 2);         % Plot input signal
axis([0 length(sig_plot) -2 3]);
title('Input Data Sequence');
ylabel('Amplitude');
xlabel('Time,ms');

% ------------------------ Plot Carrier ----------------------------------
subplot(3,1,2);
plot(carrier);                           % Full carrier waveform
title('Carrier Signal (1 MHz)');
ylabel('Amplitude');
xlabel('Time');

% ------------------------ Plot Modulated Signal ------------------------
subplot(3,1,3);
plot(z);                                 % Full modulated waveform
title('PSK Modulated Signal');
ylabel('Amplitude');
xlabel('Time');

pause(3);                                % Pause for 3 seconds to view plots

% ------------------------ Coherent Demodulation ------------------------
ref_carrier = carrier(1:bit_len);        % Reference carrier (1 symbol period)
demod = zeros(1, len);                   % Recovered bit array

for i = 1:len
    idx_start = floor((i - 1) * bit_len) + 1;
    idx_end = floor(i * bit_len);
    segment = z(idx_start:idx_end);      % Extract one symbol
    product = segment .* ref_carrier;    % Correlate with reference
    sum_product = sum(product);          % Integrate the correlation
    demod(i) = sum_product > 0;          % Make decision
end

% ------------------------ Plot Demodulated Bits ------------------------
figure;
stairs(0:len, [demod demod(end)], 'LineWidth', 2); % Extended one sample for clarity
axis([0 len -0.5 1.5]);
title('Demodulated Data Sequence');
ylabel('Amplitude');
xlabel('Time,ms');

% ------------------------ Zoomed Waveforms ------------------------------

% Zoomed Carrier Signal: 5 cycles
cycles_to_plot = 5;
samples_per_cycle = Fs / fc;
samples_to_plot = round(cycles_to_plot * samples_per_cycle);
t_zoom = (0:samples_to_plot-1) * Ts * 1e6; % Convert to microseconds

figure;
plot(t_zoom, carrier(1:samples_to_plot), 'LineWidth', 1.5);
title(['Zoomed Carrier Signal (' num2str(cycles_to_plot) ' Cycles, 1 MHz)']);
ylabel('Amplitude');
xlabel('Time (\mus)');
grid on;

% Zoomed PSK Modulated Signal: focus on transition at t = 4ms
target_time = 0.004;                     % 1ms, 2ms, 3ms and 4 ms
samples_center = round(target_time / Ts);
cycles_to_show = 6;                      % Number of cycles to display
samples_to_plot = round(cycles_to_show * samples_per_cycle);
half_span = round(samples_to_plot / 2);

idx_start = samples_center - half_span;
idx_end = samples_center + half_span - 1;
t_zoom = (0:samples_to_plot-1) * Ts * 1e6;  % Time axis in µs

%----dadada
figure;
plot(t_zoom, z(idx_start:idx_end), 'LineWidth', 1.5);
title(['Zoomed PSK Modulated Signal Around t = ' num2str(target_time*1e3) ' ms']);
xlabel('Time (\\mus)');
ylabel('Amplitude');
grid on;

% ------------------------ 16-PSK Constellation --------------------------
num_symbols = 16;
bits_per_symbol = 4;
bit_symbols = dec2bin(0:num_symbols-1, bits_per_symbol); % Binary mapping
angles = (0:num_symbols-1) * (2*pi / num_symbols);        % Phase angles (radians)
angles_deg = angles * 180/pi;                             % Convert to degrees

% Convert polar to Cartesian coordinates for plotting
I = cos(angles);
Q = sin(angles);

% Create figure with 2 panels: constellation plot and truth table
fig = figure('Name', '16-PSK Constellation with Truth Table', 'Position', [100, 100, 1000, 500]);
tiledlayout(1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

% Plot constellation diagram
nexttile(1);
plot(I, Q, 'bo', 'MarkerSize', 10, 'LineWidth', 2);
hold on;
axis equal;
grid on;
title('16-PSK Constellation');
xlabel('In-phase (I)');
ylabel('Quadrature (Q)');

% Label each constellation point with binary value
for i = 1:num_symbols
    text(I(i)*1.2, Q(i)*1.2, bit_symbols(i,:), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'FontName', 'Courier');
end

% Prepare truth table: symbol index, binary, and phase angle
data = cell(num_symbols, 3);
for i = 1:num_symbols
    data{i,1} = i-1;                             % Decimal index
    data{i,2} = bit_symbols(i,:);               % Binary string
    data{i,3} = sprintf('%.1f°', angles_deg(i)); % Phase angle in degrees
end

% Display truth table in table widget
uitable('Data', data, ...
    'ColumnName', {'Symbol', 'Binary', 'Phase'}, ...
    'ColumnWidth', {60, 80, 80}, ...
    'Position', [520 50 400 360], ...
    'FontSize', 10, ...
    'Parent', gcf);

clc; clear; close all;

%% =============================
% 1. Cargar señal de voz
% =============================
[x, fs] = audioread('AudioSebastian.wav'); % Cambia por tu archivo si quieres
x = x(:,1); % En caso de estéreo → mono

t = (0:length(x)-1)/fs;

%% =============================
% 2. Parámetros de análisis
% =============================
frame_length = round(0.03 * fs); % 30 ms
frame_shift  = round(0.015 * fs); % 15 ms (50% overlap)

num_frames = floor((length(x) - frame_length)/frame_shift) + 1;

energy = zeros(num_frames,1);
zcr    = zeros(num_frames,1);

%% =============================
% 3. Cálculo de características
% =============================
for i = 1:num_frames
    idx = (i-1)*frame_shift + (1:frame_length);
    frame = x(idx);
    
    % Energía en tiempo corto
    energy(i) = sum(frame.^2);
    
    % Tasa de cruces por cero
    zcr(i) = sum(abs(diff(sign(frame)))) / (2*frame_length);
end

%% =============================
% 4. Normalización
% =============================
energy = energy / max(energy);
zcr = zcr / max(zcr);

%% =============================
% 5. Umbrales (ajustables)
% =============================
th_energy_silence = 0.02;
th_energy_voiced  = 0.05;
th_zcr = 0.3; % antes 0.1 → muy bajo

labels = strings(num_frames,1);

%% =============================
% 6. Clasificación con niveles lógicos
% =============================
levels = zeros(num_frames,1); % aquí guardamos 0, 2.5 o 5

for i = 1:num_frames
    
    if energy(i) < th_energy_silence
        levels(i) = 0; % Silencio
        
    elseif energy(i) > th_energy_voiced && zcr(i) < th_zcr
        levels(i) = 2.5; % Vocalizado
        
    else
        levels(i) = 5; % No vocalizado
    end
end

%% =============================
% 7. Tiempo por frame
% =============================
t_frames = ((0:num_frames-1)*frame_shift + frame_length/2)/fs;

%% =============================
% 8. Gráficas
% =============================
%% =============================
% Gráfica única sobrepuesta
% =============================
figure;
hold on

% Señal original (gris)
plot(t, x, 'Color', [0.7 0.7 0.7])

% Energía (escalada para visualizar)
energy_plot = interp1(t_frames, energy, t, 'linear', 'extrap');
plot(t, energy_plot, 'b', 'LineWidth', 1.5)

% Clasificación (escalada al mismo eje)
levels_plot = interp1(t_frames, levels, t, 'nearest', 'extrap');
plot(t, levels_plot, 'r', 'LineWidth', 1.5)

% Líneas de referencia
yline(0,'--b')
yline(2.5,'--g')
yline(5,'--r')

title('Señal, Energía y Clasificación (sobrepuesta)')
xlabel('Tiempo (s)')
ylabel('Amplitud / Nivel lógico')

legend('Señal','Energía','Clasificación')

grid on
hold off
%% =============================
% 9. Reproducción (opcional)
% =============================
sound(x, fs)
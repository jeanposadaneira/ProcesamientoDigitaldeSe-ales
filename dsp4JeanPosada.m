clc; clear; close all;
[x,fs] = audioread('AudioSebastian.wav');%cargamos audio
x = x(:,1); % mono
x = x(abs(x) > 0.02); % eliminar silencios iniciales
x = x - mean(x);      % quitar DC

[b,a] = butter(4,[60 200]/(fs/2),'bandpass');%filtramos
x = filter(b,a,x);
win_len = 1024;
hop = round(win_len/4);
num_frames = floor((length(x)-win_len)/hop);
fmin = 60;    %Se escogen estas frecuencias por que vi voz es masculina y asi evitamos detectar armonicos
fmax = 200;
tau_min = floor(fs/fmax); %retardo donde aparece el primer pico en la autocorrelación
tau_max = ceil(fs/fmin);
pitch = zeros(num_frames,1);% El pitch (tono) es la frecuencia fundamental f0 de una señal de voz.
energy = zeros(num_frames,1);
r_example = [];
frame_example = [];

for i = 1:num_frames  %autocorrelacion y energia
    
    idx = (i-1)*hop + (1:win_len);
    frame = x(idx);

    frame = frame .* hamming(win_len);
    frame = frame / (sqrt(frame'*frame) + 1e-8);

    % Energía (para detectar sílabas)
    energy(i) = sum(frame.^2);

    % --- Autocorrelación ---
    r = zeros(win_len,1);
    
    for k = 0:tau_max
        y = zeros(win_len,1);
        y((k+1):win_len) = frame(1:(win_len-k));
        r(k+1) = frame' * y;
    end

    % Guardamos 
    if i == 5
        r_example = r;
        frame_example = frame;
    end

    % --- Detección de pitch ---
    r_valid = r(tau_min:tau_max);

    [val, idx_peak] = max(r_valid);
    tau = idx_peak + tau_min - 1;

    if val > 0.1*r(1)
        pitch(i) = fs / tau;
    else
        pitch(i) = 0;
    end
end

energy_norm = energy / max(energy); %detectamos silabas(voz)
voice_activity = energy_norm > 0.1; % umbral

% Forzar pitch = 0 donde no hay voz
pitch(~voice_activity) = 0;
pitch = medfilt1(pitch,11);
pitch = smoothdata(pitch,'movmean',5);

for i=2:length(pitch)
    if pitch(i)>0 && pitch(i-1)>0
        if pitch(i) > 2*pitch(i-1)
            pitch(i) = pitch(i)/2;
        elseif pitch(i) < pitch(i-1)/2
            pitch(i) = pitch(i)*2;
        end
    end
end

t = (0:num_frames-1)*hop/fs;
figure;
plot(t, pitch,'LineWidth',1.5);
ylim([0 300])
xlabel('Tiempo (s)');
ylabel('Frecuencia (Hz)');
title('Seguimiento de tono con separación de sílabas');
grid on;

figure;
subplot(2,1,1)
plot(frame_example)
title('Ventana de voz')
grid on
subplot(2,1,2)
plot(r_example)
title('Autocorrelación')
grid on
hold on
xline(tau_min,'r--')
xline(tau_max,'r--')

dur_note = 0.25; % notas más largas
guitar_signal = [];

for i = 1:length(pitch)
    
    f = pitch(i);

    if voice_activity(i) && f > 0
        
        % Nota con tono
        N = round(fs/f);
        N = min(max(N,20),2000);

        buffer = 2*rand(N,1) - 1;

        M = round(dur_note * fs);
        y = zeros(M,1);

        for n = 1:M
            y(n) = buffer(1);
            avg = 0.498*(buffer(1) + buffer(2));
            buffer = [buffer(2:end); avg];
        end
        
    else
        % Silencio entre sílabas
        M = round(0.15 * fs);
        y = zeros(M,1);
    end

    guitar_signal = [guitar_signal; y];
end

guitar_signal = guitar_signal / (max(abs(guitar_signal)) + 1e-8);

sound(guitar_signal, fs);
audiowrite('guitarra_silabas.wav', guitar_signal, fs);
disp(['Pitch min: ', num2str(min(pitch))])
disp(['Pitch max: ', num2str(max(pitch))])
disp(['Frames con voz: ', num2str(sum(voice_activity))])
%% =========================================================
% ANALISIS STFT + MODIFICACION DE TONO Y DURACION (ESPECTOGRAMA)
% =========================================================

clear; close all; clc;

%% =========================
% 1. GENERAR MELODIA (Estrellita)
% =========================
Fs = 8000;

f = [220 220 247 247 262 262 247 220 220 196 196 175 175 147];

x = [];

for i = 1:length(f)
    dur = 1;
    if i==7 || i==14
        dur = 2;
    end
    t = 0:1/Fs:dur;
    nota = sin(2*pi*f(i)*t);
    x = [x nota];
end

x = x(:);
audiowrite('melodia.wav', x, Fs);

%% =========================
% 2. CARGAR AUDIO
% =========================
[x, Fs] = audioread('melodia.wav');
x = mean(x,2);

%% =========================
% 3. ESPECTROGRAMA ORIGINAL (CORREGIDO)
% =========================
N = 2048;
overlap = round(0.75*N);
window = hamming(N);

[S, F, T] = spectrogram(x, window, overlap, N, Fs);

% CORRECCIÓN CLAVE (eliminar f=0)
F = F(2:end);
S = S(2:end, :);

% Convertir a semitonos
g = 12*(log2(F) - log2(110));

figure;
imagesc(T, g, 20*log10(abs(S)+1e-6));
axis xy;
xlabel('Tiempo (s)');
ylabel('Semitonos');
title('Espectrograma Original');
colorbar;

%% =========================
% 4. CAMBIO DE TONO
% =========================

% Subir medio tono
factor_up = 2^(1/12);
x_up = resample(x, round(1000*factor_up), 1000);
x_up = resample(x_up, 1000, round(1000*factor_up));
audiowrite('subida.wav', x_up, Fs);

% Bajar medio tono
factor_down = 2^(-1/12);
x_down = resample(x, round(1000*factor_down), 1000);
x_down = resample(x_down, 1000, round(1000*factor_down));
audiowrite('bajada.wav', x_down, Fs);

%% =========================
% 5. CAMBIO DE DURACION
% =========================

% Alargar 1.25x
x_long = resample(x, 1250, 1000);
audiowrite('larga.wav', x_long, Fs);

% Acortar 0.75x
x_short = resample(x, 750, 1000);
audiowrite('corta.wav', x_short, Fs);

%% =========================
% 6. ESPECTROGRAMAS COMPARATIVOS (CORREGIDO)
% =========================

signals = {x_up, x_down, x_long, x_short};
titles = {'Subida +1/2 tono', 'Bajada -1/2 tono', ...
          'Duracion 1.25x', 'Duracion 0.75x'};

figure;
for i = 1:4
    [S,F,T] = spectrogram(signals{i}, window, overlap, N, Fs);

    % CORRECCIÓN CLAVE
    F = F(2:end);
    S = S(2:end,:);

    g = 12*(log2(F) - log2(110));

    subplot(2,2,i);
    imagesc(T, g, 20*log10(abs(S)+1e-6));
    axis xy;
    xlabel('Tiempo');
    ylabel('Semitonos');
    title(titles{i});
end

%% =========================
% 7. (OPCIONAL) CORRECCION LOCAL DE TONO
% =========================

inicio = 2; % segundos
fin = 3;

idx = round(inicio*Fs):round(fin*Fs);
segmento = x(idx);

factor = 2^(1/12);

seg_mod = resample(segmento, round(1000*factor), 1000);
seg_mod = resample(seg_mod, 1000, round(1000*factor));

seg_mod = seg_mod(1:length(segmento));

x_corr = x;
x_corr(idx) = seg_mod;

audiowrite('corregida.wav', x_corr, Fs);

%% =========================
% 8. ESPECTROGRAMA FINAL CORREGIDO
% =========================

[S,F,T] = spectrogram(x_corr, window, overlap, N, Fs);

% CORRECCIÓN CLAVE
F = F(2:end);
S = S(2:end,:);

g = 12*(log2(F) - log2(110));

figure;
imagesc(T, g, 20*log10(abs(S)+1e-6));
axis xy;
xlabel('Tiempo');
ylabel('Semitonos');
title('Espectrograma Corregido');
colorbar;

%% =========================
% FIN
% =========================
disp('corregido');
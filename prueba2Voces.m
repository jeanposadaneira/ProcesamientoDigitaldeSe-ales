[x,fs]=audioread('vozfemenina.wav');
h = hamming(384);
x = x.*h;
x = x/sqrt(x'*x);
for k=0:100
    y = zeros(384,1);
    y((k+1):384) = x(1:(384-k));
    r(k+1) = x'*y;
end
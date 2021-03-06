function pogs_time = logistic(m, n, params)
%LOGISTIC

if nargin == 2
  params = [];
end

% Generate data.
rng(0, 'twister');

x = randn(n + 1, 1) / n .* (rand(n + 1, 1) > 0.8);
A = [rand(m, n), ones(m, 1)];
y = (rand(m, 1) < 1 ./ (1 + exp(-A * x)));

f.h = kLogistic;
f.d = -y;
g.h = kAbs;
g.c = 0.06 * norm(A' * (ones(m, 1) / 2 - y), inf);

% Solve
tic
pogs(A, f, g, params);
pogs_time = toc;

end

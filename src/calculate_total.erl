-module(calculate_total).
-export([total/1]).
total([{What,N}|T]) -> shop:cost(What) * N + total(T);
total([]) ->0.

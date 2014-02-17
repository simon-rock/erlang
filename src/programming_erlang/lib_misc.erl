-module(lib_misc).
-export([qsort/1, pythag/1, perms/1, max/2, odds_and_evens_acc/1
        ,sleep/1            %% stop process T
        ,flush_buffer/0
        ,priority_receive/0  %% don't handle when there are too many mails in email.
        ,on_exit/2           %% send reason when process exit or crash
        ]).

%quick sort
qsort([]) -> [];
qsort([Pivot | T]) -> 
        qsort([X || X <- T, X < Pivot])
        ++[Pivot]++
        qsort([X || X <- T, X >= Pivot]).   %% X ++ Y ++ Z : [X, Y, Z]

pythag(N) ->
    [{A, B, C} ||
        A <- lists:seq(1, N),
        B <- lists:seq(1, N),
        C <- lists:seq(1, N),
        A + B + C =< N,
        A*A+B*B =:=C*C
    ].

perms([]) -> [[]];
perms(L) ->  [[H | T] || H <- L, T <- perms(L -- [H])].  %%  X--Y : remove Y from X

max(X, Y) when X > Y -> X;  %% and : G1, G2, G3 -> X,,,or : G1; G2; G3 -> X
max(X, Y) -> Y.

odds_and_evens(L) ->
    Odds = [X || X <- L, (X rem 2) =:= 1],
    Evens = [X || X <- L, (X rem 2) =:= 0],
    {Odds, Evens}.

odds_and_evens_acc(L) ->
    odds_and_evens_acc(L, [], []).
odds_and_evens_acc([H|T], Odds, Evens) ->
    case (H rem 2) of
        1 -> odds_and_evens_acc(T, [H|Odds], Evens);
        0 -> odds_and_evens_acc(T, Odds, [H | Evens])
    end;
odds_and_evens_acc([], Odds, Evens) ->
    {lists:reverse(Odds), lists:reverse(Evens)}.

%% p125
sleep(T) ->
    receive
    after T -> true
    end.

flush_buffer() ->
    receive
        _Any ->
            flush_buffer()
    after 0 ->
            true
    end.

priority_receive()->
    receive
        {alarm, X} ->
            {alarm, X}
    after 0 ->
            receive
                Any ->
                    Any
            end
    end.

on_exit(Pid, Fun) ->
    spawn(fun() -> 
                  process_flag(trap_exit, true),  %% change process to system process
                  link(Pid),                      %% link sp. process with Pid to the new process. whe Pid exit, will sent info to system process and run Fun().
                  receive
                      {'EXIT', Pid, Why} ->
                          Fun(Why)
                  end
          end).

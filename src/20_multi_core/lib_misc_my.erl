-module(lib_misc).
-export([qsort/1, pythag/1, perms/1, max/2, odds_and_evens_acc/1
        ,sleep/1            %% stop process T
        ,flush_buffer/0
        ,priority_receive/0  %% don't handle when there are too many mails in email.
        ,on_exit/2           %% send reason when process exit or crash
        ,keep_alive/2
        ,consult/1
%        ,ls/1
        ,string2value/1
        ,pmap/2
        ]).

%% 列表推断 List Comprehensions
%% [Expr || Qualifier1,...,QualifierN]
%quick sort : usage => qsort("321") => "123"
qsort([]) -> [];
qsort([Pivot | T]) -> 
        qsort([X || X <- T, X < Pivot])
        ++[Pivot]++
        qsort([X || X <- T, X >= Pivot]).   %% X ++ Y ++ Z : [X, Y, Z]

%% lists:seq(1, 10).   => [1,2,3,4,5,6,7,8,9,10]
%% lists:seq(1, 20, 3). => [1,4,7,10,13,16,19]
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

keep_alive(Name, Fun) ->
    register(Name, Pid = spawn(Fun)),
    on_exit(Pid, fun(_Why) -> keep_alive(Name, Fun) end).

%% file:consult() of myself
consult(File) ->
    case file:open(File, read) of
        {ok, S} ->
            Val = consult1(S),
            file:close(S),
            {ok, Val};
        {error, Why} ->
            {error, Why}
    end.

consult1(S) ->
    case io:read(S, '') of
        {ok, Term} -> [Term|consult1(S)];
        eof -> [];
        Error -> Error
    end.

%windows
%-include_lib("C:\\erl5.10.3\\lib\\kernel-2.16.3\\include\\file.hrl").
%linux
%-include_lib("include/file.hrl").
%file_size_and_type(File) ->
%    case file:read_file_info(File) of
%        {ok, Facts} ->
%            {Facts#file_info.type, Facts#file_info.size};
%        _ ->
%            error
%    end.

%ls(Dir) ->
%    {ok, L} = file:list_dir(Dir),
%    lists:map(fun(I) -> {I, file_size_and_type(I)} end, lists:sort(L)).

string2value(Str) ->
    {ok, Tokens, _} = erl_scan:string(Str ++ "."),
    %% generate
    {ok, Exprs} = erl_parse:parse_exprs(Tokens),
    Bindings = erl_eval:new_bindings(),
    {value, Value, _} = erl_eval:exprs(Exprs, Bindings),
    Value.

%%multi core, chapter 20
pmap(F, L) ->
    S = self(),
    %% make_ref() returns a unique reference
    %% we'll match on this later
    Ref = erlang:make_ref(),
    Pids = lists:map(fun(I) -> 
                       spawn(fun() -> do_f(S, Ref, F, I) end) 
               end, L),
    
    %% gather the results
    gather(Pids, Ref).

do_f(Parent, Ref, F, I) ->
    Parent ! {self(), Ref, (catch F(I))}.

gather([Pid|T], Ref) ->
    receive
        {Pid, Ref, Ret} -> [Ret | gather(T, Ref)]
    end;
gather([], _) ->
    [].


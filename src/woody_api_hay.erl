%%%
%%% Copyright 2018 RBKmoney
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%

-module(woody_api_hay).

-behaviour(hay_metrics_handler).

%% how_are_you callbacks
-export([init/1]).
-export([get_interval/1]).
-export([gather_metrics/1]).

%% Types

-type options() :: #{
    interval := timeout()
}.

-export_type([options/0]).

%% Internal types

-type state() :: options().
-type metric() :: how_are_you:metric().
-type metric_key() :: how_are_you:metric_key().
-type metric_value() :: how_are_you:metric_value().
-type nested_metrics() :: [metric() | nested_metrics()].

%% API

-spec init(options()) -> {ok, state()}.
init(Options) ->
    {ok, #{
        interval => maps:get(interval, Options, 10 * 1000)
    }}.

-spec get_interval(state()) -> timeout().
get_interval(#{interval := Interval}) ->
    Interval.

-spec gather_metrics(state()) -> [hay_metrics:metric()].
gather_metrics(_) ->
    lists:map(fun create_server_metrics/1, get_active_connections()).

%% Internals

create_server_metrics({Ref, Nconns}) when is_tuple(Ref) ->
    create_server_metrics({tuple_to_list(Ref), Nconns});
create_server_metrics({Ref, Nconns}) ->
    gauge([woody, server, Ref, active_connections], Nconns).

get_ranch_info() ->
    try
        ranch:info()
    catch
        _:_ = Error ->
            {error, Error}
    end.

get_ranch_info_safe() ->
    case get_ranch_info() of
        {error, _} -> [];
        Reply -> Reply
    end.

get_active_connections() ->
    F = fun({Ref, Info}) ->
        Nconns =
            case lists:keyfind(active_connections, 1, Info) of
                false -> 0;
                {_, N} -> N
            end,
        {Ref, Nconns}
    end,
    lists:map(F, get_ranch_info_safe()).

-spec gauge(metric_key(), metric_value()) -> metric().
gauge(Key, Value) ->
    how_are_you:metric_construct(gauge, Key, Value).

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

-spec test() -> _.

-spec get_ranch_inf_error_test() -> _.
get_ranch_inf_error_test() ->
    ?_assertMatch({error, _}, get_ranch_info()).

-spec get_ranch_info_ok_test_() -> _.
get_ranch_info_ok_test_() ->
    {setup, fun() -> application:start(ranch) end, fun(_) -> application:stop(ranch) end,
        ?_assertEqual([], get_ranch_info())}.

-endif.

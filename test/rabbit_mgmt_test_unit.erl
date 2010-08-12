%%   The contents of this file are subject to the Mozilla Public License
%%   Version 1.1 (the "License"); you may not use this file except in
%%   compliance with the License. You may obtain a copy of the License at
%%   http://www.mozilla.org/MPL/
%%
%%   Software distributed under the License is distributed on an "AS IS"
%%   basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
%%   License for the specific language governing rights and limitations
%%   under the License.
%%
%%   The Original Code is RabbitMQ Management Console.
%%
%%   The Initial Developers of the Original Code are Rabbit Technologies Ltd.
%%
%%   Copyright (C) 2010 Rabbit Technologies Ltd.
%%
%%   All Rights Reserved.
%%
%%   Contributor(s): ______________________________________.
%%
-module(rabbit_mgmt_test_unit).
-export([test/0]).

-include_lib("amqp_client/include/amqp_client.hrl").
-include_lib("eunit/include/eunit.hrl").

rates_test() ->
    Previous = [{foo, 1}, {bar, 100}, {baz, 3}],
    PreviousTS = {0, 0, 0},
    New = [{foo, 2}, {bar, 200}, {bash, 100}, {baz, 3}],
    NewTS = {0, 10, 0},
    WithRates = rabbit_mgmt_db:rates(New, NewTS, Previous, PreviousTS,
                                     [foo, bar, bash]),
    equals(0.1, pget(foo_rate, WithRates)),
    equals(10, pget(bar_rate, WithRates)),
    undefined = pget(bash_rate, WithRates),
    undefined = pget(baz_rate, WithRates).

http_overview_test() ->
    {struct, Props} = request("/json/overview"),
    %% Rather crude, but this req doesn't say much and at least this means it
    %% didn't blow up.
    [<<"0.0.0.0:5672">>] = pget(<<"bound_to">>, Props).

%%---------------------------------------------------------------------------

request(Path) ->
    {ok, {{_HTTP, 200, _OK}, _Headers, Body}} =
        httpc:request(
          get,
          {"http://localhost:55672" ++ Path,
           [{"Authorization",
             "Basic " ++ binary_to_list(base64:encode("guest:guest"))}]},
          [], []),
    mochijson2:decode(Body).

%%---------------------------------------------------------------------------

pget(K, L) ->
     proplists:get_value(K, L).

equals(F1, F2) ->
    true = (abs(F1 - F2) < 0.001).

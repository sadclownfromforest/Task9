-module(iotserv).

-export([start_link/0, add/5, delete/1, change/5, lookup/1,
        init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).


-behaviour(gen_server).


start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

add(Id, Name, Address, Temp, Metrics) ->
    gen_server:call(?MODULE, {add, {Id, Name, Address, Temp, Metrics}}).

delete(Id) ->
    gen_server:call(?MODULE, {delete, Id}).

change(Id, Name, Address, Temp, Metrics) ->
    gen_server:call(?MODULE, {change, {Id, Name, Address, Temp, Metrics}}).

lookup(Id) ->
    gen_server:call(?MODULE, {lookup, Id}).

init([]) ->
    ok = iotserv_db:init(),
    {ok, {}}.

handle_call({add, Device}, _From, State) ->
    Response = iotserv_db:insert(Device),
    {reply, Response, State};

handle_call({change, Device = {Id, _, _, _, _}}, _From, State) ->
    case iotserv_db:lookup(Id) of
        {ok, _} ->
            iotserv_db:insert(Device),
            {reply, ok, State};
        {error, not_found} ->
            {reply, {error, not_found}, State}
    end;

handle_call({delete, Id}, _From, State) ->
    Response = iotserv_db:delete(Id),
    {reply, Response, State};

handle_call({lookup, Id}, _From, State) ->
    Result = iotserv_db:lookup(Id),
    {reply, Result, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    iotserv_db:close(),
    ok.



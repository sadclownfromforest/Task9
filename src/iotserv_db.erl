-module(iotserv_db).

-export([init/0, close/0, insert/1, delete/1, lookup/1]).

init() ->
    DetsPath = get_dets_path(),
    {ok, iotserv_dets} = dets:open_file(iotserv_dets, [{file, DetsPath}, {type, set}, {keypos, 1}]),
    ets:new(iotserv_ets, [set, named_table, public, {keypos, 1}]),
    dets:to_ets(iotserv_dets, iotserv_ets),
    ok.

close() ->
    dets:close(iotserv_dets),
    ok.

insert(Device = {Id, _, _, _, _}) ->
    case ets:lookup(iotserv_ets, Id) of
        [_] -> {error, id_already_exist};
        []  ->
        ets:insert(iotserv_ets, Device),
        dets:insert(iotserv_dets, Device),
        ok
    end.


delete(Id) ->
    case ets:lookup(iotserv_ets, Id) of
        [_] ->
            ets:delete(iotserv_ets, Id),
            dets:delete(iotserv_dets, Id),
            ok;
        [] ->
            {error, id_not_found}
    end.

lookup(Id) ->
    case ets:lookup(iotserv_ets, Id) of
        [Device] -> {ok, Device};
        [] -> {error, not_found}
    end.

get_dets_path() ->
    case file:read_file("config.json") of
        {ok, Bin} ->
            Map = jsx:decode(Bin, [return_maps]),
            PathBinary = maps:get(<<"db_path">>, Map, <<"db.dets">>),
            binary_to_list(PathBinary);
        {error, _Reason} ->
            "db.dets"
    end.

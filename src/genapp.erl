-module(genapp).

-export([start/0,
         parse_metadata/1,
         deploy/1,
         deploy/2,
	 undeploy/1,
	 query_apps/1,
	 query_app/2,
         get_env/1,
         get_env/2,
         priv_dir/0,
         mode/0,
	 app_env/1]).

-include("genapp.hrl").

start() ->
    e2_application:start_with_dependencies(genapp).

parse_metadata(File) ->
    genapp_metadata:parse_file(File).

deploy(PackageDir) ->
    genapp_tasks:start_deploy(PackageDir).

deploy(PackageDir, Options) ->
    genapp_tasks:start_deploy(PackageDir, Options).

undeploy(AppId) ->
    genapp_resource:delete_app_dir(AppId).

query_apps(Options) ->
    genapp_resource:query_apps(Options).

query_app(AppId, Options) ->
    genapp_resource:query_app(AppId, Options).

get_env(Name) ->
    handle_required_env(application:get_env(genapp, Name), Name).

get_env(Name, Default) ->
    handle_optional_env(application:get_env(genapp, Name), Default).

handle_required_env({ok, Value}, _Name) -> Value;
handle_required_env(undefined, Name) -> error({required_env, Name}).

handle_optional_env({ok, Value}, _Default) -> Value;
handle_optional_env(undefined, Default) -> Default.

priv_dir() ->
    Ebin = filename:dirname(code:which(?MODULE)),
    genapp_util:filename_join(filename:dirname(Ebin), "priv").

mode() ->
    handle_devmode_env(genapp:get_env(devmode, false)).

handle_devmode_env(true) -> devmode;
handle_devmode_env(false) -> normal;
handle_devmode_env(Other) -> error({invalid_devmode, Other}).

app_env(#app{id=Id}) -> app_env(Id);
app_env(AppId) ->
    [{"genapp_functions", genapp_functions_dir()},
     {"app_id", AppId},
     {"app_dir", app_dir(AppId)},
     {"app_user", genapp_user:app_user(AppId)},
     {"genapp_dir", genapp_dir:root(AppId)},
     {"control_dir", genapp_dir:subdir(AppId, ?GENAPP_CONTROL_SUBDIR)},
     {"log_dir", genapp_dir:subdir(AppId, ?GENAPP_LOG_SUBDIR)}].

genapp_functions_dir() ->
    genapp_util:filename_join(genapp:priv_dir(), "functions").

app_dir(AppId) ->
    handle_app_dir(genapp_resource:app_dir(AppId), AppId).

handle_app_dir({ok, Dir}, _AppId) -> Dir;
handle_app_dir(error, AppId) -> error({invalid_app, AppId}).

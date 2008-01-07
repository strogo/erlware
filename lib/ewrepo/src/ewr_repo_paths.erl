%%%-------------------------------------------------------------------
%%% Copyright: Eric Merritt, Martin Logan, Erlware
%%% File     : ewr_repo_dav.erl
%%% Author   : Martin Logan <martinjlogan@erlware.org>
%%%
%%% @doc This module houses respository structure aware functions in ewrepo. *Note* this file should not
%%%      contain any convenience functions or shortcuts.  Those should be placed in higher level modules so that this 
%%%      stays free of any clutter.
%%%
%%% <pre>
%%% Example Suffix Breakdown: 
%%%          /5.5.5/Generic/lib/mnesia/2.3 
%%%          ErtsVsn/Area/Side/PackageName/PackageVsn
%%%
%%%          /5.5.5/Generic/lib/mnesia/2.3/mnesia.tar.tz 
%%%          /5.5.5/Meta/release/sinan/1.0/sinan.rel
%%%          ErtsVsn/Area/Side/PackageName/PackageVsn/File
%%%
%%% Types:
%%%  Area = "Generic" | "Meta" | Architecture
%%%   Architecture = string()
%%%  Side = "lib" | "releases"
%%% </pre>
%%%
%%% @end
%%%
%%% Created : 30 Nov 2007 by Martin Logan <martinjlogan@erlware.org>
%%%-------------------------------------------------------------------
-module(ewr_repo_paths).

%%--------------------------------------------------------------------
%% Include files
%%--------------------------------------------------------------------
-include("eunit.hrl").
-include("ewrepo.hrl").

%%--------------------------------------------------------------------
%% External exports
%%--------------------------------------------------------------------
-export([
	 package_vsn_suffix/5,
	 package_name_suffix/4,
	 side_suffix/3,
	 area_suffix/2,
	 erts_suffix/1
        ]).

-export([
	 package_suffix/5,
	 erts_package_suffix/2,
	 dot_app_file_suffix/3,
	 dot_rel_file_suffix/3
        ]).

-export([
	 decompose_suffix/1
        ]).
%%====================================================================
%% External functions
%%====================================================================

%%====================================================================
%% The following functions return just paths as opposed to paths to files
%%====================================================================

%%--------------------------------------------------------------------
%% @doc Returns the suffix pointing to the repo location for a given erts version. 
%% @spec erts_suffix(ErtsVsn::string()) -> string()
%% @end 
%%--------------------------------------------------------------------
erts_suffix(ErtsVsn) when is_list(ErtsVsn) ->
    lists:flatten(["/", ErtsVsn]).

%%--------------------------------------------------------------------
%% @doc Returns the suffix pointing to the repo location for a given area. 
%% @spec area_suffix(ErtsVsn::string(), Area::string()) -> string()
%% @end 
%%--------------------------------------------------------------------
area_suffix(ErtsVsn, Area) when is_list(Area) ->
    ewl_file:join_paths(erts_suffix(ErtsVsn), Area).

%%--------------------------------------------------------------------
%% @doc Returns the suffix pointing to the repo location for a given side; lib, or releases, etc... 
%% @spec side_suffix(ErtsVsn::string(), Area::string(), Side::string()) -> string()
%% @end 
%%--------------------------------------------------------------------
%% TODO This first clause will be removed when Meta area gets Sides. This will happen after the new Sinan 0.9.0.0 is tested stable.
side_suffix(ErtsVsn, "Meta" = Area, Side) when Side == "lib"; Side == "releases" ->
    area_suffix(ErtsVsn, Area);
side_suffix(ErtsVsn, Area, Side) when Side == "lib"; Side == "releases" ->
    ewl_file:join_paths(area_suffix(ErtsVsn, Area), Side).

%%--------------------------------------------------------------------
%% @doc Returns the suffix pointing to the repo location for a given package name.
%% @spec package_name_suffix(ErtsVsn::string(), Area::string(), Side::string(), PackageName::string()) -> string()
%% @end 
%%--------------------------------------------------------------------
package_name_suffix(ErtsVsn, Area, Side, PackageName) when is_list(PackageName) ->
    ewl_file:join_paths(side_suffix(ErtsVsn, Area, Side), PackageName).
    
%%--------------------------------------------------------------------
%% @doc Returns the suffix pointing to the repo location for a given package name.
%% @spec package_vsn_suffix(ErtsVsn::string(), Area::string(), Side::string(), PackageName::string(), PackageVsn::string()) -> 
%%        string()
%% @end 
%%--------------------------------------------------------------------
package_vsn_suffix(ErtsVsn, Area, Side, PackageName, PackageVsn) when is_list(PackageVsn) ->
    ewl_file:join_paths(package_name_suffix(ErtsVsn, Area, Side, PackageName), PackageVsn).
    

%%====================================================================
%% The following functions return paths to actual files in the repo structure
%%====================================================================

%%--------------------------------------------------------------------
%% @doc Returns the suffix pointing to the tarball for a given erts vsn.
%% @spec erts_package_suffix(ErtsVsn::string(), Area::string()) -> string()
%% @end 
%%--------------------------------------------------------------------
erts_package_suffix(ErtsVsn, Area) when is_list(ErtsVsn) ->
    ewl_file:join_paths(area_suffix(ErtsVsn, Area), "erts.tar.gz").

%%--------------------------------------------------------------------
%% @doc Returns the suffix pointing to the actual package for the given name and version.
%% @spec package_suffix(ErtsVsn::string(), Area::string(), Side::string(), PackageName::string(), PackageVsn::string()) -> 
%%        string()
%% @end 
%%--------------------------------------------------------------------
package_suffix(ErtsVsn, Area, Side, PackageName, PackageVsn) when is_list(PackageVsn) ->
    lists:flatten([package_vsn_suffix(ErtsVsn, Area, Side, PackageName, PackageVsn), "/", PackageName, ".tar.gz"]).

%%--------------------------------------------------------------------
%% @doc Returns the suffix pointing to the .app file to be stored in the repo.
%% @spec dot_app_file_suffix(ErtsVsn::string(), AppName::string(), AppVsn::string()) -> 
%%        string()
%% @end 
%%--------------------------------------------------------------------
dot_app_file_suffix(ErtsVsn, AppName, AppVsn) when is_list(AppVsn) ->
    lists:flatten([package_vsn_suffix(ErtsVsn, "Meta", "lib", AppName, AppVsn), "/", AppName, ".app"]).

%%--------------------------------------------------------------------
%% @doc Returns the suffix pointing to the .rel file to be stored in the repo.
%% @spec dot_rel_file_suffix(ErtsVsn::string(), ReleaseName::string(), ReleaseVsn::string()) -> 
%%        string()
%% @end 
%%--------------------------------------------------------------------
dot_rel_file_suffix(ErtsVsn, ReleaseName, ReleaseVsn) when is_list(ReleaseVsn) ->
    lists:flatten([package_vsn_suffix(ErtsVsn, "Meta", "releases", ReleaseName, ReleaseVsn), "/", ReleaseName, ".rel"]).

%%====================================================================
%% Other External Functions
%%====================================================================

%%--------------------------------------------------------------------
%% @doc Returns the suffix pointing to the .rel file to be stored in the repo.
%% @spec decompose_suffix(Suffix) -> {ok, [Segment]} | {error, Reason}
%% where
%%  Segment = {Type, SegmentText}
%%   Type = erts_vsn | area | side | package_name | package_vsn | package
%% @end
%%--------------------------------------------------------------------
decompose_suffix(Suffix) ->
    Tokens = string:tokens(Suffix, "/"),
    try 
	analyse_tokens(Tokens)
    catch 
	_Class:Exception ->
	    Exception
    end.
	
%%====================================================================
%% Internal Functions
%%====================================================================

analyse_tokens([ErtsVsn|T]) ->
    case regexp:match(ErtsVsn, "^[0-9]+\.[0-9]+\.[0-9]+") of
	{match, 1, Length} when length(ErtsVsn) == Length ->
	    [{erts_vsn, ErtsVsn}|area(T)];
	_Error ->
	    throw({error, {bad_erts_vsn, ErtsVsn}})
    end.

area([]) ->	    
    [];
area(["Meta"|T]) ->	    
    [{area, "Meta"}|package_name(T)];
area([Area|T]) ->	    
    [{area, Area}|side(T)].

side([]) ->	    
    [];
side([Side|T]) when Side == "lib"; Side == "releases" ->
    [{side, Side}|package_name(T)];
side([Side|_]) ->
    throw({error, {bad_side, Side}}).

package_name([]) ->
    [];
package_name([PackageName|T]) ->
    case regexp:match(PackageName, "^" ++ ?PACKAGE_NAME_REGEXP) of
	{match, 1, Length} when length(PackageName) == Length ->
	    [{package_name, PackageName}|package_vsn(T)];
	_Error ->
	    throw({error, {bad_package_name, PackageName}})
    end.
    
package_vsn([]) ->
    [];
package_vsn([PackageVsn|T]) ->
    case regexp:match(PackageVsn, "^" ++ ?PACKAGE_VSN_REGEXP) of
	{match, 1, Length} when length(PackageVsn) == Length ->
	    [{package_vsn, PackageVsn}|package(T)];
	_Error ->
	    throw({error, {bad_package_vsn, PackageVsn}})
    end.

package([]) ->
    [];
package([Package]) ->
    case regexp:match(Package, ?PACKAGE_EXT_REGEXP) of
	{match, _, _} ->
	    [{package, Package}];
	_Error ->
	    throw({error, {bad_package, Package}})
    end.
    
    
%%====================================================================
%% Test Functions
%%====================================================================

dot_rel_file_suffix_test() ->
    ?assertMatch("/5.5.5/Meta/faxien/1.0/faxien.rel", dot_rel_file_suffix("5.5.5", "faxien", "1.0")).

erts_package_suffix_test() ->
    ?assertMatch("/5.5.5/myos/erts.tar.gz", erts_package_suffix("5.5.5", "myos")).

package_vsn_suffix_test() ->
    ?assertMatch("/5.5.5/Generic/lib/mnesia/1.0", package_vsn_suffix("5.5.5", "Generic", "lib", "mnesia", "1.0")).

decompose_suffix_test() ->
    ?assertMatch({error, {bad_erts_vsn, "5.5"}}, 
		 decompose_suffix("5.5/Generic/lib/gas/5.1.0/gas.tar.z")),

    ?assertMatch({error, {bad_package, "gas.tar.z"}}, 
		 decompose_suffix("5.5.5/Generic/lib/gas/5.1.0/gas.tar.z")),

    ?assertMatch([{erts_vsn, "5.5.5"}, {area, "Generic"}, {side, "lib"}],
		  decompose_suffix("5.5.5/Generic/lib")),

    ?assertMatch([{erts_vsn, "5.5.5"}, {area, "Generic"},
		  {side, "lib"}, {package_name, "gas"},
		  {package_vsn, "5.1.0"}, {package, "gas.tar.gz"}], 
		  decompose_suffix("5.5.5/Generic/lib/gas/5.1.0/gas.tar.gz")),

    ?assertMatch([{erts_vsn, "5.5.5"}, {area, "Generic"},
		  {side, "lib"}, {package_name, "gas"},
		  {package_vsn, "5.1-alpha"}, {package, "gas.tar.gz"}], 
		  decompose_suffix("5.5.5/Generic/lib/gas/5.1-alpha/gas.tar.gz")).
    

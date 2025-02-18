open! Import

module Cache_workflow : sig
  (** Kind of [ocamlmerlin] cache population to be simulated when running
      [ocamlmerlin]. *)
  type t =
    | Buffer_typed
    (* | File_hash_diff *)
    (* | Cmis_cached *)
    | No_cache

  val yojson_of_t : t -> Yojson.Safe.t
  val to_string : t -> string
  val description : t -> string

  val all : t list
  (** Contains all supported cache workflows. *)
end

type t
(** Configuration details and metadata about the [ocamlmerlin] to be used *)

val pp : Format.formatter -> t -> unit
val yojson_of_t : t -> Yojson.Safe.t

val make : ?comment:string -> Fpath.t -> Cache_workflow.t -> t
(** Create a [t] value by providing the path of where your [ocamlmerlin]
    executable lives and the frontend you want to be used and the id you want to
    attach to it. *)

val is_server : t -> bool
(** Returns [true] if the frontend is [Server] and [false] if it's [Single] *)

module Query_type : sig
  (** The [ocamlmerlin] queries that this tool can create analysis data for *)
  type t =
    | Case_analysis
    | Type_enclosing
    | Occurrences
    | Complete_prefix
    | Expand_prefix
    | Locate
    | Errors

  val yojson_of_t : t -> Yojson.Safe.t
  val to_string : t -> string

  val all : t list
  (** Returns a list of all [ocamlmerlin] queries that this tool creates
      benchmark data for*)

  val is_global : t -> bool
  (** Returns [true] if the query is run globally on a file; returns [false], if
      it needs a location speficied. *)

  (** The AST node types that can serve as target for (s)ome of the query types
      in [t] *)
  type node =
    | Longident
    | Expression
    | Var_pattern
    | Module_expr
    | Module_decl
    | Module_type_decl

  val has_target : t -> node -> bool
  (** [has_target query_type node] checks whether [query_type] can act on AST
      nodes of type [node] or not *)
end

module Response : sig
  type t
  (** Represents the response of an [ocamlmerlin] command *)

  val yojson_of_t : t -> Yojson.Safe.t

  type value_class = Msg of string | Empty | Other
  type return_class = Return of value_class | Failure | Error | Exception

  val yojson_of_return_class : return_class -> Yojson.Safe.t

  val get_timing : t -> int
  (** Extracts the information about time consumption from an [ocamlmerlin]
      response *)

  val crop_arbitrary_keys : string list -> t -> t
  (** [crop_arbitrary_keys keys x] Removes the various [keys] passed from the
      result. *)

  val strip_file : t -> t
  (** In a Merlin response of the form [{"value":{"file":file_dir, ...}, ...}],
      where [file_dir] is a qualified file name, this strips off the directory
      from [file_dir], keeping only its file base name.*)

  val strip_location : t -> t
  (** Strip the location in a Merlin response of class [Exception]. *)

  val get_return_class : t -> (return_class, Logs.t) result
  val get_query_num : t -> (int, Logs.t) result
end

module Cmd : sig
  type merlin

  type t
  (** Represents a concrete [ocamlmerlin] command including location and
      everything *)

  val yojson_of_t : t -> Yojson.Safe.t

  val make :
    query_type:Query_type.t ->
    file:File.t ->
    ?li:Longident.t ->
    ?loc:Location.t ->
    merlin ->
    (t, Logs.t) Result.t
  (** [make ~query_type ~file ~loc merlin] creates a concrete [ocamlmerlin]
      command by providing the following: the query [query_type]; the target of
      the query, i.e. the source code [file] and the location [loc] inside that
      file; and a [Merlin.t] value [merlin] *)

  val run : repeats:int -> t -> (Response.t list, Logs.t) Result.t
  (** [run ~repeats cmd] runs the concrete [ocamlmerlin] command [cmd]. It runs
      that command [repeat] times in a row and returns the [repeats] responses
  *)
end
with type merlin := t

val init_cache : File.t -> t -> (unit, Logs.t) Result.t
(** [init_cache file merlin] inits the [merlin] cache on [file]. This should be
    called if one of the frontends is [Server]. It inits the cache by running a
    global command on the file. *)

val stop_server : t -> unit
(** Stops the [ocamlmerlin] server. This should be called at the end of the
    whole process, if one of the frontends is [Server]; does nothing if the
    frontend is [Single] *)

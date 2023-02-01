open! Import

type update =
    id:int ->
    responses:Merlin.Response.t list ->
    cmd:Merlin.Cmd.t ->
    file:File.t ->
    loc:Warnings.loc ->
    query_type:Merlin.Query_type.t ->
    unit
module Make (Backend : Backend.T) : sig
  
 type t
(** The data that's being collected by the tool. Consists of two pieces of
    information: the configuration with which the data is collected
    (unmutable) and the data that's being collected step by step by the tool
    (mutable). *)

val init : Fpath.t -> t
(** [init ~pure dir_path] returns a data instance with empty mutable content.
    The provided path [dir_path] is the path of the directory, inside which
    the data will be persisted as json-line-files. If [pure] is true, then
    updating the created data instance will be a pure process, i.e. updating
    it twice with the same content yields the same result; in particular, no
    performance data is being added. *)

(* val update_analysis_data :
     id:int ->
     responses:Merlin.Response.t list ->
     cmd:Merlin.Cmd.t ->
     file:File.t ->
     loc:Warnings.loc ->
     query_type:Merlin.Query_type.t ->
     t ->
     unit
   (** [update_analysis_data ~id ~responses ~cmd ~file ~loc ~query_type data]
       appends the new pieces of data [responses], [cmd], [file], [loc] and
       [query_type], coming from the sample with id [id], to [data]. If [data] was
       initialized with [pure = false], then it also does computations to add some
       performance overview data to [data]. If [data] was initialized with
       [pure = true], then the un-pure part of the merlin response is being
       cropped. *)

   module Logs : sig
     type t = Error of string | Warning of string | Log of string
   end

   val update_log : log:Logs.t -> t -> unit
   (** [update_log ~log data] updates the log table of [data] with [log], as a way
       to persist logs. *)

   val update_metadata :
     proj_path:Fpath.t -> merlin:Merlin.t -> query_time:float option -> t -> unit
   (** Updates the metadata table of [data] with the arguments provided. It also
       adds some more metadata. Concretely, the commit sha of the project merlin is
       being analyzed on, the date, and the total time the tool has taken. For the
       last one to be accurate, it's important to call this function at the end of
       the process. Notice that those pieces of information are only being added,
       if the [data] wasn't initalized with [pure = true].*) *)

val update : t -> update

val persist_logs : log:Logs.t -> t -> unit

val persist_metadata : t -> proj_paths:Fpath.t list -> merlin:Merlin.t -> query_time:float -> unit

val dump : t -> unit
(** [dump data] writes the content of [data] into json-line files inside the
    directory of [data]. *)
end

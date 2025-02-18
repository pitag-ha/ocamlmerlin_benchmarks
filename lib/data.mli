open! Import

(* FIXME: once the tables structure is improved, this type should be split into several types and renamed *)
type sample = {
  id : int;
  responses : Merlin.Response.t list;
  cmd : Merlin.Cmd.t;
  file : File.t;
  loc : Location.t;
  query_type : Merlin.Query_type.t;
}

module Make (_ : Backend.Data_tables) : sig
  type t
  (** The data that's being collected by the tool. Consists of two pieces of
      information: the configuration with which the data is collected
      (unmutable) and the data that's being collected step by step by the tool
      (mutable). *)

  (* TODO: this shouldn't be only exactly merlins and dump_dir, but all configuration data. and the data should be stored in Data.t as well*)
  val init : Merlin.t -> Fpath.t -> t
  (** [init ~pure dir_path] returns a data instance with empty mutable content.
      The provided path [dir_path] is the path of the directory, inside which
      the data will be persisted as json-line-files. *)

  val init_cache : t -> bool

  val update : t -> sample -> unit
  (** Update the data by appending analyzis data of one sample to it. *)

  val persist_logs : log:Logs.t -> t -> unit
  (** Add the log to one of the data tables; the table will later be dumped to
      disk when dumping all tables. *)

  val wrap_up : t -> proj_paths:Fpath.t list -> unit
  (** Call this, before ending the program. It makes sure there's no data left
      in memory anymore and, in case there still is, dumps it (TODO!). Depending
      on the backend kind, it also generates and dumps some metadata. *)

  val dump : t -> unit
  (** [dump data] writes the content of [data] into json-line files. The
      directory, into which the files will be written, is part of the
      configuration data stored in the [Data.t] value. *)
end

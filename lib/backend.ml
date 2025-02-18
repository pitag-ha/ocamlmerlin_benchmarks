open! Import

type kind = Perf | Regr | Error_regr | Bench

module type Data_tables = sig
  type t

  val kind : kind
  val create_initial : Merlin.t -> t
  val init_cache : t -> bool

  val update_analysis_data :
    id:int ->
    responses:Merlin.Response.t list ->
    cmd:Merlin.Cmd.t ->
    file:File.t ->
    loc:Location.t ->
    query_type:Merlin.Query_type.t ->
    t ->
    unit

  val persist_logs : log:Logs.t -> t -> unit
  val dump : dump_dir:Fpath.t -> t -> unit
  val all_files : unit -> Fpath.t list

  val wrap_up :
    t -> dump_dir:Fpath.t -> proj_paths:Fpath.t list -> merlin:Merlin.t -> unit
end

module Field = struct
  (* A custom augmentation of [Fieldslib.Field] for [Data_tables.t] *)

  include Fieldslib.Field

  let to_filename field =
    let field_name = Fieldslib.Field.name field in
    Fpath.(add_ext ".json" @@ v field_name)

  let dump_single pp dump_dir tables field =
    let table_content = Fieldslib.Field.get field tables in
    let file_name = to_filename field in
    let file_path = Fpath.(to_string @@ append dump_dir file_name) in
    let oc = open_out file_path in
    Fun.protect
      ~finally:(fun () -> close_out_noerr oc)
      (fun () ->
        let ppf = Format.formatter_of_out_channel oc in
        pp ppf table_content)

  let dump pp dump_dir tables field =
    let write_json_lines ~pp ~ppf l =
      Format.pp_print_list ~pp_sep:Format.pp_print_newline pp ppf l
    in
    let table_content = Fieldslib.Field.get field tables in
    let file_name = to_filename field in
    let file_path = Fpath.(to_string @@ append dump_dir file_name) in
    let oc = open_out file_path in
    Fun.protect
      ~finally:(fun () -> close_out_noerr oc)
      (fun () ->
        let ppf = Format.formatter_of_out_channel oc in
        write_json_lines ~pp ~ppf table_content)

  let dump_opt pp dump_dir tables field =
    let write_json_lines ~pp ~ppf l =
      Format.pp_print_list ~pp_sep:Format.pp_print_newline pp ppf l
    in
    match Fieldslib.Field.get field tables with
    | Some content ->
        let file_name = to_filename field in
        let file_path = Fpath.(to_string @@ append dump_dir file_name) in
        let oc = open_out file_path in
        Fun.protect
          ~finally:(fun () -> close_out_noerr oc)
          (fun () ->
            let ppf = Format.formatter_of_out_channel oc in
            write_json_lines ~pp ~ppf content)
    | None -> ()
end

module P = struct
  type t = {
    sample_id : int;
    timings : int list;
    max_timing : int;
    file : File.t;
    query_type : Merlin.Query_type.t;
    loc : Location.t;
  }
  [@@deriving yojson_of]

  (* FIXME: print each of the sample repeats in a separate json field *)
  let pp ppf data =
    Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (yojson_of_t data))
end

module Query_response = struct
  type t = {
    sample_id : int;
    cmd : Merlin.Cmd.t;
    responses : Merlin.Response.t list;
  }
  [@@deriving yojson_of]

  (* FIXME: print the sample repeats in a separate json field *)
  let pp ppf data =
    Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (yojson_of_t data))
end

module Command = struct
  type t = { sample_id : int; cmd : Merlin.Cmd.t } [@@deriving yojson_of]

  let pp ppf data =
    Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (yojson_of_t data))
end

module Benchmark_metric = struct
  type t = { name : string; mutable value : int list; units : string }
  [@@deriving yojson_of] [@@warning "-unused-field"]
end

module StringMap = Map.Make (String)

module Benchmark_result = struct
  type t = { name : string; mutable metrics : Benchmark_metric.t StringMap.t }
  [@@warning "-unused-field"]

  let update (result : t) (metric : Benchmark_metric.t) =
    let f x =
      match x with
      | Some (me : Benchmark_metric.t) ->
          Some { me with value = List.append metric.value me.value }
      | None -> Some metric
    in
    { result with metrics = StringMap.update metric.name f result.metrics }

  let create name (metric : Benchmark_metric.t) =
    { name; metrics = StringMap.add metric.name metric StringMap.empty }

  (* TODO: Figure out a way to remove intermediate type *)
  type t1 = { name : string; metrics : Benchmark_metric.t list }
  [@@deriving yojson_of]

  let convert ({ name; metrics } : t) =
    { name; metrics = StringMap.bindings metrics |> List.map snd }
end

module Benchmark_summary = struct
  type t = { mutable results : Benchmark_result.t StringMap.t }

  (* TODO: Figure out a way to remove intermediate type *)
  type t1 = { results : Benchmark_result.t1 list } [@@deriving yojson_of]

  let pp ppf data =
    let convert ({ results } : t) =
      {
        results =
          StringMap.bindings results |> List.map snd
          |> List.map Benchmark_result.convert;
      }
    in
    Format.fprintf ppf "%s%!"
      (Yojson.Safe.to_string (yojson_of_t1 (convert data)))
end

module Distilled_data = struct
  type t = {
    sample_id : int;
    cmd : Merlin.Cmd.t;
    return : Merlin.Response.return_class option;
    query_num : int option;
  }
  [@@deriving yojson_of]

  (* FIXME: print the sample repeats in a separate json field *)
  let pp ppf data =
    Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (yojson_of_t data))
end

(* module Files = struct
     type kind = Ml | Mli
     type t = {
       file_id : string (* could be the hash of the content *)
       name : string option (* None, when using [--sanitize] *)
       len : int;
       functor_depth : int;
       num_first_class_modules : int;
       cmi_deps : t list; (* note: probably not a good idea to have t itself... *)
       cmt_deps : t list; (* note: probably not a good idea to have t itself... *)
       commit_sha : string option;
     }
     let get_commit_sha ~proj_path =
        let cmd = "git rev-parse HEAD" in
        try
          let cwd = Unix.getcwd () in
          Unix.chdir @@ Fpath.to_string proj_path;
          let ic = Unix.open_process_in cmd in
          Unix.chdir cwd;
          match input_line ic with
          | sha -> Ok sha
          | exception exc ->
              let err =
                Logs.Warning
                  (Format.sprintf
                     "Warning: something went wrong trying to get the commit sha \
                      of the source code project: %s"
                     (Printexc.to_string exc))
              in
              Error err
        with exc ->
          let err =
            Logs.Warning
              (Format.sprintf
                 "Warning: something went wrong trying to get the commit sha of \
                  the source code project: %s"
                 (Printexc.to_string exc))
          in
          Error err
   end *)

module Performance = struct
  (* TODO: add more data/restructure data, such as:
     - add a files "table" containing things like
        - the length of the file (size of AST)
        - in-file max functor depth
        - number of first-class modules shipped around in the file
        - number of cmi/cmt dependencies
        - commit sha of that file
     - have a finer-grained level than sample_id to allow dedicated fields for the repeats of one query
     - possibly: add a query_types "table":
        - all query types used in that `merl-an` run
        - the AST node type(s) corresponding to that query
        - the way the cache is being initialized for that query
        - the way the query is run
  *)
  type t = {
    mutable performances : P.t list;
    mutable query_responses : Query_response.t list;
    mutable commands : Command.t list;
    mutable logs : Logs.t list;
    merlin : Merlin.t;
  }
  [@@deriving fields]

  let init_cache p = Merlin.is_server p.merlin
  let kind = Perf

  let dump ~dump_dir t =
    let d = dump_dir in
    let () =
      Fields.iter ~performances:(Field.dump P.pp d t)
        ~query_responses:(Field.dump Query_response.pp d t)
        ~commands:(Field.dump Command.pp d t)
        ~logs:(Field.dump Logs.pp d t)
        ~merlin:(Field.dump_single Merlin.pp d t)
    in
    ()

  let update_analysis_data ~id ~responses ~cmd ~file ~loc ~query_type tables =
    let max_timing, timings, responses =
      (* FIXME: add json struture to the two lists *)
      let rec loop ~max_timing ~responses ~timings = function
        | [] -> (max_timing, timings, responses)
        | resp :: rest ->
            let timing = Merlin.Response.get_timing resp in
            let timings = timing :: timings in
            let responses = resp :: responses in
            let max_timing = Int.max timing max_timing in
            loop ~max_timing ~timings ~responses rest
      in
      loop ~max_timing:Int.min_int ~responses:[] ~timings:[] responses
    in
    let perf =
      { P.timings; max_timing; file; query_type; sample_id = id; loc }
    in
    let resp =
      (* TODO: make a cli-argument out of this instead of doing this always *)
      let responses =
        List.map
          (fun resp ->
            Merlin.Response.(
              crop_arbitrary_keys [ "value" ] @@ strip_location @@ resp))
          responses
      in
      { Query_response.sample_id = id; cmd; responses }
    in
    let cmd = { Command.sample_id = id; cmd } in
    tables.performances <- perf :: tables.performances;
    tables.query_responses <- resp :: tables.query_responses;
    tables.commands <- cmd :: tables.commands

  let persist_logs ~log tables = tables.logs <- log :: tables.logs

  let create_initial merlin =
    {
      performances = [];
      query_responses = [];
      commands = [];
      logs = [];
      merlin;
    }

  module Metadata = struct
    type t = {
      date : string option;
      proj : string list;
      total_time : float; (* query_time : float; *)
      merlin : Merlin.t;
    }
    [@@deriving yojson_of]

    let file_name = Fpath.v "metadata.json"

    let pp ppf data =
      Format.fprintf ppf "%s%!" (Yojson.Safe.to_string (yojson_of_t data))

    let get_date () =
      let epoch = Unix.time () |> Ptime.of_float_s |> Option.get in
      let (year, month, day), _ = Ptime.to_date_time epoch in
      Printf.sprintf "%i/%i/%i" day month year

    let produce_and_dump ~dump_dir ~proj_paths ~merlin =
      let metadata =
        let total_time = Sys.time () in
        let date = Some (get_date ()) in
        {
          date;
          proj = List.map Fpath.to_string proj_paths;
          total_time;
          merlin;
          (* query_time; *)
        }
      in
      let file_path = Fpath.(to_string @@ append dump_dir file_name) in
      let oc = open_out file_path in
      Fun.protect
        ~finally:(fun () -> close_out_noerr oc)
        (fun () ->
          let ppf = Format.formatter_of_out_channel oc in
          Format.fprintf ppf "%a" pp metadata)
  end

  let wrap_up _t ~dump_dir ~proj_paths ~merlin =
    (* TODO: check whether there's data left in memory and, if so, dump it *)
    Metadata.produce_and_dump ~dump_dir ~proj_paths ~merlin

  let all_files () =
    let f = Field.to_filename in
    Metadata.file_name
    :: Fields.to_list ~performances:f ~query_responses:f ~commands:f ~logs:f
         ~merlin:f
end

type behavior_config = { full : bool; distilled_data : bool }

let behavior config =
  let module Behavior = struct
    type t = {
      mutable full_responses : Query_response.t list option;
      mutable distilled_data : Distilled_data.t list option;
      mutable commands : Command.t list;
      mutable logs : Logs.t list;
    }
    [@@deriving fields]

    let kind = Regr

    let dump ~dump_dir t =
      let d = dump_dir in
      Fields.iter
        ~full_responses:(Field.dump_opt Query_response.pp d t)
        ~distilled_data:(Field.dump_opt Distilled_data.pp d t)
        ~commands:(Field.dump Command.pp d t)
        ~logs:(Field.dump Logs.pp d t)

    let persist_logs ~log tables = tables.logs <- log :: tables.logs

    let update_analysis_data ~id ~responses ~cmd ~file:_ ~loc:_ ~query_type:_
        tables =
      let command = { Command.sample_id = id; cmd } in
      tables.commands <- command :: tables.commands;
      let () =
        match tables.full_responses with
        | None -> ()
        | Some fr ->
            tables.full_responses <-
              (let resp =
                 let responses =
                   List.map
                     (fun resp ->
                       Merlin.Response.(
                         strip_file
                         @@ crop_arbitrary_keys
                              [ "timing"; "cache"; "heap_mbytes" ]
                         @@ strip_location @@ resp))
                     responses
                 in
                 { Query_response.sample_id = id; cmd; responses }
               in
               Some (resp :: fr))
      in
      match tables.distilled_data with
      | None -> ()
      | Some rc -> (
          match responses with
          | [ resp ] -> (
              match
                ( Merlin.Response.get_return_class resp,
                  Merlin.Response.get_query_num resp )
              with
              | Ok return, Ok query_num ->
                  let new_entry =
                    {
                      Distilled_data.sample_id = id;
                      return = Some return;
                      query_num = Some query_num;
                      cmd;
                    }
                  in
                  tables.distilled_data <- Some (new_entry :: rc)
              | Error log, Ok query_num ->
                  persist_logs ~log tables;
                  let new_entry =
                    {
                      Distilled_data.sample_id = id;
                      return = None;
                      query_num = Some query_num;
                      cmd;
                    }
                  in
                  tables.distilled_data <- Some (new_entry :: rc)
              | Ok return, Error log ->
                  persist_logs ~log tables;
                  let new_entry =
                    {
                      Distilled_data.sample_id = id;
                      return = Some return;
                      query_num = None;
                      cmd;
                    }
                  in
                  tables.distilled_data <- Some (new_entry :: rc)
              | Error log1, Error log2 ->
                  persist_logs ~log:log1 tables;
                  persist_logs ~log:log2 tables)
          | _ -> (*FIXME*) ())

    let create_initial _merlin =
      let full_responses = if config.full then Some [] else None in
      let distilled_data = if config.distilled_data then Some [] else None in
      { full_responses; distilled_data; commands = []; logs = [] }

    let wrap_up _t ~dump_dir:_ ~proj_paths:_ ~merlin:_ =
      (* TODO: check whether there's data left in memory and, if so, dump it *)
      ()

    let init_cache _ = false

    let all_files () =
      let f = Field.to_filename in
      Fields.to_list ~full_responses:f ~distilled_data:f ~commands:f ~logs:f
  end in
  (module Behavior : Data_tables)

module Benchmark = struct
  type t = {
    mutable bench : Benchmark_summary.t;
    mutable query_responses : Query_response.t list;
    mutable commands : Command.t list;
    mutable logs : Logs.t list;
    merlin : Merlin.t;
  }
  [@@deriving fields]

  let kind = Bench
  let init_cache b = Merlin.is_server b.merlin

  let create_initial merlin =
    {
      bench = { results = StringMap.empty };
      query_responses = [];
      commands = [];
      logs = [];
      merlin;
    }

  let persist_logs ~log tables = tables.logs <- log :: tables.logs

  let all_files () =
    let f = Field.to_filename in
    Fields.to_list ~bench:f ~query_responses:f ~commands:f ~logs:f ~merlin:f

  let dump ~dump_dir t =
    let d = dump_dir in
    let () =
      Fields.iter
        ~bench:(Field.dump_single Benchmark_summary.pp d t)
        ~query_responses:(Field.dump Query_response.pp d t)
        ~commands:(Field.dump Command.pp d t)
        ~logs:(Field.dump Logs.pp d t)
        ~merlin:(Field.dump_single Merlin.pp d t)
    in
    ()

  let update_analysis_data ~id ~responses ~cmd ~file:_file
      ~loc:(_loc : Import.location) ~query_type tables =
    let _max_timing, timings, responses =
      (* FIXME: add json struture to the two lists *)
      let rec loop ~max_timing ~responses ~timings = function
        | [] -> (max_timing, timings, responses)
        | resp :: rest ->
            let timing = Merlin.Response.get_timing resp in
            let timings = timing :: timings in
            let responses = resp :: responses in
            let max_timing = Int.max timing max_timing in
            loop ~max_timing ~timings ~responses rest
      in
      loop ~max_timing:Int.min_int ~responses:[] ~timings:[] responses
    in
    let resp =
      (* TODO: make a cli-argument out of this instead of doing this always *)
      let responses =
        List.map
          Merlin.Response.(
            fun resp ->
              crop_arbitrary_keys [ "value" ] @@ strip_location @@ resp)
          responses
      in
      { Query_response.sample_id = id; cmd; responses }
    in
    let cmd = { Command.sample_id = id; cmd } in
    let metric =
      {
        Benchmark_metric.name = Merlin.Query_type.to_string query_type;
        value = timings;
        units = "ms";
      }
    in
    (* TODO: Pass it instead of hardcoding *)
    let cache_workflow = Merlin.Cache_workflow.Buffer_typed in
    let upd = function
      | Some x -> Some (Benchmark_result.update x metric)
      | None ->
          Some
            (Benchmark_result.create
               (Merlin.Cache_workflow.to_string cache_workflow)
               metric)
    in
    let result =
      StringMap.update
        (Merlin.Cache_workflow.to_string cache_workflow)
        upd tables.bench.results
    in
    tables.bench.results <- result;
    tables.query_responses <- resp :: tables.query_responses;
    tables.commands <- cmd :: tables.commands

  let wrap_up _t ~dump_dir:_ ~proj_paths:_ ~merlin:_ = ()
end

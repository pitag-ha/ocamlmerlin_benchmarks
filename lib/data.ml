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

module Make (B : Backend.Data_tables) = struct
  (* TODO: should probably also contain `repeats` and all the other means of configuration  *)
  type t = { dump_dir : Fpath.t; mutable content : B.t; merlin : Merlin.t }
  [@@warning "-unused-field"]

  let create_dir_recursively data_path =
    let dir = Fpath.to_string data_path in
    if Sys.file_exists dir then (
      (* possible TODO: prompt would be nicer *)
      Format.printf
        "Your data directory %a already exists. So the data in there will be \
         overriden. Sure you want that?? If not, you should interrupt now.\n\
         %!"
        Fpath.pp data_path;
      Unix.sleep 60)
    else
      let rec get_all_subpaths acc = function
        | _ :: rest as all ->
            let acc = String.concat "/" (List.rev all) :: acc in
            get_all_subpaths acc rest
        | [] -> acc
      in

      Fpath.segs data_path |> List.rev |> get_all_subpaths []
      |> List.iter (fun dir -> try Sys.mkdir dir 0o777 with _ -> ())

  let init_cache d = B.init_cache d.content

  let create_files dir =
    List.iter (fun fn ->
        let path = Fpath.(to_string @@ append dir fn) in
        let descr = Unix.openfile path [ Unix.O_CREAT ] 0o777 in
        Unix.close descr)

  let some_file_isnt_writable data_path =
    List.exists (fun fn ->
        match open_out Fpath.(to_string @@ append data_path fn) with
        | exception _ -> true
        | oc ->
            close_out_noerr oc;
            false)

  (* TODO: this shouldn't be only exactly dump_dir, but all configuration data. and the data should be stored in Data.t as well*)
  let init merlin dump_dir =
    create_dir_recursively dump_dir;
    let tables = B.create_initial merlin in
    let data_files = B.all_files () in
    create_files dump_dir data_files;
    if some_file_isnt_writable dump_dir data_files then (
      Format.eprintf "It's not possible to write to the data files\n%!";
      exit 20)
    else { dump_dir; content = tables; merlin }

  let update t { id; responses; cmd; file; loc; query_type } =
    B.update_analysis_data ~id ~responses ~cmd ~file ~loc ~query_type t.content

  let persist_logs ~log { content; _ } = B.persist_logs ~log content

  let wrap_up { content; dump_dir; merlin } =
    B.wrap_up content ~dump_dir ~merlin

  let dump { dump_dir; content; _ } = B.dump ~dump_dir content
end

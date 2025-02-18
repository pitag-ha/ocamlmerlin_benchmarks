  $ merl-an behavior -s 1 -p test.ml,test1.ml --data=test-data

  $ cat test-data/distilled_data.json
  {"sample_id":13,"cmd":"ocamlmerlin server errors -filename test1.ml < test1.ml","return":["Return",["Other"]],"query_num":13}
  {"sample_id":12,"cmd":" ocamlmerlin server locate -look-for ml -position '3:12' -filename test1.ml < test1.ml","return":["Return",["Other"]],"query_num":12}
  {"sample_id":11,"cmd":"ocamlmerlin server expand-prefix -prefix '( +' -position '3:12' -filename test1.ml < test1.ml","return":["Return",["Other"]],"query_num":11}
  {"sample_id":10,"cmd":"ocamlmerlin server complete-prefix -prefix '( +' -position '3:12' -filename test1.ml < test1.ml","return":["Return",["Other"]],"query_num":10}
  {"sample_id":9,"cmd":"ocamlmerlin server occurrences -identifier-at '3:12' -filename test1.ml < test1.ml","return":["Return",["Other"]],"query_num":9}
  {"sample_id":8,"cmd":"ocamlmerlin server type-enclosing -position '3:12' -index 0 -filename test1.ml < test1.ml","return":["Return",["Other"]],"query_num":8}
  {"sample_id":7,"cmd":"ocamlmerlin server case-analysis -start '3:10' -end '3:14' -filename test1.ml < test1.ml","return":["Return",["Other"]],"query_num":7}
  {"sample_id":6,"cmd":"ocamlmerlin server errors -filename test.ml < test.ml","return":["Return",["Other"]],"query_num":6}
  {"sample_id":5,"cmd":" ocamlmerlin server locate -look-for ml -position '3:12' -filename test.ml < test.ml","return":["Return",["Other"]],"query_num":5}
  {"sample_id":4,"cmd":"ocamlmerlin server expand-prefix -prefix '( +' -position '3:12' -filename test.ml < test.ml","return":["Return",["Other"]],"query_num":4}
  {"sample_id":3,"cmd":"ocamlmerlin server complete-prefix -prefix '( +' -position '3:12' -filename test.ml < test.ml","return":["Return",["Other"]],"query_num":3}
  {"sample_id":2,"cmd":"ocamlmerlin server occurrences -identifier-at '3:12' -filename test.ml < test.ml","return":["Return",["Other"]],"query_num":2}
  {"sample_id":1,"cmd":"ocamlmerlin server type-enclosing -position '3:14' -index 0 -filename test.ml < test.ml","return":["Return",["Other"]],"query_num":1}
  {"sample_id":0,"cmd":"ocamlmerlin server case-analysis -start '3:10' -end '3:10' -filename test.ml < test.ml","return":["Return",["Other"]],"query_num":0}

(* FIXME: This is a problem in all tests: The build artefacts aren't found.*)
  $ cat test-data/full_responses.json | sed "/No config found for file/d"
  {"sample_id":12,"cmd":" ocamlmerlin server locate -look-for ml -position '3:12' -filename test1.ml < test1.ml","responses":[{"class":"return","value":{"file":"stdlib.ml","pos":{"line":92,"col":9}},"notifications":[],"query_num":12}]}
  {"sample_id":11,"cmd":"ocamlmerlin server expand-prefix -prefix '( +' -position '3:12' -filename test1.ml < test1.ml","responses":[{"class":"return","value":{"entries":[{"name":"()","kind":"Constructor","desc":"","info":"","deprecated":false}],"context":null},"notifications":[],"query_num":11}]}
  {"sample_id":10,"cmd":"ocamlmerlin server complete-prefix -prefix '( +' -position '3:12' -filename test1.ml < test1.ml","responses":[{"class":"return","value":{"entries":[],"context":["application",{"argument_type":"'a","labels":[]}]},"notifications":[],"query_num":10}]}
  {"sample_id":9,"cmd":"ocamlmerlin server occurrences -identifier-at '3:12' -filename test1.ml < test1.ml","responses":[{"class":"return","value":[{"start":{"line":3,"col":12},"end":{"line":3,"col":13}}],"notifications":[],"query_num":9}]}
  {"sample_id":8,"cmd":"ocamlmerlin server type-enclosing -position '3:12' -index 0 -filename test1.ml < test1.ml","responses":[{"class":"return","value":[{"start":{"line":3,"col":12},"end":{"line":3,"col":13},"type":"int -> int -> int","tail":"no"},{"start":{"line":3,"col":12},"end":{"line":3,"col":13},"type":1,"tail":"no"},{"start":{"line":3,"col":10},"end":{"line":3,"col":15},"type":2,"tail":"no"},{"start":{"line":3,"col":6},"end":{"line":3,"col":15},"type":3,"tail":"no"}],"notifications":[],"query_num":8}]}
  {"sample_id":7,"cmd":"ocamlmerlin server case-analysis -start '3:10' -end '3:14' -filename test1.ml < test1.ml","responses":[{"class":"return","value":[{"start":{"line":3,"col":10},"end":{"line":3,"col":15}},"match y + 3 with | 0 -> _ | _ -> _"],"notifications":[],"query_num":7}]}
  {"sample_id":5,"cmd":" ocamlmerlin server locate -look-for ml -position '3:12' -filename test.ml < test.ml","responses":[{"class":"return","value":{"file":"stdlib.ml","pos":{"line":92,"col":9}},"notifications":[],"query_num":5}]}
  {"sample_id":4,"cmd":"ocamlmerlin server expand-prefix -prefix '( +' -position '3:12' -filename test.ml < test.ml","responses":[{"class":"return","value":{"entries":[{"name":"()","kind":"Constructor","desc":"","info":"","deprecated":false}],"context":null},"notifications":[],"query_num":4}]}
  {"sample_id":3,"cmd":"ocamlmerlin server complete-prefix -prefix '( +' -position '3:12' -filename test.ml < test.ml","responses":[{"class":"return","value":{"entries":[],"context":["application",{"argument_type":"'a","labels":[]}]},"notifications":[],"query_num":3}]}
  {"sample_id":2,"cmd":"ocamlmerlin server occurrences -identifier-at '3:12' -filename test.ml < test.ml","responses":[{"class":"return","value":[{"start":{"line":3,"col":12},"end":{"line":3,"col":13}}],"notifications":[],"query_num":2}]}
  {"sample_id":1,"cmd":"ocamlmerlin server type-enclosing -position '3:14' -index 0 -filename test.ml < test.ml","responses":[{"class":"return","value":[{"start":{"line":3,"col":14},"end":{"line":3,"col":15},"type":"int","tail":"no"},{"start":{"line":3,"col":10},"end":{"line":3,"col":15},"type":1,"tail":"no"},{"start":{"line":3,"col":6},"end":{"line":3,"col":15},"type":2,"tail":"no"}],"notifications":[],"query_num":1}]}
  {"sample_id":0,"cmd":"ocamlmerlin server case-analysis -start '3:10' -end '3:10' -filename test.ml < test.ml","responses":[{"class":"return","value":[{"start":{"line":3,"col":10},"end":{"line":3,"col":11}},"(match y with | 0 -> _ | _ -> _)"],"notifications":[],"query_num":0}]}

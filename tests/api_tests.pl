:- begin_tests(interfaz_http).

:- use_module('../servidor').
:- use_module(library(http/http_open)).

pagina(Port,Ruta,Cuerpo) :-
    format(atom(Url),'http://127.0.0.1:~w/~w',[Port,Ruta]),
    setup_call_cleanup(http_open(Url,Stream,[]),
                       read_string(Stream,_,Cuerpo),
                       close(Stream)).

test(pagina_e_inventario, [nondet]) :-
    setup_call_cleanup(
        servidor:iniciar(Port),
        ( pagina(Port,'app',Html),
          sub_string(Html,_,_,_,'Gemelo digital del banco de sangre'),
          pagina(Port,'api/inventario',Json),
          sub_string(Json,_,_,_,'"inventario"'),
          sub_string(Json,_,_,_,'"globulos"') ),
        servidor:detener).

test(decision_y_conflicto, [nondet]) :-
    setup_call_cleanup(
        servidor:iniciar(Port),
        ( pagina(Port,'api/decidir?id=s1',Decision),
          sub_string(Decision,_,_,_,'"unidad":"u1"'),
          sub_string(Decision,_,_,_,'protege(s2)'),
          pagina(Port,'api/decidir?id=s3',Conflicto),
          sub_string(Conflicto,_,_,_,'no_se_sabe'),
          \+ sub_string(Conflicto,_,_,_,'"accion":"propuesta"') ),
        servidor:detener).

:- end_tests(interfaz_http).

:- begin_tests(interfaz_http).

:- use_module('../servidor').
:- use_module(library(http/http_open)).
:- use_module(library(http/json)).

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

test(reacomodo_y_cirugia_sin_cobertura, [nondet]) :-
    setup_call_cleanup(
        servidor:iniciar(Port),
        ( pagina(Port,'api/decidir?id=s2',Decision),
          sub_string(Decision,_,_,_,'"accion":"reacomodo"'),
          sub_string(Decision,_,_,_,'"repuesto":"u11"'),
          pagina(Port,'api/reservas',Reservas),
          sub_string(Reservas,_,_,_,'"cirugia":"cir1"'),
          sub_string(Reservas,_,_,_,'"cirugia":"cir2"'),
          sub_string(Reservas,_,_,_,'"estado":"sin_cobertura"') ),
        servidor:detener).

test(reserva_liberable_sin_sumarla_al_inventario, [nondet]) :-
    setup_call_cleanup(
        servidor:iniciar(Port),
        ( pagina(Port,'api/reservas',Respuesta),
          atom_string(Json,Respuesta),
          atom_json_dict(Json,Datos,[]),
          member(Cirugia,Datos.cirugias),
          Cirugia.cirugia == "cir3",
          Cirugia.estado == "liberable",
          Cirugia.unidad == "u9",
          member(Mensaje,Cirugia.evidencia),
          sub_string(Mensaje,_,_,_,"2 horas"),
          pagina(Port,'api/inventario',Inventario),
          atom_string(InventarioJson,Inventario),
          atom_json_dict(InventarioJson,Existencias,[]),
          member(Fila,Existencias.inventario),
          Fila.tipo == "b_pos",
          Fila.disponibles == 0 ),
        servidor:detener).

:- end_tests(interfaz_http).

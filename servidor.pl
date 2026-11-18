:- module(servidor, [iniciar/1, detener/0]).

:- use_module(reglas).
:- use_module(hechos).
:- use_module(library(http/http_server)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_parameters)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_files)).
:- dynamic puerto_servidor/1.

:- http_handler(root('api/inventario'), inventario_http, []).
:- http_handler(root('api/decidir'), decision_http, []).
:- http_handler(root('api/reservas'), reservas_http, []).
:- http_handler(root(app), pagina_http, []).

% Servidor independiente del Cowboy/Erlang; endpoints de solo lectura.
iniciar(Port) :-
    % Sólo loopback: datos simulados y sin autenticación.
    http_server(http_dispatch, [port(localhost:Port), workers(2)]),
    assertz(puerto_servidor(Port)).
detener :-
    retract(puerto_servidor(Port)),
    http_stop_server(localhost:Port, []).

pagina_http(Request) :-
    source_file(servidor:pagina_http(_), Archivo),
    file_directory_name(Archivo, Directorio),
    directory_file_path(Directorio, 'web/index.html', Pagina),
    % Ruta fija derivada del propio archivo fuente, nunca de la petición HTTP.
    http_reply_file(Pagina, [unsafe(true),cache(false)], Request).

inventario_http(_Request) :-
    findall(_{componente:"globulos",tipo:Nombre,disponibles:N},
            (reglas:existencias(globulos,Tipo,N), atom_string(Tipo,Nombre)),
            Filas),
    reply_json_dict(_{inventario:Filas,nota:"Fotografía educativa, no datos de Erlang"}).

decision_http(Request) :-
    http_parameters(Request, [id(IdTexto, [string])]),
    ( hechos:solicitud(Id,_,_,_,_), atom_string(Id,IdTexto) ->
        findall(_{decision:Json,explicacion:Mensajes,evidencia:Detalles},
                (reglas:decide(Id,Decision,Explicacion),
                 decision_json(Decision,Json),
                 maplist(term_string,Explicacion,Detalles),
                 maplist(explicacion_texto,Explicacion,Mensajes)),
                Opciones),
        reply_json_dict(_{solicitud:IdTexto,opciones:Opciones})
    ; reply_json_dict(_{error:"Solicitud ficticia desconocida"}, [status(404)])
    ).

reservas_http(_Request) :-
    findall(_{cirugia:Nombre,estado:"reacomodable",unidad:Original,
              repuesto:Repuesto,evidencia:Evidencia},
            (reglas:situacion(C,reserva_reacomodable(U,R),Prueba),
             atom_string(C,Nombre),atom_string(U,Original),
             atom_string(R,Repuesto),maplist(explicacion_texto,Prueba,Evidencia)),
            Reacomodables),
    findall(_{cirugia:Nombre,estado:"sin_cobertura",evidencia:Evidencia},
            (reglas:situacion(C,sin_cobertura,Prueba),
             atom_string(C,Nombre),maplist(explicacion_texto,Prueba,Evidencia)),
            SinCobertura),
    findall(_{cirugia:Nombre,estado:"liberable",unidad:Unidad,
              evidencia:Evidencia},
            (reglas:situacion(U,reserva_liberable(C),Prueba),
             atom_string(C,Nombre),atom_string(U,Unidad),
             maplist(explicacion_texto,Prueba,Evidencia)),
            Liberables),
    append([Reacomodables,SinCobertura,Liberables],Cirugias),
    reply_json_dict(_{cirugias:Cirugias,nota:"Propuestas; ninguna reserva se cambia"}).

decision_json(asignar(U,Tipo), _{accion:"propuesta",unidad:Id,tipo:Nombre}) :-
    atom_string(U,Id), atom_string(Tipo,Nombre).
decision_json(reacomodar(U,Cirugia,Repuesto),
              _{accion:"reacomodo",unidad:Id,cirugia:C,repuesto:R}) :-
    atom_string(U,Id),atom_string(Cirugia,C),atom_string(Repuesto,R).
decision_json(no_se_sabe(tipo_paciente), _{accion:"no_se_sabe",motivo:"tipo_paciente"}).
decision_json(sin_existencias, _{accion:"sin_existencias"}).

% La redacción de la explicación también vive en Prolog, no en JavaScript.
explicacion_texto(tipo_de(P,registros(Fuentes)),Texto) :-
    format(string(Texto),'Paciente ~w: tipo respaldado por ~w.',[P,Fuentes]).
explicacion_texto(elegida(U,Tipo),Texto) :-
    format(string(Texto),'La unidad ~w (~w) es compatible y utilizable.',[U,Tipo]).
explicacion_texto(comprobacion(Pruebas),Texto) :-
    format(string(Texto),'Evidencia de vigencia, prueba y liberación: ~w.',[Pruebas]).
explicacion_texto(descartada(U,protege(S)),Texto) :-
    format(string(Texto),'No se prefiere ~w: se conserva O negativo para ~w.',[U,S]).
explicacion_texto(descartada(U,orden_de_sustitucion),Texto) :-
    format(string(Texto),'~w no se eligió en esta alternativa por el orden de sustitución.',[U]).
explicacion_texto(conflicto_de_fuentes(P),Texto) :-
    format(string(Texto),'No se sabe el tipo de ~w: las fuentes no coinciden.',[P]).
explicacion_texto(sin_registro(P),Texto) :-
    format(string(Texto),'No se sabe el tipo de ~w: no hay registro.',[P]).
explicacion_texto(sin_unidad_compatible(T),Texto) :-
    format(string(Texto),'No hay unidad utilizable compatible con ~w.',[T]).
explicacion_texto(urgencia_entrega(S,U,Caduca),Texto) :-
    format(string(Texto),'La urgencia ~w podría recibir ~w: vence en la hora ~w.',[S,U,Caduca]).
explicacion_texto(reserva_original_inutil(C,U,Caduca,Hora),Texto) :-
    format(string(Texto),'La reserva ~w para ~w vence en ~w, antes de la cirugía en ~w.',
           [U,C,Caduca,Hora]).
explicacion_texto(cirugia_protegida(C,U,Caduca),Texto) :-
    format(string(Texto),'La cirugía ~w conservaría cobertura con ~w, vigente hasta ~w.',
           [C,U,Caduca]).
explicacion_texto(reserva_inutil(U),Texto) :-
    format(string(Texto),'La reserva ~w no seguirá vigente a la hora de la cirugía.',[U]).
explicacion_texto(repuesto_para(C,U),Texto) :-
    format(string(Texto),'La cirugía ~w puede reacomodarse con ~w.',[C,U]).
explicacion_texto(sin_reemplazo(C),Texto) :-
    format(string(Texto),'Con esta fotografía no hay repuesto libre para ~w.',[C]).
explicacion_texto(no_utilizada_confirmada(C,Hora),Texto) :-
    format(string(Texto),'Se confirmó que la reserva de ~w no se usó al terminar la cirugía en la hora ~w.',[C,Hora]).
explicacion_texto(margen_de_liberacion(Margen),Texto) :-
    format(string(Texto),'Ya transcurrió el margen ficticio de ~w horas tras la confirmación.',[Margen]).
explicacion_texto(propuesta_liberar(U),Texto) :-
    format(string(Texto),'Se puede proponer liberar ~w; sigue reservada hasta que se registre su liberación.',[U]).

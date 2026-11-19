:- encoding(utf8).
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
:- http_handler(root('api/incidente'), incidente_http, []).
:- http_handler(root('api/falla'), falla_http, []).
:- http_handler(root('api/accidente'), accidente_http, []).
:- http_handler(root('api/que-falta'), faltantes_http, []).
:- http_handler(root(app), pagina_http, []).

% Servidor independiente del Cowboy/Erlang; endpoints de solo lectura.
iniciar(Port) :-
    % Sólo loopback: acceso remoto mediante túnel SSH; sin autenticación HTTP.
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
    hechos:ahora(Hora),
    findall(_{componente:"globulos",tipo:Nombre,disponibles:N},
            (reglas:existencias(globulos,Tipo,N), atom_string(Tipo,Nombre)),
            Filas),
    reply_json_dict(_{hora:Hora,inventario:Filas,
                      nota:"Fotografía educativa, no datos de Erlang"}).

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

faltantes_http(Request) :-
    http_parameters(Request, [id(IdTexto, [string])]),
    ( (hechos:solicitud(Id,_,_,_,_); hechos:cirugia(Id,_,_,_,_);
       hechos:unidad(Id,_,_,_)), atom_string(Id,IdTexto) ->
        findall(_{objetivo:Objetivo,explicacion:Texto,evidencia:Pruebas},
                (reglas:que_falta(Id,Meta,Evidencia),
                 term_string(Meta,Objetivo),faltante_texto(Meta,Texto),
                 maplist(term_string,Evidencia,Pruebas)),
                Faltantes),
        reply_json_dict(_{consulta:IdTexto,faltantes:Faltantes,
                          nota:"Requisitos del modelo, no instrucciones clínicas"})
    ; reply_json_dict(_{error:"Identificador ficticio desconocido"}, [status(404)])
    ).

faltante_texto(tipo_confirmado(P),Texto) :-
    format(string(Texto),'Falta resolver con evidencia el conflicto entre registros del tipo de ~w.',[P]).
faltante_texto(tipificacion_registrada(P),Texto) :-
    format(string(Texto),'Falta registrar y confirmar el tipo de ~w; no se supone un tipo.',[P]).
faltante_texto(unidad_compatible(T),Texto) :-
    format(string(Texto),'No hay una unidad utilizable compatible con ~w en esta fotografía.',[T]).
faltante_texto(repuesto_vigente(C),Texto) :-
    format(string(Texto),'~w necesita una unidad libre compatible y vigente hasta la hora de cirugía.',[C]).
faltante_texto(liberacion_registrada(U),Texto) :-
    format(string(Texto),'La propuesta no libera ~w: falta registrar su liberación tras validarla.',[U]).

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

incidente_http(_Request) :-
    hechos:hora_incidente(Hora),
    findall(_{unidad:Id,explicacion:Mensajes,evidencia:Pruebas},
            (reglas:incidente(retirar,U,E),atom_string(U,Id),
             maplist(incidente_texto,E,Mensajes),maplist(term_string,E,Pruebas)),
            Retirar),
    findall(_{paciente:Id,explicacion:Mensajes,evidencia:Pruebas},
            (reglas:incidente(avisar,P,E),atom_string(P,Id),
             maplist(incidente_texto,E,Mensajes),maplist(term_string,E,Pruebas)),
            Avisar),
    findall(_{unidad:Id,explicacion:Mensajes,evidencia:Pruebas},
            (reglas:incidente(no_se_sabe,U,E),atom_string(U,Id),
             maplist(incidente_texto,E,Mensajes),maplist(term_string,E,Pruebas)),
            NoSeSabe),
    findall(_{cirugia:Id,explicacion:Mensajes,evidencia:Pruebas},
            (reglas:incidente(reserva_afectada,C,E),atom_string(C,Id),
             maplist(incidente_texto,E,Mensajes),maplist(term_string,E,Pruebas)),
            Reservas),
    reply_json_dict(_{hora:Hora,retirar:Retirar,avisar:Avisar,
                      no_se_sabe:NoSeSabe,reservas_afectadas:Reservas,
                      nota:"Escenario ficticio prospectivo; no se ejecutan retiros ni avisos"}).

incidente_texto(cadena(Donante,Donacion,U,Componente),Texto) :-
    format(string(Texto),'Donante ~w → donación ~w → unidad ~w (~w).',
           [Donante,Donacion,U,Componente]).
incidente_texto(prueba_positiva(D,Hora),Texto) :-
    format(string(Texto),'La prueba tardía de ~w dio positiva en la hora ~w.',[D,Hora]).
incidente_texto(estado_previo(liberada,Hora),Texto) :-
    format(string(Texto),'La unidad estaba liberada desde la hora ~w: se propone retirarla.',[Hora]).
incidente_texto(estado_previo(reservada(C),Hora),Texto) :-
    format(string(Texto),'La unidad estaba reservada para ~w desde la hora ~w: se propone retirarla.',[C,Hora]).
incidente_texto(transfundida_en(Hora),Texto) :-
    format(string(Texto),'La unidad se registró transfundida en la hora ~w.',[Hora]).
incidente_texto(receptor_confirmado(P),Texto) :-
    format(string(Texto),'El receptor registrado ~w debe ser avisado.',[P]).
incidente_texto(receptor_sin_registro,
               "No se sabe a quién avisar: falta el registro del receptor; no significa que no se transfundió.").
incidente_texto(unidad_retirada(U),Texto) :-
    format(string(Texto),'La unidad reservada ~w se propone retirar.',[U]).
incidente_texto(reserva_sin_cobertura_confirmada(C),Texto) :-
    format(string(Texto),'~w pierde su reserva; aún no se verificó un reemplazo de plasma.',[C]).

falla_http(_Request) :-
    hechos:ventana_falla(Inicio,Fin),
    findall(U,hechos:movimiento_falla(U,_,_,_),Todos),sort(Todos,Unidades),
    findall(_{unidad:Id,estado:EstadoTexto,titulo:Titulo,
              explicacion:Mensajes,evidencia:Pruebas},
            (member(U,Unidades),
             member(Estado,[comprometida,no_se_sabe,salvada]),
             once(reglas:falla(U,Estado,Evidencia)),
             atom_string(U,Id),atom_string(Estado,EstadoTexto),
             falla_titulo(U,Estado,Titulo),
             maplist(falla_texto,Evidencia,Mensajes),
             maplist(term_string,Evidencia,Pruebas)),
            Resultados),
    reply_json_dict(_{inicio:Inicio,fin:Fin,max_hueco_horas:2,
                      resultados:Resultados,nota:"Escenario ficticio con respaldo hipotético; ninguna unidad cambia de estado"}).

falla_titulo(U,comprometida,Texto) :-
    format(string(Texto),'~w · exposición confirmada (retiro propuesto)',[U]).
falla_titulo(U,no_se_sabe,Texto) :-
    format(string(Texto),'~w · no se sabe (evaluar / cuarentena propuesta)',[U]).
falla_titulo(U,salvada,Texto) :-
    format(string(Texto),'~w · sin exposición detectada en el modelo',[U]).

falla_texto(lectura_fuera_de_rango(E,Hora,Valor),Texto) :-
    format(string(Texto),'Expuesta en ~w a la lectura ~w en hora ~w, fuera del rango de su componente.',[E,Valor,Hora]).
falla_texto(sin_lectura(E,Inicio,Fin),Texto) :-
    format(string(Texto),'No se sabe la temperatura de ~w entre las horas ~w y ~w: supera el hueco tolerado de 2 horas.',[E,Inicio,Fin]).
falla_texto(tramos_monitorizados(Tramos),Texto) :-
    format(string(Texto),'Tramos con lecturas dentro de rango y sin huecos mayores de 2 horas: ~w.',[Tramos]).

accidente_http(_Request) :-
    hechos:hora_accidente(Hora),
    findall(_{decision:Json,explicacion:Mensajes,evidencia:Pruebas},
            (reglas:accidente(Decision,Evidencia),
             accidente_json(Decision,Json),
             maplist(accidente_texto,Evidencia,Mensajes),
             maplist(term_string,Evidencia,Pruebas)),
            Decisiones),
    reply_json_dict(_{hora:Hora,decisiones:Decisiones,
                      nota:"Accidente ficticio anterior a la reserva de u4; propuestas sin escritura"}).

accidente_json(asignar(S,U),_{accion:"asignar",solicitud:Solicitud,
                               unidad:Unidad,titulo:Titulo}) :-
    atom_string(S,Solicitud),atom_string(U,Unidad),
    format(string(Titulo),'Asignación propuesta · ~w → ~w',[S,U]).
accidente_json(sin_cobertura(S),_{accion:"sin_cobertura",solicitud:Solicitud,
                                     titulo:Titulo}) :-
    atom_string(S,Solicitud),format(string(Titulo),'Sin cobertura · ~w',[S]).
accidente_json(no_se_sabe(S),_{accion:"no_se_sabe",solicitud:Solicitud,
                                  titulo:Titulo}) :-
    atom_string(S,Solicitud),format(string(Titulo),'No se sabe el tipo · ~w',[S]).
accidente_json(nivel_critico(T),_{accion:"nivel_critico",tipo:Tipo,
                                     titulo:Titulo}) :-
    atom_string(T,Tipo),format(string(Titulo),'Nivel crítico · ~w',[T]).

accidente_texto(prioridad(tipo_confirmado),"Prioridad ficticia: tipo O negativo confirmado antes que paciente sin tipificar.").
accidente_texto(prioridad(sin_tipificar),"Sin tipificar: solo se considera O negativo en este escenario.").
accidente_texto(unidad_restante(U,C),Texto) :-
    format(string(Texto),'La unidad utilizable ~w vence en hora ~w y no se asigna dos veces.',[U,C]).
accidente_texto(demanda_sin_unidad(S),Texto) :-
    format(string(Texto),'La solicitud ~w queda sin unidad en este reparto.',[S]).
accidente_texto(unidades_agotadas,"Las unidades O negativo restantes se asignaron a solicitudes anteriores.").
accidente_texto(conflicto_de_fuentes(P),Texto) :-
    format(string(Texto),'No se sabe el tipo de ~w: expediente y pulsera discrepan; no se le asigna unidad.',[P]).
accidente_texto(restantes(N),Texto) :-
    format(string(Texto),'Quedan ~w unidades O negativo utilizables tras el consumo simulado, antes del reparto.',[N]).
accidente_texto(umbral(U),Texto) :-
    format(string(Texto),'Umbral crítico educativo: menos de ~w unidades.',[U]).
accidente_texto(consumidas(Us),Texto) :-
    format(string(Texto),'El accidente consume las unidades ficticias ~w.',[Us]).

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

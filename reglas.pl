:- module(reglas, [compatible/2, decide/3, situacion/3, existencias/3]).

:- use_module(hechos).
:- use_module(library(lists)).

% Fase 1: compatibilidad de GLOBULOS ROJOS; plasma y plaquetas tienen
% compatibilidad distinta y aquí NO se les aplica esta tabla.
tipo(o_neg,o,neg).   tipo(o_pos,o,pos).
tipo(a_neg,a,neg).   tipo(a_pos,a,pos).
tipo(b_neg,b,neg).   tipo(b_pos,b,pos).
tipo(ab_neg,ab,neg). tipo(ab_pos,ab,pos).

abo_ok(o,_).
abo_ok(A,A) :- memberchk(A,[a,b,ab]).
abo_ok(a,ab).
abo_ok(b,ab).

compatible(Donante,Receptor) :-
    tipo(Donante,AD,RD), tipo(Receptor,AR,RR),
    abo_ok(AD,AR), (RD == neg -> true ; RR == pos).

% Si falta un registro o dos fuentes se contradicen, no inferimos un tipo.
tipo_paciente(Paciente,Tipo,Evidencia) :-
    findall(T-F, hechos:tipo_registrado(Paciente,F,T), Registros),
    Registros \= [],
    findall(T, member(T-_,Registros), Tipos0), sort(Tipos0,[Tipo]),
    Evidencia = registros(Registros).

tipo_desconocido(Paciente,conflicto_de_fuentes(Paciente)) :-
    findall(T, hechos:tipo_registrado(Paciente,_,T), Tipos0),
    sort(Tipos0,Tipos), length(Tipos,N), N > 1.
tipo_desconocido(Paciente,sin_registro(Paciente)) :-
    \+ hechos:tipo_registrado(Paciente,_,_).

% El último evento explícito y la prueba del donante respaldan la oferta.
ultimo_evento(U,Estado,Hora) :-
    findall(H-E, (hechos:evento_unidad(U,E,H), hechos:ahora(A), H =< A), Pares),
    Pares \= [], keysort(Pares,Orden), last(Orden,Hora-Estado).

situacion(Paciente,tipo_paciente(no_se_sabe),[Motivo]) :-
    tipo_desconocido(Paciente,Motivo).
situacion(Paciente,tipo_paciente(Tipo),[Evidencia]) :-
    tipo_paciente(Paciente,Tipo,Evidencia).

situacion(U,utilizable,
          [liberada_en(Hora),prueba_negativa(D,HPrueba),
           ubicada(Equipo,Desde),vigente_hasta(Caduca)]) :-
    hechos:ahora(Ahora), hechos:unidad(U,D,globulos,Caduca),
    Caduca > Ahora,
    ultimo_evento(U,liberada,Hora),
    hechos:prueba(D,negativa,HPrueba), HPrueba =< Ahora,
    \+ (hechos:prueba(D,positiva,HPositiva), HPositiva =< Ahora),
    hechos:ubicacion(U,Equipo,Desde), Desde =< Ahora.

existencias(globulos,Tipo,N) :-
    tipo(Tipo,_,_),
    findall(U,(hechos:unidad(U,D,globulos,_),hechos:donacion(D,_,Tipo,_),
               situacion(U,utilizable,_)), Unidades),
    length(Unidades,N).

versatilidad(Donante,N) :-
    findall(R,(tipo(R,_,_),compatible(Donante,R)), Receptores),
    length(Receptores,N).

% Prioridad declarada: exacto -> menor versatilidad -> tipo -> FEFO -> ID.
% Umbrales clínicos, reservas y lecturas fuera de rango NO se inventan aquí.
candidato(Receptor,k(Exacto,Versatilidad,Tipo,Caduca,U)-c(U,Tipo)) :-
    hechos:unidad(U,D,globulos,Caduca),
    hechos:donacion(D,_,Tipo,_),
    compatible(Tipo,Receptor), situacion(U,utilizable,_),
    (Tipo == Receptor -> Exacto = 0, Versatilidad = 0 ;
                         Exacto = 1, versatilidad(Tipo,Versatilidad)).

candidatos(Receptor,Ordenados) :-
    findall(P,candidato(Receptor,P),Pares),
    keysort(Pares,Ordenados).

% El paciente O- confirmado s2 solo puede usar glóbulos O- en esta foto:
% esto explica por qué una alternativa universal se guarda para él.
protege(U,S) :-
    hechos:unidad(U,D,globulos,_), hechos:donacion(D,_,o_neg,_),
    hechos:solicitud(S,P,globulos,_,_), tipo_paciente(P,o_neg,_),
    situacion(U,utilizable,_).

motivo_descarte(U,S,protege(S)) :- protege(U,S), !.
motivo_descarte(_,_,orden_de_sustitucion).

explicar(Elegido,Tipo,Paciente,Evidencia,Orden,Explicacion) :-
    findall(descartada(Otro,Motivo),
            (member(_-c(Otro,_),Orden), Otro \== Elegido,
             motivo_descarte(Otro,_,Motivo)), Descartadas),
    situacion(Elegido,utilizable,Prueba),
    Explicacion = [tipo_de(Paciente,Evidencia),elegida(Elegido,Tipo),
                   comprobacion(Prueba)|Descartadas].

decide(S,no_se_sabe(tipo_paciente),[Motivo]) :-
    hechos:solicitud(S,Paciente,globulos,_,_),
    tipo_desconocido(Paciente,Motivo).
decide(S,asignar(U,Tipo),Explicacion) :-
    hechos:solicitud(S,Paciente,globulos,1,_),
    tipo_paciente(Paciente,Receptor,Evidencia),
    candidatos(Receptor,Orden),
    member(_-c(U,Tipo),Orden),
    explicar(U,Tipo,Paciente,Evidencia,Orden,Explicacion).
decide(S,sin_existencias,[sin_unidad_compatible(Receptor)]) :-
    hechos:solicitud(S,Paciente,globulos,1,_),
    tipo_paciente(Paciente,Receptor,_),
    candidatos(Receptor,[]).

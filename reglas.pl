:- encoding(utf8).
:- module(reglas, [compatible/2, decide/3, situacion/3, existencias/3,
                   incidente/3, falla/3, accidente/2, que_falta/3]).

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
    hechos:ahora(A), ultimo_evento_hasta(U,A,Estado,Hora).

ultimo_evento_hasta(U,A,Estado,Hora) :-
    findall(H-E, (hechos:evento_unidad(U,E,H), H =< A), Pares),
    Pares \= [], keysort(Pares,Orden), last(Orden,Hora-Estado).

% Situación 3: horizonte hipotético 102, distinto de la foto base (100).
% Solo se inspeccionan las donaciones con resultado positivo documentado;
% no se infiere contaminación de otras donaciones del mismo donante.
cadena_positiva(U,Donante,D,Componente,HoraPositiva,Estado,HoraEstado) :-
    hechos:hora_incidente(A),
    hechos:unidad(U,D,Componente,_),
    hechos:donacion(D,Donante,_,_),
    hechos:prueba(D,positiva,HoraPositiva), HoraPositiva =< A,
    ultimo_evento_hasta(U,A,Estado,HoraEstado).

incidente(retirar,U,[cadena(Donante,D,U,Componente),
                      prueba_positiva(D,HoraPositiva),
                      estado_previo(Estado,HoraEstado)]) :-
    cadena_positiva(U,Donante,D,Componente,HoraPositiva,Estado,HoraEstado),
    memberchk(Estado,[liberada,reservada(_)]).

incidente(avisar,Paciente,[cadena(Donante,D,U,Componente),
                           prueba_positiva(D,HoraPositiva),
                           transfundida_en(Hora),receptor_confirmado(Paciente)]) :-
    cadena_positiva(U,Donante,D,Componente,HoraPositiva,transfundida,Hora),
    hechos:receptor_unidad(U,Paciente,Hora).

incidente(no_se_sabe,U,[cadena(Donante,D,U,Componente),
                        prueba_positiva(D,HoraPositiva),
                        transfundida_en(Hora),receptor_sin_registro]) :-
    cadena_positiva(U,Donante,D,Componente,HoraPositiva,transfundida,Hora),
    \+ hechos:receptor_unidad(U,_,Hora).

incidente(reserva_afectada,Cirugia,[unidad_retirada(U),
            reserva_sin_cobertura_confirmada(Cirugia)]) :-
    incidente(retirar,U,_),
    cadena_positiva(U,_,_,_,_,reservada(Cirugia),_),
    hechos:cirugia(Cirugia,_,_,_,_).

% Situación 4: una muestra fuera de rango basta para marcar exposición;
% un hueco mayor de 2 horas impide afirmar que no hubo exposición.
sensor(globulos,temp_globulos).
sensor(plasma,temp_plasma).
sensor(plaquetas,temp_plaquetas).

muestra_fuera(U,E,H,Valor) :-
    hechos:movimiento_falla(U,E,Desde,Hasta),
    hechos:unidad(U,_,Componente,_), sensor(Componente,Sensor),
    hechos:lectura_falla(E,Sensor,Valor,H),
    Desde =< H, H < Hasta,
    hechos:rango(Sensor,Min,Max), (Valor < Min ; Valor > Max).

hueco_unidad(U,E,Primera,Segunda) :-
    hechos:movimiento_falla(U,E,Desde,Hasta),
    hechos:unidad(U,_,Componente,_), sensor(Componente,Sensor),
    hechos:lectura_falla(E,Sensor,_,Primera),
    hechos:lectura_falla(E,Sensor,_,Segunda),
    Primera < Segunda, Segunda - Primera > 2,
    \+ (hechos:lectura_falla(E,Sensor,_,Intermedia),
        Primera < Intermedia, Intermedia < Segunda),
    Desde < Segunda, Hasta > Primera.

tramo_cubierto(U,E,Desde,Hasta) :-
    hechos:movimiento_falla(U,E,Desde,Hasta),
    hechos:unidad(U,_,Componente,_), sensor(Componente,Sensor),
    hechos:lectura_falla(E,Sensor,_,Anterior),
    Anterior =< Desde, Desde - Anterior =< 2,
    \+ (hechos:lectura_falla(E,Sensor,_,MasCerca),
        Anterior < MasCerca, MasCerca =< Desde),
    hechos:lectura_falla(E,Sensor,_,Posterior),
    Posterior >= Hasta, Posterior - Hasta =< 2,
    \+ (hechos:lectura_falla(E,Sensor,_,MasCerca),
        Hasta =< MasCerca, MasCerca < Posterior),
    \+ hueco_unidad(U,E,_,_).

falla(U,comprometida,[lectura_fuera_de_rango(E,H,Valor)]) :-
    muestra_fuera(U,E,H,Valor).
falla(U,no_se_sabe,[sin_lectura(E,Primera,Segunda)]) :-
    hechos:movimiento_falla(U,_,_,_),
    \+ muestra_fuera(U,_,_,_),
    hueco_unidad(U,E,Primera,Segunda).
falla(U,salvada,[tramos_monitorizados(Tramos)]) :-
    hechos:movimiento_falla(U,_,_,_),
    \+ muestra_fuera(U,_,_,_),
    \+ hueco_unidad(U,_,_,_),
    findall(E-Desde-Hasta,hechos:movimiento_falla(U,E,Desde,Hasta),Tramos),
    Tramos \= [],
    forall(member(E-Desde-Hasta,Tramos),tramo_cubierto(U,E,Desde,Hasta)).

% Situación 5: foto contrafactual anterior a la reserva de u4.
candidata_accidente(U,Tipo,Caduca) :-
    hechos:hora_accidente(Hora),
    hechos:unidad(U,D,globulos,Caduca), Caduca > Hora,
    hechos:donacion(D,_,Tipo,_),
    ultimo_evento_hasta(U,Hora,liberada,_),
    hechos:ubicacion(U,_,Desde), Desde =< Hora,
    hechos:prueba(D,negativa,Prueba), Prueba =< Hora,
    \+ (hechos:prueba(D,positiva,Positiva),Positiva =< Hora).

unidad_accidente(U,Tipo,Caduca) :-
    candidata_accidente(U,Tipo,Caduca),
    \+ hechos:consumo_accidente(U).

consumo_valido :-
    findall(U,hechos:consumo_accidente(U),Unidades),
    sort(Unidades,Unicas), length(Unidades,N),length(Unicas,N),
    forall(member(U,Unidades),candidata_accidente(U,o_neg,_)).

solicitud_accidente(S,0,tipo_confirmado) :-
    hechos:solicitud(S,P,globulos,1,emergencia),
    tipo_paciente(P,o_neg,_).
solicitud_accidente(S,1,sin_tipificar) :-
    hechos:solicitud(S,P,globulos,1,emergencia),
    tipo_desconocido(P,sin_registro(P)).

reparto_accidente(Solicitudes,Unidades) :-
    consumo_valido,
    findall(P-S-M,solicitud_accidente(S,P,M),Pares),
    keysort(Pares,Solicitudes),
    findall(C-U,unidad_accidente(U,o_neg,C),Candidatas),
    keysort(Candidatas,Unidades).

accidente(asignar(S,U),[prioridad(Motivo),unidad_restante(U,Caduca)]) :-
    reparto_accidente(Solicitudes,Unidades),
    nth0(Pos,Solicitudes,_-S-Motivo),
    nth0(Pos,Unidades,Caduca-U).
accidente(sin_cobertura(S),[demanda_sin_unidad(S),unidades_agotadas]) :-
    reparto_accidente(Solicitudes,Unidades),
    nth0(Pos,Solicitudes,_-S-_),
    length(Unidades,Disponibles), Pos >= Disponibles.
accidente(no_se_sabe(S),[conflicto_de_fuentes(P)]) :-
    hechos:solicitud(S,P,globulos,1,emergencia),
    tipo_desconocido(P,conflicto_de_fuentes(P)).
accidente(nivel_critico(o_neg),[restantes(N),umbral(Umbral),
                                 consumidas(Consumidas)]) :-
    consumo_valido,
    hechos:umbral_critico(o_neg,Umbral),
    findall(U,unidad_accidente(U,o_neg,_),Libres),length(Libres,N),
    N < Umbral,
    findall(U,hechos:consumo_accidente(U),Consumidas).

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

% La reserva existe, pero la bolsa no seguirá vigente a la hora de la cirugía.
situacion(U,reserva_inutil(Cirugia),[reservada_para(Cirugia),
           caduca_antes_de_cirugia(Caduca,HoraCirugia)]) :-
    hechos:unidad(U,_,globulos,Caduca),
    ultimo_evento(U,reservada(Cirugia),_),
    hechos:cirugia(Cirugia,_,HoraCirugia,globulos,_),
    Caduca =< HoraCirugia.

situacion(Cirugia,reserva_reacomodable(U,Repuesto),
          [reserva_inutil(U),repuesto_para(Cirugia,Repuesto)]) :-
    situacion(U,reserva_inutil(Cirugia),_),
    repuesto_preferido(Cirugia,Repuesto).

situacion(Cirugia,sin_cobertura,[reserva_inutil(U),sin_reemplazo(Cirugia)]) :-
    situacion(U,reserva_inutil(Cirugia),_),
    \+ repuesto_preferido(Cirugia,_).

% Ausencia de transfusión NO basta: exigimos el evento explícito de no uso.
% Esta regla solo propone liberar; no muta el estado ni suma la bolsa al stock.
situacion(U,reserva_liberable(Cirugia),
          [no_utilizada_confirmada(Cirugia,HoraConfirmacion),
           margen_de_liberacion(Margen),propuesta_liberar(U)]) :-
    hechos:ahora(Ahora), hechos:margen_liberacion(Margen),
    hechos:unidad(U,D,globulos,Caduca), Caduca > Ahora,
    ultimo_evento(U,cirugia_terminada_sin_uso(Cirugia),HoraConfirmacion),
    hechos:evento_unidad(U,reservada(Cirugia),HoraReserva),
    HoraReserva < HoraConfirmacion,
    hechos:cirugia(Cirugia,_,HoraCirugia,globulos,_),
    HoraCirugia =< HoraConfirmacion,
    Ahora >= HoraConfirmacion + Margen,
    hechos:ubicacion(U,_,Desde), Desde =< Ahora,
    hechos:prueba(D,negativa,HPrueba), HPrueba =< Ahora,
    \+ (hechos:prueba(D,positiva,HPositiva),HPositiva =< Ahora).

existencias(globulos,Tipo,N) :-
    tipo(Tipo,_,_),
    findall(U,(hechos:unidad(U,D,globulos,_),hechos:donacion(D,_,Tipo,_),
               situacion(U,utilizable,_)), Unidades),
    length(Unidades,N).

versatilidad(Donante,N) :-
    findall(R,(tipo(R,_,_),compatible(Donante,R)), Receptores),
    length(Receptores,N).

% Prioridad declarada: exacto -> menor versatilidad -> tipo -> FEFO -> ID.
% Umbrales clínicos y lecturas fuera de rango NO se inventan aquí.
candidato(Receptor,k(Exacto,Versatilidad,Tipo,Caduca,U)-c(U,Tipo)) :-
    hechos:unidad(U,D,globulos,Caduca),
    hechos:donacion(D,_,Tipo,_),
    compatible(Tipo,Receptor), situacion(U,utilizable,_),
    (Tipo == Receptor -> Exacto = 0, Versatilidad = 0 ;
                         Exacto = 1, versatilidad(Tipo,Versatilidad)).

candidatos(Receptor,Ordenados) :-
    findall(P,candidato(Receptor,P),Pares),
    keysort(Pares,Ordenados).

% El repuesto debe ser libre ahora y SEGUIR vigente a la hora de cirugía;
% se usa la misma compatibilidad y orden de sustitución del escenario 1.
candidato_repuesto(Cirugia,k(Exacto,V,Tipo,Caduca,U)-U) :-
    hechos:cirugia(Cirugia,Paciente,Hora,globulos,1),
    tipo_paciente(Paciente,Receptor,_),
    hechos:unidad(U,D,globulos,Caduca), Caduca > Hora,
    hechos:donacion(D,_,Tipo,_), compatible(Tipo,Receptor),
    situacion(U,utilizable,_),
    (Tipo == Receptor -> Exacto=0,V=0 ; Exacto=1,versatilidad(Tipo,V)).

repuesto_preferido(Cirugia,U) :-
    findall(P,candidato_repuesto(Cirugia,P),Candidatos),
    keysort(Candidatos,[_-U|_]).

% Solo se considera reacomodar una reserva INÚTIL para su propia cirugía, y
% únicamente si queda cubierta con una unidad libre que dure hasta ella.
% No se altera ninguna reserva: es una propuesta contrafactual.
plan_reacomodo(S,U,Cirugia,Repuesto,Caduca,HoraCirugia) :-
    hechos:solicitud(S,Paciente,globulos,1,emergencia),
    tipo_paciente(Paciente,Receptor,_),
    situacion(U,reserva_inutil(Cirugia),_),
    hechos:unidad(U,D,globulos,Caduca), hechos:ahora(Ahora), Caduca > Ahora,
    hechos:donacion(D,_,Tipo,_), compatible(Tipo,Receptor),
    hechos:prueba(D,negativa,HPrueba), HPrueba =< Ahora,
    \+ (hechos:prueba(D,positiva,HPositiva),HPositiva =< Ahora),
    hechos:ubicacion(U,_,Desde), Desde =< Ahora,
    hechos:cirugia(Cirugia,_,HoraCirugia,globulos,1),
    repuesto_preferido(Cirugia,Repuesto),
    % FEFO y el orden de tipo también se aplican frente a unidades libres.
    findall(K-libre,candidato(Receptor,K-_),Libres),
    findall(K-reacomodo(R,C,Rp),
            (situacion(R,reserva_inutil(C),_),
             hechos:unidad(R,DR,globulos,CR), CR > Ahora,
             hechos:donacion(DR,_,TR,_), compatible(TR,Receptor),
             hechos:prueba(DR,negativa,HR), HR =< Ahora,
             \+ (hechos:prueba(DR,positiva,HP), HP =< Ahora),
             hechos:ubicacion(R,_,Ubicada), Ubicada =< Ahora,
             repuesto_preferido(C,Rp),
             (TR == Receptor -> X=0,V=0 ; X=1,versatilidad(TR,V)),
             K=k(X,V,TR,CR,R)), Reservadas),
    append(Libres,Reservadas,Opciones),
    keysort(Opciones,[_-reacomodo(U,Cirugia,Repuesto)|_]).

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
decide(S,reacomodar(U,Cirugia,Repuesto),
       [urgencia_entrega(S,U,Caduca),
        reserva_original_inutil(Cirugia,U,Caduca,HoraCirugia),
        cirugia_protegida(Cirugia,Repuesto,CaducaRepuesto)]) :-
    plan_reacomodo(S,U,Cirugia,Repuesto,Caduca,HoraCirugia),
    hechos:unidad(Repuesto,_,globulos,CaducaRepuesto).
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

% Consulta inversa educativa: requisitos documentados que impiden avanzar.
% No ejecuta correcciones ni supone que una condición bastaría clínicamente.
que_falta(S,tipo_confirmado(P),[conflicto_de_fuentes(P)]) :-
    hechos:solicitud(S,P,globulos,_,_),
    tipo_desconocido(P,conflicto_de_fuentes(P)).
que_falta(S,tipificacion_registrada(P),[sin_registro(P)]) :-
    hechos:solicitud(S,P,globulos,_,_),
    tipo_desconocido(P,sin_registro(P)).
que_falta(S,unidad_compatible(T),[sin_unidad_compatible(T)]) :-
    hechos:solicitud(S,P,globulos,1,_),
    tipo_paciente(P,T,_),
    candidatos(T,[]).
que_falta(C,repuesto_vigente(C),[reserva_inutil(U),sin_reemplazo(C)]) :-
    situacion(U,reserva_inutil(C),_),
    \+ repuesto_preferido(C,_).
que_falta(U,liberacion_registrada(U),[propuesta_liberar(U)]) :-
    situacion(U,reserva_liberable(_),_),
    \+ situacion(U,utilizable,_).

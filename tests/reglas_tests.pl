:- encoding(utf8).
:- begin_tests(situacion_1).

:- use_module('../reglas').
:- use_module('../hechos').

test(fotografia_de_30_unidades) :-
    findall(U, hechos:unidad(U,_,_,_), Us), length(Us, 30).

test(o_neg_sirve_a_todos_los_rojos) :-
    forall(member(T,[o_neg,o_pos,a_neg,a_pos,b_neg,b_pos,ab_neg,ab_pos]),
           compatible(o_neg,T)).

test(rh_positivo_no_sirve_a_negativo, [fail]) :- compatible(o_pos,a_neg).
test(ab_positivo_no_dona_a_o_negativo, [fail]) :- compatible(ab_pos,o_neg).

test(tipo_exacto_agotado_elige_a_negativo, [nondet]) :-
    decide(s1, asignar(u1,a_neg), Exp),
    member(elegida(u1,a_neg), Exp),
    member(descartada(u3,protege(s2)), Exp),
    member(descartada(u2,orden_de_sustitucion), Exp).

test(fefo_solo_dentro_del_tipo, [nondet]) :-
    % O+ vence antes, pero A- tiene prioridad de sustitución según el modelo.
    decide(s1, asignar(u1,a_neg), _).

test(o_negativo_recibe_reacomodo, [nondet]) :-
    decide(s2, reacomodar(u4,cir1,u11), _).

test(alternativas_en_orden) :-
    findall(U, decide(s1, asignar(U,_), _), Us),
    Us = [u1,u2,u3,u6].

test(reservada_no_se_oferta, [fail]) :- situacion(u4,utilizable,_).
test(caducada_no_se_oferta, [fail]) :- situacion(u5,utilizable,_).

test(paciente_con_fuentes_en_conflicto, [nondet]) :-
    decide(s3, no_se_sabe(tipo_paciente), Exp),
    member(conflicto_de_fuentes(p3), Exp).

test(sin_datos_no_es_negativo, [nondet]) :-
    situacion(p6,tipo_paciente(no_se_sabe),_).

:- end_tests(situacion_1).

:- begin_tests(situacion_2).
:- use_module('../reglas').

test(reserva_vence_antes_de_cirugia, [nondet]) :-
    situacion(u4,reserva_inutil(cir1),E),
    member(caduca_antes_de_cirugia(109,120),E).

test(reserva_no_es_inventario_libre, [fail]) :-
    situacion(u4,utilizable,_).

test(cirugia_tiene_repuesto_vigente, [nondet]) :-
    situacion(cir1,reserva_reacomodable(u4,u11),_),
    \+ situacion(u11,reserva_inutil(cir1),_).

test(urgencia_prefiere_unidad_que_vence_antes, [nondet]) :-
    decide(s2,reacomodar(u4,cir1,u11),E),
    member(urgencia_entrega(s2,u4,109),E),
    member(cirugia_protegida(cir1,u11,125),E).

test(urgencia_conserva_alternativa_libre, [true(Decisiones ==
     [reacomodar(u4,cir1,u11),asignar(u3,o_neg),asignar(u6,o_neg)])]) :-
    findall(D,decide(s2,D,_),Decisiones).

test(otra_reserva_sin_repuesto, [nondet]) :-
    situacion(cir2,sin_cobertura,Exp),
    member(sin_reemplazo(cir2),Exp).

test(cirugia_terminada_sin_uso_se_puede_liberar, [nondet]) :-
    situacion(u9,reserva_liberable(cir3),E),
    member(margen_de_liberacion(2),E).

test(no_se_cuenta_libre_hasta_liberacion_expresa, [fail]) :-
    situacion(u9,utilizable,_).

test(b_positivo_no_aumenta_por_liberacion_propuesta, [true(N == 0)]) :-
    existencias(globulos,b_pos,N).

test(ninguna_otra_reserva_es_liberable, [true(Unidades == [u9])]) :-
    findall(U,situacion(U,reserva_liberable(_),_),Unidades).

:- end_tests(situacion_2).

:- begin_tests(situacion_3).
:- use_module('../reglas').

test(retirar_unidades_de_donacion_positiva, [true(Unidades == [u1,u13])]) :-
    findall(U,incidente(retirar,U,_),Unidades).

test(avisar_receptor_con_traza, [nondet]) :-
    incidente(avisar,p5,Explicacion),
    member(cadena(dona_1,d1,u22,plaquetas),Explicacion).

test(destino_no_registrado_no_es_no_transfundida, [nondet]) :-
    incidente(no_se_sabe,u12,Explicacion),
    member(receptor_sin_registro,Explicacion),
    \+ incidente(avisar,_,[cadena(_,_,u12,_)|_]).

test(cirugia_pierde_reserva, [nondet]) :-
    incidente(reserva_afectada,cir4,E),
    member(unidad_retirada(u13),E).

test(resultados_futuros_no_contaminan_foto_100, [nondet]) :-
    situacion(u1,utilizable,_),
    \+ situacion(u22,utilizable,_).

test(no_se_extiende_a_donaciones_no_positivas, [fail]) :-
    incidente(retirar,u2,_).

:- end_tests(situacion_3).

:- begin_tests(situacion_4).
:- use_module('../reglas').

test(expuestas_a_lectura_fuera_de_rango, [nondet]) :-
    falla(u1,comprometida,E), member(lectura_fuera_de_rango(e_rojos,94,9),E),
    falla(u3,comprometida,_).
test(llegada_durante_hueco_no_se_sabe, [nondet]) :-
    falla(u4,no_se_sabe,[sin_lectura(e_rojos,98,102)]).
test(movida_antes_y_plaquetas_salvadas, [nondet]) :-
    falla(u2,salvada,_), falla(u25,salvada,_),
    \+ falla(u2,comprometida,_).
test(no_se_declara_salvada_por_lectura_final, [fail]) :-
    falla(u1,salvada,_).
:- end_tests(situacion_4).

:- begin_tests(situacion_5).
:- use_module('../reglas').

test(escala_accidente_y_critico, [nondet]) :-
    accidente(nivel_critico(o_neg),[restantes(1),umbral(2),consumidas([u4,u6])]).
test(reparto_sin_duplicar_unidad, [true(Asignaciones == [s2-u3])]) :-
    findall(S-U,accidente(asignar(S,U),_),Asignaciones).
test(consumo_previo_a_reserva_y_sin_positivos, [nondet]) :-
    hechos:hora_accidente(94),
    hechos:evento_unidad(u4,reservada(cir1),95),
    hechos:prueba(d3,negativa,80),
    \+ (hechos:prueba(d3,positiva,Hora),Hora =< 94).
test(urgencia_no_tipificada_sin_cobertura, [nondet]) :-
    accidente(sin_cobertura(s4),_).
test(conflicto_no_es_tipo_confirmado, [nondet]) :-
    accidente(no_se_sabe(s3),_), \+ accidente(asignar(s3,_),_).
:- end_tests(situacion_5).

:- begin_tests(consulta_inversa).
:- use_module('../reglas').

test(conflicto_exige_evidencia, [true(Metas == [tipo_confirmado(p3)])]) :-
    findall(M,que_falta(s3,M,_),Metas).
test(sin_registro_no_supone_tipo, [true(Metas == [tipificacion_registrada(p6)])]) :-
    findall(M,que_falta(s4,M,_),Metas).
test(cirugia_sin_repuesto, [nondet]) :-
    que_falta(cir2,repuesto_vigente(cir2),E),
    member(sin_reemplazo(cir2),E).
test(liberacion_aun_no_registrada, [nondet]) :-
    que_falta(u9,liberacion_registrada(u9),_),
    \+ situacion(u9,utilizable,_).
test(solicitud_cubierta_no_inventa_obstaculos, [fail]) :-
    que_falta(s1,_,_).
test(cirugia_con_repuesto_no_se_marca_sin_cobertura, [fail]) :-
    que_falta(cir1,repuesto_vigente(cir1),_).

:- end_tests(consulta_inversa).

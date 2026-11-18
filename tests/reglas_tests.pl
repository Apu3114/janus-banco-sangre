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
    Us = [u1,u2,u3].

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
     [reacomodar(u4,cir1,u11),asignar(u3,o_neg)])]) :-
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

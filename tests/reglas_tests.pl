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

test(o_negativo_recibe_su_unidad, [nondet]) :-
    decide(s2, asignar(u3,o_neg), _).

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

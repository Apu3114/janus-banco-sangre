:- encoding(utf8).
:- module(hechos, [ahora/1, donacion/4, unidad/4, ubicacion/3, rango/3,
                   lectura/4, evento_unidad/3, prueba/3, tipo_registrado/3,
                   solicitud/5, cirugia/5, margen_liberacion/1,
                   receptor_unidad/3, hora_incidente/1]).

% DATOS TOTALMENTE FICTICIOS. Instantes en horas del modelo, no reloj real.
% Decisiones de simulación: 30 unidades, 3 equipos, 6 pacientes; caducidades
% relativas. Una donación puede dar varios componentes (u1, u13, u22).
ahora(100).
% Supuesto educativo: esperar 2 horas después de confirmación de no uso.
margen_liberacion(2).
% Situación 3: foto prospectiva en 102; no modifica las respuestas de hora 100.
hora_incidente(102).

donacion(d1, dona_1, a_neg, 70).   donacion(d2, dona_2, o_pos, 70).
donacion(d3, dona_3, o_neg, 70).   donacion(d4, dona_4, o_neg, 70).
donacion(d5, dona_5, a_pos, 70).   donacion(d6, dona_6, b_neg, 70).
donacion(d7, dona_7, ab_pos, 70). donacion(d8, dona_8, a_pos, 70).
donacion(d9, dona_9, b_pos, 70).  donacion(d10, dona_10, ab_neg, 70).
donacion(d11, dona_11, b_neg, 70). donacion(d12, dona_12, ab_pos, 70).

% Glóbulos: A+ exacto no disponible; A- u1, O+ u2 y O- u3 sí sirven a p1.
unidad(u1,d1,globulos,112).  unidad(u2,d2,globulos,103).
unidad(u3,d3,globulos,110).  unidad(u4,d4,globulos,109).
unidad(u5,d5,globulos,99).   unidad(u6,d6,globulos,115).
unidad(u7,d7,globulos,118).  unidad(u8,d8,globulos,116).
unidad(u9,d9,globulos,120).  unidad(u10,d10,globulos,124).
unidad(u11,d11,globulos,125). unidad(u12,d12,globulos,130).

unidad(u13,d1,plasma,220).   unidad(u14,d2,plasma,215).
unidad(u15,d3,plasma,214).   unidad(u16,d4,plasma,216).
unidad(u17,d5,plasma,211).   unidad(u18,d6,plasma,218).
unidad(u19,d7,plasma,217).   unidad(u20,d8,plasma,213).
unidad(u21,d9,plasma,219).

unidad(u22,d1,plaquetas,107). unidad(u23,d2,plaquetas,106).
unidad(u24,d3,plaquetas,105). unidad(u25,d4,plaquetas,104).
unidad(u26,d5,plaquetas,108). unidad(u27,d6,plaquetas,109).
unidad(u28,d7,plaquetas,108). unidad(u29,d8,plaquetas,107).
unidad(u30,d9,plaquetas,106).

% Primer escenario sin movimientos ni incidentes: un equipo por componente.
ubicacion(U,e_rojos,80) :- unidad(U,_,globulos,_).
ubicacion(U,e_plasma,80) :- unidad(U,_,plasma,_).
ubicacion(U,e_plaquetas,80) :- unidad(U,_,plaquetas,_).

% Rangos didácticos para desarrollar la situación 4; no se usan aún al decidir.
rango(temp_globulos,1,6). rango(temp_plasma,-30,-18).
rango(temp_plaquetas,20,24).
lectura(e_rojos,temp_globulos,4,90).
lectura(e_plasma,temp_plasma,-25,90).
lectura(e_plaquetas,temp_plaquetas,22,90).

% La liberación documentada importa: sin evidencia no se presume liberada.
evento_unidad(u1,liberada,85). evento_unidad(u2,liberada,85).
evento_unidad(u3,liberada,85). evento_unidad(u4,liberada,85).
evento_unidad(u5,liberada,85). evento_unidad(u6,liberada,85).
evento_unidad(u7,liberada,85). evento_unidad(u8,liberada,85).
evento_unidad(u9,liberada,85). evento_unidad(u10,liberada,85).
evento_unidad(u11,liberada,85). evento_unidad(u12,liberada,85).
evento_unidad(u13,liberada,85). evento_unidad(u14,liberada,85).
evento_unidad(u15,liberada,85). evento_unidad(u16,liberada,85).
evento_unidad(u17,liberada,85). evento_unidad(u18,liberada,85).
evento_unidad(u19,liberada,85). evento_unidad(u20,liberada,85).
evento_unidad(u21,liberada,85). evento_unidad(u22,liberada,85).
evento_unidad(u23,liberada,85). evento_unidad(u24,liberada,85).
evento_unidad(u25,liberada,85). evento_unidad(u26,liberada,85).
evento_unidad(u27,liberada,85). evento_unidad(u28,liberada,85).
evento_unidad(u29,liberada,85). evento_unidad(u30,liberada,85).
evento_unidad(u4,reservada(cir1),95).
evento_unidad(u8,reservada(cir2),96).
evento_unidad(u9,reservada(cir3),91).
evento_unidad(u9,cirugia_terminada_sin_uso(cir3),97).
% La donación d1 produjo u1/u13/u22. Se conocen tres destinos diferentes.
evento_unidad(u13,reservada(cir4),99).
evento_unidad(u22,transfundida,99).
% d12 también tendrá resultado positivo; su bolsa salió sin receptor registrado.
evento_unidad(u12,transfundida,99).
receptor_unidad(u22,p5,99).

prueba(d1,negativa,80). prueba(d2,negativa,80).
prueba(d3,negativa,80). prueba(d4,negativa,80).
prueba(d5,negativa,80). prueba(d6,negativa,80).
prueba(d7,negativa,80). prueba(d8,negativa,80).
prueba(d9,negativa,80). prueba(d10,negativa,80).
prueba(d11,negativa,80). prueba(d12,negativa,80).
prueba(d1,positiva,101). prueba(d12,positiva,101).

tipo_registrado(p1,expediente,a_pos).
tipo_registrado(p2,expediente,o_neg).
tipo_registrado(p3,expediente,ab_pos).
tipo_registrado(p3,pulsera,a_neg). % conflicto: nunca adivinar el tipo
tipo_registrado(p4,expediente,b_pos).
tipo_registrado(p5,expediente,a_neg).
% p6 no tiene fuente de tipo; ausencia no equivale a O negativo confirmado.

solicitud(s1,p1,globulos,1,programada).
solicitud(s2,p2,globulos,1,emergencia).
solicitud(s3,p3,globulos,1,emergencia).
cirugia(cir1,p4,120,globulos,1).
% La reserva u8 es A+ y pertenece a p1; vence antes de su cirugía.
cirugia(cir2,p1,122,globulos,1).
cirugia(cir3,p4,95,globulos,1).
% No se aplica compatibilidad de plasma en esta situación; solo trazabilidad.
cirugia(cir4,p1,120,plasma,1).

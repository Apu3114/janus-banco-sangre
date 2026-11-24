:- encoding(utf8).
:- module(grafo, [red/3, nodo/4]).

:- use_module(hechos).

% Únicamente relaciones documentadas en la fotografía base (hora 100).
% Ninguna propuesta de asignación o evento del futuro es una arista factual.
nodo(Id,donante,Etiqueta,"Donante ficticio") :-
    hechos:donacion(_,Id,_,_),
    format(string(Etiqueta),'Donante ~w',[Id]).
nodo(Id,donacion,Etiqueta,Detalle) :-
    hechos:donacion(Id,_,Tipo,Hora),
    format(string(Etiqueta),'Donación ~w',[Id]),
    format(string(Detalle),'Tipo ~w · registrada en hora ~w',[Tipo,Hora]).
nodo(Id,unidad,Etiqueta,Detalle) :-
    hechos:unidad(Id,_,Componente,Caduca),
    format(string(Etiqueta),'Unidad ~w',[Id]),
    format(string(Detalle),'~w · caduca en hora ~w',[Componente,Caduca]).
nodo(Id,equipo,Etiqueta,"Ubicación de la fotografía base") :-
    hechos:ubicacion(_,Id,_),
    format(string(Etiqueta),'Equipo ~w',[Id]).
nodo(Id,paciente,Etiqueta,Detalle) :-
    (hechos:solicitud(_,Id,_,_,_); hechos:cirugia(_,Id,_,_,_);
     hechos:receptor_unidad(_,Id,_)),
    format(string(Etiqueta),'Paciente ~w',[Id]),
    findall(Fuente-Tipo,hechos:tipo_registrado(Id,Fuente,Tipo),Fuentes),
    ( Fuentes == [] -> Detalle = "Sin tipo registrado en esta fotografía"
    ; term_string(Fuentes,Detalle) ).
nodo(Id,solicitud,Etiqueta,Detalle) :-
    hechos:solicitud(Id,_,Componente,Cantidad,Prioridad),
    format(string(Etiqueta),'Solicitud ~w',[Id]),
    format(string(Detalle),'~w · ~w unidad(es) de ~w',[Prioridad,Cantidad,Componente]).
nodo(Id,cirugia,Etiqueta,Detalle) :-
    hechos:cirugia(Id,_,Hora,Componente,_),
    format(string(Etiqueta),'Cirugía ~w',[Id]),
    format(string(Detalle),'Hora ~w · ~w',[Hora,Componente]).

% La evidencia se entrega como texto consultable, no como vínculo inventado.
arista(Donante,Donacion,"donó",Evidencia) :-
    hechos:donacion(Donacion,Donante,Tipo,Hora),
    format(string(Evidencia),'donacion(~w,~w,~w,~w)',[Donacion,Donante,Tipo,Hora]).
arista(Donacion,Unidad,"produjo",Evidencia) :-
    hechos:unidad(Unidad,Donacion,Componente,Caduca),
    format(string(Evidencia),'unidad(~w,~w,~w,~w)',[Unidad,Donacion,Componente,Caduca]).
arista(Unidad,Equipo,"ubicada en",Evidencia) :-
    hechos:ubicacion(Unidad,Equipo,Hora),
    format(string(Evidencia),'ubicacion(~w,~w,~w)',[Unidad,Equipo,Hora]).
arista(Paciente,Solicitud,"solicitó",Evidencia) :-
    hechos:solicitud(Solicitud,Paciente,Componente,Cantidad,Prioridad),
    format(string(Evidencia),'solicitud(~w,~w,~w,~w,~w)',
           [Solicitud,Paciente,Componente,Cantidad,Prioridad]).
arista(Paciente,Cirugia,"tiene cirugía",Evidencia) :-
    hechos:cirugia(Cirugia,Paciente,Hora,Componente,Cantidad),
    format(string(Evidencia),'cirugia(~w,~w,~w,~w,~w)',
           [Cirugia,Paciente,Hora,Componente,Cantidad]).
arista(Unidad,Cirugia,"reservada para",Evidencia) :-
    hechos:evento_unidad(Unidad,reservada(Cirugia),Hora),
    format(string(Evidencia),'evento_unidad(~w,reservada(~w),~w)',
           [Unidad,Cirugia,Hora]).
arista(Unidad,Paciente,"transfundida a",Evidencia) :-
    hechos:receptor_unidad(Unidad,Paciente,Hora),
    hechos:evento_unidad(Unidad,transfundida,_),
    format(string(Evidencia),'receptor_unidad(~w,~w,~w)',[Unidad,Paciente,Hora]).

vecino(Id,Otro) :- arista(Id,Otro,_,_).
vecino(Id,Otro) :- arista(Otro,Id,_,_).

% Dos saltos: d1 -> u22 -> p5 y u22 -> d1 -> dona_1, sin
% tomar la mera ausencia de un registro como una relación.
red(Centro,Nodos,Enlaces) :-
    nodo(Centro,_,_,_), !,
    findall(V,vecino(Centro,V),Directos0),sort(Directos0,Directos),
    % El equipo figura como nodo, pero no se usa como atajo para expandir
    % todas las bolsas del refrigerador al seguir una unidad concreta.
    findall(V,(member(N,Directos),\+ nodo(N,equipo,_,_),vecino(N,V)),Segundos0),
    append([[Centro],Directos,Segundos0],Visitados0),
    sort(Visitados0,Visitados),
    findall(_{id:Id,tipo:Tipo,etiqueta:Etiqueta,detalle:Detalle},
            (member(Id,Visitados),once(nodo(Id,Tipo,Etiqueta,Detalle))),Nodos),
    findall(_{origen:Origen,destino:Destino,relacion:Relacion,evidencia:Evidencia},
            (arista(Origen,Destino,Relacion,Evidencia),
             memberchk(Origen,Visitados),memberchk(Destino,Visitados)),Enlaces).

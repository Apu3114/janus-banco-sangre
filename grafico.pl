:- module(grafico, [graficar/1]).

:- use_module(reglas).

% Janus es OPCIONAL: las decisiones siguen funcionando sin Python.
% Solo envía a Python las existencias deducidas en Prolog; no delega reglas.
graficar(Ruta) :-
    findall([Tipo,N], (reglas:existencias(globulos,T,N),atom_string(T,Tipo)), Filas),
    use_module(library(janus)),
    source_file(grafico:graficar(_), Archivo),
    file_directory_name(Archivo, Carpeta),
    py_add_lib_dir(Carpeta),
    % En Windows, Janus 10.0.2 busca site-packages con formato Linux.
    ( getenv('VIRTUAL_ENV', Venv), current_prolog_flag(windows,true),
      directory_file_path(Venv, 'Lib/site-packages', Paquetes),
      exists_directory(Paquetes) -> py_add_lib_dir(Paquetes) ; true ),
    py_call(grafica_python:guardar(Filas,Ruta), _).

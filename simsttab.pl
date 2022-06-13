:- use_module(library(clpz)).
:- use_module(library(dcgs)).
:- use_module(library(reif)).
:- use_module(library(pairs)).
:- use_module(library(lists)).
:- use_module(library(format)).
:- use_module(library(pio)).

:- dynamic(class_subject_teacher_times/4).
:- dynamic(coupling/4).
:- dynamic(teacher_freeday/2).
:- dynamic(slots_per_day/1).
:- dynamic(slots_per_week/1).
:- dynamic(class_freeslot/2).
:- dynamic(room_alloc/4).

:- discontiguous(class_subject_teacher_times/4).
:- discontiguous(class_freeslot/2).

requirements(Rs) :-
        Goal = class_subject_teacher_times(Class,Subject,Teacher,Number),
        setof(req(Class,Subject,Teacher,Number), Goal, Rs0),
        maplist(req_with_slots, Rs0, Rs).

req_with_slots(R, R-Slots) :- R = req(_,_,_,N), length(Slots, N).

classes(Classes) :-
        setof(C, S^N^T^class_subject_teacher_times(C,S,T,N), Classes).

teachers(Teachers) :-
        setof(T, C^S^N^class_subject_teacher_times(C,S,T,N), Teachers).

rooms(Rooms) :-
        findall(Room, room_alloc(Room,_C,_S,_Slot), Rooms0),
        sort(Rooms0, Rooms).

consultas(Rs, Vars) :-
        requirements(Rs),
        pairs_slots(Rs, Vars),
        slots_per_week(SPW),
        Max #= SPW - 1,
        Vars ins 0..Max,
        maplist(constrain_subject, Rs),
        classes(Classes),
        teachers(Teachers),
        rooms(Rooms),
        maplist(constrain_teacher(Rs), Teachers),
        maplist(constrain_class(Rs), Classes),
        maplist(constrain_room(Rs), Rooms).

slot_quotient(S, Q) :-
        slots_per_day(SPD),
        Q #= S // SPD.


list_without_nths(Es0, Ws, Es) :-
        phrase(without_(Ws, 0, Es0), Es).

without_([], _, Es) --> seq(Es).
without_([W|Ws], Pos0, [E|Es]) -->
        { Pos #= Pos0 + 1,
          zcompare(R, W, Pos0) },
        without_at_pos0(R, E, [W|Ws], Ws1),
        without_(Ws1, Pos, Es).

without_at_pos0(=, _, [_|Ws], Ws) --> [].
without_at_pos0(>, E, Ws0, Ws0) --> [E].

%:- list_without_nths([a,b,c,d], [3], [a,b,c]).
%:- list_without_nths([a,b,c,d], [1,2], [a,d]).

slots_couplings(Slots, F-S) :-
        nth0(F, Slots, S1),
        nth0(S, Slots, S2),
        S2 #= S1 + 1.

constrain_subject(req(Class,Subj,_Teacher,_Num)-Slots) :-
        strictly_ascending(Slots), % break symmetry
        maplist(slot_quotient, Slots, Qs0),
        findall(F-S, coupling(Class,Subj,F,S), Cs),
        maplist(slots_couplings(Slots), Cs),
        pairs_values(Cs, Seconds0),
        sort(Seconds0, Seconds),
        list_without_nths(Qs0, Seconds, Qs),
        strictly_ascending(Qs).


all_diff_from(Vs, F) :- maplist(#\=(F), Vs).

constrain_class(Rs, Class) :-
        tfilter(class_req(Class), Rs, Sub),
        pairs_slots(Sub, Vs),
        all_different(Vs),
        findall(S, class_freeslot(Class,S), Frees),
        maplist(all_diff_from(Vs), Frees).


constrain_teacher(Rs, Teacher) :-
        tfilter(teacher_req(Teacher), Rs, Sub),
        pairs_slots(Sub, Vs),
        all_different(Vs),
        findall(F, teacher_freeday(Teacher, F), Fs),
        maplist(slot_quotient, Vs, Qs),
        maplist(all_diff_from(Qs), Fs).

sameroom_var(Reqs, r(Class,Subject,Lesson), Var) :-
        memberchk(req(Class,Subject,_Teacher,_Num)-Slots, Reqs),
        nth0(Lesson, Slots, Var).

constrain_room(Reqs, Room) :-
        findall(r(Class,Subj,Less), room_alloc(Room,Class,Subj,Less), RReqs),
        maplist(sameroom_var(Reqs), RReqs, Roomvars),
        all_different(Roomvars).


strictly_ascending(Ls) :- chain(#<, Ls).

class_req(C0, req(C1,_S,_T,_N)-_, T) :- =(C0, C1, T).

teacher_req(T0, req(_C,_S,T1,_N)-_, T) :- =(T0,T1,T).

pairs_slots(Ps, Vs) :-
        pairs_values(Ps, Vs0),
        append(Vs0, Vs).

days_variables(Days, Vs) :-
        slots_per_week(SPW),
        slots_per_day(SPD),
        NumDays #= SPW // SPD,
        length(Days, NumDays),
        length(Day, SPD),
        maplist(same_length(Day), Days),
        append(Days, Vs).

class_days(Rs, Class, Days) :-
        days_variables(Days, Vs),
        tfilter(class_req(Class), Rs, Sub),
        foldl(v(Sub), Vs, 0, _).

v(Rs, V, N0, N) :-
        (   member(req(_,Subject,_,_)-Times, Rs),
            member(N0, Times) -> V = subject(Subject)
        ;   V = free
        ),
        N #= N0 + 1.

teacher_days(Rs, Teacher, Days) :-
        days_variables(Days, Vs),
        tfilter(teacher_req(Teacher), Rs, Sub),
        foldl(v_teacher(Sub), Vs, 0, _).

v_teacher(Rs, V, N0, N) :-
        (   member(req(C,Subj,_,_)-Times, Rs),
            member(N0, Times) -> V = class_subject(C, Subj)
        ;   V = free
        ),
        N #= N0 + 1.

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        IMRPIMIR HORARIOS
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

horarios(Rs) :-
        classes(Cs),
        phrase_to_stream(format_classes(Cs, Rs), user_output).

format_classes([], _) --> [].
format_classes([Class|Classes], Rs) -->
        { class_days(Rs, Class, Days0),
          transpose(Days0, Days) },
        format_("Semestre: ~w~2n", [Class]),
        weekdays_header,
        align_rows(Days),
        format_classes(Classes, Rs).

align_rows([]) --> "\n\n\n".
align_rows([R|Rs]) -->
        align_row(R),
        "\n",
        align_rows(Rs).

align_row([]) --> [].
align_row([R|Rs]) -->
        align_(R),
        align_row(Rs).

align_(free)               --> align_(verbatim('   ')).
align_(class_subject(C,S)) --> align_(verbatim(C/S)).
align_(subject(S))         --> align_(verbatim(S)).
align_(verbatim(Element))  --> format_("~t~w~t~8+", [Element]).

print_teachers(Rs) :-
        teachers(Ts),
        phrase_to_stream(format_teachers(Ts, Rs), user_output).

format_teachers([], _) --> [].
format_teachers([T|Ts], Rs) -->
        { teacher_days(Rs, T, Days0),
          transpose(Days0, Days) },
        format_("Docente: ~w~2n", [T]),
        weekdays_header,
        align_rows(Days),
        format_teachers(Ts, Rs).

weekdays_header -->
        { maplist(with_verbatim,
                  ['Lun','Mar','Mie','Jue','Vie'],
                  Vs) },
        align_row(Vs),
        format_("~n~`=t~40|~n", []).

with_verbatim(T, verbatim(T)).

/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
   ?- consult('reqs_example.pl'),
      consultas(Rs, Vs), labeling([ff], Vs), horarios(Rs).

        CORDOBA JAMES
        MIRANDA DARIEN
        MOLINA FRANKLIN
        PAZ CARLOS
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
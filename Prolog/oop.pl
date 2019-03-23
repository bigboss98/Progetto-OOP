%%%% -*- Mode:Prolog -*-

/*
 * Authors: Natali Marco 829843
 *          Occhiuto Giovanni 830195
 */

/*
 * Predicato solve/1 risolve i Goals passati come argomento
 * utilizzando per la risoluzione il predicato solve/2
 */
solve(Goal):- solve(Goal, []).

/*
 * Predicato solve/2 risolve i goals presenti nelle due liste
 * passate come argomento in cui queste liste di goals possono anche essere vuote.
 */
solve([], []):- !.
solve([], [G | Goals]):-
        solve(G, Goals).

solve([A | B], Goals):-
        append(B, Goals, BGoals), !,
        solve(A, BGoals).

solve(A, Goals):-
        call(A), !,
        solve(Goals, []).

solve(A, Goals):-
         clause(A, B), !,
         solve(B, Goals).

/*
 * Predicato def_class(Name, Parent, SlotValues) definisce la struttura di una 
 * classe e la memorizza nella "base di conoscenza" di Prolog con assert.
 * -Name deve essere un atomo 
 * -Parent è una lista indicante le classi genitori della classe da definire.
 * -SlotValues sono una lista di definizioni dei metodi/proprietà della classe
 */
def_class(Name, Parent, SlotValues):-
        atom(Name),
        are_valid_parents(Parent),
        associate_slots_values(SlotValues, Name), !,
        assertz(superclass(Name, Parent)),
        assertz(class(Name)).

/*
 * Il predicato are_valid_parents/1 stabilisce se la lista passata come argomento 
 * contiene soltanto delle classi valide, definite nella base di conoscenza di Prolog.
 */
are_valid_parents([]):- !.

are_valid_parents([X | Xs]):-
        class(X),
        are_valid_parents(Xs).

/*
 * Il predicato associate_slots_values/2(Slots, Class) associa ogni elemento di Slots
 * alla classe Class nella base di conoscenza Prolog.
 */
associate_slots_values([], NameClass):- !. 

associate_slots_values([Slot | Slots], NameClass):-%Caso passo
        obtain_slot_value(Slot, Name, Value),
        find_already_slot(NameClass, Name), 
        assertz(slot_value_in_class(NameClass, Name, Value)), 
        associate_slots_values(Slots, NameClass).   

/*
 * Il predicato find_already_slot/2(Class, NameSlot) permette di 
 * rimuovere la vecchia definizione dello slot nella base di conoscenza.
 * In caso non sia stato definito ritorna comunque true senza fare nulla.
 */
find_already_slot(Class, NameSlot):-%Caso trovata vecchia definizione
        retract(slot_value_in_class(Class, NameSlot, X)).

find_already_slot(Class, NameSlot):- !.%Caso non esiste una definizione

/*
 * Il predicato obtain_slot_value/4(Slot, Class, Name, Value) permette di stabilire
 * se la stringa di Slot risulta valida e di ottenere i valori Name e Value,
 * al fine di inserirli nella base di conoscenza della classe o dell'istanza.
 */
obtain_slot_value(Slot, Name, Instructions):- %caso Metodo
        is_method(Slot), !,
        find_elements(Slot, Name, Args, Instructions),
        create_method(Name, Args, Instructions).

obtain_slot_value(Slot, Name, Value):- %Caso value
        Slot =.. X, !,
        nth0(1, X, Name),
        nth0(2, X, Value).


/*
 * Il predicato replace_this/3(Instance, Terms, NewTerms) effettua la sostituzione
 * del atomo this con Instance dentro la lista di termini Terms.
 */
replace_this(_, [], []):- !. 

replace_this(Instance, [Term | Terms], [NewTerm | NewTerms]):-
        Term =.. TermList,
        replace("this", Instance, TermList, NewTermList),
        NewTerm =.. NewTermList,
        replace_this(Instance, Terms, NewTerms).


/*
 * Il predicato is_method/1(Value) stabilisce se Value rappresenta un metodo, 
 * ossia se la stringa rappresentante Value presenta la sottostringa "method(".
 */
is_method(Value):-
        term_string(Value, String),
        sub_string(String, X, Y, Z, "method(").

/*
 * Il predicato create_method/3(Name, Arg, Instructions) definisce un metodo
 * nella base di conoscenza, al fine poi di poter eseguire il metodo su un 
 * istanza della classe.
 */
create_method(Name, Arg, Instructions):-
        append([Instance], Arg, Args),
        append([Name], Args, AllArgs),
        Head =.. AllArgs,
        find_all_variables(Instructions, VarBefore),
        assertz((Head :- getv(Instance, Name, Y),
                        replace_this(Instance, Y, A),
                        find_all_variables(A, VarAfter),
                        replace_args_instructions(A, Instr,VarBefore, VarAfter),
                        solve(Instr))).

/*
 * Predicato new/3(InstanceName,ClassName, SlotValues) crea una nuova istanza
 * della classe ClassName, associando poi gli SlotValues, rappresentanti una nuova
 * definizione di una parte o tutti gli slot definiti nella classe ClassName.
 */
new(InstanceName, ClassName, SlotValues):-
        atom(InstanceName),
        class(ClassName),
        associate_instance_values(SlotValues, InstanceName, ClassName),
        assertz(instance_of(InstanceName, ClassName)).

/*
 * Il predicato new/2(InstanceName, ClassName) crea una nuova istanza della 
 * classe ClassName, ereditando tutti i valori di default dalla classe.
 * La chiamata new(Instance, Class, []) è equivalente a new(Instance, Class).
 */
new(InstanceName, ClassName):- new(InstanceName, ClassName, []).

/*
 * Il predicato associate_instance_values/2(Slots, Name) associa gli slot alla
 * nuova istanza di una classe tramite sempre la base di conoscenza.
 */
associate_instance_values([], InstanceName, ClassName):- !.

associate_instance_values([Slot | Slots], InstanceName, ClassName):-
        obtain_slot_value(Slot, Name, Value),
        exists_attribute(Name, ClassName),
        \+ getv(InstanceName, Name, X), !,
        assert(slot_value_in_istance(InstanceName, Name, Value)),
        associate_instance_values(Slots, InstanceName, ClassName).

associate_instance_values([Slot | Slots], InstanceName, ClassName):-
        obtain_slot_value(Slot, Name, Value),
        getv(InstanceName, Name, X), !,
        associate_instance_values(Slots, InstanceName, ClassName).

/*
 * Il predicato exists_attribute/2(Name, ClassName) stabilisce se l'attributo di
 * istanza Name è definito nella base di conoscenza della classe, ossia se è
 * un attributo definito dalla classe e quindi anche definibile nell'istanza.
 * Ovviamente se l'attributo non è definito per la classe il predicato fallisce.
 */  
exists_attribute(Name, ClassName):-%Caso attributo definito nella classe stessa
        slot_value_in_class(ClassName, Name, Y).

exists_attribute(Name, ClassName):-%Caso attributo definito da una superclasse
        superclass(ClassName, SuperClass),
        obtain_value(SuperClass, Name, X).

/*
 * Il predicato getv/3(Instance, NameSlot, Res) permette di ricavare il valore
 * di uno slot, collegato ad un istanza.
 * Per ricavare i valori usa la base di conoscenza, analizzando prima l'istanza
 * poi le sua classe ed infine fa un analisi nelle sue superclassi.
 */
getv(Instance, SlotValue, Result):-%Caso valore in istanza
        slot_value_in_istance(Instance, SlotValue, Result), !.

getv(Instance, SlotValue, Result):- %Caso valore nella classe
        instance_of(Instance, Class),
        slot_value_in_class(Class, SlotValue, Result), !.

getv(Instance, SlotValue, Result):-%Caso valore nelle superclassi
        instance_of(Instance, Class),
        superclass(Class, SuperClasses),
        obtain_value(SuperClasses, SlotValue, Result).

/*
 * Il predicato getxv/3(Istance, Slots, Res) permette di ri
 */
getvx(Instance, [Value], Result):-
        getv(Instance, Value, Result), !.

getvx(Instance, [Value | Values], Result):-  
        getv(Instance, Value, X),
        getvx(X, Values, Result).

/*
 * Il predicato obtain_value(SuperClasses, NameSlot, Value) ricerca il valore di 
 * uno slot di una classe/istanza all'interno nella base di conoscenza delle
 * sue superclassi.
 * Questo predicato viene richiamato da getv per ricavare il valore di uno slot
 * da una  superclasse.
 */
obtain_value([], SlotValue, []):- false.%Valore non trovato nelle superclassi

obtain_value([Class | Classes], SlotValue, Result):-%Caso valore trovato in un elemento 
        slot_value_in_class(Class, SlotValue, Result), !.

obtain_value([Class | Classes], SlotValue, Result):-%Ricerca valore nelle altre sottoclassi
        superclass(Class, SuperClasses),
        nth0(0, SuperClasses, SuperClass, Rest),
        obtain_value(SuperClasses, SlotValue, Result).

obtain_value([Class | Classes], SlotValue, Result):-
        \+ obtain_value(Class, SlotValue, Result),
        obtain_value(Classes, SlotValue, Result).
/*
 * Il predicato find_elements/4(Slot, Name, Args, Instructions) ricava da uno slot
 * il nome, gli argomenti e il corpo di un metodo.
 * Utilizza i predicati find_args e find_instructions per riuscire a ricavarli.
 */
find_elements(Slot, Name, Args, Instructions):-
        (Slot) =.. X,
        nth0(1, X, Name),
        nth0(2, X, Term),
        find_args(Term, Args, Format),
        find_instructions(Format, Instructions).

/*
 * Il predicato find_args/3(Term, Args, NewTerm) ricava gli argomenti del predicato
 * e ritorna il nuovo termine, indicante solo le istruzioni del metodo.
 */
find_args(Term, Args, NewTerm):-
        Term =.. [Method, Args, NewTerm].

/*
 * Il predicato find_instructions/2(Term, Elements) crea la lista di istruzioni
 * di un metodo di uno slot, partendo da un termine contenente tutte le istruzioni.
 */
find_instructions([], []):- !.%Caso fine termine

find_instructions(Term, [Elem | Elems]):-
        find_instruction(Term, Elem, NewTerm), !,
        find_instructions(NewTerm, Elems).

/*
 * Il predicato find_instruction/3(Term, Instruction, NewTerm) ricava un istruzione
 * del metodo da un termine col nome Instruction e ritorna invece con NewTerm
 * il nuovo termine indicante le successive istruzioni.
 */
find_instruction(Term, Term, []):-%Caso ultima istruzione(NewTerm vuoto)
        Term =.. X,
        nth0(0, X, Elem),
        Elem \= ',', !.

find_instruction(Term, Elem, NewTerm):-%Caso istruzione con NewTerm non vuoto
        Term =.. X,
        nth0(1, X, Elem, WithComma),
        nth0(1, WithComma, NewTerm).

/*
 * Il predicato find_all_variables/2(Terms, Variables) trova tutte le variabili
 * presente nella lista di termini Terms.
 */
find_all_variables(Terms, Variables):- 
        find_all_variables(Terms, Variables, []), !.

/*
 * Il predicato find_all_variables/3(Terms, Variables, PartialListVariables)
 * trova tutte le variabili presenti in Terms, usando una lista di accumulazione
 * quindi find_all_variables(Terms, Variables) = find_all_variables(Terms, Var, []).
 */
find_all_variables([], Var, Var):- !.%Caso base senza più termini

find_all_variables([Term | Terms], X, ListVar):-
        term_variables(Term, Var),
        append(Var, ListVar, NewListVar),
        find_all_variables(Terms, X, NewListVar).

/*
 * Il predicato replace/4(Old, New, List, NewList) sostituisce tutti gli 
 * elementi di List con valore Old con il nuovo valore New e ritorna 
 * la lista modificata NewList.
 */
replace(_, _, [], []):- !.%Caso lista vuota

replace(Old, New, [X | Xs], [X | Ys]):-%Caso elemento sia una variabile
        var(X), !,
        replace(Old, New, Xs, Ys).

replace(Old, New, [X | Xs], [New | Ys]):-%Caso elemento = Old
        term_string(TermOld, Old),
        X = TermOld, !,
        replace(Old, New, Xs, Ys).

replace(Old, New, [X | Xs], [X | Ys]):-%Caso elemento \= Old
        term_string(TermOld, Old),
        X \= TermOld, !,
        replace(Old, New, Xs, Ys).

/*
 * Il predicato replace_args_instructions/4(Terms, NewTerms, VarList, NewVarList)
 * sostituisce tutte le occorenze di VarList con NewVarList in Terms al fine
 * di tenere traccia degli argomenti passati alle funzioni.
 */ 
replace_args_instructions([], [], _, _):- !.%Caso base nessun termine

replace_args_instructions([Term | Terms], [NewTerm | NewTerms], 
                          [Var | Vars], [NewVar | NewVars]):-
        replace_single_instruction(Term, NewTerm, [Var | Vars], [NewVar | NewVars]),
        replace_args_instructions(Terms, NewTerms, [Var | Vars], [NewVar | NewVars]).

/*
 * Il predicato replace_single_instructions/4(Term, NewTerm, VarList, NewVars)
 * sostituisce tutte le occorenze di VarList con NewVars all'interno di un termine
 */
replace_single_instruction(Term, Term, [], []):- !.

replace_single_instruction(Term, NewTerm, [Var | Vars], [NewVar | NewVars]):-
        replace_variables(Term, PossibleTerm, Var, NewVar),
        replace_single_instruction(PossibleTerm, NewTerm, Vars, NewVars).

/*
 * Il predicato replace_variables(Term, Old, New, NewTerm) sostituisce
 * tutte le occorrenze di Old con New all'interno di Term.
 */
replace_variables(Old, Old, New, New) :-%Caso termine = Old
        !.

replace_variables(Term, Old, New, Result) :-%Caso termine \= Old
        Term =.. [Fun | Args],
        replace_args(Args, Old, New, NewArgs),
        Result =.. [Fun | NewArgs].

/*
 * Il predicato replace_args/4(Args, Old, New, NewArgs) sostituisce nella lista
 * di argomenti Args Old con New e viene usato per definire il predicato
 * replace_variables/4.
 */
replace_args([],_,_,[]).

replace_args([Arg | Args], Old, New, [NewArg | NewArgs]) :-
     replace_variables(Arg, Old, New, NewArg),
     replace_args(Args, Old, New, NewArgs).

%Permette la definizione dinamica di questi predicati
:-dynamic class/1, instance_of/2, slot_value_in_class/3, slot_value_in_istance/3.

%Predicati predefiniti per evitare problemi durante la prima definizione 
class(X):- fail.
instance_of(X, Y):- fail.
slot_value_in_istance(X, Y, Z):- fail.
slot_value_in_class(X, Y, Z):- fail.

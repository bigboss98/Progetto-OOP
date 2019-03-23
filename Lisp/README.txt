%%%% -*- Mode: Text -*-

AUTORI: Natali Marco 829843
	Occhiuto Giovanni 830195
					
INTRODUZIONE

OOA è un linguaggio object-oriented con ereditarietÃ  multipla. 
Il suo scopo è didattico e mira soprattutto ad evidenziare
aspetti dell'implementazione di linguaggi object-oriented: 
(1) il problema di dove e come recuperare i valori ereditati
(2) come rappresentare i metodi e le loro chiamate
(3) come manipolare il codice nei metodi stessi.

FUNZIONI IMPLEMENTATE:

FUNZIONE parents-depth-first (root-class)

Percorre il grafo delle superclassi relative a root-class e 
torna una lista in ordine "depth-first" delle superclassi
da percorrere

FUNZIONE equal-parents (parents class-name)

Verifica che la class-name non sia uguale a nessuna classe
ereditata della lista parents. 
Torno T -> ho problemi di definizione
Torno NIL -> nessun problema

FUNZIONE check-parents (parents)

Verifico che la lista di parents sia una lista costituita
da tutte classi già definite.
Torno T -> nessun problema
Torno NIL -> ho problemi di definizione

FUNZIONE check-slots (slot-value class-name)

Verifico che la lista di slot sia di lunghezza pari (non può essere
altrimenti essendo una lista di coppie), che ciascun slot-name sia 
un simbolo e che ciascun slot-name sia ereditato o appartenga alla 
definizione della classe corrente

FUNZIONE is-a-method (slot-value)

Verifico che lo slot preso in considerazione sia un metodo. 
Lo slot-value deve essere una lista e deve iniziare con "=>"
Torno T -> è un metodo
Torno NIL -> non è un metodo

FUNZIONE method-in-slots (slot-value)

Verifico la presenza di metodi in slot-value e in tal caso li processo
chiamando method-process

FUNZIONE check-args (arguments)

Verifico che nella lista degli argomenti non vi siano argomenti ripetuti
Torno T > nessun problema
Altrimenti genero un errore

FUNZIONE find-v (slots slot-name)

Cerco slot-name nella lista di slots e se lo trovo lo torno

FUNZIONE find-v-parents (parents slot-name)

Cerco slot-name su una lista di parents in modalità  depth-first, torno il
valore trovato (se presente) oppure NIL

FUNZIONE getv (instance slot-name)

Data una instance e uno slot-name estraggo lo slot-name associato.
Eseguo prima una ricerca sugli slot della instance stessa e, se non trovo
nulla, eseguo una ricerca depth-first sui parents della classe dell'istanza

FUNZIONE getvx (instance &rest slot-name-list)

Data una instance e una lista slot-name-list, estraggo il valore associato
alla lista di ricerca percorrendo la catena di attributi.

FUNZIONE def-class (class-name parents &rest slot-value)

Definisco una classe verificando:
<class-name> deve essere un simbolo
<parents> deve essere una lista
Nessun parents può essere uguale a class-name
Qualora parents fosse null definisco una classe che eridata NIL
altrimenti verifico che i parents siano realmente definiti e 
definisco una classe che eredita dalla lista parents

FUNZIONE method-process (method-name method-spec)

Verifico che l'attrivuto method-name sia associato all'instance su cui è chiamato il metodo e
associo al method-name una funzione lamba che esegue come corpo la ridefinizione 
del metodo processata da rewrite-method-code e come argomenti l'instance 
su cui è chiamata e la lista di argomenti passati

FUNZIONE rewrite-method-code (method-name method-spec)

Verifico che method-name sia un simbolo, verifico la correttezza degli
argomenti e aggiungo 'this alla definizione del metodo in modo tale che 
agli argomenti del metodo venga aggiunto il this

FUNZIONE new (class-name &rest slot-value)

Creo un nuovo oggetto, verifico che class-name sia un simbolo e
che class-name sia una classe definita
Verifico la validità  di slot-value e torno una lista così formata:
('oolinst class-name slot-value)

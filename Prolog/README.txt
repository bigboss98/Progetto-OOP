%%% -*- Mode: Text -*-
AUTORI: Natali Marco 829843
        Occhiuto Giovanni 830195

%% INTRODUZIONE
Questa libreria implementa al fine scolastico un estensione OOP 
del linguaggio Prolog senza analizzarne incampsulazione e la visibilità
anche se nonostante ciò, sempre in considerazione del linguaggio Prolog,
si hanno già notevoli problemi semantici con notevoli casi patologici 
difficili da trattare, come il trattamento delle istanze di una vecchia
definizione di una classe.
È stato deciso, in caso di presenza di più classi e/o istanze con lo stesso nome
di ridefinire la classe e/o l'istanza rimuovendo le definizioni precedenti e di 
sostituire il parametro this con la variabile di istanza all'interno 
di un metodo trampolino.
In presenza di definizione di istanze con dei parametri di istanza non definiti 
nella classe è stato deciso di far fallire il predicato e non far instanziare l'istanza.

La libreria è costituita da due parti principali:

- definizione di classi e istanze, salvate nella base di conoscenza Prolog.

- ottenimento dei valori di stato, sia che essi siano valori, metodi e oggetti

-esecuzione dei metodi definiti da una classe
	
La descrizione esaustiva dei predicati definiti in questa libreria è possibile
trovarla nel listato Prolog oop.pl 


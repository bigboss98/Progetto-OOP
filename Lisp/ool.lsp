;;;; -*- Mode:Lisp -*-


;Authors: Natali Marco 829843
;         Occhiuto Giovanni 830195
;



;Definizione dell'hash-table globale, utilizzata per salvare
;la lista rappresentante ciascuna classe

(defparameter *classes-specs* (make-hash-table))


;Aggiungo la lista rappresentante la descrizione
;di una classe all'hash-table, torno il nome della classe definita

(defun add-class-spec (name class-spec)
    (setf (gethash name *classes-specs*) class-spec) name)

	
;Ottengo la descrizione di una classe dato il nome
;della classe stessa 

(defun get-class-spec (name)
    (gethash name *classes-specs*))

	
;Data una classe radice, ottengo l'attraversamento depth-first
;del grafo delle superclassi relative alla classe radice

(defun parents-depth-first (root-class)
	(cond ((null (car (get-class-spec root-class)))
				(list root-class))
             (T (cons root-class (mapcan #'parents-depth-first 
			 (car (get-class-spec root-class)))))))

			 
;Verifico che la class-name non sia uguale a nessun parents

(defun equal-parents (parents class-name)
	(cond ((null parents) NIL)
	    ((equalp class-name (car parents))	T)
		(T (equal-parents (cdr parents) class-name))))

		
;Verifico che i parents siano effettivamente classi già definite

(defun check-parents (parents)
	(cond ((null parents) T)
		((null (get-class-spec (car parents)))	NIL)
		(T (check-parents (cdr parents)))))

		
;Verifico che la lista degli slot sia di lunghezza pari
;(<slot-name> <value>), che ciascun slot-name sia un simbolo
;e che ciascun slot-name sia ereditato o appartenga 
;alla definizione della classe corrente

(defun check-slots (slot-value class-name)
	(cond ((not (evenp (length slot-value))) NIL)
		((null slot-value) T)
		((and (symbolp (car slot-value)) 
			(not (null (find-v-parents (parents-depth-first class-name) 
				(car slot-value)))))
			(check-slots (cdr (cdr slot-value)) class-name ))
		(T NIL)))

		
;Verifico che lo slot-value corrente sia un metodo

(defun is-a-method (slot-value)
	(if (and (listp (car (cdr slot-value)))
	       (equalp (car (car (cdr slot-value))) '=>))
		  T NIL))

		  
;Verifico la presenza di metodi in slot-value
;in tal caso richiamo la method-process sul metodo

(defun method-in-slots (slot-value)
	(cond ((null slot-value) NIL)
				((is-a-method slot-value)
					(append (list (car slot-value))
					(list (method-process (car slot-value) 
								(car (cdr slot-value))))
					(method-in-slots (cdr (cdr slot-value)))))
		(T (append (list (car slot-value) (car (cdr slot-value)))
			(method-in-slots (cdr (cdr slot-value)))))))
		  
		  
;Verifico che gli argomenti non siano ripetuti

(defun check-args (arguments)
  (cond ((null arguments) T)
        ((member (car arguments) (cdr arguments))
          (error "repeated arguments."))
        (T (check-args (cdr (cdr arguments))))))

		
;Cerca slot-name su slots

(defun find-v (slots slot-name)
	(cond ((null slots) NIL)
		((equalp (car slots) slot-name)
			(append (list slot-name) (list (car (cdr slots)))))
		(T (find-v (cdr (cdr slots)) slot-name))))

		
;Cerco slot-name su parents in modalità depth-first

(defun find-v-parents (parents slot-name)
	(cond ((null parents) NIL)
		   ((not (null (find-v 
				(cdr (get-class-spec (car parents))) slot-name)))
					(find-v (cdr (get-class-spec (car parents))) slot-name))
		   (T (find-v-parents (cdr parents) slot-name))))

		   
;Data una instance e uno slot-name, estraggo lo slot-name associato,
;eseguo prima una ricerca sulla instance stessa e 
;se non trovo nulla provo una ricerca depth-first sui parents

(defun getv (instance slot-name)
	(cond ((not (equalp 'oolinst (car instance)))
				(error "instance is not correctly defined."))
			((not (symbolp slot-name))
				(error "slot-name is not a symbol."))
            ((not (null (find-v (cdr (cdr instance)) slot-name)))
                  (car (cdr (find-v (cdr (cdr instance)) slot-name))))
            ((if (not (null (find-v-parents
					(parents-depth-first (car (cdr instance))) 
									slot-name)))	
                       (car (cdr (find-v-parents
					(parents-depth-first (car (cdr instance))) 
									slot-name)))
               (error "no method or slot named ~S found." slot-name )))))
									
									
;Data una instance e una lista slot-name, 
;estraggo il valore della classe percorrendo una catena di attributi

(defun getvx (instance &rest slot-name-list)
	(cond ((not (listp slot-name-list))
				(error "slot-name-list is not a list."))
		((null (getv instance (car slot-name-list)))
				(error "slot not found."))
		((null (cdr slot-name-list))
				(getv instance (car slot-name-list)))
		(T (apply #'getvx (getv instance (car slot-name-list)) 
					(cdr slot-name-list)))))

					
;Definisco una classe

(defun def-class (class-name parents &rest slot-value)
	(cond ((or (null class-name) (not (symbolp class-name)))
				(error "class-name is not valid."))
		((not (listp parents))
				(error "parents is not a list."))
		((equal-parents parents class-name)	
				(error "class-name can not be equals to parents list."))
		((null (check-parents parents))
				(error "parents are not valid."))
		((and (null parents) (check-args slot-value))
			(add-class-spec class-name (cons '() 
				      (method-in-slots slot-value))))
		((check-args slot-value) (add-class-spec class-name (cons parents 
					  (method-in-slots slot-value))))))

					  
;Associo al method-name una funzione lamba che esegue come corpo
;la ridefinizione del metodo processata da rewrite-method-code e
;come argomenti l'instance su cui è chiamata e la lista di argomenti passati

(defun method-process (method-name method-spec)
	(setf (fdefinition method-name)
		(lambda (this &rest arguments)
			(if (not (null (getv this method-name)))
				(apply (getv this method-name) this arguments))))
	(eval (rewrite-method-code method-name method-spec)))

  
;Verifico che method-name sia un simbolo, verifico la correttezza degli
;argomenti e aggiungo 'this alla definizione del metodo in modo tale che 
;agli argomenti del metodo venga aggiunto il this

(defun rewrite-method-code (method-name method-spec)
  (cond ((not (symbolp method-name))
          (error "method-name must be a symbol."))
       ((check-args (car (cdr method-spec)))
        (append (list 'lambda (cons 'this
				(car (cdr method-spec))))
	(cdr (cdr method-spec))))))
	  
	  
;Creo un nuovo oggetto, verifico che class-name sia un simbolo e
;che class-name sia una classe definita
;Verifico la validità  di slot-value e torno una lista così formata:
;('oolinst class-name slot-value)

(defun new (class-name &rest slot-value)
	(cond ((or (not (symbolp class-name))
				(null (get-class-spec class-name)))
					(error "class-name is not valid."))
			((check-slots slot-value class-name)
				(append (list 'oolinst class-name) 
					(method-in-slots slot-value)))
            (T (error "slot-value is not inherited or is not valid."))))

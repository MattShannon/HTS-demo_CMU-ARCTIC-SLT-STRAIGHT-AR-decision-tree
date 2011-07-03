
;; Copyright 2011 Matt Shannon
;; Copyright 2001-2008 Nagoya Institute of Technology, Department of Computer Science
;; Copyright 2001-2008 Tokyo Institute of Technology, Interdisciplinary Graduate School of Science and Engineering

;; This file is part of HTS-demo_CMU-ARCTIC-SLT-STRAIGHT-AR-decision-tree.
;; See `License` for details of license and warranty.


;;  Extra features
;;  From Segment items refer by 
;;
;;  R:SylStructure.parent.parent.R:Phrase.parent.lisp_num_syls_in_phrase
;;  R:SylStructure.parent.parent.R:Phrase.parent.lisp_num_words_in_phrase
;;  lisp_total_words
;;  lisp_total_syls
;;  lisp_total_phrases
;;
;;  The last three will act on any item

(require 'radio_phones)
(Parameter.set 'Language 'americanenglish)
(Parameter.set 'PhoneSet 'radio)
(PhoneSet.select 'radio)

(define (distance_to_p_content i)
  (let ((c 0) (rc 0 ) (w (item.relation.prev i "Phrase")))
    (while w
      (set! c (+ 1 c))
      (if (string-equal "1" (item.feat w "contentp"))
      (begin
        (set! rc c)
        (set! w nil))
      (set! w (item.prev w)))
      )
    rc))

(define (distance_to_n_content i)
  (let ((c 0) (rc 0) (w (item.relation.next i "Phrase")))
    (while w
      (set! c (+ 1 c))
      (if (string-equal "1" (item.feat w "contentp"))
      (begin
        (set! rc c)
        (set! w nil))
      (set! w (item.next w)))
      )
    rc))

(define (distance_to_p_accent i)
  (let ((c 0) (rc 0 ) (w (item.relation.prev i "Syllable")))
    (while (and w (member_string (item.feat w "syl_break") '("0" "1")))
      (set! c (+ 1 c))
      (if (string-equal "1" (item.feat w "accented"))
      (begin
        (set! rc c)
        (set! w nil))
        (set! w (item.prev w)))
        )
        rc))

(define (distance_to_n_accent i)
  (let ((c 0) (rc 0 ) (w (item.relation.next i "Syllable")))
    (while (and w (member_string (item.feat w "p.syl_break") '("0" "1")))
      (set! c (+ 1 c))
      (if (string-equal "1" (item.feat w "accented"))
      (begin
        (set! rc c)
        (set! w nil))
        (set! w (item.next w)))
        )
        rc))

(define (distance_to_p_stress i)
  (let ((c 0) (rc 0 ) (w (item.relation.prev i "Syllable")))
    (while (and w (member_string (item.feat w "syl_break") '("0" "1")))
      (set! c (+ 1 c))
      (if (string-equal "1" (item.feat w "stress"))
      (begin
        (set! rc c)
        (set! w nil))
        (set! w (item.prev w)))
        )
        rc))

(define (distance_to_n_stress i)
  (let ((c 0) (rc 0 ) (w (item.relation.next i "Syllable")))
    (while (and w (member_string (item.feat w "p.syl_break") '("0" "1")))
      (set! c (+ 1 c))
      (if (string-equal "1" (item.feat w "stress"))
      (begin
        (set! rc c)
        (set! w nil))
        (set! w (item.next w)))
        )
        rc))

(define (num_syls_in_phrase i)
  (apply 
   +
   (mapcar
    (lambda (w)
      (length (item.relation.daughters w 'SylStructure)))
    (item.relation.daughters i 'Phrase))))

(define (num_words_in_phrase i)
  (length (item.relation.daughters i 'Phrase)))

(define (total_words w)
  (length
   (utt.relation.items (item.get_utt w) 'Word)))

(define (total_syls s)
  (length
   (utt.relation.items (item.get_utt s) 'Syllable)))

(define (total_phrases s)
  (length
   (utt.relation_tree (item.get_utt s) 'Phrase)))


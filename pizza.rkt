#lang typed/racket
(require racket/gui/base)

; t1 - the base pizza, t2 - the topping, t3 in {left, right, all}
(define-struct Add
  ([t1 : Term]
   [t2 : Term]
   [t3 : Term]))

; t1 - the base pizza, t2 - the topping
(define-struct Remove
  ([t1 : Term]
   [t2 : Term]))

(define-type Term
  (U 'bp 'left 'right 'all 'gp 'onion 'mush Add Remove))

(define-type Token
  (U 'ID_LIKE_UH 'PIZZA 'WITH 'ON_THE 'LEFT 'RIGHT 'ALL 'AND 'ACTUALLY 'HOLD_THE 'DONT_FORGET_TO_BAKE_IT 'GREEN_PEPPERS 'ONIONS 'MUSHROOMS 'None))

;; list->cons : (listof char) -> (cons char (cons char ...))
(: list->cons : (Listof Char) (Listof Char) -> (Listof Char))
(define (list->cons lst tail)
  (if (= (length lst) 0)
      tail
      (cons (first lst)
            (list->cons (rest lst) tail))))

;; next-token : String -> (Optionof (Pair Token String))
(: next-token : (Listof Char) -> (Pairof Token (Listof Char)))
(define (next-token cs)
  (match cs
    [(cons #\i (cons #\' (cons #\d (cons #\space (cons #\l (cons #\i (cons #\k (cons #\e (cons #\space (cons #\u (cons #\h (cons #\. (cons #\. (cons #\. tail)))))))))))))) (cons 'ID_LIKE_UH tail)]
    [(cons #\p (cons #\i (cons #\z (cons #\z (cons #\a tail))))) (cons 'PIZZA tail)]
    [(cons #\w (cons #\i (cons #\t (cons #\h tail)))) (cons 'WITH tail)]
    [(cons #\o (cons #\n (cons #\space (cons #\t (cons #\h (cons #\e tail)))))) (cons 'ON_THE tail)]
    [(cons #\l (cons #\e (cons #\f (cons #\t (cons #\space (cons #\h (cons #\a (cons #\l (cons #\f tail))))))))) (cons 'LEFT tail)]
    [(cons #\r (cons #\i (cons #\g (cons #\h (cons #\t (cons #\space (cons #\h (cons #\a (cons #\l (cons #\f tail)))))))))) (cons 'RIGHT tail)]
    [(cons #\w (cons #\h (cons #\o (cons #\l (cons #\e (cons #\space (cons #\t (cons #\h (cons #\i (cons #\n (cons #\g tail))))))))))) (cons 'ALL tail)]
    [(cons #\a (cons #\n (cons #\d tail))) (cons 'AND tail)]
    [(cons #\a (cons #\c (cons #\t (cons #\u (cons #\a (cons #\l (cons #\l (cons #\y tail)))))))) (cons 'ACTUALLY tail)]
    [(cons #\h (cons #\o (cons #\l (cons #\d (cons #\space (cons #\t (cons #\h (cons #\e tail)))))))) (cons 'HOLD_THE tail)]
    [(cons #\d (cons #\o (cons #\n (cons #\' (cons #\t (cons #\space (cons #\f (cons #\o (cons #\r (cons #\g (cons #\e (cons #\t (cons #\space (cons #\t (cons #\o (cons #\space (cons #\b (cons #\a (cons #\k (cons #\e (cons #\space (cons #\i (cons #\t tail))))))))))))))))))))))) (cons 'DONT_FORGET_TO_BAKE_IT tail)]
    [(cons #\g (cons #\r (cons #\e (cons #\e (cons #\n (cons #\space (cons #\p (cons #\e (cons #\p (cons #\p (cons #\e (cons #\r (cons #\s tail))))))))))))) (cons 'GREEN_PEPPERS tail)]
    [(cons #\m (cons #\u (cons #\s (cons #\h (cons #\r (cons #\o (cons #\o (cons #\m (cons #\s tail))))))))) (cons 'MUSHROOMS tail)]
    [(cons #\o (cons #\n (cons #\i (cons #\o (cons #\n (cons #\s tail)))))) (cons 'ONIONS tail)]
    [(cons #\space tail) (next-token tail)]
    [(cons #\newline tail) (next-token tail)]
    [(cons #\tab tail) (next-token tail)]
    [_ (error 'next-token "invalid syntax: ~a" cs)]
    ))

;; lexer : string -> (listof token)

(: valid-token-list? : (Listof Token) -> Boolean)
(define (valid-token-list? ts)
  (and (eq? (first ts) 'ID_LIKE_UH)
       (eq? (last ts) 'DONT_FORGET_TO_BAKE_IT)))

(: lex-looper : (Listof Char) -> (Listof Token))
(define (lex-looper cs)
  (match cs
    ['() '()]
    [_ (match (next-token cs)
         [(cons tok '()) (list tok)]
         [(cons tok tail) (cons tok (lex-looper tail))])]))

(: lex : String -> (Listof Token))
(define (lex s)
  (local
    {(define toks (lex-looper (string->list s)))}
    (unless (valid-token-list? toks)
      (error 'lex "not a valid format: ~a" s))
    toks))

;; (split-add-remove '() toks)
(: split-add-remove : (Pair (Listof Token) (Listof Token)) -> (Pair (Listof Token) (Listof Token)))
(define (split-add-remove as-rs)
  (match as-rs
    [(cons as rs)
     (match rs
       [(cons 'ACTUALLY rtail) (cons as rtail)]
       [(cons tok rtail) (split-add-remove (cons (cons tok as) rtail))])]))

(: token->term : Token -> Term)
(define (token->term tok)
  (match tok
    ['ONIONS 'onion]
    ['GREEN_PEPPERS 'gp]
    ['MUSHROOMS 'mush]
    ['LEFT 'left]
    ['RIGHT 'right]
    ['ALL 'all]))

(: add-toks->add-term : (Listof Token) -> Term)
(define (add-toks->add-term as)
  (match as
    [(cons 'ID_LIKE_UHH tail) (add-toks->add-term tail)]
    [(cons 'DONT_FORGET_TO_BAKE_IT tail) (add-toks->add-term tail)]
    [(cons loc (cons 'ON_THE (cons topping (cons word tail))))
     #:when (and (not (empty? (member loc (list 'LEFT 'RIGHT 'ALL))))
                 (not (empty? (member topping (list 'MUSHROOMS 'ONIONS 'GREEN_PEPPERS))))
                 (not (empty? (member word (list 'WITH 'AND)))))
     (Add (add-toks->add-term tail) (token->term topping) (token->term loc))]
    [(cons 'PIZZA '()) 'bp]
    [(cons 'PIZZA tail) 'bp]
    [_ (error 'add-toks->add-term "invalid tokens: ~a" as)]))



;; next-term : (Listof Token) -> (Pair Term (Listof Token)
(: next-term : (Listof Token) -> (Pair Term (Listof Token)))
(define (next-term toks)
  (match toks
    [(cons 'ONIONS tail) (cons 'onion tail)]
    [(cons 'GREEN_PEPPERS tail) (cons 'gp tail)]
    [(cons 'MUSHROOMS tail) (cons 'mush tail)]
    [(cons 'ID_LIKE_UH tail) (next-term tail)]
    [(cons 'DONT_FORGET_TO_BAKE_IT tail) (next-term tail)]))
    

;; parse : (listof token) -> Term
(define (parse tokens) 'onion)

;; interp : Term -> GUI PICTURE!
(define (interp term)
  term)


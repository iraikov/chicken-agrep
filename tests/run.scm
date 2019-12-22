(import agrep test)

(define pat (string->pattern "text"))

(test-assert  (string-match pat "text" numerrs: 1))
(test-assert  (string-match pat "test" numerrs: 1))
(test-assert (not (string-match pat "tesk" numerrs: 1)))
(test-assert (string-match pat "tesk" numerrs: 2))

(test-exit)

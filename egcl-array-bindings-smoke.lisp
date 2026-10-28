(require :asdf)
(asdf:load-system "babel")

(defun selected-array-values (array start end)
  (babel::with-simple-vector ((data array) (lo start) (hi end))
    (declare (type fixnum lo hi))
    (values (loop for i from lo below hi collect (aref data i)) (- hi lo) :third)))

#+egcl
(defun portable-array-values (array start end)
  (funcall (if (adjustable-array-p array)
               #'babel::call-with-array-data/copy
               #'babel::call-with-array-data/fast)
           array start end
           (lambda (data lo hi)
             (values (loop for i from lo below hi collect (aref data i))
                     (- hi lo) :third))))

(let* ((base (make-array 8 :element-type '(unsigned-byte 8)
                         :initial-contents '(10 11 12 13 14 15 16 17)))
       (displaced (make-array 5 :element-type '(unsigned-byte 8)
                              :displaced-to base :displaced-index-offset 1))
       (nested (make-array 3 :element-type '(unsigned-byte 8)
                           :displaced-to displaced :displaced-index-offset 1))
       (adjustable (make-array 5 :element-type '(unsigned-byte 8) :adjustable t
                                :initial-contents '(20 21 22 23 24)))
       (fp (make-array 5 :element-type '(unsigned-byte 8) :adjustable t :fill-pointer 3
                        :initial-contents '(30 31 32 33 34))))
  (assert (equal (multiple-value-list (selected-array-values base 2 5))
                 '((12 13 14) 3 :third)))
  (assert (equal (multiple-value-list (selected-array-values displaced 1 4))
                 '((12 13 14) 3 :third)))
  (assert (equal (multiple-value-list (selected-array-values nested 1 3))
                 '((13 14) 2 :third)))
  (assert (equal (multiple-value-list (selected-array-values adjustable 1 4))
                 '((21 22 23) 3 :third)))
  (assert (equal (multiple-value-list (selected-array-values fp 1 (length fp)))
                 '((31 32) 2 :third)))
  (assert (equal (multiple-value-list (selected-array-values base 3 3))
                 '(nil 0 :third)))
  #+egcl
  (dolist (case (list (list base 2 5) (list displaced 1 4)
                     (list nested 1 3) (list adjustable 1 4)
                     (list fp 1 3) (list base 3 3)))
    (destructuring-bind (array start end) case
      (assert (equal (multiple-value-list (selected-array-values array start end))
                     (multiple-value-list (portable-array-values array start end))))))
  ;; A nonadjustable displaced view aliases the ultimate storage.
  (babel::with-simple-vector ((data nested) (lo 0) (hi 1))
    (declare (ignore hi)) (setf (aref data lo) 99))
  (assert (= (aref base 2) 99))
  ;; A fill pointer limits checked input length, not this unchecked macro's
  ;; explicit capacity bounds. Preserve the portable nonadjustable branch.
  (let ((nonadjustable-fp (make-array 5 :element-type '(unsigned-byte 8)
                                       :fill-pointer 2 :initial-element 7)))
    (assert (equal (multiple-value-list (selected-array-values nonadjustable-fp 3 5))
                   '((7 7) 2 :third))))
  ;; The existing EGCL portable branch copies adjustable input and never
  ;; writes the temporary back. SBCL exposes actual underlying storage.
  (babel::with-simple-vector ((data adjustable) (lo 1) (hi 2))
    (declare (ignore hi)) (setf (aref data lo) 77))
  #+egcl (assert (= (aref adjustable 1) 21))
  #+sbcl (assert (= (aref adjustable 1) 77))
  (assert (null (multiple-value-list
    (babel::with-simple-vector ((data base) (lo 0) (hi 0))
      (declare (ignore data lo hi)) (values)))))
  (let ((order nil))
    (assert (= 42
      (babel::with-simple-vector
          ((data (progn (push :vector order) base))
           (lo (progn (push :start order) 1))
           (hi (progn (push :end order) 2)))
        (declare (ignore data lo hi))
        (push :body order) 42)))
    (assert (equal (reverse order) '(:vector :start :end :body)))))
;; Input names may coincide with output names; final bindings must capture
;; all normalized values before the caller's declarations take effect.
(let ((data (make-array 4 :initial-contents '(40 41 42 43)))
      (lo 1) (hi 3))
  (assert (equal
    (multiple-value-list
      (babel::with-simple-vector ((data data) (lo lo) (hi hi))
        (declare (type fixnum lo hi))
        (values (aref data lo) (aref data (1- hi)))))
    '(41 42))))
(defvar *array-binding-smoke-data* :outside)
(let ((input (make-array 1 :initial-element 9)))
  (assert (= 9
    (babel::with-simple-vector ((*array-binding-smoke-data* input) (lo 0) (hi 1))
      (declare (special *array-binding-smoke-data*) (ignore hi))
      (aref *array-binding-smoke-data* lo))))
  (assert (eq *array-binding-smoke-data* :outside)))
#+egcl
(let ((input (make-array 3 :initial-contents '(81 82 83) :adjustable t)))
  (babel::with-simple-vector ((data input) (lo 1) (hi 3))
    (egcl-ext:gc)
    (assert (= (aref data lo) 82))
    (assert (= (aref data (1- hi)) 83))))
(format t "BABEL-ARRAY-BINDINGS-OK~%")

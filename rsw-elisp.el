;;; rsw-elisp.el --- Interactively eval regions, var defs, quoted sexps
;;
;; Author:           Robert Weiner <rsw at gnu dot org>
;; Maintainer:       Robert Weiner <rsw at gnu dot org>
;; Created:          20-Dec-17 at 15:44:48
;; Released:         23-Dec-17
;; Version:          1.0.3
;; Keywords:         languages, tools
;; Package:          rsw-elisp
;; Package-Requires: ((emacs "24.4.0"))
;; URL:              http://github.com/rswgnu/rsw-elisp
;;
;;
;; Copyright (C) 2017  Free Software Foundation, Inc.
;; Licensed under the GNU General Public License, version 3.
;;
;; This file is not part of GNU Emacs.
;; It is derived from Emacs elisp-mode.el.
;;
;; This is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;   This code improves and replaces the GNU Emacs commands that
;;   interactively evaluate Emacs Lisp expressions.  The new commands
;;   replace standard key bindings and are all prefixed with `rsw-elisp-'.
;;   They work the same way as the old commands when called non-interactively;
;;   only the interactive behavior should be different, as described below.

;;   To set up to use this every Emacs session, first install this package
;;   with an Emacs package manager and then add the following to your
;;   Emacs initialization file:
;;
;;     (require 'rsw-elisp)
;;     (rsw-elisp-enable)
;;
;;   Or you can test it out the remapped key bindings of all of the
;;   interactive Emacs Lisp evaluation commands and a few minibuffer
;;   helper commands, with:
;;
;;     M-x rsw-elisp-enable RET
;;
;;   To return to the standard key bindings, use:
;;
;;     M-x rsw-elisp-disable RET
;;
;;   To toggle this on and off, use:
;;
;;     M-x rsw-elisp-toggle RET
;;
;;   Programmatically, to see whether it is enabled or not, use:
;;
;;     (rsw-elisp-p)

;;   The commands and key bindings herein provide 5 new features for
;;   interactive Emacs Lisp evaluation:
;;
;;     1.  Evaluating Quoted Expressions: C-x C-e `eval-last-expression'
;;         on a regularly quoted sexpression doesn't show you anything
;;         different than what you see on screen already.  You really want
;;         to see the value of the unquoted sexpression and now you can.
;;         C-x C-e `rsw-elisp-eval-last-expression' and M-:
;;         `rsw-elisp-eval-expression' remove any regular outer quotes
;;         from sexpressions and show you the value.  For example,
;;         'emacs-version interactively yields "26.0.50".
;;
;;         This is for programmers who already understand how quoting
;;         works and don't need to see the same expression fed back to
;;         them.  For times where you really need to see the quoted
;;         form, use a backquote ` or a backquote followed by a
;;         regular quote '.
;;
;;     2.  Evaluating Function Symbols: When interactively evaluating a
;;         symbol, Emacs returns only the symbol's value, giving an unbound
;;         error if it is not defined.  But if it is a function symbol in
;;         such a case, you typically want to see its function binding, so
;;         these functions return that when the symbol is bound as a
;;         function (or a macro) but not a variable.
;;
;;     3.  Redefining Variables: Interactively calling
;;         `eval-last-expression' with point after a previously defined
;;         variable definition does not reset its value in Emacs, though
;;         clearly the only reason to do this is to redefine the variable.
;;         Although `eval-defun' does do this, there is no reason to have to
;;         use a different key binding than you would to interactively
;;         evaluate other expressions.  C-x
;;         C-e `rsw-elisp-eval-last-expression' resolves this.
;;
;;     4.  Default Expressions to Evaluate: When using M-: bound
;;         to `rsw-elisp-eval-expression', if a region
;;         is active, the leading expression in the region is used as the
;;         default expression to evaluate and included in the prompt.
;;         Otherwise, if called with point in an Emacs Lisp mode listed in
;;         `rsw-elisp-modes' and not on a whitespace character, then the
;;         expression around point is used as the default.
;;
;;     5.  Editing Default Expressions: If you ever want to edit the
;;         default, use M-y `rsw-elisp-yank-pop; to yank it into the
;;         editable portion of the minibuffer, any time other than after a
;;         yank command.  (M-y still performs its normal `yank-pop'
;;         function as well after a C-y `yank').  If you yank in a large
;;         expression by mistake, press C-d or DELETE FORWARD when at
;;         the end of the minibuffer to erase its entire contents.  If you
;;         prefer these helper keys not be bound, after the call to:
;;
;;           (rsw-elisp-enable)
;;
;;         add:
;;
;;           (setq rsw-elisp-helper-keys nil)

;;; Code:

;;; ************************************************************************
;;; Key bindings
;;; ************************************************************************

(defvar rsw-elisp-helper-keys t
  "When non-nil, `rsw-elisp-enable' binds minibuffer helper keys.
\\[delete-char] at the end of the minibuffer deletes its entire contents.
\\[yank-pop] when not after a yank, inserts the default expression for editing.")

(defun rsw-elisp-p ()
  "Return non-nil if `rsw-elisp' interactive Emacs Lisp evaluation commands are enabled."
  (eq (key-binding (kbd "M-:")) #'rsw-elisp-eval-expression))

;;;###autoload
(defun rsw-elisp-enable ()
  "Enable improvements to interactive Emacs Lisp evaluation commands."
  (interactive)
  ;; M-:
  (global-set-key [remap eval-expression] 'rsw-elisp-eval-expression)
  ;;
  ;; C-x C-e
  (global-set-key [remap eval-last-sexp] 'rsw-elisp-eval-last-sexp)
  (when (require 'eros nil t)
    ;; If you have the Eros Elisp evaluation result in-buffer overlay
    ;; package installed, use that.
    (global-set-key [remap eros-eval-last-sexp] 'rsw-elisp-eros-eval-last-sexp))
  ;;
  ;; RET in Lisp Interaction Mode
  (define-key lisp-interaction-mode-map [remap eval-print-last-sexp] 'rsw-elisp-eval-print-last-sexp)
  ;;
  (when rsw-elisp-helper-keys
    ;; The next key remappings make C-d and the DELETE FORWARD key, when at the
    ;; end of the minibuffer, delete its whole contents.  That way, a
    ;; large expression can be deleted with one key press and then
    ;; replaced with another.
    ;;
    ;; C-d and <deletechar>, forward delete char, in the minibuffer
    (define-key minibuffer-local-map [remap delete-char] 'rsw-elisp-delete-char)
    (define-key minibuffer-local-map [remap delete-forward-char] 'rsw-elisp-delete-forward-char)
    ;;
    ;; Any default expression pulled from the current buffer by M-: is
    ;; included in the non-editable prompt.  If you ever want to edit
    ;; the default, the next key remapping makes M-y in the minibuffer,
    ;; if not preceded by a yank command, insert the default into the
    ;; editable minibuffer contents, as if from the kill ring.
    ;; M-y
    (define-key minibuffer-local-map [remap yank-pop] 'rsw-elisp-yank-pop))
  ;;
  (if (called-interactively-p)
      (message "rsw-elisp enabled; using improved Emacs Lisp evaluation commands")))

(defun rsw-elisp-disable ()
  "Disable improvements to interactive Emacs Lisp evaluation commands."
  (interactive)
  ;; M-:
  (global-set-key [remap eval-expression] nil)
  ;;
  ;; C-x C-e
  (global-set-key [remap eval-last-sexp] nil)
  (when (require 'eros nil t)
    (global-set-key [remap eros-eval-last-sexp] nil))
  ;;
  ;; RET in Lisp Interaction Mode
  (define-key lisp-interaction-mode-map [remap eval-print-last-sexp] nil)
  ;;
  ;; C-d and <deletechar>, forward delete char
  (define-key minibuffer-local-map [remap delete-char] nil)
  (define-key minibuffer-local-map [remap delete-forward-char] nil)
  ;;
  ;; M-y, yank-pop the initial expression into the minibuffer at any time, as if
  ;; from the kill ring.
  (define-key minibuffer-local-map [remap yank-pop] nil)
  ;;
  (if (called-interactively-p)
      (message "rsw-elisp disabled; using standard Emacs Lisp evaluation commands")))

;;;###autoload
(defun rsw-elisp-toggle ()
  "Toggle improvements to interactive Emacs Lisp evaluation commands on and off."
  (interactive)
  (if (rsw-elisp-p)
      (call-interactively #'rsw-elisp-disable)
    (call-interactively #'rsw-elisp-enable)))

;;; ************************************************************************
;;; Private variables
;;; ************************************************************************

(defvar rsw-elisp--default nil
  "The value of the initial expression inserted during `rsw-elisp-eval-expression'.")

;;; ************************************************************************
;;; Public variables
;;; ************************************************************************

(defvar rsw-elisp-modes '(emacs-lisp-mode lisp-interaction-mode))

;;; ************************************************************************
;;; Private functions
;;; ************************************************************************

(defun rsw-elisp-read (&optional stream)
  "Read one Lisp expression as text from STREAM, return as Lisp object or nil on error.
If STREAM is nil, use the value of `standard-input' (which see).
STREAM or the value of `standard-input' may be:
 a buffer (read from point and advance it)
 a marker (read from where it points and advance it)
 a function (call it with no arguments for each character,
     call it with a char as argument to push a char back)
 a string (takes text from string, starting at the beginning)
 t (read text line using minibuffer and use it, or read from
    standard input in batch mode)."
  (condition-case ()
      (read stream)
    (error nil)))

(defun rsw-elisp-eval (expr interactive-flag)
  "Same as `eval' but if EXPR is not boundp and is fboundp and INTERACTIVE-FLAG is non-nil, return EXPR's symbol function.
Otherwise, just return EXPR's value.  With INTERACTIVE-FLAG non-nil,
remove any regular quotes before evaluation. 

If `lexical-binding' is t, evaluate using lexical scoping.
`lexical-binding' can also be an actual lexical environment, in the
form of an alist mapping symbols to their value."
  (if interactive-flag
      (progn (setq expr (rsw-elisp-unquote-sexp expr))
	     (if (eq (type-of expr) 'symbol)
		 (cond ((boundp expr)
			`,(symbol-value expr))
		       ((fboundp expr)
			`,(symbol-function expr))
		       (t (eval expr lexical-binding)))
	       (eval expr lexical-binding)))
    (eval expr lexical-binding)))

(defun rsw-elisp-delete-char (n &optional killflag)
  "Like `delete-char' but if in the minibuffer and at end of buffer, delete contents.
Use undo to get the contents back, if necessary."
  (interactive "p\nP")
  (if (and (minibufferp) (eobp))
      (delete-region (minibuffer-prompt-end) (point-max))
    (delete-char n killflag)))

(defun rsw-elisp-delete-forward-char (n &optional killflag)
  "Delete the following N characters (previous if N is negative).
If Transient Mark mode is enabled, the mark is active, and N is 1,
delete the text in the region and deactivate the mark instead.
To disable this, set variable `delete-active-region' to nil.

Optional second arg KILLFLAG non-nil means to kill (save in kill
ring) instead of delete.  Interactively, N is the prefix arg, and
KILLFLAG is set if N was explicitly specified.

When killing, the killed text is filtered by
`filter-buffer-substring' before it is saved in the kill ring, so
the actual saved text might be different from what was killed."
  (declare (interactive-only delete-char))
  (interactive "p\nP")
  (unless (integerp n)
    (signal 'wrong-type-argument (list 'integerp n)))
  (if (and (minibufferp) (eobp))
      (delete-region (minibuffer-prompt-end) (point-max))
    ;; Otherwise, do simple forward deletion.
    (delete-forward-char n killflag)))

(defun rsw-elisp-unquote-sexp (exp)
  "Remove Elisp quote prefixes; leave backquote and function # quote."
    (while (and (consp exp) (memq (car exp) '(quote)))
      (setq exp (cadr exp)))
    exp)

(defun rsw-elisp-get-thing-at-point ()
  "If in an `rsw-elisp-modes' major mode and not over whitespace, return the Lisp form around point as a string.
Otherwise, return the empty string."
  ;; Hyperbole's "hui-select.el" library does a better selection job
  ;; than "thingatpt.el", so use it if available.
  (let (str)
    (cond ((fboundp 'hui-select-get-region)
	   (let ((pos (point))
		 (end))
	     (setq str (unless (eolp)
			 (save-excursion
			   (if (memq (char-syntax (char-after pos)) '(?w ?_))
			       (progn (condition-case ()
					  (progn (setq end (scan-sexps pos 1))
						 (buffer-substring-no-properties
						  (min pos (scan-sexps end -1)) end))
					(error nil)))
			     (hui-select-reset)
			     (hui-select-get-region)))))))
	  ((or (eobp) (looking-at "[ \t\n\r]"))
	   (setq str ""))
	  (t (setq str (thing-at-point 'sexp))))
    (if str (string-trim str) "")))

(defun rsw-elisp-internal-eval-last-sexp (arg interactive-flag)
  "Same as `elisp--eval-last-sexp' but does not print to the minibuffer.
Prefix ARG is followed by INTERACTIVE-FLAG, which if non-nil, calls
`rsw-elisp-unquote-sexp' to strip any initial regular quoting."
  (unless arg (setq arg current-prefix-arg))
  (pcase-let*
      ((`(,insert-value ,no-truncate ,char-print-limit)
        (eval-expression-get-print-arguments arg)))
    ;; Setup the lexical environment if lexical-binding is enabled.
    (elisp--eval-last-sexp-print-value
     (rsw-elisp-eval (eval-sexp-add-defvars (rsw-elisp-unquote-sexp (elisp--preceding-sexp)))
		     nil)
     (if insert-value (current-buffer) t) no-truncate char-print-limit)))

(defun rsw-elisp-eval-last-sexp-or-def (arg interactive-flag)
  "If at the start or end of a Lisp definition, define/redefine it; otherwise, eval preceding expression.
Given a non-nil prefix ARG, print eval result to the buffer.  When INTERACTIVE-FLAG is non-nil,
if the expression is a constant or variable definition, its value is redefined."
  (interactive "P\np")
  (condition-case ()
      ;; If after or at the start of a Lisp definition, use eval-defun
      (if (and interactive-flag
	       (save-excursion 
		 ;; Go to beginning of current or prior sexp
		 (goto-char (or (scan-sexps (point) -1) (point)))
		 ;; Exclude any define- lines.
		 (and (looking-at "\\(;*[ \t]*\\)?(def[[:alnum:]]*[[:space:]]")
		      ;; Ignore lines that start with (default
		      (not (looking-at "\\(;*[ \t]*\\)?(default")))))
	  ;; At or after a definition
	  (if arg
	      (prin1 (eval-defun nil) (current-buffer))
	    (eval-defun nil))
	;; At or after another kind of sexp
	(rsw-elisp-internal-eval-last-sexp arg interactive-flag))
    ;; Error also means it wasn't a definition, so evaluate it normally
    (error (rsw-elisp-internal-eval-last-sexp arg interactive-flag))))

(defun rsw-elisp-read-expression (prompt &optional initial-contents)
  (let ((minibuffer-completing-symbol t)
	str)
    (minibuffer-with-setup-hook
	(lambda ()
          ;; FIXME: call emacs-lisp-mode?
          (add-function :before-until (local 'eldoc-documentation-function)
			#'elisp-eldoc-documentation-function)
          (eldoc-mode 1)
          (add-hook 'completion-at-point-functions
                    #'elisp-completion-at-point nil t)
          (run-hooks 'eval-expression-minibuffer-setup-hook))
      ;; Allow empty input, in which case this returns the empty string.
      (setq str (read-from-minibuffer prompt initial-contents
				      read-expression-map nil
				      'read-expression-history)))
    (if (and str (not (equal str "")))
	(rsw-elisp-read str)
      str)))

;;; ************************************************************************
;;; Public functions
;;; ************************************************************************

;;;###autoload
(defun rsw-elisp-eval-expression (exp &optional insert-value no-truncate char-print-limit)
  "Same as `eval-expression' but when called interactively, uses sexp near point as a default.
If the region is active, use the first sexp from there.  Otherwise, if not on a
whitespace character and in one of the `rsw-elisp-modes' major modes,
then remove any regular quoting (not backquoting) from the sexp around point
and use that as the default."
  (interactive
   (progn (setq exp (cond ((use-region-p)
			   (buffer-substring-no-properties
			    (region-beginning) (region-end)))
			  ((memq major-mode rsw-elisp-modes)
			   (rsw-elisp-get-thing-at-point)))
		;; Convert string to an sexpression
		exp (and exp (not (equal exp "")) (rsw-elisp-read exp))
		exp (if (not noninteractive)
			(rsw-elisp-unquote-sexp exp)
		      exp)
		rsw-elisp--default (if (and exp (not (stringp exp)))
				       (prin1-to-string exp)
				     exp))
	  (let ((result (rsw-elisp-read-expression
			 (if (and exp (not (equal exp "")))
			     (format "Eval (default %s): " exp)
			   "Eval: "))))
	    (if (and result (not (equal result "")))
		(setq exp result)))
	  (setq rsw-elisp--default (if (and exp (not (stringp exp)))
				       (prin1-to-string exp)
				     exp)
		exp (if (and (equal exp "")
			     rsw-elisp--default
			     (not (equal rsw-elisp--default "")))
			(rsw-elisp-read rsw-elisp--default)
		      exp))
	  (cons exp (eval-expression-get-print-arguments current-prefix-arg))))
  (unwind-protect
      (let ((interactive-flag (and (called-interactively-p 'any)
				   (not noninteractive))))
	(setq rsw-elisp--default (if (and exp (not (stringp exp)))
				     (prin1-to-string exp)
				   exp))
	(if (null eval-expression-debug-on-error)
	    (push (rsw-elisp-eval exp interactive-flag) values)
	  (let ((old-value (make-symbol "t")) new-value)
	    ;; Bind debug-on-error to something unique so that we can
	    ;; detect when evalled code changes it.
	    (let ((debug-on-error old-value))
	      (push (rsw-elisp-eval exp interactive-flag) values)
	      (setq new-value debug-on-error))
	    ;; If evalled code has changed the value of debug-on-error,
	    ;; propagate that change to the global binding.
	    (unless (eq old-value new-value)
	      (setq debug-on-error new-value))))

	     (let ((print-length (unless no-truncate eval-expression-print-length))
		   (print-level  (unless no-truncate eval-expression-print-level))
		   (eval-expression-print-maximum-character char-print-limit)
		   (deactivate-mark))
	       (let ((out (if insert-value (current-buffer) t)))
		 (prog1
		     (prin1 (car values) out)
		   (let ((str (and char-print-limit
				   (eval-expression-print-format (car values)))))
		     (when str (princ str out)))))))
    (setq rsw-elisp--default nil)))

;;;###autoload
(defun rsw-elisp-eval-last-sexp (arg &optional interactive-flag)
  "Evaluate sexp before point with any non-backquoting removed; print value in the echo area.

Interactively, with a non `-' prefix argument, instead print
output into the current buffer.  Interactively, this redefines
any variable definition preceding point.

Normally, this function truncates long output according to the
value of the variables `eval-expression-print-length' and
`eval-expression-print-level'.  With a prefix argument of zero,
however, there is no such truncation.  Such a prefix argument
also causes integers to be printed in several additional formats
\(octal, hexadecimal, and character when the prefix argument is
-1 or the integer is `eval-expression-print-maximum-character' or
less).

If `eval-expression-debug-on-error' is non-nil, which is the default,
this command arranges for all errors to enter the debugger."
  (interactive "P\np")
  (if (null eval-expression-debug-on-error)
      (rsw-elisp-eval-last-sexp-or-def arg interactive-flag)
    (let ((value
	   (let ((debug-on-error elisp--eval-last-sexp-fake-value))
	     (cons (rsw-elisp-eval-last-sexp-or-def
		    arg interactive-flag)
		   debug-on-error))))
      (unless (eq (cdr value) elisp--eval-last-sexp-fake-value)
	(setq debug-on-error (cdr value)))
      (car value))))

;;;###autoload
(defun rsw-elisp-eros-eval-last-sexp (arg)
"Evaluate sexp before point with any non-backquoting removed.
Display result value with a text overlay at the end of the
current line.

Interactively, with a non `-' prefix argument, additionally print
output into the current buffer.  Interactively, this redefines
any variable definition preceding point.

Normally, this function truncates long output according to the
value of the variables `eval-expression-print-length' and
`eval-expression-print-level'.  With a prefix argument of zero,
however, there is no such truncation.  Such a prefix argument
also causes integers to be printed in several additional formats
\(octal, hexadecimal, and character when the prefix argument is
-1 or the integer is `eval-expression-print-maximum-character' or
less).

If `eval-expression-debug-on-error' is non-nil, which is the default,
this command arranges for all errors to enter the debugger."
  (interactive "P")
  (require 'eros)
  (eros--eval-overlay
   (rsw-elisp-eval-last-sexp arg (and (called-interactively-p 'any)
				      (not noninteractive)))
   (point)))

;; Bind this to {C-j} in Emacs Lisp interaction mode.
;;;###autoload
(defun rsw-elisp-eval-print-last-sexp (&optional arg)
  "Evaluate sexp before point with any non-backquoting removed and print value into current buffer.

Interactively, this redefines any variable definition preceding point.

Normally, this function truncates long output according to the value
of the variables `eval-expression-print-length' and
`eval-expression-print-level'.  With a prefix argument of zero,
however, there is no such truncation.  Such a prefix argument
also causes integers to be printed in several additional formats
\(octal, hexadecimal, and character).

If `eval-expression-debug-on-error' is non-nil, which is the default,
this command arranges for all errors to enter the debugger."
  (interactive "P")
  ;; Caller may have moved point down past the last sexp
  (if (eolp) (skip-chars-backward " \t\n\r"))
  (let ((sexp (rsw-elisp-eval-last-sexp
	       arg (and (called-interactively-p 'any)
			(not noninteractive))))
	(standard-output (current-buffer)))
    (terpri)
    (prin1 sexp)
    (terpri)))

;;;###autoload
(defun rsw-elisp-yank-pop (&optional arg)
  "Like `yank-pop' but if last command was not a yank, inserts any `rsw-elisp--default' text.
Typically, one would bind this to {M-y} in the minibuffer only."
  (interactive "*p")
  (if (and (not (eq last-command 'yank))
	   rsw-elisp--default (not (string-empty-p rsw-elisp--default)))
      (progn
	(setq this-command 'yank)
	;; Yank any default value sent to the minibuffer
	(set-marker (mark-marker) (point) (current-buffer))
	(insert rsw-elisp--default))
    (yank-pop arg)))

(provide 'rsw-elisp)

;;; rsw-elisp.el ends here

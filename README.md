# rsw-elisp
Interactively evaluate regions, preceding variable definitions and quoted sexpressions

This code improves and replaces the GNU Emacs commands that
interactively evaluate Emacs Lisp expressions.  The new commands
replace standard key bindings and are all prefixed with `rsw-elisp-`.
They work the same way as the old commands when called non-interactively;
only the interactive behavior should be different, as described below.

To set up to use this every Emacs session, first install this package
with an Emacs package manager and then add the following to your
Emacs initialization file:

    (require 'rsw-elisp)
    (rsw-elisp-enable)

Or you can test it out the remapped key bindings of all of the
interactive Emacs Lisp evaluation commands and a few minibuffer
helper commands, with:

    M-x rsw-elisp-enable RET

To return to the standard key bindings, use:

    M-x rsw-elisp-disable RET

The commands and key bindings herein provide 5 new features for
interactive Emacs Lisp evaluation:

  1.  **Evaluating Quoted Expressions**: *C-x C-e* (`eval-last-expression`) on
      a regularly quoted sexpression doesn't show you anything
      different than what you see on screen already.  You really want
      to see the value of the unquoted sexpression and now you can.
      *C-x C-e* (`rsw-elisp-eval-last-expression`) and
      *M-:* (`rsw-elisp-eval-expression`) remove any regular outer quotes
      from sexpressions and show you the value.  For example,
      `'emacs-version` interactively yields "26.0.50".

      This is for programmers who already understand how quoting
      works and don't need to see the same expression fed back to
      them.  For times where you really need to see the quoted
      form, use a backquote \` or a backquote followed by a
      regular quote \'.

  2.  **Evaluating Function Symbols**: When interactively evaluating a
      symbol, Emacs returns only the symbol's value, giving an unbound
      error if it is not defined.  But if it is a function symbol in
      such a case, you typically want to see its function binding, so
      these functions return that when the symbol is bound as a
      function (or a macro) but not a variable.

  3.  **Redefining Variables**: Interactively calling
      `eval-last-expression` with point after a previously defined
      variable definition does not reset its value in Emacs, though
      clearly the only reason to do this is to redefine the variable.
      Although `eval-defun` does do this, there is no reason to have to
      use a different key binding than you would to interactively
      evaluate other expressions.  *C-x C-e*
      (`rsw-elisp-eval-last-expression`) resolves this. 

  4.  **Default Expressions to Evaluate**: When using *M-:* bound
      to (`rsw-elisp-eval-expression`), if a region
      is active, the leading expression in the region is used as the
      default expression to evaluate and included in the prompt.
      Otherwise, if called with point in an Emacs Lisp mode listed in
      `rsw-elisp-modes` and not on a whitespace character, then the
      expression around point is used as the default.

  5.  **Editing Default Expressions**: If you ever want to edit the
      default, use *M-y* (`rsw-elisp-yank-pop`) to yank it into the
      editable portion of the minibuffer, any time other than
      after a `yank` command.  (*M-y* still performs its normal
      `yank-pop` function as a *C-y* `yank`).  If you yank a
      large expression in by mistake, press *C-d* or *DELETE FORWARD*
      when at the end of the minibuffer to erase its entire
      contents.  If you prefer these helper keys not be bound,
      after the call to:

         ```
		 (rsw-elisp-enable)
		 ```

      add:

         ```
		 (setq rsw-elisp-helper-keys nil)
		 ```


;;; app-launchers.el --- Simple app launcher via desktop entries

;;; Code:

;; App-Launcher
;; The app-launcher package reads desktop entries, and its prompts respect
;; completing-read, so it works well with Vertico/Orderless.

(use-package app-launcher
  :commands (app-launcher-run-app))
;; create a global keyboard shortcut with the following code
;; emacsclient -cF "((visibility . nil))" -e "(emacs-run-launcher)"

(defun dt/emacs-run-launcher ()
  "Create a minibuffer-only frame, run app-launcher, then delete the frame."
  (interactive)
  (with-selected-frame
    (make-frame '((name . "emacs-run-launcher")
                  (minibuffer . only)
                  (fullscreen . 0) ; no fullscreen
                  (undecorated . t) ; remove title bar
                  ;;(auto-raise . t) ; focus on this frame
                  ;;(tool-bar-lines . 0)
                  ;;(menu-bar-lines . 0)
                  (internal-border-width . 10)
                  (width . 80)
                  (height . 11)))
    (unwind-protect
        (app-launcher-run-app)
      (delete-frame))))


(provide 'app-launchers)
;;; app-launchers.el ends here

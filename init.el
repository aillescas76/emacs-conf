;; Minimal init entrypoint for this config.
(let ((config-el (expand-file-name "config.el" user-emacs-directory))
      (config-org (expand-file-name "config.org" user-emacs-directory)))
  (when (and (not (file-exists-p config-el))
             (file-exists-p config-org))
    ;; Tangle config.org on first run to create config.el.
    (require 'org)
    (org-babel-tangle-file config-org))
  (load config-el))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

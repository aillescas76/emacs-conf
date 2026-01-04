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
 '(package-selected-packages
   '(cape corfu dashboard diminish dired-open dirvish doom-modeline
	  doom-themes eat elfeed-goodies elixir-mode embark-consult
	  eshell-syntax-highlighting eshell-toggle general
	  git-timemachine haskell-mode helpful hl-todo lua-mode magit
	  marginalia nerd-icons-completion nerd-icons-corfu
	  nerd-icons-dired orderless org-bullets org-roam peep-dired
	  perspective php-mode pyvenv rainbow-delimiters rainbow-mode
	  sudo-edit tldr toc-org treesit-auto unicode-fonts vertico
	  visual-fill-column vundo yasnippet-snippets)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

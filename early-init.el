(setq package-enable-at-startup nil)

;; Reduce startup work and avoid UI flashing.
(setq gc-cons-threshold (* 50 1000 1000))
(menu-bar-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode -1)
(tooltip-mode -1)
(set-fringe-mode -1)
(setq native-comp-async-report-warnings-errors nil)

;; Frame defaults for first frame.
(add-to-list 'default-frame-alist '(fullscreen . maximized))
(add-to-list 'default-frame-alist '(alpha-background . 100))

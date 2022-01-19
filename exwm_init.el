(defun aic/exwm-update-class()
  (exwm-workspace-rename-buffer exwm-class-name))
(use-package exwm
  :config
  ;; Set default number of workspaces
  (setq exwm-workspace-number 5)

  ;; When window "class" updates, use it to set the buffer name
  (add-hook 'exwm-update-class-hook #'aic/exwm-update-class)
  (add-hook 'exwm-init-hook #'aic/start-panel)
  ;; (require 'exwm-systemtray)
  ;; (exwm-systemtray-enable)
  ;; These keys should always pass through to emacs
  (setq exwm-input-prefix-keys
      '(?\C-x
        ?\C-u
        ?\C-h
        ?\M-x
        ?\M-'
        ?\M-&
        ?\M-:
        ?\C-\M-j ;; Buffer list
        ?\C-\ )) ;; Ctrl+Space
  ;; Ctrl+q will enable the next key to be sent directly
  (define-key exwm-mode-map [?\C-q] 'exwm-input-send-next-key)

  ;; Set up global key bindings. These always work, no matter the input state!
  ;; Keep in mind that changing this list after EXWM initializes has no effect.
  (setq exwm-input-global-keys
        `(
        ;; Reset to line-mode (C-c C-k switches to char-mode via exwm-input-release-keyboard)
        ([?\s-r] . exwm-reset)

        ;; Move between windows
        ([s-left] . windmove-left)
        ([s-right] . windmove-right)
        ([s-up] . windmove-up)
        ([s-down] . windmove-down)

        ;; Launch applications via shell command
        ([?\s-&] . (lambda (command)
                     (interactive (list (read-shell-command "$ ")))
                     (start-process-shell-command command nil command)))

        ;; Shortcut for Chrome
        ([?\s-g] . (lambda ()
                   (interactive)                   
                   (start-process-shell-command "google-chrome" nil "google-chrome")))

        ;; Shortcut for firefox
        ([?\s-f] . (lambda ()
                   (interactive)
                   (start-process-shell-command "firefox" nil "firefox")))

        ;; Shortcut for Terminator
        ([?\s-t] . (lambda ()
                   (interactive)                   
                   (start-process-shell-command "terminator" nil "terminator")))

        ;; Switch workspace
        ([s-w] . exwm-workspace-switch)
        ([s-n] . (lambda () (interactive) (exwm-workspace-switch-create 0)))

        ;; 's-N': Switch to certain workspace with Super (Win) plus a number key (0 - 9)
        ,@(mapcar (lambda (i)
                    `(,(kbd (format "s-%d" i)) .
                      (lambda ()
                        (interactive)
                        (exwm-workspace-switch-create ,i))))
                  (number-sequence 0 9))))

  (exwm-enable))

(defvar aic/polybar-processes nil
  "Holds the processes of the running Polybar instance, if any")
(defun aic/get_monitors ()
  (split-string (shell-command-to-string "xrandr --query | grep \" connected\" | cut -d\" \" -f1")))
(defun aic/kill-panel ()
  (interactive)
    (ignore-errors
      (dolist (item aic/polybar-processes)
        (message "Killing process %s" item)
        (kill-process item)))
    (setq aic/polybar-processes nil))


(defun aic/start-panel ()
  (interactive)
  (aic/kill-panel)
  (setq aic/polybar-processes (aic/get_monitors))
  (dolist (item aic/polybar-processes)
    (while (get-process item)
      (sleep-for 0 1))
    (message "Starting polybar %s" item)
    (start-process-shell-command item nil (format "MONITOR=%s polybar --reload panel" item))))

(defun aic/distribute_windows ()
  (setq all_monitors (aic/get_monitors))
  (print (format "All monitors: %s" all_monitors))
  (if (cdr all_monitors)
    (progn
      (print "Multiple monitors")
      (setq first 1)
      (setq monitor_list nil)
      (dolist (window '(5 4 3 2 1))
        (if first
            (progn
              (push (car (cdr all_monitors)) monitor_list)
              (push window monitor_list)
              (setq first nil))
          (progn
            (push (car all_monitors) monitor_list)
            (push window monitor_list)
            (setq first 1)
            )
          )
        )
      (require 'exwm-randr)
      (setq exwm-randr-workspace-monitor-plist nil)
      (setq exwm-randr-workspace-monitor-plist monitor_list)
      (print (format "Monitor exit list: %s" exwm-randr-workspace-output-plist))
      (exwm-randr-enable)
      )
    )
  )
(aic/distribute_windows)

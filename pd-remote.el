;;; pd-remote.el --- Pd remote control stuff.

;;; Commentary:

;;; You can add this to your .emacs for remote control of Pd patches in
;;; conjunction with the accompanying pd-remote.pd abstraction. In particular,
;;; there's support for reloading pd_lua scripts and compiling Faust programs
;;; with faustgen2~.

;;; Install this anywhere where Emacs finds it (e.g., in the Emacs site-lisp
;;; directory -- usually under /usr/share/emacs/site-lisp on Un*x systems, or
;;; in any directory on the Emacs load-path) and load it in your .emacs as
;;; follows:

;;; (require 'pd-remote)

;;; Code:

(defun pd-send-start-process ()
  "Start a pdsend process to communicate with Pd via UDP port 4711."
  (interactive)
  (start-process "pdsend" nil "pdsend" "4711" "localhost" "udp")
  (set-process-query-on-exit-flag (get-process "pdsend") nil))

(defun pd-send-stop-process ()
  "Stops a previously started pdsend process."
  (interactive)
  (delete-process "pdsend"))

(defun pd-send-message (message)
  "Send the given MESSAGE to Pd.  Start the pdsend process if needed."
  (interactive "sMessage: ")
  (unless (get-process "pdsend") (pd-send-start-process))
  (process-send-string "pdsend" (concat message "\n")))

;; Faust mode; this requires Juan Romero's Faust mode available at
;; https://github.com/rukano/emacs-faust-mode. NOTE: If you don't have this,
;; or you don't need it, just comment the following two lines.
(setq auto-mode-alist (cons '("\\.dsp$" . faust-mode) auto-mode-alist))
(autoload 'faust-mode "faust-mode" "FAUST editing mode." t)

;; Juan's Faust mode doesn't have a local keymap, add one.
(defvar faust-mode-map nil)
(cond
 ((not faust-mode-map)
  (setq faust-mode-map (make-sparse-keymap))
  ;; Some convenient keybindings for Faust mode.
  (define-key faust-mode-map "\C-c\C-m" 'pd-send-message)
  (define-key faust-mode-map "\C-c\C-k" '(lambda () "Compile" (interactive)
					   (pd-send-message "faustgen2~ compile")))
  (define-key faust-mode-map "\C-c\C-s" '(lambda () "Start" (interactive)
					   (pd-send-message "play 1")))
  (define-key faust-mode-map "\C-c\C-t" '(lambda () "Stop" (interactive)
					   (pd-send-message "play 0")))
  (define-key faust-mode-map "\C-c\C-g" '(lambda () "Restart" (interactive)
					   (pd-send-message "play 0")
					   (pd-send-message "play 1")))
  (define-key faust-mode-map [(control ?\/)] '(lambda () "Dsp On" (interactive)
						(pd-send-message "pd dsp 1")))
  (define-key faust-mode-map [(control ?\.)] '(lambda () "Dsp Off" (interactive)
						(pd-send-message "pd dsp 0")))
  ))
(add-hook 'faust-mode-hook '(lambda () (use-local-map faust-mode-map)))

;; Lua mode: This requires lua-mode from MELPA.
(require 'lua-mode)
;; Pd Lua uses this as the extension for Lua scripts
(setq auto-mode-alist (cons '("\\.pd_luax?$" . lua-mode) auto-mode-alist))
;; add some convenient key bindings
(define-key lua-mode-map "\C-c\C-c" 'lua-send-current-line)
(define-key lua-mode-map "\C-c\C-d" 'lua-send-defun)
(define-key lua-mode-map "\C-c\C-r" 'lua-send-region)
; Pd tie-in (see pd-lua tutorial)
(define-key lua-mode-map "\C-c\C-k" '(lambda () "Reload" (interactive)
				       (pd-send-message "pdluax reload")))

(provide 'pd-remote)
;;; pd-remote.el ends here
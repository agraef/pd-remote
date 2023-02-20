;;; pd-remote.el --- Pd remote control helper

;; Copyright (c) 2023 Albert Graef

;; Author: Albert Graef <aggraef@gmail.com>
;; Keywords: multimedia, pure-data
;; Version: 1.0.1
;; URL: https://github.com/agraef/pd-remote
;; License: MIT

;;; Commentary:

;; You can add this to your .emacs for remote control of Pd patches in
;; conjunction with the accompanying pd-remote.pd abstraction.  In particular,
;; there's support for reloading pd_lua scripts and compiling Faust programs
;; with faustgen2~.

;; Install this anywhere where Emacs finds it (e.g., in the Emacs site-lisp
;; directory -- usually under /usr/share/emacs/site-lisp on Un*x systems, or
;; in any directory on the Emacs load-path) and load it in your .emacs as
;; follows:

;; (require 'pd-remote)

;;; Code:

(defun pd-remote-start-process ()
  "Start a pdsend process to communicate with Pd via UDP port 4711."
  (interactive)
  (start-process "pdsend" nil "pdsend" "4711" "localhost" "udp")
  (set-process-query-on-exit-flag (get-process "pdsend") nil))

(defun pd-remote-stop-process ()
  "Stops a previously started pdsend process."
  (interactive)
  (delete-process "pdsend"))

(defun pd-remote-message (message)
  "Send the given MESSAGE to Pd.  Start the pdsend process if needed."
  (interactive "sMessage: ")
  (unless (get-process "pdsend") (pd-remote-start-process))
  (process-send-string "pdsend" (concat message "\n")))

;; some convenient helpers

(defun pd-remote-dsp-on ()
  "Start dsp processing."
  (interactive)
  (pd-remote-message "pd dsp 1"))

(defun pd-remote-dsp-off ()
  "Stop dsp processing."
  (interactive)
  (pd-remote-message "pd dsp 0"))

;; Faust mode; this requires Juan Romero's Faust mode available at
;; https://github.com/rukano/emacs-faust-mode. NOTE: If you don't have this,
;; or you don't need it, just comment the following two lines.
(setq auto-mode-alist (cons '("\\.dsp$" . faust-mode) auto-mode-alist))
(autoload 'faust-mode "faust-mode" "FAUST editing mode." t)

;; various convenient keybindings, factored out so that they can be used
;; in different keymaps
(defun pd-remote-keys (mode-map)
  "Add common Pd keybindings to MODE-MAP."
  (define-key mode-map "\C-c\C-m" #'pd-remote-message)
  (define-key mode-map "\C-c\C-s" #'(lambda () "Start" (interactive)
				      (pd-remote-message "play 1")))
  (define-key mode-map "\C-c\C-t" #'(lambda () "Stop" (interactive)
				      (pd-remote-message "play 0")))
  (define-key mode-map "\C-c\C-r" #'(lambda () "Restart" (interactive)
				      (pd-remote-message "play 0")
				      (pd-remote-message "play 1")))
  (define-key mode-map [(control ?\/)] #'pd-remote-dsp-on)
  (define-key mode-map [(control ?\.)] #'pd-remote-dsp-off))

;; Juan's Faust mode doesn't have a local keymap, add one.
(defvar faust-mode-map nil)
(cond
 ((not faust-mode-map)
  (setq faust-mode-map (make-sparse-keymap))
  ;; Some convenient keybindings for Faust mode.
  (define-key faust-mode-map "\C-c\C-k" #'(lambda () "Compile" (interactive)
					    (pd-remote-message "faustgen2~ compile")))
  (pd-remote-keys faust-mode-map)))
(add-hook 'faust-mode-hook #'(lambda () (use-local-map faust-mode-map)))

;; Lua mode: This requires lua-mode from MELPA.
(require 'lua-mode)
;; Pd Lua uses this as the extension for Lua scripts
(setq auto-mode-alist (cons '("\\.pd_luax?$" . lua-mode) auto-mode-alist))
;; add some convenient key bindings
(define-key lua-mode-map "\C-c\C-c" #'lua-send-current-line)
(define-key lua-mode-map "\C-c\C-d" #'lua-send-defun)
(define-key lua-mode-map "\C-c\C-r" #'lua-send-region)
; Pd tie-in (see pd-lua tutorial)
(pd-remote-keys lua-mode-map)
(define-key lua-mode-map "\C-c\C-k" #'(lambda () "Reload" (interactive)
					(pd-remote-message "pdluax reload")))

;; add any convenient global keybindings here
;(global-set-key [(control ?\/)] #'pd-remote-dsp-on)
;(global-set-key [(control ?\.)] #'pd-remote-dsp-off)

(provide 'pd-remote)

;; End:
;;; pd-remote.el ends here

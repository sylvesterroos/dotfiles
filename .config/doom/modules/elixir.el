;;; elixir.el -*- lexical-binding: t; -*-

(setq lsp-elixir-suggest-specs nil)

;; set ruler used by mix format
(add-hook 'elixir-mode-hook
          (lambda ()
            (display-fill-column-indicator-mode)
            (setq display-fill-column-indicator-column 98)))

;; fix lsp version downloaded by emacs-elixir-mode
(use-package! lsp-elixir
  :init
  ;; Must be set before lsp-elixir.el loads
  (setf lsp-elixir-ls-version "v0.19.0")
  ;; this can be removed when lsp-mode 8.0.1 or greater is released
  (setf lsp-elixir-ls-download-url
        (format
         "https://github.com/elixir-lsp/elixir-ls/releases/download/%1$s/elixir-ls-%1$s.zip"
         lsp-elixir-ls-version)))

;; (after! lsp-mode
;;   (lsp-register-client (make-lsp-client :new-connection (lsp-stdio-connection '("/home/sylvester/.bin/next-ls" "--stdio"))
;;                                         :multi-root t
;;                                         :activation-fn (lsp-activate-on "elixir")
;;                                         :priority -100
;;                                         :server-id 'next-ls))

;;   (lsp-register-client (make-lsp-client :new-connection (lsp-stdio-connection "/home/sylvester/GitProjects/lexical/_build/dev/package/lexical/bin/start_lexical.sh")
;;                                         :activation-fn (lsp-activate-on "elixir")
;;                                         :priority -100
;;                                         :server-id 'lexical))
;;   )

;; fix apheleia project dir https://github.com/radian-software/apheleia/issues/30#issuecomment-778150037
(defun shou/fix-apheleia-project-dir (orig-fn &rest args)
  (let ((project (project-current)))
    (if (not (null project))
        (let ((default-directory (project-root project))) (apply orig-fn args))
      (apply orig-fn args))))

(advice-add 'apheleia-format-buffer :around #'shou/fix-apheleia-project-dir)

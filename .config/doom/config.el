;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
                                        ;(setq doom-theme 'doom-one)
(setq doom-theme 'doom-gruvbox)


;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)


;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/Documents/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; my config ;;

;; Fish (and possibly other non-POSIX shells) is known to inject garbage
;; output into some of the child processes that Emacs spawns. Many Emacs
;; packages/utilities will choke on this output, causing unpredictable
;; issues.
(setq shell-file-name (executable-find "bash"))
(setq-default vterm-shell (executable-find "fish"))

;; load modules
(let ((doomdir "~/.config/doom/"))
  (dolist (file (directory-files (concat doomdir "modules/") t "\\.el$"))
    (load-file file)))

(setq doom-font (font-spec :family "JetBrainsMono Nerd Font Mono" :size 11.0)
      doom-variable-pitch-font (font-spec :family "Cantarell" :size 15.0)
      doom-big-font (font-spec :family "JetBrainsMono Nerd Font Mono" :size 23.0))
(after! doom-themes
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t))
(custom-set-faces!
  '(font-lock-comment-face :slant italic)
  '(font-lock-keyword-face :slant italic))

(after! treemacs
  (setq treemacs-position 'right)
  (treemacs-follow-mode)
  )

(after! evil-escape
  (setq evil-escape-key-sequence "jj")
  (setq evil-escape-delay 0.5))

(after! evil
  ;; make `s` work again
  (remove-hook 'doom-first-input-hook #'evil-snipe-mode)

  ;; don't continue commented lines
  (setq +evil-want-o/O-to-continue-comments nil)
  )
;;
;; underscore is a word character
(modify-syntax-entry ?_ "w")

;; (if (provided-mode-derived-p major-mode 'text-mode 'prog-mode)
;;     (lambda ()
;;       (add-hook! 'evil-insert-state-exit-hook display-line-numbers 'relative)
;;       (add-hook! 'evil-insert-state-entry-hook display-line-numbers t)))
;; (setq-hook! 'evil-insert-state-exit-hook display-line-numbers 'relative)
;; (setq-hook! 'evil-insert-state-entry-hook display-line-numbers t)

;; (global-set-key (kbd "<mouse-6>") 'scroll-right)
;; (global-set-key (kbd "<mouse-7>") 'scroll-left)

(unless (equal "Power N/A, battery unknown (N/A% load, remaining time N/A)"
               (battery))
  (display-battery-mode 1)) ; On laptops it's nice to know how much power you have left

(after! centaur-tabs
  (setq centaur-tabs-show-navigation-buttons t)
  )

(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)

;; make window divider usable
(window-divider-mode)
(setq window-divider-default-right-width 4
      window-divider-default-bottom-width 4)

;; lsp
(after! lsp-ui
  (setq lsp-ui-doc-enable t)
  (setq lsp-ui-doc-show-with-mouse t)
  (setq lsp-ui-doc-show-with-cursor nil)
  (setq lsp-ui-doc-max-height 20)
  )


;; improve mouse scrolling
(setq mouse-wheel-progressive-speed nil)
(setq mouse-wheel-scroll-amount '(3 ((shift) . hscroll)))
(setq scroll-margin 5)

(after! coverlay
  (setq coverlay:tested-line-background-color "#171732")
  (setq coverlay:untested-line-background-color "#8c0b0b")
  )

;; blimpy
(after! (:and blimpy evil)
  (add-hook 'blimpy-before-typing-the-word-blimpy-in-emacs-hook
            (apply-partially #'evil-insert 1)))

(map! :leader
      :desc "Type the word blimpy in Emacs"
      "i b" #'blimpy-type-the-word-blimpy-in-emacs)

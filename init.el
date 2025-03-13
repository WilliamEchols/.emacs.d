;;; init.el --- Emacs config -*- lexical-binding: t -*-

;;; Commentary:

;; Setup: M-x nerd-icons-install-fonts

;; TODO: snippets

;;; Code:

;; Performance tweaks
(setq gc-cons-threshold 100000000)
(setq read-process-output-max (* 1024 1024))

;; Minimize GUI elements
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq inhibit-startup-screen t)
(setq ring-bell-function 'ignore)
(setq visible-bell nil)

(defvar my-org-roam-dir "~/Desktop/orgfiles" "Directory for Org-roam notes.")
(defvar my-org-agenda-dir "~/Desktop/orgfiles/agenda" "Directory for Org agenda files.")
(setq my-snippets-dir '("~/.emacs.d/snippets/"))
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))
(setq banner-filepath "~/.emacs.d/banner.txt")


;; Package setup
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))
(package-initialize)
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-when-compile (require 'use-package))
(setq use-package-always-ensure t)
(setq use-package-compute-statistics t)

;; Evil mode
(use-package evil
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  :config
  (evil-mode 1)
  ;; Function to discourage arrow keys
  (defun my/no-arrow-keys-message ()
    (interactive)
    (message "Use h,j,k,l instead!"))
  ;; Rebind arrow keys in normal mode
  (define-key evil-normal-state-map (kbd "<up>") 'my/no-arrow-keys-message)
  (define-key evil-normal-state-map (kbd "<down>") 'my/no-arrow-keys-message)
  (define-key evil-normal-state-map (kbd "<left>") 'my/no-arrow-keys-message)
  (define-key evil-normal-state-map (kbd "<right>") 'my/no-arrow-keys-message))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

;; Which-key for keybinding hints
(use-package which-key
  :init
  (which-key-mode)
  :config
  (setq which-key-idle-delay 0.5))

;; Vertico: Vertical completion UI
(use-package vertico
  :init
  (vertico-mode)
  :config
  (setq vertico-cycle t))

;; Consult: Enhanced search and navigation commands
(use-package consult
  :demand t ; Force load consult immediately
  :bind
  (("C-x b" . consult-buffer)      ; Switch buffers
   ("C-x 4 b" . consult-buffer-other-window)
   ("C-s" . consult-line))         ; Search within buffer
  :config
  (setq consult-project-root-function #'projectile-project-root))

;; Orderless: Flexible, space-separated filtering
(use-package orderless
  :init
  (setq completion-styles '(orderless basic))
  (setq completion-category-defaults nil)
  (setq completion-category-overrides '((file (styles basic partial-completion)))))

(defun my/org-export-to-pdf-and-open ()
  "Export current Org buffer to a PDF and open it with Zathura or Preview."
  (interactive)
  (let ((output-file (org-latex-export-to-pdf)))
    (when output-file
      (cond
       ;; macOS
       ((eq system-type 'darwin)
        (start-process "open-pdf" "*Open PDF*" "open" "-a" "Preview" output-file))
       
       ;; GNU/Linux
       ((eq system-type 'gnu/linux)
        (start-process "zathura" "*Zathura*" "zathura" output-file))
       
       ;; Fallback
       (t
        (message "No PDF viewer configured for this system."))))))

;; Custom functions
(defun my/split-and-follow-horizontally ()
  "Split window horizontally (right)."
  (interactive)
  (split-window-right)
  (other-window 1))

(defun my/split-and-follow-vertically ()
  "Split window horizontally (right)."
  (interactive)
  (split-window-below)
  (other-window 1))

;; Custom keybindings
(use-package general
  :after evil
  :config
  (general-define-key
   :states 'normal
   :prefix "SPC"

   ;; system
   "ff" 'find-file
   "d" 'image-dired
   "tf" 'toggle-frame-fullscreen
   "fo" 'org-open-at-point
   "o" 'org-todo
   "k" 'kill-buffer
   "TAB" 'org-cycle
   "wr" 'my/split-and-follow-horizontally
   "wb" 'my/split-and-follow-vertically
   "wo" 'other-window

   ;; LaTeX
   "lo" 'my/org-export-to-pdf-and-open

   ;; org-agenda
   "a" 'org-agenda

   ;; org-roam
   "nf" 'org-roam-node-find
   "nr" 'org-roam-node-random
   "nd" 'org-roam-dailies-goto-date
   "ni" 'org-roam-node-insert

   ;; consult
   "x" 'consult-M-x
   "b" 'consult-buffer
   "s" 'consult-line))

;; General appearance
(set-frame-font "Andale Mono-14" nil t)

(use-package color-theme-sanityinc-tomorrow
  :config
  (load-theme 'sanityinc-tomorrow-night t))

(global-display-line-numbers-mode 1)
(setq display-line-numbers-type 'absolute)
(setq image-use-external-converter t)

;; Status line with doom-modeline
(use-package doom-modeline
  :init
  (doom-modeline-mode 1)
  :config
  (setq doom-modeline-height 25)
  (setq doom-modeline-icon t) ; Enable icons
  (setq doom-modeline-major-mode-icon t)) ; Show mode-specific icons

;; Dashboard
(use-package dashboard
  :config
  (dashboard-setup-startup-hook)
  (setq dashboard-startup-banner banner-filepath)
  (setq dashboard-banner-logo-title (concat "GNU Emacs v. " emacs-version))
  (setq dashboard-footer-messages '(""))
  (setq dashboard-items nil)
  (setq initial-buffer-choice
        (lambda ()
          (dashboard-refresh-buffer)
          (get-buffer "*dashboard*"))))

;; Org-mode enhancements
(use-package org
  :defer t
  :config
  (setq org-startup-indented t)
  (setq org-agenda-files (list my-org-agenda-dir)))
(add-hook 'org-mode-hook #'visual-line-mode)

(use-package org-bullets
  :after org
  :hook (org-mode . org-bullets-mode))

(use-package yasnippet
  :hook (org-mode . yas-minor-mode)
  :config
  (setq yas-snippet-dirs my-snippets-dir)
  (yas-reload-all))

;; Org-agenda
(setq org-agenda-timegrid-use-ampm t)
(setq org-agenda-prefer-last-repeat t)
(use-package org-super-agenda
  :config
  (setq org-agenda-custom-commands
        '(("n" "Next View"
             ((agenda "" ((org-agenda-span 'day)
                          (org-super-agenda-groups
                           '((:name "Schedule"
                                    :time-grid t
                                    :todo "TODAY"
                                    :scheduled today
                                    ;:face 'de-default
                                    :order 0)
                             (:habit t)
                             (:name "Due Today"
                                    :deadline today
                                    ;:face 'de-default
                                    :order 2)
                             (:name "Due Soon"
                                    :deadline future
                                    ;:face 'de-default
                                    :order 8)
                             (:name "Overdue"
                                    :deadline past
                                    ;:face 'de-critical
                                    :order 7)
                             (:discard (:anything t))
                             ))))
              (todo "" ((org-agenda-overriding-header "")
                        (org-super-agenda-groups
                         '((:name "Inbox"
                                  :order 0
                                  )
                           (:discard (:todo "TODO"))
                           (:auto-category t
                                           :order 9)
                           ))))))
            ))
  (org-super-agenda-mode))

(use-package org-roam
  :after org
  :init
  (setq org-roam-v2-ack t)
  :config
  (setq org-roam-directory my-org-roam-dir)
  (setq org-roam-dailies-directory "daily/")
  (org-roam-setup))

;; Autocompletion with company
(use-package company
  :hook (prog-mode . company-mode)
  :config
  (setq company-idle-delay 0.1)
  (setq company-minimum-prefix-length 2))

;; Syntax checking with flycheck
(use-package flycheck
  :hook (prog-mode . flycheck-mode))

;; LSP with eglot
(use-package eglot
  :hook ((c++-mode python-mode) . eglot-ensure)
  :config
  (add-to-list 'eglot-server-programs
               '((c++-mode) . ("clangd"))
               '((python-mode) . ("pyright"))))

;; Programming languages
(use-package cc-mode :defer t)
(use-package python-mode :defer t)

;; Magit for Git
(use-package magit
  :defer t
  :bind ("C-x g" . magit-status))

;; Treemacs with custom binding
(use-package treemacs
  :defer t
  :bind (:map evil-normal-state-map
              ("\\" . treemacs))
  :config
  (treemacs-follow-mode t))

(use-package treemacs-evil
  :after (treemacs evil))

;; LaTeX
(use-package org-fragtog
  :hook (org-mode . org-fragtog-mode))

;; Custom keybindings
(use-package general
  :after evil
  :config
  (general-define-key
   :states 'normal
   :prefix "SPC"
   "a" 'org-agenda
   "r" 'org-roam-node-find))

;; Restore reasonable GC threshold after init
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold 800000)))

;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(org-fragtog treemacs-evil treemacs magit python-mode flycheck company org-roam org-super-agenda org-bullets dashboard doom-modeline color-theme-sanityinc-tomorrow general orderless consult vertico which-key evil-collection evil)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

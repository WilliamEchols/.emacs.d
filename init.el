;; δ Emacs                                            -*- lexical-binding: t -*-

;; Modern, fully-featured emacs, with minimal dependencies

(setq config-name "GNU Emacs")
(setq local-directory "~/Desktop/orgfiles")
(setq banner-filepath "~/.emacs.d/banner.txt")

;; --- Speed benchmarking -----------------------------------------------------
(setq init-start-time (current-time))

;; --- garbage collection and compilation ---
(setq gc-cons-threshold (* 50 1000 1000))
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 2 1000 1000))))

;; Enable native compilation if available (Emacs 28+)
(when (and (fboundp 'native-comp-available-p)
           (native-comp-available-p))
  (setq comp-deferred-compilation t)
  (message "Native compilation enabled."))

;; --- Package management

(require 'package)
;; Add package archives
(add-to-list 'package-archives '("gnu"   . "https://elpa.gnu.org/packages/") t)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

;; Initialize the package system
(package-initialize)

;; Refresh package contents if not already available
(unless package-archive-contents
  (package-refresh-contents))

;; Bootstrap use-package if it's not installed
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

;; Ensure use-package is loaded
(eval-when-compile (require 'use-package))
(setq use-package-always-ensure t)

;; --- Typography stack -------------------------------------------------------
(set-face-attribute 'default nil
                    :height 170 :weight 'light :family "Andale Mono")
(set-face-attribute 'bold nil :weight 'regular)
(set-face-attribute 'bold-italic nil :weight 'regular)
(set-display-table-slot standard-display-table 'truncation (make-glyph-code ?…))
(set-display-table-slot standard-display-table 'wrap (make-glyph-code ?–))

;; --- Frame / windows layout & behavior --------------------------------------
(setq default-frame-alist
      '((height . 44) (width  . 81) (left-fringe . 0) (right-fringe . 0)
        (internal-border-width . 32) (vertical-scroll-bars . nil)
        (bottom-divider-width . 0) (right-divider-width . 0)
        (undecorated-round . t)))
(modify-frame-parameters nil default-frame-alist)
(setq-default pop-up-windows nil)

;; --- Activate / Deactivate modes --------------------------------------------
(tool-bar-mode -1) (menu-bar-mode -1) (blink-cursor-mode -1)
(global-hl-line-mode 1) (icomplete-vertical-mode 1)
(pixel-scroll-precision-mode 1)
(setq isearch-lazy-count t) ; no effect
(setq isearch-lazy-highlight t) ; no effect


;; --- Evil mode ---

(use-package evil
  :config
  (evil-mode 1))

;; --- Minimal theme ----------------------------------------
(defface de-default '((t)) "")   (defface de-default-i '((t)) "")
(defface de-highlight '((t)) "") (defface de-highlight-i '((t)) "")
(defface de-subtle '((t)) "")    (defface de-subtle-i '((t)) "")
(defface de-faded '((t)) "")     (defface de-faded-i '((t)) "")
(defface de-salient '((t)) "")   (defface de-salient-i '((t)) "")
(defface de-popout '((t)) "")    (defface de-popout-i '((t)) "")
(defface de-strong '((t)) "")    (defface de-strong-i '((t)) "")
(defface de-critical '((t)) "")  (defface de-critical-i '((t)) "")

(defun de-set-face (name &optional foreground background weight)
  "Set NAME and NAME-i faces with given FOREGROUND, BACKGROUND and WEIGHT"

  (apply #'set-face-attribute `(,name nil
                                ,@(when foreground `(:foreground ,foreground))
                                ,@(when background `(:background ,background))
                                ,@(when weight `(:weight ,weight))))
  (apply #'set-face-attribute `(,(intern (concat (symbol-name name) "-i")) nil
                                :foreground ,(face-background 'de-default)
                                ,@(when foreground `(:background ,foreground))
                                :weight regular)))

(defun de-link-face (sources faces &optional attributes)
  "Make FACES to inherit from SOURCES faces and unspecify ATTRIBUTES."

  (let ((attributes (or attributes
                        '( :foreground :background :family :weight
                           :height :slant :overline :underline :box))))
    (dolist (face (seq-filter #'facep faces))
      (dolist (attribute attributes)
        (set-face-attribute face nil attribute 'unspecified))
      (set-face-attribute face nil :inherit sources))))

(defun de-install-theme ()
  "Install theme"

  (set-face-attribute 'default nil
                      :foreground (face-foreground 'de-default)
                      :background (face-background 'de-default))
  (dolist (item '((de-default .  (variable-pitch variable-pitch-text
                                    fixed-pitch fixed-pitch-serif))
                  (de-highlight . (hl-line highlight))
                  (de-subtle .    (match region
                                     lazy-highlight widget-field))
                  (de-faded .     (shadow
                                     font-lock-comment-face
                                     font-lock-doc-face
                                     icomplete-section
                                     completions-annotations))
                  (de-popout .    (warning
                                     font-lock-string-face))
                  (de-salient .   (success link
                                     help-argument-name
                                     custom-visibility
                                     font-lock-type-face
                                     font-lock-keyword-face
                                     font-lock-builtin-face
                                     completions-common-part))
                  (de-strong .    (font-lock-function-name-face
                                     font-lock-variable-name-face
                                     icomplete-first-match
                                     minibuffer-prompt))
                  (de-critical .  (error
                                     completions-first-difference))
                  (de-faded-i .   (help-key-binding))
                  (de-default-i . (custom-button-mouse
                                     isearch))
                  (de-critical-i . (isearch-fail))
                  ((de-subtle de-strong) . (custom-button
                                                icomplete-selected-match))
                  ((de-faded-i de-strong) . (show-paren-match))))
    (de-link-face (car item) (cdr item)))

  ;; Mode & header lines 
  (set-face-attribute 'header-line nil
                      :background 'unspecified
                      :underline nil
                      :box `( :line-width 1
                              :color ,(face-background 'de-default))
                      :inherit 'de-subtle)
  (set-face-attribute 'mode-line nil
                      :background (face-background 'default)
                      :underline (face-foreground 'de-faded)
                      :height 40 :overline nil :box nil)
  (set-face-attribute 'mode-line-inactive nil
                      :background (face-background 'default)
                      :underline (face-foreground 'de-faded)
                      :height 40 :overline nil :box nil))

(defun de/org-custom-faces ()
  "Apply custom theme colors to Org-mode faces.
This function sets custom colors for headlines as well as other Org elements like the document title, property drawers, and document info lines."
  (set-face-attribute 'org-level-1 nil :foreground (face-foreground 'de-strong))
  (set-face-attribute 'org-level-2 nil :foreground (face-foreground 'de-salient))
  (set-face-attribute 'org-level-3 nil :foreground (face-foreground 'de-popout))
  (set-face-attribute 'org-document-title nil :foreground (face-foreground 'de-salient))
  (set-face-attribute 'org-document-info nil :foreground (face-foreground 'de-popout))
  (set-face-attribute 'org-document-info-keyword nil :foreground (face-foreground 'de-strong))
  (set-face-attribute 'org-drawer nil :foreground (face-foreground 'de-strong) :weight 'bold)
  (set-face-attribute 'org-property-value nil :foreground (face-foreground 'de-strong))
  (set-face-attribute 'org-meta-line nil :foreground (face-foreground 'de-strong))
  )
(add-hook 'org-mode-hook 'de/org-custom-faces)

(defun de-dark (&rest args)
  "Dark mode."
  (interactive)
  (de-set-face 'de-default "#ebdbb2" "#282828")
  (de-set-face 'de-strong "#fbf1c7" nil 'regular)
  (de-set-face 'de-highlight nil "#3c3836")
  (de-set-face 'de-subtle nil "#504945")
  (de-set-face 'de-faded "#a89984")
  (de-set-face 'de-salient "#fb4934")
  (de-set-face 'de-popout "#fabd2f")
  (de-set-face 'de-critical "#fabd2f")
  (de-install-theme))

(defun de-light (&rest args)
  "Light mode."
  (interactive)
  (de-set-face 'de-default "#3c3836" "#fbf1c7")
  (de-set-face 'de-strong "#282828" nil 'regular)
  (de-set-face 'de-highlight nil "#ebdbb2")
  (de-set-face 'de-subtle nil "#d5c4a1")
  (de-set-face 'de-faded "#7c6f64")
  (de-set-face 'de-salient "#9d0006")
  (de-set-face 'de-popout "#b57614")
  (de-set-face 'de-critical "#b57614")
  (de-install-theme))

(de-dark)

;; --- Minibuffer completion --------------------------------------------------
(setq tab-always-indent 'complete
      icomplete-delay-completions-threshold 0
      icomplete-compute-delay 0
      icomplete-show-matches-on-no-input t
      icomplete-hide-common-prefix nil
      icomplete-prospects-height 9
      icomplete-separator " . "
      icomplete-with-completion-tables t
      icomplete-in-buffer t
      icomplete-max-delay-chars 0
      icomplete-scroll t
      resize-mini-windows 'grow-only
      icomplete-matches-format nil)
(bind-key "TAB" #'icomplete-force-complete icomplete-minibuffer-map)
(bind-key "RET" #'icomplete-force-complete-and-exit icomplete-minibuffer-map)

;; --- Misc -------------------------------------------------------------------

;; --- tree-sitter ---

(when (and (boundp 'treesit-language-source-alist)
           (fboundp 'treesit-install-language-grammar)))

;; --- spell checking ---

(use-package flyspell
  :ensure nil
  :hook ((markdown-mode . flyspell-mode)
         (org-mode      . flyspell-mode)))

;; --- latex ---

(require 'ox-latex)
(plist-put org-format-latex-options :scale 1.4)

(use-package org-fragtog
  :hook (org-mode . org-fragtog-mode))

;; --- dashboard ---

(use-package dashboard
  :config
  (dashboard-setup-startup-hook)
  (setq dashboard-startup-banner banner-filepath
        dashboard-banner-logo-title (concat config-name " (" emacs-version ")")
        dashboard-init-info ""
        dashboard-items nil
        dashboard-set-footer t
        dashboard-footer-icon ""
        dashboard-footer-messages '(""))
  (dashboard-refresh-buffer))

(setq initial-buffer-choice
      (lambda ()
        (require 'dashboard)
        (unless (get-buffer "*dashboard*")
          (dashboard-refresh-buffer))
        (get-buffer "*dashboard*")))

;; --- org ---

(require 'org)
;(require 'org-tempo)
(setq org-todo-keywords '((sequence "TODO" "DONE")))
(add-hook 'org-mode-hook #'visual-line-mode)

(setq org-hide-leading-stars t
      org-startup-indented t
      org-log-done 'time)

(use-package org-modern
  :hook (org-mode . org-modern-mode)
  :config
  (setq org-modern-star 'replace)
  (setq org-modern-replace-stars "♠♣♥♦"))

;; org-agenda

(setq org-agenda-files (list (concat local-directory "/agenda")))
(setq org-agenda-timegrid-use-ampm t)

; change due to org-mode v9
(setq org-agenda-prefer-last-repeat t)

;; org-super-agenda

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
                                    :face 'de-default
                                    :order 0)
                             (:habit t)
                             (:name "Due Today"
                                    :deadline today
                                    :face 'de-default
                                    :order 2)
                             (:name "Due Soon"
                                    :deadline future
                                    :face 'de-default
                                    :order 8)
                             (:name "Overdue"
                                    :deadline past
                                    :face 'de-critical
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

(set-face-attribute 'org-agenda-date nil
                    :foreground (face-attribute 'de-popout :foreground)
                    :weight 'normal)
(set-face-attribute 'org-agenda-date-today nil
                    :foreground (face-attribute 'de-salient :foreground)
                    :weight 'bold)
(set-face-attribute 'org-agenda-structure nil
                    :foreground (face-attribute 'de-default :foreground)
                    :background (face-attribute 'de-default :background)
                    :weight 'bold)

;; --- Functions --------------------------------------------------------------

;; ERROR: apply: Removing old name: is a directory: /Users/user/Desktop/orgfiles/ltximg
(defun de/clear-latex-preview-cache ()
  "Clear all latex preview images in the current buffer."
  (interactive)
  (org-remove-latex-fragment-image-overlays)
  (let ((dir (file-name-directory (buffer-file-name))))
    (when dir
      (let ((files (directory-files dir t "^ltximg.*\\|^.*\\.dvi\\|^.*\\.pdf\\|^.*\\.ps\\|^.*\\.png$")))
        (dolist (file files)
          (when (file-exists-p file)
            (delete-file file)))))
  (message "Cleared latex preview cache")))

(defun de/bottom-terminal ()
  (interactive)
  (split-window-vertically (- (/ (window-total-height) 5)))
  (other-window 1)
  (ansi-term (getenv "SHELL"))
  (other-window 1))

(defun de/org-export-to-pdf-and-open ()
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

(defun de/split-and-follow-vertically ()
  "Split window vertically (below)."
  (interactive)
  (split-window-below)
  (other-window 1))

(defun de/split-and-follow-horizontally ()
  "Split window horizontally (right)."
  (interactive)
  (split-window-right)
  (other-window 1))

(defun de/arrange-windows ()
  "Re-arrange open windows."
  (interactive)
  (let ((current-window (selected-window)))
    (delete-other-windows)
    (split-window-horizontally)
    (other-window 1)
    (switch-to-buffer (other-buffer))
    (other-window -1)
    (select-window current-window)))

(defun de/evil-yank-to-clipboard (beg end &optional type register yank-handler)
  "After an Evil yank, also copy the yanked text to the system clipboard."
  (when (and (display-graphic-p) (fboundp 'gui-set-selection))
    (let ((text (buffer-substring-no-properties beg end)))
      (gui-set-selection 'CLIPBOARD text)
      (gui-set-selection 'PRIMARY text))))
(advice-add 'evil-yank :after #'de/evil-yank-to-clipboard)

;; --- org-roam ---

(use-package org-roam
  :defer t
  :custom
  (org-roam-directory local-directory)
  :config
  (org-roam-setup)
  (setq org-roam-dailies-directory "daily/")
  (org-roam-db-autosync-mode))

(setq org-roam-capture-templates
  '(
    ;; normal notes
    ("d" "default" plain "%?" :target
    (file+head "${slug}.org" "#+title: ${title}")
    :unnarrowed t)

    ;; agenda notes
    ("a" "agenda" plain "%?" :target
    (file+head "agenda/${slug}.org" "#+title: ${title}")
    :unnarrowed t)))

;; --- Keybindings ------------------------------------------------------------

(use-package which-key
  :config
  (which-key-mode)
  (setq which-key-idle-delay 0.3
        which-key-idle-secondary-delay 0.05))

(use-package general
  :defer t
  :config
  (general-define-key
    :states '(normal motion visual)
    :keymaps 'override
    :prefix "SPC"

    ;; emacs
    "q" '(save-buffers-kill-emacs :which-key "quit emacs")
    "f s" '(save-buffer :which-key "save buffer")
    "f o" '(org-open-at-point :which-key "open point")
    "f f" '(find-file :which-key "find file")

    ;; buffers
    "b" '(switch-to-buffer :which-key "switch buffer")
    "k" '(kill-buffer :which-key "kill buffer")
    "d" '(image-dired :which-key "image-dired")

    ;; cycle status
    "o" '(org-todo :which-key "cycle todo status")

    ;; encryption
    "p e" '(org-encrypt-entry :which-key "PGP encrypt")
    "p d" '(org-decrypt-entry :which-key "PGP decrypt")
    
    ;; latex
    "l p" '(org-latex-preview :which-key "latex preview")
    "l e" '(org-latex-export-to-pdf :which-key "latex export")
    "l o" '(de/org-export-to-pdf-and-open :which-key "latex open")
    "l c" '(de/clear-latex-preview-cache :which-key "clear latex cache")

    ;; agenda
    "a" '(org-agenda :which-key "agenda")

    ;; window
    "w a" '(de/arrange-windows :which-key "arrange horizontally")
    "w o" '(other-window :which-key "other window")
    "w r" '(de/split-and-follow-horizontally :which-key "split right")
    "w b" '(de/split-and-follow-vertically :which-key "split below")

    ;; toggles
    "t f" '(toggle-frame-fullscreen :which-key "toggle fullscreen")

    ;; roam
    "n f" '(org-roam-node-find :which-key "roam find")
    "n i" '(org-roam-node-insert :which-key "roam insert")
    "n r" '(org-roam-node-random :which-key "random node")
    "n d N" '(org-roam-dailies-capture-today :which-key "capture today")
    "n d Y" '(org-roam-dailies-capture-yesterday :which-key "capture yesterday")
    "n d T" '(org-roam-dailies-capture-tomorrow :which-key "capture tomorrow")
    "n d n" '(org-roam-dailies-goto-today :which-key "goto today")
    "n d y" '(org-roam-dailies-goto-yesterday :which-key "goto yesterday")
    "n d t" '(org-roam-dailies-goto-tomorrow :which-key "goto tomorrow")
    "n d d" '(org-roam-dailies-goto-date :which-key "goto date")
    ))

;; general for org tweaks

(general-define-key
  :states 'normal
  :keymaps 'org-mode-map
  "TAB" 'org-cycle)

(setq org-hide-block-startup t
      org-startup-folded "fold")

;; --- Sane settings ----------------------------------------------------------
(setq inhibit-startup-echo-area-message "williamechols")
(setq inhibit-startup-message t)
(setq split-width-threshold 1 ) ;; open new windows to the right
(set-default-coding-systems 'utf-8)
(setq-default indent-tabs-mode nil
              ring-bell-function 'ignore
              select-enable-clipboard t)

;; Store backup files in a central location
(setq backup-directory-alist
      `(("." . ,(concat user-emacs-directory "backups")))
      backup-by-copying t    ; Don't delink hardlinks
      version-control t      ; Use version numbers on backups
      delete-old-versions t  ; Automatically delete excess backups
      kept-new-versions 6    ; Number of newest versions to keep
      kept-old-versions 2)   ; Number of oldest versions to keep

;; Create backup directory if it doesn't exist
(make-directory (concat user-emacs-directory "backups") t)

;; --- image-dired --- 
; requires `imagemagick`

(setq image-use-external-converter t)
(evil-set-initial-state 'image-dired-thumbnail-mode 'emacs)
(general-define-key
   :states '(normal motion visual)
   :keymaps 'image-dired-image-mode-map
   "q" '(lambda () (interactive) (kill-this-buffer) (delete-other-windows)))
(general-define-key
   :states '(normal motion visual)
   :keymaps 'image-dired-mode-map
   "q" '(lambda () (interactive) (kill-this-buffer) (delete-other-windows)))
(general-define-key
   :states '(normal motion visual)
   :keymaps 'image-mode-map
   "q" '(lambda () (interactive) (kill-this-buffer) (delete-other-windows)))

;; --- macOS Specific ----------------------------------------------------------

(defun de/macos-modifier-keys ()
  (interactive)
  (when (eq system-type 'darwin)
    (select-frame-set-input-focus (selected-frame))
    (setq mac-option-modifier nil
          ns-function-modifier 'super
          mac-right-command-modifier 'hyper
          mac-right-option-modifier 'alt
          mac-command-modifier 'meta)))

;; --- Header & mode lines ----------------------------------------------------
(setq-default mode-line-format "")
(setq-default header-line-format
  '(:eval
    (let ((prefix (cond (buffer-read-only     '("RO" . de-default-i))
                        ((buffer-modified-p)  '("**" . de-critical-i))
                        (t                    '("RW" . de-faded-i))))
          (mode (concat "(" (downcase (cond ((consp mode-name) (car mode-name))
                                            ((stringp mode-name) mode-name)
                                            (t "unknow")))
                        " mode)"))
          (coords (format-mode-line "%c:%l ")))
      (list
       (propertize " " 'face (cdr prefix)  'display '(raise -0.25))
       (propertize (car prefix) 'face (cdr prefix))
       (propertize " " 'face (cdr prefix) 'display '(raise +0.25))
       (propertize (format-mode-line " %b ") 'face 'de-strong)
       (propertize mode 'face 'header-line)
       (propertize " " 'display `(space :align-to (- right ,(length coords))))
       (propertize coords 'face 'de-faded)))))

;; --- Minibuffer setup -------------------------------------------------------

(setq completion-styles '(substring basic))
(defun de-minibuffer--setup ()
  (set-window-margins nil 3 0)
  (let ((inhibit-read-only t))
    (add-text-properties (point-min) (+ (point-min) 1)
      `(display ((margin left-margin)
                 ,(format "δ %s" (substring (minibuffer-prompt) 0 1))))))
  (setq truncate-lines t))
(add-hook 'minibuffer-setup-hook #'de-minibuffer--setup)

;; --- Package development ---

;; lace

;; (condition-case err
;;     (progn
;;       (add-to-list 'load-path
;;                    (expand-file-name "lisp/lace" user-emacs-directory))
;;       (require 'lace)
;;       (lace-verify-load))
;;   (error
;;    (message "Failed to load LACE: %S" err)
;;    (with-current-buffer (get-buffer-create "*LACE Load Error*")
;;      (erase-buffer)
;;      (insert "LACE Loading Error\n")
;;      (insert "================\n\n")
;;      (insert (format "Error: %S\n\n" err))
;;      (insert "Load Path:\n")
;;      (insert (format "  %S\n\n" load-path))
;;      (insert "Backtrace:\n")
;;      (insert (with-output-to-string (backtrace)))
;;      (display-buffer (current-buffer)))))

;; ;; atp

;; (condition-case err
;;     (progn
;;       (add-to-list 'load-path
;;                    (expand-file-name "lisp/atp" user-emacs-directory))
;;       (require 'eatp))
;;   (error
;;    (message "Failed to load EATP: %S" err)
;;    (with-current-buffer (get-buffer-create "*EATP Load Error*")
;;      (erase-buffer)
;;      (insert "ATP Loading Error\n")
;;      (insert "================\n\n")
;;      (insert (format "Error: %S\n\n" err))
;;      (insert "Load Path:\n")
;;      (insert (format "  %S\n\n" load-path))
;;      (insert "Backtrace:\n")
;;      (insert (with-output-to-string (backtrace)))
;;      (display-buffer (current-buffer)))))

;; --- Speed benchmarking -----------------------------------------------------

(let ((init-time (float-time (time-subtract (current-time) init-start-time)))
      (total-time (string-to-number (emacs-init-time "%f"))))
  (message (concat
    (propertize "Startup time: " 'face 'bold)
    (format "%.2fs " init-time)
    (propertize (format "(+ %.2fs system time)"
                        (- total-time init-time)) 'face 'shadow))))


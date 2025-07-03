;; memacs (minimal emacs)

;; Config

(setq gc-cons-threshold (* 100 1024 1024))
(setq inhibit-startup-screen t)
(setq inhibit-startup-echo-area-message t)
(setq inhibit-startup-message t)
(setq initial-scratch-message nil)
(setq initial-major-mode 'org-mode)
(setq pop-up-windows nil)
(setq image-use-external-converter t)
(tool-bar-mode 0)
(tooltip-mode  0)
(scroll-bar-mode 0)
(menu-bar-mode 0)

(defun custom/kill-this-buffer ()
  (interactive) (kill-buffer (current-buffer)))
(global-set-key (kbd "C-x k") 'custom/kill-this-buffer)

(require 'uniquify)
(setq uniquify-buffer-name-style 'forward)

(save-place-mode 1)

(global-set-key (kbd "C-z") 'undo)
(global-set-key (kbd "C-x C-x") 'execute-extended-command)

;; Functions and Variables

(defvar my-org-roam-dir "~/Desktop/orgfiles" "Directory for Org-roam notes.")
(defvar my-org-agenda-dir "~/Desktop/orgfiles/agenda" "Directory for Org agenda files.")
(setq my-snippets-dir '("~/.emacs.d/snippets/"))
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))
(setq banner-filepath "~/.emacs.d/banner.txt")
(setq my-pgp-key "EC4C243CFE51BE23026AED8BB2FD48BFD99A47DB")

(defun my/org-export-to-pdf-and-open ()
  "Export current Org buffer to a PDF and open it with Document Viewer or Preview."
  (interactive)
  (let ((output-file (org-latex-export-to-pdf)))
    (when output-file
      (cond
       ;; macOS
       ((eq system-type 'darwin)
        (start-process "open-pdf" "*Open PDF*" "open" "-a" "Preview" output-file))
       
       ;; GNU/Linux
       ((eq system-type 'gnu/linux)
        (start-process "evince" "*Evince*" "evince" output-file))
       
       ;; Fallback
       (t
        (message "No PDF viewer configured for this system."))))))

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

;; Packages

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

;; Orderless: Flexible, space-separated filtering
(use-package orderless
  :init
  (setq completion-styles '(orderless basic))
  (setq completion-category-defaults nil)
  (setq completion-category-overrides '((file (styles basic partial-completion)))))

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

(require 'org-crypt)
(org-crypt-use-before-save-magic)
(setq org-tags-exclude-from-inheritance (quote ("crypt")))
(setq org-crypt-key my-pgp-key)

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

;; org-roam
(use-package org-roam
  :after org
  :init
  (setq org-roam-v2-ack t)
  :config
  (setq org-roam-directory my-org-roam-dir)
  (setq org-roam-dailies-directory "daily/")
  (org-roam-setup))

(use-package org-roam-ui
  :after org-roam
  :ensure t
  :config
  ;; Optional settings
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start nil))

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

   ;; system
   "ff" 'find-file
   "d" 'image-dired
   "tf" 'toggle-frame-fullscreen
   "fo" 'org-open-at-point
   "o" 'org-todo
   "b" 'switch-to-buffer
   "k" 'kill-buffer
   "TAB" 'org-cycle
   "wr" 'my/split-and-follow-horizontally
   "wb" 'my/split-and-follow-vertically
   "wo" 'other-window
   "p" 'org-decrypt-entry
   "r" 'rgrep

   ;; LaTeX
   "lo" 'my/org-export-to-pdf-and-open

   ;; org-agenda
   "a" 'org-agenda

   ;; org-roam
   "nf" 'org-roam-node-find
   "nr" 'org-roam-node-random
   "nd" 'org-roam-dailies-goto-date
   "ni" 'org-roam-node-insert))

;; UI

;; Font and frame size
;(set-face-font 'default "Roboto Mono 14")
;(setq default-frame-alist
;      (append (list '(width  . 72) '(height . 40)
;                    '(vertical-scroll-bars . nil)
;                    '(internal-border-width . 24)
;                    '(font . "Roboto Mono 14"))))
(set-frame-parameter (selected-frame)
                     'internal-border-width 24)

;; Line spacing, can be 0 for code and 1 or 2 for text
(setq-default line-spacing 0)

;; Underline line at descent position, not baseline position
(setq x-underline-at-descent-line t)

;; No ugly button for checkboxes
(setq widget-image-enable nil)

;; Line cursor and no blink
(set-default 'cursor-type  '(bar . 1))
(blink-cursor-mode 0)

;; No sound
(setq visible-bell t)
(setq ring-bell-function 'ignore)

;; No Tooltips
(tooltip-mode 0)

;; Paren mode is part of the theme
(show-paren-mode t)

;; No fringe but nice glyphs for truncated and wrapped lines
(fringe-mode '(0 . 0))
(defface fallback '((t :family "Fira Code Light"
                       :inherit 'face-faded)) "Fallback")
(set-display-table-slot standard-display-table 'truncation
                        (make-glyph-code ?… 'fallback))
(set-display-table-slot standard-display-table 'wrap
                        (make-glyph-code ?↩ 'fallback))
(set-display-table-slot standard-display-table 'selective-display
                        (string-to-vector " …"))


;; When we set a face, we take care of removing any previous settings
(defun set-face (face style)
  "Reset a face and make it inherit style."
  (set-face-attribute face nil
   :foreground 'unspecified :background 'unspecified
   :family     'unspecified :slant      'unspecified
   :weight     'unspecified :height     'unspecified
   :underline  'unspecified :overline   'unspecified
   :box        'unspecified :inherit    style))

;; A theme is fully defined by these six faces 
(defgroup elegance nil
  "Faces for the elegance theme"
  :prefix "face-")

;; Do not show prefix when displaying the elegance group
(setq custom-unlispify-remove-prefixes t)

(defface face-critical nil
"Critical face is for information that requires immediate action.
It should be of high constrast when compared to other faces. This
can be realized (for example) by setting an intense background
color, typically a shade of red. It must be used scarcely."
:group 'elegance)

(defface face-popout nil
"Popout face is used for information that needs attention.
To achieve such effect, the hue of the face has to be
sufficiently different from other faces such that it attracts
attention through the popout effect."
:group 'elegance)

(defface face-strong nil
"Strong face is used for information of a structural nature.
It has to be the same color as the default color and only the
weight differs by one level (e.g., light/regular or
regular/bold). IT is generally used for titles, keywords,
directory, etc."
:group 'elegance)

(defface face-salient nil
"Salient face is used for information that are important.
To suggest the information is of the same nature but important,
the face uses a different hue with approximately the same
intensity as the default face. This is typically used for links."

:group 'elegance)

(defface face-faded nil
"Faded face is for information that are less important.
It is made by using the same hue as the default but with a lesser
intensity than the default. It can be used for comments,
secondary information and also replace italic (which is generally
abused anyway)."
:group 'elegance)

(defface face-subtle nil
"Subtle face is used to suggest a physical area on the screen.
It is important to not disturb too strongly the reading of
information and this can be made by setting a very light
background color that is barely perceptible."
:group 'elegance)


;; Mode line (this might be slow because of the "☰" that requires substitution)
;; This line below makes things a bit faster
(set-fontset-font "fontset-default"  '(#x2600 . #x26ff) "Fira Code 16")

(define-key mode-line-major-mode-keymap [header-line]
  (lookup-key mode-line-major-mode-keymap [mode-line]))

(defun mode-line-render (left right)
  (let* ((available-width (- (window-width) (length left) )))
    (format (format "%%s %%%ds" available-width) left right)))
(setq-default mode-line-format
     '((:eval
       (mode-line-render
       (format-mode-line (list
         (propertize "☰" 'face `(:inherit mode-line-buffer-id)
                         'help-echo "Mode(s) menu"
                         'mouse-face 'mode-line-highlight
                         'local-map   mode-line-major-mode-keymap)
         " %b "
         (if (and buffer-file-name (buffer-modified-p))
             (propertize "(modified)" 'face `(:inherit face-faded)))))
       (format-mode-line
        (propertize "%4l:%2c  " 'face `(:inherit face-faded)))))))


;; Comment if you want to keep the modeline at the bottom
(setq-default header-line-format mode-line-format)
(setq-default mode-line-format'(""))

              
;; Vertical window divider
(setq window-divider-default-right-width 3)
(setq window-divider-default-places 'right-only)
(window-divider-mode)

;; Modeline
(defun set-modeline-faces ()

  ;; Mode line at top
  (set-face 'header-line                                 'face-strong)
  (set-face-attribute 'header-line nil
                                :underline (face-foreground 'default))
  (set-face-attribute 'mode-line nil
                      :height 10
                      :underline (face-foreground 'default)
                      :overline nil
                      :box nil 
                      :foreground (face-background 'default)
                      :background (face-background 'default))
  (set-face 'mode-line-inactive                            'mode-line)

  (set-face-attribute 'cursor nil
                      :background (face-foreground 'default))
  (set-face-attribute 'window-divider nil
                      :foreground (face-background 'mode-line))
  (set-face-attribute 'window-divider-first-pixel nil
                      :foreground (face-background 'default))
  (set-face-attribute 'window-divider-last-pixel nil
                      :foreground (face-background 'default))
  )

;; Buttons
(defun set-button-faces ()
  (set-face-attribute 'custom-button nil
                      :foreground (face-foreground 'face-faded)
                      :background (face-background 'face-subtle)
                      :box `(:line-width 1
                             :color ,(face-foreground 'face-faded)
                             :style nil))
  (set-face-attribute 'custom-button-mouse nil
                      :foreground (face-foreground 'default)
                      ;; :background (face-foreground 'face-faded)
                      :inherit 'custom-button
                      :box `(:line-width 1
                             :color ,(face-foreground 'face-subtle)
                             :style nil))
  (set-face-attribute 'custom-button-pressed nil
                      :foreground (face-background 'default)
                      :background (face-foreground 'face-salient)
                      :inherit 'face-salient
                      :box `(:line-width 1
                             :color ,(face-foreground 'face-salient)
                             :style nil)
                      :inverse-video nil))

;; Light theme 
(defun elegance-light ()
    (setq frame-background-mode 'light)
    (set-background-color "#ffffff")
    (set-foreground-color "#333333")
    (set-face-attribute 'default nil
                        :foreground (face-foreground 'default)
                        :background (face-background 'default))
    (set-face-attribute 'face-critical nil :foreground "#ffffff"
                                           :background "#ff6347")
    (set-face-attribute 'face-popout nil :foreground "#ffa07a")
    (set-face-attribute 'face-strong nil :foreground "#333333"
                                         :weight 'regular)
    (set-face-attribute 'face-salient nil :foreground "#00008b"
                                          :weight 'light)
    (set-face-attribute 'face-faded nil :foreground "#999999"
                                        :weight 'light)
    (set-face-attribute 'face-subtle nil :background "#f0f0f0")

    (set-modeline-faces)
    
    (with-eval-after-load 'cus-edit (set-button-faces)))

;; Dark theme
(defun elegance-dark ()
  (setq frame-background-mode 'dark)
  (set-background-color "#282c34")
  (set-foreground-color "#dcdfe4")
  (set-face-attribute 'default nil
                      :foreground "#dcdfe4"
                      :background "#282c34")
  (set-face-attribute 'face-critical nil :foreground "#e06c75"
                                         :background "#3e2e2e")
  (set-face-attribute 'face-popout nil :foreground "#e5c07b") ; string literal
  (set-face-attribute 'face-strong nil :foreground "#dcdfe4"
                                       :weight 'regular)
  (set-face-attribute 'face-salient nil :foreground "#c678dd" ; function name
                                        :weight 'normal)
  (set-face-attribute 'face-faded nil :foreground "#5c6370" ; comments
                                      :weight 'light)
  (set-face-attribute 'face-subtle nil :background "#3a3f4b")
  (set-modeline-faces) ;; Ensure these are defined
  (with-eval-after-load 'cus-edit (set-button-faces)))

;; Set theme
(elegance-dark)

;; Structural
(set-face 'bold                                          'face-strong)
(set-face 'italic                                         'face-faded)
(set-face 'bold-italic                                   'face-strong)
(set-face 'region                                        'face-subtle)
(set-face 'highlight                                     'face-subtle)
(set-face 'fixed-pitch                                       'default)
(set-face 'fixed-pitch-serif                                 'default)
(set-face 'variable-pitch                                    'default)
(set-face 'cursor                                            'default)

;; Semantic
(set-face 'shadow                                         'face-faded)
(set-face 'success                                      'face-salient)
(set-face 'warning                                       'face-popout)
(set-face 'error                                       'face-critical)

;; General
(set-face 'buffer-menu-buffer                            'face-strong)
(set-face 'minibuffer-prompt                             'face-strong)
(set-face 'link                                         'face-salient)
(set-face 'fringe                                         'face-faded)
(set-face 'isearch                                       'face-strong)
(set-face 'isearch-fail                                   'face-faded)
(set-face 'lazy-highlight                                'face-subtle)
(set-face 'trailing-whitespace                           'face-subtle)
(set-face 'show-paren-match                              'face-popout)
(set-face 'show-paren-mismatch                           'face-normal)
(set-face-attribute 'tooltip nil                         :height 0.85)

;; Programmation mode
(set-face 'font-lock-comment-face                         'face-faded)
(set-face 'font-lock-doc-face                             'face-faded)
(set-face 'font-lock-string-face                         'face-popout)
(set-face 'font-lock-constant-face                      'face-salient)
(set-face 'font-lock-warning-face                        'face-popout)
(set-face 'font-lock-function-name-face                  'face-strong)
(set-face 'font-lock-variable-name-face                  'face-strong)
(set-face 'font-lock-builtin-face                       'face-salient)
(set-face 'font-lock-type-face                          'face-salient)
(set-face 'font-lock-keyword-face                       'face-salient)

;; Documentation
(with-eval-after-load 'info
  (set-face 'info-menu-header                            'face-strong)
  (set-face 'info-header-node                            'face-normal)
  (set-face 'Info-quoted                                  'face-faded)
  (set-face 'info-title-1                                'face-strong)
  (set-face 'info-title-2                                'face-strong)
  (set-face 'info-title-3                                'face-strong)
  (set-face 'info-title-4                               'face-strong))

;; Bookmarks
(with-eval-after-load 'bookmark
  (set-face 'bookmark-menu-heading                       'face-strong)
  (set-face 'bookmark-menu-bookmark                    'face-salient))

;; Message
(with-eval-after-load 'message
  (set-face 'message-cited-text                           'face-faded)
  (set-face 'message-header-cc                               'default)
  (set-face 'message-header-name                         'face-strong)
  (set-face 'message-header-newsgroups                       'default)
  (set-face 'message-header-other                            'default)
  (set-face 'message-header-subject                     'face-salient)
  (set-face 'message-header-to                          'face-salient)
  (set-face 'message-header-xheader                          'default)
  (set-face 'message-mml                                 'face-popout)
  (set-face 'message-separator                           'face-faded))

;; Outline
(with-eval-after-load 'outline
  (set-face 'outline-1                                   'face-strong)
  (set-face 'outline-2                                   'face-strong)
  (set-face 'outline-3                                   'face-strong)
  (set-face 'outline-4                                   'face-strong)
  (set-face 'outline-5                                   'face-strong)
  (set-face 'outline-6                                   'face-strong)
  (set-face 'outline-7                                   'face-strong)
  (set-face 'outline-8                                  'face-strong))

;; Interface
(with-eval-after-load 'cus-edit
  (set-face 'widget-field                                'face-subtle)
  (set-face 'widget-button                               'face-strong)
  (set-face 'widget-single-line-field                    'face-subtle)
  (set-face 'custom-group-subtitle                       'face-strong)
  (set-face 'custom-group-tag                            'face-strong)
  (set-face 'custom-group-tag-1                          'face-strong)
  (set-face 'custom-comment                               'face-faded)
  (set-face 'custom-comment-tag                           'face-faded)
  (set-face 'custom-changed                             'face-salient)
  (set-face 'custom-modified                            'face-salient)
  (set-face 'custom-face-tag                             'face-strong)
  (set-face 'custom-variable-tag                             'default)
  (set-face 'custom-invalid                              'face-popout)
  (set-face 'custom-visibility                          'face-salient)
  (set-face 'custom-state                               'face-salient)
  (set-face 'custom-link                               'face-salient))

;; Package
(with-eval-after-load 'package
  (set-face 'package-description                             'default)
  (set-face 'package-help-section-name                       'default)
  (set-face 'package-name                               'face-salient)
  (set-face 'package-status-avail-obso                    'face-faded)
  (set-face 'package-status-available                        'default)
  (set-face 'package-status-built-in                    'face-salient)
  (set-face 'package-status-dependency                  'face-salient)
  (set-face 'package-status-disabled                      'face-faded)
  (set-face 'package-status-external                         'default)
  (set-face 'package-status-held                             'default)
  (set-face 'package-status-incompat                      'face-faded)
  (set-face 'package-status-installed                   'face-salient)
  (set-face 'package-status-new                              'default)
  (set-face 'package-status-unsigned                         'default)

  ;; Button face is hardcoded, we have to redefine the relevant
  ;; function
  (defun package-make-button (text &rest properties)
    "Insert button labeled TEXT with button PROPERTIES at point.
PROPERTIES are passed to `insert-text-button', for which this
function is a convenience wrapper used by `describe-package-1'."
    (let ((button-text (if (display-graphic-p)
                           text (concat "[" text "]")))
          (button-face (if (display-graphic-p)
                           '(:box `(:line-width 1
                             :color "#999999":style nil)
                            :foreground "#999999"
                            :background "#F0F0F0")
                         'link)))
      (apply #'insert-text-button button-text
             'face button-face 'follow-link t properties)))
  )

;; Flyspell
(with-eval-after-load 'flyspell
  (set-face 'flyspell-duplicate                         'face-popout)
  (set-face 'flyspell-incorrect                         'face-popout))

;; Ido 
(with-eval-after-load 'ido
  (set-face 'ido-first-match                            'face-salient)
  (set-face 'ido-only-match                               'face-faded)
  (set-face 'ido-subdir                                 'face-strong))

;; Diff
(with-eval-after-load 'diff-mode
  (set-face 'diff-header                                  'face-faded)
  (set-face 'diff-file-header                            'face-strong)
  (set-face 'diff-context                                    'default)
  (set-face 'diff-removed                                 'face-faded)
  (set-face 'diff-changed                                'face-popout)
  (set-face 'diff-added                                 'face-salient)
  (set-face 'diff-refine-added            '(face-salient face-strong))
  (set-face 'diff-refine-changed                         'face-popout)
  (set-face 'diff-refine-removed                          'face-faded)
  (set-face-attribute     'diff-refine-removed nil :strike-through t))

;; Term
(with-eval-after-load 'term
  ;; (setq eterm-256color-disable-bold nil)
  (set-face 'term-bold                                   'face-strong)
  (set-face-attribute 'term-color-black nil
                                :foreground (face-foreground 'default)
                               :background (face-foreground 'default))
  (set-face-attribute 'term-color-white nil
                              :foreground "white" :background "white")
  (set-face-attribute 'term-color-blue nil
                          :foreground "#42A5F5" :background "#BBDEFB")
  (set-face-attribute 'term-color-cyan nil
                          :foreground "#26C6DA" :background "#B2EBF2")
  (set-face-attribute 'term-color-green nil
                          :foreground "#66BB6A" :background "#C8E6C9")
  (set-face-attribute 'term-color-magenta nil
                          :foreground "#AB47BC" :background "#E1BEE7")
  (set-face-attribute 'term-color-red nil
                          :foreground "#EF5350" :background "#FFCDD2")
  (set-face-attribute 'term-color-yellow nil
                         :foreground "#FFEE58" :background "#FFF9C4"))

;; org-agende
(with-eval-after-load 'org-agenda
  (set-face 'org-agenda-calendar-event                    'default)
  (set-face 'org-agenda-calendar-sexp                     'face-faded)
  (set-face 'org-agenda-clocking                          'face-faded)
  (set-face 'org-agenda-column-dateline                   'face-faded)
  (set-face 'org-agenda-current-time                      'face-faded)
  (set-face 'org-agenda-date                            'face-salient)
  (set-face 'org-agenda-date-today        '(face-salient face-strong))
  (set-face 'org-agenda-date-weekend                      'face-faded)
  (set-face 'org-agenda-diary                             'face-faded)
  (set-face 'org-agenda-dimmed-todo-face                  'face-faded)
  (set-face 'org-agenda-done                              'face-faded)
  (set-face 'org-agenda-filter-category                   'face-faded)
  (set-face 'org-agenda-filter-effort                     'face-faded)
  (set-face 'org-agenda-filter-regexp                     'face-faded)
  (set-face 'org-agenda-filter-tags                       'face-faded)
  ;; fixes issue #18 (set-face 'org-agenda-property-face                     'face-faded)
  (set-face 'org-agenda-restriction-lock                  'face-faded)
  (set-face 'org-agenda-structure                        'face-faded))

;; org mode
(with-eval-after-load 'org
  (set-face 'org-archived                                 'face-faded)
  (set-face 'org-block                                    'face-faded)
  (set-face 'org-block-begin-line                         'face-faded)
  (set-face 'org-block-end-line                           'face-faded)
  (set-face 'org-checkbox                                 'face-faded)
  (set-face 'org-checkbox-statistics-done                 'face-faded)
  (set-face 'org-checkbox-statistics-todo                 'face-faded)
  (set-face 'org-clock-overlay                            'face-faded)
  (set-face 'org-code                                     'face-faded)
  (set-face 'org-column                                   'face-faded)
  (set-face 'org-column-title                             'face-faded)
  (set-face 'org-date                                     'face-faded)
  (set-face 'org-date-selected                            'face-faded)
  (set-face 'org-default                                  'face-faded)
  (set-face 'org-document-info                            'face-faded)
  (set-face 'org-document-info-keyword                    'face-faded)
  (set-face 'org-document-title                           'face-faded)
  (set-face 'org-done                                        'default)
  (set-face 'org-drawer                                   'face-faded)
  (set-face 'org-ellipsis                                 'face-faded)
  (set-face 'org-footnote                                 'face-faded)
  (set-face 'org-formula                                  'face-faded)
  (set-face 'org-headline-done                            'face-faded)
;;  (set-face 'org-hide                                     'face-faded)
;;  (set-face 'org-indent                                   'face-faded)
  (set-face 'org-latex-and-related                        'face-faded)
  (set-face 'org-level-1                                 'face-strong)
  (set-face 'org-level-2                                 'face-strong)
  (set-face 'org-level-3                                 'face-strong)
  (set-face 'org-level-4                                 'face-strong)
  (set-face 'org-level-5                                 'face-strong)
  (set-face 'org-level-6                                 'face-strong)
  (set-face 'org-level-7                                 'face-strong)
  (set-face 'org-level-8                                 'face-strong)
  (set-face 'org-link                                   'face-salient)
  (set-face 'org-list-dt                                  'face-faded)
  (set-face 'org-macro                                    'face-faded)
  (set-face 'org-meta-line                                'face-faded)
  (set-face 'org-mode-line-clock                          'face-faded)
  (set-face 'org-mode-line-clock-overrun                  'face-faded)
  (set-face 'org-priority                                 'face-faded)
  (set-face 'org-property-value                           'face-faded)
  (set-face 'org-quote                                    'face-faded)
  (set-face 'org-scheduled                                'face-faded)
  (set-face 'org-scheduled-previously                     'face-faded)
  (set-face 'org-scheduled-today                          'face-faded)
  (set-face 'org-sexp-date                                'face-faded)
  (set-face 'org-special-keyword                          'face-faded)
  (set-face 'org-table                                    'default)
  (set-face 'org-tag                                      'face-faded)
  (set-face 'org-tag-group                                'face-faded)
  (set-face 'org-target                                   'face-faded)
  (set-face 'org-time-grid                                'face-faded)
  (set-face 'org-todo                                    'face-popout)
  (set-face 'org-upcoming-deadline                        'face-faded)
  (set-face 'org-verbatim                                 'face-faded)
  (set-face 'org-verse                                    'face-faded)
  (set-face 'org-warning                                'face-popout))

;; Mu4e
(with-eval-after-load 'mu4e
  (set-face 'mu4e-attach-number-face                     'face-strong)
  (set-face 'mu4e-cited-1-face                            'face-faded)
  (set-face 'mu4e-cited-2-face                            'face-faded)
  (set-face 'mu4e-cited-3-face                            'face-faded)
  (set-face 'mu4e-cited-4-face                            'face-faded)
  (set-face 'mu4e-cited-5-face                            'face-faded)
  (set-face 'mu4e-cited-6-face                            'face-faded)
  (set-face 'mu4e-cited-7-face                            'face-faded)
  (set-face 'mu4e-compose-header-face                     'face-faded)
  (set-face 'mu4e-compose-separator-face                  'face-faded)
  (set-face 'mu4e-contact-face                          'face-salient)
  (set-face 'mu4e-context-face                            'face-faded)
  (set-face 'mu4e-draft-face                              'face-faded)
  (set-face 'mu4e-flagged-face                            'face-faded)
  (set-face 'mu4e-footer-face                             'face-faded)
  (set-face 'mu4e-forwarded-face                          'face-faded)
  (set-face 'mu4e-header-face                                'default)
  (set-face 'mu4e-header-highlight-face                  'face-subtle)
  (set-face 'mu4e-header-key-face                        'face-strong)
  (set-face 'mu4e-header-marks-face                       'face-faded)
  (set-face 'mu4e-header-title-face                      'face-strong)
  (set-face 'mu4e-header-value-face                          'default)
  (set-face 'mu4e-highlight-face                         'face-popout)
  (set-face 'mu4e-link-face                             'face-salient)
  (set-face 'mu4e-modeline-face                           'face-faded)
  (set-face 'mu4e-moved-face                              'face-faded)
  (set-face 'mu4e-ok-face                                 'face-faded)
  (set-face 'mu4e-region-code                             'face-faded)
  (set-face 'mu4e-replied-face                          'face-salient)
  (set-face 'mu4e-special-header-value-face                  'default)
  (set-face 'mu4e-system-face                             'face-faded)
  (set-face 'mu4e-title-face                             'face-strong)
  (set-face 'mu4e-trashed-face                            'face-faded)
  (set-face 'mu4e-unread-face                            'face-strong)
  (set-face 'mu4e-url-number-face                         'face-faded)
  (set-face 'mu4e-view-body-face                             'default)
  (set-face 'mu4e-warning-face                            'face-faded))

;; Evil

(use-package evil
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))
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

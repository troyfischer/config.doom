(setq user-full-name "Troy Fischer"
      user-mail-address "troytfischer@gmail.com"
      display-line-numbers-type t
      doom-theme 'doom-city-lights
      password-cache-expiry nil   ;; only type password once
      delete-by-moving-to-trash t ;; move files to trash instead of perma deletion
      )

(setq menu-bar-mode -1) ;; otherwise it comes up in terminal mode
;; display time in modeline
(setq display-time-format "%m-%d-%y %l:%M %p"
      display-time-default-load-average nil)
(display-time-mode)

;; line numbers in all modes
(global-display-line-numbers-mode)

;; underline current cursor line
(defun +troy/set-underline ()
  (global-hl-line-mode 1)
  (setq doom--hl-line-mode t)
  (set-face-attribute hl-line-face nil :underline t)
  (set-face-background 'hl-line nil)
  (set-face-underline 'hl-line t)
  (set-face-attribute 'hl-line nil :inherit nil))
(defun +troy/load-theme ()
  (interactive)
  (call-interactively 'consult-theme)
  (+troy/set-underline))
(map! :leader :desc "load-theme" "h t" #'+troy/load-theme)
(+troy/set-underline)
(add-hook! (prog-mode text-mode conf-mode special-mode feature-mode) #'hl-line-mode)

(let ((main-font '"Monaspace Argon")
      (variable-font '"Source Code Pro"))
(setq +troy/mono-fonts '("Cascadia Code"
                         "Hack"
                         "Fira Code"
                         "Jetbrains Mono"
                         "IBM Plex Mono"
                         "Monaspace Argon"
                         "Monaspace Krypton"
                         "Monaspace Neon"
                         "Monaspace Radon"
                         "Monaspace Xenon"))
(setq +troy/variable-fonts '("Overpass" "Source Code Pro"))
(setq +troy/font-types '("Code" "Variable"))

(defun +troy/read-font (fonts)
  (completing-read "Font: " fonts))
(defun +troy/read-face (faces)
  (completing-read "Font Type: " faces))

(defun +troy/change-font ()
  (interactive)
  (let ((face (+troy/read-face +troy/font-types)))
    (let ((font (+troy/read-font (if (string= face "Code") +troy/mono-fonts +troy/variable-fonts))))
      (if (string= face "Code") (+troy/set-mono-font font) (+troy/set-variable-font font))
      (message "%s font set to %s" face font)))
  (doom/reload-font))

(defun +troy/set-mono-font (f)
  (setq doom-font (font-spec :family f :size 15)
        doom-big-font (font-spec :family f :size 24)))

(defun +troy/set-variable-font (f)
  (setq doom-variable-pitch-font (font-spec :family f :size 15)))


(+troy/set-mono-font main-font)
(+troy/set-variable-font variable-font)

(map! :leader :desc "change font" "h r F" #'+troy/change-font)
)

(setq +doom-dashboard-banner-file (expand-file-name "default-emacs.svg" doom-private-dir))  ;; use custom image as banner

(defun +troy/open-project-in-pycharm ()
  (interactive)
  (async-shell-command (format "open -na 'PyCharm CE.app' --args %s" (projectile-project-root)))
  (doom/window-maximize-buffer))

(defun +troy/open-project-in-neovim ()
  (interactive)
  (call-process-shell-command (format "alacritty -e nvim %s" (projectile-project-root)) nil 0))
(defun +troy/open-file-in-neovim ()
  (interactive)
  (call-process-shell-command (format "alacritty -e nvim %s" (buffer-file-name)) nil 0))

(use-package! dired-x
  :config
  (setq dired-omit-files (concat dired-omit-files "\\|^\\..+$") ;; hides dotfiles
        dired-omit-files (concat dired-omit-files "\\|__pycache__") ;; hides __pycache__
        dired-deletion-confirmer #'y-or-n-p
        dired-open-extensions '(("mkv" . "mpv")
                                ("mp4" . "mpv"))))

(use-package! feature-mode
  :config
  (add-to-list 'auto-mode-alist '("\.feature$" . feature-mode)))

(setq python-shell-completion-native-enable nil)

(use-package! lsp-diagnostics
  :after flycheck
  :config
  (lsp-diagnostics-flycheck-enable))

(use-package! lsp-pyright
  :hook
  ((python-mode . (lambda ()
                    (lsp-deferred)))
   (flycheck-mode . (lambda ()
                      (flycheck-add-next-checker 'lsp 'python-pyright 'python-ruff))))
  ;;(flycheck-add-next-checker 'python-flake8 'python-pylint)
  :config
  (setq lsp-pyright-venv-directory "~/.local/share/virtualenvs"
        lsp-pyright-type-checking-mode "all"
        lsp-pyright-multi-root nil
        lsp-pyright-langserver-command "basedpyright-langserver"))

(defun +troy/python-formatter-hook ()
  (setq apheleia-formatter 'ruff)
  (setq flycheck-python-ruff-executable "/opt/homebrew/bin/ruff"))
(add-hook! python-mode #'+troy/python-formatter-hook)

(after! dap-mode
  (setq dap-python-executable "python3")
  (setq dap-python-debugger 'debugpy)
  (require 'dap-python))
(defun refresh-breakpoints ()
  (interactive)
  (set-window-buffer nil (current-buffer)))

(map! :leader
      (:prefix-map ("d" . "debug")
       :desc "dap-breakpoint-toggle" "t" #'dap-breakpoint-toggle
       :desc "dap-debug" "d" #'dap-debug
       :desc "dap-debug-recent" "r" #'dap-debug-recent
       :desc "dap-debug-last" "l" #'dap-debug-last
       :desc "dap-debug-edit-template" "e" #'dap-debug-edit-template
       :desc "dap-next" "n" #'dap-next
       :desc "refresh breakpoints" "R" #'refresh-breakpoints
       :desc "disconnect" "q" #'dap-disconnect
       (:prefix-map ("u" . "ui")
        :desc "dap-ui-breakpoints-list" "l" #'dap-ui-breakpoints-list
        :desc "dap-ui-breakpoints-delete" "d" #'dap-ui-breakpoints-delete)))

(let ((pip-path (concat (shell-command-to-string "echo -n $(python3 -m site --user-base)") "/bin")))
  (add-to-list 'exec-path pip-path))

(use-package! lsp-lua
  :config
  (setq lsp-clients-lua-language-server-bin (expand-file-name "~/.local/share/nvim/mason/bin/lua-language-server")
        lsp-clients-lua-language-server-main-location (expand-file-name "~/.local/share/nvim/mason/packages/lua-language-server/libexec/main.lua")
        lsp-lua-workspace-library (ht
                                   ((expand-file-name "~/.local/share/nvim/site/pack/deps/opt") t)
                                   ((concat (string-trim (shell-command-to-string "brew --prefix") ) "/Cellar/neovim/0.10.2_1/share/nvim/runtime" ) t))))

(use-package! clang-format)
(add-hook! 'c++-mode-hook #'lsp-deferred)

(use-package! lsp-mode
  :config
  (setq lsp-headerline-breadcrumb-enable t)
  (map! :leader :after lsp-mode "c R" #'lsp-workspace-restart))

(use-package! org
  :ensure nil
  :config
  (defvar +troy/main-org-agenda-file (expand-file-name (concat org-directory "/agenda.org")))
  (setq org-directory "~/org/"
        org-agenda-files (list +troy/main-org-agenda-file)
        org-default-notes-file (concat org-directory "notes.org")
        org-agenda-span 30
        org-hide-emphasis-markers t)
  (map! :map org-mode-map
        :localleader "TAB" #'org-toggle-inline-images)
  (add-to-list 'org-refile-targets '(org-default-notes-file :maxlevel . 3))
  ;; disable org mode auto complete suggestions
  (add-hook! 'org-mode-hook #'(lambda () (company-mode -1))))

(defun +troy/open-org-agenda ()
  (interactive)
  (find-file +troy/main-org-agenda-file))
(map! :leader
      :desc "Open agenda.org" "o a o" #'+troy/open-org-agenda)

(use-package! ob-http
  :after org-babel
  :ensure nil
  :config
  (add-to-list 'org-babel-load-languages '(http . t)))

(after! org
  (use-package! ox-extra
    :config
    (ox-extras-activate '(latex-header-blocks ignore-headlines)))

  ;; Import ox-latex to get org-latex-classes and other funcitonality
  ;; for exporting to LaTeX from org
  (use-package! ox-latex
    :init
    ;; code here will run immediately
    :config
    ;; code here will run after the package is loaded
    (setq org-latex-with-hyperref nil) ;; stop org adding hypersetup{author..} to latex export
    ;; (setq org-latex-prefer-user-labels t)

    (setq org-highlight-latex-and-related '(script entities))
    ;; deleted unwanted file extensions after latexMK
    (setq org-latex-logfiles-extensions
          (quote ("xdv" "lof" "lot" "tex~" "aux" "idx" "log" "out" "toc" "nav" "snm" "vrb" "dvi" "fdb_latexmk" "blg" "brf" "fls" "entoc" "ps" "spl" "bbl" "xmpi" "run.xml" "bcf" "acn" "acr" "alg" "glg" "gls" "ist")))

    (unless (boundp 'org-latex-classes)
      (setq org-latex-classes nil)))
  )

(defun org-babel-edit-prep:python (babel-info)
  (setq-local buffer-file-name (->> babel-info caddr (alist-get :tangle)))
  (lsp))

(defun +troy/password-store-dir ()
  (find-file "~/.password-store"))
(defun +troy/git-password-store ()
  (interactive)
  (+troy/password-store-dir)
  (magit))
(use-package! password-store
  :config
  (map! :leader
        (:prefix-map ("P" . "Passwords")
         :desc "password-store-copy" "c" #'password-store-copy
         :desc "password-store-otp-token-copy" "o" #'password-store-otp-token-copy
         :desc "password-store-git" "g" #'+troy/git-password-store
         :desc "password-store" "p" #'pass)))

(use-package! projectile
  :ensure nil
  :config
  (map! :leader :desc "ripgrep" "p G" #'projectile-ripgrep)
  (map! :leader :desc "PyCharm" "p P" #'+troy/open-project-in-pycharm)
  (map! :leader :desc "Neovim" "p N" #'+troy/open-project-in-neovim)
  (map! :leader :desc "Neovim" "p n" #'+troy/open-file-in-neovim)
  (add-to-list 'projectile-globally-ignored-directories "^\\.venv$"))

(map! :map vertico-map "C-l" #'+vertico/enter-or-preview) ;; allow C-l to select an item

(setq org-html-postamble-format
      '(("en" "<p class=\"author\">Author: %a</p><p class=\"date\">Updated: %C</p>")))
(setq org-html-postamble t)
(setq org-html-head-include-default-style nil)
(setq org-publish-project-alist
      '(
        ("blog-html"
         :recursive t
         :base-extension "org"
         :base-directory "~/blog/content"
         :publishing-directory "~/blog/public"
         :publishing-function org-html-publish-to-html
         :section-numbers nil
         :org-html-link-home "/index.html"
         :org-html-link-use-abs-url t
         )
        ("blog-static"
         :recursive t
         :base-directory "~/blog/content/"
         :base-extension "css\\|js\\|png\\|jpg\\|jpeg\\|gif\\|pdf\\|mp3\\|ogg\\|swf\\|ico"
         :publishing-directory "~/blog/public/"
         :publishing-function org-publish-attachment
         )
        ("blog" :components ("blog-html" "blog-static"))))
(defun +troy/publish-blog-remote ()
  (interactive)
  (async-shell-command "rsync -L -e ssh -uvrz ~/blog/public/ root@165.227.115.74:/var/www/html/ --delete --chmod=Du=rwx,Dgo=rx,Fu=rw,Fog=r"))

(setq auth-sources '("~/.authinfo.gpg"))

(setq code-review-auth-login-marker 'forge)
(add-hook 'code-review-mode-hook #'emojify-mode)
(add-hook 'code-review-mode-hook
          (lambda ()
            ;; include *Code-Review* buffer into current workspace
            (persp-add-buffer (current-buffer))))

(setq code-review-lgtm-message "LGTM ✔")

(add-hook 'json-mode-hook (lambda ()
                            (make-local-variable 'js-indent-level)
                            (setq js-indent-level 2)))

(add-to-list 'auto-mode-alist '("Bogiefile" . yaml-mode))

(when (version<= "29" emacs-version)
  (setq pixel-scroll-precision-mode t))

(defun file-notify-rm-all-watches ()
  "Remove all existing file notification watches from Emacs."
  (interactive)
  (maphash
   (lambda (key _value)
     (file-notify-rm-watch key))
   file-notify-descriptors))

(when (not (eq system-type 'darwin))
  (use-package! screenshot))

(defun +troy/pdf-view-config ()
  (display-line-numbers-mode -1)
  (global-hl-line-mode -1))
(add-hook! 'pdf-view-mode-hook #'+troy/pdf-view-config)

(use-package! leetcode
  :config
  (setq leetcode-prefer-language "python3")
  (setq leetcode-prefer-sql "mysql")
  (setq leetcode-save-solutions t)
  (setq leetcode-directory "~/leetcode")
  (add-to-list 'lsp-file-watch-ignored-directories "[/\\\\]leetcode\\'")
  (add-hook 'leetcode-solution-mode-hook
          (lambda() (flycheck-mode -1))))

(map! :leader
      (:prefix-map
       ("y" . "yank")
       :desc "org-yank-link" "o" #'link-hint-copy-link-at-point
       :desc "magit-yank-link" "g" #'forge-copy-url-at-point-as-kill))

(use-package! avy
  :config
  (setq avy-all-windows t))

(map! "C-s" #'swiper-isearch
      "C-S-s" #'swiper-isearch-backward)
(map! :map ivy-minibuffer-map
      "C-j" #'ivy-next-line
      "C-k" #'ivy-previous-line)

(when (not (bound-and-true-p evil-state))
  (map! :leader
        :desc "split horizontal" "w v" #'split-window-horizontally
        :desc "split vertical" "w s" #'split-window-vertically
        :desc "ace window" "w w" #'ace-window
        :desc "ace window delete" "w d" #'ace-delete-window))
(when (bound-and-true-p evil-state)
  (use-package! ace-window
    :config
    (map! :leader :desc "ace window" "w C-w" #'ace-window)))

(map! "C-c w h" #' +hydra/window-nav/body)

(when (not (bound-and-true-p evil-state))
  (map! "C-c s r" #'counsel-mark-ring))

(use-package! magit
  :ensure nil
  :config
  (setq magit-log-margin '(t "%Y-%m-%d %I:%M %p " magit-log-margin-width t 18)))

(put 'aio-defun 'edebug-form-spec
     '(name
       (&optional arg-list)
       body))

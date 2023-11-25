;;; cmake-utils.el --- Run useful CMake commands from inside Emacs -*- lexical-binding:t -*-

;; Copyright (C) 2023 nonk123

;; Author: nonk123 <me@nonk.dev>
;; Version: 0.1.0
;; Keywords: cmake, utils, commands
;; URL: https://github.com/nonk123/emacs-cmake-utils

;;; Commentary:

;; See README.md for more information.

;;; Code:

(require 'project)

(defvar cmake-utils-cmake-executable "cmake"
  "The CMake executable used when executing commands.")

(defvar cmake-utils-jobs-count 4
  "A safe default for the `-j' argument.")

(defvar cmake-utils-build-dir "build"
  "The build directory relative to the root of the project.")

(defun cmake-utils--expect-cmake-project ()
  "Signal a `user-error' unless inside a CMake project."
  (let ((proj* nil))
    (when-let ((proj (project-current)))
      (when (file-exists-p (concat (project-root proj)
				   "CMakeLists.txt"))
	(setq proj* proj)))
    (or proj* (user-error "Not inside a CMake project"))))

(defun cmake-utils--expect-project-root ()
  "Return the root of the open CMake project."
  (project-root (cmake-utils--expect-cmake-project)))

(defun cmake-utils--expect-build-dir ()
  "Get the absolute path to the build directory of the open CMake project."
  (concat (cmake-utils--expect-project-root) cmake-utils-build-dir))

(defun cmake-utils--run (buffer-name process-name &rest args)
  "Run CMake with ARGS inside the current CMake project.

If BUFFER-NAME is not nil, pop-up that buffer and display the output there.

PROCESS-NAME is passed to `make-process'."
  (cmake-utils--expect-cmake-project)
  (let ((buffer (if buffer-name (get-buffer-create buffer-name) nil)))
    (when buffer
      (with-current-buffer buffer
        (let ((inhibit-read-only t))
          (erase-buffer))
        (special-mode)))
    (prog1 (apply #'start-process process-name buffer
		  cmake-utils-cmake-executable args)
      (when buffer
        (display-buffer buffer #'display-buffer-pop-up-window)))))

;;;###autoload
(defun cmake-utils-configure ()
  "Configure the CMake project."
  (interactive)
  (cmake-utils--run "*cmake-configure*" "CMake Configure"
		    "-B" (cmake-utils--expect-build-dir)
		    "-S" (cmake-utils--expect-project-root)
		    "-G" "Ninja"
		    "-D" "CMAKE_BUILD_TYPE=Debug"))

;;;###autoload
(defun cmake-utils-build ()
  "Build the CMake project."
  (interactive)
  (cmake-utils--run "*cmake-build*" "CMake Build"
		    "--build" (cmake-utils--expect-build-dir)
		    "-j" (number-to-string cmake-utils-jobs-count)))

;;;###autoload
(defun cmake-utils-clean ()
  "Clean the CMake project."
  (interactive)
  (cmake-utils--run "*cmake-clean*" "CMake Clean"
 		    "--build" (cmake-utils--expect-build-dir)
		    "--target" "clean"))

;;;###autoload
(defun cmake-utils-reconfigure ()
  "Reconfigure the CMake project."
  (interactive)
  (let ((build-dir (cmake-utils--expect-build-dir)))
    (delete-file (concat build-dir "CMakeCache.txt"))
    (cmake-utils-configure)))

;; TODO: add clean-build.

;; TODO: add list targets and run.

(with-eval-after-load 'cmake-mode
  (defvar cmake-mode-map) ; silence a warning
  (keymap-set cmake-mode-map "C-c c" #'cmake-utils-configure)
  (keymap-set cmake-mode-map "C-c r" #'cmake-utils-reconfigure)
  (keymap-set cmake-mode-map "C-c b" #'cmake-utils-build)
  (keymap-set cmake-mode-map "C-c C" #'cmake-utils-clean))

(provide 'cmake-utils)

;;; cmake-utils.el ends here

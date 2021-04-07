+++
title = "Efficiently untangling Elisp from .org files"
date = "2016-05-12"
tags = [ "Emacs", "org-mode" ]
topics = [ "Emacs" ]
+++

Many people keep their Emacs config in and org-mode file because it&rsquo;s
easier to manage.

However, we need to extract the Elisp parts out of the org file and
evaluate them somehow. org-mode has a built-in command for this:
`(org-babel-load-file "config.org")`. However, this is an org-mode
command, and org-mode is huge. So your init.el needs to load a good
amount of org-mode just to get the elisp out of it.
But to be able to do this you&rsquo;d
need to load a good amount of the org-mode file. 

I wanted to have something better. Something that is flexible and
gives me a quicker startup time.

<!--more-->

My method is to do the following:

1.  If the `config.org` is newer than `config.el`, then **efficiently**
    extract all **eligible** Elisp source code blocks from the `.org`
    file and write them into the `.el` file. Even when done efficiently,
    this is relatively slow. But it almost never happens.
2.  then load the `config.el` file. This is quite fast.

I wrote two words in bold:

-   **efficiently:** to un-tangle the source-code blocks I could have
    used `(org-babel-tangle nil "config.el")`. But it opens and
    closes the target file for every single source code blocks. You
    can hear the churn if you still use spinning rust (a hard disk).
    My code fixes this.
-   **eligible:** we all know than org-tangle honors &ldquo;`:tangle no`&rdquo;. But
    it doesn&rsquo;t care for the todo-state of a section. I wrote my code
    so that it will skip over items marked as &ldquo;CANCELED&rdquo;. It&rsquo;s just
    nicer to mark one section with &ldquo;CANCELED&rdquo; &#x2014; compared to change
    everyone of it&rsquo;s five source-code blocks with `:tangle no`.

# The tangling

First I define a function that &#x2014; when the point is at some source-code block &#x2014;
goes back to the section header and checks if there entry has been canceled:

```lisp
;; This is GPLv2. If you still don't know the details, read
;; http://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html

(defun my-tangle-section-canceled ()
  "Return t if the current section header was CANCELED, else nil."
  (save-excursion
    (if (re-search-backward "^\\*+\\s-+\\(.*?\\)?\\s-*$" nil t)
        (string-prefix-p "CANCELED" (match-string 1))
      nil)))
```

With that done, we can untangle source-code blocks like this:

-   disabled garbage collection
-   defines the regexp (stolen from org-mode) to parse org-mode source blocks
-   uses a while-loop to search every source-block
-   checks that the source block is neither untangleable nor in a CANCELED section
-   appends the body of the source block to `body-list`
-   finally, it uses a temporary file and insert all the collected bodies into it
-   and writes the result out into a `.el`-file

```lisp
;; This uses partially derived code from ob-core.el. So this snippet
;; is GPLv3 or later. If you still don't know the details, read
;; http://www.gnu.org/licenses/

(defun my-tangle-config-org (orgfile elfile)
  "This function will write all source blocks from =config.org= into
=config.el= that are ...

- not marked as :tangle no
- have a source-code of =emacs-lisp=
- doesn't have the todo-marker CANCELED"
  (let* ((body-list ())
         (gc-cons-threshold most-positive-fixnum)
         (org-babel-src-block-regexp   (concat
                                        ;; (1) indentation                 (2) lang
                                        "^\\([ \t]*\\)#\\+begin_src[ \t]+\\([^ \f\t\n\r\v]+\\)[ \t]*"
                                        ;; (3) switches
                                        "\\([^\":\n]*\"[^\"\n*]*\"[^\":\n]*\\|[^\":\n]*\\)"
                                        ;; (4) header arguments
                                        "\\([^\n]*\\)\n"
                                        ;; (5) body
                                        "\\([^\000]*?\n\\)??[ \t]*#\\+end_src")))
    (with-temp-buffer
      (insert-file-contents orgfile)
      (goto-char (point-min))
      (while (re-search-forward org-babel-src-block-regexp nil t)
        (let ((lang (match-string 2))
              (args (match-string 4))
              (body (match-string 5))
              (canc (my-tangle-section-canceled)))
          (when (and (string= lang "emacs-lisp")
                     (not (string-match-p ":tangle\\s-+no" args))
                     (not canc))
              (add-to-list 'body-list body)))))
    (with-temp-file elfile
      (insert (format ";; Don't edit this file, edit %s instead ...\n\n" orgfile))
      (apply 'insert (reverse body-list)))
    (message "Wrote %s ..." elfile)))
```

# The Usage

Now I can use this function. If either the `.el` file doesn&rsquo;t exist or
the `.org` file is newer, I&rsquo;ll re-create the `.el` file.

```lisp
;; This is GPLv2. If you still don't know the details, read
;; http://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html

(let ((orgfile (concat user-emacs-directory "config.org"))
      (elfile (concat user-emacs-directory "config.el")))
  (when (or (not (file-exists-p elfile))
            (file-newer-than-file-p orgfile elfile))
    (my-tangle-config-org orgfile elfile))
  (load-file elfile))
```

This code is mostly active when I update my emacs configuration with
`git pull`, e.g. when switching from desktop to laptop or vica versa.

# Also tangle on save

But normally I&rsquo;d like to avoid even this. I wrote a function that is
called whenever I save a file. It checks if the file is indeed the
.org file.

```lisp
;; This is GPLv2. If you still don't know the details, read
;; http://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html

(defun my-tangle-config-org-hook-func ()
  (when (string= "config.org" (buffer-name))
    (let ((orgfile (concat user-emacs-directory "config.org"))
          (elfile (concat user-emacs-directory "config.el")))
      (my-tangle-config-org orgfile elfile))))
(add-hook 'after-save-hook #'my-tangle-config-org-hook-func)
```

# Some benchmark results

<table border="2" cellspacing="0" cellpadding="6">


<colgroup>
<col  class="org-left" />

<col  class="org-left" />
</colgroup>
<thead>
<tr>
<th scope="col" class="org-left">Task</th>
<th scope="col" class="org-left">Duration</th>
</tr>
</thead>

<tbody>
<tr>
<td class="org-left">Loading with (org-babel-load-file &ldquo;config.org&rdquo;)</td>
<td class="org-left">1.31 s</td>
</tr>


<tr>
<td class="org-left">Loading with my code, config.el is up-to-date</td>
<td class="org-left">0.99 s</td>
</tr>


<tr>
<td class="org-left">Loading with my code, after byte-compiling</td>
<td class="org-left">0.85 s</td>
</tr>


<tr>
<td class="org-left">Loading with my code, but need to re-generate config.el</td>
<td class="org-left">1.10 s</td>
</tr>
</tbody>
</table>

You&rsquo;ll see that &#x2026;

-   my approach is 0.32 seconds faster than using `org-babel-load-file`.
    But I have the added benefit that I can mark sections as CANCELED
    :-)
-   after a fresh &ldquo;git pull&rdquo;, I pay a very low price of 0.09 seconds
-   byte-compilation doesn&rsquo;t bring much for this file &#x2026;

All measurements were done on my laptop. My desktop is about double as fast.

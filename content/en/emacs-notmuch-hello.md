+++
title = "A nicer notmuch-hello screen for Emacs"
date = "2016-05-03"
tags = [ "Emacs", "notmuch" ]
categories = [ "Emacs" ]
+++

Here I define my own hello screen for [notmuch](http://notmuchmail.org/). However, I didn&rsquo;t like it&rsquo;s original
&ldquo;hello&rdquo; screen not that much. So I wrote something to replace it.

<!--more-->

This is how it used to look:

![img](./emacs-notmuch-hello-orig.png)

That&rsquo;s nice for a start.

-   Notmuch&rsquo;s hello page is using Emacs&rsquo; config feature. I however like
    to write everything out, and document the things while I doing them
    in my [config.org](https://bitbucket.org/holgerschurig/emacsconf/raw/HEAD/config.org) file. &rarr; Get rid of buttons like &ldquo;Save&rdquo; or the
    &ldquo;Customize &#x2026;&rdquo; text.
-   Notmuch doesn&rsquo;t show the amount of messages. Okay, when I add query
    to `notmuch-saved-searches`, it will show them. But at an awkward
    position: around the center of the screen. Also it won&rsquo;t
    differentiate between new and total counts .. or it would need two
    queries, not just one. &rarr; Present the queries better.
-   I see elements that i never use, e.g. the header, the footer, or the
    &ldquo;Clear&rdquo; button. &rarr; Get rid of them.

What I wrote now looks like this:

![img](./emacs-notmuch-hello-mine.png)

# The implementation

Let&rsquo;s start simple: define the queries.

Note that I define basic queries, e.g. at this point in time I don&rsquo;t
create two queries for the unread/total amount of messages.

```lisp
;; This is GPLv2. If you still don't know the details, read
;; http://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html

(use-package notmuch-hello
  :defer t
  :config
  (setq notmuch-saved-searches
        '((:key "i" :name "inbox" :query "folder:INBOX")
          (:key "b" :name "barebox" :query "folder:barebox")
          (:key "c" :name "linux-can" :query "folder:linux-can")
          (:key "a" :name "linux-arm-kernel" :query "folder:linux-arm-kernel")
          (:key "m" :name "linux-mmc" :query "folder:linux-mmc")
          (:key "9" :name "ath9k-devel" :query "folder:ath9k-devel")
          (:key "e" :name "elecraft" :query "folder:elecraft")
          (:key "p" :name "powertop" :query "folder:powertop")
          (:key "D" :name "Deleted" :query "tag:deleted")
          (:key "F" :name "Flagged" :query "tag:flagged")
          (:key "S" :name "Sent" :query "folder:sent")
          (:key "u" :name "unread" :query "tag:unread")
          ))

  ;; We add items later in reverse order with (add-to-list ...):
  (setq notmuch-hello-sections '())

  ;; Add a thousand separator
  (setq notmuch-hello-thousands-separator ".")
```

We set `notmuch-hello-sections` to the empty list, so we add
hello-section after hello-section with `(add-to-list`. This prepends,
so we add the sections in reverse order. 

# List of recent searches

![img](./emacs-notmuch-hello-recent.png)

At the bottom are the recent searches, just without the &ldquo;Save&rdquo; and
&ldquo;Clear&rdquo; buttons. This is just a slightly modified reimplementation of
`notmuch-hello-insert-recent-searches`:

```lisp
;; This is GPLv3. If you still don't know the details, read
;; http://www.gnu.org/licenses/gpl-3.0.en.html

(defun my-notmuch-hello-insert-recent-searches ()
  "Insert recent searches."
  (when notmuch-search-history
    (widget-insert "Recent searches:")
    (widget-insert "\n\n")
    (let ((start (point)))
      (loop for i from 1 to notmuch-hello-recent-searches-max
        for search in notmuch-search-history do
        (let ((widget-symbol (intern (format "notmuch-hello-search-%d" i))))
          (set widget-symbol
           (widget-create 'editable-field
                  ;; Don't let the search boxes be
                  ;; less than 8 characters wide.
                  :size (max 8
                         (- (window-width)
                        ;; Leave some space
                        ;; at the start and
                        ;; end of the
                        ;; boxes.
                        (* 2 notmuch-hello-indent)
                        ;; 1 for the space
                        ;; before the `[del]'
                        ;; button. 5 for the
                        ;; `[del]' button.
                        1 5))
                  :action (lambda (widget &rest ignore)
                        (notmuch-hello-search (widget-value widget)))
                  search))
          (widget-insert " ")
          (widget-create 'push-button
                 :notify (lambda (widget &rest ignore)
                       (when (y-or-n-p "Are you sure you want to delete this search? ")
                     (notmuch-hello-delete-search-from-history widget)))
                 :notmuch-saved-search-widget widget-symbol
                 "del"))
        (widget-insert "\n"))
      (indent-rigidly start (point) notmuch-hello-indent))
    nil))

  (add-to-list 'notmuch-hello-sections #'my-notmuch-hello-insert-recent-searches)
```

# Simple search line

![img](./emacs-notmuch-hello-search.png)

Then I want a simple search method. The original implementation suited
my needs quite fine, I use it unmodified:

```lisp
  (add-to-list 'notmuch-hello-sections #'notmuch-hello-insert-search)
```

# Header face for the search screen

And finally we want out improved hello screen. Let&rsquo;s start with the
face for the header:

```lisp
  ;; This is GPLv2. If you still don't know the details, read
  ;; http://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html

  (defface my-notmuch-hello-header-face
    '((t :foreground "white"
         :background "blue"
         :weight bold))
    "Font for the header in `my-notmuch-hello-insert-searches`."
    :group 'notmuch-faces)
```

# Helper function to count messages

I implemented a simpler version of `notmuch-hello-query-counts`:

```lisp
  ;; This is GPLv3. If you still don't know the details, read
  ;; http://www.gnu.org/licenses/gpl-3.0.en.html

  (defun my-count-query (query)
    (with-temp-buffer
      (insert query "\n")
      (unless (= (call-process-region (point-min) (point-max) notmuch-command
                                      t t nil "count" "--batch") 0)
        (notmuch-logged-error "notmuch count --batch failed"
"Please check that the notmuch CLI is new enough to support `count
--batch'. In general we recommend running matching versions of
the CLI and emacs interface."))

      (goto-char (point-min))
      (let ((n (read (current-buffer))))
        (if (= n 0)
            nil
          (notmuch-hello-nice-number n)))))
```

This function can be called like this:

    (my-count-query "folder:linux-arm-kernel tag:unread")

It will return either nil or a string containing the nicely
formatted amount of messages. Note that it doesn&rsquo;t return the integer
0 or the string &ldquo;0&rdquo; but nil. I&rsquo;ve done it so that I can easier depend
on the return value in an `(if ...)` form &#x2014; if considers &ldquo;0&rdquo; to be
true.

# Create query widget

The following either inserts a `'push-button` widget (if the query has
a count associated) or some empty spaces:

```lisp
  ;; This is GPLv2. If you still don't know the details, read
  ;; http://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html

  (defun my-notmuch-hello-query-insert (cnt query elem)
    (if cnt
        (let* ((str (format "%s" cnt))
               (widget-push-button-prefix "")
               (widget-push-button-suffix "")
               (oldest-first (case (plist-get elem :sort-order)
                               (newest-first nil)
                               (oldest-first t)
                               (otherwise notmuch-search-oldest-first))))
          (widget-create 'push-button
                         :notify #'notmuch-hello-widget-search
                         :notmuch-search-terms query
                         :notmuch-search-oldest-first oldest-first
                         :notmuch-search-type 'tree
                         str)
          (widget-insert (make-string (- 8 (length str)) ? )))
      (widget-insert "        ")))
```

# Binding everything together

And finally we iterate over the `notmuch-saved-searches`, get the base
query, calculate the count of total messages into `q_tot` and the
count of new messages into `q_new`. We use that information to create
the widgets accordingly.

![img](./emacs-notmuch-hello.png)

```lisp
  ;; This is GPLv2. If you still don't know the details, read
  ;; http://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html

  (defun my-notmuch-hello-insert-searches ()
    "Insert the saved-searches section."
    (widget-insert (propertize "New     Total      Key  List\n" 'face 'my-notmuch-hello-header-face))
    (mapc (lambda (elem)
            (when elem
              (let* ((q_tot (plist-get elem :query))
                     (q_new (concat q_tot " AND tag:unread"))
                     (n_tot (my-count-query q_tot))
                     (n_new (my-count-query q_new)))
                (my-notmuch-hello-query-insert n_new q_new elem)
                (my-notmuch-hello-query-insert n_tot q_tot elem)
                (widget-insert "   ")
                (widget-insert (plist-get elem :key))
                (widget-insert "    ")
                (widget-insert (plist-get elem :name))
                (widget-insert "\n")
              ))
            )
          notmuch-saved-searches))
```

That&rsquo;s all, folks.

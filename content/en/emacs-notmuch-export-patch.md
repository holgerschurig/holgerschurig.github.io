+++
title = "Export patches from Emacs' Notmuch"
date = "2017-01-15"
topics = [ "Emacs" ]
tags = [ "Emacs", "notmuch" ]
+++

I&rsquo;m reading several linux-kernel related mailing lists. They are full
of proposed patches. And from time to time a few of them look
interesting. So I wanted to have an easy (and fast) solution of
exporting those patches: with a keystroke, and without the need
of specifying patch names.

# Format of a patch email

If you ever contributed a patch to **Linux**, you&rsquo;d know that your patch
must follow some formatting rules, or it might be ignored. Some of those
rules are import for my purpose:

-   if a patch isn&rsquo;t self, consistent, it should have some 1/4 (1 of 4)
    marking in the subject
-   patches must have a [PATCH &#x2026;] tag at the start of the subject.
-   patches must be directly in the e-mail text, not in an attachment.
    This effectively means that I don&rsquo;t have to deal with MIME parts.

Here are two examples of such email subjects:

    [PATCH] mmc: host: use pr_err for sdhci_dumpregs
    [PATCH 3/9] clocksource/drivers/rockchip_timer: Convert init function to return error

# Implementation

Let&rsquo;s define some local variables:

    (defun my-notmuch-export-patch ()
      (interactive)
      (let* ((from (notmuch-show-get-from))
             (date (notmuch-show-get-date))
             (subject (notmuch-show-get-subject))
             (id (notmuch-show-get-message-id))
             (filename subject)
             (patchnum))

The first step is to extract the patch number:

    (when (string-match "\\[PATCH.+?0*\\([0-9]+\\)/[0-9]+\\]" filename)
      (setq patchnum (string-to-number (match-string 1 filename))))

We now do the following steps with the raw subject:

-   remove the optional [PATCH &#x2026;] prefix
-   replace everything that are not letters/digits with a dash
-   convert consecutive dashes into one dash
-   make sure we don&rsquo;t have a dash at the start
-   make sure we don&rsquo;t have a dash at the end

So let&rsquo;s do this:

    (setq filename (replace-regexp-in-string "\\[PATCH.*\\]" "" filename))
    (setq filename (replace-regexp-in-string "\[^a-zA-Z0-9]" "-" filename))
    (setq filename (replace-regexp-in-string "\\-+" "-" filename))
    (setq filename (replace-regexp-in-string "^-" "" filename))
    (setq filename (replace-regexp-in-string "-$" "" filename))

Prepend the patchnum to the future filename:

    (when patchnum
      (setq filename (concat (format "%04d" patchnum) "-" filename)))

And prepend a directory as well:

    (setq filename (concat "/tmp/" filename ".patch"))

And now we need write things out.

First we create a temporary buffer and insert some of message properties
as a header.

Then we need to get the actual patch. In a non-MIME-encoded e-mail,
the text is the (sic!) MIME part 1. We call the notmuch binary to give
us back this text and insert it into the buffer as well. Note: the `t`
as the 3rd argument to `(call-process` makes the output of the notmuch
command end in the current buffer.

Finally I write this buffer to a file and kill the buffer.
buffer.

    (save-excursion
      (let ((buf (generate-new-buffer (concat "*notmuch-export-patch-" id "*"))))
        (with-current-buffer buf
          (insert (format "Subject: %s\n" subject))
          (insert (format "From: %s\n" from))
          (insert (format "Date: %s\n" date))
          (insert (format "Message-Id: %s\n\n" (substring id 3)))
          (let ((coding-system-for-read 'no-conversion))
            (call-process notmuch-command nil t nil "show" "--part:1" id))
          (write-file filename))
        (kill-buffer buf)))))

Done!

# Keybinding

And the last step is to bind this to some keys. As the function works
both in tree-view and in message-show mode, I bind it to both places.

    (define-key notmuch-show-mode-map "x" #'my-notmuch-export-patch)
    (define-key notmuch-tree-mode-map "x" #'my-notmuch-export-patch)

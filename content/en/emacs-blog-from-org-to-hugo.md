+++
title = "Blog from Org-Mode to Hugo"
date = "2016-03-31"
tags = [ "Emacs", "Hugo", "org-mode" ]
categories = [ "Emacs" ]
+++

I use the static web-site generator [Hugo](https://gohugo.io/) to create my home page. I
also use [Emacs](https://www.gnu.org/software/emacs/) as my main editor. Hugo is good with [Markdown](https://help.github.com/categories/writing-on-github/). Emacs is
good at Markdown, too. But much better with [Org-Mode](http://orgmode.org/).

If you want &#x2026;

-   export one `.org` file as one web page, look at Giles Paterson
    [solution](https://vurt.co.uk/post/blogging-with-emacs-and-hugo/)
-   export just a subtree of an org-file (e.g. from your org-based Emacs
    configuration), then look here.

<!--more-->

I wanted a nice way to publish single sub-trees of an org-file to
Hugo. So I wrote my own &ldquo;publish this specific subtree&rdquo; export. The
interactive function is simply called `hugo`, and I bind it to some
key combination, in my case to `Alt-g h`, g like go, and h like go. So
I type &ldquo;go hugo&rdquo;, more or less.

# Usage

One question is how we store Hugo-specific information. So far I only
care for the title, tags, topics and, of course, the file name. As I
don&rsquo;t want to have one-file per blog post, but instead use subtrees of
my org-file, I need to store this information into org&rsquo;s property
drawers.

But writing them by hand is tedious. So I added code that ensures that
all needed properties exists. Before I started blogging this article, 
my org-mode buffer looked like this:

![img](./start.png)

Then I called the `(hugo)` function and my buffer looked like this:

![img](./started.png)

The cursor is positioned at the first empty field.

(Note that I later changed the code below from `HUGO_CATEGORIES` to
`HUGO_TOPICS`, because that&rsquo;s how I now have defined my taxonomy in
Hugo.)

Note that the title and date fields are pre-filled. 
You can of course change them. Only when everything is filled in &#x2026;

![img](./ready.png)

&#x2026; does the export to Hugo create the markdown file with the properly
formatted TOML front matter.

# Implementation

Let&rsquo;s start simple. First we define where our contents should be stored:

    ;; This is GPLv2. If you still don't know the details, read
    ;; http://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html
    
    (defvar hugo-content-dir "~/www.hugo/content/"
      "Path to Hugo's content directory")

The next two functions care that all needed property drawers exist:

    ;; This is GPLv2. If you still don't know the details, read
    ;; http://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html
    
    (defun hugo-ensure-property (property)
      "Make sure that a property exists. If not, it will be created.
    
    Returns the property name if the property has been created,
    otherwise nil."
      (if (org-entry-get nil property)
          nil
        (progn (org-entry-put nil property "")
               property)))
    
    (defun hugo-ensure-properties ()
      "This ensures that several properties exists. If not, these
    properties will be created in an empty form. In this case, the
    drawer will also be opened and the cursor will be positioned
    at the first element that needs to be filled.
    
    Returns list of properties that still must be filled in"
      (require 'dash)
      (let ((current-time (format-time-string (org-time-stamp-format t t) (org-current-time)))
            first)
        (save-excursion
          (unless (org-entry-get nil "TITLE")
            (org-entry-put nil "TITLE" (nth 4 (org-heading-components))))
          (setq first (--first it (mapcar #'hugo-ensure-property '("HUGO_TAGS" "HUGO_TOPICS" "HUGO_FILE"))))
          (unless (org-entry-get nil "HUGO_DATE")
            (org-entry-put nil "HUGO_DATE" current-time)))
        (when first
          (goto-char (org-entry-beginning-position))
          ;; The following opens the drawer
          (forward-line 1)
          (beginning-of-line 1)
          (when (looking-at org-drawer-regexp)
            (org-flag-drawer nil))
          ;; And now move to the drawer property
          (search-forward (concat ":" first ":"))
          (end-of-line))
        first))

And this is the main function. It simply gathers all information from org-mode,
formats it correctly, and writes it out.

In case you have the `ox-gfm.el` elisp package is available, the
export will use &ldquo;Github Flavored Markdown&rdquo;. Otherwise, the normal
markdown export backend will be use. The benefit of =&rsquo;gfm= is that
code blocks can be highlighted.

    ;; This is GPLv2. If you still don't know the details, read
    ;; http://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html
    
    (defun hugo ()
      (interactive)
      (unless (hugo-ensure-properties)
        (let* ((title    (concat "title = \"" (org-entry-get nil "TITLE") "\"\n"))
               (date     (concat "date = \"" (format-time-string "%Y-%m-%d" (apply 'encode-time (org-parse-time-string (org-entry-get nil "HUGO_DATE"))) t) "\"\n"))
               (topics   (concat "topics = [ \"" (mapconcat 'identity (split-string (org-entry-get nil "HUGO_TOPICS") "\\( *, *\\)" t) "\", \"") "\" ]\n"))
               (tags     (concat "tags = [ \"" (mapconcat 'identity (split-string (org-entry-get nil "HUGO_TAGS") "\\( *, *\\)" t) "\", \"") "\" ]\n"))
               (fm (concat "+++\n"
                           title
                           date
                           tags
                           topics
                           "+++\n\n"))
               (file     (org-entry-get nil "HUGO_FILE"))
               (coding-system-for-write buffer-file-coding-system)
               (backend  'md)
               (blog))
          ;; try to load org-mode/contrib/lisp/ox-gfm.el and use it as backend
          (if (require 'ox-gfm nil t)
              (setq backend 'gfm)
            (require 'ox-md))
          (setq blog (org-export-as backend t))
          ;; Normalize save file path
          (unless (string-match "^[/~]" file)
            (setq file (concat hugo-content-dir file))
          (unless (string-match "\\.md$" file)
            (setq file (concat file ".md")))
          ;; save markdown
          (with-temp-buffer
            (insert fm)
            (insert blog)
            (untabify (point-min) (point-max))
            (write-file file)
            (message "Exported to %s" file))
          ))))

And finally I set my preferred key-binding with `(bind-key)`. I like
this method over over the standard keybinding methods because it works
together with `(describe-personal-keybindings)`. And because I&rsquo;m
already a [use-package](<https://github.com/jwiegley/use-package>) user
it&rsquo;s already loaded anyway :-)

    (bind-key "M-g h" #'hugo)

# Images

In this blog post are 3 pictures. My current code does **not** copy them to
Hugo&rsquo;s contents directory, and I don&rsquo;t really plan this. I don&rsquo;t want to
maintain images as part of my Emacs configuration. Instead, I added text like
this into my org-mode buffer and do the rest in my Hugo setup:

    [[./ready.png]]

# Separate description (teaser) from main content

In Hugo, you can separate your normal content from he teaser at the
top with a &ldquo;<!&#x2013;more&#x2013;>&rdquo; marker. Generate this HTML with
&ldquo;#+HTML: <!&#x2013;more&#x2013;>&rdquo; in a line by itself.

+++
title = "Let Hugo ignore Emacs lockfiles"
topics = [ "Emacs" ]
tags = [ "Hugo", "Emacs", "Blogging" ]
date = "2016-04-01"
+++

When you run

    hugo server
	
the static web-site generator [Hugo](http://gohugo.io) creates a local
server that you can use to fine-tune your pages. Hugo sits and watches
your content and layout directory for any changes. Whenever a file changes,
it re-renders the pages and even tells your browser to live-relead the pages.

Very nice.

Except that it doesn't work with Emacs. But there's a cure.

<!--more-->

## The problem

The problem is that Emacs creates lockfiles and Hugo triggers detects
those lockfiles, but get's confused. Here is such a lockfile:

```bash
schurig@desktop:~/www.hugo/content/en$ ll
total 24
-rw-r--r-- 1 schurig schurig  988 Apr  1 08:55 bash-aliases.md
-rw-r--r-- 1 schurig schurig 1759 Apr  1 08:55 blogging-with-sitecopy.md
drwxr-xr-x 2 schurig schurig 4096 Apr  1 08:55 emacs-blog-from-org-to-hugo/
-rw-r--r-- 1 schurig schurig 6503 Apr  1 08:55 emacs-blog-from-org-to-hugo.md
-rw-r--r-- 1 schurig schurig 3593 Apr  1 08:55 emacs-init-tangle.md
lrwxrwxrwx 1 schurig schurig   21 Apr  1 08:58 .#let-hugo-ignore-emacs-lockfiles.md -> schurig@desktop.28219
```

(Note: `ll` is described in [bash aliases]({{< relref "en/bash-aliases.md" >}})).

## The cure

Setting `ignoreFiles` in `config.toml` won't help. The file system watcher doesn't care
about the `ignoreFile` setting.

I finally fixed this with a patch to Hugo:

```diff
diff --git a/commands/hugo.go b/commands/hugo.go
index 131879c..1ed9823 100644
--- a/commands/hugo.go
+++ b/commands/hugo.go
@@ -732,12 +732,14 @@ func NewWatcher(port int) error {
 
 				for _, ev := range evs {
 					ext := filepath.Ext(ev.Name)
+					base := filepath.Base(ev.Name)
 					istemp := strings.HasSuffix(ext, "~") ||
 						(ext == ".swp") ||
 						(ext == ".swx") ||
 						(ext == ".tmp") ||
 						(ext == ".DS_Store") ||
 						filepath.Base(ev.Name) == "4913" ||
+						strings.HasPrefix(base, ".#") || // Emacs lock files
 						strings.HasPrefix(ext, ".goutputstream") ||
 						strings.HasSuffix(ext, "jb_old___") ||
 						strings.HasSuffix(ext, "jb_bak___")

```

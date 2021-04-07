+++
title = "Update your Blog with Sitecopy"
tags = [ "Hugo" ]
topics = [ "Linux" ]
date = "2016-03-31"
+++

Almost any site describing how to use the static web site generator
[Hugo](http://gohugo.io) uses some complicated method to get the contents
publish.

<!--more-->

I simply do this with [sitecopy](http://www.manyfish.co.uk/sitecopy/).

Getting it is easy on Debian:

```none
apt-get install sitecopy
```

And using it with Hugo is easy, too. I have a tiny `Makefile`
that contains this:

```none
publish:
	hugo
	sitecopy -u home
```

And together with me `~/.sitecopyrc` file updates are done in a breeze:

```none
site home
	server www.holgerschurig.de
	remote /
	local /home/holger/www.hugo/public
	username gehe-eim
	password supergeheim
	permissions exec
	state checksum
	protocol ftp
	checkmoved
	tempupload
	ignore /logs
	exclude /logs
```

Now all I do is:

```none
holger@holger:~/www.hugo$ make
hugo
Started building site
0 draft content
0 future content
14 pages created
25 non-page files copied
0 paginator pages created
16 tags created
4 topics created
in 106 ms
sitecopy -u home
sitecopy: Updating site `home' (on www.holgerschurig.de in /)
Creating en/blogging-with-sitecopy/: done.
Uploading tags/hugo/index.xml: [..] done.
Uploading tags/hugo/index.html: [.] done.
Uploading tags/index.html: [.] done.
Uploading en/emacs-init-tangle/index.html: [.] done.
Uploading en/emacs-blog-from-org-to-hugo/index.html: [..] done.
Uploading en/blogging-with-sitecopy/index.html: [.] done.
Uploading en/index.xml: [...] done.
Uploading en/index.html: [.] done.
Uploading index.xml: [........] done.
Uploading sitemap.xml: [.] done.
Uploading index.html: [..] done.
sitecopy: Update completed successfully.

```

A process that took 8.3 seconds only :-)

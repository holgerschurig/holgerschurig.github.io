+++
title = "Blogging with Hugo"
categories = [ "Linux" ]
tags = [ "Hugo", "Blogging" ]
date = "2016-04-01"
description = "Describes how I make this blog and about the used theme."
+++

I wrote my home page with various tools ...

## Pure HTML

At the beginning, I used HTML and `.shtml` include files

Apache was told to process html include files, and I had the boilerplate and bottom in such
files and included them from the per-page HTML files.

## Webber

Later I switched to Webber. That was a python written open-source software that I published
on gitorious.org. The original gitorious is now down, but you find the git tree still at
https://gitorious.org/webber/webber, where an archive team resurrected the public git trees.

Webber has support for building "bread crumps" and menus at will. It
also had support for plugins. And it also was quite slow and almost
only used by myself.
  
## Pelican

Much better maintained, and because of the plugins more powerful is, of course, the python
based [Pelican](http://docs.getpelican.com/) static web site generator. I used for some time,
but only a few pages. Because then I detected ...


## Hugo

Hugo is blazingly fast, probably because it isn't written in some
interpreted, garbage collected language. 

However, compared to plugin-based static website generators it is more
limited. Some things, that should be easy, are more complex. Some
things are even impossible. And it's templating engine is nowhere near
as nice as [Jinja2](http://jinja.pocoo.org/docs/dev/), which is used
by both Pelican and Webber.

Equations in templates are especially annoying ... and surprising. For
example, you don't write

    {{if "/de/" in .URLPath.URL}}
	
but you have to write:

    {{if in "/de/" .URLPath.URL}}

It's a bit like Forth, just upside down. But then not really Forth,
because there are parenthesis there, too.

And still Hugo seems to suit my needs.


# Structure

I use my own
[theme](https://bitbucket.org/holgerschurig/hpg/src/b51e2a347bf841a9d36ed94940d9d5e60b8e6296/themes/my/?at=master),
which is based on Hugo's
[Blackburn](http://themes.gohugo.io/theme/blackburn/tags/hugo) theme.

I simplified the
[sidemenu.html](https://bitbucket.org/holgerschurig/hpg/src/HEAD/layouts/partials/sidemenu.html?at=master&fileviewer=file-view-default)
partial, massages the CSS a bit and simplified things. Blackburn's side-menu.css
mixes styling of the side-menu with styling of the block contents. I removed all of this and concentrated
the styling of my contents into
[themes/my/static/css/my.css](https://bitbucket.org/holgerschurig/hpg/src/HEAD/themes/my/static/css/my.css?at=master&fileviewer=file-view-default)


However, I want to have a bilingual site. So I decided to use two
[Hugo Types](https://gohugo.io/content/types/). One is named "de" for
german texts, the other one "en". Each type got it's own index page, see
[layouts/indexes/de.html](https://bitbucket.org/holgerschurig/hpg/src/HEAD/layouts/indexes/de.html?at=master&fileviewer=file-view-default)
and 
[layouts/indexes/en.html](https://bitbucket.org/holgerschurig/hpg/src/HEAD/layouts/indexes/en.html?at=master&fileviewer=file-view-default). And I wrote a main
[layouts/index.html](https://bitbucket.org/holgerschurig/hpg/src/HEAD/layouts/index.html?at=master&fileviewer=file-view-default) file 
that will show the newest 4 articles from each type.

## Writing

I write blog pages either with [Emacs][e]´ [markdown-mode][m]. Or I
[publish single subtrees][s] directly from my Emacs' configuration,
which happens to be stored in an [Org-Mode][o] file.

[e]: https://www.gnu.org/software/emacs/
[m]: http://jblevins.org/projects/markdown-mode/
[s]: {{< relref "en/emacs-blog-from-org-to-hugo.md" >}}
[o]: http://orgmode.org/

## Hosting

Together with my DSL account I have a home page at 1&1 internet. They provide me
FTP access. I use [sitecopy]({{< relref "en/blogging-with-sitecopy.md" >}}) to update
those pages.

# Hugo tricks

## HTML comments

Hugo normally eats all comments, but this code in a (full or partial)
template will render a HTML comment:

```none
{{"<!-- SOURCE: index.html //-->" | safeHTML}}
```

## Setting language code

I couldn't simply access the language code in my
[themes/my/layouts/partials/header.html](https://bitbucket.org/holgerschurig/hpg/src/HEAD/themes/my/layouts/partials/header.html?at=master&fileviewer=file-view-default)
partial. This generated error on pages like tags index.

And so reverted to parsing the URL and only switch the language code
to german if the path says so:

```none
<html lang="{{if in "/de/" .URLPath.URL}}de{{else}}en{{end}}">
```

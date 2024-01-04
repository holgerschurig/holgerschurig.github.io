+++
date = "2022-12-14T09:18:00+01:00"
title = "Comment static hugo blog entry with Mastodon"
tags = [ "hugo", "mastodon" ]
categories = [ "Linux" ]
keywords = [ "Hugo", "Mastodon", "Comments", "Replies" ]
mastodon = "109511208637436749"
+++

This post describes a simply method to link back from your static block page to Mastodon, so that
people can eventually reply.

<!--more-->

Today I stumbled about Carl Schwan's article [Adding comments to your static blog with Mastodon](https://carlschwan.eu/2020/12/29/adding-comments-to-your-static-blog-with-mastodon/). I liked the idea in general, but I wanted it much simpler.


Specify mastodon host
---------------------

First, I don't want to specify my maston host into every host. So this ends up in the `Params:` section
of my `config.yaml`:

```
params:
  ...
  mastodon: "https://emacs.ch/@holgerschurig"
```

One can access this then as `{{ .Site.Params }}`` in Hugo templates.


Mastodon toot ID
----------------
When I toot about one of my blog posts, the post will get a Mastodon ID. I just put
this ID into the header of my blog post.

```
+++
date = "2022-12-13T18:28:00+01:00"
title = "Sway: tweaks and (un)usual keybindings"
...
mastodon = "109508225564672703"
+++

```
This ID can then be accessed as `{{ .Params.mastodon }}`. Note the missing `.Site` compared to the previous
configuration.


Provide link to comments
------------------------

And second, I don't really want this load comments method and the simple HTML sanitation. Somehow
this seems to be security relevant, and I fear that this simple sanitation isn't bullet proof.

So I just add a link to my meta data section:

```
diff --git a/themes/my/layouts/partials/post_meta.html b/themes/my/layouts/partials/post_meta.html
index 7b6856b..36429fe 100644
--- a/themes/my/layouts/partials/post_meta.html
+++ b/themes/my/layouts/partials/post_meta.html
@@ -36,4 +36,11 @@
   {{ end }}
   {{ end }}

+  {{ if isset .Params "mastodon" }}
+  <div>
+    <i class="fa fa-reply fa-fw"></i>
+    <span><a href="{{ .Site.Params.mastodon }}/{{ .Params.mastodon }}" alt="Replay">Comments</a> on Mastodon</span>
+  </div>
+  {{ end }}
+
 </div>
```

Basically this places a reply icon (from Font Awesome) followed by the link. `{{
.Site.Params }} as seen above. Despite being simpler than Carl's approach, his
approach doesn't work for me because the URL ``<a class="button"
href="https://{{ .host }}/interact/{{ .id }}?type=reply">Reply</a>`` uses a URL
that doesn't work with emacs.ch. It doesn't give any reply on this interact URL.


Caveats
-------
Getting this up is a bit cumbersome:

* publish your blog on the internet
* use the URL to write a Mastodon toot pointing to your blog post
* fetch the mastodon ID of this post
* modify the frontmatter of your post
* republish your blog entry

Also, should you ever edit your original toot, then it will get a new ID. Under
the old ID you won't see a toot anymore. That means, that you'll have to update
your frontmatter again and republish.

If you can life with such a workflow, then you have now a nice privacy
respecting method for people to comment on your posts.


Outro
-----
And that's all, now people see a "Comments" link at the end of my post.

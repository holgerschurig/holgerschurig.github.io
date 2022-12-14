+++
title = "mastodon.el: a Hydra to memorize/access it's many commands"
date = "2022-12-13T11:57:00+01:00"
tags = [ "Emacs", "mastodon", "Hydra" ]
topics = [ "Emacs" ]
mastodon = "109506239141605308"
+++

Mastodon has a lot of commands. You can access most of them directly via keybindings, just use
`M-x describe-mode` or the `h` or `?` keys. Can you remember them all?

But, if you don't use Mastodon that regularly, maybe a Hydra can help you?

<!--more-->

Here as preview:

![img](./emacs-mastodon-hydra.png)

created with this Hydra:

```lisp
(defhydra mastodon-help (:color blue :hint nil)
  "
Timelines^^   Toots^^^^           Own Toots^^   Profiles^^      Users/Follows^^  Misc^^
^^-----------------^^^^--------------------^^----------^^-------------------^^------^^-----
_H_ome        _n_ext _p_rev       _r_eply       _A_uthors       follo_W_         _X_ lists
_L_ocal       _T_hread of toot^^  wri_t_e       user _P_rofile  _N_otifications  f_I_lter
_F_ederated   (un) _b_oost^^      _e_dit        ^^              _R_equests       _C_opy URL
fa_V_orites   (un) _f_avorite^^   _d_elete      _O_wn           su_G_estions     _S_earch
_#_ tagged    (un) p_i_n^^        ^^            _U_pdate own    _M_ute user      _h_elp
_@_ mentions  (un) boo_k_mark^^   show _E_dits  ^^              _B_lock user
boo_K_marks   _v_ote^^
trendin_g_
_u_pdate
"
  ("H" mastodon-tl--get-home-timeline)
  ("L" mastodon-tl--get-local-timeline)
  ("F" mastodon-tl--get-federated-timeline)
  ("V" mastodon-profile--view-favourites)
  ("#" mastodon-tl--get-tag-timeline)
  ("@" mastodon-notifications--get-mentions)
  ("K" mastodon-profile--view-bookmarks)
  ("g" mastodon-search--trending-tags)
  ("u" mastodon-tl--update :exit nil)

  ("n" mastodon-tl--goto-next-toot)
  ("p" mastodon-tl--goto-prev-toot)
  ("T" mastodon-tl--thread)
  ("b" mastodon-toot--toggle-boost :exit nil)
  ("f" mastodon-toot--toggle-favourite :exit nil)
  ("i" mastodon-toot--pin-toot-toggle :exit nil)
  ("k" mastodon-toot--bookmark-toot-toggle :exit nil)
  ("c" mastodon-tl--toggle-spoiler-text-in-toot)
  ("v" mastodon-tl--poll-vote)

  ("A" mastodon-profile--get-toot-author)
  ("P" mastodon-profile--show-user)
  ("O" mastodon-profile--my-profile)
  ("U" mastodon-profile--update-user-profile-note)

  ("W" mastodon-tl--follow-user)
  ("N" mastodon-notifications-get)
  ("R" mastodon-profile--view-follow-requests)
  ("G" mastodon-tl--get-follow-suggestions)
  ("M" mastodon-tl--mute-user)
  ("B" mastodon-tl--block-user)

  ("r" mastodon-toot--reply)
  ("t" mastodon-toot)
  ("e" mastodon-toot--edit-toot-at-point)
  ("d" mastodon-toot--delete-toot)
  ("E" mastodon-toot--view-toot-edits)

  ("I" mastodon-tl--view-filters)
  ("X" mastodon-tl--view-lists)
  ("C" mastodon-toot--copy-toot-url)
  ("S" mastodon-search--search-query)
  ("h" describe-mode)

  ("q" doom/escape))
```

I personally bound this to the `?` key. And since I'm using Doom with my [emacs
configuration](https://github.com/holgerschurig/emacs-doom-config/blob/master/config.el),
I do it the Doom way:

```lisp
(map! :map mastodon-mode-map
  "?" #'mastodon-help/body)
```

But you can of course just use the default Emacs way, e.g. with `(define-key ...)`.

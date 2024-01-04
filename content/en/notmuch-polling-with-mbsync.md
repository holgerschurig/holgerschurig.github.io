+++
title = "notmuch: polling mail with mbsync"
tags = [ "notmuch", "mbsync" ]
categories = [ "Linux" ]
date = "2016-05-02"
+++

In this blog post I describe how I configured `mbsync` 1.3.0 and
`notmuch` 0.22 so that they get my mail out of GMail's IMAP service.

<!--more-->

## Systemd units

I want to have systemd poll mail for me every our. As I disabled
per-user systemd services, I wrote the following two unit files for
the system systemd:

``` keepit
# /etc/systemd/system/mbsync.timer

[Unit]
Description=Mailbox synchronization timer

[Timer]
OnCalendar=*-*-* 00/1:00:00
Persistent=true
Unit=mbsync.service

[Install]
WantedBy=timers.target
```

and

``` keepit
# /etc/systemd/system/mbsync.service 

[Unit]
Description=Mailbox synchronization service

[Service]
Type=oneshot
ExecStart=/home/schurig/bin/pollmail.sh
User=schurig
```


## Propagate mail deletions

My Emacs notmuch client tags mails to be deleted with `+deleted`. And
this here deletes them for real. This is based on the
[Excluding](https://notmuchmail.org/excluding/) entry of the notmuch
wiki:


``` sh
propagate_deletions()
{
	local COUNT=`notmuch count tag:deleted`
	test "$COUNT" = 0 && return
	echo "- deleting $COUNT messages ..."
	notmuch search --format=text0 --output=files tag:deleted | xargs -0 --no-run-if-empty rm
}
```


## Get new mail

I used `offlineimap` for some time, but now I switched to `mbsync`
1.3.0 for it. I like it slighly better.

Because I don't want to only get new mails, but also "mangle" the mail
in defined ways, I wrote a `~/bin/pollmail.sh` helper script.

``` sh
sync_mail()
{
	local CHANNELS

	if [ -z "$*" ]; then
		CHANNELS=`awk '/^Channel/ { print $2; }' .mbsyncrc`
	else
		CHANNELS="$*"
	fi

	for i in $CHANNELS; do
		echo "- syncing mail in $i"
		mbsync $i
	done
}
```

There's a reason why I use the `mbsync <channel>` calling variant over
`mbsync <group>`. When mbsync takes a long time for syncing, I
wouldn't (in the group-version) not see where it uses up it's time.
But when iterating over the channels like above there is an echo for
each processed channel in the systemd journal.


## Ignoring uninteresting mail

I've written an extra blog entry about [this](/en/notmuch-mark-uninteresting).

## Binding it all together

The final part is the `getops`-based mini-logic of the script. It behaves like this:

* when I run it without any command line arguments it does all: delete mail, get
  new mail, import mail into notmuch, mark uninteresting
* calling it with `-d` only delete mails and then stops
* callit it with `-u` only marks uninteresing mail and then stops. I use this
  when I add new uninteresting terms.


``` sh
DO_STOP=false
while getopts "sud" opt; do
	case $opt in
		d)
			DO_STOP=true
			propagate_deletions
			;;
		u)
			DO_STOP=true
			mark_uninteresting
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			;;
	esac
done
test "$DO_STOP" == true && exit 0

shift $((OPTIND-1))


propagate_deletions
sync_mail "$*"
echo "- loading new mails into notmuch"
notmuch new
mark_uninteresting
```


## .mbsyncrc

This all works together with the following `~/.mbsyncrc` file:

## Storing state

``` keepit
# snippet from ~/.mbsyncrc

SyncState *
```

This makes `mbsync` store it's metadata in `.mail/*/.mbsyncstate`. We can in turn make notmuch
ignore this by adding this to `~/.notmuch-config`:

``` keepit
# snippet from ~/.notmuch-config

[new]
ignore=.uidvalidity;.mbsyncstate
```

Storing state in the subdirectory is nice because you can then simply
run `rm -rf ~/.mail/powertop` to get rid of the powertop mails
including their state.

## Speed, not reliability

As GMail is nice to save all of my e-mails in their data-centers, I don't need 
ultra reliability here. I always can re-create the mails if in need.

``` keepit
# snippet from ~/.mbsyncrc

Fsync no
```

## Default settings for all channels

``` keepit
# snippet from ~/.mbsyncrc

CopyArrivalDate yes
Create Slave
Sync All
Expunge Both
```

* `CopyArrivalDate` is an attempt to keep the time-stamp based sorting intact
* `Create` makes sure that mbsync will automatically create
  `~/.mail/$channelname` if not already present
* `Sync` makes sure that all IMAP attributes will be synchronized
* `Expunge` makes sure that removed local files in the Maildir folder
  will be removed from IMAP as well ... and vica verca

## IMAP account

```
# snippet from ~/.mbsyncrc

IMAPAccount gmail
	Host imap.gmail.com
	User holgerschurig@gmail.com
	PassCmd "awk -F '\"' '/imap/ { print $2 }' ~/.authinfo"
	SSLType IMAPS
	CertificateFile /etc/ssl/certs/ca-certificates.crt
```

The above line works because I have an `~/.authinfo` file that roughly looks like this:

``` keepit
# ~/.authinfo

machine imap.gmail.com login holgerschurig@gmail.com password "secret" port imaps
machine smtp.gmail.com login holgerschurig@gmail.com password "secret" port 587
```

That's a remnant from the times where I used GNUS for e-mail. But as it's still there,
let's re-use it.


## Mail stores

``` keepit
# snippet from ~/.mbsyncrc

MaildirStore local
	Subfolders Verbatim
	Path /home/schurig/.mail/
	Inbox /home/schurig/.mail/INBOX
	Trash /home/schurig/.mail/trash

IMAPStore remote
	Account gmail
```

## Channels

One channel, "trash", needs special treatment. Because this because Google Mail
exposes localized names into their IMAP folder names. I need to rename this:

``` keepit
# snippet from ~/.mbsyncrc

Channel trash
	Master :remote:"[Google Mail]/Papierkorb"
	Slave  :local:trash
```

All the other channels are straightforward:

``` keepit
# snippet from ~/.mbsyncrc

Channel inbox
	Master :remote:INBOX
	Slave  :local:INBOX

Channel ath9k-devel
	Master :remote:ath9k-devel
	Slave  :local:ath9k-devel

Channel barebox
	Master :remote:barebox
	Slave  :local:barebox

Channel darc-sdr
	Master :remote:darc-sdr
	Slave  :local:darc-sdr

Channel elecraft
	Master :remote:elecraft
	Slave  :local:elecraft

Channel linux-can
	Master :remote:linux-can
	Slave  :local:linux-can

Channel linux-arm-kernel
	Master :remote:linux-arm-kernel
	Slave  :local:linux-arm-kernel

Channel linux-mmc
	Master :remote:linux-mmc
	Slave  :local:linux-mmc

Channel powertop
	Master :remote:powertop
	Slave  :local:powertop
```

## Group section

Note that we don't need any `Group gmail` section. We could have, but
as `~/bin/pollmail.sh` iterates over the Channels anyway, there's no
need for one.

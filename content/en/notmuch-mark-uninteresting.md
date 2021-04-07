+++
title = "notmuch: automatically mark uninteresting mails as read"
tags = [ "notmuch" ]
topics = [ "Linux" ]
date = "2016-05-02"
+++

Now that I switched from Emacs' `GNUS` to Emacs' `notmuch`, I needed a
method to automatically "discard" uninteresting mails. In some Linux
mailing lists a huge amount of mails are about topics that I don't
care. So I a little shell script `bin/pollmail.sh` that polls
the mails and efficiently marks uninteresting stuff as read.

<!--more-->

## Prepare notmuch

But first, have a look at a snipped from `~/.notmuch-config`:

``` keepit
[new]
tags=unread
```

This makes `notmuch` tak all newly imported mails with the tag '+unread'.

## How to tag based on a filer

When I filter messages, obviously I only need to filter such mails. So I
could do

``` keepit
holger@holger$ notmuch tag -unread -- tag:unread (subject:boring or subject:moreboring)
```

That would even work... if I hadn't so many subjects that don't
interest me with the type of embedded hardware that I use: ARM64,
Allwinner, Rockchip, KVM, kexec, PCI, PCIe ... ... ...   more than
100 topics are of no interest to me.

Clearly the command line would get too long.

## Using notmuch tag \-\-batch

But wait, there's `notmuch tag --batch` available, so we can use that.

### Prepare list of uninteresting terms ...

But first, let's define the topics for the various mailing lists that
I don't care about. This is an expert from what I tend to ignore on
the linux-arm-kernel mailing list:

``` sh
#!/bin/bash

read -r -d '\n' UNINTERESTING_LKA <<'EOF'
#
#Subsystems
#
acpi
arm64
dmaengine
kexec
kvm
mdio
mtd
pci*
spi-nor
vdma
```
...
``` sh
moxart
tango*
EOF
```

I could have written the assignment of the uninteresting topics to `$UNINTERESTING_LKA`
also more traditionally:

``` sh
UNINTERESTING_LKA+="acpi "
UNINTERESTING_LKA+="arm64 "
```

But I like the above method more, less typing involved.

### ... create a query from it ...

The following now creates a query inside a temporary file and asks
notmuch to execute the tag command with it. Because the search
runs only on unread mails, it's actually quite fast. Despite the
fact that I have now around 100 uninteresting terms.

``` sh
mark_uninteresting_do()
{
        echo "- marking uninteresting in $1"
        local i
        echo -n "-unread -- " >/tmp/notmuch.$$
        echo -n "tag:unread " >>/tmp/notmuch.$$
        echo -n "folder:$1 (subject:grumblfutz" >>/tmp/notmuch.$$
        for i in $2; do
                test ${i:0:1} == "#" && continue
                # echo "i:$i"
                echo -n " OR subject:$i" >> /tmp/notmuch.$$
        done
        echo ")" >> /tmp/notmuch.$$
        # cat /tmp/notmuch.$$
        notmuch tag --batch </tmp/notmuch.$$
        rm -f /tmp/notmuch.$$
}
```

### ... and apply everything

The code that runs this is actually simple:

``` sh
mark_uninteresting()
{
        mark_uninteresting_do linux-arm-kernel "$UNINTERESTING_LKA"
        mark_uninteresting_do linux-mmc        "$UNINTERESTING_MMC"
        mark_uninteresting_do linux-can        "$UNINTERESTING_CAN"
}
```

+++
title = "Zephyr: fixing LSP issues"
author = ["Holger Schurig"]
date = 2024-01-04
tags = ["zephyr", "make", "lsp", "clangd"]
categories = ["embedded"]
draft = false
+++

Zephyr uses command-line arguments for GCC that the clangd LSP server doesn't <br/>
understand. Here I present one approach how to fix this. <br/>

<!--more-->

<div class="ox-hugo-toc toc">

<div class="heading">Table of Contents</div>

- [What is LSP?](#what-is-lsp)
- [Enable LSP](#enable-lsp)
- [Use LSP in your editor](#use-lsp-in-your-editor)
- [Observing the first errors](#observing-the-first-errors)
- [Fixing these errors](#fixing-these-errors)

</div>
<!--endtoc-->


## What is LSP? {#what-is-lsp}

[LSP](https://en.wikipedia.org/wiki/Language_Server_Protocol) stands for "Language Server Protocol", a JSON based protocol where a tool <br/>
(e.g. a compiler) can tell an editor about language specific things **while** <br/>
editing, i.E. without an extra compilation step. It's also used for completion <br/>
of variable / function / method / type names in the editor. Or for <br/>
cross-references. As a real compiler looks at the code, it's quite precise. It <br/>
can achive much more insight into the code than using only parsing (e.g. <br/>
directly in the editor). <br/>


## Enable LSP {#enable-lsp}

Out of the box, Zephyr doesn't support LSP, but it's easy enough to add. When <br/>
configuring for a board, you only need to ask CMake to create a compilation database: <br/>

```text { linenos=true, anchorlinenos=true, lineanchors=org-coderef--83b8fb }
west build \
	--pristine \
	-b nucleo_f303re \
	-o "build.ninja" \
	-- \
	-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
	-DOVERLAY_CONFIG="nucleo_f303re.conf"
```

Here in line [BROKEN LINK: ref:cdb] we do exactly that. Once you've compiled your project <br/>
normally, you'll now have such a compilation database in the "`build/`" <br/>
directory: <br/>

```text
~/src/multi-board-zephyr$ ls -l build/compile_commands.json
-rw-r--r-- 1 holger holger 145793 Jan  5 08:40 build/compile_commands.json
```

This compilation database contains the exact set of source files that would be <br/>
compiled, as well as the full set of compiler command-line arguments for each <br/>
file. Therefore, an LSP daemon doesn't have to parse e.g. Makefile, meson.build, <br/>
the many CMake files etc etc etc. It just looks at this one formalized database. <br/>


## Use LSP in your editor {#use-lsp-in-your-editor}

Since there are hundreds of editors out there, this is really beyond the scope <br/>
of this blog. <br/>

I personally use Emacs, and there are two options: lsp-mod and eglot. I use the latter. <br/>

On Linux, a good LSP server is [clangd](https://clangd.llvm.org/). I currently use clangd-15, so I tell eglot about it: <br/>

```elisp
  (add-to-list 'eglot-server-programs '(c-mode  .  ("clangd-15" "-j=2" "--clang-tidy")))
  (add-to-list 'eglot-server-programs '(c++-mode . ("clangd-15" "-j=2" "--clang-tidy")))
```


## Observing the first errors {#observing-the-first-errors}

... but oh no, even a miniature project already shows an error: <br/>

{{< figure src="/ox-hugo/2024-01-05_226x23.png" >}} <br/>

Note the "!!" in the left fringe. <br/>

But what are these errors? <br/>

{{< figure src="/ox-hugo/2024-01-05_733x74.png" >}} <br/>

It turns out that Zephyr uses some command line options that the GCC Compiler <br/>
understands. The CLANG compiler (when compiling) ignores them. But when we use <br/>
CLANG\*D\* (the daemon), this will be flagged as an error. <br/>


## Fixing these errors {#fixing-these-errors}

Now, clangd takes all of the command line arguments from the compilation <br/>
database. So after configuring, we simply modify the compilation database <br/>
directly. So we define a Makefile target for this: <br/>

```text
.PHONY:: fix_lsp_compilation_database
fix_lsp_compilation_database:
	sed -i 's/--param=min-pagesize=0//g' build/compile_commands.json
	sed -i 's/--specs=picolibc.specs//g' build/compile_commands.json
	sed -i 's/-fno-defer-pop//g' build/compile_commands.json
	sed -i 's/-fno-freestanding//g' build/compile_commands.json
	sed -i 's/-fno-printf-return-value//g' build/compile_commands.json
	sed -i 's/-fno-reorder-functions//g' build/compile_commands.json
	sed -i 's/-mfp16-format=ieee//g' build/compile_commands.json
```

and call it directly after we configured for a specific board: <br/>

```text { linenos=true, anchorlinenos=true, lineanchors=org-coderef--b77306 }
local: .west/config
	west build \
		--pristine \
		-b local \
		-o "build.ninja" \
		-- \
		-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
		-DOVERLAY_CONFIG="boards/arm/local/local_defconfig" \
		-DBOARD_ROOT=.
	$(MAKE) --no-print-directory fix_lsp_compilation_database
	west build
```

like this is done here in line [10](#org-coderef--b77306-10). <br/>


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
- [Use LSP in Emacs](#use-lsp-in-emacs)
- [Observing the first errors](#observing-the-first-errors)
- [Fixing these errors](#fixing-these-errors)

</div>
<!--endtoc-->


## What is LSP? {#what-is-lsp}

[LSP](https://en.wikipedia.org/wiki/Language_Server_Protocol) stands for "Language Server Protocol", a JSON-based protocol that allows <br/>
tools to communicate with editors about language-specific information while <br/>
editing. This provides more precise insight into the code than just parsing, and <br/>
enables features like completion of variable/function/method/type names, <br/>
cross-references, and other advanced functionalities. LSP is widely used in <br/>
modern software development workflows. <br/>


## Enable LSP {#enable-lsp}

Out of the box, Zephyr doesn't support LSP, but it's easy enough to add. When <br/>
configuring for a board, you only need to ask CMake to create a compilation <br/>
database. <br/>

```text { linenos=true, anchorlinenos=true, lineanchors=org-coderef--83b8fb }
west build \
	--pristine \
	-b nucleo_f303re \
	-o "build.ninja" \
	-- \
	-DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
	-DOVERLAY_CONFIG="nucleo_f303re.conf"
```

In line [BROKEN LINK: ref:cdb], we exactly do that. Once you've compiled your project <br/>
normally, you will now have such a compilation database in the "build/" <br/>
directory. <br/>

```text
~/src/multi-board-zephyr$ ls -l build/compile_commands.json
-rw-r--r-- 1 holger holger 145793 Jan  5 08:40 build/compile_commands.json
```

This compilation database contains the exact set of source files that would be <br/>
compiled, along with the full set of compiler command-line arguments for each <br/>
file. As a result, an LSP daemon doesn't have to parse e.g., Makefile, <br/>
meson.build, CMake files, etc. It simply looks at this one formalized database. <br/>


## Use LSP in Emacs {#use-lsp-in-emacs}

On Linux, a good C/C++ LSP server is [clangd](https://clangd.llvm.org/). I currently use clangd-15, so I <br/>
tell Emacs / eglot about it: <br/>

```elisp
  (add-to-list 'eglot-server-programs '(c-mode  .  ("clangd-15" "-j=2" "--clang-tidy")))
  (add-to-list 'eglot-server-programs '(c++-mode . ("clangd-15" "-j=2" "--clang-tidy")))
```


## Observing the first errors {#observing-the-first-errors}

Now all is fine, I can start eglot ("`M-x eglot`"). All is well! <br/>

... but oh no, even a miniature project already shows an error: <br/>

{{< figure src="/ox-hugo/2024-01-05_226x23.png" >}} <br/>

Note the "!!" in the left fringe. <br/>

But what are these errors? <br/>

{{< figure src="/ox-hugo/2024-01-05_733x74.png" >}} <br/>

It turns out that Zephyr uses some command-line options that the GCC Compiler <br/>
doesn't understand. The CLANG compiler (when compiling) ignores them. But not <br/>
the CLANGD language server. That one will bark about the not understood <br/>
command-line options. <br/>

In effect, you'll see errors in any of your source files. However, in reality, <br/>
there aren't any errors present. <br/>


## Fixing these errors {#fixing-these-errors}

Now, clangd takes all of the command-line arguments from the compilation <br/>
database. So after configuring, we simply modify the compilation database <br/>
directly. Therefore, we define a Makefile target for this: <br/>

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


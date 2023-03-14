# pd-remote

pd-remote is a remote-control and live-coding utility for [Pd](http://puredata.info/) and the [Emacs](https://en.wikipedia.org/wiki/GNU_Emacs) text editor. It takes the form of a Pd abstraction pd-remote.pd and an accompanying pd-remote.el elisp file for Emacs.

- pd-remote.pd goes into your Pd patches that you want to control remotely via Pd messages sent over UDP port 4711. These messages can be sent over the local network with the pdsend program, or you can pass messages directly into the inlet of the abstraction for testing purposes.

- pd-remote.el provides the necessary hooks to send messages to pd-remote.pd via pdsend from Emacs. It also includes built-in support for [pd-lua](https://github.com/agraef/pd-lua) and [pd-faustgen2](https://github.com/agraef/pd-faustgen), and adds some convenient commands and keybindings for lua-mode and faust-mode, both available from [MELPA](https://melpa.org).

**VS Code users:** Baris Altun has created an alternative [Visual Studio Code](https://code.visualstudio.com/) version which utilizes the same interface and can be used as a replacement for pd-remote.el if you're so inclined. Baris' extension is available in Microsoft's extension marketplace (just go to VS Code's extension manager and search for [pd-remote](https://marketplace.visualstudio.com/items?itemName=barisssss.pd-remote-vscode)). Please check the notes [below](#using-pd-remote-with-vs-code), and see [Baris' repository](https://github.com/barisssss/pdRemoteVscode) for details and installation instructions. Thanks, Baris!

Note that pd-remote is a simplified and unified version of the Pd remote control helpers that I've been distributing with various Pd externals such as [pd-faust](https://github.com/agraef/pure-lang/tree/master/pd-faust) and [pd-lua](https://github.com/agraef/pd-lua) over the years. It's also important to note that pd-remote.pd is a very simple abstraction without any built-in "application logic" of its own. Its sole purpose is to receive Pd messages over the network and dispatch those messages to the given receivers. You still have to set up those receivers in your patch as needed to implement the intended application logic. But in the case of pd-lua or pd-faustgen2, the receivers are already there for reloading source programs on the fly. This is pd-remote's primary purpose and is also known as [live-coding](https://en.wikipedia.org/wiki/Live_coding), please check the [live-coding section](https://agraef.github.io/pd-lua/tutorial/pd-lua-intro.html#remote-control) of the pd-lua tutorial for details.

## Installation

### Install pd-remote.pd

There's a pdlibbuilder-based Makefile with which you can install the abstraction and the accompanying examples for system-wide use in the usual way (`make install` will usually do the trick). But there's really no need to install the abstraction at all, you can also just drop it into the directory with the patches you want to use it in.

### Install pd-remote.el

The **easy** way: Install it from [MELPA](https://melpa.org/). (You can also open pd-remote.el in Emacs and run (Alt+x) `package-install-from-buffer`.)

The **hard** way: Copy pd-remote.el to some place on your Emacs load-path, and make sure that you have both faust-mode and lua-mode installed as well.

Either way, to finish the installation you need to add these lines to your .emacs:

~~~lisp
(require 'pd-remote)
(add-hook 'faust-mode-hook #'pd-remote-mode)
(add-hook 'lua-mode-hook #'pd-remote-mode)
~~~

This also loads Faust and Lua mode and enables some convenient keybindings in these modes. Alternatively, you can also omit the hooks and define a global keybinding to toggle the pd-remote-mode minor mode when you need it:

~~~lisp
(require 'pd-remote)
(global-set-key "\C-c\C-p" #'pd-remote-mode)
~~~

## Usage

pd-remote hooks into faust-mode and lua-mode by activating the pd-remote-mode minor mode (indicated by "Pd" in the Emacs mode line) which offers some convenient keybindings, listed below. Most of these commands are also available as interactive elisp functions under the pd-remote prefix, such as pd-remote-message which can be used to send any message to Pd.

The most common use for pd-remote is to tell Pd when to reload or recompile Lua and Faust objects, for which there is the keyboard shortcut C-C C-K (i.e., Ctrl+C Ctrl+K). This sends the reload or compile message to the pdluax and faustgen2~ receivers, respectively, depending on which kind of file you're editing in Emacs.

- To make this work for Lua objects, some preparation is needed, as described in the [live-coding section](https://agraef.github.io/pd-lua/tutorial/pd-lua-intro.html#remote-control) of the pd-lua tutorial. For Faust programs this should work out of the box, just adding pd-remote to the patch is enough.

- In either case, at present pd-remote simply reloads *all* corresponding objects, not just objects that have actually been edited. In a future version, we may hopefully be more clever about this.

Here is a complete list of the available keybindings, along with the corresponding elisp commands if available.

| Keybinding | Message Sent                          | Command                |
| ---------- | ------------------------------------- | ---------------------- |
| C-C C-K    | Compile/Reload                        | pd-remote-compile      |
| C-C C-M    | Prompts for a message to be sent      | pd-remote-message      |
| C-C C-Q    | Stop pdsend                           | pd-remote-stop-process |
| C-C C-S    | Start (`play 1`)                      |                        |
| C-C C-T    | Stop (`play 0`)                       |                        |
| C-C C-R    | Restart (send `play 0` then `play 1`) |                        |
| C-/        | DSP on (`pd dsp 1`)                   | pd-remote-dsp-on       |
| C-.        | DSP off (`pd dsp 0`)                  | pd-remote-dsp-off      |

You can change any of these bindings in pd-remote.el as needed/wanted, and you can add pretty much any Pd message there, as long as it starts with a symbol for a receiver in your patch. In the same vein, you can also enable pd-remote-mode in any major mode that you use in conjunction with Pd, with a line like this:

~~~lisp
(add-hook 'foo-mode-hook #'pd-remote-mode)
~~~

In fact, it may be useful to add the DSP on/off messages to your *global* keybindings, too, so that they work everywhere:

~~~lisp
(global-set-key [(control ?\/)] #'pd-remote-dsp-on)
(global-set-key [(control ?\.)] #'pd-remote-dsp-off)
~~~

You can either put these lines into your local copy of pd-remote.el, or just add them to your .emacs.

Also, note that C-C C-M will prompt you for a message to be sent, so you can send *any* message to Pd that way. Messages are sent using the pdsend program. The pdsend process is started automatically when you first send a message during an Emacs session, and will normally continue to run until you exit Emacs. You can also stop a running pdsend process at any time with C-C C-Q. If you send another message afterwards, a new pdsend process will be started automatically.

## Customization

Two customization variables are defined in the `pd-remote` customization group (which is located in Emacs' `multimedia` group):

- `pd-remote-pdsend`: Name of the pdsend executable. Normally this is just `"pdsend"`, but you may have to change this to the absolute pathname of the executable if it isn't on the system PATH (in which case Emacs will complain that it can't find the executable).
- `pd-remote-port`: UDP port number (`"4711"` by default). Note that this number is also hard-coded into the pd-remote.pd abstraction. If you have to change the port number for some reason, then you also have to edit the abstraction accordingly.

Note that changes to these will not affect a running pdsend process, so you will need to restart it (C-C C-Q).

## Troubleshooting

If communication between Emacs and Pd fails to work, here are some things to watch out for:

- Make sure that the "Pd" minor mode is enabled in the current Emacs buffer. This should normally be the case in faust-mode and lua-mode buffers if the appropriate hooks are defined. Otherwise the minor mode can be toggled on and off with the (Alt+x) `pd-remote-mode` command, in order to enable the pd-remote keybindings in the current buffer.

- The pdsend program needs to be installed and on the PATH. This program usually accompanies the different Pd flavors but may not always be on the PATH, so you may have to either copy it to a directory on your PATH, modify your PATH accordingly, or edit the `pd-remote-pdsend` customization variable (see above) to supply the absolute path under which pdsend can be found.

- pd-remote.pd needs to be loaded on the Pd side. Usually you will include it as an abstraction in the Pd patch that you're working with, but if that isn't possible then you can also just open the pd-remote.pd patch itself in Pd.

- pd-remote.pd uses Pd's `netreceive`. Only a single instance of this object can be listening on a given port at any time. Thus, if you use multiple instances of pd-remote.pd, you may see the error message `netreceive: listen failed: Address already in use`, and only one of the instances will actually be active. Incidentally, this also prevents a received message to be dispatched more than once, which is a good thing. On the other hand, if you happen to close the patch containing the active pd-remote instance, the connection to Emacs will be lost until you re-create a new pd-remote instance (or reopen one of the other patches containing such an instance).

- Recall that if you change the UDP port number in the `pd-remote-port` customization variable (see above), you'll also have to change pd-remote.pd accordingly.

- The same limitations also apply to the VS Code version of pd-remote. Baris' extension also provides some configuration parameters which let you change the pdsend pathname and the UDP port number if needed.

## Examples

I've included some examples from the [pd-lua](https://github.com/agraef/pd-lua) and [pd-faustgen2](https://github.com/agraef/pd-faustgen) distributions in the examples subdirectory for your perusal. Note that you need to have these externals installed to make the examples work. In the sample patches, right-click on the Lua or Faust objects to open them in Emacs (this assumes that Emacs is your default text editor), or open them directly in Emacs using your file manager or the command line.

You can then change the Lua script or Faust program, as described in the pd-lua or pd-faustgen2 documentation. When you've saved your changes, just press C-C C-K in Emacs to have the objects reload the corresponding source in the Pd patch. This works even as the patch keeps running, although you may notice some hiccups in the audio or control processing while the programs are reloaded. (Note: This may look like Emacs somehow submits the edited program to the Pd patch, but it merely sends a message via pd-remote which makes the objects themselves reload their source files.)

### Using pd-remote with VS Code

The same workflow can be employed with Baris' [VS Code version](https://github.com/barisssss/pdRemoteVscode) of pd-remote mentioned above which offers the same keybindings by default. In this case you'd usually want to configure VS Code as your default text editor. Emacs has a steep learning curve, so if you're not familiar with it, or just prefer a modern-style editing environment, you may find VS Code easier to use.

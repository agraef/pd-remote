# pd-remote

This is a simplified and unified version of the Pd remote control helpers that I've been distributing with various Pd externals such as [pd-faust](https://github.com/agraef/pure-lang/tree/master/pd-faust) and [pd-lua](https://github.com/agraef/pd-lua) over the years. The present implementation will work with any of these and replaces the more specialized versions. It takes the form of a Pd abstraction pd-remote.pd and an accompanying pd-remote.el elisp file for Emacs.

- pd-remote.pd goes into your Pd patches that you want to control remotely via Pd messages sent over UDP port 4711. These messages can be sent over the local network with the pdsend program, or you can pass messages directly into the inlet of the abstraction for testing purposes.

- pd-remote.el provides the necessary hooks to send messages to pd-remote.pd via pdsend from the [Emacs](https://en.wikipedia.org/wiki/GNU_Emacs) text editor. It also includes built-in support for pd-lua and [pd-faustgen2](https://github.com/agraef/pd-faustgen) (which has since replaced pd-faust), and adds some convenient keybindings for lua-mode and faust-mode, both available from [MELPA](https://melpa.org).

**VS Code users:** There's no need to despair any more if you are not keen on learning Emacs. Baris Altun has created a [Visual Studio Code](https://code.visualstudio.com/) version of pd-remote which utilizes the same interface and can be used as a replacement for pd-remote.el if you're so inclined. Baris' extension is available in Microsoft's extension marketplace (just go to VS Code's extension manager and search for pd-remote). Please check the notes [below](#using-pd-remote-with-vs-code), and see [Baris' repository](https://github.com/barisssss/pdRemoteVscode) for details and installation instructions. Thanks, Baris!

Also note that pd-remote.pd is really a very simple abstraction which merely receives Pd messages of the form `symbol atoms ...` either from its inlet or via netreceive, and dispatches each message to the given receiver symbol at the front of the message, that's all. You still have to set up the corresponding receivers in your patch as needed. But in the case of pd-lua or pd-faustgen2 objects, the receivers are already there for reloading source programs, which is pd-remote's primary purpose.

## Installation

### Install pd-remote.pd

There's a pdlibbuilder-based Makefile with which you can install the abstraction and the accompanying examples for system-wide use in the usual way (`make install` will usually do the trick). But there's really no need to install the abstraction at all, you can also just drop it into the directory with the patches you want to use it in.

### Install pd-remote.el

- The **easy** way: Install it from [MELPA](https://melpa.org/) (currently WIP, check back later). Or open pd-remote.el in Emacs and run (Alt+x) `package-install-from-buffer`.
- The **hard** way: Copy pd-remote.el to some place on your Emacs load-path. (There's really no good reason to do it that way any more, unless you want to avoid Emacs' built-in package management system for some reason.)

Either way, make sure that you also have both lua-mode and faust-mode installed, they're both available from MELPA. Then add this line to your .emacs:

~~~lisp
(require 'pd-remote)
~~~

This also autoloads Faust and Lua mode and adds some convenient keybindings. You can also change these as needed by editing your local copy of pd-remote.el in ~/.emacs.d accordingly.

#### Notes for Emacs newbies

The Emacs [load-path](https://www.emacswiki.org/emacs/LoadPath) usually includes places like /usr/share/emacs/site-lisp for a system-wide, and/or some places in ~/.emacs.d for personal installation. If you're using Emacs' built-in package management commands, then all this will be taken care of for you. But if you prefer manual installation, you may want to put this into your .emacs to make sure that ~/.emacs.d/lisp is searched for elisp files:

~~~lisp
(add-to-list 'load-path "~/.emacs.d/lisp/")
~~~

Then create ~/.emacs.d/lisp if necessary and copy pd-remote.el to that directory.

## Usage

The most common use for pd-remote is to tell Pd when to reload or recompile Lua and Faust objects, for which there is a common keyboard shortcut in both Lua and Faust mode, C-C C-K (i.e., Ctrl+C Ctrl+K). This sends the reload or compile message to the pdluax and faustgen2~ receivers, respectively, depending on which kind of file you're editing in Emacs.

- To make this work for Lua objects, some preparation is needed, as described in the [live-coding section](https://agraef.github.io/pd-lua/tutorial/pd-lua-intro.html#remote-control) of the pd-lua tutorial. For Faust programs this should work out of the box, just adding pd-remote to the patch is enough.

- In either case, at present pd-remote simply reloads *all* corresponding objects, not just objects that have actually been edited. In a future version, we may hopefully be more clever about this.

Both modes also offer the following special keybindings:

| Keybinding | Message Sent                            |
| ---------- | --------------------------------------- |
| C-C C-M    | Prompts for a message to send to Pd     |
| C-C C-S    | Start (sends a `play 1` message)        |
| C-C C-T    | Stop (sends a `play 0` message)         |
| C-C C-R    | Restart (sends `play 0,` then `play 1`) |
| C-/        | DSP on (`pd dsp 1`)                     |
| C-.        | DSP off (`pd dsp 0`)                    |

Please note that these are really just examples. You can change any of these bindings in both lua-mode and faust-mode as needed/wanted, and you can add pretty much any Pd message there, as long as it starts with a symbol for a receiver in your patch. In the same vein, you can easily add pd-remote support to any Emacs mode that you use in conjunction with Pd, as long as there is some receiver on the Pd side which processes the Pd messages you want to send.

In fact, the DSP on/off messages are not just useful in Faust and Lua mode, so you may want to add them to your *global* keybindings, too:

~~~lisp
(global-set-key [(control ?\/)] #'pd-dsp-on)
(global-set-key [(control ?\.)] #'pd-dsp-off)
~~~

You can either put these lines into your local copy of pd-remote.el, or just add them to your .emacs.

## Troubleshooting

If communication between Emacs and Pd fails to work, here are some things to watch out for:

- The pdsend program needs to be installed and on the PATH. This program usually accompanies the different Pd flavors but may not always be on the PATH, so you may have to either copy it to a directory on your PATH, modify your PATH accordingly, or edit pd-remote.el to supply the absolute path under which pdsend can be found.

- pd-remote.pd needs to be loaded on the Pd side. Usually you will include it as an abstraction in the Pd patch that you're working with, but if that isn't possible then you can also just open the pd-remote.pd patch itself in Pd.

- pd-remote.pd uses Pd's `netreceive` which can only listen on a given port in a single instance. Thus, if you use multiple instances of pd-remote.pd, you may see the error message `netreceive: listen failed: Address already in use`, and only one of the instances will actually be active at any one time. Incidentally, this also prevents a received message to be dispatched more than once, which is a good thing. On the other hand, if you happen to close the patch containing the active pd-remote instance, the connection to Emacs will be lost until you re-create a new pd-remote instance (or reopen one of the other patches containing such an instance).

- If you change the UDP port number in pd-remote.el, you'll have to change pd-remote.pd accordingly.

- The same limitations also apply to the VS Code version of pd-remote. However, Baris' extension also provides some convenient configuration parameters which let you change the pdsend pathname and the UDP port number without having to edit the code of the extension.

## Examples

I've included some examples from the pd-lua and pd-faustgen2 distributions in the examples subdirectory for your perusal. In the sample patches, right-click on the Lua or Faust objects to open them in Emacs (this assumes that Emacs is your default text editor), or open them directly in Emacs using your file manager or the command line.

You can then change the Lua script or Faust program, as described in the pd-lua or pd-faustgen2 documentation. When you've saved your changes, just press C-C C-K in Emacs to have the objects reload the corresponding source in the Pd patch. This works even as the patch keeps running, although you may notice some hiccups in the audio or control processing while the programs are reloaded. (Note: This may look like Emacs somehow submits the edited program to the Pd patch, but it merely sends a message via pd-remote which makes the objects themselves reload their source files.)

### Using pd-remote with VS Code

The same workflow can be employed with Baris' [VS Code version](https://github.com/barisssss/pdRemoteVscode) of pd-remote mentioned above which offers the same keybindings by default. In this case you'd usually want to configure VS Code as your default text editor. Emacs has a steep learning curve, so if you're not familiar with it, or just prefer a modern-style editing environment, VS Code will be the better choice.

## Future Work

- Add some configuration variables to pd-remote.el (e.g., key bindings, UDP port number, and pdsend pathname), to mirror what's available in the VS Code version.
- Try to be more clever about which objects to reload after edits. This will require changes in pd-lua and pd-faustgen2 and a fair deal of bidirectional communication between Pd and Emacs (or VS Code) in order to figure out which objects need to be reloaded, and under what receive symbols they can be told to do so.

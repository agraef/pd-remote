# pd-remote

pd-remote is a remote-control and live-coding utility for [Pd](http://puredata.info/) and the [Emacs](https://en.wikipedia.org/wiki/GNU_Emacs) text editor. It takes the form of a Pd abstraction pd-remote.pd and an accompanying pd-remote.el elisp file for Emacs.

- pd-remote.pd goes into your Pd patches that you want to control remotely via Pd messages sent over UDP port 4711. These messages can be sent over the local network with the pdsend program, or you can pass messages directly into the inlet of the abstraction for testing purposes.

- pd-remote.el provides the necessary hooks to send messages to pd-remote.pd via pdsend from Emacs. It also includes built-in support for [pd-lua](https://github.com/agraef/pd-lua) and [pd-faustgen2](https://github.com/agraef/pd-faustgen), and adds some convenient keybindings for lua-mode and faust-mode, both available from [MELPA](https://melpa.org).

**VS Code users:** Baris Altun has created an alternative [Visual Studio Code](https://code.visualstudio.com/) version which utilizes the same interface and can be used as a replacement for pd-remote.el if you're so inclined. Baris' extension is available in Microsoft's extension marketplace (just go to VS Code's extension manager and search for [pd-remote](https://marketplace.visualstudio.com/items?itemName=barisssss.pd-remote-vscode)). Please check the notes [below](#using-pd-remote-with-vs-code), and see [Baris' repository](https://github.com/barisssss/pdRemoteVscode) for details and installation instructions. Thanks, Baris!

Note that pd-remote is a simplified and unified version of the Pd remote control helpers that I've been distributing with various Pd externals such as [pd-faust](https://github.com/agraef/pure-lang/tree/master/pd-faust) and [pd-lua](https://github.com/agraef/pd-lua) over the years. It's also important to note that pd-remote.pd is a very simple abstraction without any built-in "application logic" of its own. Its sole purpose is to receive Pd messages over the network and dispatch those messages to the given receivers. You still have to set up those receivers in your patch as needed to implement the intended application logic. But in the case of pd-lua or pd-faustgen2, the receivers are already there for reloading source programs on the fly. This is pd-remote's primary purpose and is also known as [live-coding](https://en.wikipedia.org/wiki/Live_coding), please check the [live-coding section](https://agraef.github.io/pd-lua/tutorial/pd-lua-intro.html#remote-control) of the pd-lua tutorial for details.

## Installation

### Install pd-remote.pd

There's a pdlibbuilder-based Makefile with which you can install the abstraction and the accompanying examples for system-wide use in the usual way (`make install` will usually do the trick). But there's really no need to install the abstraction at all, you can also just drop it into the directory with the patches you want to use it in.

### Install pd-remote.el

The **easy** way: Install it from [MELPA](https://melpa.org/). (Submission currently pending, please check back later. For the time being, open pd-remote.el in Emacs and run (Alt+x) `package-install-from-buffer`.)

The **hard** way: Copy pd-remote.el to some place on your Emacs load-path. (See the notes below if needed.)

Either way, to finish the installation you need to add this line to your .emacs:

~~~lisp
(require 'pd-remote)
~~~

This also loads Faust and Lua mode and adds some convenient keybindings. (You can also change these as needed by editing your local copy of pd-remote.el.)

#### Emacs newbies: Notes for manual installation

If you're an Emacs novice, do yourself a favor and install the easy way, using the Emacs package manager.

But if you *really* want to install manually, make sure you understand how the Emacs [load-path](https://www.emacswiki.org/emacs/LoadPath) works. You may want to put this into your .emacs so that ~/.emacs.d/lisp is searched for elisp files:

~~~lisp
(add-to-list 'load-path "~/.emacs.d/lisp/")
~~~

Then create ~/.emacs.d/lisp if necessary and copy pd-remote.el to that directory. You'll also have to ensure that both lua-mode and faust-mode are installed (they're both available from MELPA).

## Usage

The most common use for pd-remote is to tell Pd when to reload or recompile Lua and Faust objects, for which there is a common keyboard shortcut in both Lua and Faust mode, C-C C-K (i.e., Ctrl+C Ctrl+K). This sends the reload or compile message to the pdluax and faustgen2~ receivers, respectively, depending on which kind of file you're editing in Emacs.

- To make this work for Lua objects, some preparation is needed, as described in the [live-coding section](https://agraef.github.io/pd-lua/tutorial/pd-lua-intro.html#remote-control) of the pd-lua tutorial. For Faust programs this should work out of the box, just adding pd-remote to the patch is enough.

- In either case, at present pd-remote simply reloads *all* corresponding objects, not just objects that have actually been edited. In a future version, we may hopefully be more clever about this.

Both modes also offer the following special keybindings:

| Keybinding | Message Sent                            |
| ---------- | --------------------------------------- |
| C-C C-M    | Prompts for a message to send to Pd     |
| C-C C-Q    | Stops a running pdsend process          |
| C-C C-S    | Start (sends a `play 1` message)        |
| C-C C-T    | Stop (sends a `play 0` message)         |
| C-C C-R    | Restart (sends `play 0,` then `play 1`) |
| C-/        | DSP on (`pd dsp 1`)                     |
| C-.        | DSP off (`pd dsp 0`)                    |

Please note that these are really just examples. You can change any of these bindings in both lua-mode and faust-mode as needed/wanted, and you can add pretty much any Pd message there, as long as it starts with a symbol for a receiver in your patch. In the same vein, you can easily add pd-remote support to any Emacs mode that you use in conjunction with Pd, as long as there is some receiver on the Pd side which processes the Pd messages you want to send.

In fact, the DSP on/off messages are not just useful in Faust and Lua mode, so you may want to add them to your *global* keybindings, too:

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

- The pdsend program needs to be installed and on the PATH. This program usually accompanies the different Pd flavors but may not always be on the PATH, so you may have to either copy it to a directory on your PATH, modify your PATH accordingly, or edit the `pd-remote-pdsend` customization variable (see above) to supply the absolute path under which pdsend can be found.

- pd-remote.pd needs to be loaded on the Pd side. Usually you will include it as an abstraction in the Pd patch that you're working with, but if that isn't possible then you can also just open the pd-remote.pd patch itself in Pd.

- pd-remote.pd uses Pd's `netreceive`. Only a single instance of this object can be listening on a given port at any time. Thus, if you use multiple instances of pd-remote.pd, you may see the error message `netreceive: listen failed: Address already in use`, and only one of the instances will actually be active. Incidentally, this also prevents a received message to be dispatched more than once, which is a good thing. On the other hand, if you happen to close the patch containing the active pd-remote instance, the connection to Emacs will be lost until you re-create a new pd-remote instance (or reopen one of the other patches containing such an instance).

- Recall that if you change the UDP port number in the `pd-remote-port` customization variable (see above), you'll also have to change pd-remote.pd accordingly.

- The same limitations also apply to the VS Code version of pd-remote. Baris' extension also provides some configuration parameters which let you change the pdsend pathname and the UDP port number if needed.

## Examples

I've included some examples from the [pd-lua](https://github.com/agraef/pd-lua) and [pd-faustgen2](https://github.com/agraef/pd-faustgen) distributions in the examples subdirectory for your perusal. Note that you need to have these externals installed to make the examples work. In the sample patches, right-click on the Lua or Faust objects to open them in Emacs (this assumes that Emacs is your default text editor), or open them directly in Emacs using your file manager or the command line.

You can then change the Lua script or Faust program, as described in the pd-lua or pd-faustgen2 documentation. When you've saved your changes, just press C-C C-K in Emacs to have the objects reload the corresponding source in the Pd patch. This works even as the patch keeps running, although you may notice some hiccups in the audio or control processing while the programs are reloaded. (Note: This may look like Emacs somehow submits the edited program to the Pd patch, but it merely sends a message via pd-remote which makes the objects themselves reload their source files.)

### Using pd-remote with VS Code

The same workflow can be employed with Baris' [VS Code version](https://github.com/barisssss/pdRemoteVscode) of pd-remote mentioned above which offers the same keybindings by default. In this case you'd usually want to configure VS Code as your default text editor. Emacs has a steep learning curve, so if you're not familiar with it, or just prefer a modern-style editing environment, VS Code will be the better choice.

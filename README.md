# pd-remote

This is a simplified and unified version of the Pd remote control helpers that I've been distributing with various Pd externals such as [pd-faust](https://github.com/agraef/pure-lang/tree/master/pd-faust) and [pd-lua](https://github.com/agraef/pd-lua) over the years. The present implementation will work with any of these and replaces the more specialized versions. It takes the form of a Pd abstraction pd-remote.pd and an accompanying pd-remote.el elisp file for Emacs.

- pd-remote.pd goes into your Pd patches that you want to control remotely via Pd messages sent over UDP port 4711. These messages can be sent over the local network with the pdsend program, or you can pass messages directly into the inlet of the abstraction for testing purposes.

- pd-remote.el provides the necessary hooks to send messages to pd-remote.pd via pdsend from the [Emacs](https://en.wikipedia.org/wiki/GNU_Emacs) text editor. It also includes built-in support for pd-lua and [pd-faustgen2](https://github.com/agraef/pd-faustgen) (which has since replaced pd-faust), and adds some convenient keybindings for lua-mode and faust-mode, both available from [MELPA](https://melpa.org).

Please note that pd-remote.pd is really a very simple abstraction which merely receives Pd messages of the form `symbol atoms ...` either from its inlet or via netreceive, and then just sends the given atoms (any number of symbols or numbers) to the given receiver symbol at the front of the message, that's all. You still have to set up the corresponding receivers in your patch as needed. But in the case of pd-lua or pd-faustgen2 objects, the receivers are already there for reloading source programs, which is pd-remote's primary purpose.

### pd-remote in Visual Studio Code

A [Visual Studio Code](https://code.visualstudio.com/) version by Baris Altun is available which utilizes the same interface. Please check <https://github.com/barisssss/pdRemoteVscode> for details and installation instructions.

## Installation

pd-remote.pd can be copied to your Pd extra directory (e.g., /usr/lib/pd/extra on Linux) for a system-wide installation, or you can just copy it to the directory with the patches you want to use it in.

pd-remote.el needs to go into a directory that Emacs searches for elisp files, such as /usr/share/emacs/site-lisp on Linux systems for a system-wide, or some place in ~/.emacs.d for a personal installation. E.g., you may want to put this into your .emacs to make sure that ~/.emacs.d/lisp is searched for elisp files (cf. https://www.emacswiki.org/emacs/LoadPath):

~~~lisp
(add-to-list 'load-path "~/.emacs.d/lisp/")
~~~

Create ~/.emacs.d/lisp if necessary and copy pd-remote.el to that directory. Finally, make sure that you have both lua-mode and faust-mode installed (use the "Manage Emacs Packages" option to do this, cf. https://www.emacswiki.org/emacs/InstallingPackages), then add this line to your .emacs:

~~~lisp
(require 'pd-remote)
~~~

This also autoloads Faust and Lua mode and adds some convenient keybindings. You can also change these as needed by editing your local copy of pd-remote.el in ~/.emacs.d/lisp accordingly.

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
| C-C C-G    | Restart (sends `play 0,` then `play 1`) |
| C-/        | DSP on (`pd dsp 1`)                     |
| C-.        | DSP off (`pd dsp 0`)                    |

Please note that these are really just examples. You can change any of these bindings in both lua-mode and faust-mode as needed/wanted, and you can add pretty much any Pd message there, as long as it starts with a symbol for a receiver in your patch. In the same vein, you can easily add pd-remote support to any Emacs mode that you use in conjunction with Pd, as long as there is some receiver on the Pd side which processes the Pd messages you want to send.

In fact, the DSP on/off messages are not just useful in Faust and Lua mode, so you may want to add them to your *global* keybindings, too:

~~~lisp
(global-set-key [(control ?\/)] 'pd-dsp-on)
(global-set-key [(control ?\.)] 'pd-dsp-off)
~~~

You can either put these lines into your local copy of pd-remote.el, or just add them to your .emacs.

However, one thing to remember is that, in order to make any of this work, pd-remote.pd needs to be loaded on the Pd side. Usually you will include it as an abstraction in the Pd patch that you're working with, but if that isn't possible then you can also just open the pd-remote.pd patch itself in Pd.

## Examples

I've included some examples from the pd-lua and pd-faustgen2 distributions in the examples subdirectory for your perusal. In the sample patches, right-click on the Lua or Faust objects to open them in Emacs (this assumes that Emacs is your default text editor), or open them directly in Emacs using your file manager or the command line.

You can then change the Lua script or Faust program, as described in the pd-lua or pd-faustgen2 documentation. When you're done with your changes, just press C-C C-K in Emacs to have the objects reload the corresponding source in the Pd patch. This works even as the patch keeps running, although you may notice some hiccups in the audio or control processing while the programs are reloaded. (Note: This may look like Emacs somehow submits the edited program to the Pd patch, but it merely sends a message via pd-remote which makes the objects themselves reload their source files.)

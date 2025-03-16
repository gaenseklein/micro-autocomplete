# autocomplete plugin to replace autocomplete logic 

use autocomplete from all open buffers in shell style 

# what it does

autocomplete builds a tree of words from all open buffers in open micro instance.
on activation it takes the word in front of current carrent position and 
looks up in the tree to form a list of possible words begining with current words
if there is only one result it completes the word.
if there is more then one result it completes as far as it can without 
loosing words from the list, displaying a message in the status bar with 
possible completions. 
you may know this kind of behaviour from a bash-shell. 


# how to install
copy plugin to your plugin directory (for example `git clone https://github.com/gaenseklein/micro-autocomplete ~/.config/micro/plug/autocomplete`)
edit your bindings.json to use a key for `lua:autocomplete.autocomplete`. you can use '|' to concat other 
actions in case autocomplete does not have a candidate
for example with Tab a line could be:
`    "Tab": "lua:sniptab.on_tab|lua:autocomplete.autocomplete|IndentSelection|InsertTab"`
this means that on a pressed tab, first it checkes 
- if there is a snippet from the sniptab-plugin, 
- if not then checks for an autocomlete from this plugin, 
- if not then to indent a selection 
- and finaly if all failed it writes a tab

# how to configure

## word-building
you can change the recognition of what forms a word with setting the option abc:
`set autocomplete.abc "abcdefghijklmnopqrstuvwxyz"`
the default setting is:
"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789äöüÄÖÜ_./"
## function-call parentesis
by default if function-call-parentesises are detected they are added to the word to complete to. for example 
a text with a call like "foo(bar)" would lead to two completion-words: foo(), bar
so a autocomplete on "fo" would lead to "foo()" while a autocomplete on "ba" would lead to "bar"

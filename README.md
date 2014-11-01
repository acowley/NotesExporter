# Notes Exporter

## Backup the notes you store in OS X's Notes.app, or the Notes apps on your iOS devices.

Looks for a Notes.app SQLite3 database in the file `data/NotesV3.storedata`, and outputs a series of note files to a directory `notes` in the current working directory (multiple backups will be given integer suffixes, like `notes01`, `notes02`, etc.). In OS X Yosemite, the Notes.app database may be found in `~/Library/Containers/com.apple.Notes/Data/Library/Notes/`. Make a directory `data` in your current working directory, and copy all files from the `Notes` directory to this `data` directory. This way you have a backup of the database itself, as well as the extracted note text.

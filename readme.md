# Autopull: Automate git pull

This is a simple script to automate git pull.

It register the time of each pull, and perform pull if the last pull took place on or before yesterday.

Usage: 

```bash
sh autopull -h # show help

sh autopull.sh <path> # pull <path> if the last pull took place on or before yesterday
sh autopull.sh ~/repo -H # pull ~/repo if the last pull took place one hour ago
```

## Installation

```bash
make install 
```

This will install `autopull` to `~/.local/bin`.

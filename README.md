# Commission Organizer

A ~~bash~~ Python script for organizing commissioned art via naming convention.

```
usage: organize.py [-h] [--no-rating] [--date] [--include-song] [-v]
                   [--dry-run] [--regen-thumbs]

Build a static site of commissioned art.

optional arguments:
  -h, --help      show this help message and exit
  --no-rating     Don't include the rating in the naming convention
  --date, -d      Include date in the format YYYY-MM-DD in expected naming
                  convention
  --include-song  Include a "by song" link for song commissions
  -v              Run in verbose mode (-vv for more info, up to -vvvv)
  --dry-run       Don't actually touch any files, just say what will happen
                  (verbosity automatically set to max)
  --regen-thumbs  Regenerate thumbnails

See https://github.com/makyo/commission-organizer for more details
```

## Setup

Your files should be named like so:

    <ARTIST>--<TITLE>--<CHAR>--<RATING>.<EXTENSION>

Where `<RATING>` is one of `G`, `R`, or `X`. You can specify multiple characters separated by a `-`, e.g: `maddy-jd`, and it will link the file to both of those characters (with the downside being that characters with a - in their names will need to be modified somehow). You may also prefix the file name with the date in the format `YYYY-MM-DD--` if you pass the `--date` flag.

Then, simply run this script in a directory with all of your commissions, and it will build a static site that can be used to serve them, with pages for artists, characters, and ratings. Images within those subdirectories are symbolic links to the images in the root directory so that you can still navigate the structure in a file browser. It ignores all other files and directories, so you can still store other files in there. For an example, see <https://drab-makyo.com/commissions>.

I have my commissions in a git repository and initialized this repo as a submodule:

    git submodule add https://github.com/makyo/commission-organizer.git go

Then to run it, I use:

    python go/organize.py

To deploy the site, I add everything and commit, then push the repository to my [Gitea](https://gitea.com) instance. Then on my server, I pull it into `/var/www/commissions`. In my nginx config for drab-makyo.com, I have the following:

    location /commissions {
        alias /var/www/commissions;
    }

This is also generates a static site perfectly suitable for things like GitHub Pages or Netlify, I just have my own little setup (plus some larger files in there that won't work without LFS in GitHub). Might want to keep GitHub's content guidelines in mind, too, if your commissions are adult in nature.

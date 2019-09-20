# Commission Organizer

A bash script for organizing commissioned art via naming convention.

## Setup

Your files should be named like so:

    <ARTIST>--<TITLE>--<CHAR1>-<CHAR2...>--<RATING>.<EXTENSION>

Then, simply run this script in a directory with all of your commissions, and it will build a static site that can be used to serve them, with pages for artists, characters, and ratings. Images within those subdirectories are symbolic links to the images in the root directory so that you can still navigate the structure in a file browser. It ignores all other files and directories, so you can still store other files in there. For an example, see <https://drab-makyo.com/commissions>.

I have my commissions in a git repository and initialized this repo as a submodule:

    git submodule add https://github.com/makyo/commission-organizer.git go

Then to run it, I use:

    ./go/organize

To deploy the site, I add everything and commit, then push the repository to my [Gitea](https://gitea.com) instance. Then on my server, I pull it into `/var/www/commissions`. In my nginx config for drab-makyo.com, I have the following:

    location /commissions {
        alias /var/www/commissions;
    }

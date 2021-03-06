#!/bin/bash

echo -e "\e[91mThis script has been deprecated in favor of the python version!"
echo -e "\e[94mPlease see https://github.com/makyo/commission-organizer for details."

exit 1

STARTTIME=$(date +%s)
read -r -d '' TEMPL_START<<'EOF'
<!DOCTYPE html>
<html>
    <head>
        <link href="https://fonts.googleapis.com/css?family=Ubuntu&display=swap" rel="stylesheet" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            body {
                font-family: "Ubuntu", sans-serif;
            }
            a.G, a.R, a.X {
                display: inline-block;
                border: 2px solid transparent;
                overflow: hidden;
            }
            img {
                max-height: 200px;
                max-width: 100%;
            }
            a.X {
                border: 2px solid red;
            }
            a.X img {
                filter: blur(1rem);
            }
            a.R {
                border: 2px solid orange;
            }
            a.R img {
                filter: blur(0.5rem);
            }
            a.X img:hover, a.R img:hover {
                filter: blur(0);
            }
            main {
                max-width: 1024px;
                border: 1px solid #ccc;
                margin: 0 auto;
                padding: 0.5rem;
                overflow: none;
                text-align: center;
            }
            .modal {
                display: none;
                position: fixed;
                top: 0;
                left: 0;
                bottom: 0;
                width: 100%;
                background-color: rgba(0, 0, 0, 0.8);
            }
            .modal .inner {
                width: calc(100% - 2rem);
                max-height: calc(100vh - 2rem);
                max-width: 1024px;
                position: relative;
                overflow: scroll;
                margin: 1rem auto;
                padding: 0;
                background-color: #fff;
            }
            .modal .meta {
                padding: 1rem;
                margin: 0 auto;
            }
            .show {
                display: block !important;
            }
            .modal .img {
                text-align: center;
                width: 100%;
            }
            .modal .img img {
                max-width: 100%;
                max-height: 100vh;
            }
            dt {
                font-weight: bold;
            }
            table {
                margin: 0 auto;
                min-width: 50%;
            }
            td {
                padding: 5px;
            }
            tbody tr:nth-child(even) td {
                background-color: #eee;
            }
            thead th {
                border-bottom: 2px solid #888;
            }
        </style>
    </head>
    <body>
        <main>
            <h1>
EOF
read -r -d '' TEMPL_END<<'EOF'
        </main>
        <div class="modal">
            <div class="inner">
                <div class="meta"></div>
                <div class="img"></div>
            </div>
        </div>
        <script type="text/javascript">
            const root = window.location.pathname.replace(/\/by-.+$/, '/');
            const modal = document.querySelector('.modal');
            const img = document.querySelector('.img');
            const meta = document.querySelector('.meta');
            let mustLoadHash = window.location.hash !== '';

            function loadHash() {
                if (!mustLoadHash) {
                    mustLoadHash = true;
                    return;
                }
                hash = window.location.hash.replace('#', '');
                if (hash !== '') {
                    document.querySelectorAll('.G, .R, .X').forEach(thumb => {
                        if (thumb.attributes.href.textContent === hash) {
                            thumb.click();
                        }
                    });
                } else {
                    hideModal();
                }
            }
            function hideModal() {
                modal.classList.remove('show');
                window.location.hash = '';
            }

            document.body.addEventListener('keydown', evt => {
                if (evt.key === 'Escape') {
                    hideModal();
                }
            });
            modal.addEventListener('click', evt => {
                hideModal();
            });
            window.onhashchange = loadHash;

            document.querySelectorAll('.G, .R, .X').forEach(thumb => {
                thumb.addEventListener('click', evt => {
                    const imgName = thumb.attributes.href.textContent;
                    const parts = imgName.split('.')[0].split('--');
                    const characters = parts[2].split('-').map(c => `<a href="${root}by-character/${c}">${c}</a>`).join(', ');
                    evt.preventDefault();
                    modal.classList.add('show');
                    mustLoadHash = true;
                    window.location.hash = imgName;
                    img.innerHTML = `<a href="${thumb.attributes.href.textContent}" target="_blank">${thumb.innerHTML}</a>`;
                    meta.innerHTML = `<h2>${parts[1].replace(/-/g, ' ')}</h2>
                        <table>
                            <thead>
                                <tr>
                                    <th>Artist</th>
                                    <th>Characters</th>
                                    <th>Rating</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td><a href="${root}by-artist/${parts[0]}">${parts[0]}</a></td>
                                    <td>${characters}</td>
                                    <td>${parts[3]}</td>
                                </tr>
                            </tbody>
                        </table>`;
                });
            });

            loadHash();
        </script>
    </body>
</html>
EOF

# Remove the existing artist and character directories
rm -rf by-artist by-character by-rating
mkdir by-artist by-character by-rating

# Start the index file for /
cat <<EOF > index.html
${TEMPL_START}All commissions</h1>
<p><strong>
<a href="by-artist">By artist</a> |
<a href="by-character">By character</a> |
<a href="by-rating">By rating</a> (<a href="by-rating/G">G</a> - <a href="by-rating/R">R</a> - <a href="by-rating/X">X</a>) |
<a href="by-song">By song</a> |
<a href="all.html">All images</a>
</strong></p>
EOF
cp index.html all.html
echo "<h2>Most recent additions</h2>" >> index.html
for img in `ls -1t *--*--*|head`; do
    IFS=',' read -r -a parts <<< `echo $img | sed -e 's/--/,/g' | sed -e 's/\....$//'`
    echo "<a href=\"$img\" class=\"${parts[3]}\"><img src=\"$img\" title=\"${parts[1]}\" alt=\"${parts[1]}\" /></a>" >> index.html
done
echo "$TEMPL_END" >> index.html

# Loop over the images.
for img in `ls -1t *--*--*--*`; do
    if ! [[ $(file $img) =~ "image data" ]]; then
        echo -e "\e[31m$img is not an image, skipping...\e[0m"
        continue
    else
        echo -e "\e[36mProcessing $img...\e[0m"
    fi
    # Split the filename
    IFS=',' read -r -a parts <<< `echo $img | sed -e 's/--/,/g' | sed -e 's/\....$//'`

    # Write the link to the index file for /
    echo -e "<a href=\"$img\" class=\"${parts[3]}\"><img src=\"$img\" title=\"${parts[1]}\" alt=\"${parts[1]}\" /></a>\n" >> all.html

    # Set the image up in the artist index
    mkdir -p "by-artist/${parts[0]}"
    pushd "by-artist/${parts[0]}" > /dev/null 2>&1

    # Write the link to the index file for the artist, creating if needed
    if ! test -e index.html; then
        echo -e "    \e[35mArtist ${parts[0]} does not exist, creating...\e[0m"
        echo -e "${TEMPL_START}Artist: ${parts[0]}</h1>\n" > index.html
    fi

    echo -e "    \e[34mAdding image to artist '${parts[0]}'\e[0m"
    # Write the link to the index file for the artist
    echo -e "<a href=\"$img\" class=\"${parts[3]}\"><img src=\"$img\" title=\"${parts[1]}\" alt=\"${parts[1]}\" /></a>\n" >> index.html

    # Link the file
    ln -s ../../$img .
    popd > /dev/null 2>&1

    # Set the image up in the characters index/indices
    IFS='-' read -r -a chars <<< ${parts[2]}
    for char in ${chars[*]}; do
        # Set the image up in the character index
        mkdir -p "by-character/${char}"
        pushd "by-character/${char}" > /dev/null 2>&1

        # Write the link to the index file for the artist, creating if needed
        if ! test -e index.html; then
            echo -e "    \e[35mCharacter $char does not exist, creating...\e[0m"
            echo -e "${TEMPL_START}Character: $char</h1>\n" > index.html
        fi

        echo -e "    \e[94mAdding image to character '$char'\e[0m"
        # Write the link to the index file for the artist
        echo -e "<a href=\"$img\" class=\"${parts[3]}\"><img src=\"$img\" title=\"${parts[1]}\" alt=\"${parts[1]}\" /></a>\n" >> index.html

        # Link the file
        ln -s ../../$img .
        popd > /dev/null 2>&1
    done

    # Set the image up in the rating index
    mkdir -p "by-rating/${parts[3]}"
    pushd "by-rating/${parts[3]}" > /dev/null 2>&1

    # Write the link to the index file for the rating, creating if needed
    if ! test -e index.html; then
        echo -e "    \e[35mRating ${parts[3]} does not exist, creating...\e[0m"
        echo -e "${TEMPL_START}Rating: ${parts[3]}</h1>\n" > index.html
    fi

    echo -e "    \e[34mAdding image to rating '${parts[3]}'\e[0m"
    # Write the link to the index file for the rating
    echo -e "<a href=\"$img\" class=\"${parts[3]}\"><img src=\"$img\" title=\"${parts[1]}\" alt=\"${parts[1]}\" /></a>\n" >> index.html
    echo -e "\e[32mDone processing $img\e[0m"

    # Link the file
    ln -s ../../$img .
    popd > /dev/null 2>&1

    echo
done

echo "Cleaning up..."
# Close out the html files and write the index files for the directory
echo "$TEMPL_END" >> all.html

echo -e "\e[36mWriting artist index...\e[0m"
pushd by-artist > /dev/null 2>&1
cat <<EOF > index.html
${TEMPL_START}Artists</h1>
<table>
<thead>
<tr><th>Artist</th><th>Images</th></tr>
</thead>
<tbody>
EOF
for artist in `find . -maxdepth 1 -type d | sort`; do
    if [[ $artist = . ]]; then
        continue
    fi
    count=$(find $artist -type l | wc -l)
    echo -e "<tr><td><a href=\"$artist\">$(echo $artist | cut -d / -f 2)</a></td><td>$count image$([[ $count == 1 ]] || echo 's')</td>\n" >> index.html
    echo "$TEMPL_END" >> "$artist/index.html"
done
echo -e "</tbody>\n</table>$TEMPL_END" >> index.html
popd > /dev/null 2>&1
echo -e "\e[32mDone\e[0m"

echo -e "\e[36mWriting character index...\e[0m"
pushd by-character > /dev/null 2>&1
cat <<EOF > index.html
${TEMPL_START}Characters</h1>
<table>
<thead>
<tr><th>Character</th><th>Images</th></tr>
</thead>
<tbody>
EOF
for char in `find . -maxdepth 1 -type d | sort`; do
    if [[ $char = . ]]; then
        continue
    fi
    count=$(find $char -type l | wc -l)
    echo -e "<tr><td><a href=\"$char\">$(echo $char | cut -d / -f 2)</a></td><td>$count image$([[ $count == 1 ]] || echo 's')</td>\n" >> index.html
    echo "$TEMPL_END" >> "$char/index.html"
done
echo -e "</tbody>\n</table>$TEMPL_END" >> index.html
popd > /dev/null 2>&1
echo -e "\e[32mDone\e[0m\n"

echo -e "\e[36mWriting rating index...\e[0m"
pushd by-rating > /dev/null 2>&1
cat <<EOF > index.html
${TEMPL_START}Ratings</h1>
<table>
<thead>
<tr><th>Rating</th><th>Images</th></tr>
</thead>
<tbody>
<tr><td><a href="G">Generally okay</a></td><td>$(find G -type l | wc -l)</td></tr>
<tr><td><a href="R">Risq&eacute;</a></td><td>$(find R -type l | wc -l)</td></tr>
<tr><td><a href="X">Explicit</a></td><td>$(find X -type l | wc -l)</td></tr>
</tbody>
</table>
${TEMPL_END}
EOF
echo "$TEMPL_END" >> "G/index.html"
echo "$TEMPL_END" >> "R/index.html"
echo "$TEMPL_END" >> "X/index.html"
popd > /dev/null 2>&1
echo -e "\e[32mDone\e[0m\n"

ENDTIME=$(date +%s)
echo -e "\e[92mDone!\e[0m"
echo
echo "Completed in $(($ENDTIME - $STARTTIME)) seconds."

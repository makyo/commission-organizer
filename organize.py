import os
import re
import glob
import argparse
from collections import defaultdict
from shutil import rmtree
from string import Template
from datetime import datetime

CWD = os.getcwd()

# Filename globs
RATING = r'--?'
DATE = r'[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]--'
FILENAME_FORMAT = r'{}/{}*--*--*{}.???'

# Regular expression for matching filenames
FILENAME_RE = re.compile(
    r'''^.+/(                         # Path
        ((\d\d\d\d-\d\d-\d\d)--)?     # Date (maybe)
        (?P<artist>.+)--              # Artist
        (?P<title>.+)--               # Title
        (?P<characters>.+)            # Characters (- separated)
        (--(?<=--)(?P<rating>[GRX]))  # Rating
        \.(?P<extension>....?))$        # Extension
    ''', re.X)
VALID_EXTENSIONS = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'bmp',
    'svg',
    'webp',
    'tif',
    'tiff',
]

# Template strings for various parts of the indices
THUMB_STR = '''
<a href="{img}" class="{rating}">
    <img src="{img}" title="{title}" alt="{title}" />
</a>'''
TABLE_STR = '''
<table>
    <thead>
        <tr>
            <th>{part_type}</th>
            <th>Images</th>
        </tr>
    </thead>
    <tbody>
        {rows}
    </tbody>
</table>'''
TABLE_ROW_STR = '''
<tr>
    <td><a href="{part}">{part}</a></td>
    <td>{count} image{s}</td>
</tr>'''

COMMIT = True

VERBOSITY = 0
MAX_VERBOSITY = 4
VERBOSITY_COLORS = [
    '\x1b[0m',
    '\x1b[96m',
    '\x1b[94m',
    '\x1b[95m',
    '\x1b[34m'
]

# Open and compile the base gallery template.
with open(os.path.join(
        os.path.dirname(os.path.realpath(__file__)),
        'gallery.template.html')) as f:
    TEMPLATE = Template(f.read())

def log(level, message, done=False):
    if level <= VERBOSITY:
        print('{}{}{}\x1b[0m'.format(
            '\x1b[92m' if done else VERBOSITY_COLORS[level],
            '  ' * level,
            message))

def create_by_index(link_dir, link_type, parts):
    '''Create the base index file for a type (artist, character, etc).'''
    log(2, 'Generating index page for {}s'.format(link_type))
    content = TABLE_STR.format(
        part_type=link_type.capitalize(),
        rows=''.join([TABLE_ROW_STR.format(
            part=k,
            count=len(parts[k]),
            s='s' if len(parts[k]) != 1 else '') for k in
            sorted(parts.keys())]))
    with open(os.path.join(link_dir, 'index.html'), 'w') as f:
        if COMMIT:
            f.write(TEMPLATE.substitute(
                title=link_type.capitalize(),
                content=content))

def get_file_list(include_date=False, include_rating=True):
    '''Get a list of files matching the naming convention.'''
    log(1, 'Getting list of commissions...')
    result = glob.glob(FILENAME_FORMAT.format(
        CWD,
        DATE if include_date else '',
        RATING if include_rating else '',
    ))
    log(1, 'Found {} matching files'.format(len(result)), done=True)
    return result

def create_by_dir(by_dir, by_type, by, parts):
    '''Create a part directory (artist, character, etc) with index and links.'''
    log(2, 'Generating {} page for {}...'.format(by_type, by))
    if COMMIT:
        os.mkdir(os.path.join(by_dir, by))
    log(3, 'Linking files for {} {}...'.format(by_type, by))
    parts.sort(key=lambda x: x['path'])
    for part in parts:
        log(4, 'Linking {} for the {} {} page'.format(
            os.path.basename(part['path']), by, by_type))
        if COMMIT:
            os.symlink(
                os.path.join(
                    '..',
                    '..',
                    os.path.basename(part['path'])),
                os.path.join(
                    by_dir, by, os.path.basename(part['path'])))
    log(3, 'Done', done=True)
    content = ''.join([THUMB_STR.format(
        img=os.path.basename(part['path']),
        rating=part.get('rating'),
        title=part['title']) for part in parts])
    with open(os.path.join(by_dir, by, 'index.html'), 'w') as f:
        log(3, 'Generating the index page for {} {}'.format(by_type, by))
        if COMMIT:
            f.write(TEMPLATE.substitute(
                title='{}: {}'.format(by_type.capitalize(), by),
                content=content))
    log(2, 'Done', done=True)

def create_by(link_type, parts):
    log(1, 'Wiping previous state')
    link_dir = os.path.join(CWD, 'by-{}'.format(link_type))
    if COMMIT:
        rmtree(link_dir)
        os.mkdir(link_dir)
    log(1, 'Generating {} pages...'.format(link_type))
    create_by_index(link_dir, link_type, parts)
    for k, v in parts.items():
        create_by_dir(link_dir, link_type, k, v)

def main(include_date=False, include_rating=True):
    '''Build a static site for commissions.'''
    start = datetime.now()
    log(0, 'Building commissions site...')

    # Get the list of files.
    files = get_file_list(
        include_date=include_date,
        include_rating=include_rating)

    # Organize them into various types.
    artists = defaultdict(list)
    characters = defaultdict(list)
    ratings = defaultdict(list)

    for path in files:
        match = FILENAME_RE.match(path)
        if match and match.group('extension').lower() in VALID_EXTENSIONS:
            parts = match.groupdict()
            parts['path'] = path
            parts['characters'] = parts['characters'].split('-')
            if 'rating' not in parts:
                parts['rating'] = 'G'
            artists[parts['artist']].append(parts)
            for character in parts['characters']:
                characters[character].append(parts)
            ratings[parts['rating']].append(parts)

    # Create the various parts.
    create_by('artist', artists)
    create_by('character', characters)
    if include_rating:
        create_by('rating', ratings)

    # Create the index page with the most recent additions.
    log(1, 'Generating home page...')
    recent = []
    with os.scandir(CWD) as it:
        for entry in it:
            if entry.is_file() and FILENAME_RE.match(entry.path):
                recent.append(entry)
    recent.sort(key=lambda x: x.stat().st_mtime)
    content = '''
    <p><strong>
        <a href="by-artist">By artist</a> |
        <a href="by-character">By character</a> |
        <a href="by-rating">By rating</a> (<a href="by-rating/G">G</a> - <a href="by-rating/R">R</a> - <a href="by-rating/X">X</a>) |
        <a href="by-song">By song</a> |
        <a href="all.html">All images</a>
    </strong></p>''' + ''.join([THUMB_STR.format(
        img=path.group(1),
        rating=path.group('rating'),
        title=path.group('title')) for path in map(lambda x: FILENAME_RE.match(x.path), recent[:10])])
    with open(os.path.join(CWD, 'index.html'), 'w') as f:
        if COMMIT:
            f.write(TEMPLATE.substitute(
                title='Commissions',
                content=content))

    duration = datetime.now() - start
    log(0,
        'Done in {}.{} seconds'.format(duration.seconds, duration.microseconds),
        done=True)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Build a static site of commissioned art.',
        epilog='See https://github.com/makyo/commission-organizer for more details')
    parser.add_argument('--no-rating',
                        dest='include_rating',
                        action='store_false',
                        help="Don't include the rating in the naming "
                        "convention")
    parser.add_argument('--date',
                        '-d',
                        dest='include_date',
                        action='store_true',
                        help='Include date in the format YYYY-MM-DD in '
                        'expected naming convention')
    parser.add_argument('-v',
                        default=0,
                        action='count',
                        help='Run in verbose mode (-vv for more info, up to '
                        '-{})'.format('v' * MAX_VERBOSITY))
    parser.add_argument('--dry-run',
                        dest='dry_run',
                        action='store_true',
                        help="Don't actually touch any files, just say what "
                        "will happen (verbosity automatically set to max)")
    args = parser.parse_args()
    COMMIT = not args.dry_run
    VERBOSITY = MAX_VERBOSITY if args.dry_run else args.verbose
    main(include_date=args.include_date, include_rating=args.include_rating)

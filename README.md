# yalesites-starterkit
A collection of content to be imported to new yalesites

## Adding content directly to this repo

The dev site (`ys-starterkit.dev`) is the source of truth for exports. If a PR adds or changes content here without going through dev, the next export will wipe it.

After merging such a PR, run the script from an updated `main`. It imports the PR's new and changed items onto dev. By default it covers the last merge (`HEAD^1..HEAD`). Pass a different base ref to cover more.

Preview what would be uploaded:

```bash
scripts/sync-to-dev.sh --dry-run
```

Import onto dev (needs `terminus` logged in):

```bash
scripts/sync-to-dev.sh
```

Set `SITE` to target a different Pantheon environment, for example `SITE=ys-starterkit.test scripts/sync-to-dev.sh`.

The import cannot delete. If the PR removed content, the script lists those files and you must remove them on dev by hand.

The preferred path is still to add content on dev first and export it.

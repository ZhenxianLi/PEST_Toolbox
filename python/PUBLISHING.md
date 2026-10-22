# Publishing psychopy-pest

How `psychopy-pest` is released to PyPI and listed in the PsychoPy plugin
manager. Follow these steps for every new version.

## 1. Release a new version to PyPI

Releases are published by [`.github/workflows/publish.yml`](../.github/workflows/publish.yml)
using [PyPI trusted publishing](https://docs.pypi.org/trusted-publishers/),
so no API token is stored in the repository.

One-time setup (already done for this project): on
<https://pypi.org/manage/account/publishing/>, a trusted publisher was added
with these values:

| Field             | Value           |
|-------------------|-----------------|
| PyPI project name | `psychopy-pest` |
| Owner             | `ZhenxianLi`    |
| Repository name   | `PEST_Toolbox`  |
| Workflow name     | `publish.yml`   |
| Environment name  | `pypi`          |

For each release:

1. Update `__version__` in `src/psychopy_pest/__init__.py`, and keep the
   version in `toolbox/Contents.m` and `CITATION.cff` in step.
2. Merge the change into `main` with CI green.
3. Create a GitHub release at
   <https://github.com/ZhenxianLi/PEST_Toolbox/releases/new> with the tag
   `v<version>` (for example `v2.1.0`). The workflow fails if the tag does
   not match `__version__`.
4. Check the new version at <https://pypi.org/project/psychopy-pest/>.

## 2. List the plugin in the PsychoPy plugin manager

Publishing to PyPI makes the plugin installable with pip, but the Plugins
dialog in PsychoPy only shows plugins listed in the
[PsychoPy plugin registry](https://github.com/psychopy/plugins), which the
PsychoPy team curates. Plugins are added to it by pull request; this is only
needed once, not for every release.

1. Fork <https://github.com/psychopy/plugins> to your GitHub account.
2. In the fork, append an entry to `plugins.json`. The file uses Windows
   (CRLF) line endings; keep them. The entry for this plugin:

   ```json
   {
     "pipname": "psychopy-pest",
     "name": "PEST Staircase",
     "author": {
       "name": "Zhenxian Li",
       "github": "ZhenxianLi",
       "avatar": "https://plugins.psychopy.org/_static/plugin-icons/authors/ZhenxianLi.png"
     },
     "icon": "https://plugins.psychopy.org/_static/plugin-icons/psychopy-pest.png",
     "description": "Adds the PEST adaptive staircase (Taylor & Creelman, 1967) as psychopy.data.PestHandler, alongside StairHandler and QuestHandler.",
     "homepage": "https://github.com/ZhenxianLi/PEST_Toolbox/tree/main/python",
     "docs": "https://github.com/ZhenxianLi/PEST_Toolbox/blob/main/python/README.md",
     "repo": "https://github.com/ZhenxianLi/PEST_Toolbox",
     "keywords": ["staircase", "psychophysics", "threshold", "adaptive"]
   }
   ```

   `pipname` must be the PyPI name. `email` is optional and left out here
   because the file is public.
3. Add the images the entry points to:
   - `docs/_static/plugin-icons/psychopy-pest.png`: copy of
     [`images/psychopy-pest.png`](images/psychopy-pest.png). Icons must be
     PNG in RGBA mode (other modes have broken the registry before); about
     128×128 with a transparent background matches the other plugins.
   - `docs/_static/plugin-icons/authors/ZhenxianLi.png`: the author avatar.
4. Commit with a message such as
   `NF: Add psychopy-pest plugin to plugins.json` and open a pull request
   from the fork to `psychopy/plugins:main`.
5. Once the PsychoPy team merges it, the plugin appears in
   **Tools → Plugins/packages manager → Plugins** in PsychoPy, and users can
   install it from there.

To change the listing later (new description, icon or links), open another
pull request to `psychopy/plugins` that edits the same entry.

## Naming conventions

Names follow PsychoPy's conventions, so the plugin looks like part of
PsychoPy:

| Use                   | Name                                                    |
|-----------------------|---------------------------------------------------------|
| PyPI / pip            | `psychopy-pest` (every registry plugin is `psychopy-<name>`) |
| Python import         | `psychopy_pest`                                         |
| Class in PsychoPy     | `psychopy.data.PestHandler` (like `QuestHandler`, `PsiHandler`) |
| Entry point group     | `psychopy.data` in `pyproject.toml`                     |

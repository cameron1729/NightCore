# NightCore

A small Lua framework for OpenITG and StepMania 3.95 themes, targeting Lua 5.0 and 5.1.

## Using it in a theme

Copy `NightCore.lua` into the theme as `Scripts/00.00 NightCore.lua`, before the
bootstrap and module scripts:

```lua
-- Scripts/00.01 Bootstrap.lua
BuildGrooveNights = NightCore.bootstrap()

-- Scripts/00.10 Settings.Cabinet.lua
Venue = "ITG Cam's House"

-- Scripts/00.30 Initialise.lua
GrooveNights = BuildGrooveNights()
BuildGrooveNights = nil
```

This produces `GrooveNights.Settings.Cabinet.Venue`. Each module needs a unique
`NN.NN` filename prefix; dots in the remaining name form namespaces. Modules can
read earlier modules and engine globals. The returned tree belongs to the theme.

`NightCore.addField`, `NightCore.build`, `NightCore.group` and `NightCore.enum`
combine fields into fresh tables. Nested values are shared and treated as read-only.

Bootstrap logs `NightCore.Version` and the Lua version through the engine's `Trace` function.

For local theme development, symlink `00.00 NightCore.lua` to this checkout's
`NightCore.lua`. Edits take effect on the next script reload. Keep the link out of
theme commits and bundle a regular copy when committing the theme integration.
Exclude the untracked link through the theme repository's `.git/info/exclude`.
For GrooveNights, add:

```gitignore
/Scripts/00.00 NightCore.lua
```

## Development and releases

Work directly on `main`; use a temporary branch when an experiment needs one.
The version string in `NightCore.lua` starts at `0.1.0-dev` and can stay unchanged
through many development commits. Development versions are not tagged.

To release `0.1.0`, change `NightCore.Version` to `"0.1.0"`, then:

```sh
git add NightCore.lua
git commit -m "Release 0.1.0"
git tag -a v0.1.0 -m "Release 0.1.0"
git push origin main v0.1.0
```

The home server mirrors branches and tags to GitHub. Keep released tags fixed.
When development resumes, change the string to the next intended version, such
as `0.1.1-dev` for fixes or `0.2.0-dev` for the next feature release.

Versions follow [SemVer](https://semver.org/). The API can change during `0.x`;
`1.0.0` marks a stable API. After that, patches fix bugs, minor versions add
compatible features, and major versions introduce breaking changes.

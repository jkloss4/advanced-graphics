# Advanced Graphics

Graphics settings for World of Warcraft that aren't in the game's options menus, on one options page
(Options → AddOns → Advanced Graphics) in Blizzard's settings style.

Retail (Interface 120100) and WoW: Forever (Interface 16001). Settings a client doesn't have are left off the page:
the HDR section and Linear Lighting / Bloom are WoW: Forever only.

## Settings

- **HDR** (WoW: Forever): HDR output, highlight strength, and overrides for peak brightness and paper white (nits).
- **Lighting**: Linear Lighting and Bloom (WoW: Forever), surface shine, light draw distance.
- **Sharpening**: sharpen even without FSR upscaling, sharpness amount, crisper CMAA2 anti-aliasing.
- **World Detail**: ground clutter density, distance and fade, weather density, cloud detail, object detail and fade
  distance, footprints, soft edges.
- **Distance & Detail**: how far terrain, buildings and characters keep full detail, where the distant landscape
  begins, small-object culling and keep distance, and full-quality (uncompressed) character textures.
- **Screen Effects**: full-screen glow, the gray death effect, the nether effect.

Each control reads and sets the game's own setting (console variable), so the game saves it in its config; the addon
saves nothing. **Defaults** puts every setting on the page back to the game's default. Some of these (clutter,
object detail) are also set by the menus' quality presets, so moving the matching menu slider later replaces them.

Slash commands: `/advancedgraphics` or `/advgfx` (opens the options).

## Install

Download `AdvancedGraphics-<version>.zip` from the [latest release](../../releases/latest) and extract the
`AdvancedGraphics` folder into `World of Warcraft\_classic_beta_\Interface\AddOns\` for WoW: Forever (`_retail_`
instead of `_classic_beta_` for retail).

An addon manager that installs from GitHub releases (e.g. WowUp: *Install from URL* with this repo's URL) can also
install and update it, **but only if the repository is public**.

## Developing / releasing

- Test local changes: `.\scripts\install-local.ps1` copies the addon folder into `AddOns` (WoW: Forever by default;
  `-AddOnsPath` for retail), then `/reload`.
- After a WoW patch: bump `## Interface:` in `AdvancedGraphics/AdvancedGraphics.toc`.
- Release: `git tag v1.0.1 && git push --tags`. The [Release workflow](.github/workflows/release.yml) stamps the
  version into the TOC, builds the zip (with a `release.json` so addon managers see it's a retail and Forever build), and
  publishes the GitHub release.

## License

MIT ([`LICENSE`](LICENSE), also included in the addon folder).

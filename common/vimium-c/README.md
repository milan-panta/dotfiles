# Vimium C

In Vimium C's extension options, paste `vimium-c.txt` into **Custom key mappings**
and `vimium-c.css` into **Custom CSS for Vimium C UI**, then save. Reload an
existing webpage to check the changes. These files are paste-in configuration;
editing them here does not update the running extension automatically.

## Modes and link hints

Press **Shift+Escape** to toggle insert mode: page shortcuts and typing pass
through to the website. The small entry notice disappears after about 1.5 seconds;
insert mode stays active until you toggle it off. Ordinary text fields already
accept typing without manually entering this mode.

In normal mode, press a hint command, then type the label beside the target.
`;f` means press `;`, then lowercase `f`; `;F` means `;`, then Shift+F.
Release Shift before typing hint labels: modifier keys can change hint behavior.

| Keys | What they do |
| --- | --- |
| `f` | Click a link, button, or other interactive element. |
| `F` | Open a link in a background tab, keeping this page active. |
| `;F` | Keep choosing links to open in background tabs; Escape finishes. |
| `;f` | Focus an element without clicking it; also select where scrolling goes. |
| `gi` | Focus a text input; Tab cycles through inputs. |
| `;h` / `;H` | Hover / leave an element, useful for hover menus. |
| `;y` | Copy a hinted link's URL. |
| `;o` | Put a hinted link's URL or text into the Vomnibar for editing. |
| `;v` | Select hinted text and enter visual mode. |

`F` and `;F` use `newtab="force"` to open actual link URLs directly instead of
simulating Ctrl+click, which websites can intercept. In Vimium C 2.12.2,
`action2="*//-1"` is also needed so that the click action follows `newtab`.
Buttons, JavaScript links,
and local `#fragment` links may still perform their page action: they do not
provide an ordinary destination for this option to open in a new tab.

`F` and `;F` also use `focus=false autoUnhover=true` to avoid leaving keyboard
focus or simulated hover on the original link. To clear an existing outline,
press `;H` and select that link's hint; leaving the element also blurs it.
`;f` still focuses elements intentionally.

## Useful everyday combinations

| Keys | What they do |
| --- | --- |
| `o` / `O` | Search or open a URL in this tab / a new tab. `t` also opens the new-tab Vomnibar. |
| `b` | Search open tabs by title or URL and switch to one. |
| `B` | Search bookmarks and open one in a new tab. |
| `J` / `K` | Next / previous tab. |
| Backspace | Switch to the previously visited tab. |
| `D` / `u` | Close / restore a tab. |
| `yy`, then `P` | Copy this page's URL, then open the clipboard URL in a new tab. |
| `/`, then `n` / `N` | Find text, then next / previous match. |
| `ma`, then `` `a `` | Save position as mark `a`, then return to it. |
| `gu` / `gU` | Go up one URL level / to the site's root. |
| `gf` / `gF` | Focus the next frame / the main frame when a page has embedded content. |
| `?` | Show the help overlay for your configured commands. |

Counts work with many commands: `5j` scrolls farther and `3J` moves three tabs.
For research, try `;F` to collect links, `b` to jump between them, and `D` to close
finished tabs. For long pages, use `/` to jump to a phrase and `ma` to save your
place before exploring elsewhere.

This profile starts with `unmapAll`, so generic Vimium cheat sheets may list
shortcuts that are not enabled here. Ctrl shortcuts remain available to Chromium.

Upstream references: [command list](https://github.com/gdh1995/vimium-c/wiki/List-of-all-commands),
[link actions](https://github.com/gdh1995/vimium-c/blob/master/content/link_actions.ts),
and [insert-mode options](https://github.com/gdh1995/vimium-c/blob/master/background/all_commands.ts).

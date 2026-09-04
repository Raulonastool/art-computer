-- Art Computer.
--
-- Installed by art-computer/install.sh. Nothing outside this file was changed
-- except one require() line in bindings.lua.
--
-- Delete it freely, but note that install.sh rewrites this file on every run,
-- so local edits are lost on the next upgrade. To change a binding for good,
-- override it in bindings.lua after the require, or edit the copy in the repo.

o.bind("SUPER + A", "Art Computer", "art home")
o.bind("SUPER + ALT + A", "Art agent", "art open")

-- Chromium ignores --class for --app windows and derives the app_id from the
-- URL instead, so the reliable handle is the page title. Every Art Computer
-- page ends with " · Art Computer"; the home page is titled just
-- "Art Computer", so the optional prefix covers both.
local artwork = { title = "^(?:.* · )?Art Computer$" }

-- Artwork must render at true colour: opt out of Omarchy's browser opacity.
o.window(artwork, { tag = "-chromium-based-browser" })
o.window(artwork, { tag = "-default-opacity" })
o.window(artwork, { opacity = "1.0 1.0" })

-- Deliberately not forcing fullscreen: it fights the tiler and traps people
-- in a window they can't get out of. SUPER + F when you want it.

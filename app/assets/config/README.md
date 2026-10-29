# Settings files (docs/settings-file.md)

- `settings.default.toml`: the first-start copy of the user's `settings.toml` (Node and Epicbox lists, three switches); the wallet writes it to its data folder once and keeps that file in step with the app.
- `app-config.toml`: the app's own configuration (addresses, onions, operators, timeouts, intervals, ports, limits); read-only, read from here, never written to the data folder or a backup.
- Rule: all configuration lives in these two files, none in code (`tools/check-no-hosts.sh`).
- Dev chains (floonet, usernet) have their own pair in `app/tool/config/<chain>/`, copied by `app/tool/dev_settings.sh`.

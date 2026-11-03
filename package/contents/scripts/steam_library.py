#!/usr/bin/env python3

from pathlib import Path
import json
import vdf
import sys

from appinfo_parser import AppInfoParser


steam_path = Path.home() / ".local/share/Steam"

library_file = steam_path / "steamapps/libraryfolders.vdf"
appinfo_file = steam_path / "appcache/appinfo.vdf"
library_cache = steam_path / "appcache/librarycache"


# Read Steam's library information.
with library_file.open("r", encoding="utf-8") as file:
    library_data = vdf.load(file)


# Load Steam's application metadata database.
appinfo_parser = AppInfoParser(appinfo_file)


# Collect installed apps from every Steam library.
installed_apps = {}

for library in library_data["libraryfolders"].values():
    library_path = Path(library["path"])
    steamapps_path = library_path / "steamapps"

    if not steamapps_path.is_dir():
        print(f"SKIPPED: {steamapps_path}", file=sys.stderr)
        continue

    manifest_files = list(steamapps_path.glob("appmanifest_*.acf"))

    print(
        f"FOUND: {steamapps_path} -> {len(manifest_files)} manifests",
        file=sys.stderr,
    )
    
    for manifest_file in steamapps_path.glob("appmanifest_*.acf"):
        app_id = manifest_file.stem.replace("appmanifest_", "")
        installed_apps[app_id] = manifest_file

games = []

for app_id in installed_apps:
    app = appinfo_parser.get_app(int(app_id))
    
    if app is None:
        continue

    common = app.get("common", {})

    app_name = common.get("name", "Unknown")
    app_type = common.get("type", "Unknown")

    if app_type.lower() not in ("game", "demo"):
        continue

    cover_files = list(
        (library_cache / app_id).glob("**/library_600x900.jpg")
    )

    if not cover_files:
        cover_files = list(
            (library_cache / app_id).glob("**/library_capsule.jpg")
        )

    cover_file = cover_files[0] if cover_files else None

    icon_hash = common.get("icon")
    icon_file = None

    if icon_hash:
        icon_files = list(
            (library_cache / app_id).glob(f"**/{icon_hash}.*")
        )

        if icon_files:
            icon_file = icon_files[0]

    games.append({
        "appid": app_id,
        "name": app_name,
        "type": app_type,
        "cover": str(cover_file) if cover_file else None,
        "icon": str(icon_file) if icon_file else None
    })

print(json.dumps(games))

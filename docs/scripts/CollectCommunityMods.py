from urllib.request import Request, urlopen
import json

USER="UwUDev"
REPO="balamod"
github_repo_api = f"https://api.github.com/repos/{USER}/{REPO}/releases/latest"
mods_repo_index_url = f"https://raw.githubusercontent.com/{USER}/{REPO}/master/repos.index"
apis_repo_index_url = f"https://raw.githubusercontent.com/{USER}/{REPO}/master/apis.index"
headers = {"User-Agent": "Balamod client"}

config_path = "src/context.json"
config_obj={
    "balamod": {
        "latest_tag": None,
        "latest_url": None,
        "published_at": None,
        "release_url_linux": None,
        "release_name_linux": None,
        "release_url_windows": None,
        "release_name_windows": None,
        "release_url_macos": None,
        "release_name_macos": None,
    },
    "mods": []
}

def request(url):
    req = Request(url, headers=headers)
    response = urlopen(req)
    return response.read().decode()

def get_balamod_version():
    global config_obj
    res = request(github_repo_api)
    if not res:
        raise Exception("Error: Failed to get latest release")
    res = json.loads(res)
    config_obj["balamod"]["latest_tag"] = res["tag_name"]
    config_obj["balamod"]["latest_url"] = res["html_url"]
    config_obj["balamod"]["published_at"] = res["published_at"]

    linux_assets = next((asset for asset in res["assets"] if "linux" in asset["name"]), None)
    config_obj["balamod"]["release_url_linux"] = linux_assets["browser_download_url"] if linux_assets else None
    config_obj["balamod"]["release_name_linux"] = linux_assets["name"] if linux_assets else None

    windows_assets = next((asset for asset in res["assets"] if "windows" in asset["name"]), None)
    config_obj["balamod"]["release_url_windows"] = windows_assets["browser_download_url"] if windows_assets else None
    config_obj["balamod"]["release_name_windows"] = windows_assets["name"] if windows_assets else None

    macos_assets = next((asset for asset in res["assets"] if "mac" in asset["name"]), None)
    config_obj["balamod"]["release_url_macos"] = macos_assets["browser_download_url"] if macos_assets else None
    config_obj["balamod"]["release_name_macos"] = macos_assets["name"] if macos_assets else None
    print("Successfully collected balamod version")


def parse_mod(mod):
    """
    dev_console|0.5.1|Dev Console|An in-game developer console|https://github.com/balamod/mods/tree/main/dev_console|{}
    """
    mod = mod.split("|")
    return {
        "id": mod[0],
        "version": mod[1],
        "name": mod[2],
        "description": mod[3],
        "url": mod[4],
    }

def collect(url, section):
    global config_obj
    repos = request(url)
    for repo in repos.split("\n"):
        if not repo:  # Skip if repo is empty
            continue
        mods = request(repo)
        for mod in mods.split("\n"):
            if not mod:
                continue
            config_obj[section].append(parse_mod(mod))
    print("Successfully collected community mods")

def main():
    global config_obj
    get_balamod_version()
    collect(mods_repo_index_url, "mods")

    with open(config_path, "w") as f:
        json.dump(config_obj, f, indent=4)
    return 0

if __name__ == "__main__":
    main()
from urllib.request import Request, urlopen

mods_repo_index_url = "https://raw.githubusercontent.com/UwUDev/balamod/master/repos.index"
apis_repo_index_url = "https://raw.githubusercontent.com/UwUDev/balamod/master/apis.index"
headers = {"User-Agent": "Balamod client"}
file_name = "src/community-mods.md"

template = """
# Community Mods

<!-- toc -->

This is a list of mods created by the community. If you have a mod you would like to add to this list, please create a pull request on the [Balamod repository](https://github.com/UwUDev/balamod).

- root mods repo index is available [here](https://raw.githubusercontent.com/UwUDev/balamod/master/repos.index).
- root APIs repo index is available [here](https://raw.githubusercontent.com/UwUDev/balamod/master/apis.index).

## Mods

| Name | Version | Description |
|------|---------|-------------|
{mods}

## APIs

| Name | Version | Description |
|------|---------|-------------|
{apis}

"""

template_error = """
# Community Mods

An error occurred while fetching the list of mods. Please try again later.

{}

"""

template_mod = """| [{name}]({url}) | {version} | {description} |"""

def request(url):
    req = Request(url, headers=headers)
    try:
        response = urlopen(req)
        return True, response.read().decode()
    except Exception as e:
        return False, f"Request failed: {e}"

def write_to_file(data, file_name):
    if isinstance(data, dict):
        content = template.format(**data)
    else:
        content = data
    with open(file_name, "w") as f:
        f.write(content)

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

def collect(url):
    mod_list = []
    res, repos = request(url)
    if not res:
        write_to_file(repos, file_name)
        return False
    for repo in repos.split("\n"):
        if not repo:  # Skip if repo is empty
            continue
        res, mods = request(repo)
        if not res:
            write_to_file(mods, file_name)
            return False
        for mod in mods.split("\n"):
            if not mod:
                continue
            mod_list.append(parse_mod(mod))
    return mod_list

def main():
    mods = collect(mods_repo_index_url)
    if not mods:
        write_to_file(template_error.format(mods), file_name)
        print("Error")
        return 0
    mods = "\n".join([template_mod.format(**mod) for mod in mods])

    # apis = collect(apis_repo_index_url)
    # if not apis:
    #     write_to_file(template_error.format(apis), file_name)
    #     print("Error")
    #     return 0
    # apis = "\n".join([template_mod.format(**api) for api in apis])

    apis = "|No| APIs| available|"

    write_to_file({
        "mods": mods,
        "apis": apis,
    }, file_name)
    print("Done")
    return 0

if __name__ == "__main__":
    main()
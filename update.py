#!/usr/bin/env python3
import glob
import json
import os
import subprocess
import urllib.request
import re


def get_latest_release(owner, repo):
    url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
    req = urllib.request.Request(url, headers={"User-Agent": "nix-update-script"})
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read())
            return data.get("tag_name")
    except Exception:
        return None


def get_latest_commit(owner, repo):
    url = f"https://api.github.com/repos/{owner}/{repo}/commits"
    req = urllib.request.Request(url, headers={"User-Agent": "nix-update-script"})
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read())
            return data[0]["sha"]
    except Exception:
        return None


def version_key(version):
    """Sortable key for a version string (semver-ish).

    Components are split on ".", "-" and "+" and mapped to (number, suffix)
    pairs, so "3.0.0" > "2.1.1" and "1.2" < "1.2.1". Suffixes sort before
    "~" (the stand-in for a missing suffix), so prereleases compare older
    than the release they precede: "3.0.0-rc1" < "3.0.0". Purely
    alphabetic leading labels like "release-" are ignored.
    """
    key = []
    for comp in re.split(r"[.\-+]", str(version).lower().lstrip("vV")):
        if not comp:
            continue
        m = re.match(r"(\d*)(.*)", comp)
        key.append((int(m.group(1) or "0"), m.group(2) or "~"))
    while key and key[0][0] == 0 and key[0][1] != "~":
        key.pop(0)
    return key


VERSION_TAG_RE = re.compile(r"^[vV]?\d+\.\d+")


def is_older_version(candidate, current):
    """True if `candidate` is strictly older than `current` (semver-ish).

    Only compares strings that look like version tags ("3.0.0", "v2.1.1",
    "3.0.0-rc1"); anything else (commit hashes, "nightly") keeps the
    previous update behavior.
    """
    if not VERSION_TAG_RE.match(str(candidate)) or not VERSION_TAG_RE.match(str(current)):
        return False
    cand, cur = version_key(candidate), version_key(current)
    for i in range(max(len(cand), len(cur))):
        a = cand[i] if i < len(cand) else (0, "~")
        b = cur[i] if i < len(cur) else (0, "~")
        if a != b:
            return a < b
    return False


def prefetch_hash(owner, repo, rev):
    cmd = ["nix", "run", "nixpkgs#nix-prefetch-github", "--", owner, repo, "--rev", rev]
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    data = json.loads(result.stdout)
    return data["hash"]


def get_pypi_sdist(pname, version=None):
    """Return (version, sdist_url) for a PyPI project's source tarball.

    Without `version` the newest release is used. Returns (None, None) if the
    project or its sdist cannot be resolved (offline, renamed, wheels only).
    """
    endpoint = (
        f"https://pypi.org/pypi/{pname}/{version}/json"
        if version
        else f"https://pypi.org/pypi/{pname}/json"
    )
    req = urllib.request.Request(endpoint, headers={"User-Agent": "nix-update-script"})
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read())
    except Exception:
        return None, None
    resolved = version or data["info"]["version"]
    for f in data["urls"]:
        if f.get("packagetype") == "sdist" and f["filename"].endswith(".tar.gz"):
            return resolved, f["url"]
    return resolved, None


def parse_fetchpypi(content):
    """Extract (pname, version) from the `fetchPypi { ... }` call in a file.

    The fetchPypi pname is the *PyPI project name*, which often differs from
    the derivation's pname (e.g. jellyfin_mpv_shim vs jellyfin-mpv-shim) and
    is what the sdist URL is built from. `version` is None when the call uses
    `inherit version;`.
    """
    match = re.search(r"fetchPypi\s*\{([^{}]*)\}", content, re.S)
    if not match:
        return None, None
    body = match.group(1)
    pname = re.search(r'pname\s*=\s*"([^"]+)"', body)
    version = re.search(r'version\s*=\s*"([^"]+)"', body)
    return (pname.group(1) if pname else None), (version.group(1) if version else None)


def prefetch_url_hash(url):
    cmd = ["nix", "store", "prefetch-file", "--json", url]
    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if result.returncode == 0:
        return json.loads(result.stdout)["hash"]
    return None


def get_latest_git_tag(url):
    cmd = ["git", "ls-remote", "--tags", url]
    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        return None, None
    tags = []
    for line in result.stdout.strip().split("\n"):
        if not line:
            continue
        parts = line.split("\t")
        if len(parts) != 2:
            continue
        rev, ref = parts
        if ref.endswith("^{}"):
            continue
        tags.append((ref.replace("refs/tags/", ""), rev))
    if not tags:
        return None, None
    # Highest version wins, so we never "update" to an older tag.
    best_tag, best_rev = max(tags, key=lambda t: version_key(t[0]))
    return best_tag, best_rev


def get_all_pkg_info():
    expr = """
    with builtins;
    let
      flake = getFlake (toString ./.);
      pkgs = flake.packages.${currentSystem};
      getInfo = name: p: let src = if p ? src then p.src else null; in {
        inherit name;
        pname = p.pname or p.name or null;
        version = p.version or null;
        src = if src != null then {
          owner = src.owner or null;
          repo = src.repo or null;
          rev = src.rev or null;
          hash = src.outputHash or null;
          url = src.url or null;
          urls = src.urls or null;
        } else null;
      };
    in mapAttrs getInfo pkgs
    """
    cmd = ["nix", "eval", "--json", "--impure", "--expr", expr]
    res = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if res.returncode != 0:
        print("Failed to evaluate flake packages!")
        return {}
    return json.loads(res.stdout)


def get_pkg_data_for_file(filepath, all_data):
    base = os.path.basename(filepath)
    name = (
        os.path.basename(os.path.dirname(filepath))
        if base == "default.nix"
        else base.replace(".nix", "")
    )
    if name in all_data:
        return all_data[name]
    for v in all_data.values():
        if v.get("pname") == name or v.get("pname") == name.replace("-", "_"):
            return v
    return None


def update_file(filepath, pkg_data):
    if not pkg_data or not pkg_data.get("src"):
        return

    src = pkg_data["src"]
    with open(filepath, "r") as f:
        content = f.read()

    new_content = content
    current_version = pkg_data.get("version")
    current_hash = src.get("hash")
    current_rev = src.get("rev")

    latest_version = None
    latest_rev = None
    new_hash = None

    try:
        if "fetchFromGitHub" in content and src.get("owner") and src.get("repo"):
            owner, repo = src["owner"], src["repo"]
            is_commit = (
                current_rev
                and len(current_rev) == 40
                and all(c in "0123456789abcdefABCDEF" for c in current_rev)
            )
            latest_rev = (
                get_latest_commit(owner, repo)
                if is_commit
                else get_latest_release(owner, repo)
            )
            if not latest_rev and not is_commit:
                latest_rev = get_latest_commit(owner, repo)
            if latest_rev and not is_commit and is_older_version(latest_rev, current_rev):
                print(
                    f"[{filepath}] Skipping {owner}/{repo}: latest release "
                    f"{latest_rev} is older than current {current_rev} "
                    "(prerelease pinned?)"
                )
                latest_rev = None
            if latest_rev and latest_rev != current_rev:
                # A release tag carries the version too; derive it so the
                # version attribute stays in sync when the rev is written
                # indirectly, e.g. rev = "v${finalAttrs.version}".
                if VERSION_TAG_RE.match(latest_rev):
                    latest_version = latest_rev.lstrip("v")
                new_hash = prefetch_hash(owner, repo, latest_rev)

                # Rust packages that vendor their Cargo.lock for
                # importCargoLock (pure eval cannot read it out of the fetched
                # src) must keep the vendored copy in sync with the src rev;
                # cargoRoot says where upstream keeps it.
                lockfile = re.search(r"lockFile = \./([A-Za-z0-9_.-]+Cargo\.lock)", content)
                if lockfile:
                    cargo_root = re.search(r'cargoRoot = "([^"]+)"', content)
                    root_path = (cargo_root.group(1) + "/") if cargo_root else ""
                    lock_url = (
                        f"https://raw.githubusercontent.com/{owner}/{repo}/{latest_rev}"
                        f"/{root_path}Cargo.lock"
                    )
                    dest = os.path.join(os.path.dirname(filepath) or ".", lockfile.group(1))
                    try:
                        req = urllib.request.Request(lock_url, headers={"User-Agent": "nix-update-script"})
                        with urllib.request.urlopen(req, timeout=30) as response:
                            lock_data = response.read()
                        with open(dest, "wb") as f:
                            f.write(lock_data)
                        print(f"[{filepath}] Updated vendored Cargo.lock from rev {latest_rev}")
                    except Exception as e:
                        print(f"[{filepath}] Failed to update vendored Cargo.lock: {e}")

        elif "fetchPypi" in content and current_hash:
            pypi_pname, pinned_version = parse_fetchpypi(content)
            pypi_pname = pypi_pname or (pkg_data.get("pname") or "").replace("-", "_")
            pinned_version = pinned_version or current_version
            if pypi_pname and pinned_version:
                latest_version, sdist_url = get_pypi_sdist(pypi_pname)
                if latest_version is not None:
                    if latest_version == pinned_version:
                        # Nothing to bump, but the hash is still re-checked
                        # below: PyPI allows a yanked release to be
                        # re-uploaded with different contents, which silently
                        # invalidates the hash pinned for that version.
                        latest_version = None
                    elif is_older_version(latest_version, pinned_version):
                        print(
                            f"[{filepath}] Skipping {pypi_pname}: latest {latest_version} "
                            f"is older than current {pinned_version} "
                            "(prerelease pinned?)"
                        )
                        latest_version, sdist_url = None, None
                if sdist_url:
                    new_hash = prefetch_url_hash(sdist_url)
                    if new_hash == current_hash:
                        new_hash = None

        elif ("builtins.fetchGit" in content or "fetchGit" in content) and (
            src.get("url") or src.get("urls")
        ):
            url = src.get("url") or src.get("urls")[0]
            if url and current_rev:
                tag, latest_rev = get_latest_git_tag(url)
                if tag and latest_rev != current_rev:
                    latest_version = tag.lstrip("v")
                    if current_version and is_older_version(latest_version, current_version):
                        print(
                            f"[{filepath}] Skipping: latest tag {tag} is older "
                            f"than current {current_version} (prerelease pinned?)"
                        )
                        latest_version = None
                        latest_rev = None

        elif src.get("url") and "github.com/" in src.get("url") and "/releases/download/" in src.get("url") and current_version:
            url_str = src.get("url")
            match = re.search(r"https://github\.com/([^/]+)/([^/]+)/releases/download/", url_str)
            if match:
                owner, repo = match.group(1), match.group(2)
                latest_tag = get_latest_release(owner, repo)
                if latest_tag:
                    latest_version = latest_tag.lstrip("v")
                    if latest_version != current_version:
                        if is_older_version(latest_version, current_version):
                            print(
                                f"[{filepath}] Skipping: latest release "
                                f"{latest_tag} is older than current "
                                f"{current_version} (prerelease pinned?)"
                            )
                            latest_version = None
                        else:
                            new_url = url_str.replace(current_version, latest_version)
                            new_hash = prefetch_url_hash(new_url)
    except Exception as e:
        print(f"[{filepath}] Failed to fetch updates: {e}")
        return

    if latest_version and current_version and latest_version != current_version:
        print(f"[{filepath}] Updating version {current_version} -> {latest_version}...")
        new_content = new_content.replace(
            f'version = "{current_version}"', f'version = "{latest_version}"'
        )

    if latest_rev and current_rev and latest_rev != current_rev:
        print(f"[{filepath}] Updating rev {current_rev} -> {latest_rev}...")
        new_content = new_content.replace(
            f'rev = "{current_rev}"', f'rev = "{latest_rev}"'
        )

    if new_hash and current_hash:
        if new_hash != current_hash:
            print(f"[{filepath}] Updating hash {current_hash} -> {new_hash}...")
        new_content = new_content.replace(
            f'hash = "{current_hash}"', f'hash = "{new_hash}"'
        )

    if content != new_content:
        with open(filepath, "w") as f:
            f.write(new_content)


def main():
    print("Evaluating packages via Nix AST...")
    all_data = get_all_pkg_info()
    if not all_data:
        return

    files = glob.glob("pkgs/*.nix") + glob.glob("pkgs/*/*.nix")
    for f in files:
        data = get_pkg_data_for_file(f, all_data)
        update_file(f, data)
    print("Done checking all packages.")


if __name__ == "__main__":
    main()

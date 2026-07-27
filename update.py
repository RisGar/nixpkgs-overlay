#!/usr/bin/env python3
import os
import re
import json
import glob
import urllib.request
import subprocess
import sys

def get_latest_release(owner, repo):
    url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
    req = urllib.request.Request(url, headers={'User-Agent': 'nix-update-script'})
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read())
            return data.get('tag_name')
    except Exception as e:
        return None

def get_latest_commit(owner, repo):
    url = f"https://api.github.com/repos/{owner}/{repo}/commits"
    req = urllib.request.Request(url, headers={'User-Agent': 'nix-update-script'})
    try:
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read())
            return data[0]['sha']
    except Exception as e:
        return None

def prefetch_hash(owner, repo, rev):
    cmd = ["nix", "run", "nixpkgs#nix-prefetch-github", "--", owner, repo, "--rev", rev]
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    data = json.loads(result.stdout)
    return data['hash']

def update_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    new_content = content
    blocks = list(re.finditer(r'fetchFromGitHub\s*\{([^}]+)\}', content))
    
    for block_match in blocks:
        block = block_match.group(1)
        owner_m = re.search(r'owner\s*=\s*"([^"]+)"', block)
        repo_m = re.search(r'repo\s*=\s*"([^"]+)"', block)
        rev_m = re.search(r'rev\s*=\s*"([^"]+)"', block)
        hash_m = re.search(r'(hash|sha256)\s*=\s*"([^"]+)"', block)
        
        if not (owner_m and repo_m and rev_m and hash_m):
            continue
            
        owner = owner_m.group(1)
        repo = repo_m.group(1)
        rev = rev_m.group(1)
        hash_type = hash_m.group(1)
        current_hash = hash_m.group(2)
        
        is_commit = len(rev) == 40 and all(c in "0123456789abcdefABCDEF" for c in rev)
        
        if is_commit:
            print(f"[{filepath}] {owner}/{repo}: Uses commit, checking latest commit...")
            latest_rev = get_latest_commit(owner, repo)
        else:
            print(f"[{filepath}] {owner}/{repo}: Uses release ({rev}), checking latest release...")
            latest_rev = get_latest_release(owner, repo)
            if not latest_rev:
                print(f"[{filepath}] {owner}/{repo}: No release found, falling back to latest commit...")
                latest_rev = get_latest_commit(owner, repo)
                
        if not latest_rev:
            print(f"[{filepath}] {owner}/{repo}: Failed to get latest rev.")
            continue

        if latest_rev == rev:
            print(f"[{filepath}] {owner}/{repo}: Already up-to-date ({rev}).")
            continue

        print(f"[{filepath}] {owner}/{repo}: Updating {rev} -> {latest_rev}...")
        try:
            new_hash = prefetch_hash(owner, repo, latest_rev)
            
            old_rev_str = f'rev = "{rev}"'
            new_rev_str = f'rev = "{latest_rev}"'
            old_hash_str = f'{hash_type} = "{current_hash}"'
            new_hash_str = f'hash = "{new_hash}"' # Standardize on SRI hash attribute
            
            new_content = new_content.replace(old_rev_str, new_rev_str)
            new_content = new_content.replace(old_hash_str, new_hash_str)
            
            print(f"[{filepath}] {owner}/{repo}: Successfully updated.")
        except Exception as e:
            print(f"[{filepath}] {owner}/{repo}: Failed to prefetch hash: {e}")

    if content != new_content:
        with open(filepath, 'w') as f:
            f.write(new_content)

def main():
    files = glob.glob("pkgs/*.nix")
    for f in files:
        update_file(f)
    print("Done checking all packages.")

if __name__ == "__main__":
    main()

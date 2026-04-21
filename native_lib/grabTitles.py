#!/bin/env python
import os
import urllib.request
import ssl

def checkAndDeleteFile(file):
    if os.path.exists(file):
        print(f"Deleting {file}")
        os.remove(file)

# Disable certificate verification
ssl_context = ssl.create_default_context()
ssl_context.check_hostname = False
ssl_context.verify_mode = ssl.CERT_NONE

opener = urllib.request.build_opener(urllib.request.HTTPSHandler(context=ssl_context))
opener.addheaders = [("User-agent", "NUSspliBuilder/2.1")]
urllib.request.install_opener(opener)

dest_path = "db.go"
checkAndDeleteFile(dest_path)

print("Downloading db.go...")

with urllib.request.urlopen("https://napi.v10lator.de/db?t=go") as response:
    content_bytes = response.read()
    content = content_bytes.decode("utf-8") 

before, sep, after = content.partition("var titleEntry")
content = "package main\nimport wiiudownloader \"github.com/Xpl0itU/WiiUDownloader\"\n" + sep + after
content = content.replace("[]TitleEntry{", "[]wiiudownloader.TitleEntry{")

with open(dest_path, "w", encoding="utf-8") as f:
    f.write(content)

print(f"Database saved to {dest_path}")
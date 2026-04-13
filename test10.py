import urllib.request
from bs4 import BeautifulSoup
url = "https://wiki.hyprland.org/Configuring/Variables/"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
html = urllib.request.urlopen(req).read()
soup = BeautifulSoup(html, 'html.parser')
tags = soup.find_all(text=lambda x: x and 'workspace_swipe' in x.lower())
for t in tags:
    print(t.strip())

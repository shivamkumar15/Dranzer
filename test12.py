import urllib.request
from bs4 import BeautifulSoup
url = "https://wiki.hyprland.org/Configuring/Variables/"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
html = urllib.request.urlopen(req).read()
soup = BeautifulSoup(html, 'html.parser')

for t in soup.find_all(string=lambda x: x and ('workspace_swipe_fingers' in x.lower() or x.strip() == 'workspace_swipe')):
    parent = t.parent.parent
    print("--- CONTEXT ---")
    print(parent.get_text())

import urllib.request
from bs4 import BeautifulSoup
url = "https://wiki.hyprland.org/Configuring/Variables/"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
html = urllib.request.urlopen(req).read()
soup = BeautifulSoup(html, 'html.parser')

for t in soup.find_all(string=lambda x: x and ('workspace_swipe_fingers' in x.lower() or x.strip() == 'workspace_swipe')):
    parent = t.find_parent('table')
    if parent:
        prev = parent.find_previous(['h2', 'h3'])
        print(f"FOUND IN TABLE UNDER HEADING: {prev.get_text()}")
    else:
        print(f"FOUND NOT IN TABLE: {t.strip()}")

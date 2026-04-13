import urllib.request
from bs4 import BeautifulSoup
url = "https://wiki.hyprland.org/Configuring/Binds/"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
html = urllib.request.urlopen(req).read()
soup = BeautifulSoup(html, 'html.parser')
for t in soup.find_all(string=lambda x: x and 'swipe' in x.lower()):
    print("--- CONTEXT ---")
    print(t.parent.get_text())

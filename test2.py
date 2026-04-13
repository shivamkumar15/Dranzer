import urllib.request
from bs4 import BeautifulSoup
url = "https://wiki.hyprland.org/Configuring/Variables/"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
html = urllib.request.urlopen(req).read()
soup = BeautifulSoup(html, 'html.parser')

for header in soup.find_all(['h2', 'h3']):
    nextNode = header
    while True:
        nextNode = nextNode.nextSibling
        if nextNode is None:
            break
        if nextNode.name in ['h2', 'h3']:
            break
        if nextNode.name == 'table':
            text = nextNode.get_text()
            if 'workspace_swipe' in text:
                print("HEADING:", header.get_text())
                break

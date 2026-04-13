import urllib.request
from bs4 import BeautifulSoup
url = "https://wiki.hyprland.org/Configuring/Variables/"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
html = urllib.request.urlopen(req).read()
soup = BeautifulSoup(html, 'html.parser')

for table in soup.find_all('table'):
    prev = table.find_previous(['h2', 'h3'])
    heading = prev.get_text().lower()
    if 'gestures' in heading or 'touchpad' in heading or 'input' in heading:
        print("======== HEADING:", heading)
        for row in table.find_all('tr'):
            cols = [col.get_text() for col in row.find_all('td')]
            if len(cols) > 0 and ('swipe' in cols[0] or 'finger' in cols[0]):
                print(cols[0])

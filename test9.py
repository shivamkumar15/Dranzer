import urllib.request
from bs4 import BeautifulSoup
url = "https://wiki.hyprland.org/Configuring/Variables/"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
html = urllib.request.urlopen(req).read()
soup = BeautifulSoup(html, 'html.parser')
for table in soup.find_all('table'):
    prev = table.find_previous(['h2', 'h3'])
    if prev and 'Gestures' in prev.get_text():
        for row in table.find_all('tr'):
            cols = [col.get_text().strip() for col in row.find_all('td')]
            if len(cols) > 0:
                print(cols[0])

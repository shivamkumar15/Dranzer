import urllib.request
from bs4 import BeautifulSoup
url = "https://wiki.hyprland.org/Configuring/Variables/"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
html = urllib.request.urlopen(req).read()
soup = BeautifulSoup(html, 'html.parser')
for table in soup.find_all('table'):
    for row in table.find_all('tr'):
        cols = [col.get_text() for col in row.find_all('td')]
        if len(cols) > 0 and cols[0].strip() == 'workspace_swipe':
            prev = table.find_previous(['h2', 'h3'])
            print(f"[{prev.get_text()}] {cols[0]}")
        elif len(cols) > 0 and cols[0].strip() == 'workspace_swipe_fingers':
            prev = table.find_previous(['h2', 'h3'])
            print(f"[{prev.get_text()}] {cols[0]}")

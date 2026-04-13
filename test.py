import urllib.request
from bs4 import BeautifulSoup
url = "https://wiki.hyprland.org/Configuring/Variables/"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
html = urllib.request.urlopen(req).read()
soup = BeautifulSoup(html, 'html.parser')
for table in soup.find_all('table'):
    text = table.get_text()
    if 'workspace_swipe' in text:
        print("FOUND IN TABLE:")
        for row in table.find_all('tr'):
            if 'workspace_swipe' in row.get_text():
                print(row.get_text(separator=' | '))

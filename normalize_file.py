import pathlib
import re
import sys

import bs4


for path in sys.argv[1:]:
    path = pathlib.Path(path)

    soup = bs4.BeautifulSoup(path.read_text(), features="html.parser")
    html = soup.prettify()

    html = re.sub(r'\b(0x)[a-f0-9]+\b', r'\1...', html)
    html = re.sub(r'^(Build Date UTC ?:).+', r'\1...', html, flags=re.MULTILINE)
    html = re.sub(r'\b[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\b', r'...', html)
    html = re.sub(r'(?<=id="cell-id=)\w+(?=")', r'...', html)

    path.write_text(html)

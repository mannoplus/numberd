import requests
import re
url = "https://www.taiwanlottery.com/game/dailycash/past"
res = requests.get(url, headers={"User-Agent": "Mozilla/5.0"})
matches = re.findall(r'TLCAPIWeB.*?Result', res.text)
print("Found in body:", set(matches))

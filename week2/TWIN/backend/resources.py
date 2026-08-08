from pypdf import PdfReader
import json

# Read LinkedIn PDF
try:
    reader = PdfReader("./data/linkdin.pdf")
    linkedin = ""
    for page in reader.pages:
        text = page.extract_text()
        if text:
            linkedin += text
except FileNotFoundError:
    linkedin = "LinkedIn profile not available"

# Read other data files
with open("../data/summary.txt", "r", encoding="utf-8") as f:
    summary = f.read()

with open("../data/style.txt", "r", encoding="utf-8") as f:
    style = f.read()

with open("../data/facts.json", "r", encoding="utf-8") as f:
    facts = json.load(f)
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def instant():
    return "Live from production!"
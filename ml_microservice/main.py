from fastapi import FastAPI

app = FastAPI(title="SparMate ML Microservice")

@app.get("/")
def read_root():
    return {"status": "online", "service": "SparMate AI"}

@app.post("/calculate-bkt")
def calculate_bkt():
    # TODO: Implement Bayesian Knowledge Tracing logic here
    return {"message": "BKT calculation endpoint ready"}
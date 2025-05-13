from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uvicorn
import os
import json
import faiss
import numpy as np
from sentence_transformers import SentenceTransformer
from typing import List

app = FastAPI()

with open("train.json", "r", encoding="utf-8") as f:
    tickets = json.load(f)

embedding_model = SentenceTransformer('all-MiniLM-L6-v2')

ticket_texts = []
ticket_responses = []
ticket_metadata = []

for ticket in tickets:
    metadata = f"Title: {ticket['title']}\nCategory: {ticket['category']}\nDescription: {ticket['description']}"
    dialog = "\n".join([f"{m['role'].capitalize()}: {m['text']}" for m in ticket["history"]])
    combined_text = f"{metadata}\nConversation:\n{dialog}"
    ticket_texts.append(combined_text)
    ticket_responses.append(ticket["next_engineer_reply"])
    ticket_metadata.append({"category": ticket["category"]})

embeddings = embedding_model.encode(ticket_texts, convert_to_numpy=True)
index = faiss.IndexFlatL2(embeddings.shape[1])
index.add(embeddings)

try:
    from openai import OpenAI
except ImportError:
    OpenAI = None

def generate_reply(messages, model="gpt-4", provider="openai", **kwargs):
    if provider == "openai":
        if OpenAI is None:
            raise ImportError("OpenAI client not available.")
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            raise ValueError("Set the OPENAI_API_KEY environment variable.")
        client = OpenAI(api_key=api_key)
        response = client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=kwargs.get("temperature", 0.4)
        )
        return response.choices[0].message.content.strip()
    else:
        raise ValueError(f"Unsupported provider: {provider}")

class Message(BaseModel):
    role: str
    text: str

class TicketInput(BaseModel):
    title: str
    category: str
    description: str
    history: List[Message]

@app.post("/predict")
def predict_reply(ticket: TicketInput):
    query_metadata = f"Title: {ticket.title}\nCategory: {ticket.category}\nDescription: {ticket.description}"
    dialog = "\n".join([f"{m.role.capitalize()}: {m.text}" for m in ticket.history])
    query_text = f"{query_metadata}\nConversation:\n{dialog}"
    query_embedding = embedding_model.encode([query_text], convert_to_numpy=True)

    distances, indices = index.search(query_embedding, 20)

    boosted, fallback = [], []
    for dist, idx in zip(distances[0], indices[0]):
        candidate_category = ticket_metadata[idx]['category']
        adjusted_dist = dist * 0.85 if candidate_category == ticket.category else dist
        (boosted if candidate_category == ticket.category else fallback).append((adjusted_dist, idx))

    boosted.sort(key=lambda x: x[0])
    fallback.sort(key=lambda x: x[0])
    needed = 3 - len(boosted)
    top_adjusted = boosted + fallback[:needed] if needed > 0 else boosted[:3]

    prompt_parts = ["You are a helpful technical support engineer.\n"]
    for _, idx in top_adjusted:
        prompt_parts.append(f"Example:\n{ticket_texts[idx]}\nEngineer: {ticket_responses[idx]}\n")
    prompt_parts.append("Now, consider this support case:\n")
    prompt_parts.append(query_text)
    prompt_parts.append("Engineer:")
    full_prompt = "\n".join(prompt_parts)

    messages = [
        {"role": "system", "content": "You are a technical support engineer."},
        {"role": "user", "content": full_prompt}
    ]

    try:
        reply = generate_reply(messages)
        return {"reply": reply}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    uvicorn.run("rag_api_server:app", host="0.0.0.0", port=8000, reload=True)

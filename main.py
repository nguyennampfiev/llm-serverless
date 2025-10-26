# app.py
import os
from fastapi import FastAPI
import gradio as gr
from mangum import Mangum
from openai import OpenAI
import dotenv
# load .env variables
dotenv.load_dotenv()
api_key = os.getenv("OPENAI_API_KEY")

app = FastAPI(title="Gradio LLM Chat")

# === LLM call (simple OpenAI example) ===
def llm_reply(prompt: str):
    client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key=api_key,
    )

    completion = client.chat.completions.create(
    extra_headers={
        "HTTP-Referer": "<YOUR_SITE_URL>", # Optional. Site URL for rankings on openrouter.ai.
        "X-Title": "<YOUR_SITE_NAME>", # Optional. Site title for rankings on openrouter.ai.
    },
    extra_body={},
    model="mistralai/devstral-small-2505:free",
    messages=[
        {
        "role": "user",
        "content": prompt
        }
    ]
    )
    return completion.choices[0].message.content

# === Gradio interface as a Blocks chat UI ===
with gr.Blocks() as gradio_ui:
    gr.Markdown("# 🤖 Serverless LLM Chat")
    chatbot = gr.Chatbot()
    txt = gr.Textbox(placeholder="Ask a question...")
    def submit_fn(user, history):
        resp = llm_reply(user)
        history = history or []
        history.append((user, resp))
        return history, history
    txt.submit(submit_fn, [txt, chatbot], [chatbot, chatbot])
    gr.Button("Clear").click(lambda: None, None, chatbot, queue=False)

# mount Gradio into FastAPI at /chat
app = gr.mount_gradio_app(app, gradio_ui, path="/chat")

# simple root endpoint
@app.get("/")
def root():
    return {"status": "ok", "docs": "/docs"}

# Mango — adapter to run on Lambda (event -> ASGI)
handler = Mangum(app)

import gradio as gr
from typing import List
from main import TicketInput, Message, predict_reply  # assumes FastAPI logic is in main.py

# Define categories you support
CATEGORIES = ["Authentication", "Data Sync", "Stability", "Export/Import", "Billing"]

# Store conversation state across turns
def chatbot_fn(title, category, description, chat_history: List[List[str]], message: str):
    # Accumulate chat history into Message objects
    history = []
    for user, bot in chat_history:
        if user:  history.append(Message(role="customer", text=user))
        if bot:   history.append(Message(role="engineer", text=bot))
    history.append(Message(role="customer", text=message))

    # Build the input
    ticket = TicketInput(
        title=title,
        category=category,
        description=description,
        history=history
    )

    # Get prediction from model
    response = predict_reply(ticket)
    reply = response["reply"]

    # Return updated chat history
    chat_history.append([message, reply])
    return chat_history, ""  # clear input box

with gr.Blocks() as demo:
    gr.Markdown("## 🛠️ Technical Support Chatbot (RAG-Powered)")
    
    with gr.Row():
        title = gr.Textbox(label="Ticket Title", value="Notes not syncing")
        category = gr.Dropdown(CATEGORIES, value="Data Sync", label="Category")
    description = gr.Textbox(label="Description", value="User notes are not syncing between phone and tablet.")

    chatbot = gr.Chatbot(label="Conversation", height=400)
    msg_input = gr.Textbox(label="Your Message", placeholder="Type your support question here...")

    submit = gr.Button("Send")
    clear = gr.Button("Clear Chat")

    submit.click(
        chatbot_fn,
        inputs=[title, category, description, chatbot, msg_input],
        outputs=[chatbot, msg_input]
    )
    clear.click(lambda: ([], ""), None, [chatbot, msg_input])

if __name__ == "__main__":
    demo.launch()

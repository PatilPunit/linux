import requests
import json
from tool import run_command, install_package

OLLAMA_URL = "http://localhost:11434/api/chat"
MODEL = "qwen2.5:3b"

TOOLS = {
    "run_command": run_command,
    "install_package": install_package
}

TOOL_DEFINITIONS = [
    {
        "type": "function",
        "function": {
            "name": "run_command",
            "description": "Run a shell command on the system",
            "parameters": {
                "type": "object",
                "properties": {
                    "command": {"type": "string", "description": "The shell command to run"}
                },
                "required": ["command"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "install_package",
            "description": "Install a package using pacman",
            "parameters": {
                "type": "object",
                "properties": {
                    "package_name": {"type": "string", "description": "Name of the package to install"}
                },
                "required": ["package_name"]
            }
        }
    }
]

def ask_model(messages):
    response = requests.post(OLLAMA_URL, json={
        "model": MODEL,
        "messages": messages,
        "tools": TOOL_DEFINITIONS,
        "stream": False
    })
    return response.json()

def agent_loop(user_task):
    messages = [{"role": "user", "content": user_task}]

    for step in range(10):
        result = ask_model(messages)
        message = result["message"]
        messages.append(message)

        if "tool_calls" not in message or not message["tool_calls"]:
            print(message["content"])
            break

        for call in message["tool_calls"]:
            fn_name = call["function"]["name"]
            args = call["function"]["arguments"]

            print(f"\n[AI wants to run]: {fn_name}({args})")
            confirm = input("Allow this? (y/n): ")

            if confirm.lower() != "y":
                messages.append({"role": "tool", "content": "User denied this action."})
                continue

            output = TOOLS[fn_name](**args)
            print(f"[Result]: {output}")
            messages.append({"role": "tool", "content": output})
"""
Minimal CrewAI + Local llama-server example.
Install: pip install crewai litellm
"""

import os
import requests
from crewai import Agent, Task, Crew, Process
from litellm import completion

# Option 1: Local llama-server (already running on port 8080)
# Uses OpenAI-compatible API at http://localhost:8080/v1
# Model: Qwen2.5 1.5B Q4 (fits in ~2GB VRAM)
LOCAL_SERVER = "http://localhost:8080/v1"
USE_LOCAL = True

# Option 2: OpenCode Go (set your API key and USE_LOCAL=False)
# os.environ["OPENCODE_GO_API_KEY"] = "sk-xxxxxxxxxxxxx"

if USE_LOCAL:
    os.environ["LITELLM_MODEL"] = "openai/qwen2.5-1.5b-instruct"
    os.environ["LITELLM_API_KEY"] = "dummy-key"  # local server doesn't need auth
    os.environ["LITELLM_BASE_URL"] = LOCAL_SERVER
else:
    os.environ["LITELLM_MODEL"] = "opencode-go/minimax-m2.5"
    os.environ["LITELLM_API_KEY"] = os.environ.get("OPENCODE_GO_API_KEY", "")
    os.environ["LITELLM_BASE_URL"] = "https://opencode.ai/zen/go/v1"

def get_completion(messages, model=None):
    """Custom LLM wrapper for local server."""
    return completion(
        model=os.environ["LITELLM_MODEL"],
        messages=messages,
    )

# Define the manager agent (smart, coordinates others)
manager = Agent(
    role="Project Manager",
    goal="Coordinate a team to complete complex tasks efficiently",
    backstory="""
    You are an experienced project manager who specializes in breaking down
    complex tasks into smaller pieces and assigning them to specialized agents.
    You coordinate researchers, coders, and reviewers to get work done.
    """,
    verbose=True,
    llm=get_completion,
)

# Define worker agents
researcher = Agent(
    role="Code Researcher",
    goal="Find relevant code and understand the codebase",
    backstory="""
    You are an expert at exploring codebases, finding files, and understanding
    how different parts of a project work together.
    """,
    verbose=True,
    llm=get_completion,
)

coder = Agent(
    role="Software Coder",
    goal="Write clean, working code based on requirements",
    backstory="""
    You are a skilled programmer who writes clean, maintainable code.
    You follow best practices and write tests for your code.
    """,
    verbose=True,
    llm=get_completion,
)

# Example task: research and understand a codebase, then implement a feature
research_task = Task(
    description="""
    Explore the codebase to understand:
    1. What is the main purpose of this project?
    2. What is the directory structure?
    3. What language(s) and frameworks are used?
    """,
    agent=researcher,
    expected_output="A summary of the codebase structure and technologies used",
)

code_task = Task(
    description="""
    Based on the research, create a simple 'hello world' function in the
    appropriate language for this project. Output the file path and content.
    """,
    agent=coder,
    expected_output="File path and content of the hello world implementation",
)

# Create crew with hierarchical process (manager coordinates workers)
crew = Crew(
    agents=[manager, researcher, coder],
    tasks=[research_task, code_task],
    process=Process.hierarchical,
    manager_agent=manager,
    verbose=True,
)

# Run the crew
result = crew.kickoff()
print("\n=== FINAL RESULT ===")
print(result)
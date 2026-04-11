planmode

I want to write a openclaw alternative in elixit. Create a plan and architecture

Perform deepthinkmode

Absolutely. I’ll treat “elixit” as Elixir.

If your goal is to build an OpenClaw-style personal AI assistant in Elixir, the right move is not to clone every OpenClaw feature first. OpenClaw’s surface area is already broad: a local-first gateway, many messaging channels, multi-agent routing, sessions, cron, canvas, browser/tools, onboarding, and skills.

The smarter approach is:

build the core agent runtime
make it safe and observable
add channels + tools
only then add multi-agent orchestration and richer UI surfaces

Elixir is a strong fit because the problem is mostly about concurrency, supervision, queues, long-running sessions, retries, isolation, and distributed runtime behavior—all areas where OTP/BEAM shines. An existing Elixir-based OpenClaw node project also highlights BEAM strengths like telemetry, clustering, hot reload, and long-running reliability.

1. Product definition
   What you are building

An agent platform, not just a chatbot.

At minimum, your system should support:

persistent user/workspace identity
conversational sessions
tool calling
background jobs
memory
multi-channel I/O
secure execution boundaries
observability
extensibility through skills/plugins

That lines up with the parts that make OpenClaw interesting: local-first control plane, session model, channel integrations, first-class tools, skills, and proactive/background behavior.

Recommended product position

Instead of “OpenClaw clone,” define it as:

A local-first, OTP-native personal agent platform with strong supervision, secure tool execution, and channel-first automation.

That gives you a clean differentiator:

OpenClaw is broad and fast-moving
your Elixir version can be more reliable, more inspectable, and more operationally safe 2) Strategic architecture choice

You have two possible directions.

Option A — Monolithic OTP app first

One Phoenix/OTP application that contains:

API
websocket event bus
session runtime
tool runtime
job scheduler
memory pipeline
channel adapters

This is the best choice for v1.

Why
fewer moving parts
easier local-first deployment
easier tracing/debugging
simpler supervision tree
better velocity
Option B — Service split from day one

Separate services for:

gateway
inference broker
memory
tool sandbox
channel adapters
scheduler

This is only worth it if you already know you need multi-machine scale or hard isolation boundaries.

Recommendation

Start with Option A, but design internal boundaries so you can later extract:

tool runner
inference broker
memory/indexing
channel adapters 3) Core system architecture

Here is the architecture I’d recommend.

                         ┌─────────────────────────────┐
                         │         Client UIs          │
                         │  Web / Mobile / CLI / Chat  │
                         └──────────────┬──────────────┘
                                        │
                              HTTP / WS / Webhooks
                                        │
                     ┌──────────────────▼──────────────────┐
                     │         Phoenix Gateway              │
                     │  Auth, API, WS, channel ingress      │
                     └───────┬──────────────┬──────────────┘
                             │              │
                             │ events       │ commands
                             │              │
              ┌──────────────▼───────┐   ┌──▼──────────────────┐
              │   Session Runtime     │   │   Channel Adapters  │
              │ GenServer per session │   │ Slack/Telegram/etc. │
              └───────┬───────────────┘   └──────────┬──────────┘
                      │                              │
                      │ tool plans / LLM calls       │ inbound/outbound
                      │                              │
      ┌───────────────▼────────────────────────────────────────────┐
      │                     Orchestrator Layer                      │
      │ planner / policy / tool router / interrupt handling        │
      └───────┬───────────────────────────────┬────────────────────┘
              │                               │
              │                               │

┌───────────▼───────────┐ ┌──────────▼───────────┐
│ LLM Broker │ │ Tool Runtime │
│ OpenAI/Anthropic/local │ │ sandboxed execution │
└───────────┬───────────┘ └──────────┬───────────┘
│ │
│ │
┌──────────▼─────────┐ ┌──────────▼──────────────┐
│ Memory + Retrieval │ │ Jobs / Cron / Workflows │
│ pgvector + ETS │ │ Oban / scheduler │
└──────────┬─────────┘ └──────────┬──────────────┘
│ │
└──────────────┬────────────────┘
│
┌────────▼────────┐
│ Postgres / Blob │
│ state, events, │
│ embeddings, │
│ artifacts │
└─────────────────┘ 4) OTP-native design

This is where Elixir should really win.

Supervision model

Use supervisors aggressively.

Suggested tree
ApplicationSupervisor
├── TelemetrySupervisor
├── Repo
├── PubSub
├── Presence
├── Registry
├── DynamicSupervisor(SessionSupervisor)
├── DynamicSupervisor(ChannelSupervisor)
├── DynamicSupervisor(ToolWorkerSupervisor)
├── Oban
├── CacheSupervisor
└── Endpoint
Session model

Create one process per active session.

Each session process owns:

conversation state
pending tool calls
local short-term memory
cancellation state
rate limiting/token budget
currently running tasks
Session state
%SessionState{
session_id: "...",
workspace_id: "...",
user_id: "...",
mode: :interactive | :background,
messages: [...],
scratchpad: %{...},
tool_context: %{...},
memory_refs: [...],
status: :idle | :planning | :executing | :waiting_user,
active_run_id: "...",
permissions: %{...}
}
Why this is good
session crash does not crash the whole app
retries are local
OTP supervision gives clean restart semantics
easy to isolate concurrent conversations
good fit for background tasks and long-lived flows 5) Key bounded contexts

Break the codebase into domains early.

A. Gateway

Responsibilities:

REST/GraphQL/WS API
auth
websocket streams
webhook ingress from channels
event fanout

Suggested modules:

ClawWeb.Endpoint
ClawWeb.Router
Claw.Gateway.Dispatcher
B. Sessions

Responsibilities:

hold conversation/session state
invoke planner
execute step loop
handle interrupts/cancellations
emit events

Suggested modules:

Claw.Sessions.SessionServer
Claw.Sessions.Supervisor
Claw.Sessions.Registry
C. Orchestrator

Responsibilities:

decide when to call model
decide when to call tool
enforce policies
stop infinite loops
checkpoint state

Suggested modules:

Claw.Agent.Orchestrator
Claw.Agent.Planner
Claw.Agent.StepExecutor
Claw.Agent.Policy
D. Tools

Responsibilities:

register tool metadata
validate input
execute tool safely
stream tool outputs
audit results

Suggested modules:

Claw.Tools.Registry
Claw.Tools.Executor
Claw.Tools.Schema
Claw.Tools.Sandbox
E. Memory

Responsibilities:

short-term memory
long-term memory
semantic retrieval
summarization
fact extraction

Suggested modules:

Claw.Memory.Writer
Claw.Memory.Retriever
Claw.Memory.Summarizer
F. Channels

Responsibilities:

Slack/Telegram/Discord/web/email adapters
normalize incoming events
normalize outgoing response blocks

Suggested modules:

Claw.Channels.Slack
Claw.Channels.Telegram
Claw.Channels.Web
G. Jobs

Responsibilities:

cron tasks
reminders
follow-ups
polling workflows
retries

Suggested modules:

Claw.Jobs.\*
use Oban
H. Observability

Responsibilities:

traces
metrics
run logs
event timelines
replay

Suggested modules:

Claw.Telemetry
Claw.Tracing
Claw.Audit 6) Data architecture
Primary store

Use Postgres.

Store:

users
workspaces
sessions
messages
runs
tool invocations
job definitions
artifacts
memory records
embeddings metadata
permissions/audit logs
Hot caches

Use:

ETS for process-local or node-local fast access
Cachex or Nebulex if needed

Use ETS for:

tool registry cache
channel tokens
session routing map
model metadata cache
temporary run state
Semantic memory

Use pgvector first.

Reasons:

fewer systems
simpler deployment
enough for v1/v2
good fit for local-first install

Later, if needed:

Qdrant
Weaviate
Milvus
Blob/artifact storage

Use:

local disk for self-hosted local-first mode
S3-compatible store for team/cloud mode

Artifacts:

uploaded files
screenshots
audio
generated docs/images
tool outputs 7) Agent loop design

Do not let the model directly drive the system with unconstrained recursive execution.

Use an explicit loop.

Recommended loop
receive input
→ normalize event
→ load session context
→ retrieve relevant memory
→ build prompt context
→ ask planner/model for next action
→ validate action against policy
→ execute one step
→ record result
→ decide: continue / ask user / end / schedule background job
→ stream events to UI/channel
Execution principles
One-step-at-a-time

The model proposes the next action, not the entire uncontrolled chain.

Bounded loops

Cap:

max iterations
max tool calls
max token spend
max wall clock per run
Checkpoint everything

Every step writes:

model request metadata
tool request
tool response
state transition
final user-visible output

This makes replay and debugging far easier.

8. Tool system design

This is the heart of the platform.

OpenClaw’s appeal comes partly from broad tool/plugin use and skill-driven extensibility.

Tool contract

Every tool should expose:

@callback spec() :: %ToolSpec{
name: String.t(),
description: String.t(),
input_schema: map(),
output_schema: map(),
permissions: [atom()],
timeout_ms: pos_integer(),
idempotent: boolean()
}

@callback run(input :: map(), ctx :: map()) ::
{:ok, map()} | {:error, map()}
Tool categories
Pure tools

No side effects.
Examples:

calculator
parser
summarizer
extraction
file transform
Read tools

Can read external state.
Examples:

read calendar
search docs
fetch webpage
query DB
Write tools

Cause side effects.
Examples:

send email
create event
edit file
run shell command
Dangerous tools

Need explicit approval/sandboxing.
Examples:

shell execution
browser automation with clicks
OS-level control
secret access
Safety model

For each tool:

define permission class
define input schema
define output schema
define human approval policy
define timeout
define audit logging policy 9) Skills / plugin architecture

You probably want “skills” because OpenClaw users strongly associate it with reusable workflows, onboarding, and extensions.

My recommendation

Support two layers:

Layer 1 — Declarative skills

YAML/JSON/DB-defined

prompt additions
tool bundles
policy settings
triggers
workflow templates

Example:

name: calendar_assistant
tools:

- calendar.read
- calendar.create
  policies:
  require_confirmation_for: - calendar.create
  system_instructions: |
  You help manage calendars carefully.
  triggers:
- "schedule"
- "meeting"
  Layer 2 — Code plugins

Elixir behaviors for advanced integrations.

Example:

channel adapters
custom retrieval
enterprise SSO connectors
special tools

This gives you:

easy user-created skills
robust core code for serious extensions 10) Channel architecture

OpenClaw supports many channels, but you should not start there. Its public repo lists a very large multi-channel inbox footprint and routing model.

Start with 3 channels only
Phase 1
Web UI
CLI
Telegram or Slack

Why:

easiest to validate the loop
easiest to debug
covers interactive and real-world messaging
Unified channel event contract

Every adapter normalizes into:

%InboundEvent{
source: :web | :slack | :telegram | :cli,
channel_account_id: "...",
user_external_id: "...",
conversation_external_id: "...",
message_id: "...",
text: "...",
attachments: [...],
timestamp: ...
}

And outbound:

%OutboundEvent{
target: ...,
session_id: "...",
blocks: [...],
text: "...",
attachments: [...],
typing: boolean()
}

This abstraction prevents channel logic from leaking into session logic.

11. Memory design

Memory should be layered.

Layer A — Working memory

Inside the session process.

latest messages
plan state
tool outputs
unresolved tasks
Layer B — Episodic memory

Per run/session summaries.

“what happened”
decisions made
important artifacts
Layer C — Semantic memory

Embeddings + retrieval.

facts
preferences
docs
prior outcomes
Layer D — Structured memory

Explicit facts in tables.

user preferences
allowed tools
workspace entities
reminders
Write policy

Do not store everything.
Use extraction stages:

raw interaction
summarize
extract candidate facts
score usefulness
commit selected memory

This avoids memory bloat.

12. LLM abstraction

Do not couple the whole platform to a single model provider.

Broker contract
defmodule Claw.LLM.Provider do
@callback chat(map()) :: {:ok, map()} | {:error, term()}
@callback embeddings(map()) :: {:ok, map()} | {:error, term()}
@callback supports_tools?() :: boolean()
@callback supports_vision?() :: boolean()
@callback supports_json?() :: boolean()
end
Providers

Start with:

OpenAI
Anthropic
local vLLM / Ollama adapter
Why broker it
model failover
cost-aware routing
workspace-specific provider choice
easy evals 13) Security architecture

This matters a lot for agentic systems. Public guidance around OpenClaw emphasizes risks such as data exposure and malicious tool behavior, especially because agents may need broad access and external communication.

Security principles
Least privilege

Tools get only what they need.

Capability tokens

Instead of global access, hand tools scoped credentials:

read-only file token
specific Gmail action token
limited browser session token
Confirmation gates

Require approval for:

sending messages
creating/deleting files
shell execution
purchases
credential changes
Sandboxed execution

Never run arbitrary code in the main node.

Use:

ports
isolated OS processes
containerized workers for risky tools
Secrets separation

Keep secrets out of prompts whenever possible.

Audit everything

Store:

who invoked
why
what tool
input hash
output hash
approval status 14) Deep technical recommendation for Elixir implementation
Phoenix for the gateway

Use Phoenix for:

web UI backend
websocket streams
LiveView admin console if desired
webhook ingress
API
Oban for jobs

Use Oban for:

cron reminders
retries
polling external systems
delayed follow-ups
long-running workflows
Broadway only if event volume grows

If later you ingest lots of channel events or logs, add Broadway.

Finch/Req for outbound HTTP

Use these for provider/tool HTTP calls.

Ecto for state

Keep your persistent state model explicit and boring.

Telemetry + OpenTelemetry

Instrument:

model latency
tool latency
queue time
session duration
failure rates
token usage
retries
memory retrieval quality 15) Suggested internal package/module layout
lib/
claw/
application.ex
repo.ex

    gateway/
      dispatcher.ex
      event_bus.ex

    sessions/
      session_server.ex
      session_state.ex
      supervisor.ex
      registry.ex

    agent/
      orchestrator.ex
      planner.ex
      policy.ex
      step_executor.ex
      run_manager.ex

    llm/
      provider.ex
      broker.ex
      providers/
        openai.ex
        anthropic.ex
        ollama.ex

    tools/
      registry.ex
      executor.ex
      sandbox.ex
      schema.ex
      tools/
        calculator.ex
        browser_fetch.ex
        file_search.ex
        shell_command.ex

    memory/
      writer.ex
      retriever.ex
      summarizer.ex
      extractor.ex

    channels/
      adapter.ex
      slack.ex
      telegram.ex
      web.ex
      cli.ex

    jobs/
      reminder_worker.ex
      followup_worker.ex

    security/
      approvals.ex
      secrets.ex
      capabilities.ex
      audit.ex

    telemetry/
      metrics.ex
      tracing.ex

claw_web/
endpoint.ex
router.ex
controllers/
channels/
live/ 16) Recommended v1 scope

Do not try to reproduce:

full multi-channel surface
live canvas
mobile nodes
autonomous skill authoring
huge plugin marketplace

Even OpenClaw’s public surface in those areas is already extensive.

Best v1
Capabilities
local-first single-user install
Web UI
CLI
one messaging channel
one agent
session persistence
memory
5–8 safe tools
scheduler/reminders
approval workflow
telemetry dashboard
provider abstraction
Example v1 tools
web fetch
file read/write in workspace
shell command allowlist
calendar read/create
email draft/send
notes/memory search
reminder creation
internal workflow runner

That is enough to prove the platform.

17. v2 scope
    Add
    multi-agent routing
    team workspaces
    shared memory scopes
    richer skill system
    browser automation
    voice
    mobile companion
    artifact generation
    model routing policies
    policy packs for enterprise
18. Anti-patterns to avoid

1) Letting the model own the state machine

Bad idea. Keep the state machine in Elixir.

2. One giant conversation table

Separate:

sessions
runs
steps
tool calls
artifacts
summaries 3. Running dangerous tools inline

Use isolated workers.

4. Making everything autonomous by default

Start assistive, then selectively add autonomy.

5. Storing full history in every prompt

Use retrieval and summaries.

6. Plugin system before core runtime stability

Tools first, plugins second.

19. Suggested delivery roadmap
    Phase 0 — Discovery
    write product spec
    define user stories
    define safety boundaries
    define tool classes
    define session state machine
    Phase 1 — Skeleton
    Phoenix app
    Postgres schema
    session supervisor
    LLM broker
    simple web chat
    persistent messages/runs
    Phase 2 — Tool loop
    tool registry
    one-step orchestrator
    schema validation
    tool execution + audit
    streaming progress events
    Phase 3 — Memory
    run summaries
    semantic retrieval
    structured facts
    memory write filters
    Phase 4 — Jobs
    Oban workers
    reminders
    recurring workflows
    delayed follow-ups
    Phase 5 — Channels
    Telegram or Slack adapter
    unified event contract
    outbound formatting
    retry/idempotency
    Phase 6 — Safety + Ops
    approval UI
    tool permissions
    secrets manager integration
    telemetry dashboard
    traces + replay
    Phase 7 — Multi-agent
    workspace agents
    handoff protocol
    shared tool registry
    scoped memory
20. Concrete architecture decision record

If I were starting this today, I would choose:

Language/runtime: Elixir/OTP
Web/API: Phoenix
Realtime: Phoenix PubSub + Channels/LiveView
DB: Postgres + pgvector
Jobs: Oban
Cache: ETS
LLM providers: broker abstraction
Tool execution: OTP workers + isolated OS/container workers for dangerous tools
Observability: Telemetry + OpenTelemetry
Packaging: Docker + local-first single-node deployment
Initial UX: web app + CLI + one messaging adapter 21) My recommended architecture in one sentence

Build an OTP-supervised, local-first agent control plane in Phoenix, where each conversation is an isolated session process, tools run through a policy-checked execution layer, memory is layered across working/episodic/semantic stores, and channels are adapters on top of a unified event model.

22. What I would build first this week

Day 1–2:

session GenServer
broker for one LLM
chat UI
persisted messages

Day 3–4:

orchestrator loop
tool registry
2 safe tools
run logs

Day 5–6:

memory summary
semantic retrieval
approval flow

Day 7:

scheduler/reminders
telemetry dashboard
one channel adapter 23) Opinionated final recommendation

Do not build a feature-for-feature OpenClaw alternative first.

Build a smaller, more reliable Elixir-native agent runtime that is:

local-first
supervised
inspectable
replayable
policy-driven
easy to extend

That gives you a real wedge instead of a weaker clone.

If you want, I can turn this next into a full RFC-style technical design doc with:

database schema
OTP supervision tree
module skeletons
message/event contracts
and a phased implementation backlog.
Explain the core engine ... How to create and run agents. Teams mode like Claude etc

Here’s the core idea:

You are not really “running an agent.”
You are running a managed execution loop around an LLM, with:

state
tools
memory
permissions
scheduling
supervision
routing

That loop is the core engine.

If you want “teams mode like Claude,” then agents are just specialized runtimes with different instructions, tools, memory scopes, and handoff rules.

1. Mental model

Think of the system as 4 layers:

Layer 1 — Control plane

This is the system that knows:

what agents exist
which tools each agent can use
what memory they can access
who owns the task
which runs are active
what approvals are needed
which jobs are pending

This is your platform brain.

Layer 2 — Agent runtime

This is the execution engine for one agent run.

It does:

load context
retrieve memory
ask model for next step
validate step
execute tool or send message
checkpoint state
continue or stop

This is your worker brain.

Layer 3 — Tool/runtime layer

This is where actual work happens:

read files
write files
search web
run shell commands
call APIs
schedule jobs
query memory
hand off to another agent

This is your hands.

Layer 4 — UI / channels

This is how the user interacts:

web app
CLI
Slack
Telegram
email
API

This is your face.

2. What the core engine actually is

The core engine is a state machine plus step executor.

Not a single prompt.

Not “just call the model.”

A proper engine tracks:

current task
agent identity
run status
allowed tools
budget
approvals
scratchpad / working memory
outputs
child runs
retries
final result
Minimal run lifecycle
NEW
→ PREPARE_CONTEXT
→ PLAN_NEXT_STEP
→ VALIDATE_STEP
→ EXECUTE_STEP
→ RECORD_RESULT
→ DECIDE_NEXT
→ COMPLETE / WAITING / FAILED / HANDOFF

In Elixir, this maps very naturally to:

a GenServer or managed process per run/session
a supervisor over all runs
persistent checkpointing in Postgres
async tool work via Task, Oban, or worker processes 3) Core engine loop

This is the real heart.

Pseudocode
receive task
load agent definition
load session/run state
retrieve relevant memory
build model input
ask model: "what is the next best step?"
parse structured response
validate against policy
if response is tool call:
execute tool
save result
continue loop
if response is handoff:
create child agent run
wait or continue based on mode
if response is ask_user:
emit question
pause run
if response is final:
save final output
mark complete
Important principle

The model should not control the whole system.

The model proposes actions.
Your Elixir runtime decides whether they are allowed, how they run, and what happens next.

That is the difference between:

toy agents
production agents 4) The objects you need

You should define a few core entities early.

Agent

An agent is a reusable configuration.

Example:

%Agent{
id: "researcher",
name: "Research Agent",
system_prompt: "...",
model: "gpt-5",
tools: [:web_search, :read_file, :write_notes],
memory_scope: :workspace,
max_steps: 20,
handoff_targets: ["coder", "reviewer"],
approval_policy: %{
require_approval_for: [:send_email, :delete_file]
}
}

An agent is not a process by itself.
It is a definition/template.

Run

A run is one execution instance of an agent.

%Run{
id: "run_123",
agent_id: "researcher",
task: "Analyze repo and propose refactor",
status: :running,
step_count: 4,
parent_run_id: nil,
session_id: "sess_1"
}
Session

A session is the broader conversation/work context.

It may contain:

user messages
files
memory references
active runs
UI state
Step

A step is one action taken by the runtime.

Examples:

model reasoning step
tool call
handoff
final response
user question
Tool

A tool is a validated executable capability.

Team

A team is a set of agent definitions plus coordination rules.

5. How to create and run agents

There are 3 levels of sophistication.

Level 1 — Static agents

You define agents in code or config.

Example:

Researcher
Coder
Reviewer
PM
File organizer

This is the best starting point.

How it works
register agents in a registry
each agent has prompt + tools + policy
user chooses agent or default router chooses one
system creates a run for that agent
engine executes until done
Good for
reliability
debugging
v1 systems
Level 2 — Dynamic task-specific agents

The system can create temporary agents at runtime.

Example:

“Create a Python migration specialist”
“Spawn a docs summarizer”
“Create a test-writer agent with repo-only access”

These are still just structured definitions, but generated on demand.

How it works

A parent agent or orchestrator creates:

{
"name": "migration_specialist",
"role": "Convert legacy Java utility layer to Elixir service wrappers",
"tools": ["read_file", "write_file", "search_code"],
"constraints": ["Only touch /lib/migration", "No deletes"],
"memory_scope": "task_local"
}

The control plane validates it, then registers it as an ephemeral agent, then creates a run.

Good for
flexible teams
large workflows
specialized subtasks
Level 3 — Agent factories

You let agents create other agents recursively under policy.

This is powerful but dangerous.

You need:

depth limits
max child count
budget limits
strict tool inheritance
audit logs
cancellation propagation

For v1, do not start here.

6. How agents should be defined

Use a clean schema.

Agent definition schema
defmodule MyApp.AgentDefinition do
defstruct [
:id,
:name,
:description,
:system_prompt,
:model,
:temperature,
:max_steps,
:tool_names,
:memory_scope,
:visibility,
:handoff_targets,
:approval_policy,
:metadata
]
end
Recommended fields
Identity
id
name
description
Behavior
system prompt
model
output style
planning mode
Capabilities
tool list
allowed channels
file scopes
memory scopes
Coordination
can delegate?
can receive handoffs?
can spawn children?
wait-for-child or parallel?
Safety
step limit
token budget
forbidden tools
confirmation requirements 7) The engine internals

Break the runtime into components.

A. Run Manager

Responsible for:

create run
update status
checkpoint progress
cancel run
resume run
B. Context Builder

Responsible for:

loading recent messages
loading memory
loading files/artifacts
building prompt/tool context
C. Planner

Calls the model to decide the next step.

Important: planner output should be structured JSON, not free text.

Example output:

{
"action": "tool_call",
"tool": "read_file",
"input": { "path": "lib/core.ex" },
"reason": "Need to inspect core logic before proposing changes"
}
D. Policy Engine

Checks:

is this tool allowed?
does it need approval?
is budget exceeded?
is path within allowed scope?
is handoff target allowed?
E. Step Executor

Actually runs:

tool calls
child agents
pauses
final responses
F. Event Stream

Sends updates to UI:

“planning”
“reading files”
“delegating to reviewer”
“waiting for approval”
“done”
G. Memory Writer

After the run, writes:

summary
facts
artifacts
learned preferences if appropriate 8) Teams mode like Claude

“Teams mode” usually means one of two things:

Meaning A — Multiple reusable specialist agents

Example:

Research
Code
Review
Docs
QA

The user can select them, or the system can route work among them.

Meaning B — Coordinated multi-agent execution

A lead agent decomposes a task and hands subtasks to specialists.

This is the closer analogue to “Claude-like team workflows.”

9. Recommended team architecture

Use a Lead + Specialists model.

Structure
User
↓
Coordinator Agent
├─ Research Agent
├─ Coding Agent
├─ Review Agent
└─ Docs Agent

The coordinator:

receives the task
breaks it into subtasks
assigns subtasks
collects results
synthesizes final answer

This is much safer than free-for-all peer-to-peer delegation.

10. Team execution modes
    Mode 1 — Sequential delegation

Coordinator calls one specialist at a time.

Example:

Research agent analyzes
Coder agent implements
Reviewer agent checks
Coordinator returns answer

Best for v1.

Mode 2 — Parallel delegation

Coordinator spawns multiple child runs concurrently.

Example:

Research repo structure
Research dependencies
Draft architecture options

Then merges results.

Elixir is very strong here because concurrent child runs map well to OTP processes.

Mode 3 — Persistent team room

A long-lived team shares:

workspace memory
files
artifacts
task board

This is more advanced and should come later.

11. How handoffs should work

Handoffs should be first-class actions in the engine.

Not “just mention another agent in the prompt.”

Handoff object
%Handoff{
from_run_id: "run_1",
to_agent_id: "reviewer",
task: "Review the proposed architecture for concurrency issues",
input_artifacts: ["artifact_1"],
memory_scope: :task_shared,
return_mode: :wait
}
Handoff flow
parent run decides to delegate
policy engine checks whether allowed
create child run
pass scoped context
child executes
child produces structured result
parent resumes with child output 12) Shared memory in teams mode

You need memory scopes.

Recommended scopes

1. Run-local

Visible only inside one run.

Use for:

scratchpad
temporary reasoning
intermediate notes 2. Task-shared

Visible to parent and child runs of the same task.

Use for:

subtasks
partial results
shared artifacts 3. Session-shared

Visible to all agents in a conversation/session.

Use for:

conversation context
user instructions
session files 4. Workspace/global

Visible to all agents in a workspace.

Use for:

stable project knowledge
policies
repositories
docs
preferences

Without scopes, teams become messy very fast.

13. Team coordination patterns

Here are the best patterns.

Pattern 1 — Coordinator / worker

Best default.

one coordinator
many specialists
coordinator owns final answer
Pattern 2 — Planner / executor / critic

Very useful for code and research.

Planner creates plan
Executor does work
Critic reviews
Coordinator synthesizes
Pattern 3 — Map / reduce agents

Good for large document or repo analysis.

split repo/doc into chunks
spawn analyzers
aggregate findings
Pattern 4 — Pipeline agents

Good for transformation workflows.

ingest
parse
normalize
validate
publish

For your Elixir agent platform, start with:
Coordinator / worker and Planner / executor / critic.

14. How to implement this in Elixir
    Core OTP mapping
    One run = one process

Each active run gets a process:

GenServer for orchestration state
maybe Tasks for short-lived substeps
Oban for resumable background jobs
One session = optional process

If you want live interactive sessions, maintain a session process too.

DynamicSupervisor

Use it to start/stop runs dynamically.

Registry

Map:

run_id → pid
session_id → pid
agent name → definition
Suggested runtime modules
MyApp.Agents.Registry
MyApp.Agents.Definition
MyApp.Runs.RunSupervisor
MyApp.Runs.RunServer
MyApp.Runs.RunManager
MyApp.Engine.ContextBuilder
MyApp.Engine.Planner
MyApp.Engine.Policy
MyApp.Engine.StepExecutor
MyApp.Engine.HandoffManager
MyApp.Engine.ResultAggregator
MyApp.Tools.Registry
MyApp.Memory.Store 15) Example run server flow

A RunServer might hold:

%State{
run_id: "run_123",
agent: %AgentDefinition{},
session_id: "sess_1",
task: "Analyze architecture",
status: :planning,
step_count: 0,
max_steps: 20,
scratchpad: %{},
child_runs: [],
pending_approval: nil,
results: []
}
Main cycle
handle_continue(:start, state)
build initial context
call planner
planner returns action
tool call
final response
ask user
handoff
wait
execute action
update DB
emit event
continue next step 16) Creating agents

There are several practical ways.

Option 1 — Hardcoded modules

Each agent is an Elixir module.

Example:

defmodule MyApp.Agents.Researcher do
def definition do
%AgentDefinition{
id: "researcher",
name: "Researcher",
system_prompt: "You investigate and summarize carefully.",
tool_names: [:web_search, :read_file, :write_note],
handoff_targets: ["reviewer"],
max_steps: 15
}
end
end

Good for early development.

Option 2 — DB-backed definitions

Store agent definitions in Postgres.

Good for:

admin UI
editing without deploy
per-workspace agents
Option 3 — YAML files

Good compromise for developer-friendly teams.

Example:

id: reviewer
name: Reviewer
model: gpt-5
tools:

- read_file
- diff_files
- comment
  max_steps: 10
  handoff_targets:
- coordinator

Recommended:

start with code
move to DB/YAML later 17) Running an agent
Simple flow
MyApp.Runs.create_run(%{
agent_id: "researcher",
session_id: "sess_1",
task: "Read the repo and propose architecture"
})

That function should:

fetch agent definition
persist run record
start RunServer under DynamicSupervisor
return run id
Under the hood
create_run
→ load agent
→ validate tool permissions
→ insert run row
→ start child process
→ emit run_started event
→ process loop begins 18) How child agents should return results

Do not return giant raw chat logs.
Return structured outputs.

Example child result:

{
"summary": "The codebase mixes transport and domain logic.",
"findings": [
"No clear boundary between orchestration and adapters",
"Shared mutable file-write behavior in multiple modules"
],
"recommendations": [
"Introduce Engine context",
"Separate tool runtime from API layer"
],
"artifacts": ["artifact_22"]
}

This makes aggregation much cleaner.

19. Approval model

Teams mode becomes dangerous unless approvals are built in.

Require approval for
external send actions
deleting files
shell execution
credential access
purchases
irreversible actions
In the engine

The planner may request a tool call, but the policy engine can respond:

{:needs_approval, approval_request}

Then the run pauses.

This is critical.

20. Failure handling

Teams mode needs strong failure semantics.

Child run failure cases
tool timeout
budget exceeded
invalid output
forbidden action
model error
Parent behavior options
retry child
route to fallback agent
continue without child
stop and ask user

Make this explicit in policy.

21. Team mode design I recommend for you

If you want a Claude-style team experience, build this in stages:

Stage 1 — Specialist agents

Create 4 static agents:

coordinator
researcher
coder
reviewer
Stage 2 — Handoff support

Let coordinator delegate to one specialist.

Stage 3 — Parallel subtasks

Let coordinator spawn 2–3 child runs.

Stage 4 — Shared task workspace

Artifacts + notes + results visible across child runs.

Stage 5 — Persistent teams

Named team presets:

“Code Team”
“Research Team”
“Docs Team”
“Ops Team” 22) Best first team preset
Code Team

This is the most useful starting point.

Coordinator

Breaks task down and merges outputs.

Researcher

Reads repo, docs, dependencies, architecture.

Coder

Proposes or writes changes.

Reviewer

Checks correctness, risk, edge cases.

Docs

Writes explanation/changelog/migration notes.

This maps very well to real tasks.

23. A clean architecture for team mode
    User Task
    ↓
    Team Coordinator Run
    ↓
    Task Planner
    ├── Child Run: Researcher
    ├── Child Run: Coder
    └── Child Run: Reviewer
    ↓
    Result Aggregator
    ↓
    Final Response
    Required engine components
    HandoffManager
    ChildRunSupervisor
    ResultAggregator
    SharedTaskContext
    PolicyEngine
24. What not to do

Do not do these early:

1. Free-form agent chats

Do not let agents endlessly talk to each other.

Bad:

noisy
expensive
hard to debug
easy to loop forever 2. Shared giant prompt

Do not cram all agent instructions into one giant context blob.

3. Unbounded delegation

Always cap:

depth
number of children
total steps
total budget 4. Tool access inheritance without checks

A child should not automatically inherit every dangerous tool.

25. Minimal v1 engine design

If you want the smallest solid version:

Core
agent registry
run manager
run process
planner
tool executor
policy engine
event log
Team support
coordinator agent
handoff action
child run creation
result aggregation
Safety
max 10–20 steps
max 2 levels of delegation
approval gates
audit logs

That is enough to feel powerful.

26. Practical example

User asks:

Analyze this repo and propose a scalable Elixir architecture.

Flow
system creates coordinator run
coordinator decides:
research repo structure
analyze concurrency model
propose module boundaries
spawns:
researcher child
reviewer child
child outputs return
coordinator synthesizes
final answer shown to user

If user says:

Now implement the basic supervision tree

then:

coordinator spawns coder
coder reads files and drafts changes
reviewer checks
approval requested before write
changes applied if approved

That is a proper teams workflow.

27. My recommendation for your Elixir implementation

Build the engine around these ideas:

Core engine
one run = one supervised process
explicit state machine
structured planner outputs
strict policy validation
step-by-step execution
Agents
agent = definition, not process
run = live execution
child runs for delegation
Teams mode
coordinator-led
structured handoffs
scoped memory/artifacts
bounded delegation
result aggregation 28) The simplest one-sentence definition

The core engine is an OTP-supervised run state machine that turns agent definitions into controlled, stepwise executions with tools, memory, policies, and optional delegation to specialist child agents.

If you want, next I can turn this into:

an Elixir module/file structure, or
a step-by-step implementation plan for v1 core engine + teams mode.
General scaffolding and pseudo code for the main engine , agents running and orchestration

Below is a general scaffolding for an Elixir-based agent platform with:

main engine
agent definitions
run lifecycle
orchestration
child-agent delegation
tool execution
event streaming
memory hooks
team mode

I’ll keep it architectural + pseudo-code, not over-focus on exact syntax.

1. High-level structure

A clean starting structure:

lib/
claw/
application.ex

    agents/
      agent_definition.ex
      registry.ex
      presets/
        coordinator.ex
        researcher.ex
        coder.ex
        reviewer.ex

    runs/
      run_manager.ex
      run_supervisor.ex
      run_server.ex
      run_state.ex
      handoff_manager.ex
      result_aggregator.ex

    engine/
      context_builder.ex
      planner.ex
      policy.ex
      step_executor.ex
      loop.ex
      action_parser.ex

    tools/
      tool_definition.ex
      registry.ex
      executor.ex
      sandbox.ex
      builtins/
        read_file.ex
        write_file.ex
        web_search.ex
        shell_command.ex

    memory/
      retriever.ex
      writer.ex
      summarizer.ex

    events/
      bus.ex
      publisher.ex

    persistence/
      repo.ex
      schemas/
        run.ex
        step.ex
        agent.ex
        artifact.ex
        approval.ex

    approvals/
      manager.ex

claw_web/
endpoint.ex
router.ex
channels/
controllers/ 2) Core concepts
Agent definition

An agent is a template, not a live process.

defmodule Claw.Agents.AgentDefinition do
defstruct [
:id,
:name,
:description,
:system_prompt,
:model,
:temperature,
:max_steps,
:tool_names,
:memory_scope,
:handoff_targets,
:approval_policy,
:visibility,
:metadata
]
end

Example:

%AgentDefinition{
id: "researcher",
name: "Researcher",
description: "Reads sources and summarizes findings",
system_prompt: "You are a precise research assistant.",
model: "gpt-5",
temperature: 0.2,
max_steps: 12,
tool_names: [:read_file, :web_search, :search_memory],
memory_scope: :workspace,
handoff_targets: ["coordinator", "reviewer"],
approval_policy: %{require_approval_for: [:write_file, :send_email]},
visibility: :team
}
Run

A run is one live execution of an agent.

defmodule Claw.Runs.RunState do
defstruct [
:run_id,
:session_id,
:parent_run_id,
:agent,
:task,
:status,
:step_count,
:max_steps,
:budget,
:messages,
:scratchpad,
:memory_refs,
:artifacts,
:child_runs,
:pending_approval,
:results,
:last_error,
:inserted_at,
:updated_at
]
end 3) OTP supervision scaffolding
Application supervisor
defmodule Claw.Application do
use Application

def start(\_type, \_args) do
children = [
Claw.Persistence.Repo,
{Registry, keys: :unique, name: Claw.RunRegistry},
{DynamicSupervisor, strategy: :one_for_one, name: Claw.RunSupervisor},
Claw.Events.Bus,
Claw.Tools.Registry,
Claw.Agents.Registry
]

    Supervisor.start_link(children, strategy: :one_for_one, name: Claw.Supervisor)

end
end 4) Agent registry

This loads built-in agents first. Later it can pull from DB/YAML.

defmodule Claw.Agents.Registry do
use GenServer

alias Claw.Agents.AgentDefinition

def start_link(\_opts) do
GenServer.start_link(**MODULE**, %{}, name: **MODULE**)
end

def init(\_) do
agents =
[
Claw.Agents.Presets.Coordinator.definition(),
Claw.Agents.Presets.Researcher.definition(),
Claw.Agents.Presets.Coder.definition(),
Claw.Agents.Presets.Reviewer.definition()
]
|> Map.new(fn %AgentDefinition{id: id} = a -> {id, a} end)

    {:ok, agents}

end

def fetch(agent_id), do: GenServer.call(**MODULE**, {:fetch, agent_id})

def handle_call({:fetch, agent_id}, \_from, state) do
{:reply, Map.fetch(state, agent_id), state}
end
end 5) Run manager

This is the entry point for creating and controlling runs.

defmodule Claw.Runs.RunManager do
alias Claw.Agents.Registry, as: AgentRegistry
alias Claw.Runs.RunState

def create_run(attrs) do
with {:ok, agent} <- AgentRegistry.fetch(attrs.agent_id),
{:ok, run_state} <- build_initial_state(agent, attrs),
{:ok, \_db_record} <- persist_run(run_state),
{:ok, pid} <- start_run_process(run_state) do
{:ok, %{run_id: run_state.run_id, pid: pid}}
end
end

def cancel*run(run_id) do
case Registry.lookup(Claw.RunRegistry, run_id) do
[{pid, *}] -> GenServer.call(pid, :cancel)
[] -> {:error, :run_not_found}
end
end

defp build_initial_state(agent, attrs) do
{:ok,
%RunState{
run_id: generate_id(),
session_id: attrs.session_id,
parent_run_id: Map.get(attrs, :parent_run_id),
agent: agent,
task: attrs.task,
status: :new,
step_count: 0,
max_steps: agent.max_steps || 12,
budget: %{tokens: 100_000, tool_calls: 20},
messages: [],
scratchpad: %{},
memory_refs: [],
artifacts: [],
child_runs: [],
pending_approval: nil,
results: [],
inserted_at: DateTime.utc_now(),
updated_at: DateTime.utc_now()
}}
end

defp persist_run(run_state) do # write DB row
{:ok, :persisted}
end

defp start_run_process(run_state) do
spec = {Claw.Runs.RunServer, run_state}
DynamicSupervisor.start_child(Claw.RunSupervisor, spec)
end

defp generate*id, do: "run*" <> Base.encode16(:crypto.strong_rand_bytes(8), case: :lower)
end 6) Run server

This is the main live runtime per agent run.

defmodule Claw.Runs.RunServer do
use GenServer

alias Claw.Engine.Loop
alias Claw.Events.Publisher

def start_link(run_state) do
GenServer.start_link(**MODULE**, run_state, name: via(run_state.run_id))
end

defp via(run_id), do: {:via, Registry, {Claw.RunRegistry, run_id}}

def init(run_state) do
Publisher.run_started(run_state)
{:ok, %{run_state | status: :starting}, {:continue, :boot}}
end

def handle_continue(:boot, state) do
case Loop.tick(state) do
{:continue, new_state} ->
{:noreply, new_state, {:continue, :boot}}

      {:wait, new_state} ->
        {:noreply, new_state}

      {:done, new_state} ->
        Publisher.run_completed(new_state)
        {:stop, :normal, new_state}

      {:failed, new_state} ->
        Publisher.run_failed(new_state)
        {:stop, :normal, new_state}
    end

end

def handle_call(:cancel, \_from, state) do
new_state = %{state | status: :cancelled}
{:reply, :ok, new_state, {:stop, :normal, new_state}}
end

def handle_info({:child_result, child_run_id, result}, state) do
new_state = Claw.Runs.ResultAggregator.merge_child_result(state, child_run_id, result)

    case Loop.tick(new_state) do
      {:continue, next_state} -> {:noreply, next_state, {:continue, :boot}}
      {:wait, next_state} -> {:noreply, next_state}
      {:done, next_state} -> {:stop, :normal, next_state}
      {:failed, next_state} -> {:stop, :normal, next_state}
    end

end

def handle_info({:approval_decision, decision}, state) do
resumed = %{state | pending_approval: nil, scratchpad: Map.put(state.scratchpad, :approval_decision, decision)}
{:noreply, resumed, {:continue, :boot}}
end
end 7) Main engine loop

This is the heart.

defmodule Claw.Engine.Loop do
alias Claw.Engine.{ContextBuilder, Planner, Policy, StepExecutor}
alias Claw.Events.Publisher

def tick(state) do
cond do
state.status in [:cancelled, :completed, :failed] ->
{:done, state}

      state.step_count >= state.max_steps ->
        {:failed, %{state | status: :failed, last_error: :max_steps_exceeded}}

      true ->
        do_tick(state)
    end

end

defp do_tick(state) do
Publisher.status(state, :building_context)

    with {:ok, context} <- ContextBuilder.build(state),
         {:ok, planned_action} <- Planner.plan_next_step(state, context),
         {:ok, validated_action} <- Policy.validate(state, planned_action),
         {:ok, outcome} <- StepExecutor.execute(state, validated_action) do
      handle_outcome(state, outcome)
    else
      {:wait, new_state} ->
        {:wait, new_state}

      {:error, reason} ->
        {:failed, %{state | status: :failed, last_error: reason}}
    end

end

defp handle_outcome(state, outcome) do
case outcome do
{:continue, new_state} ->
{:continue, increment_step(new_state)}

      {:wait, new_state} ->
        {:wait, increment_step(new_state)}

      {:done, new_state} ->
        {:done, %{increment_step(new_state) | status: :completed}}

      {:failed, new_state} ->
        {:failed, %{increment_step(new_state) | status: :failed}}
    end

end

defp increment_step(state) do
%{state | step_count: state.step_count + 1, updated_at: DateTime.utc_now()}
end
end 8) Context builder

This gathers the information for the planner.

defmodule Claw.Engine.ContextBuilder do
alias Claw.Memory.Retriever

def build(state) do
relevant_memory = Retriever.fetch(state)

    context = %{
      agent: %{
        id: state.agent.id,
        name: state.agent.name,
        system_prompt: state.agent.system_prompt
      },
      task: state.task,
      recent_messages: Enum.take(state.messages, -20),
      scratchpad: state.scratchpad,
      results_so_far: state.results,
      artifacts: state.artifacts,
      memory: relevant_memory,
      child_runs: state.child_runs
    }

    {:ok, context}

end
end 9) Planner

The planner asks the LLM for the next step.
Important: make it return structured actions.

Expected action types
:tool_call
:handoff
:ask_user
:final_response
:wait
:noop
defmodule Claw.Engine.Planner do
alias Claw.Engine.ActionParser

def plan_next_step(state, context) do
prompt = build_prompt(state, context)

    # pseudo provider call
    llm_response =
      %{
        "action" => "tool_call",
        "tool" => "read_file",
        "input" => %{"path" => "lib/core.ex"},
        "reason" => "Need to inspect the core engine implementation"
      }

    ActionParser.parse(llm_response)

end

defp build_prompt(state, context) do
%{
system: state.agent.system_prompt,
developer: """
Return a single next action in strict JSON.
Allowed actions: tool_call, handoff, ask_user, final_response, wait, noop.
Never return more than one action.
""",
user: state.task,
context: context
}
end
end 10) Action parser
defmodule Claw.Engine.ActionParser do
def parse(%{"action" => "tool_call", "tool" => tool, "input" => input} = raw) do
{:ok, %{type: :tool_call, tool: String.to_atom(tool), input: input, raw: raw}}
end

def parse(%{"action" => "handoff", "agent_id" => agent_id, "task" => task} = raw) do
{:ok, %{type: :handoff, agent_id: agent_id, task: task, raw: raw}}
end

def parse(%{"action" => "ask_user", "question" => question} = raw) do
{:ok, %{type: :ask_user, question: question, raw: raw}}
end

def parse(%{"action" => "final_response", "message" => message} = raw) do
{:ok, %{type: :final_response, message: message, raw: raw}}
end

def parse(%{"action" => "wait"} = raw) do
{:ok, %{type: :wait, raw: raw}}
end

def parse(raw), do: {:error, {:invalid_action, raw}}
end 11) Policy engine

The policy engine decides what is allowed.

defmodule Claw.Engine.Policy do
def validate(state, action) do
case action.type do
:tool*call -> validate_tool_call(state, action)
:handoff -> validate_handoff(state, action)
:ask_user -> {:ok, action}
:final_response -> {:ok, action}
:wait -> {:ok, action}
* -> {:error, :unknown_action_type}
end
end

defp validate_tool_call(state, action) do
cond do
action.tool not in state.agent.tool_names ->
{:error, {:tool_not_allowed, action.tool}}

      requires_approval?(state, action.tool) ->
        {:ok, Map.put(action, :approval_required, true)}

      true ->
        {:ok, Map.put(action, :approval_required, false)}
    end

end

defp validate_handoff(state, action) do
if action.agent_id in state.agent.handoff_targets do
{:ok, action}
else
{:error, {:handoff_not_allowed, action.agent_id}}
end
end

defp requires_approval?(state, tool_name) do
required = get_in(state.agent.approval_policy, [:require_approval_for]) || []
tool_name in required
end
end 12) Step executor

This executes one validated action.

defmodule Claw.Engine.StepExecutor do
alias Claw.Tools.Executor, as: ToolExecutor
alias Claw.Runs.HandoffManager
alias Claw.Events.Publisher

def execute(state, %{type: :tool_call, approval_required: true} = action) do
Publisher.approval_requested(state, action)
new_state = %{state | status: :waiting_approval, pending_approval: action}
{:ok, {:wait, new_state}}
end

def execute(state, %{type: :tool_call} = action) do
Publisher.status(state, {:executing_tool, action.tool})

    case ToolExecutor.execute(action.tool, action.input, build_tool_ctx(state)) do
      {:ok, result} ->
        new_state =
          state
          |> append_result(%{tool: action.tool, result: result})
          |> append_message(%{role: :tool, content: result})

        {:ok, {:continue, %{new_state | status: :running}}}

      {:error, reason} ->
        {:ok, {:failed, %{state | last_error: reason}}}
    end

end

def execute(state, %{type: :handoff} = action) do
Publisher.status(state, {:delegating, action.agent_id})

    case HandoffManager.spawn_child_run(state, action) do
      {:ok, child_run_id, new_state} ->
        {:ok, {:wait, %{new_state | status: :waiting_child, child_runs: [child_run_id | state.child_runs]}}}

      {:error, reason} ->
        {:ok, {:failed, %{state | last_error: reason}}}
    end

end

def execute(state, %{type: :ask_user, question: question}) do
Publisher.ask_user(state, question)
{:ok, {:wait, %{state | status: :waiting_user}}}
end

def execute(state, %{type: :final_response, message: message}) do
Publisher.final_response(state, message)
new_state = append_message(state, %{role: :assistant, content: message})
{:ok, {:done, new_state}}
end

def execute(state, %{type: :wait}) do
{:ok, {:wait, %{state | status: :waiting}}}
end

defp build_tool_ctx(state) do
%{
run_id: state.run_id,
session_id: state.session_id,
agent_id: state.agent.id,
memory_scope: state.agent.memory_scope
}
end

defp append_result(state, result), do: %{state | results: [result | state.results]}
defp append_message(state, msg), do: %{state | messages: state.messages ++ [msg]}
end 13) Tool system scaffolding
Tool definition behavior
defmodule Claw.Tools.ToolDefinition do
@callback spec() :: map()
@callback run(map(), map()) :: {:ok, any()} | {:error, any()}
end
Registry
defmodule Claw.Tools.Registry do
use GenServer

def start_link(\_opts), do: GenServer.start_link(**MODULE**, %{}, name: **MODULE**)

def init(\_) do
tools = %{
read_file: Claw.Tools.Builtins.ReadFile,
write_file: Claw.Tools.Builtins.WriteFile,
web_search: Claw.Tools.Builtins.WebSearch,
shell_command: Claw.Tools.Builtins.ShellCommand
}

    {:ok, tools}

end

def fetch(tool_name), do: GenServer.call(**MODULE**, {:fetch, tool_name})

def handle_call({:fetch, tool_name}, \_from, state) do
{:reply, Map.fetch(state, tool_name), state}
end
end
Executor
defmodule Claw.Tools.Executor do
alias Claw.Tools.Registry

def execute(tool_name, input, ctx) do
with {:ok, mod} <- Registry.fetch(tool_name) do
mod.run(input, ctx)
end
end
end
Example tool
defmodule Claw.Tools.Builtins.ReadFile do
@behaviour Claw.Tools.ToolDefinition

def spec do
%{
name: :read_file,
description: "Read a text file from allowed workspace path",
input_schema: %{path: :string}
}
end

def run(%{"path" => path}, \_ctx) do
case File.read(path) do
{:ok, content} -> {:ok, %{path: path, content: content}}
{:error, reason} -> {:error, reason}
end
end
end 14) Handoff manager

This is the key part for team orchestration.

defmodule Claw.Runs.HandoffManager do
alias Claw.Runs.RunManager

def spawn_child_run(parent_state, action) do
attrs = %{
agent_id: action.agent_id,
session_id: parent_state.session_id,
parent_run_id: parent_state.run_id,
task: action.task
}

    case RunManager.create_run(attrs) do
      {:ok, %{run_id: child_run_id}} ->
        new_state =
          put_in(parent_state.scratchpad[:waiting_on_child], %{
            child_run_id: child_run_id,
            delegated_task: action.task
          })

        {:ok, child_run_id, new_state}

      {:error, reason} ->
        {:error, reason}
    end

end
end 15) Returning child results to parent

You need an explicit path for that.

Simplest model:

child run stores its result in DB
child completion hook notifies parent pid
parent receives {:child_result, child_run_id, result}

Pseudo completion hook:

defmodule Claw.Runs.ChildCompletionHook do
def notify*parent_if_needed(state) do
if state.parent_run_id do
parent_pid =
case Registry.lookup(Claw.RunRegistry, state.parent_run_id) do
[{pid, *}] -> pid
[] -> nil
end

      if parent_pid do
        send(parent_pid, {:child_result, state.run_id, extract_result(state)})
      end
    end

end

defp extract_result(state) do
%{
run_id: state.run_id,
final_messages: state.messages,
results: state.results,
summary: summarize(state)
}
end

defp summarize(state) do
"Child run completed with #{length(state.results)} results"
end
end 16) Result aggregator
defmodule Claw.Runs.ResultAggregator do
def merge_child_result(state, child_run_id, result) do
state
|> put_in([Access.key(:scratchpad), :last_child_result], %{child_run_id: child_run_id, result: result})
|> Map.update!(:results, fn existing ->
[%{child_run: child_run_id, result: result} | existing]
end)
|> Map.put(:status, :running)
end
end 17) Memory scaffolding

Keep it simple early.

Retriever
defmodule Claw.Memory.Retriever do
def fetch(state) do # later: # - semantic search # - session history lookup # - workspace facts
[
%{type: :session_summary, text: "User is building an Elixir agent platform."}
]
end
end
Writer
defmodule Claw.Memory.Writer do
def maybe_persist_run_summary(state) do
summary = %{
run_id: state.run_id,
task: state.task,
outcome: state.status,
important_results: Enum.take(state.results, 5)
}

    {:ok, summary}

end
end 18) Event publishing scaffolding

Your UI and logs need structured events.

defmodule Claw.Events.Publisher do
def run_started(state), do: publish({:run_started, state.run_id, state.agent.id})
def run_completed(state), do: publish({:run_completed, state.run_id})
def run_failed(state), do: publish({:run_failed, state.run_id, state.last_error})
def status(state, status), do: publish({:run_status, state.run_id, status})
def approval_requested(state, action), do: publish({:approval_requested, state.run_id, action})
def ask_user(state, question), do: publish({:ask_user, state.run_id, question})
def final_response(state, message), do: publish({:final_response, state.run_id, message})

defp publish(event) do
Phoenix.PubSub.broadcast(Claw.PubSub, "runs", event)
end
end 19) Coordinator agent pattern

For teams mode, your coordinator agent should be the only one allowed to delegate broadly.

Coordinator example
defmodule Claw.Agents.Presets.Coordinator do
alias Claw.Agents.AgentDefinition

def definition do
%AgentDefinition{
id: "coordinator",
name: "Coordinator",
description: "Breaks tasks down and delegates to specialists",
system_prompt: """
You are a coordinator.
You do not do deep implementation yourself unless trivial.
You delegate specialized work to appropriate agents.
You synthesize the final answer.
""",
model: "gpt-5",
temperature: 0.2,
max_steps: 20,
tool_names: [:search_memory],
memory_scope: :workspace,
handoff_targets: ["researcher", "coder", "reviewer"],
approval_policy: %{require_approval_for: []},
visibility: :team
}
end
end 20) Example orchestration flow

User task:

Analyze the repo and propose the engine architecture.

Coordinator loop might produce:
Step 1
{
"action": "handoff",
"agent_id": "researcher",
"task": "Inspect the repository structure and summarize the existing runtime architecture."
}
Step 2 after child returns
{
"action": "handoff",
"agent_id": "reviewer",
"task": "Review the research findings and identify architectural risks or missing boundaries."
}
Step 3 after both return
{
"action": "final_response",
"message": "Here is the synthesized architecture proposal..."
}

That is much better than having all agents free-chat with each other.

21. Minimal planner contract for production sanity

Your planner should always output one of these forms:

Tool call
{
"action": "tool_call",
"tool": "read_file",
"input": {"path": "lib/engine/loop.ex"},
"reason": "Need source inspection"
}
Handoff
{
"action": "handoff",
"agent_id": "reviewer",
"task": "Review the proposed module boundaries",
"reason": "Specialist review required"
}
Ask user
{
"action": "ask_user",
"question": "Which repository path should I prioritize?"
}
Final response
{
"action": "final_response",
"message": "Done. Here is the proposed architecture..."
}

Keep this strict. It prevents chaos.

22. Suggested state machine

A good starting state machine for each run:

:new
→ :starting
→ :running
→ :waiting_approval
→ :waiting_child
→ :waiting_user
→ :waiting
→ :completed
→ :failed
→ :cancelled

Transitions:

:starting -> :running
:running -> :waiting_approval
:running -> :waiting_child
:running -> :waiting_user
:running -> :completed
:running -> :failed 23) Pseudo DB schema ideas

You do not need full SQL yet, but define these entities early:

runs
id
session_id
parent_run_id
agent_id
task
status
step_count
max_steps
last_error
inserted_at
updated_at
steps
id
run_id
step_index
action_type
action_payload
result_payload
status
inserted_at
artifacts
id
run_id
type
path_or_uri
metadata
inserted_at
approvals
id
run_id
tool_name
request_payload
decision
decided_by
inserted_at
updated_at
agents
id
name
definition_json
scope
inserted_at
updated_at 24) Skeleton for step persistence

Every step should be recorded.

defmodule Claw.Persistence.StepStore do
def record_planned_action(run_id, step_index, action) do # insert into steps
{:ok, :recorded}
end

def record_step_result(run_id, step_index, result) do
{:ok, :recorded}
end
end

Then in the engine loop:

{:ok, planned_action} <- Planner.plan_next_step(state, context)
:ok = maybe_record_action(state, planned_action)
{:ok, outcome} <- StepExecutor.execute(state, planned_action)
:ok = maybe_record_outcome(state, outcome) 25) A cleaner orchestration split

For maintainability, think in these responsibilities:

RunServer

Owns lifecycle and process state.

Loop

Advances one step.

ContextBuilder

Builds model input.

Planner

Gets next action.

Policy

Approves or denies action.

StepExecutor

Executes one action.

HandoffManager

Creates child runs.

ResultAggregator

Merges child outputs.

This separation is what keeps the engine readable.

26. Very small end-to-end pseudo flow
    User creates run
    Claw.Runs.RunManager.create_run(%{
    agent_id: "coordinator",
    session_id: "sess_001",
    task: "Design an Elixir multi-agent engine"
    })
    Run server starts
    init -> continue(:boot)
    Loop tick
    build context
    → planner says handoff to researcher
    → policy validates
    → handoff manager spawns child
    → parent waits
    Child finishes
    child sends result to parent
    → parent aggregates result
    → loop tick again
    → planner says final_response
    → done
27. What to avoid in the first scaffolding

Do not start with:

agent-to-agent chat rooms
recursive delegation without hard limits
massive reflection loops
unbounded scratchpads
direct model control over tool execution
dangerous tools in-process
one huge “agent.ex” god module

Keep it composable.

28. Practical v1 preset agents

These four are enough:

coordinator

Delegates and synthesizes

researcher

Reads, searches, summarizes

coder

Writes implementation proposals or patches

reviewer

Critiques architecture, correctness, and risk

That gives you a real “team mode” without overengineering.

29. Recommended first implementation order

Build in this order:

Step 1
AgentDefinition
Agents.Registry
RunState
RunManager
RunServer
Step 2
Loop
Planner
ActionParser
Policy
StepExecutor
Step 3
Tools.Registry
one safe tool like read_file
Step 4
HandoffManager
child run result flow
ResultAggregator
Step 5
event publishing
run/step persistence
Step 6
memory retrieval and summary writing
Step 7
approvals and safer write tools 30) Concise main engine pseudo code

This is the shortest version of the engine:

def tick(state) do
context = build_context(state)
action = planner_next_action(state.agent, state.task, context)
validated = validate_action(state, action)

case validated do
{:tool_call, tool, input} ->
result = execute_tool(tool, input, state)
update_state_with_result(state, result)

    {:handoff, agent_id, task} ->
      child_run = spawn_child(agent_id, task, state)
      wait_for_child(state, child_run)

    {:ask_user, question} ->
      emit_question(question)
      pause(state)

    {:final_response, message} ->
      emit_final(message)
      complete(state)

    {:error, reason} ->
      fail(state, reason)

end
end 31) Best design principle to remember

The main rule is:

The model chooses the next action, but the engine owns execution.

That one principle will keep your system stable.

If you want, next I can turn this into a more concrete Elixir code skeleton with actual module stubs that you can paste into a Phoenix project.

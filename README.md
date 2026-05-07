<p align="center">
  <img src="assets/profile-hero.svg" alt="Steven Chou — Personal AI Operating System" width="100%">
</p>

# Steven Chou

**I build Personal AI Operating Systems: memory → agents → evaluation → public proof.**

My work is not a shelf of unrelated repositories. It is one compounding system: capture high-signal inputs, encode identity and judgment, run agents through real tools, evaluate whether they earned trust, and publish the proof chain.

## The Shape of the Work

<p align="center">
  <img src="assets/proof-chain-map.svg" alt="From points to line to surface to body: StevenOS proof chain" width="100%">
</p>

```text
point:   individual tools and experiments
line:    memory → identity → agents → evals → proof
surface: repos, writing, demos, resume, and operating loops reinforce each other
body:    Steven as one inspectable AI-native builder entity
```

## StevenOS Stack

<p align="center">
  <img src="assets/stevenos-stack.svg" alt="StevenOS repository stack" width="100%">
</p>

| Layer | Repository / Surface | Role in the system |
|---|---|---|
| Memory | knowledge-harness *(local hardening before public release)* | Routes agents through an Obsidian-backed knowledge base without mixing content and runtime state. |
| Identity | [digital-twin](https://github.com/stevenchouai/digital-twin) | File-first operating layer for making agents inherit style, judgment, memory, and reusable workflows. |
| Agent runtime | Hermes / OpenClaw contributions | Real assistant plumbing: messaging, Feishu threads, gateway/runtime debugging, OAuth, CLI backends, tools. |
| Model + tool infra | CLIProxyAPI *(public surface pending cleanup)* | Normalizes model access and CLI-compatible API infrastructure. |
| Evaluation | [agent-scorecard](https://github.com/stevenchouai/agent-scorecard) | Trace-first quality gate for deciding whether agents deserve more tokens, permissions, and autonomy. |
| Public proof | [stevenchouai.github.io](https://stevenchouai.github.io) · resume system | Converts repos, essays, demos, and job-market artifacts into one navigable proof chain. |

## Featured Proof

### Agent systems

- **[Agent Scorecard](https://github.com/stevenchouai/agent-scorecard)** — deterministic checks for tool use, verification, durable artifacts, side-effect safety, and anti-busywork behavior.
- **[Claude Code Sourcemap](https://github.com/stevenchouai/claude-code-sourcemap)** — source-map-based architecture guide for AI coding agents.
- **Hermes / OpenClaw work** — practical runtime and gateway fixes across real assistant stacks, not toy demos.

### Personal AI infrastructure

- **[Digital Twin](https://github.com/stevenchouai/digital-twin)** — a personal agent operating layer built around explicit files, skills, memory, and durable outputs.
- **knowledge-harness** *(local hardening before public release)* — CLI/runtime wrapper around an Obsidian LLM wiki.
- **Input Copilot iOS** *(local proof)* — capture → profile signal → radar → Obsidian export loop.

### Career and communication systems

- **Resume system** *(public writeup pending)* — dual-track PM / Engineer resume workflow with local JD matching, AI tailoring, ATS review, and reproducible PDF output.
- **ManageUp** *(archive / visibility pending)* — MCP server + skill library for manager-facing reporting.

## Operating Principles

- **Trace over vibes** — logs, tests, files, reports, screenshots, and commits beat confident claims.
- **Coherence over volume** — every project should explain its upstream and downstream role.
- **Small tools before dashboards** — build the proof loop before polishing the surface.
- **AI as leverage, not theater** — an agent earns autonomy only by producing verified artifacts.

## Selected Writing

- [Claude Code source deep dive](https://stevenchouai.github.io/blog/claude-code-source-deep-dive)
- [Digital Twin operating layer](https://stevenchouai.github.io/blog/digital-twin-operating-layer)
- [AI reshapes engineering SDLC](https://stevenchouai.github.io/blog/ai-reshapes-engineering-sdlc)
- [Public proof chain](https://stevenchouai.github.io/proof-chain)

## Links

- Website: [stevenchouai.github.io](https://stevenchouai.github.io)
- GitHub: [github.com/stevenchouai](https://github.com/stevenchouai)
- Focus: AI agents · evaluation · knowledge systems · product engineering

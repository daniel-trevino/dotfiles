/**
 * MyContext journal: shared memory for coding-agent sessions.
 *
 * In a git repo, every Pi session can:
 * - read the project's previous sessions and plans (mycontext_project_history),
 * - save living execution plans automatically, unless the person opts out (mycontext_save_plan),
 * - log a cumulative session summary at natural stopping points (mycontext_log_session).
 *
 * Notes go to the personal MyContext vault under projects/<repo>/{sessions,plans}/, in the format
 * of the vault skills `log-coding-session` and `execution-plan`, so Claude Code and Codex agents
 * read and write the same files. The extension fills in the facts it knows better than the model:
 * dates, branch, commits, changed files, session id, model.
 *
 * Event handlers cannot call MCP tools, so the model does the writing; the extension nudges it
 * once after a commit or push and offers /log to force it. Sessions outside git repos are skipped.
 *
 * Commands: /log, /journal [on|off|status]
 */

import type { ExtensionAPI, ExtensionContext, ExtensionToolContext } from "@earendil-works/pi-coding-agent";
import { StringEnum } from "@earendil-works/pi-ai";
import { Type } from "typebox";

const MCP = "mcp__mycontext";
const READ = `${MCP}__read_file`;
const WRITE = `${MCP}__write_file`;
const STATE_TYPE = "mycontext-journal";
const NUDGE_TYPE = "mycontext-journal-nudge";
const TOOL_NAMES = ["mycontext_project_history", "mycontext_log_session", "mycontext_save_plan"];
const PLAN_STATUSES = ["draft", "approved", "in-progress", "done", "abandoned"] as const;

interface Project {
	slug: string;
	root: string;
}

/** Persisted per session (pi.appendEntry), so resume keeps the same note and plans. */
interface JournalState {
	enabled: boolean;
	sessionPath?: string;
	plans: string[];
	/** HEAD when the session started; commits after it belong to the session. */
	startHead?: string;
}

interface Runtime {
	project?: Project;
	state: JournalState;
	startedAt: Date;
	editedFiles: Set<string>;
	/** A commit or push happened since the last log. */
	stopSignal: boolean;
	nudged: boolean;
}

const slugify = (value: string, max = 60): string =>
	value
		.toLowerCase()
		.normalize("NFKD")
		.replace(/[\u0300-\u036f]/g, "")
		.replace(/[^a-z0-9]+/g, "-")
		.replace(/^-+|-+$/g, "")
		.slice(0, max)
		.replace(/-+$/g, "") || "untitled";

const localDate = (d: Date): string => {
	const pad = (n: number) => String(n).padStart(2, "0");
	return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
};

/** YAML flow list of JSON strings, which YAML accepts. */
const yamlList = (items: string[]): string => `[${items.map((i) => JSON.stringify(i)).join(", ")}]`;

const bullets = (items: string[] | undefined, empty = "- None"): string =>
	items && items.length > 0 ? items.map((i) => `- ${i.replace(/^\s*[-*]\s+/, "")}`).join("\n") : empty;

/** Minimal front matter reader for the files this extension writes. */
function parseFrontMatter(text: string): { fields: Record<string, string | string[]>; body: string } {
	const match = /^---\n([\s\S]*?)\n---\n?/.exec(text);
	if (!match) return { fields: {}, body: text };
	const fields: Record<string, string | string[]> = {};
	for (const line of match[1].split("\n")) {
		const kv = /^([A-Za-z_]+):\s*(.*)$/.exec(line.replace(/\s+#.*$/, ""));
		if (!kv) continue;
		const raw = kv[2].trim();
		if (raw.startsWith("[")) {
			try {
				fields[kv[1]] = JSON.parse(raw);
			} catch {
				fields[kv[1]] = raw
					.slice(1, -1)
					.split(",")
					.map((s) => s.trim().replace(/^["']|["']$/g, ""))
					.filter(Boolean);
			}
		} else {
			fields[kv[1]] = raw.replace(/^["']|["']$/g, "");
		}
	}
	return { fields, body: text.slice(match[0].length) };
}

const asList = (v: string | string[] | undefined): string[] => (Array.isArray(v) ? v : v ? [v] : []);

/** Insert or replace the index line for `file`, keeping the header and newest-first order. */
function upsertIndexLine(index: string | undefined, header: string, file: string, line: string): string {
	const lines = (index ?? header).trimEnd().split("\n");
	const kept = lines.filter((l) => !l.includes(`](${file})`));
	const firstItem = kept.findIndex((l) => l.startsWith("- "));
	if (firstItem === -1) kept.push(...(kept[kept.length - 1] === "" ? [] : [""]), line);
	else kept.splice(firstItem, 0, line);
	return `${kept.join("\n")}\n`;
}

export default function (pi: ExtensionAPI) {
	const rt: Runtime = {
		state: { enabled: true, plans: [] },
		startedAt: new Date(),
		editedFiles: new Set(),
		stopSignal: false,
		nudged: false,
	};

	const git = async (args: string[], cwd: string): Promise<string | undefined> => {
		const r = await pi.exec("git", ["-C", cwd, ...args]);
		return r.code === 0 ? r.stdout.trim() : undefined;
	};

	async function detectProject(cwd: string): Promise<Project | undefined> {
		const root = await git(["rev-parse", "--show-toplevel"], cwd);
		if (!root) return undefined;
		const remote = await git(["remote", "get-url", "origin"], root);
		let name = remote?.replace(/\/+$/, "").split(/[/:]/).pop()?.replace(/\.git$/, "");
		if (!name) {
			// Worktrees: name the project after the main checkout, not the worktree folder.
			const common = await git(["rev-parse", "--path-format=absolute", "--git-common-dir"], root);
			const parts = (common ?? root).split("/").filter(Boolean);
			name = parts[parts.length - 1] === ".git" ? parts[parts.length - 2] : parts[parts.length - 1];
		}
		return { slug: slugify(name ?? "repo"), root };
	}

	const persist = () => pi.appendEntry(STATE_TYPE, { ...rt.state });

	function setToolsActive(active: boolean) {
		const current = pi.getActiveTools().filter((t) => !TOOL_NAMES.includes(t));
		pi.setActiveTools(active ? [...current, ...TOOL_NAMES] : current);
	}

	function requireProject(): Project {
		if (!rt.project) throw new Error("Not in a git repository; sessions outside repos are not journaled.");
		if (!rt.state.enabled) throw new Error("Journaling is off for this session (/journal on to enable).");
		return rt.project;
	}

	async function call(ctx: ExtensionToolContext, name: string, args: Record<string, unknown>) {
		const outcome = await ctx.executeTool(name, args);
		const result = outcome.result as { content?: { type: string; text?: string }[]; isError?: boolean } | undefined;
		const text = (result?.content ?? [])
			.filter((c) => c.type === "text")
			.map((c) => c.text ?? "")
			.join("\n");
		return { ok: !outcome.isError && !result?.isError, text };
	}

	async function readVault(ctx: ExtensionToolContext, path: string): Promise<string | undefined> {
		const r = await call(ctx, READ, { path, max_chars: 100000 });
		// read_file appends a "[version N]" footer that is not part of the file.
		return r.ok ? r.text.replace(/\n*\[version \d+\]\s*$/, "\n") : undefined;
	}

	async function writeVault(ctx: ExtensionToolContext, path: string, content: string, extra: Record<string, unknown> = {}) {
		const r = await call(ctx, WRITE, { path, content, ...extra });
		if (!r.ok) throw new Error(`MyContext write_file ${path} failed: ${r.text}`);
	}

	async function ensureProjectIndex(ctx: ExtensionToolContext, p: Project) {
		const path = `projects/${p.slug}/_index.md`;
		const existing = await readVault(ctx, path);
		if (existing === undefined) {
			await writeVault(
				ctx,
				path,
				`# ${p.slug}\n\nCoding work on the \`${p.slug}\` repository.\n\n- [Sessions](sessions/_index.md) — coding-agent session summaries, newest first\n- [Plans](plans/_index.md) — execution plans per feature\n`,
				{ if_exists: "fail" },
			);
		} else if (!existing.includes("sessions/_index.md")) {
			await writeVault(
				ctx,
				path,
				`\n- [Sessions](sessions/_index.md) — coding-agent session summaries, newest first\n- [Plans](plans/_index.md) — execution plans per feature\n`,
				{ append: true },
			);
		}
	}

	pi.on("session_start", async (_event, ctx) => {
		rt.project = await detectProject(ctx.cwd);
		const header = ctx.sessionManager.getHeader();
		rt.startedAt = header?.timestamp ? new Date(header.timestamp) : new Date();
		rt.editedFiles = new Set();
		rt.stopSignal = false;
		rt.nudged = false;
		rt.state = { enabled: true, plans: [] };
		for (const entry of ctx.sessionManager.getBranch()) {
			if (entry.type === "custom" && entry.customType === STATE_TYPE && entry.data) {
				rt.state = { ...rt.state, ...(entry.data as JournalState) };
			}
		}
		if (rt.project && !rt.state.startHead) {
			rt.state.startHead = await git(["rev-parse", "HEAD"], rt.project.root);
			if (rt.state.startHead) persist();
		}
		setToolsActive(Boolean(rt.project) && rt.state.enabled);
	});

	// Track what the session changed and whether a natural stopping point (commit/push) happened.
	pi.on("tool_call", async (event, ctx) => {
		if (!rt.project) return;
		const input = (event as { input?: Record<string, unknown> }).input ?? {};
		if ((event.toolName === "edit" || event.toolName === "write") && typeof input.path === "string") {
			const abs = input.path.startsWith("/") ? input.path : `${ctx.cwd}/${input.path}`;
			rt.editedFiles.add(abs.startsWith(`${rt.project.root}/`) ? abs.slice(rt.project.root.length + 1) : input.path);
		}
		if (event.toolName === "bash" && typeof input.command === "string") {
			if (/\bgit\b[^\n|;&]*\b(commit|push)\b/.test(input.command)) {
				rt.stopSignal = true;
				rt.nudged = false;
			}
		}
	});

	// One nudge per commit/push: the model decides whether this is really a stopping point.
	pi.on("agent_before_settle", async (event) => {
		if (!rt.project || !rt.state.enabled || event.outcome !== "completed") return;
		if (!rt.stopSignal || rt.nudged) return;
		rt.nudged = true;
		return {
			entries: [
				{
					type: "custom_message" as const,
					customType: NUDGE_TYPE,
					display: false,
					content:
						"[mycontext-journal] A commit or push happened since the last session log. If this is a natural stopping point, update the session summary now with mycontext_log_session (cumulative; it replaces this session's note) and update any execution plan you worked on with mycontext_save_plan. If work is still mid-flight, skip logging and do not mention this note.",
				},
			],
			continue: true,
		};
	});

	pi.registerTool({
		name: "mycontext_project_history",
		label: "Project history",
		description:
			"Read this repository's shared memory from the MyContext vault: the session index, the latest session summary, and the execution plans with their status. Written by every coding agent (Pi, Claude Code, Codex).",
		promptSnippet: "Read previous sessions and plans for this repository from MyContext",
		promptGuidelines: [
			"In this repository, call mycontext_project_history once before substantive work, to pick up where earlier sessions and agents left off. Skip it for trivial questions.",
		],
		parameters: Type.Object({}),
		reachesTools: () => [MCP],
		executionMode: "sequential",
		async execute(_id, _params, _signal, _onUpdate, ctx) {
			const p = requireProject();
			const base = `projects/${p.slug}`;
			const [sessions, plans] = await Promise.all([
				readVault(ctx, `${base}/sessions/_index.md`),
				readVault(ctx, `${base}/plans/_index.md`),
			]);
			const latest = sessions && /\]\(([^)]+\.md)\)/.exec(sessions)?.[1];
			const latestNote = latest ? await readVault(ctx, `${base}/sessions/${latest}`) : undefined;
			const parts = [
				`# Project history: ${p.slug} (MyContext ${base}/)`,
				sessions ? `## Sessions index\n${sessions.trim()}` : "## Sessions index\nNo sessions logged yet.",
				latestNote ? `## Latest session (${base}/sessions/${latest})\n${latestNote.trim().slice(0, 8000)}` : "",
				plans ? `## Plans\n${plans.trim()}` : "## Plans\nNo plans yet.",
				"Read older sessions or a plan with mcp__mycontext__read_file if relevant.",
			];
			return { content: [{ type: "text", text: parts.filter(Boolean).join("\n\n") }], details: undefined };
		},
	});

	pi.registerTool({
		name: "mycontext_log_session",
		label: "Log session",
		description:
			"Write or update this session's summary in the MyContext vault (projects/<repo>/sessions/). Each call replaces the session's note, so always pass the cumulative summary of the whole session. Date, branch, commits, changed files, model and session id are added automatically. Never include secrets or file contents.",
		promptSnippet: "Log a cumulative summary of this session to MyContext",
		promptGuidelines: [
			"Call mycontext_log_session at natural stopping points: a task or feature is finished, after a commit or push, when the user wraps up or says goodbye, or before switching to an unrelated topic. Not after every message, and not for sessions with no lasting value. Write for an agent starting cold; facts only, no secrets.",
		],
		parameters: Type.Object({
			topic: Type.String({ description: "Short topic of the session, e.g. 'MyContext session logging'" }),
			summary: Type.String({ description: "2-4 sentences: goal and outcome" }),
			done: Type.Array(Type.String(), { description: "What was done" }),
			decisions: Type.Optional(Type.Array(Type.String(), { description: "'<decision> — <why>'" })),
			state: Type.String({ description: "What works, what is half-done, anything uncommitted" }),
			next_steps: Type.Optional(Type.Array(Type.String())),
			plans: Type.Optional(
				Type.Array(Type.String(), { description: "Feature slugs of plans worked on that were not saved in this session" }),
			),
		}),
		reachesTools: () => [MCP],
		executionMode: "sequential",
		async execute(_id, params, _signal, _onUpdate, ctx) {
			const p = requireProject();
			const base = `projects/${p.slug}`;
			const date = localDate(rt.startedAt);
			const range = rt.state.startHead ? [`${rt.state.startHead}..HEAD`] : [`--since=${rt.startedAt.toISOString()}`];
			const [branch, commitsOut, committedFiles] = await Promise.all([
				git(["rev-parse", "--abbrev-ref", "HEAD"], p.root),
				git(["log", ...range, "--format=%h"], p.root),
				git(["log", ...range, "--name-only", "--format="], p.root),
			]);
			const commits = (commitsOut ?? "").split("\n").filter(Boolean).reverse();
			const files = [...new Set([...(committedFiles ?? "").split("\n").filter(Boolean), ...rt.editedFiles])].sort();

			let path = rt.state.sessionPath;
			if (!path) {
				const stem = `${base}/sessions/${date}-${slugify(params.topic)}`;
				path = `${stem}.md`;
				for (let n = 2; (await readVault(ctx, path)) !== undefined && n < 20; n++) path = `${stem}-${n}.md`;
			}
			const file = path.split("/").pop() as string;
			const planPaths = [
				...new Set([...rt.state.plans, ...(params.plans ?? []).map((s) => `plans/${slugify(s.replace(/\.md$/, "").split("/").pop() ?? s)}.md`)]),
			];

			const note = [
				"---",
				"type: session",
				`project: ${p.slug}`,
				`date: ${date}`,
				`topic: ${JSON.stringify(params.topic)}`,
				"harness: pi",
				`model: ${ctx.model?.id ?? "unknown"}`,
				`branch: ${branch ?? "unknown"}`,
				`commits: ${yamlList(commits)}`,
				`files: ${yamlList(files)}`,
				`plans: ${yamlList(planPaths)}`,
				`session_id: ${ctx.sessionManager.getSessionId()}`,
				`updated: ${new Date().toISOString()}`,
				"---",
				"",
				`# ${params.topic}`,
				"",
				params.summary.trim(),
				"",
				"## Done",
				bullets(params.done),
				"",
				"## Decisions",
				bullets(params.decisions),
				"",
				"## State",
				params.state.trim(),
				"",
				"## Next steps",
				bullets(params.next_steps),
				"",
				...(planPaths.length ? ["## Plans", ...planPaths.map((pp) => `- [${pp.replace(/^plans\/|\.md$/g, "")}](../${pp})`), ""] : []),
			].join("\n");

			await writeVault(ctx, path, note, { title: params.topic, tags: ["coding-session", p.slug] });

			const oneLine = params.summary.trim().split(/(?<=[.!?])\s/)[0].slice(0, 200);
			const indexPath = `${base}/sessions/_index.md`;
			const index = await readVault(ctx, indexPath);
			await writeVault(
				ctx,
				indexPath,
				upsertIndexLine(
					index,
					`# ${p.slug}: sessions\n\nCoding-agent session summaries, newest first. Format: skills/log-coding-session.md\n`,
					file,
					`- ${date} · [${params.topic}](${file}) — ${oneLine} · pi`,
				),
			);
			await ensureProjectIndex(ctx, p);

			// Link back from each plan to this session.
			for (const pp of planPaths) {
				const planPath = `${base}/${pp}`;
				const plan = await readVault(ctx, planPath);
				if (!plan) continue;
				const { fields } = parseFrontMatter(plan);
				const sessions = asList(fields.sessions);
				const ref = `sessions/${file}`;
				if (sessions.includes(ref)) continue;
				const updated = plan.replace(/^sessions:.*$/m, `sessions: ${yamlList([...sessions, ref])}`);
				if (updated !== plan) await writeVault(ctx, planPath, updated);
			}

			rt.state.sessionPath = path;
			rt.stopSignal = false;
			rt.nudged = false;
			persist();
			return { content: [{ type: "text", text: `Session logged to MyContext: ${path}` }], details: undefined };
		},
	});

	pi.registerTool({
		name: "mycontext_save_plan",
		label: "Save plan",
		description:
			"Create or update the living execution plan for one feature in the MyContext vault (projects/<repo>/plans/<feature>.md). Pass the full current plan body; it replaces the previous version. Created date, branch and linked sessions are kept automatically.",
		promptSnippet: "Save or update a feature's execution plan in MyContext",
		promptGuidelines: [
			"Whenever you produce an implementation plan the user intends to act on, save it with mycontext_save_plan right away, without asking, unless the user said not to save it. Brainstorms and lists of options are not plans.",
			"While executing a saved plan, keep it current with mycontext_save_plan: tick steps, set status (approved when the user agrees, in-progress, done, abandoned), and record changes of approach in the Decision log instead of starting a new plan.",
			`Date Decision log entries with today's date: ${localDate(new Date())}.`,
		],
		parameters: Type.Object({
			feature: Type.String({ description: "Feature name; also determines the file name. Reuse the same name to update." }),
			status: StringEnum(PLAN_STATUSES),
			body: Type.String({
				description:
					"Markdown without front matter or title, with sections: ## Goal, ## Context, ## Approach, ## Steps (- [ ] / - [x] checklist), ## Risks, ## Verification, ## Decision log (- YYYY-MM-DD — change and why)",
			}),
		}),
		reachesTools: () => [MCP],
		executionMode: "sequential",
		async execute(_id, params, _signal, _onUpdate, ctx) {
			const p = requireProject();
			const base = `projects/${p.slug}`;
			const file = `${slugify(params.feature)}.md`;
			const path = `${base}/plans/${file}`;
			const today = localDate(new Date());
			const existing = await readVault(ctx, path);
			const { fields } = parseFrontMatter(existing ?? "");
			const sessions = asList(fields.sessions);
			const sessionFile = rt.state.sessionPath?.split("/").pop();
			if (sessionFile && !sessions.includes(`sessions/${sessionFile}`)) sessions.push(`sessions/${sessionFile}`);
			const branch = await git(["rev-parse", "--abbrev-ref", "HEAD"], p.root);

			const content = [
				"---",
				"type: plan",
				`project: ${p.slug}`,
				`feature: ${JSON.stringify(params.feature)}`,
				`status: ${params.status}`,
				`created: ${typeof fields.created === "string" && fields.created ? fields.created : today}`,
				`updated: ${today}`,
				`branch: ${branch ?? "unknown"}`,
				`sessions: ${yamlList(sessions)}`,
				"---",
				"",
				`# ${params.feature}`,
				"",
				params.body.trim(),
				"",
			].join("\n");
			await writeVault(ctx, path, content, { title: params.feature, tags: ["execution-plan", p.slug] });

			const indexPath = `${base}/plans/_index.md`;
			const index = await readVault(ctx, indexPath);
			await writeVault(
				ctx,
				indexPath,
				upsertIndexLine(
					index,
					`# ${p.slug}: plans\n\nExecution plans per feature. Format: skills/execution-plan.md\n`,
					file,
					`- [${params.feature}](${file}) — ${params.status} · updated ${today}`,
				),
			);
			await ensureProjectIndex(ctx, p);

			const rel = `plans/${file}`;
			if (!rt.state.plans.includes(rel)) rt.state.plans.push(rel);
			persist();
			return {
				content: [{ type: "text", text: `Plan ${existing ? "updated" : "saved"} in MyContext: ${path} (${params.status})` }],
				details: undefined,
			};
		},
	});

	const notify = (ctx: ExtensionContext, msg: string, level: "info" | "warning" = "info") => {
		if (ctx.hasUI) ctx.ui.notify(msg, level);
	};

	pi.registerCommand("log", {
		description: "Log this session to MyContext now (and update any plan worked on)",
		handler: async (_args, ctx) => {
			if (!rt.project) return notify(ctx, "Not in a git repository; nothing to log.", "warning");
			if (!rt.state.enabled) return notify(ctx, "Journaling is off (/journal on).", "warning");
			pi.sendUserMessage(
				"Log this session to MyContext now with mycontext_log_session (cumulative summary of the whole session), and update any execution plan you worked on with mycontext_save_plan.",
				ctx.isIdle() ? undefined : { deliverAs: "followUp" },
			);
		},
	});

	pi.registerCommand("journal", {
		description: "MyContext journal: /journal on | off | status",
		handler: async (args, ctx) => {
			const arg = (args ?? "").trim();
			if (arg === "on" || arg === "off") {
				rt.state.enabled = arg === "on";
				persist();
				setToolsActive(Boolean(rt.project) && rt.state.enabled);
				return notify(ctx, `MyContext journal ${arg} for this session.`);
			}
			const lines = rt.project
				? [
						`Project: projects/${rt.project.slug}/ (${rt.state.enabled ? "on" : "off"})`,
						`Session note: ${rt.state.sessionPath ?? "not logged yet"}`,
						`Plans: ${rt.state.plans.join(", ") || "none"}`,
					]
				: ["Not in a git repository; journaling skipped."];
			notify(ctx, lines.join("\n"));
		},
	});
}

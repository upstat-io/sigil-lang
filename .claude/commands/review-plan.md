# Review Plan Command

Iteratively review and refine any plan through 10 sequential analysis passes. Each pass is performed by an external agent that reads the current state of the plan, identifies issues, collects questions, and then updates the plan after user Q&A.

## Usage

```
/review-plan <plan-path>
```

- `plan-path`: Path to the plan directory (e.g., `plans/lexer_v2`, `plans/llvm_v2`) or a single plan file

## Overview

This command runs **10 sequential refinement passes** over a plan. Each pass:

1. **Agent analyzes** the plan in its current state
2. **Questions collected** — agent returns findings + questions for the user
3. **Interactive Q&A** — questions presented to user with recommended answers and reasoning
4. **Agent updates** the plan based on analysis + user answers
5. **Next pass** begins on the updated plan

Each pass builds on the previous one's changes, creating iterative refinement. Early passes catch major issues; later passes catch subtleties, inconsistencies introduced by earlier edits, and polish.

---

## Workflow

### Step 0: Setup

1. **Resolve the plan path** from the argument. If it's a directory, identify all plan files (index.md, 00-overview.md, section-*.md). If it's a single file, use that.
2. **Read all plan files** to understand the current state.
3. **Create a todo list** with 10 tasks, one for each review pass. All tasks are sequential (each blocked by the previous one).

### Step 1-10: Review Passes (Sequential)

For each pass N (1 through 10), execute the following two-phase process:

#### Phase A: Analysis (External Agent)

Launch a **general-purpose agent** (subagent_type: "general-purpose") with the following prompt structure:

```
You are performing review pass {N}/10 on a plan. Your job is to thoroughly analyze the plan
and identify issues WITHOUT making changes yet.

PLAN FILES TO READ:
{list all plan file paths}

REVIEW FOCUS:
Go through this plan and thoroughly check to make sure:
1. The design is accurate and sound
2. All facts are checked for correctness
3. It utilizes the existing Ori systems appropriately (lexer, parser, types, IR, eval, etc.)
4. Architecture decisions align with the codebase (read relevant source files to verify)
5. Referenced files, types, functions, and modules actually exist
6. The implementation steps are in the right order and dependencies are correct
7. Nothing is missing — gaps in the design, unaddressed edge cases, missing error handling
8. Terminology is consistent with the Ori codebase and spec

WHAT TO EXAMINE:
- Read the plan files thoroughly
- Cross-reference claims against actual source code in compiler/
- Check that referenced Ori systems (lexer: compiler/ori_lexer/, parser: compiler/ori_parse/,
  types: compiler/ori_types/, IR: compiler/ori_ir/, eval: compiler/ori_eval/,
  diagnostic: compiler/ori_diagnostic/) are accurately described
- Verify that proposed changes are compatible with existing architecture
- Check the spec at docs/ori_lang/0.1-alpha/spec/ for accuracy

PASS {N} CONTEXT:
{If N == 1: "This is the first pass. Focus on major structural issues, factual errors,
  and fundamental design problems."}
{If N == 2-3: "Previous passes have addressed major issues. Focus on accuracy of details,
  correct references to existing code, and design consistency."}
{If N == 4-6: "The plan has been through several rounds. Focus on subtle issues: edge cases,
  missing steps, ordering problems, and interactions between sections."}
{If N == 7-8: "The plan is maturing. Focus on completeness, polish, and ensuring nothing
  was broken by previous edits."}
{If N == 9-10: "Final passes. Focus on overall coherence, readability, and any remaining
  inconsistencies. Look for issues introduced by previous rounds of editing."}

YOUR OUTPUT MUST BE IN THIS FORMAT:

## Issues Found

For each issue:
### Issue {number}: {title}
- **Location**: {file path and section/line}
- **Problem**: {what's wrong}
- **Evidence**: {what you found in the source code or spec that contradicts the plan}
- **Suggested Fix**: {how to fix it}
- **Confidence**: HIGH / MEDIUM / LOW

## Questions for User

For each question:
### Question {number}: {title}
- **Context**: {why this question matters}
- **Question**: {the actual question}
- **Recommended Answer**: {your recommendation}
- **Reasoning**: {why you recommend this}
- **Alternatives**: {other valid options}

## Summary

- Issues found: {count}
- Questions for user: {count}
- Overall plan health: {assessment}
```

#### Phase B: User Q&A (Interactive)

After the agent returns:

1. **If the agent found questions**: Present them to the user using **AskUserQuestion**, one at a time or grouped logically. For each question:
   - Show the context and reasoning
   - Offer the agent's recommended answer as the first option (marked as recommended)
   - Include alternatives as other options
   - Allow "Other" for custom input

2. **If no questions**: Skip to Phase C.

#### Phase C: Plan Update (External Agent)

Launch a **general-purpose agent** to apply the fixes. Use `resume` if possible (same agent from Phase A), otherwise launch a new agent with all context:

```
You are performing the UPDATE phase of review pass {N}/10.

PLAN FILES TO MODIFY:
{list all plan file paths}

ISSUES TO FIX:
{paste all issues from Phase A}

USER ANSWERS TO QUESTIONS:
{paste user's answers from Phase B Q&A}

INSTRUCTIONS:
1. Read each plan file
2. Apply fixes for all issues identified in the analysis
3. Incorporate the user's answers into the plan where relevant
4. Use the Edit tool to make precise, targeted changes
5. Do NOT rewrite entire files — make surgical edits
6. Do NOT introduce new issues or change things that weren't flagged
7. After all edits, re-read modified files to verify changes are correct

IMPORTANT:
- Only modify plan files, never modify source code
- Preserve existing formatting and structure
- If an issue fix conflicts with a user answer, the user answer takes priority
```

#### Phase D: Progress Report

After each pass completes, briefly report to the user:
```
Pass {N}/10 complete.
- Issues fixed: {count}
- Questions resolved: {count}
- Files modified: {list}

Moving to pass {N+1}...
```

Mark the todo item as completed.

---

## Todo List Structure

Create these tasks at the start:

| Task | Subject | Active Form |
|------|---------|-------------|
| 1 | Review plan — Pass 1: Major structural issues | Analyzing plan (pass 1/10) |
| 2 | Review plan — Pass 2: Detail accuracy | Analyzing plan (pass 2/10) |
| 3 | Review plan — Pass 3: Code reference verification | Analyzing plan (pass 3/10) |
| 4 | Review plan — Pass 4: Edge cases and gaps | Analyzing plan (pass 4/10) |
| 5 | Review plan — Pass 5: Section interactions | Analyzing plan (pass 5/10) |
| 6 | Review plan — Pass 6: Completeness check | Analyzing plan (pass 6/10) |
| 7 | Review plan — Pass 7: Polish and consistency | Analyzing plan (pass 7/10) |
| 8 | Review plan — Pass 8: Coherence review | Analyzing plan (pass 8/10) |
| 9 | Review plan — Pass 9: Final issues sweep | Analyzing plan (pass 9/10) |
| 10 | Review plan — Pass 10: Final validation | Analyzing plan (pass 10/10) |

Each task (except #1) is **blocked by** the previous task. Process them strictly in order.

---

## Important Constraints

### DO:
- Read actual source code to verify plan claims
- Check that referenced types, functions, modules exist
- Verify proposed architecture against existing codebase patterns
- Present questions with recommended answers and clear reasoning
- Make surgical edits to plan files
- Track all changes across passes

### DO NOT:
- Modify any source code files (only plan files)
- Run passes in parallel (must be strictly sequential)
- Skip the Q&A phase (even if there are no questions, report that)
- Make changes not supported by the analysis
- Rewrite entire plan files (surgical edits only)
- Let agents hallucinate file paths or type names — verify everything

### Q&A Guidelines:
- Group related questions when presenting to user
- Always provide a recommended answer with reasoning
- If the agent's recommended answer seems wrong, flag that to the user
- Keep Q&A focused — avoid philosophical questions, focus on concrete decisions
- If a question was already answered in a previous pass, don't re-ask it

---

## Completion

After all 10 passes:

```
Plan review complete (10/10 passes).

Summary:
- Total issues fixed: {sum across all passes}
- Total questions resolved: {sum}
- Files modified: {list with modification counts}

The plan has been iteratively refined through 10 review passes.
Review the final state of the plan at: {plan-path}
```

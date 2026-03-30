---
title: "Editorial review (MVR)"
date: 2026-03-30
url: "/editorial-review/"
---

This page describes the **Minimal Editorial Review (MVR)** framework used by editors when reviewing pull requests. It is a **quality gate**, not academic peer review.

## Goal

Ensure posts are **accurate, readable, appropriately tagged, and safe to publish**—while maintaining a fast turnaround (target: 48–72 hours).

---

## 1. Core review dimensions

### A. Scope and relevance (fast gate)

* Fits the **genomics × AI** remit
* Declared **`scope`** (e.g. tutorials, protocols, insights, ideas, discussions, negative-results) matches the actual content
* **`audience`** (within-field, general, intro-to-field) is plausible for the writing

**Decision rule:** If misaligned → reject or ask the author to reclassify early (update frontmatter and framing).

### B. Technical soundness (lightweight)

* No obvious factual errors
* Methods and tools described correctly
* Claims are **proportionate to evidence**

**For tutorials and protocols:** Steps are logically reproducible; code snippets are coherent (they need not be executed in review).

**For opinion or perspective-style pieces:** Framing is clear (opinion vs. established fact).

**Decision rule:** If correctness is uncertain → escalate to the author (or optional second reviewer; see below).

### C. Clarity and readability

* Clear target audience (implicit or explicit)
* Logical structure: introduction → content → takeaway
* Minimal ambiguity or confusing phrasing

**Heuristic:** A domain peer should be able to follow without re-reading sections multiple times.

### D. Metadata and tagging

* **`tags`** are relevant and consistent with the post
* **`categories`** and **`scope`** reflect the piece
* Title accurately reflects content

### E. Compliance and risk

* No plagiarism
* No slander or defamation
* Proper attribution (figures, code, ideas)
* No unethical or sensitive data misuse (especially genomics)

### F. Presentation quality

* Clean formatting (headers, spacing)
* Figures render correctly
* Links work
* Code blocks properly formatted

---

## 2. Executive summary requirement

### Purpose

Provide a **clear, concise entry point** for readers across disciplines.

### Requirement

Each post must include an **executive summary** (3–5 bullets or a short paragraph) that:

* States the topic
* Highlights key takeaway(s)
* Indicates intended audience

On this site, that content lives in the **`{{</* summary */>}}` … `{{</* /summary */>}}`** shortcode pair in the post body (see [submission guidelines](/submission-guidelines/) and the blog post template).

### Responsibility

* **Preferred:** Provided by the author
* **Fallback:** Added or refined by the handling editor if missing or unclear

### Editor guidelines

* Neutral and faithful to content
* No hype or reinterpretation
* Plain language
* About 75–100 words or 3–5 bullets

---

## 3. Review outcomes

Editors choose one:

* **Accept**
* **Minor revisions**
* **Major revisions**
* **Reject** (out of scope or insufficient quality)

---

## 4. Minimal review checklist

### Must pass (hard requirements)

* [ ] In scope (genomics × AI)
* [ ] No obvious technical errors
* [ ] No plagiarism / slander
* [ ] Tags, scope, and audience correctly applied
* [ ] Readable and logically structured
* [ ] Executive summary present in the summary shortcode (or added by editor)

### Should pass (soft requirements)

* [ ] Clear takeaway or value
* [ ] Appropriate level for audience
* [ ] References and links included where needed
* [ ] Formatting clean

---

## 5. Time expectations

* Initial triage: under 10 minutes
* Full minimal review: 30–45 minutes
* Total turnaround: 2–3 days (target)

---

## 6. Escalation (optional review layer)

Escalate beyond MVR only if:

* Highly technical or novel method
* Potentially controversial claims
* Uncertainty about correctness
* High-visibility post

**Action:** Assign a second reviewer (focus on correctness, clarity, and usefulness).

---

## 7. Roles and responsibilities

### Handling editor

* Owns the review process
* Completes the MVR checklist
* Adds or refines the executive summary if needed
* Makes the recommendation to the team

### Optional reviewer

* Provides input when escalated
* Focus on correctness, clarity, and usefulness

---

## 8. Guiding principle

> We are not performing academic peer review—we are ensuring clarity, correctness, and usefulness.

---

## 9. Optional submission enhancements

Authors are encouraged to make explicit:

* **Who is this for?**
* **What will the reader learn?**

These improve review efficiency and content clarity. They can sit in the summary block or the introduction.

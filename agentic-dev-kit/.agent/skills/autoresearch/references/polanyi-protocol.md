# Polanyi Protocol: Epistemological Enhancements for Autoresearch

This document details the four "Tacit Knowledge" (隐性知识) mechanisms inspired by Michael Polanyi's philosophy, designed to prevent the Autoresearch loop from falling into mechanical literalness and to grant it expert-level intuition.

## 1. Tacit Tradition Map (传统的前置内化)

**Integration Point:** Setup Phase

Before the Autoresearch loop begins any modifications, it must first construct `.agent/state/tacit-tradition-map.md`. 
- **Purpose:** To build a "subsidiary awareness" (辅助意识) of the codebase. Instead of treating the codebase as a sterile object, the agent must "indwell" (内居) its history.
- **Action:** The agent automatically extracts the unwritten design language, architectural compromises, and coding habits of the project. This map acts as the unconscious foundation that guides the focal (焦点) problem-solving during iterations.

## 2. Aesthetic Review Gate (审美的机制化)

**Integration Point:** Phase 7.5 (Review Gate)

- **Trigger:** `IF metric_improved_significantly AND complexity_increased`
- **Purpose:** Mechanical metrics (like coverage or latency) can sometimes be gamed by introducing "ugly complexity." Ugliness is a tacit judgment. 
- **Action:** Triggers an independent Aesthetic Review utilizing a third-party persona (e.g., Expert B). This reviewer acts as a peer in the "Republic of Science," specifically evaluating the "subconscious chaos" and architecture friction introduced by the change. If declared aesthetically disruptive, the change is reverted despite its metric success.

## 3. Rebellion Against the Guard (对护栏的合理反叛)

**Integration Point:** Phase 5.5 / Phase 6 (Guard / Decide)

- **Trigger:** `IF optimization_is_revolutionary_but_guard_failed`
- **Purpose:** Traditional CI/CD guards possess "Specific Authority" (绝对威权). In Polanyi's framework, scientific paradigms advance by occasionally rebelling against old rules. 
- **Action:** Instead of an immediate mechanical revert when a guard fails, the system undergoes a meta-investigation: *Is the Guard itself enforcing an obsolete paradigm?* If the optimization is judged to be a massive leap, the agent is authorized to rewrite the Guard (tests) to align with the new superior architecture, cementing a paradigm shift.

## 4. Epistemological Escalation (环境级断裂 Escalation)

**Integration Point:** Crash Recovery

- **Trigger:** Persistent Runtime errors, Crashes, or Timeouts that survive 3 mechanical retry attempts.
- **Purpose:** When a hammer breaks, awareness shifts from the nail to the hammer. The agent must recognize when "Indwelling" in the toolset has collapsed.
- **Action:** The loop exits "code generation mode" and activates "Tool Alignment mode." The agent autonomously investigates environment drift, incompatible framework assumptions, or deep conceptual misalignments rather than blindly retrying syntax changes. Treat the tooling as broken, not the code.

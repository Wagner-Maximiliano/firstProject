---
name: ama-human-testing
description: Generating plain-language GUI test guides for non-developers, spinning up isolated test environments, and collecting pass/fail feedback.
version: 0.1.0
license: MIT
metadata:
  hermes:
    tags: [ama, testing, human, gui, qa]
    category: ama
---

# Human Testing & Per-Phase Test Guides

Machines can run unit tests, but they cannot judge a graphical interface the way a user does. Any feature with a GUI is **always human-tested**. This skill makes that as easy and foolproof as possible for a non-developer.

## When to Use

- At the end of a build phase that includes any graphical UI, before accepting the phase as complete.
- When a human needs to verify behavior that automated tests cannot (visual polish, usability, perceived performance).
- When gathering pass/fail feedback from the human before merging a phase to `main`.

## Procedure

### 1. Identify what to test

After a phase build is complete (all code merged, CI green, automated tests passing), check if the phase includes any **GUI** or **human-perceivable behavior** (visual output, UI elements, user interactions). If yes, proceed. If the phase is purely backend/logic with no visual component, skip to automated verification.

**Examples that need human testing:**
- Any web UI, mobile UI, or graphical component.
- User-facing behavior that is subjective (fonts, spacing, colors, clarity of messaging).
- Workflows that involve navigation or sequence of clicks/interactions.

**Examples that do NOT need human testing:**
- API endpoints (automated via curl/Postman).
- Data correctness (automated via unit tests).
- Performance benchmarks (automated via load tests).

### 2. Generate a test guide

The test guide is a **plain-language document** with exactly 5 sections. Write it for someone with **zero development skills**—no jargon, numbered steps, clear screenshots/examples. Use a T1 model to auto-assemble this from the phase's tasks and acceptance criteria (cheap to produce).

**Template: 5 sections**

```
# Phase X Test Guide

## 1. What was done
In plain language (2–3 sentences), what this phase added or changed.
Example: "We added a login form to the home page. You can now create an account with your email and password."

## 2. How to run it
Literal command(s) or clicks to start the test environment. No jargon.
Example: "1. Open your terminal. 2. Run: `./run-test-env.sh`. 3. Wait for the message 'App ready at http://localhost:3000'. 4. Open that URL in your browser."

## 3. What to check
A numbered checklist of things to look at or do. Each item is one clear action.
Example:
1. Click on "Sign Up" at the top-right.
2. Fill in your email and password.
3. Click "Create Account".
4. Check that you see a welcome message with your email.

## 4. What you should see
For each item in section 3, describe the expected result. Include a screenshot if helpful.
Example: "After step 3, the page should show 'Welcome, your-email@example.com' and a 'Dashboard' button. You should NOT see an error message."

## 5. If it doesn't match
What to do when reality differs: how to report it, what info to include, and that the system will diagnose and fix automatically.
Example: "If you see an error message instead of the welcome screen: 1. Take a screenshot. 2. Open Telegram and send it to @channel with 'Phase X test failed: login error'. 3. The system will automatically investigate and re-test once fixed. Do not debug locally."
```

### 3. Spin up an isolated test environment

The test environment must be self-contained, reproducible, and never touch production data.

**For Python projects:**

1. Create a `.venv-test` directory (separate from the development `.venv`):
   ```bash
   python3 -m venv .venv-test
   source .venv-test/bin/activate  # on Windows: .venv-test\Scripts\activate
   pip install -r requirements-test.txt  # or requirements.txt if there's no separate test file
   ```

2. Create a `run-test-env.sh` script in the repo root:
   ```bash
   #!/bin/bash
   source .venv-test/bin/activate
   python seed_test_data.py  # if you have seeded data
   python -m flask run  # or python manage.py runserver, etc.
   ```
   (Or equivalent for your framework.)

3. **Seed sample data** so the human sees realistic content:
   - Create a `seed_test_data.py` (or similar) that populates the database with fake accounts, posts, or records.
   - Run it once when setting up the test environment.
   - Document any credentials needed: "Log in as test@example.com / password123."

**For JavaScript projects:**

1. Do a clean, isolated dependency install (don't reuse the dev install):
   ```bash
   npm ci  # clean install from package-lock.json (or yarn install --frozen-lockfile)
   ```

2. Create a `run-test-env.sh`:
   ```bash
   npm run seed-data  # populate test data
   npm run dev  # start dev server
   ```

3. Seed sample data via `scripts/seed-test-data.js` or similar.

**For other stacks**, follow the same pattern: isolated environment, one script to run it, seeded data.

4. **Test the test environment locally** before handing it off. Verify it boots without errors and shows the expected sample data.

### 4. Deliver the test guide and environment via Telegram

Once the guide is written and the environment is tested:

1. **Post to the human's Telegram channel** (the same bridge the system uses for escalations; see §11.5 in FRAMEWORK_SPEC.md):
   ```
   Phase X ready for testing! 🚀

   What was done: <1–2 sentences from section 1>
   
   To test:
   1. Open your terminal
   2. cd /path/to/repo
   3. Run: ./run-test-env.sh
   4. Wait for "App ready at …" and follow the guide below.

   [Attach or paste the full 5-section test guide]

   Tap the button below when you're done:
   ✅ PASS — everything worked
   ❌ FAIL — something didn't match (tell us what)
   ```

2. **Include a link to the test guide** (post the markdown or a shareable doc link—not just a screenshot, so the human can copy commands).

3. **Set a patience window.** The Watchdog knows how long to wait before assuming the human is busy and pausing that stream (typical: 8–24 hours). Record this in the issue/ADR.

### 5. Collect feedback

**If PASS:**
- Human taps ✅ PASS in Telegram.
- Phase is accepted. Move the final issue/PR card to **Done**. Merge to `main` if not already done.
- Log the pass in `STATE.md` and move to the next phase.

**If FAIL:**
- Human taps ❌ FAIL and types a note or takes a screenshot (e.g., "Button doesn't appear on mobile" or "Error message says 'undefined'").
- The human's feedback becomes a **new issue** (auto-created from the Telegram note).
- Builders diagnose, fix, and re-run automated tests (no retest needed if the fix is obvious and tested).
- System re-generates the test guide and re-posts to Telegram: "Phase X test — round 2, ready to retry."
- Human re-tests (or confirms with a re-test if only a small fix was needed).
- Cycle repeats until PASS.

### 6. Archive the test environment

Once the phase is accepted (human says PASS):

1. **Commit the test seed data** to the repo (if not already done):
   ```bash
   git add seed_test_data.py  # or equivalent
   git commit -m "test: seed data for Phase X testing"
   git push
   ```

2. **Keep the `.venv-test` and `run-test-env.sh`** in the repo for future regression testing (other phases may regression-test against old phases' UIs).

3. **Clean up temporary files** (e.g., test database snapshots) that were used just for this phase.

## Pitfalls

**Writing in jargon:** "Instantiate the component" → wrong. "Click the sign-up button" → right. If a developer wrote it, re-read it out loud to a non-dev; if they're lost, simplify.

**Over-testing:** Don't ask the human to test every pixel. Focus on the user's actual workflow: "create account → log in → see dashboard." Skip internal implementation details.

**Missing screenshots:** For visual things (layout, colors, spacing), a screenshot is worth 100 words. Include them, especially for "what you should see."

**Assuming the test environment works:** Always test it yourself before handing it to the human. Nothing worse than "run-test-env.sh" failing on their machine because you didn't notice a missing dependency.

**Forgetting seeded data:** An empty database is useless for testing a UI. Seed it with realistic sample data so the human can immediately see what they're testing.

**Blocking on feedback.** If the human is busy and doesn't respond within the patience window, the Watchdog pauses that stream and keeps the rest of the project moving. Don't stall the whole build waiting for feedback—other tasks in parallel continue.

**Not logging the result.** After the human's feedback, write it to the issue and/or STATE.md so there's a record: "Phase X: human tested + PASS on 2026-05-27."

## Verification

- **Test guide is plain-language:** No jargon, numbered steps, clear expected results.
- **Test environment boots:** `./run-test-env.sh` or equivalent runs without errors and shows a working app.
- **Sample data is visible:** The human opens the app and sees realistic sample data, not an empty shell.
- **Human receives the guide:** Posted to Telegram with the guide, commands, and feedback buttons.
- **Feedback is recorded:** Human's PASS or FAIL and any notes are logged in the issue and `STATE.md`.
- **Phase is marked done:** If PASS, the issue/card moves to Done and `main` is updated (or will be at the next integration point).

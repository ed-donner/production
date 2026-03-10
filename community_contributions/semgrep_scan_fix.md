# Change in `semgrep_scan` Tool – Running Semgrep Without Docker

**Author:** Akash Persetti

**Lecture:** 65

**GitHub Repo:** https://github.com/akashpersetti/cyber

---

## Overview

While working on running **Semgrep locally (without Docker)** using the `semgrep_scan` MCP tool, I encountered an issue where the scan failed even though the input code was valid.

After the analysis completed, the UI showed:

> *"The semgrep scan could not be executed due to a technical error with file path formatting."*

From the OpenAI tool traces, the actual error was:

```
Error executing tool semgrep_scan: Invalid local code files format: 'path'
```

This caused Semgrep to silently fail and forced a manual security analysis instead of an automated scan.

---

## Root Cause

The root cause was a **recent change in the input schema** for the `semgrep_scan` tool.

Previously, file paths could be passed in a looser format. The updated schema now requires:

- A `code_files` array
- Each entry must be an object
- Each object must contain a `path` key
- The `path` must be an **absolute path to a real file on disk**

### Updated Tool Input Schema (Relevant Section)

```json
{
  "code_files": [
    {
      "path": "/absolute/path/to/file.py"
    }
  ]
}
```

If this format is not followed exactly, the tool throws a schema validation error and does not execute.

---

## The Fix

Updating the tool invocation to match the new schema resolves the issue.

### Correct Tool Call Format

```json
{
  "config": "auto",
  "code_files": [
    {
      "path": "<ABSOLUTE_FILE_PATH>"
    }
  ]
}
```

In addition, the agent prompt must explicitly reference this absolute path so it can be passed correctly when calling `semgrep_scan`.

### Prompt Update Example

```python
def get_analysis_prompt(code: str, code_file_path: str) -> str:
    """Generate the analysis prompt for the security agent.
    code_file_path must be the absolute path to a real file on disk containing the code.
    """
    return f"""
The code to analyze is in a file at this exact path (use this path when calling semgrep_scan):
PATH: {code_file_path}

Please analyze the code in that file for security vulnerabilities.
The code is also shown below for reference:

{code}
"""
```

This ensures:

- The file exists on disk
- The agent passes the correct path
- Semgrep runs successfully without Docker

### Change in `server.py` – Writing Code to a Temp File

Because `semgrep_scan` requires a **real file on disk**, the `run_security_analysis` function in `server.py` was updated to write the code to a temporary file before invoking the agent. The absolute path to that temp file is then passed into the prompt and used directly by the tool.

```python
async def run_security_analysis(code: str) -> SecurityReport:
    """Execute the security analysis workflow.
    Writes code to a temp file so semgrep_scan can read it (it requires real file paths).
    """
    fd = None
    path = None
    try:
        fd, path = tempfile.mkstemp(suffix=".py", prefix="analysis_")
        os.write(fd, code.encode("utf-8"))
        os.close(fd)
        fd = None

        with trace("Security Researcher"):
            async with create_semgrep_server() as semgrep:
                agent = create_security_agent(semgrep)
                result = await Runner.run(agent, input=get_analysis_prompt(code, path))
                return result.final_output_as(SecurityReport)
    finally:
        if fd is not None:
            try:
                os.close(fd)
            except OSError:
                pass
        if path is not None:
            try:
                os.unlink(path)
            except OSError:
                pass
```

Key points about this change:

- `tempfile.mkstemp` creates a real file with a unique absolute path, satisfying the schema requirement
- The file descriptor is closed before the agent runs, so Semgrep can read it without contention
- The `finally` block ensures the temp file is always cleaned up, even if the scan fails

---

## Outcome

After applying this fix, `semgrep_scan` executed successfully and returned proper findings. The instructor confirmed this was due to an upstream change in the MCP server and encouraged submitting a PR so the fix benefits all students.

---

*Thanks for reading, and feel free to explore the full implementation in the [linked repository](https://github.com/akashpersetti/cyber).*
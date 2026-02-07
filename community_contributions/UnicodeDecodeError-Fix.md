# Fixing Windows UnicodeDecodeError in AlexAI Project

**By Harsh Patel** | [My AlexAI Repo](https://github.com/CodeBy-HP/AlexAI-Financial-Advisor-SaaS)

---

## Table of Contents

- [The Error](#the-error)
- [Why It Happens](#why-it-happens)
- [Important Note](#important-note)
- [Quick Fix (Temporary)](#quick-fix-temporary)
- [Permanent Fix (Code Change)](#permanent-fix-code-change)
- [Affected Files](#affected-files)
- [Code Examples](#code-examples)
- [Summary](#summary)

---

## The Error

On Windows, you may see this error when running deployment scripts:

```
UnicodeDecodeError: 'charmap' codec can't decode byte 0x81 in position 9867: character maps to <undefined>
```

---

## Why It Happens

Windows Python uses **cp1252** encoding by default. Docker, npm, Terraform, and AWS CLI output UTF-8 characters that cp1252 can't decode.

The scripts use `subprocess.run(..., text=True)`, which tries to decode output using Windows' default encoding and fails.

---

## Files where this error may occur

**Lambda Packaging Scripts** (most common):
- `backend/api/package_docker.py`
- `backend/charter/package_docker.py`
- `backend/planner/package_docker.py`
- `backend/reporter/package_docker.py`
- `backend/retirement/package_docker.py`
- `backend/tagger/package_docker.py`
- `backend/package_docker.py`

**Deployment Scripts:**
- `scripts/deploy.py`
- `scripts/destroy.py`
- `scripts/run_local.py`

**Backend Scripts:**
- `backend/deploy_all_lambdas.py`
- `backend/researcher/deploy.py`
- `backend/database/reset_db.py`

---

## Important Note

⚠️ **This is NOT a major error.**

- Your builds/deployments usually **still succeed**
- The error only affects how Python reads terminal output
- Apply the fix only if the script crashes or you want clean output

👉 **Try the Quick Fix first**

---

## Quick Fix (Temporary)

Set UTF-8 encoding before running the script:

**Windows CMD:**
```cmd
set PYTHONIOENCODING=utf-8
```

**Git Bash / WSL:**
```bash
export PYTHONIOENCODING=utf-8
```

Then re-run your script. This works for the current terminal session.

---

## Permanent Fix (Code Change)

Add `encoding='utf-8', errors='ignore'` to `subprocess.run()` calls:

**Before:**
```python
result = subprocess.run(cmd, capture_output=True, text=True)
```

**After:**
```python
result = subprocess.run(cmd, capture_output=True, text=True,
                       encoding='utf-8', errors='ignore')
```

**What this does:**
- Forces UTF-8 decoding (works on Windows, Mac, Linux)
- Ignores undecodable bytes without crashing
- Preserves actual command output and error checking

---

## Code Examples

### package_docker.py files

```python
# Change this:
result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)

# To this:
result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True,
                       encoding='utf-8', errors='ignore')
```

### deploy.py / destroy.py

```python
# In the capture_output block, change:
result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, 
                       shell=isinstance(cmd, str), env=env)

# To:
result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, 
                       shell=isinstance(cmd, str), env=env,
                       encoding='utf-8', errors='ignore')
```

### deploy_all_lambdas.py

```python
# Change:
result = subprocess.run(['terraform', 'taint', f'aws_lambda_function.{func}'],
                       cwd=terraform_dir, capture_output=True, text=True)

# To:
result = subprocess.run(['terraform', 'taint', f'aws_lambda_function.{func}'],
                       cwd=terraform_dir, capture_output=True, text=True,
                       encoding='utf-8', errors='ignore')
```

---

## Summary

- **Problem**: Windows uses cp1252 encoding; scripts fail decoding UTF-8 output
- **Quick Fix**: Set `PYTHONIOENCODING=utf-8` before running scripts
- **Permanent Fix**: Add `encoding='utf-8', errors='ignore'` to subprocess calls
- **Safe**: Works on all platforms, doesn't hide real errors
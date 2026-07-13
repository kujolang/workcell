# Context

- Objective: continue the review backlog with the next concrete receipt provenance failure.
- Finding: `new_receipt` accepted an existing but unreadable definition path, then called `sha256_file` without exception handling and crashed the Kujo VM.
- Scope: make definition hashing fail closed with a structured receipt error and add a regression.
- External boundary: hosted CI remains unavailable because GitHub Actions billing/spending-limit eligibility has not been restored.

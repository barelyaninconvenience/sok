---
description: Generate a tailored cover letter for a specific job from the shortlist
---

# /generate-cover-letter

Produce a tailored cover letter for a shortlisted job, using the user's resume + optional voice sample.

## What happens

1. You specify a `job-id` from the scored_jobs table.
2. I load the job description, your resume (`data/test_resume.md` or specified path), and optional voice sample.
3. I produce a 400-word cover letter tailored to the posting, in your voice.
4. The letter avoids AI-writing clichés: no "I am writing to express my interest," no "In today's fast-paced world," no "I am passionate about."
5. Output is saved to `data/cover_letters/{timestamp}_{company}_{job-id}.md` and the application tracker is updated.

## Usage

```
/generate-cover-letter --job-id <16-char-id> [--resume path/to/resume.md] [--voice path/to/voice_sample.md]
```

## Conventions

- Letters are under 400 words.
- Open with a specific reference to something in the posting (NOT a greeting).
- Three middle paragraphs: match, specific experience, value you'd bring to THIS company.
- Close without clichés.
- No em-dashes at the start of sentences.

## Application tracking

Generating a cover letter marks the job as `not_applied` in the applications table (the letter exists, but you haven't yet sent it). After you actually apply, update with `/set-status --job-id X --status applied`.

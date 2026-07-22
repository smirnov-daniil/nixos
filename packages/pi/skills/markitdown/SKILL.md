---
name: markitdown
description: Convert files (PDF, DOCX, PPTX, XLSX, HTML, CSV, JSON, XML, images, audio, etc.) to Markdown using Microsoft's markitdown. Use when user says "convert to markdown", "markitdown", "read this pdf", "extract text", "转markdown", "转换文件", or wants to convert any document to readable Markdown text.
argument-hint: <file-path-or-url> [options]
allowed-tools: bash read write
---
# MarkItDown - File to Markdown Converter

Convert the file or URL specified by the user to Markdown.

## Prerequisites

`markitdown` CLI required. Not found? Install:

```bash
# Preferred (fastest, no conflicts)
uv tool install 'markitdown[all]'

# Alternatives
pipx install 'markitdown[all]'
pip install --user 'markitdown[all]'
```

## Supported Formats

| Format | Extensions | Notes |
|--------|-----------|-------|
| PDF | `.pdf` | Text extraction, layout preserved |
| Word | `.docx` | Headings, tables, lists preserved |
| PowerPoint | `.pptx` | Slide-by-slide, headers |
| Excel | `.xlsx`, `.xls` | Sheet-by-sheet tables |
| HTML | `.html`, `.htm` | Full structure conversion |
| CSV | `.csv` | Converted to Markdown tables |
| JSON | `.json` | Formatted output |
| XML | `.xml` | Formatted output |
| Images | `.jpg`, `.png`, `.gif`, `.webp` | EXIF metadata extraction |
| Audio | `.mp3`, `.wav` | Transcription (needs ffmpeg) |
| Email | `.msg` | Outlook message extraction |
| eBook | `.epub` | Full text extraction |
| Archives | `.zip` | Lists contents, converts supported files inside |
| URLs | `http://...` | Fetches, converts web pages |

## Workflow

### Step 1: Parse Arguments

Parse `$ARGUMENTS` for:

- **Target**: file path, glob pattern, directory, or URL
- **Output option**: `-o output.md` to save, else stdout
- **Batch mode**: target is directory or glob pattern

No arguments? Ask user what file to convert.

### Step 2: Validate Target

```bash
# Check if file exists
ls -la "$TARGET"

# Check markitdown is available
markitdown --version
```

markitdown missing? Install:
```bash
uv tool install 'markitdown[all]'
```

### Step 3: Convert

**Single file:**
```bash
markitdown "$FILE_PATH"
```

**Save to file:**
```bash
markitdown "$FILE_PATH" -o "$OUTPUT_PATH"
```

**From URL:**
```bash
markitdown "$URL"
```

**Batch convert (directory):**
```bash
for f in "$DIR"/*.{pdf,docx,pptx,xlsx,html,csv}; do
    [ -f "$f" ] && markitdown "$f" -o "${f%.*}.md"
done
```

**From stdin with extension hint:**
```bash
cat "$FILE" | markitdown -x .html
```

### Step 4: Present Results

- Short output (< 200 lines): display direct in conversation
- Long output: save to `.md` file, report path
- Batch conversions: report summary of converted files

### Step 5: Post-Processing (Optional)

If user asks:

1. **Summarize**: read converted markdown, give summary
2. **Extract specific info**: parse markdown for tables, headings, key data
3. **Clean up**: remove artifacts, fix formatting issues
4. **Translate**: markdown now clean text, translatable
5. **Split**: break large docs into sections

## Examples

```
/markitdown report.pdf
/markitdown slides.pptx -o slides.md
/markitdown data.xlsx
/markitdown https://example.com/page.html
/markitdown ./documents/              # batch convert all supported files
/markitdown *.pdf                     # convert all PDFs in current directory
```

## Error Handling

| Error | Fix |
|-------|-----|
| `markitdown: command not found` | Run: `uv tool install 'markitdown[all]'` |
| `No such file or directory` | Check file path with `ls` |
| Audio transcription fails | Install ffmpeg: `brew install ffmpeg` (macOS) or `apt install ffmpeg` (Linux) |
| PDF extraction empty | PDF may be image-only; suggest OCR tools |
| Encoding issues | Try: `markitdown -c UTF-8 "$FILE"` |
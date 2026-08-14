# PDF Reader and Editor Evaluation

Status: deferred. PDF Expert is the installed baseline; this plan does not imply
that it should be replaced.

## Goal

Select the smallest macOS PDF toolset that reliably covers:

1. everyday reading, forms, signing, page organization, and light editing;
1. scientific-paper reading and review with portable annotations; and
1. live preview while authoring the LaTeX thesis.

The desired outcome is one primary general-purpose application. Add a specialist
reader or LaTeX previewer only when it provides a material capability the primary
application cannot provide. Avoid paying for, configuring, and maintaining two
interchangeable general editors.

## Scope boundaries

- Reference management and citation generation belong to Zotero or the eventual
  knowledge-management workflow, not to this decision.
- Obsidian PDF++ is a candidate for durable Markdown commentary linked to PDF
  passages, not a replacement for a conventional editor used to return reviewed
  PDFs to other people.
- A drawn signature and a certificate-backed digital signature are different
  requirements. Test certificate workflows only if a real legal or institutional
  requirement exists.
- AI summaries are optional. They never compensate for weak core PDF handling,
  and confidential documents must remain usable with AI and cloud features off.
- Evaluate current releases, prices, licences, and privacy terms when this plan is
  executed; the values found during the initial August 2026 survey will go stale.

## Decision rule

**Keep PDF Expert unless a challenger proves a concrete advantage in the actual
workflow.** Familiarity and an already-paid licence count, but they do not excuse
failed portability, redaction, fidelity, or privacy gates.

A candidate is eligible only if it passes every applicable gate:

- opens and renders every test document without corruption or missing content;
- preserves ordinary PDF highlights and comments across applications;
- saves repeatedly without losing bookmarks, links, forms, or annotations;
- performs true redaction rather than drawing an opaque rectangle;
- supports the confidential-document workflow without mandatory upload;
- has understandable licensing, update, and device terms; and
- remains responsive on the thesis and other long technical documents.

After the gates, score fit from 1 (poor) to 5 (excellent). Use the weights to
break real trade-offs, not to manufacture precision.

| Criterion                             | Weight | What to observe                                                |
| ------------------------------------- | -----: | -------------------------------------------------------------- |
| Rendering fidelity and save integrity |     15 | Fonts, math, transparency, links, repeated saves               |
| Annotation portability                |     15 | Highlights, text notes, replies, author names, export          |
| Reading and navigation                |     12 | Search, outline, history, split view, references, keyboard use |
| Editing, pages, forms, and signing    |     12 | Actual recurring tasks, not feature-list breadth               |
| Performance and stability             |     10 | Cold open, large-file scrolling, memory, crashes               |
| OCR and redaction                     |     10 | Accuracy, searchable output, irreversible removal              |
| Privacy and offline behavior          |     10 | Local operation, cloud/AI controls, account requirement        |
| macOS ergonomics and interoperability |      8 | Native behavior, services, automation, file watching           |
| Cost and licence durability           |      8 | Total cost, renewal, devices, update entitlement               |

## Candidate set

### Baselines

- **Apple Preview** — zero-cost baseline for reading, standard annotations,
  signatures, forms, and simple page operations.
- **PDF Expert** — current polished Mac baseline and the default candidate to
  retain.

### General editor challengers

- **PDFgear** — first free challenger; verify business model, privacy boundaries,
  save fidelity, OCR, redaction, and long-term viability rather than trusting the
  feature list.
- **Foxit PDF Editor** — strongest non-Adobe professional challenger when advanced
  editing, forms, comparison, preflight, or accessibility work matters.
- **Adobe Acrobat Pro** — compatibility reference for regulated, accessibility,
  certificate-signature, prepress, and enterprise workflows; its cost and weight
  require an actual need.
- **UPDF** — lower-cost cross-platform candidate; separate the editor licence from
  recurring AI services and verify feature parity on macOS.
- **PDF Studio** — perpetual/offline-oriented candidate if ownership and advanced
  tools matter more than a native Mac interface.
- **Nitro PDF Pro** — evaluate only if employer interoperability or Nitro Sign is a
  requirement; confirm current Mac feature parity before spending trial time.

### Specialist candidates

- **Skim** — LaTeX authoring previewer. Evaluate automatic reload plus forward and
  inverse SyncTeX with Zed; do not judge it as a full editor.
- **Sioyek** — dense technical-reading candidate. Evaluate Smart Jump, portals,
  marks, keyboard navigation, search, and annotation export/interoperability.
- **Highlights** — research annotation and extraction candidate when quotations,
  tables, images, or citations need to become notes.
- **Zotero reader** — candidate when a paper belongs in the bibliographic library
  and extracted annotations should remain attached to that library. Explicitly
  test the export-with-embedded-annotations step before external review.
- **Obsidian PDF++** — candidate for private, durable Markdown commentary and
  backlinks. Keep the source PDF unchanged by default; treat direct annotation
  embedding as experimental until tested on copies.

## Test corpus

Use disposable copies in one dated evaluation directory. Never test mutation,
redaction, OCR, or annotation round-trips on the sole copy of a real document.

1. `phd-thesis/main.pdf` or a copy of the current full build: large, linked,
   font-heavy, and representative of daily authoring.
1. A dense born-digital research paper with equations, figures, internal links,
   references, and two-column text.
1. A reviewer-marked PDF containing highlights, sticky notes, replies, drawings,
   and author metadata from another application.
1. A scanned multi-page document with skew, mixed fonts, and at least one table.
1. A troublesome real form with text fields, checkboxes, a date, and a signature.
1. A synthetic editing document containing known text, images, links, metadata,
   and unique redaction tokens.
1. A non-sensitive stand-in for confidential material, used with networking and
   cloud features disabled where possible.

Record expected page count, file size, checksums, and the unique redaction tokens
before testing. Restore a fresh copy before each application's destructive tests.

## Evaluation protocol

### Preparation

- Refresh candidate availability, macOS support, version, price, renewal terms,
  refund policy, device allowance, update entitlement, and privacy policy from
  primary sources.
- Record whether an account, cloud upload, or internet connection is required for
  each tested operation.
- Install trials declaratively where practical, but do not put trial applications
  in the Dock or make them system defaults.
- Disable AI and cloud synchronization first; enable them only for a separately
  recorded optional test.
- Create one scorecard with a row for every test below and fields for duration,
  failure, workaround, output path, and observation.

### Core workflow tests

Run the same sequence in every general editor:

1. Cold-open the thesis, jump via outline and search, follow an internal link,
   return to the prior location, zoom, and scroll rapidly through image-heavy
   pages.
1. Highlight text, underline text, attach a comment to a highlight, add a sticky
   note, draw a mark, and set the annotation author. Save, quit, reopen, and edit
   each annotation.
1. Open that result in Preview and one competing editor. Confirm every annotation
   is visible, positioned correctly, searchable where expected, and still
   editable. Export a flattened copy separately; flattening must never be the only
   interoperability path.
1. Reorder, rotate, insert, extract, and delete pages on a fresh copy. Confirm
   links, bookmarks, page labels, and existing annotations still point to the
   correct content.
1. Correct a full paragraph and replace an image. Confirm font substitution,
   wrapping, and surrounding layout rather than checking only that editing is
   technically possible.
1. Fill and save the form, reopen it in Preview, and verify field values and the
   signature. Distinguish a reusable drawn signature from certificate signing.
1. OCR the scan, search for known phrases, select text across columns, and export
   searchable PDF and plain text. Record recognition errors, page rotation, and
   whether OCR altered the visible scan.
1. Redact every unique token in the synthetic document. Verify visually, by copy
   and paste, full-text search, text extraction, metadata inspection, and reopening
   in a second application. A covered but recoverable token is an automatic fail.
1. Convert representative pages to Word or images only if conversion is a real
   recurring requirement; inspect layout rather than accepting a successful exit.
1. Repeat save/reopen cycles five times and compare page count and file size for
   unexplained growth or data loss.

### Scientific-reading tests

- Navigate from an in-text figure, equation, and citation reference to the target
  and back without losing the reading position.
- Keep two distant passages visible or cheaply reachable while writing a comment.
- Search across the document, highlights, and comments.
- Create bookmarks or marks for an argument trail, close the application, and
  resume from that state.
- Return a conventionally annotated PDF to Preview/PDF Expert and confirm another
  reader can inspect the comments without the specialist application.
- For note-centric tools, move or rename the PDF and verify whether links and notes
  survive. Export all durable notes to non-proprietary files and inspect them.

### LaTeX authoring tests

Use the thesis's supported build entry point, never an editor's raw `latexmk`
command when it bypasses `./scripts/thesis-build` and its compile lock.

- Keep the output open through five successful rebuilds and one failed rebuild.
- Confirm reload does not steal focus or reset page, zoom, or reading position.
- Forward-search from three included chapter files to the correct PDF locations.
- Inverse-search from three PDF locations back to the correct source files and
  lines in Zed.
- Confirm the viewer follows the PDF produced by the active watch process, whose
  output lives under `.agent-build/watch/`, rather than a stale root `main.pdf`.
- Confirm stopping watch mode leaves no process running and that a later full
  `./scripts/thesis-build` still succeeds.

## Trial order and stop rules

Minimize churn:

1. Score the already-installed PDF Expert and Apple Preview baselines.
1. Trial PDFgear as the free general challenger.
1. Trial Skim for the LaTeX-only role and Sioyek for dense paper reading.
1. Trial Foxit and Acrobat only for unmet professional requirements.
1. Trial UPDF or PDF Studio only if price, cross-platform use, or perpetual
   licensing remains a deciding gap.
1. Trial Highlights, Zotero, and PDF++ only against the research-note workflow,
   not against general editing.

Reject a candidate immediately after a reproducible gate failure. Do not spend
more time scoring polish after corruption, non-portable annotations, fake
redaction, or mandatory cloud handling of confidential files. Conversely, stop
adding candidates once the current baseline passes all gates and no remaining
candidate addresses an observed deficiency.

The top two eligible general editors get a seven-day daily-use trial. Specialist
applications get three real sessions in their intended role. Marketing demos do
not count as sessions.

## Decision record

For every candidate, record:

- role: primary editor, specialist reader, LaTeX previewer, or rejected;
- gate results and links to generated test artifacts;
- weighted score and the observations behind every score below 3 or above 4;
- annual and three-year cost under the licence terms current on the test date;
- cloud, AI, telemetry, and account behavior;
- the decisive advantage or failure in one sentence; and
- uninstall/export steps, so rejection does not leave data or background agents.

The final decision must explicitly choose one of these outcomes:

1. keep PDF Expert only;
1. keep PDF Expert plus one justified specialist;
1. replace PDF Expert with one named general editor; or
1. use Preview plus a specialist and accept the documented editing gaps.

"Keep evaluating" is not a final outcome.

## Implementation after selection

- Add selected applications to `modules/darwin/homebrew.nix` using the existing
  signed-vendor-cask convention.
- Put only daily applications in `modules/darwin/defaults.nix`; a build previewer
  does not automatically deserve Dock space.
- Declare the PDF default handler only after testing that doing so does not harm
  the LaTeX preview workflow.
- Remove rejected trials, their login items, caches where appropriate, and any
  temporary file associations.
- Apply with `darwin-switch`, exercise the selected workflows, and commit the
  configuration separately from this decision document.

## Done when

- Every selected application passes all applicable gates on the same corpus.
- Annotation interchange, true redaction, offline behavior, and licence terms are
  evidenced rather than inferred.
- The primary editor decision and any specialist exception have explicit reasons.
- Rejected applications are removed and their data is exported or discarded.
- The declarative macOS configuration reproduces the chosen setup.

## Primary sources to refresh

- [PDF Expert features](https://pdfexpert.com/features) and
  [pricing](https://pdfexpert.com/pricing)
- [Apple Preview User Guide](https://support.apple.com/guide/preview/welcome/mac)
- [PDFgear for Mac](https://www.pdfgear.com/pdfgear-for-mac/) and
  [privacy policy](https://www.pdfgear.com/privacy/)
- [Adobe Acrobat plans](https://www.adobe.com/acrobat/pricing.html)
- [Foxit PDF Editor plans](https://www.foxit.com/pdf-editor/pricing/)
- [UPDF plans](https://updf.com/pricing-individuals/)
- [PDF Studio store](https://www.qoppa.com/pdfstudio/buy/)
- [Nitro plans](https://www.gonitro.com/pricing)
- [Skim](https://skim-app.sourceforge.io/)
- [Sioyek](https://sioyek.info/)
- [Highlights](https://highlightsapp.net/)
- [Zotero PDF reader](https://www.zotero.org/support/pdf_reader)
- [PDF++ repository](https://github.com/RyotaUshio/obsidian-pdf-plus)
- [Zed LaTeX extension](https://zed.dev/extensions/latex) and its
  [macOS preview guidance](https://github.com/rzukic/zed-latex/wiki/Preview-%E2%80%90-MacOS)

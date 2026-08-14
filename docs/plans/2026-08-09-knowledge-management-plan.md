# Knowledge Management

Status: draft. The decision is made; the RemNote export and the vault's
repository location remain open.

## Goal

Replace RemNote with something still navigable in three years, used by hand,
covering research papers now and project, career, and personal thinking later.

## The binding constraint

Asked how much recurring upkeep was realistic in the bad months, the answer was
**nothing scheduled**. That is the spec, not an obstacle, and it decides
everything below.

It does not mean "no structure". It means every structure must pass two tests:

1. **It costs nothing while unused.** No tax on every capture.
1. **Neglect leaves it incomplete, never false.**

Test 2 does the real work. Skipping a structure's upkeep must not turn it into
a wrong claim, because a structure that lies is worse than no structure — you
either act on bad information or stop trusting the vault. That is the failure
being avoided: "I knew I'd just create more chaos over time."

| Structure                     | Free while unused           | Neglect makes it                            | Verdict          |
| ----------------------------- | --------------------------- | ------------------------------------------- | ---------------- |
| Map of content                | Yes                         | Incomplete                                  | **Keep**         |
| Overview or index note        | Yes                         | Incomplete                                  | **Keep**         |
| PARA                          | No, classify every capture  | False: finished work still listed as active | Out              |
| Status properties             | No, set and update per note | False                                       | Out              |
| Tag taxonomy                  | No, recall the vocabulary   | Inconsistent, then false                    | Out              |
| Base view over derived facts  | Yes                         | Nothing, it recomputes                      | **Keep**         |
| Base view over declared state | Yes                         | False, and looks freshly computed           | Out              |
| Dataview                      | Yes                         | Broken on plugin drift; runs arbitrary JS   | Out              |
| Zettelkasten craft            | No, effort on every note    | —                                           | Out, declined    |
| Johnny.Decimal                | No, address at capture      | False as categories shift                   | Out of the vault |

A map passes because it never claimed completeness. It says "links I gathered
about X", which stays true whatever happens next; a six-month-old map is a
smaller map, not a false one. PARA's `Projects` folder does claim to list your
projects, so the same neglect makes it wrong. That asymmetry, not the presence
of upkeep, is what separates them.

## Decision

**One Obsidian vault, no framework.** Notes with descriptive titles, links when
a link is natural, and full-text search for everything else. No prescribed
folder taxonomy, note types, tag schema, dashboards, review cadence, or
lifecycle states.

**Maps are welcome, on demand.** When a topic gets hard to hold in your head,
write a note that links the relevant notes and says what they add up to. Make
one because you want one; never on a schedule, never in advance, never one per
subject. An overlay like this cannot conflict with anything, because it files
nothing: a note can appear in five maps or none and still lives where it lived.
That is why adding maps is not the composite this plan otherwise refuses.

LYT calls the trigger a Mental Squeeze Point, which is a good name for it. Take
the technique and the trigger; leave the surrounding apparatus. Milo's own
advice is to ignore most of the kit until roughly 100 notes.

This is not the absence of a decision. It is Obsidian's own idiom, adopted
whole:

- Obsidian's official onboarding is create a vault, write a note, link notes.
  It prescribes no methodology at all.
- Steph Ango, who runs Obsidian, keeps most personal notes at the vault root,
  avoids folders for organisation, and navigates by Quick Switcher and
  backlinks.
- kazu reports 5,000+ notes in one folder with neither tags nor categories and
  no trouble.
- Saikat Basu tried nested folders and PARA, found filing decisions cost more
  than writing, and dropped to search plus a few properties past 100 notes.

It is also the cheapest option to abandon. Plain Markdown with human titles has
an exit cost near zero. Given that rigorous multi-year comparative evidence for
*any* of these systems turns out to be thin, choosing the option that is
cheapest to leave is the correct move under uncertainty.

## Why not Ideaverse Pro

The condition was "yes, if it holds up." It does not hold up, and this is a fit
finding rather than a price objection.

- The marketing says "ready-to-use" and "done-for-you". The seller's own FAQ
  says to open Pro as a separate vault, explore it, decide what is useful, then
  download **Zero** and transfer your notes into it. Zero is described as
  "perfect for building your own ideaverse from scratch." The supported path is
  therefore a migration and customisation project — a paid version of the
  assembly problem, not an escape from it.
- Nick Milo's own public page tells new users to ignore most of the kit until
  they have roughly 100 notes, says the only structure that works emerges
  slowly through use, and warns explicitly against leaping to an "ultimate"
  system because it will be fragile and may cause burnout. **The author of the
  packaged system prescribes the bare start.**
- The live official copy contradicts itself on both price ($299 on the sales
  page, "$139 today, $250 afterwards" in the FAQ) and entitlement (one year of
  updates plus $29/year renewal, alongside a lifetime-updates line on the same
  page). There are no refunds and no publicly linked licence.
- The free Lite vault ships 30 community plugins, three of which are gone from
  the registry with archived repositories. Plugin dependence is recurring
  maintenance, which the constraint above rules out.
- No defensible multi-year evidence from actual Pro buyers exists. Plenty of
  launch commentary; almost nothing from six months in.

The LYT *method* is coherent. The Pro *product* is a teaching vault plus a
scaffold. Since the method's own author says to start small and let structure
emerge, following that advice costs nothing.

**Do this instead:** download the free Ideaverse Lite into a throwaway separate
vault and look around. It answers the original question — whether it is worth
it sight-unseen — for zero money and zero risk. Look, do not adopt.

## Queries

Bases is a core plugin. Its data lives in ordinary frontmatter and its views
are plain YAML, saved as a `.base` file or embedded in a note. There is no
third-party dependency to rot and nothing to lose but a view definition.
Dataview is a different proposition and stays out: community-maintained, and
DataviewJS executes arbitrary JavaScript with file and network access.

A query beats a hand-written map on staleness outright, because it recomputes
every time it renders. It is never even incomplete.

That forces the two tests one level deeper: **they apply to the data a
structure reads, not only to the structure.** A query is perfectly honest — it
faithfully reports whatever the properties say. When a property is stale, the
query launders stale data into something that looks freshly computed. A map at
least wears its age on its face; a wrong query does not.

So the real axis is not manual versus automatic. It is **derived versus
declared**.

**Derived — free, and correct forever.** Nobody maintains these, so they cannot
rot: filename, folder and path, created and modified time, outgoing links,
backlinks, tags actually present in the text, and full-text content. Query them
freely.

**Declared but immutable — safe.** A paper's `year`, `authors`, `doi`, `venue`.
You type them once and they can never go false, because the underlying fact
never changes. This costs a little at capture, which is a real cost and worth
stating; but it is data you would write into a paper note anyway, and it is
what makes the bibliographic layer genuinely queryable.

**Declared and mutable — out.** `status`, `priority`, `due`. These are the ones
that rot, and a query over them rots invisibly.

### Derive state instead of declaring it

Most workflow questions have a derived answer, which is strictly better than a
field you must remember to update:

| Question                           | Declared version | Derived version                     |
| ---------------------------------- | ---------------- | ----------------------------------- |
| Which papers have I not processed? | `status: unread` | Paper notes with no outgoing links  |
| What have I neglected?             | `reviewed:` date | Modified time older than six months |
| What never got connected?          | `orphan: true`   | No backlinks                        |

The absence of links *is* the processing state. No schema required.

### Why the wiki analogy holds, and where it stops

A Cargo-backed wiki is the right comparison for the bibliographic layer:
objective, schematised, repetitive data where manual tables genuinely cannot
keep up. The paper corpus has exactly that shape.

It stops at provenance. Game data is machine-extracted and re-derivable — if a
table is wrong, re-run the extraction and the wiki is correct again. A
hand-typed `status: reading` has no source of truth and no re-derivation path.
Same query engine, completely different guarantees about the data underneath.

### Queries do not replace maps

They answer different questions. A query answers "which files match?" A map
answers "what do these add up to?" — which is prose judgement, and no query can
produce it. Use a query for retrieval and a map for meaning. Restoring queries
does not retire maps.

Note also that queries strengthen the case against a tag taxonomy rather than
weakening it: `#symbolic-execution` and `#symbolicexecution` produce a query
that silently returns half the answer.

## Scope boundary

One Obsidian vault for **thinking**: research notes, project and modding
knowledge, career material, and personal planning.

Administrative **records** go in the vault too — tax documents, warranties,
statements, scans — with the two carve-outs below.

An earlier version of this plan sent them elsewhere on the grounds that they
add search noise, produce dead graph nodes, and are never linked. All three
were wrong. Core search does not index PDF bodies at all, so a scanned invoice
cannot add search noise; it is found by filename, which is the point. Graph
view filters attachments out with a toggle, and is an exploratory view here
rather than a navigation surface. And records do get linked: a NAS invoice
belongs next to the note evaluating NAS platforms.

The deeper error was recommending a destination that does not exist. "The
structured-document home the backup plan will define" is a draft with the
storage platform still undecided, so in practice that advice meant "leave them
wherever they are", which is worse than any deliberate location. **The place
that gets backed up, versioned, and habitually opened beats the place that is
architecturally tidy and empty.**

Retention is also better served here than in a folder. A record can carry
`retain_until: 2033-12-31` in frontmatter — an immutable declared fact by the
test above, since the legal period does not change — and a base view can then
list everything past its date. A folder of PDFs cannot answer that question at
all.

### When a separate store is justified at all

One store by default. A second store needs a requirement the first cannot meet:

1. **A different audience** — someone else must find it without you.
1. **A different exposure surface** — it must not go where the vault goes.
1. **Tooling that genuinely cannot be replicated** — test this case by case
   rather than assuming it.

"It is a different kind of information" is not a requirement. Bibliographic
metadata, paper notes, project thinking, and household records are different
kinds of thing that all meet the same requirement, so they share one store.
Splitting on category alone is taxonomy for its own sake, and it produced both
the Zotero duplication and the vapourware document home above.

### The two carve-outs

**If the vault is pushed to a remote, sensitive records do not go in it.**
Financial statements, identity scans, and medical documents in a repository
pushed anywhere — including a private one — are on someone else's disk, and git
history means a mistaken commit is not really removable. This makes the open
question of where the vault repository lives load-bearing rather than
administrative. A local-only repository with Time Machine and the eventual NAS
behind it has no such problem.

**Anything another person must find without you belongs somewhere else.**
Household insurance, the estate and emergency material, account inventories,
recovery instructions. A spouse or executor should not have to navigate your
vault, your filenames, and your machine under duress. That is the family backup
plan's job and it is a genuine requirement from it, not a tidiness argument.
The dividing line is private versus shared, which is the axis that plan already
uses — not notes versus records.

This is a seam between a notes vault and a filing location, not a blend of two
methodologies. It is a functional judgement rather than something the system
authors mandate, and it is reversible.

Johnny.Decimal is ruled out above for the vault, but it is a filing
architecture for exactly this kind of material and is worth considering when
the backup plan defines that document home. Fixed addresses are a poor fit for
notes that should stay fluid and a good fit for records that never move.

Tasks and deadlines also stay out. TickTick is already installed and already
does that job; the vault does not need a status schema.

## The vault

Conventions, in full:

1. Give a note a title you would actually search for.
1. Link when a link is natural. Do not link to hit a quota.
1. Put PDFs and images in one attachments folder.
1. Everything else: write the note.

That is the whole system. There is nothing to maintain because there is nothing
that decays.

## Papers

PDF++ stays, on backlink highlighting, with the existing page anchors
preserved.

One thing genuinely forces a convention here. **Obsidian's core search reads
notes and canvases only — it does not search PDF bodies.** So a paper whose
content exists solely inside the PDF is invisible to search. The note is what
makes it findable, which means each paper worth keeping needs a note carrying,
in text: the title, what it claims, and why it mattered. Highlights and their
anchors sit below that.

This is a product boundary, not a methodology. It is the one place where "just
write notes" needs a specific shape.

Give that note frontmatter for the immutable bibliographic facts — title,
authors, year, venue, DOI, and the PDF path. They never change, so they never
go false, and they are what turns the paper corpus into something a base view
can query by author, year, or venue. Nothing about your reading or your opinion
belongs in a property.

**Drop Zotero. The frontmatter is the bibliographic database.**

An earlier version kept Zotero as "the catalogue and the future citation
authority" while also specifying `title`, `authors`, `year`, and `doi` in note
frontmatter. That is two stores holding the same fields with nothing keeping
them in step — the worst of both, and the first thing that would drift.

What Zotero actually supplied, and what replaces it:

| Zotero provided         | Replacement                                                                                             |
| ----------------------- | ------------------------------------------------------------------------------------------------------- |
| Metadata capture        | A DOI resolves to CSL-JSON or BibTeX by content negotiation; a short script turns that into frontmatter |
| Bibliography generation | Emit BibTeX from frontmatter when something needs it; Pandoc consumes it                                |
| Citekeys                | The DOI already is one; derive a readable key if a manuscript ever needs it                             |
| PDF storage             | The vault already holds the annotated copy                                                              |

A fetch-and-format script is not the bespoke-system risk this plan otherwise
avoids. That warning is about blending conceptual frameworks, not about writing
twenty lines to call an API.

Before the MacBook Air goes back, export the existing library once to CSL-JSON
or BibTeX. Copying the Zotero folder is not the same thing: that preserves
`zotero.sqlite`, which needs Zotero to read. An export is portable text and
costs nothing to keep.

Annotate exactly one copy of any paper.

## Growth, driven by pressure only

Add a structure when a specific pain appears, and add the smallest thing that
removes it. Never in advance.

| Pain                                              | Smallest fix                                                                |
| ------------------------------------------------- | --------------------------------------------------------------------------- |
| Cannot recall a note's name                       | Better titles, and an alias on the old note                                 |
| "What do I think about X overall?"                | A map for X: links plus what they add up to                                 |
| Papers and thoughts blur in results               | Two folders: sources, everything else                                       |
| Re-running the same search by hand                | Save it as a base view over derived facts                                   |
| A folder became a junk drawer                     | Move the dead part to an archive folder                                     |
| Need a passage you never highlighted              | Omnisearch and Text Extractor, accepting two plugins                        |
| Source formatting drifts, likely from agent edits | Obsidian Linter, on demand rather than on save, after round-tripping a copy |

Each is additive, local, and survives being ignored. None requires a scheduled
pass. If a structure ever needs tending to stay truthful, that is the signal it
was the wrong fix.

## Deliberately not doing

Failing test 1, test 2, or both: no PARA, no Zettelkasten discipline, no
Johnny.Decimal inside the vault, no Dataview, no tag taxonomy, no mutable
status properties, no weekly review, and no community plugins besides PDF++.
No spaced repetition either, on the separate ground that it is not wanted.

Passing both tests but not prescribed, so use them if they help and ignore them
otherwise: bolding a passage on re-reading when something stands out, which is
all progressive summarization amounts to in practice; daily notes; a template
for paper notes. None of these decays into a false claim, so none needs a
ruling — they are permission, not process.

A Home note is fine as a set of entry links. It is not fine as a list of
current projects, which is a status claim and goes stale into falsehood.

Agents read this vault well because it is Markdown in git. That is a
consequence, never a reason.

## Tooling

- **Obsidian** via Homebrew cask, matching the existing convention for
  applications whose vendor updater should set the cadence — the same argument
  already recorded for Zed and the browsers. The nixpkgs package supports
  `aarch64-darwin` but is unfree, and this configuration sets no `allowUnfree`
  policy.

- **Do not manage `.obsidian` with Home Manager.** It links generated files out
  of the immutable store while Obsidian rewrites its own settings, which is the
  failure already documented for Karabiner.

- **Git** for undo, committed by a launchd agent, not by hand. Git only has
  history if someone commits, so "use git" as written was a recurring chore
  hiding inside a plan that forbids them. A declared launchd agent fixes it in
  the idiom already used here, keeps working when Obsidian is closed, and
  captures edits made by anything else. The Obsidian Git plugin does the same
  job but only while the app is running. Ignore `workspace.json` and
  `workspaces.json`.

  The agent runs on a fifteen-minute timer and applies two guards, so it
  neither commits mid-sentence nor fights a deliberate commit:

  ```sh
  # Skip while the vault is still being edited: commit moments you stopped,
  # not moments you paused. Anything touched in the last five minutes defers.
  [ -n "$(find "$VAULT" -newermt '-5 minutes' -not -path '*/.git/*' -print -quit)" ] && exit 0
  git -C "$VAULT" add -A
  git -C "$VAULT" diff --cached --quiet || git -C "$VAULT" commit -qm "snapshot $(date -Iseconds)"
  ```

  The idle guard answers the half-written-commit objection; the `--quiet` check
  means a tree you already committed by hand is a no-op. Commit deliberately
  whenever you want a real message — the agent simply finds nothing to do.

- Desktop only. No sync layer. Never run git alongside Obsidian Sync or iCloud
  against the same vault.

### Never run a generic Markdown formatter over the vault

Tested, not assumed. This repository's own `mdformat` with the GFM plugin, run
over a file of ordinary Obsidian syntax, destroyed the YAML frontmatter into a
horizontal rule plus a heading, escaped every `[[wikilink]]` and `![[embed]]`,
escaped the PDF++ anchors, and truncated a table row at the `|` inside a
wikilink alias — losing the alias and closing brackets outright.

The cause is structural: Obsidian's dialect is not CommonMark, so a
standards-compliant tool is *correct* to mangle it. The repository's plan
documents survive only because they happen to contain no frontmatter,
wikilinks, or anchors. Putting a wikilink in one would break it.

### The plugin test

There are 6,487 community plugins, so the question is never "which exist" but
"what gets through". One test, on top of the two above:

**If this plugin vanished tomorrow, what would I lose?** A convenience or a
view is acceptable. Data, or the readability of a note, never is.

PDF++ passes, and that is the whole reason it is the one accepted. Its
highlights are ordinary Markdown links; disable it and the quotes, page
numbers, and anchors are still plain text in the note. Only the rendering in
the PDF viewer is lost.

Plugin death is a measurable rate, not a hypothetical: of the 30 community
plugins bundled with Ideaverse Lite, three were already gone from the registry
with archived repositories.

Note honestly that PDF++ itself was last pushed on 2025-08-30, the least active
of the plugins considered here. Its author has said he is working toward v1.0
with minor fixes rather than major releases, so this is a risk flag rather than
evidence of abandonment — and the structural mitigation above is precisely why
the dependency is acceptable anyway.

## Migration from RemNote

The converted vault on the MacBook Air is not a model and not a starting point.

1. Export twice: native or Complete as a rollback archive, Markdown as the
   readable corpus. Copy PDFs and media separately; Complete exports are
   documented as omitting uploaded media.
1. Verify counts and spot-check a sample before trusting either export.
1. Keep RemNote readable until that passes.
1. **Do not bulk import.** Bring a paper into the vault when you next read it
   and write its note then. A bulk import recreates the pile.

## What was rejected, and why

Two earlier versions of this plan were discarded. Recorded so the mistakes are
not repeated.

The first optimised for what an LLM agent could parse, and proposed replacing
PDF++ with a `pdfannots` batch pipeline that offered no link from a quote back
to its page. Wrong priority: this vault is read by a person.

The second built a composite from PARA, Zettelkasten, LYT, evergreen notes,
progressive summarization, and Johnny.Decimal. Those give three mutually
exclusive answers to where a note belongs — actionability, conceptual linkage,
and fixed address — and the plan contained all three with no rule for which
wins. A bespoke assembly with six upstreams is the opposite of idiomatic. It
also took a passing remark about how the old RemNote data was shaped and made
it the architectural spine, then went looking for scholarly support.

## Decisions still open

- Where the vault repository lives, and whether it is private on GitHub.
- Whether the converted vault is kept read-only as a reference or dropped.
- Whether anything on the MacBook Air is needed before it goes back next month.

## References

- [Obsidian: getting started](https://help.obsidian.md/Home)
- [Obsidian: search](https://help.obsidian.md/Plugins/Search) — notes and
  canvases only; PDF bodies are not searched
- [Steph Ango: how I use Obsidian](https://stephango.com/vault)
- [kazu: Obsidian practice guide, no folders needed](https://note.com/worktech2791/n/n07402e651f6e?hl=en)
- [Saikat Basu: my Obsidian vault was a mess until I stopped using folders](https://www.makeuseof.com/obsidian-vault-organization-without-folders/)
- [Nick Milo: is LYT for me?](https://www.linkingyourthinking.com/ideaverse/is-lyt-for-me) —
  ignore the kit until ~100 notes; structure must emerge slowly
- [Ideaverse Pro sales page](https://www.linkingyourthinking.com/ideaverse-pro)
- [Ideaverse onboarding and free Lite download](https://www.linkingyourthinking.com/ideaverse-for-obsidian/onboarding-ideaverse)
- [PDF++ backlink highlighting](https://ryotaushio.github.io/obsidian-pdf-plus/backlink-highlighting-basics.html)

## Done when

Obsidian is installed declaratively, the vault exists under git with PDF++ as
its only plugin, one paper has been read and written up in a note that makes it
findable by search, and Ideaverse Lite has been looked at in a throwaway vault
so the question is closed. Nothing else is set up, because nothing else has
hurt yet.

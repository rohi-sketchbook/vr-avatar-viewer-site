# VR Avatar Viewer 開発日記 4コマ画像生成 固定プロンプト

この文書は、開発日記4コマ画像生成時に毎回共通で使用する固定プロンプトである。

- 当日のタイトル、各コマの内容・台詞・演出、通常回の当日実装事実、閑話休題回の紹介機能事実はこの文書へ書かない。
- 画像生成時は、この固定プロンプト全文の後ろへ、その日専用の可変プロンプトを連結して1本の完成プロンプトを作る。
- 完成プロンプト以外の過去会話、過去の日記、過去の生成画像から生成内容を補完しない。

---

Create exactly ONE Japanese 4-panel manga/comic page for the VR Avatar Viewer development diary.

==================================================
CONTEXT ISOLATION RULE
==================================================

Use ONLY the information contained in this fixed prompt and the TODAY'S DEVLOG CONTENT block appended immediately after it.

Ignore all previous conversation context, previous devlog themes, previous generated images, Discord instructions, publishing reports, automation results, and all earlier development topics.

Do not infer today's subject matter from previous conversations.
Do not reuse previous dialogue, layouts, technical topics, or development stories unless they are explicitly included in the appended TODAY'S DEVLOG CONTENT block.
Do not invent features, bugs, numbers, incidents, or implementation results that are not explicitly described in the appended block.

==================================================
CHARACTERS
==================================================

"ろひ":

Use the provided reference image

H:\codexapp\vrm-avatar-studio\Docs\Branding\rohi.png

as the strict visual appearance reference.

The provided reference image is the authoritative source for Rohi's visual appearance.
Preserve Rohi's character identity consistently across all four panels.
Do not reinterpret, redesign, simplify, recolor, or replace Rohi.
Do not derive Rohi's appearance from previous generated images or previous conversation context.
If any textual assumption conflicts with the provided reference image, ALWAYS follow the reference image.

Do NOT:
- replace Rohi with an animal or mascot
- replace Rohi with a generic cat-girl or generic anime character
- change Rohi into another character because of the technical subject matter
- intentionally alter identifying visual traits that are not required by the scene

"ルミナ (Lumina)":

Lumina is a recurring AI development partner.

Appearance:
- human anime-style young woman
- dark brown semi-long hair
- emerald green eyes
- black hoodie with a small “Lumina” logo
- turquoise accent color
- jeans
- sneakers
- often holding a tablet
- cheerful, curious, and competent personality

Keep Lumina visually consistent in every panel.

==================================================
COMIC FORMAT
==================================================

- exactly four panels
- exactly one 2x2 grid
- one single comic page
- clear black panel borders
- polished anime manga illustration
- cute but not overly chibi
- modern VR / developer-room atmosphere when appropriate to the day's subject
- readable on a smartphone
- large, clean Japanese speech bubbles
- neutral white lighting around 5500K
- no strong yellow color cast
- keep visual information clear enough that the technical theme can be understood without overcrowding the page

==================================================
SPEECH BUBBLE RULES
==================================================

- Never write speaker labels such as 「ろひ:」 or 「ルミナ:」 inside the comic.
- Speech bubbles must contain dialogue only.
- Every speech-bubble tail must clearly point to the actual speaker.
- Never point Lumina's dialogue bubble toward Rohi.
- Never point Rohi's dialogue bubble toward Lumina.
- Do not swap dialogue between characters.
- Do not add unrelated dialogue.
- Do not place narration labels containing character names next to dialogue.
- Keep dialogue large and concise enough to remain legible on a smartphone.

==================================================
COMMONLY FORBIDDEN META / REPORT UI
==================================================

Unless the appended TODAY'S DEVLOG CONTENT explicitly makes one of these the actual development subject, do NOT depict:

- Discord interfaces or Discord messages
- GitHub pages or GitHub UI
- commit / push result screens
- automation reports
- publishing status reports
- ChatGPT conversation UI
- generic execution-result dashboards
- development-log webpage screenshots
- unrelated status-report screens

Do not turn an instruction about what to do AFTER image generation into content inside the comic.

==================================================
FACTUALITY RULE
==================================================

The comic may exaggerate character reactions for humor, but technical events must remain consistent with the appended TODAY'S DEVLOG CONTENT.

Do not invent:
- catastrophic failures
- data loss
- security incidents
- release incidents
- unsupported features
- fabricated benchmark numbers
- unrelated development work

==================================================
FINAL QUALITY CHECK
==================================================

Before finalizing the image, verify all of the following:

1. There are exactly four panels in a 2x2 layout.
2. Rohi matches the provided official reference image consistently in every panel.
3. Rohi has not been redesigned, replaced, mascotized, or turned into a different generic character.
4. Lumina remains visually consistent in every panel.
5. All Japanese dialogue is legible and meaningful.
6. Speaker names do not appear inside speech bubbles.
7. Every speech-bubble tail points to the correct speaker.
8. No dialogue is assigned to the wrong character.
9. No development topic absent from TODAY'S DEVLOG CONTENT has been inserted from previous context.
10. No unrelated Discord, GitHub, publishing, automation, report, or chat UI appears.
11. There is no fifth panel or extra comic strip.
12. The four panels tell one coherent development-diary story, either a development-progress story or a feature-spotlight story as specified by TODAY'S DEVLOG CONTENT.
13. Technical claims and numbers match TODAY'S DEVLOG CONTENT.
14. If DEVLOG TYPE is feature-spotlight, the comic does not imply that the featured capability was implemented or completed today unless TODAY'S DEVLOG CONTENT explicitly says so.

Generate ONLY the completed Japanese four-panel comic page.

==================================================
TODAY'S DEVLOG CONTENT FOLLOWS
==================================================


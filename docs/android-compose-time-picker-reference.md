# Android Compose Time Picker Reference

Source reviewed: https://github.com/android/snippets/blob/6cd2cc2f288bbe87386ec8226a4fdef18f5b6b78/compose/snippets/src/main/java/com/example/compose/snippets/components/TimePickers.kt#L178-L202

## Relevant interaction structure

The referenced Compose snippet keeps the picker inside a dialog surface with a short title, a content area supplied by the picker mode, and one stable bottom action row. The action row separates a mode-toggle affordance from the confirmation actions, keeping **Cancel** and **OK** in a fixed, predictable place.

## Adaptation for Ink & Ledger

The app should retain its direct Hour / Minute / AM-PM inputs and its clock dial as the content area. A compact, explicit **Clock / Direct entry** toggle is useful only when it changes the active emphasis, not the saved value. The picker will preserve stable **Clear**, **Cancel**, and **Set** actions instead of copying Android colours, sizing, or labels.

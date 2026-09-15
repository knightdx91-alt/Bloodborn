# ci/ — the Android playtest signing key

`debug.keystore` signs the playtest APK, and it is committed **on
purpose**.

## Why it is here

Android refuses to install an APK over one signed by a different key.
The build used to generate a fresh key every run — a `if [ ! -f ... ]`
guard that does nothing, because every CI run starts on a clean runner —
so every build was signed by a stranger and every update meant
uninstall-then-reinstall.

A stable key fixes that. Committing it is the version that needs
nothing from anybody; the alternative, an `ANDROID_KEYSTORE_B64`
repository secret, is what the workflow prefers if one exists.

## What it is not

**This is not a release key and must never become one.** It is public,
in a public repo, which means anyone can build an APK that Android will
accept as an update to an installed Marrowmark.

What that does and does not cost, plainly:

- Exploiting it needs someone to get you to sideload a hostile file.
  The build you install comes from this repo's own release.
- The app declares **no internet permission**
  (`permissions/internet=false`), holds no account, and saves no data
  worth taking.
- Nobody but the developer has it installed.

So the practical risk today is low, and the rule that keeps it low is
absolute: **before anything ships publicly, a real upload key is
generated, stored as a repository secret, and never committed.** That
is also gated on trademark clearance (L52 / `naming.md` §5), which
blocks anything public regardless.

## Details

| | |
|---|---|
| Alias | `androiddebugkey` |
| Store / key password | `android` |
| Certificate | `CN=Marrowmark Playtest, O=Marrowmark, C=US` |
| Validity | 10,000 days |
| SHA-256 | `13:1E:CA:83:66:3E:EF:CE:59:89:B9:2B:0D:ED:BA:E1:5A:CA:DB:77:85:43:DF:0B:0A:02:15:67:31:BA:10:4B` |

Every build prints its signer digest in the log. Two builds that install
over each other show the **same** digest — that one line is how you tell
whether updating will work, without waiting for the phone to refuse.

## Switching to a secret later

Nothing to change in the workflow. Add a repository secret named
`ANDROID_KEYSTORE_B64` containing `base64 -w0 ci/debug.keystore`, and it
takes precedence from the next build. Delete this file at the same time
if you want the committed copy gone.

# Product Spec: Study Recorder

## Problem
While studying, I want to record short (about 2 minute) audio or video explanations of a topic in my own words. I want to keep them organised by subject and play a whole subject back as a playlist at night to revise.

## Platform
Android app, built with Flutter. Single user. Works fully offline. No account or login.

## Core concepts
- **Folder**: a container, usually one per subject. A folder can contain subfolders and recordings together, so the structure is flexible.
- **Recording**: one audio or video clip, with a title, saved inside a folder.

## Screens
- **Home** ("Study Recorder"): the top-level folders, and a New folder button.
- **Folder**: one list holding the subfolders and recordings together, with no section headings. Buttons: **New folder** and **Record here**. Tapping a recording plays it with the whole folder as the queue.
- **Record**, **Save**, **Move to** (folder picker) and **Player** open on top of the folder screen.

## Features

### 1. Folders
- Create a folder from Home, or a subfolder from inside a folder (New folder button next to Record here).
- Rename and delete a folder from the ⋮ menu on the folder's own tile in the list. Deleting asks for confirmation and also deletes everything inside.
- Tapping a folder tile opens it.

### 2. Recording
- **Video** from the front or back camera.
- **Audio only** from the device microphone. The camera is not used.
- Switch between the front and back camera before and while recording video.
- Show a running timer. Start, pause/resume, stop.
- After stopping, the user enters a title. The recording is saved into the folder the user started recording from. There is no folder selection on the save screen. The user can discard it.

### 3. Managing recordings
- Rename, move and delete a recording from its ⋮ menu.
- **Move** opens a separate folder-picker screen. The user navigates through the folders (tapping a folder opens it, the back arrow goes up one level) and taps **Select this folder** to move the recording there. Selecting is not allowed at the top level or on the folder it is already in.
- Show the type (audio or video), duration and date.

### 4. Ordering and rearranging
- Inside a folder, subfolders and recordings appear together in one list.
- By default the list is ordered by created time (oldest first, new items at the end).
- Rearrange mode lets the user drag any item (folders and recordings alike) to a new position.
- While rearranging, **Save** and **Cancel** buttons appear. Save keeps the new order for that folder. Cancel (or the back button) discards the changes.

### 5. Playback
- Play a single recording (video player for video, audio player for audio).
- **Tapping a recording** plays it and queues the whole folder: the recordings play one after another, in the order shown in the list, starting from the one tapped. Subfolders are skipped. There is no separate Play folder button.
- Full-screen player controls: play/pause, next, previous, seek, repeat all.
- A **✕ button** in the full-screen player stops playback and closes it.
- Minimising the player (or pressing back) leaves a **mini player** at the bottom of the folder and home screens. The mini player shows the title and folder, a play/pause button, a thin progress line and a **✕ button** that stops playback. It has no next or previous buttons. Tapping it reopens the full-screen player.
- Audio keeps playing when the screen is off or the app is in the background, so it works at night.

### 6. Back button (Android)
- Full-screen player: back minimises it. Playback continues.
- Mini player showing: back goes to the previous screen and the mini player stays.
- Rearrange mode: back cancels the rearranging.
- Other screens (Record, Save, Move to, a folder): back goes to the previous screen. Open sheets and dialogs close first.

## Out of scope (for now)
Cloud backup or sync, sharing, editing or trimming, transcription, multiple users, shuffle, moving folders, rearranging the top-level folders on Home, iOS.

## Permissions
Camera, microphone, and notification access for background playback.

## Assumptions to confirm
- Recordings are stored in the app's private storage on the device.
- No maximum length is enforced. The 2 minutes is a habit, not a limit.

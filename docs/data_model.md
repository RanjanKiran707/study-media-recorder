# Data model

Two entities, from `project_specs/product_spec.md`. Files are stored in the app's private storage, and the database keeps their paths.

```mermaid
erDiagram
    FOLDER ||--o{ FOLDER : "contains subfolders"
    FOLDER ||--o{ RECORDING : "contains"

    FOLDER {
        string id PK
        string parent_id FK "null = top level (Home)"
        string name
        int created_at "epoch ms"
        int sort_index "null = not rearranged"
    }

    RECORDING {
        string id PK
        string folder_id FK "never null; recordings live inside a folder"
        string title
        string type "audio or video"
        string file_path "relative to the app's recordings directory"
        int duration_ms
        int created_at "epoch ms"
        int sort_index "null = not rearranged"
    }
```

## Rules

- **One mixed list per folder.** The items of a folder are its child folders (`FOLDER.parent_id = id`) plus its recordings (`RECORDING.folder_id = id`). The app merges and orders them in code.
- **Order.** Items are ordered by `sort_index` ascending, items with `sort_index = null` last, and ties or nulls by `created_at` ascending. With no rearranging every `sort_index` is null, so the order is oldest first. A new item has a null `sort_index`, so it lands at the end.
- **Saving a rearrangement** writes `sort_index` 0..n-1 for every item currently in that folder (folders and recordings). Cancel writes nothing. `sort_index` is shared across both tables for one parent, so it only compares within a single folder.
- **Top-level folders** (`parent_id = null`) are not rearrangeable, so they are always in created order.
- **Playlist** = the recordings of the folder in the order above. Subfolders are skipped. The playlist and the mini player are in memory only and are not stored.
- **Delete folder** cascades: `FOLDER.parent_id` and `RECORDING.folder_id` use `ON DELETE CASCADE`. The repository also deletes the recording files from disk.
- **Move recording** changes only `RECORDING.folder_id`. The destination must be a folder (not the top level) and different from the current one. Folders cannot be moved.
- **Rename** changes `name` or `title`.
- **Counts and breadcrumb paths** (for example "Physics / Mechanics", "4 recordings · 1 subfolder") are computed, not stored.

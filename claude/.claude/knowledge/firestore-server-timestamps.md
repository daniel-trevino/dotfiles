# Firestore serverTimestamp Pattern

## Rule

1. **Let Firestore set the timestamps.** Do not manually set fields tagged with `serverTimestamp` before writing. Leave them as zero values so Firestore populates them server-side — this is the authoritative value.
2. **If you need to return the object immediately**, use `time.Now()` to approximate those fields in the in-memory struct. Do not re-read the document just to get timestamps.

This gives you the best of both worlds: accurate server-side timestamps in Firestore, and a usable return value without an extra read.

## Pattern

```go
_, err := collection.Doc(id).Create(ctx, entity)
if err != nil {
    return Entity{}, err
}

// Timestamps are set by Firestore via serverTimestamp tag
now := time.Now()
entity.CreatedAt = now
entity.UpdatedAt = now

return entity, nil

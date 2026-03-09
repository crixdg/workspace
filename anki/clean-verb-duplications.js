// Copyright (c) 2026-present, FromCero. All rights reserved.

const ANKI_CONNECT_URL = "http://127.0.0.1:8765";

async function invoke(action, params = {}) {
  const res = await fetch(ANKI_CONNECT_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      action,
      version: 6,
      params,
    }),
  });

  const data = await res.json();
  if (data.error) throw new Error("AnkiConnect error: " + data.error);
  return data.result;
}

async function cleanDuplicateVerbs(deckName) {
  // 1. Find all notes in deck
  const noteIds = await invoke("findNotes", {
    query: `deck:"${deckName}"`,
  });

  console.log("Total notes:", noteIds.length);

  // 2. Get note info
  const notes = await invoke("notesInfo", {
    notes: noteIds,
  });

  const map = new Map();

  for (const note of notes) {
    const verb = note.fields.verb?.value?.trim().toLowerCase();
    if (!verb) continue;

    if (!map.has(verb)) {
      map.set(verb, []);
    }

    map.get(verb).push(note.noteId);
  }

  const deleteIds = [];

  for (const [verb, ids] of map) {
    if (ids.length <= 1) continue;

    // keep newest
    ids.sort((a, b) => b - a);

    const keep = ids[0];
    const remove = ids.slice(1);

    console.log(`Duplicate verb: ${verb}`);
    console.log("Keep:", keep);
    console.log("Delete:", remove);

    deleteIds.push(...remove);
  }

  if (deleteIds.length > 0) {
    await invoke("deleteNotes", {
      notes: deleteIds,
    });
  }

  console.log("Deleted duplicates:", deleteIds.length);
}

cleanDuplicateVerbs("English: Verb Usage").catch((err) => {
  console.error("Error:", err);
});

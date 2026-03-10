// Copyright (c) 2026-present, FromCero. All rights reserved.

document.getElementById("phrase-input").addEventListener("keydown", (e) => {
  if (e.key === "Enter") {
    e.preventDefault();
    addPhrase();
  }
});

//===========================================================================

async function addPhrase() {
  const phrase = document.getElementById("phrase-input").value.trim();
  if (!phrase) return;

  try {
    const entry = { phrase };
    const notes = await findPhrase(entry);
    if (notes.length > 0) {
      setStatus(`Updating phrase: "${phrase}"`);
      await updatePhrase({ ...entry, id: notes[0] });
      setStatus(`Updated phrase: "${phrase}"`);
    } else {
      setStatus(`Creating phrase: "${phrase}"`);
      await createPhrase(entry);
      setStatus(`Created phrase: "${phrase}"`);
    }
  } catch (err) {
    setStatus(err.message);
  }
}

//===========================================================================

async function findPhrase(entry) {
  return await invoke("findNotes", {
    query: `phrase:"${entry.phrase}"`,
  });
}

async function updatePhrase(entry) {
  return invoke("updateNoteFields", {
    note: {
      id: entry.id,
      fields: {
        phrase: entry.phrase,
        version: VERSION,
      },
    },
  });
}

async function createPhrase(entry) {
  return invoke("addNote", {
    note: {
      deckName: "English",
      modelName: "Phrase",
      fields: {
        phrase: entry.phrase,
        version: VERSION,
      },
      options: { allowDuplicate: false },
      tags: ["english", "phrase"],
    },
  });
}

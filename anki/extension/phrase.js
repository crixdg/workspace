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
    const notes = await findPhraseNote(entry);
    if (notes.length > 0) {
      setStatus(`Updating phrase: "${phrase}"`);
      await updatePhraseNote({ ...entry, id: notes[0] });
      setStatus(`Updated phrase: "${phrase}"`);
    } else {
      setStatus(`Creating phrase: "${phrase}"`);
      await createPhraseNote(entry);
      setStatus(`Created phrase: "${phrase}"`);
    }
  } catch (err) {
    setStatus(err.message);
  }
}

//===========================================================================

async function findPhraseNote(entry) {
  return await invoke("findNotes", {
    query: `phrase:"${entry.phrase}"`,
  });
}

async function updatePhraseNote(entry) {
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

async function createPhraseNote(entry) {
  return invoke("addNote", {
    note: {
      deckName: PHRASE_DESK_NAME,
      modelName: PHRASE_CARD_TYPE,
      fields: {
        phrase: entry.phrase,
        version: VERSION,
      },
      options: { allowDuplicate: false },
      tags: ["english", "phrase"],
    },
  });
}

// Copyright (c) 2026-present, FromCero. All rights reserved.

const VERSION = "2";
const ANKI_CONNECT_URL = process.env.ANKI_CONNECT_URL;
const DICTIONARY_API_KEY = process.env.DICTIONARY_API_KEY;

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
  if (data.error) throw new Error(data.error);
  return data.result;
}

async function fetchWordDataFromDictionary(word) {
  const url = `https://www.dictionaryapi.com/api/v3/references/collegiate/json/${word}?key=${DICTIONARY_API_KEY}`;

  const res = await fetch(url);
  const data = await res.json();

  if (!Array.isArray(data) || !data[0] || typeof data[0] === "string") {
    throw new Error("Word not found in dictionary");
  }

  return data;
}

async function fetchPhonetic(word) {
  const url = `https://api.dictionaryapi.dev/api/v2/entries/en/${word}`;

  const res = await fetch(url);
  const data = await res.json();

  if (!Array.isArray(data) || !data[0] || !data[0].phonetic) {
    return "";
  }

  return data[0].phonetic;
}

async function convertToCardData(word, entry) {
  const partOfSpeech = entry.fl || "";
  const pronunciation = await fetchPhonetic(word);
  const audioName = entry.hwi?.prs?.[0]?.sound?.audio || "";
  const audioUrl = audioName ? getMWAudioUrl(audioName) : "";
  const definition = extractDefEx(entry);
  const definitionHTML =
    "<ul>" +
    definition
      .map(
        (i) =>
          `<li>${i.def}${i.ex ? `<ul><li><i>${i.ex}</i></li></ul>` : ""}</li>`,
      )
      .join("") +
    "</ul>";
  const stems = entry.meta?.stems || [];
  const stemHTML =
    "<ul>" +
    stems
      .map(
        (s) =>
          `<li><a href="https://www.merriam-webster.com/dictionary/${encodeURIComponent(s)}" target="_blank">${s}</a></li>`,
      )
      .join("") +
    "</ul>";
  return {
    node_id: word + "::" + partOfSpeech,
    word,
    partOfSpeech,
    pronunciation,
    audio: audioUrl,
    definition: definitionHTML,
    stems: stemHTML,
    url: `https://www.merriam-webster.com/dictionary/${word}`,
    version: VERSION,
  };
}

function getMWAudioUrl(audio) {
  const base = "https://media.merriam-webster.com/audio/prons/en/us/mp3/";
  let subdir;

  if (audio.startsWith("bix")) subdir = "bix";
  else if (audio.startsWith("gg")) subdir = "gg";
  else if (/^[0-9]/.test(audio)) subdir = "number";
  else subdir = audio[0];

  return `${base}${subdir}/${audio}.mp3`;
}

function extractDefEx(entry) {
  const results = [];

  for (const defBlock of entry.def || []) {
    for (const sseq of defBlock.sseq || []) {
      for (const item of sseq) {
        if (item[0] !== "sense") continue;

        const sense = item[1];
        let definition = null;
        let example = null;

        for (const dt of sense.dt || []) {
          if (dt[0] === "text") {
            definition = dt[1];
          }

          if (dt[0] === "vis" && dt[1]?.length) {
            example = dt[1][0].t;
          }
        }

        if (definition) {
          results.push({
            def: cleanMW(definition),
            ex: example ? cleanMW(example) : null,
          });
        }
      }
    }
  }

  return results;
}

function cleanMW(text) {
  return (
    text
      // links
      .replace(/\{d_link\|([^|]+)\|[^}]+\}/g, "$1")
      .replace(/\{a_link\|([^}]+)\}/g, "$1")
      .replace(/\{i_link\|([^}]+)\}/g, "$1")
      .replace(/\{et_link\|([^|]+)\|[^}]+\}/g, "$1")
      .replace(/\{sx\|([^|]+)\|[^}]*\}/g, "$1")

      // formatting
      .replace(/\{wi\}|\{\/wi\}/g, "")
      .replace(/\{it\}|\{\/it\}/g, "")
      .replace(/\{sc\}|\{\/sc\}/g, "")

      // punctuation / markers
      .replace(/\{bc\}/g, "")
      .replace(/\{ldquo\}|\{rdquo\}/g, '"')

      // math / misc
      .replace(/\{mat\|([^}]+)\}/g, "$1")

      // remove any remaining unknown tokens
      .replace(/\{[^}]+\}/g, "")

      .trim()
  );
}

async function getCardData(word) {
  const data = await fetchWordDataFromDictionary(word);

  const result = new Map();
  const supportPartOfSpeech = new Set([
    "noun",
    "verb",
    "adjective",
    "adverb",
    "preposition",
  ]);
  for (const entry of data) {
    try {
      const cardData = await convertToCardData(word, entry);
      if (cardData.partOfSpeech === "") continue;
      if (supportPartOfSpeech.has(cardData.partOfSpeech)) {
        if (!result.has(cardData.node_id)) {
          result.set(cardData.node_id, cardData);
        }
      }
    } catch (e) {
      console.warn(`Skipping entry due to error: ${e.message}`);
    }
  }
  return result;
}

async function findNote(entry) {
  return await invoke("findNotes", {
    query: `node_id:"${entry.node_id}"`,
  });
}

async function createCard(entry) {
  return invoke("addNote", {
    note: {
      deckName: "English",
      modelName: "Vocabulary",
      fields: {
        node_id: entry.node_id,
        word: entry.word,
        type: entry.partOfSpeech,
        pronunciation: entry.pronunciation,
        audio: entry.audio,
        definition: entry.definition,
        stems: entry.stems,
        url: `https://www.merriam-webster.com/dictionary/${entry.word}`,
        version: entry.version,
      },
      options: { allowDuplicate: false },
      tags: ["english"],
    },
  });
}

async function updateCard(entry) {
  return invoke("updateNoteFields", {
    note: {
      id: entry.id,
      fields: {
        word: entry.word,
        type: entry.partOfSpeech,
        pronunciation: entry.pronunciation,
        audio: entry.audio,
        definition: entry.definition,
        stems: entry.stems,
        url: `https://www.merriam-webster.com/dictionary/${entry.word}`,
        version: entry.version,
      },
    },
  });
}

async function main() {
  const word = process.argv[2];
  if (!word) {
    console.log("Usage: node new-word-card.js <word>");
    process.exit(1);
  }

  console.log(`Fetching data for: ${word}`);
  const cardData = await getCardData(word);

  for (const entry of cardData.values()) {
    const notes = await findNote(entry);
    if (notes.length > 0) {
      console.log(
        `Card already exists for ${entry.word} (${entry.partOfSpeech}). Updating...`,
      );
      await updateCard({ ...entry, id: notes[0] });
      console.log("Card updated.");
    } else {
      console.log(
        `Creating Anki card (${entry.word} - ${entry.partOfSpeech})...`,
      );
      const id = await createCard(entry);
      console.log(`Card created with ID: ${id}`);
    }
  }
}

main().catch(console.error);

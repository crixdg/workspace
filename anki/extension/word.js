// Copyright (c) 2026-present, FromCero. All rights reserved.

document.getElementById("word-input").addEventListener("keydown", (e) => {
  if (e.key === "Enter" && !e.shiftKey && !e.altKey) {
    e.preventDefault();
    addWord();
  }
});

//==========================================================================

async function addWord() {
  const word = document.getElementById("word-input").value.trim();
  const pos = document.getElementById("pos").value;
  if (!word) return;

  const finalStatus = [];
  try {
    setStatus("Fetching dictionary...");
    const cardData = await getCardData(word, pos);

    for (const entry of cardData.values()) {
      const notes = await findWordNote(entry);
      if (notes.length > 0) {
        setStatus(`Updating ${entry.word} (${entry.partOfSpeech})`);
        await updateWordNote({ ...entry, id: notes[0] });
        finalStatus.push(`Updated ${entry.word} (${entry.partOfSpeech})`);
      } else {
        setStatus(`Creating ${entry.word} (${entry.partOfSpeech})`);
        await createWordNote(entry);
        finalStatus.push(`Created ${entry.word} (${entry.partOfSpeech})`);
      }
    }

    if (finalStatus.length === 0) {
      finalStatus.push("No entries found for the specified part of speech.");
    }
    setStatus(finalStatus.join("\n"));
  } catch (err) {
    setStatus(err.message);
  }
}

//==========================================================================

async function getCardData(word, pos) {
  const data = await fetchWordDataFromDictionary(word);
  const pronunciation = await fetchDevPhonetic(word);

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
      entry.pronunciation = pronunciation;
      const cardData = await convertToCardData(word, entry);
      if (cardData.partOfSpeech === "") continue;
      if (supportPartOfSpeech.has(cardData.partOfSpeech)) {
        if (pos && pos != "any" && pos != cardData.partOfSpeech) continue;
        if (!result.has(cardData.node_id)) {
          result.set(cardData.node_id, cardData);
        }
      }
      if (!pos && result.size > 0) break;
    } catch (e) {
      console.warn(`Skipping entry due to error: ${e.message}`);
    }
  }
  return result;
}

async function convertToCardData(word, entry) {
  const partOfSpeech = entry.fl || "";
  const pronunciation = entry.hwi?.prs?.[0]?.mw || entry.pronunciation || "";
  pronunciation = pronunciation + " (" + respellPhonetic(pronunciation) + ")";
  const audioName = entry.hwi?.prs?.[0]?.sound?.audio || "";
  const audioUrl = audioName ? getMWAudioUrl(audioName) : "";
  const definition = extractMWDefEx(entry);
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

async function fetchWordDataFromDictionary(word) {
  const url = `https://www.dictionaryapi.com/api/v3/references/collegiate/json/${word}?key=${DICTIONARY_API_KEY}`;

  const res = await fetch(url);
  const data = await res.json();

  if (!Array.isArray(data) || !data[0] || typeof data[0] === "string") {
    throw new Error("Word not found in dictionary");
  }

  return data;
}

async function fetchDevPhonetic(word) {
  const url = `https://api.dictionaryapi.dev/api/v2/entries/en/${word}`;

  const res = await fetch(url);
  const data = await res.json();

  if (!Array.isArray(data) || !data[0] || !data[0].phonetic) {
    return "";
  }

  return data[0].phonetic;
}

//===========================================================================

function respellPhonetic(phonetic) {
  const soundMap = {
    "ir": "ear", // ɪɚ [ear] — fear, near, here
    "er": "air", // ɛɚ [air] — bear, square, chair

    "au̇r": "ow.er", // aʊɚ [ow.er] — power
    "ȯir": "oy.er", // ɔɪɚ [oy.er] — lawyer
    "ār": "ey.er", // eɪɚ [ey.er] — player
    "īr": "ai.er", // aɪɚ [ai.er] — fire
    "ōr": "oh.er", // oʊɚ [oh.er] — blower
    "u̇r": "u.er", // ʊɚ [u.er] — lure

    "ər": "er", // ɝ [er] — bird, nurse, ɚ [er] — better, actor
    "är": "ahr", // ɑɚ [ahr] — start, part, large
    "ȯr": "awr", // ɔɚ [awr] — force, more, chores

    "au̇": "ow", // aʊ [ow] — loud, blouse
    "ȯi": "oy", // ɔɪ [oy] — boiled, oyster
    "ā": "ey", // eɪ [ey] — savory, gravy
    "ī": "ai", // aɪ [ai] — nice, bike
    "ō": "oh", // oʊ [oh] — old, note

    "ē": "ee", // i: [ee] — reason, machine, police
    "ä": "ah", // ɑ: [ah] — father, pasta, drama
    "ü": "oo", // u: [oo] — moose, goofy
    "u̇": "u", // ʊ [u] — good, pudding
    "ȯ": "aw", // ɔ: [aw] — awful, coffee
    "ə": "uh", // ʌ [uh] — cup, sun, love, ə [uh] (unstressed syllable) — about, banana, sofa

    "ŋ": "ng", // ɳ [ng] — stunning, ring
    "t͟h": "tH", // ð [tH] — this, that, breathing
  };

  phonetic = phonetic.replace(/\([^)]*\)/g, "");
  for (const [key, value] of Object.entries(soundMap)) {
    phonetic = phonetic.replace(new RegExp(key, "g"), value);
  }

  let syllables = phonetic.split("-");
  for (let i = 0; i < syllables.length; i++) {
    if (syllables[i].includes("ˈ")) {
      syllables[i] = syllables[i].replace("ˈ", "");
      if (syllables.length > 1) {
        syllables[i] = syllables[i].toUpperCase();
      }
    }
  }
  return syllables.join("-");
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

function extractMWDefEx(entry) {
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
            def: cleanMWStyleSymbols(definition),
            ex: example ? cleanMWStyleSymbols(example) : null,
          });
        }
      }
    }
  }

  return results;
}

function cleanMWStyleSymbols(text) {
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

//===========================================================================

async function findWordNote(entry) {
  return await invoke("findNotes", {
    query: `node_id:"${entry.node_id}"`,
  });
}

async function createWordNote(entry) {
  return invoke("addNote", {
    note: {
      deckName: WORD_DESK_NAME,
      modelName: WORD_CARD_TYPE,
      fields: {
        node_id: entry.node_id,
        word: entry.word,
        type: entry.partOfSpeech,
        pronunciation: entry.pronunciation,
        audio: entry.audio,
        definition: entry.definition,
        stems: entry.stems,
        url: entry.url,
        version: entry.version,
      },
      options: { allowDuplicate: false },
      tags: ["english", "word"],
    },
  });
}

async function updateWordNote(entry) {
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

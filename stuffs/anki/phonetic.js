// Copyright (c) 2026-present, FromCero. All rights reserved.

const DICTIONARY_API_KEY = "...";

async function fetchWordDataFromDictionary(word) {
  const url = `https://www.dictionaryapi.com/api/v3/references/collegiate/json/${word}?key=${DICTIONARY_API_KEY}`;

  const res = await fetch(url);
  const data = await res.json();

  if (!Array.isArray(data) || !data[0] || typeof data[0] === "string") {
    throw new Error("Word not found in dictionary");
  }

  return data;
}

function respellPhonetic(phoneticInput) {
  let phonetic = phoneticInput.normalize("NFC");

  const soundMap = [
    ["ir", "ear"], // ɪɚ — fear, near
    ["er", "air"], // ɛɚ — bear, square

    ["au\u0307r", "ow.er"], // aʊɚ — power
    ["\u022Fir", "oy.er"], // ɔɪɚ — lawyer
    ["\u0101r", "ey.er"], // eɪɚ — player
    ["\u012Br", "ai.er"], // aɪɚ — fire
    ["\u014Dr", "oh.er"], // oʊɚ — blower
    ["u\u0307r", "u.er"], // ʊɚ — lure

    ["\u0259r", "er"], // ɝ/ɚ — bird, better
    ["\u00E4r", "ahr"], // ɑɚ — start, part
    ["\u022Fr", "awr"], // ɔɚ — force, more

    // Diphthongs
    ["au\u0307", "ow"], // aʊ — loud, blouse
    ["\u022Fi", "oy"], // ɔɪ — boiled, oyster
    ["\u0101", "ey"], // eɪ — savory, gravy
    ["\u012B", "ai"], // aɪ — nice, bike
    ["\u014D", "oh"], // oʊ — old, note

    // Monophthongs
    ["\u0113", "ee"], // i: — reason, machine
    ["\u00E4", "ah"], // ɑ: — father, pasta
    ["\u00FC", "oo"], // u: — moose, goofy
    ["u\u0307", "u"], // ʊ — good, pudding
    ["\u022F", "aw"], // ɔ: — awful, coffee
    ["\u0259", "uh"], // ʌ/ə — cup, about

    // Consonants
    ["\u014B", "ng"], // ɳ — stunning, ring
    ["t\u035Fh", "tH"], // ð — this, that
  ];

  phonetic = phonetic.replace(/\([^)]*\)/g, "");

  for (const [key, value] of soundMap) {
    phonetic = phonetic.replaceAll(key.normalize("NFC"), value);
  }

  let syllables = phonetic.split("-");
  for (let i = 0; i < syllables.length; i++) {
    if (syllables[i].includes("\u02C8")) {
      syllables[i] = syllables[i].replace("\u02C8", "");
      if (syllables.length > 1) {
        syllables[i] = syllables[i].toUpperCase();
      }
    }
    if (syllables[i].includes("\u02CC")) {
      syllables[i] = syllables[i].replace("\u02CC", "");
    }
  }

  return syllables.join("-");
}

async function main() {
  const n = process.argv.length;
  for (let i = 2; i < n; i++) {
    const word = process.argv[i].replace(",", "");
    const data = await fetchWordDataFromDictionary(word);
    const phonetic = data[0].hwi?.prs?.[0]?.mw || "";
    const respelledPhonetic = respellPhonetic(phonetic);
    console.log(`${word}: ${phonetic} --> ${respelledPhonetic}`);
  }
}

main();

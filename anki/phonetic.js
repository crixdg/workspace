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

function respellPhonetic(phonetic) {
  const soundMap = {
    ē: "ee", // i: [ee] — reason, machine, police
    i: "i", // ɪ [i] — limit, visit, image
    e: "e", // ɛ: [e] — elegant, affect, elephant
    ä: "ah", // ɑ: [ah] — father, pasta, drama
    a: "a", // æ [a] — cat, apple, bad
    ü: "oo", // u: [oo] — moose, goofy
    u̇: "u", // ʊ [u] — good, pudding
    ȯ: "aw", // ɔ: [aw] — awful, coffee
    ə: "uh", // ʌ [uh] — cup, sun, love, ə [uh] (unstressed syllable) — about, banana, sofa
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
    } else {
      syllables[i] = syllables[i].toLowerCase();
    }
  }
  return syllables.join("-");
}

async function main() {
  const n = process.argv.length;
  for (let i = 2; i < n; i++) {
    const word = process.argv[i];
    const data = await fetchWordDataFromDictionary(word);
    const phonetic = data[0].hwi?.prs?.[0]?.mw || "";
    const respelledPhonetic = respellPhonetic(phonetic);
    console.log(`${word}: ${phonetic} --> ${respelledPhonetic}`);
  }
}

main();

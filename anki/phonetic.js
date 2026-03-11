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
    ir: "ear", // ɪɚ [ear] — fear, near, here
    er: "air", // ɛɚ [air] — bear, square, chair

    au̇r: "ow.er", // aʊɚ [ow.er] — power
    ȯir: "oy.er", // ɔɪɚ [oy.er] — lawyer
    ār: "ey.er", // eɪɚ [ey.er] — player
    īr: "ai.er", // aɪɚ [ai.er] — fire
    ōr: "oh.er", // oʊɚ [oh.er] — blower
    u̇r: "u.er", // ʊɚ [u.er] — lure

    ər: "er", // ɝ [er] — bird, nurse, ɚ [er] — better, actor
    är: "ahr", // ɑɚ [ahr] — start, part, large
    ȯr: "awr", // ɔɚ [awr] — force, more, chores

    au̇: "ow", // aʊ [ow] — loud, blouse
    ȯi: "oy", // ɔɪ [oy] — boiled, oyster
    ā: "ey", // eɪ [ey] — savory, gravy
    ī: "ai", // aɪ [ai] — nice, bike
    ō: "oh", // oʊ [oh] — old, note

    ē: "ee", // i: [ee] — reason, machine, police
    ä: "ah", // ɑ: [ah] — father, pasta, drama
    ü: "oo", // u: [oo] — moose, goofy
    u̇: "u", // ʊ [u] — good, pudding
    ȯ: "aw", // ɔ: [aw] — awful, coffee
    ə: "uh", // ʌ [uh] — cup, sun, love, ə [uh] (unstressed syllable) — about, banana, sofa

    ŋ: "ng", // ɳ [ng] — stunning, ring
    t͟h: "tH", // ð [tH] — this, that, breathing
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

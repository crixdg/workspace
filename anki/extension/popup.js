// Copyright (c) 2026-present, FromCero. All rights reserved.

//==========================================================================

const tabs = document.querySelectorAll(".tab");
const contents = document.querySelectorAll(".tab-content");

tabs.forEach((tab) => {
  tab.addEventListener("click", () => {
    tabs.forEach((t) => t.classList.remove("active"));
    contents.forEach((c) => c.classList.remove("active"));

    tab.classList.add("active");
    document.getElementById(tab.dataset.tab).classList.add("active");
  });
});

function setStatus(text) {
  document.getElementById("status").innerText = text;
}

//==========================================================================

const VERSION = "2";
const ANKI_CONNECT_URL = "http://localhost:8765";
const DICTIONARY_API_KEY = "YOUR_DICTIONARY_API_KEY";

const WORD_DESK_NAME = "English: Words";
const WORD_CARD_TYPE = "English: Word";

const PHRASE_DESK_NAME = "English: Phrases";
const PHRASE_CARD_TYPE = "English: Phrase";

//==========================================================================

async function invoke(action, params = {}) {
  try {
    const res = await fetch(ANKI_CONNECT_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        action,
        version: 6,
        params,
      }),
    });

    if (!res.ok) {
      throw new Error(`AnkiConnnect HTTP error: ${res.status}`);
    }

    const data = await res.json();
    if (data.error) {
      throw new Error("AnkiConnect error: " + data.error);
    }

    return data.result;
  } catch (err) {
    throw new Error("Cannot connect to Anki. Is Anki running?\n" + err.message);
  }
}

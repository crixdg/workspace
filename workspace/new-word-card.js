const ANKI_CONNECT_URL = "http://localhost:8765";
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

async function getWordData(word) {
  const url = `https://www.dictionaryapi.com/api/v3/references/collegiate/json/${word}?key=${DICTIONARY_API_KEY}`;

  const res = await fetch(url);
  const data = await res.json();

  if (!Array.isArray(data) || !data[0] || typeof data[0] === "string") {
    throw new Error("Word not found in dictionary");
  }

  const result = [];
  for (const entry of data) {
    const partOfSpeech = entry.fl || "";
    const pronunciation = entry.hwi?.prs?.[0]?.mw || "";
    const definitions = entry.shortdef || [];
    const definitionHTML =
      `<ul>` + definitions.map((d) => `<li>${d}</li>`).join("") + `</ul>`;
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

    result.push({
      partOfSpeech,
      pronunciation,
      definition: definitionHTML,
      stems: stemHTML,
    });
  }
  return result;
}

async function isExistCard(entry) {
  const id = entry.word + "::" + entry.partOfSpeech;
  const result = await invoke("findNotes", {
    query: `id:${id}`,
  });
  return result.length > 0;
}

async function createCard(entry) {
  return invoke("addNote", {
    note: {
      deckName: "English",
      modelName: "Vocabulary",
      fields: {
        id: entry.word + "::" + entry.partOfSpeech,
        word: entry.word,
        type: entry.partOfSpeech,
        pronunciation: entry.pronunciation,
        definition: entry.definition,
        stems: entry.stems,
        url: `https://www.merriam-webster.com/dictionary/${entry.word}`,
      },
      tags: ["english"],
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

  const entries = await getWordData(word);

  for (let i = 0; i < entries.length; i++) {
    const entry = {
      word,
      ...entries[i],
    };

    if (await isExistCard(entry)) {
      console.log(
        `Card already exists for: ${entry.word} (${entry.partOfSpeech})`,
      );
      continue;
    }

    console.log(
      `Creating Anki card (${entry.word} - ${entry.partOfSpeech})...`,
    );

    const noteId = await createCard(entry);
    console.log(`Card created with ID: ${noteId}`);
  }
}

main().catch(console.error);

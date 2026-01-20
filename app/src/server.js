/**
 * Wiz Technical Exercise v4 web app
 * - Simple Express server that serves a minimal UI and writes/reads data from MongoDB.
 * - Mongo connection comes from env var: MONGO_URI
 */
const express = require("express");
const { MongoClient } = require("mongodb");
const path = require("path");

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 8080;
const MONGO_URI = process.env.MONGO_URI;

if (!MONGO_URI) {
  console.error("MONGO_URI env var is required. Example: mongodb://user:pass@host:27017/wizdb?authSource=admin");
  process.exit(1);
}

let db;
let items;

async function connectMongo() {
  const client = new MongoClient(MONGO_URI, {
    // Intentionally simple client options for the exercise.
  });
  await client.connect();
  db = client.db(); // database name comes from URI path
  items = db.collection("items");
  await items.createIndex({ createdAt: -1 });
  console.log("Connected to MongoDB");
}

app.get("/healthz", (req, res) => {
  res.json({ ok: true });
});

app.get("/api/items", async (req, res) => {
  try {
    const docs = await items.find({}).sort({ createdAt: -1 }).limit(50).toArray();
    res.json(docs);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: "failed_to_list_items" });
  }
});

app.post("/api/items", async (req, res) => {
  try {
    const name = String(req.body?.name || "").trim();
    if (!name) return res.status(400).json({ error: "name_required" });

    const doc = {
      name,
      createdAt: new Date()
    };
    await items.insertOne(doc);
    res.json({ ok: true });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: "failed_to_create_item" });
  }
});

// Serve static UI
app.use("/", express.static(path.join(__dirname, "..", "public")));

connectMongo()
  .then(() => {
    app.listen(PORT, () => console.log(`wizapp listening on :${PORT}`));
  })
  .catch((err) => {
    console.error("Mongo connect failed:", err);
    process.exit(1);
  });

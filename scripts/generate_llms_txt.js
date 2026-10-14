#!/usr/bin/env node

// Generates docs/static/llms.txt from docs/sidebars.js and each page's front matter.
//
//   node scripts/generate_llms_txt.js           # write the file
//   node scripts/generate_llms_txt.js --check   # exit 1 when the file is stale

const {execFileSync} = require("child_process");
const fs = require("fs");
const os = require("os");
const path = require("path");

const ROOT = path.join(__dirname, "..");
const DOCS = path.join(ROOT, "docs", "docs");
const OUTPUT = path.join(ROOT, "docs", "static", "llms.txt");
const NEXT_DOCS = "https://martenframework.com/docs/next";
const RELEASE_NOTES_ID = "the-marten-project/release-notes";

const sidebar = require(path.join(ROOT, "docs", "sidebars.js")).sidebar;

function docPath(id) {
  for (const extension of [".md", ".mdx"]) {
    const candidate = path.join(DOCS, `${id}${extension}`);
    if (fs.existsSync(candidate)) return candidate;
  }
  throw new Error(`No page for sidebar id '${id}'`);
}

function parseFrontMatter(text) {
  const match = text.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  const data = {};
  if (!match) return data;

  for (const line of match[1].split(/\r?\n/)) {
    const field = line.match(/^([A-Za-z0-9_]+):\s*(.*)$/);
    if (!field) continue;
    data[field[1]] = field[2].trim().replace(/^["']|["']$/g, "");
  }
  return data;
}

function readPage(id) {
  const file = docPath(id);
  const text = fs.readFileSync(file, "utf8");
  const frontMatter = parseFrontMatter(text);
  const body = text.replace(/^---\r?\n[\s\S]*?\r?\n---/, "").trim();
  return {file, frontMatter, body};
}

function isUnderDevelopment(id) {
  return readPage(id).body.startsWith("_Under development._");
}

function pageLink(id) {
  const page = readPage(id);
  const {title, description, slug} = page.frontMatter;

  if (!title) {
    throw new Error(`${path.relative(ROOT, page.file)} is missing a title`);
  }
  if (!description) {
    throw new Error(
      `${path.relative(ROOT, page.file)} is missing a description. ` +
        "Add one to its front matter, then regenerate docs/static/llms.txt.",
    );
  }

  const url = slug === "/" ? `${NEXT_DOCS}/` : `${NEXT_DOCS}/${id}`;
  return `- [${title}](${url}): ${description}`;
}

function addPage(sections, sectionName, id) {
  let section = sections.find(item => item.name === sectionName);
  if (!section) {
    section = {name: sectionName, items: []};
    sections.push(section);
  }
  section.items.push(id);
}

function walk(items, sectionName, sections) {
  for (const item of items) {
    if (typeof item === "string") {
      const name = sectionName || readPage(item).frontMatter.title;
      addPage(sections, name, item);
      continue;
    }

    if (!item || item.type !== "category") continue;

    const name = sectionName || item.label;
    if (item.link && item.link.id) addPage(sections, name, item.link.id);

    if (item.link && item.link.id === RELEASE_NOTES_ID) {
      for (const child of item.items || []) {
        if (typeof child === "string" && isUnderDevelopment(child)) addPage(sections, name, child);
      }
      continue;
    }

    walk(item.items || [], name, sections);
  }
}

function generate() {
  const sections = [];
  walk(sidebar, null, sections);

  const lines = [
    "# Marten",
    "",
    "> Marten is a batteries-included web framework for Crystal. This file indexes the guides for the version under development.",
    "",
    "These URLs are the in-development guides at https://martenframework.com/docs/next/. The latest stable guides are at https://martenframework.com/docs/. The generated API reference for this version is at https://martenframework.com/docs/api/dev/.",
    "",
  ];

  for (const section of sections) {
    lines.push(`## ${section.name}`, "");
    for (const id of section.items) lines.push(pageLink(id));
    lines.push("");
  }

  lines.push(
    "## API",
    "",
    "- [API reference](https://martenframework.com/docs/api/dev/index.html): Generated API reference for the version under development.",
    "",
  );

  return lines.join("\n");
}

function main() {
  const check = process.argv.includes("--check");
  if (process.argv.slice(2).some(arg => arg !== "--check")) {
    console.error("Usage: node scripts/generate_llms_txt.js [--check]");
    process.exit(2);
  }

  const generated = generate();

  if (!check) {
    fs.writeFileSync(OUTPUT, generated);
    return;
  }

  const current = fs.existsSync(OUTPUT) ? fs.readFileSync(OUTPUT, "utf8") : "";
  if (current === generated) return;

  const tmp = path.join(os.tmpdir(), "marten-llms.txt");
  fs.writeFileSync(tmp, generated);
  try {
    execFileSync("diff", ["-u", OUTPUT, tmp], {stdio: "inherit"});
  } catch (_error) {
    // diff exits with status 1 when the files differ.
  }
  console.error("\ndocs/static/llms.txt is out of date. Run: node scripts/generate_llms_txt.js");
  process.exit(1);
}

main();

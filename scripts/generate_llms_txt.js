#!/usr/bin/env node

// Generates docs/static/llms.txt and docs/static/llms-full.txt from docs/sidebars.js
// and the guide pages.
//
//   node scripts/generate_llms_txt.js           # write the files
//   node scripts/generate_llms_txt.js --check   # exit 1 when either file is stale

const {execFileSync} = require("child_process");
const fs = require("fs");
const os = require("os");
const path = require("path");

const ROOT = path.join(__dirname, "..");
const DOCS = path.join(ROOT, "docs", "docs");
const OUTPUT = path.join(ROOT, "docs", "static", "llms.txt");
const FULL_OUTPUT = path.join(ROOT, "docs", "static", "llms-full.txt");
const NEXT_DOCS = "https://martenframework.com/docs/next";
const DOCS_ORIGIN = "https://martenframework.com/docs";
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

function pageUrl(id) {
  let slug;
  try {
    slug = readPage(id).frontMatter.slug;
  } catch (_error) {
    return `${NEXT_DOCS}/${id}`;
  }
  return slug === "/" ? `${NEXT_DOCS}/` : `${NEXT_DOCS}/${id}`;
}

function pageLink(id) {
  const page = readPage(id);
  const {title, description} = page.frontMatter;

  if (!title) {
    throw new Error(`${path.relative(ROOT, page.file)} is missing a title`);
  }
  if (!description) {
    throw new Error(
      `${path.relative(ROOT, page.file)} is missing a description. ` +
        "Add one to its front matter, then regenerate docs/static/llms.txt.",
    );
  }

  return `- [${title}](${pageUrl(id)}): ${description}`;
}

function docCardsToMarkdown(body) {
  return body.replace(/<DocCard\s+item=\{\{([\s\S]*?)\}\}\s*\/>/g, (_match, attrs) => {
    const label = attrs.match(/label:\s*"([^"]+)"/);
    const docId = attrs.match(/docId:\s*"([^"]+)"/);
    if (!label || !docId) return "";
    return `- [${label[1]}](${pageUrl(docId[1])})`;
  });
}

function stripJsxTags(text) {
  let result = "";
  let index = 0;

  while (index < text.length) {
    const next = text[index + 1];
    if (text[index] === "<" && next && /[A-Za-z/!]/.test(next)) {
      let cursor = index + 1;
      let braces = 0;
      while (cursor < text.length) {
        const char = text[cursor];
        if (char === "{") braces += 1;
        else if (char === "}") braces = Math.max(0, braces - 1);
        else if (char === ">" && braces === 0) {
          cursor += 1;
          break;
        }
        cursor += 1;
      }
      index = cursor;
      continue;
    }

    result += text[index];
    index += 1;
  }

  return result;
}

function rewriteTarget(target, id) {
  if (target.startsWith("pathname:///")) {
    return `${DOCS_ORIGIN}${target.slice("pathname://".length)}`;
  }
  if (/^[a-z][a-z0-9+.-]*:/i.test(target) || target.startsWith("#") || target.startsWith("//")) {
    return target;
  }
  if (/\s/.test(target)) return target;

  const hashAt = target.indexOf("#");
  const hash = hashAt === -1 ? "" : target.slice(hashAt);
  const pathPart = hashAt === -1 ? target : target.slice(0, hashAt);
  if (!pathPart) return target;

  const base = path.posix.dirname(id);
  const resolved = path.posix.normalize(path.posix.join(base === "." ? "" : base, pathPart));
  if (resolved.startsWith("..")) return target;

  if (/\.mdx?$/.test(pathPart)) {
    return `${pageUrl(resolved.replace(/\.mdx?$/, ""))}${hash}`;
  }

  if (!path.posix.extname(pathPart)) {
    try {
      readPage(resolved);
    } catch (_error) {
      return target;
    }
    return `${pageUrl(resolved)}${hash}`;
  }

  const assetAt = resolved.indexOf("static/");
  if (assetAt !== -1 && /\.(png|jpe?g|gif|svg|webp)$/i.test(pathPart)) {
    return `${DOCS_ORIGIN}/${resolved.slice(assetAt + "static/".length)}${hash}`;
  }

  return target;
}

function rewriteLinks(segment, id) {
  const linkStart = /(!?)\[((?:[^\[\]]|\[[^\]]*\])*)\]\(/g;
  let result = "";
  let last = 0;

  for (const match of segment.matchAll(linkStart)) {
    const open = match.index + match[0].length;
    let depth = 1;
    let cursor = open;
    while (cursor < segment.length && depth > 0) {
      if (segment[cursor] === "(") depth += 1;
      else if (segment[cursor] === ")") depth -= 1;
      if (depth > 0) cursor += 1;
    }
    if (depth !== 0) continue;

    result += segment.slice(last, match.index);
    result += `${match[1]}[${match[2]}](${rewriteTarget(segment.slice(open, cursor).trim(), id)})`;
    last = cursor + 1;
  }

  return result + segment.slice(last);
}

function prepareBody(id) {
  const page = readPage(id);
  let body = page.body;

  if (page.file.endsWith(".mdx")) {
    body = docCardsToMarkdown(body);
    body = body.replace(/^import .*$/gm, "");
    body = stripJsxTags(body);
    body = body.replace(/[ \t]+\n/g, "\n").replace(/\n{3,}/g, "\n\n");
  }

  return rewriteLinks(body, id).trim();
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
    "The full text of these guides is at https://martenframework.com/docs/llms-full.txt. These URLs are the in-development guides at https://martenframework.com/docs/next/. The latest stable guides are at https://martenframework.com/docs/. The generated API reference for this version is at https://martenframework.com/docs/api/dev/.",
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

function generateFull() {
  const sections = [];
  walk(sidebar, null, sections);

  const lines = [
    "# Marten",
    "",
    "> Marten is a batteries-included web framework for Crystal. This file contains the guides for the version under development.",
    "",
    "The guide index is at https://martenframework.com/docs/llms.txt. These guides are the in-development guides at https://martenframework.com/docs/next/. The latest stable guides are at https://martenframework.com/docs/. The generated API reference for this version is at https://martenframework.com/docs/api/dev/.",
    "",
  ];

  for (const section of sections) {
    for (const id of section.items) {
      const page = readPage(id);
      lines.push(`# ${page.frontMatter.title}`, "");
      lines.push(`Source: ${pageUrl(id)}`, "");
      lines.push(prepareBody(id), "");
    }
  }

  return lines.join("\n");
}

function checkFile(output, generated) {
  const current = fs.existsSync(output) ? fs.readFileSync(output, "utf8") : "";
  if (current === generated) return false;

  const tmp = path.join(os.tmpdir(), `marten-${path.basename(output)}`);
  fs.writeFileSync(tmp, generated);
  try {
    execFileSync("diff", ["-u", output, tmp], {stdio: "inherit"});
  } catch (_error) {
    // diff exits with status 1 when the files differ.
  }
  console.error(`\n${path.relative(ROOT, output)} is out of date. Run: node scripts/generate_llms_txt.js`);
  return true;
}

function main() {
  const check = process.argv.includes("--check");
  if (process.argv.slice(2).some(arg => arg !== "--check")) {
    console.error("Usage: node scripts/generate_llms_txt.js [--check]");
    process.exit(2);
  }

  const outputs = [
    {file: OUTPUT, content: generate()},
    {file: FULL_OUTPUT, content: generateFull()},
  ];

  if (!check) {
    for (const output of outputs) fs.writeFileSync(output.file, output.content);
    return;
  }

  const stale = outputs.some(output => checkFile(output.file, output.content));
  if (stale) process.exit(1);
}

main();

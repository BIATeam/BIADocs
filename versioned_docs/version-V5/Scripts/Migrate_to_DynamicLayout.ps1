$Source = "C:\sources\Project";
$SourceFrontEnd = $Source + "\Angular\src"

$ExcludeDir = ('dist', 'node_modules', 'docs', 'scss', '.git', '.vscode', '.angular', '.dart_tool', 'bia-shared', 'bia-features', 'bia-domains', 'bia-core')

function Invoke-DynamicLayoutTransform {
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Files
    )

    # Save original dir
    $orig = Get-Location

    # Verify Node
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Error "Node.js not found on PATH. Install Node and re-run."
        exit 1
    }

    # Create temp dir (installed once)
    $temp = Join-Path $env:TEMP ("ng-route-transformer-" + [guid]::NewGuid().Guid)
    New-Item -ItemType Directory -Path $temp | Out-Null
    Set-Location $temp

    # package.json (ES module)
@"
{
  "type": "module",
  "private": true
}
"@ | Out-File -FilePath (Join-Path $temp "package.json") -Encoding utf8

    Write-Host "Installing typescript (local, once)..."
    npm install typescript --no-audit --no-fund --silent --no-progress | Out-Null

    # Write transformer.mjs (same transformer logic as your last working version, but main() loops over args)
    $transformer = @'
// transformer.mjs
import fs from "fs";
import ts from "typescript";
import path from "path";

function extractFeatureFromConstantsFile(moduleFilename) {
  const dir = path.dirname(moduleFilename);

  let files;
  try {
    files = fs.readdirSync(dir).filter(f => f.endsWith(".constants.ts"));
  } catch {
    return null;
  }

  for (const file of files) {
    const fullPath = path.join(dir, file);
    let text;
    try {
      text = fs.readFileSync(fullPath, "utf8");
    } catch {
      continue;
    }

    const m = text.match(
      /export\s+const\s+([a-zA-Z0-9]+)CRUDConfiguration\b/
    );

    if (m) {
      const raw = m[1];
      return raw.charAt(0).toUpperCase() + raw.slice(1);
    }
  }

  return null;
}

function resolveFeature(route, sf, filename) {
  return (
    extractFeatureFromConstantsFile(filename)
  );
}

function isIdentifierNamed(node, name) {
  return node && ts.isIdentifier(node) && node.text === name;
}
function findProp(obj, name) {
  if (!obj || !ts.isObjectLiteralExpression(obj)) return undefined;
  for (const p of obj.properties) {
    if (ts.isPropertyAssignment(p) && ts.isIdentifier(p.name) && p.name.text === name) return p;
  }
  return undefined;
}
function looksLikeRoute(obj) {
  if (!obj || !ts.isObjectLiteralExpression(obj)) return false;
  for (const p of obj.properties) {
    if (ts.isPropertyAssignment(p) && ts.isIdentifier(p.name)) {
      const n = p.name.text;
      if (n === "component" || n === "children" || n === "path" || n === "loadChildren") return true;
    }
  }
  return false;
}

// Collapse duplicate edits and detect true conflicts
function dedupeEdits(edits) {
  // key => { start,end,text }
  const map = new Map();
  const conflicts = [];
  for (const e of edits) {
    const key = `${e.start}:${e.end}`;
    if (!map.has(key)) {
      map.set(key, e);
    } else {
      const existing = map.get(key);
      if (existing.text === e.text) {
        // identical duplicate — ignore
        continue;
      } else {
        // conflicting replacement for same span
        conflicts.push({ span: key, existing, conflict: e });
        // Deterministic resolution: prefer the existing (first inserted)
      }
    }
  }
  return { edits: Array.from(map.values()), conflicts };
}

function applyEdits(src, edits) {
  if (!edits || edits.length === 0) return src;
  // detect overlaps first (safer): if overlapping, we will throw
  edits.sort((a,b) => a.start - b.start);
  for (let i = 1; i < edits.length; ++i) {
    if (edits[i].start < edits[i-1].end) {
      throw new Error(`Overlapping edits detected (start ${edits[i].start} < prev end ${edits[i-1].end}). Aborting apply.`);
    }
  }
  // apply descending
  edits.sort((a,b) => b.start - a.start);
  let out = src;
  for (const e of edits) out = out.slice(0,e.start) + e.text + out.slice(e.end);
  return out;
}

function safeRemoveRangeWithComma(src, start, end) {
  let s = start, e = end;
  // absorb trailing whitespace then comma if present
  while (e < src.length && /\s/.test(src[e])) e++;
  if (src[e] === ",") { e = e+1; return { s,e }; }
  // else look for leading comma
  let ls = s - 1;
  while (ls >= 0 && /\s/.test(src[ls])) ls--;
  if (ls >= 0 && src[ls] === ",") {
    // include comma and any whitespace before it
    let ls2 = ls;
    while (ls2 - 1 >= 0 && /\s/.test(src[ls2 - 1])) ls2--;
    s = ls2;
  }
  return { s, e };
}

function buildLayoutConditionalText(condNode, trueIsPopup, sf) {
  const condText = condNode.getText(sf);
  const left = trueIsPopup ? "LayoutMode.popup" : "LayoutMode.fullPage";
  const right = trueIsPopup ? "LayoutMode.fullPage" : "LayoutMode.popup";
  return `(${condText} ? ${left} : ${right})`;
}

function toKebabCase(str) {
  return str
    .replace(/([a-z0-9])([A-Z])/g, "$1-$2")        // lowercase/number followed by uppercase
    .replace(/([A-Z]+)([A-Z][a-z])/g, "$1-$2")    // consecutive uppercase letters (acronyms)
    .replace(/_/g, "-")                            // underscores
    .toLowerCase();
}

function patchImportsText(text) {
  const needed = ["DynamicLayoutComponent", "LayoutMode"];
  const importRegex = /import\s*\{([\s\S]*?)\}\s*from\s*(['"][^'"]+['"])\s*;/g;
  let out = text;
  let m;
  const inserts = [];
  let sharedImportFound = false;
  let sharedImportPath = null;

  // ---- Patch layout imports ----
  while ((m = importRegex.exec(text)) !== null) {
    const full = m[0], inner = m[1], matchStart = m.index;
    const fromPath = m[2];
    const names = inner.split(",").map(s => s.trim()).filter(Boolean).map(s => {
      const a = s.indexOf(" as ");
      return a >= 0 ? s.slice(0,a).trim() : s;
    });
    const touchesLayout = names.includes("FullPageLayoutComponent") || names.includes("PopupLayoutComponent");
    if (!touchesLayout) continue;

    const toAdd = needed.filter(n => !names.includes(n));
    if (toAdd.length === 0) continue;

    // Check if this is from a shared library (not individual component paths)
    const fromPathStr = fromPath.slice(1, -1); // remove quotes
    const isSharedLibrary = !fromPathStr.includes("/fullpage-layout/") && 
                            !fromPathStr.includes("/popup-layout/") &&
                            !fromPathStr.includes("/dynamic-layout/");
    
    if (isSharedLibrary) {
      // Add to existing shared import
      sharedImportFound = true;
      sharedImportPath = fromPathStr;
      const braceCloseRel = full.lastIndexOf("}");
      const insertPos = matchStart + braceCloseRel;
      const insertionText = (inner.trim().length === 0 || inner.trim().endsWith(",")) ? " " + toAdd.join(", ") : ", " + toAdd.join(", ");
      inserts.push({ pos: insertPos, newText: insertionText });
    } else {
      // This is from individual component paths - we'll add a separate import for shared path
      // Mark that we need to add the shared library import
      sharedImportFound = null; // Mark as needing separate import
    }
  }

  inserts.sort((a,b) => b.pos - a.pos);
  for (const ins of inserts) out = out.slice(0, ins.pos) + ins.newText + out.slice(ins.pos);

  // If we found individual component imports, add a new shared import for DynamicLayoutComponent and LayoutMode
  if (text.includes("FullPageLayoutComponent") || text.includes("PopupLayoutComponent")) {
    if (!sharedImportFound || sharedImportPath === null) {
      // Need to add new import from shared library
      const dynamicImportLine = "import { DynamicLayoutComponent, LayoutMode } from 'src/app/shared/bia-shared/components/layout/dynamic-layout/dynamic-layout.component';";
      
      // Check if it already exists
      if (!out.includes("import { DynamicLayoutComponent") && !out.includes("import { LayoutMode")) {
        const lastImport = out.lastIndexOf("import ");
        const insertPos = out.indexOf("\n", lastImport) + 1;
        out = out.slice(0, insertPos) + dynamicImportLine + "\n" + out.slice(insertPos);
      }
    }
  }

  // ---- Insert missing CRUDConfiguration imports ----
  if (text.includes("DynamicLayoutComponent")) {
    const configRegex = /([a-zA-Z0-9]+)CRUDConfiguration\b/g;
    let m2;
    const neededCRUD = new Map();
    while ((m2 = configRegex.exec(out)) !== null) {
      const feature = m2[1];
      neededCRUD.set(feature, `${feature}CRUDConfiguration`);
    }

    for (const [feature, cfg] of neededCRUD) {
      // Use kebab-case for import path
      const kebabFeature = toKebabCase(feature);
      const importLine = `import { ${cfg} } from './${kebabFeature}.constants';`;

      if (!out.includes(importLine)) {
        const lastImport = out.lastIndexOf("import ");
        const insertPos = out.indexOf("\n", lastImport) + 1;
        out = out.slice(0, insertPos) + importLine + "\n" + out.slice(insertPos);
      }
    }
  }

  return out;
}

function transformOneFile(src, filename) {
  let dynamicLayoutRootConsumed = false;
  const sf = ts.createSourceFile(filename, src, ts.ScriptTarget.Latest, true, ts.ScriptKind.TS);
  const edits = [];
  const removeInjectCandidates = [];

  function visitNode(node, depth = 0) {
    if (ts.isArrayLiteralExpression(node)) {
      node.elements.forEach(el => {
        if (ts.isObjectLiteralExpression(el) && looksLikeRoute(el)) visitRouteObject(el, depth, null);
        else if (ts.isArrayLiteralExpression(el)) visitNode(el, depth);
      });
      return;
    }
    ts.forEachChild(node, c => visitNode(c, depth));
  }

  function getInsertPosBeforeClosingBrace(objNode) {
    const lastTok = objNode.getLastToken && objNode.getLastToken();
    if (lastTok) return lastTok.getStart();
    // fallback: getEnd()-1
    return objNode.getEnd() - 1;
  }

  function prefixForInsertion(objNode, sf) {
    // If object literal text right before "}" has a comma, use a space
    const text = objNode.getFullText(sf);
    const lastProp = objNode.properties[objNode.properties.length - 1];
    if (!lastProp) return ""; // empty object → no prefix needed
    const afterLastProp = text.slice(lastProp.end - objNode.pos, objNode.end - objNode.pos);
    return /,\s*\}$/.test(afterLastProp) ? " " : ", ";
  }

  function getLoadChildrenImportPath(loadChildrenProp, sf) {
    if (!loadChildrenProp || !ts.isPropertyAssignment(loadChildrenProp)) return null;
    const text = loadChildrenProp.initializer.getText(sf);
    const m = text.match(/import\s*\(\s*['"](.+?)['"]\s*\)/);
    return m ? m[1] : null;
  }

  function isTrulyDynamicComponent(dynamicProp) {
    if (!dynamicProp || !ts.isPropertyAssignment(dynamicProp)) return false;

    let expr = dynamicProp.initializer;

    // unwrap arrow function: () => expr
    if (ts.isArrowFunction(expr)) {
      expr = expr.body;
    }

    // unwrap parentheses
    while (ts.isParenthesizedExpression(expr)) {
      expr = expr.expression;
    }

    // ONLY treat ternary as dynamic
    return ts.isConditionalExpression(expr);
  }

  // SINGLE-DECISION visitRouteObject (computes actions once per route)
  function visitRouteObject(routeObj, depth, inheritedFinalComponent) {
    const compProp = findProp(routeObj, "component");
    const dataProp = findProp(routeObj, "data");
    const childrenProp = findProp(routeObj, "children");

    // compute existing final component name if possible
    let currentFinalComponent = inheritedFinalComponent;
    if (compProp && ts.isPropertyAssignment(compProp) && ts.isIdentifier(compProp.initializer)) {
      currentFinalComponent = compProp.initializer.text;
    }

    // Decide exactly once what we will do for this route
    let desiredComponentText = null;     // if not null -> replace component initializer with this text
    let desiredLayoutModeText = null;    // if not null -> set/replace data.layoutMode to this text
    let shouldRemoveInject = false;      // whether to remove injectComponent later
    let keepInjectAlways = false;        // RULE 1: keep injectComponent when root FullPage -> Dynamic

    function getInjectInitializerText() {
      if (!dataProp || !ts.isPropertyAssignment(dataProp) || !ts.isObjectLiteralExpression(dataProp.initializer)) return null;
      const inj = findProp(dataProp.initializer, "injectComponent");
      if (inj && ts.isPropertyAssignment(inj)) return inj.initializer.getText(sf);
      return null;
    }

    if (compProp && ts.isPropertyAssignment(compProp)) {
      const compInit = compProp.initializer;

      // RULE 1: root-level FullPageLayoutComponent -> DynamicLayoutComponent (NO layoutMode)
      if (
        isIdentifierNamed(compInit, "FullPageLayoutComponent") &&
        !dynamicLayoutRootConsumed
      ) {
        desiredComponentText = "DynamicLayoutComponent";
        keepInjectAlways = true;
        dynamicLayoutRootConsumed = true;

        const feature = resolveFeature(routeObj, sf, filename);

        if (feature) {
          const featureLower =
            feature.charAt(0).toLowerCase() + feature.slice(1);

          routeObj.__crudFeature = {
            feature,
            configName: `${featureLower}CRUDConfiguration`
          };
        }
      } else {
        // RULE 2: PopupLayoutComponent or FullPageLayoutComponent (non-root)
        if (isIdentifierNamed(compInit, "PopupLayoutComponent") || isIdentifierNamed(compInit, "FullPageLayoutComponent")) {
          const isPopup = isIdentifierNamed(compInit, "PopupLayoutComponent");
          desiredLayoutModeText = `LayoutMode.${isPopup ? "popup" : "fullPage"}`;
          const injText = getInjectInitializerText();
          if (injText) desiredComponentText = injText;
          shouldRemoveInject = true;
        }
        // RULE 3: ternary cond ? Popup : Full or reversed
        else if (ts.isConditionalExpression(compInit)) {
          const cond = compInit;
          const whenT = cond.whenTrue;
          const whenF = cond.whenFalse;
          const trueIsPopup = isIdentifierNamed(whenT, "PopupLayoutComponent");
          const trueIsFull = isIdentifierNamed(whenT, "FullPageLayoutComponent");
          const falseIsPopup = isIdentifierNamed(whenF, "PopupLayoutComponent");
          const falseIsFull = isIdentifierNamed(whenF, "FullPageLayoutComponent");
          const validPair = (trueIsPopup && falseIsFull) || (trueIsFull && falseIsPopup);
          if (validPair) {
            // Only set desiredLayoutModeText if the condition doesn't contain the CrudConfiguration
            const feature = resolveFeature(routeObj, sf, filename);
            const configName = feature
              ? `${feature.charAt(0).toLowerCase() + feature.slice(1)}CRUDConfiguration`
              : null;
            const conditionText = cond.condition.getText(sf);
            const containsConfig = configName && conditionText.includes(configName);

            if (!containsConfig) {
              desiredLayoutModeText = buildLayoutConditionalText(cond.condition, trueIsPopup, sf);
            }

            const injText = getInjectInitializerText();
            if (injText) desiredComponentText = injText;
            shouldRemoveInject = true;
          }
        }
        // RULE 4: contains Popup/Full anywhere (not ternary)
        else {
          const txt = compInit.getText(sf);
          const containsPopup = /\bPopupLayoutComponent\b/.test(txt);
          const containsFull = /\bFullPageLayoutComponent\b/.test(txt);
          if ((containsPopup || containsFull) && !ts.isConditionalExpression(compInit)) {
            const mode = containsPopup ? "popup" : "fullPage";
            desiredLayoutModeText = `LayoutMode.${mode}`;
            const injText = getInjectInitializerText();
            if (injText) desiredComponentText = injText;
            shouldRemoveInject = true;
          }
        }
      }
    }

    // ---- NEW RULE: all descendants of DynamicLayoutComponent ----
    if (
      (inheritedFinalComponent === "DynamicLayoutComponent") &&
      !desiredLayoutModeText // do not override explicit layout decisions
    ) {
      const loadChildrenProp = findProp(routeObj, "loadChildren");

      if (loadChildrenProp) {
        const hasLayoutMode =
          dataProp &&
          ts.isPropertyAssignment(dataProp) &&
          ts.isObjectLiteralExpression(dataProp.initializer) &&
          findProp(dataProp.initializer, "layoutMode");

        if (!hasLayoutMode) {
          const modeText = "LayoutMode.fullPage";

          if (
            dataProp &&
            ts.isPropertyAssignment(dataProp) &&
            ts.isObjectLiteralExpression(dataProp.initializer)
          ) {
            const dataInit = dataProp.initializer;
            const insertPos = getInsertPosBeforeClosingBrace(dataInit);
            const insertion =
              prefixForInsertion(dataInit, sf) +
              `layoutMode: ${modeText} `;
            edits.push({ start: insertPos, end: insertPos, text: insertion });
          } else {
            const insertPos = getInsertPosBeforeClosingBrace(routeObj);
            const insertion =
              prefixForInsertion(routeObj, sf) +
              `data: { layoutMode: ${modeText} } `;
            edits.push({ start: insertPos, end: insertPos, text: insertion });
          }
        }
      }
    }

    // Emit the decided edits (one per target)
    if (desiredComponentText !== null && compProp && ts.isPropertyAssignment(compProp)) {
      const compInit = compProp.initializer;
      edits.push({ start: compInit.getStart(sf), end: compInit.getEnd(), text: desiredComponentText });
      inheritedFinalComponent = desiredComponentText;
    }

    const dynamicProp =
      dataProp &&
      ts.isPropertyAssignment(dataProp) &&
      ts.isObjectLiteralExpression(dataProp.initializer) &&
      findProp(dataProp.initializer, "dynamicComponent");

    const hasDynamicComponent = isTrulyDynamicComponent(dynamicProp);

    if (desiredLayoutModeText !== null) {
      if (dataProp && ts.isPropertyAssignment(dataProp) && ts.isObjectLiteralExpression(dataProp.initializer)) {
        const dataInit = dataProp.initializer;
        const layoutProp = findProp(dataInit, "layoutMode");
        if (layoutProp) {
          edits.push({ start: layoutProp.initializer.getStart(sf), end: layoutProp.initializer.getEnd(), text: desiredLayoutModeText });
        } else {
          const insertPos = getInsertPosBeforeClosingBrace(dataInit);
          const insertion = prefixForInsertion(dataInit, sf) + `layoutMode: ${desiredLayoutModeText} `;
          edits.push({ start: insertPos, end: insertPos, text: insertion });
        }
      } else {
        const insertPos = getInsertPosBeforeClosingBrace(routeObj);
        // use prefixForInsertion for routeObj as well so we handle trailing comma cases
        const insertion = prefixForInsertion(routeObj, sf) + `data: { layoutMode: ${desiredLayoutModeText} } `;
        edits.push({ start: insertPos, end: insertPos, text: insertion });
      }
    }

    // ---- NEW: Add configuration when converting to DynamicLayoutComponent ----
    if (routeObj.__crudFeature && desiredComponentText === "DynamicLayoutComponent") {
      const { configName, feature } = routeObj.__crudFeature;

      // ---- RULE: Only add configuration: if the import file exists ----
      const kebabFeature = toKebabCase(feature);
      const basePath = path.dirname(filename);
      const configFileBase = path.join(basePath, `${kebabFeature}.constants`);
      const possibleExtensions = [".ts", ".js", ".mts", ".cts"];
      const importExists = possibleExtensions.some(ext => fs.existsSync(configFileBase + ext));

      if (!importExists) {
        // Skip adding configuration & do not mark imports
        // Still remove injectComponent normally later
        // -> Abort patch 2 safely
        return;
      }

      if (dataProp && ts.isPropertyAssignment(dataProp) && ts.isObjectLiteralExpression(dataProp.initializer)) {
        const dataInit = dataProp.initializer;

        // Only add if not already present
        const existing = findProp(dataInit, "configuration");
        if (!existing) {
          const insertPos = getInsertPosBeforeClosingBrace(dataInit);
          const insertion = prefixForInsertion(dataInit, sf) + `configuration: ${configName} `;
          edits.push({ start: insertPos, end: insertPos, text: insertion });
        }
      } else {
        // No data property → create it
        const insertPos = getInsertPosBeforeClosingBrace(routeObj);
        const insertion =
          prefixForInsertion(routeObj, sf) +
          `data: { configuration: ${configName} } `;
        edits.push({ start: insertPos, end: insertPos, text: insertion });
      }

      // Mark import
      routeObj.__needsCRUDImport = true;
    }

    if (shouldRemoveInject && !keepInjectAlways && dataProp && ts.isPropertyAssignment(dataProp) && ts.isObjectLiteralExpression(dataProp.initializer)) {
      removeInjectCandidates.push({ dataProp, routeObj });
    }

    // Recurse children after decisions emitted
    if (childrenProp && ts.isPropertyAssignment(childrenProp) && ts.isArrayLiteralExpression(childrenProp.initializer)) {
      const childArr = childrenProp.initializer;
      childArr.elements.forEach(el => {
        if (ts.isObjectLiteralExpression(el)) visitRouteObject(el, depth + 1, inheritedFinalComponent);
      });
    }
  }

  function walkForRoutes(node) {
    if (ts.isVariableStatement(node)) {
      for (const decl of node.declarationList.declarations) {
        if (decl.type && ts.isTypeReferenceNode(decl.type) && decl.type.typeName && decl.type.typeName.getText(sf) === "Routes" && decl.initializer && ts.isArrayLiteralExpression(decl.initializer)) {
          visitNode(decl.initializer, 0, null);
        }
      }
    }
    ts.forEachChild(node, walkForRoutes);
  }

  walkForRoutes(sf);

  // Final sweep: remove injectComponent unless final component is DynamicLayoutComponent
  for (const cand of removeInjectCandidates) {
    const { dataProp, routeObj } = cand;
    if (!dataProp || !ts.isPropertyAssignment(dataProp)) continue;
    const dataInit = dataProp.initializer;
    if (!dataInit || !ts.isObjectLiteralExpression(dataInit)) continue;

    let finalComponent = null;
    for (const p of routeObj.properties) {
      if (ts.isPropertyAssignment(p) && ts.isIdentifier(p.name) && p.name.text === "component" && ts.isIdentifier(p.initializer)) {
        finalComponent = p.initializer.text;
      }
    }

    if (finalComponent !== "DynamicLayoutComponent") {
      for (const dp of dataInit.properties) {
        if (
          ts.isPropertyAssignment(dp) &&
          ts.isIdentifier(dp.name) &&
          (dp.name.text === "injectComponent" || dp.name.text === "dynamicComponent")
        ) {
          const start = dp.getStart(sf);
          const end = dp.getEnd();
          let { s, e } = safeRemoveRangeWithComma(src, start, end);

          // consume trailing spaces/tabs
          while (e < src.length && /[ \t]/.test(src[e])) e++;

          // consume one newline (CRLF or LF)
          if (src[e] === "\r" && src[e+1] === "\n") e += 2;
          else if (src[e] === "\n" || src[e] === "\r") e += 1;

          edits.push({ start: s, end: e, text: "" });
        }
      }
    }
  }

  // Dedupe edits and apply
  const dedup = dedupeEdits(edits);
  if (dedup.conflicts && dedup.conflicts.length > 0) {
    const dbg = {
      message: "Conflicting edits for identical spans detected (dedupe).",
      file: filename,
      conflicts: dedup.conflicts
    };
    fs.writeFileSync(filename + ".dedupe-debug.json", JSON.stringify(dbg, null, 2), "utf8");
    throw new Error("Conflicting edits detected; see " + filename + ".dedupe-debug.json");
  }

  try {
    const result = applyEdits(src, dedup.edits);
    const final = patchImportsText(result);
    return final;
  } catch (err) {
    console.error("Aborting write due to overlapping edits:", err && err.message ? err.message : err);
    const dbg = {
      message: "Overlapping edits prevented to avoid corruption",
      file: filename,
      plannedEdits: dedup.edits.map(e => ({ start: e.start, end: e.end, snippetStart: src.slice(Math.max(0,e.start-40), e.start), snippetEnd: src.slice(e.end, Math.min(src.length, e.end+40)), newTextPreview: e.text.length>200? e.text.slice(0,200)+"...": e.text }))
    };
    fs.writeFileSync(filename + ".edit-debug.json", JSON.stringify(dbg, null, 2), "utf8");
    throw err;
  }
}

function main() {
  const args = process.argv.slice(2);
  if (!args || args.length === 0) {
    console.error("Usage: node transformer.mjs <file1> <file2> ...");
    process.exit(2);
  }

  for (const f of args) {
    const abs = path.resolve(process.cwd(), f);
    let src = fs.readFileSync(abs, "utf8");

    try {
      const out = transformOneFile(src, abs);
      fs.writeFileSync(abs, out, "utf8");
      console.log("Wrote:", f);
    } catch (e) {
      console.error("Transform failed for", f);
      console.error(e && e.stack ? e.stack : e);
    }
  }
}

main();
'@

    $transformerPath = Join-Path $temp "transformer.mjs"
    Set-Content -Path $transformerPath -Value $transformer -Encoding utf8

    # Run transformer for all files in single Node invocation
    try {
        Write-Host "Transforming $($Files.Count) files..."
        & node $transformerPath @Files
    }
    catch {
        Write-Error "Transformer failed: $_"
        Set-Location $orig
        exit 1
    }
    finally {
        # try cleanup
        try { Set-Location $orig } catch {}
        # We keep temp dir briefly in case you want to inspect; remove if you want
        # Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
    }

    Write-Host "Done. Output: $($Files.Count) files"
}

function Invoke-DynamicLayoutTransformInFilesRec {
  param (
    [string]$Source,
    [string]$Include,
    [System.Collections.Generic.List[string]]$FileList
  )
  foreach ($childDirectory in Get-ChildItem -Force -Path $Source -Directory -Exclude $ExcludeDir) {
    Invoke-DynamicLayoutTransformInFilesRec -Source $childDirectory.FullName -Include $Include -FileList $FileList
  }

  $fileItems = Get-ChildItem -LiteralPath $Source -File -Filter $Include
  foreach ($file in $fileItems) {
    $FileList.Add($file.FullName)
  }
}

function Invoke-DynamicLayoutTransformInFiles {
  param (
    [string]$Source,
    [string]$Include
  )
  $fileList = New-Object System.Collections.Generic.List[string]
  Invoke-DynamicLayoutTransformInFilesRec -Source $Source -Include $Include -FileList $fileList

  if ($fileList.Count -gt 0) {
      Invoke-DynamicLayoutTransform -Files $fileList.ToArray()
  }
}

# BEGIN - Replace FullPageLayout by DynamicLayout in routing
Invoke-DynamicLayoutTransformInFiles -Source $SourceFrontEnd -Include @('*module.ts')
# END - Replace FullPageLayout by DynamicLayout in routing

# FRONT END CLEAN
Set-Location $SourceFrontEnd
npm run clean

Write-Host "Finish"
pause

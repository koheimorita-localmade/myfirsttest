// ============================================================
// AI翻訳 学習DB - Google Apps Script Web App
// ============================================================
// このファイルの中身をまるごと Apps Script エディタに貼り付けてください。
// スプレッドシートの [拡張機能] > [Apps Script] から開けます。
//
// デプロイ設定:
//   - 種類: ウェブアプリ
//   - 実行するユーザー: 自分
//   - アクセスできるユーザー: 全員
// ============================================================

const SHEET_PAIRS = "pairs";
const SHEET_SCORES = "scores";

const PAIRS_HEADERS = ["id", "pairKey", "langA", "textA", "langB", "textB", "style", "createdAt"];
const SCORES_HEADERS = ["pairId", "direction", "easeFactor", "interval", "nextReview", "lastReviewed", "repetitions"];

// ---------- Entry points ----------

function doGet(e) {
  const params = e.parameter || {};
  return handleRequest(params.action, params);
}

function doPost(e) {
  let params = {};
  try {
    if (e.postData && e.postData.contents) {
      params = JSON.parse(e.postData.contents);
    } else {
      params = e.parameter || {};
    }
  } catch (err) {
    params = e.parameter || {};
  }
  return handleRequest(params.action, params);
}

function handleRequest(action, params) {
  try {
    ensureHeaders();
    let result;
    switch (action) {
      case "ping":        result = { ok: true, time: new Date().toISOString() }; break;
      case "listAll":     result = { pairs: listPairs(), scores: listScores() }; break;
      case "listPairs":   result = listPairs(); break;
      case "listScores":  result = listScores(); break;
      case "savePair":    result = savePair(params.pair); break;
      case "updatePair":  result = updatePair(params.pair); break;
      case "deletePair":  result = deletePair(params.id); break;
      case "updateScore": result = updateScore(params.score); break;
      case "deleteScore": result = deleteScoreByDirection(params.pairId, params.direction); break;
      default: throw new Error("Unknown action: " + (action || "(none)"));
    }
    return jsonResponse({ success: true, data: result });
  } catch (err) {
    return jsonResponse({ success: false, error: String(err.message || err) });
  }
}

// ---------- Helpers ----------

function jsonResponse(data) {
  return ContentService
    .createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}

function getSheet(name) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(name);
  if (!sheet) sheet = ss.insertSheet(name);
  return sheet;
}

function ensureHeaders() {
  const pairs = getSheet(SHEET_PAIRS);
  if (pairs.getLastRow() === 0) pairs.appendRow(PAIRS_HEADERS);
  const scores = getSheet(SHEET_SCORES);
  if (scores.getLastRow() === 0) scores.appendRow(SCORES_HEADERS);
}

function rowsToObjects(sheet) {
  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];
  const headers = data[0];
  return data.slice(1).map(row => {
    const obj = {};
    headers.forEach((h, i) => {
      let v = row[i];
      if (v instanceof Date) v = v.toISOString();
      obj[h] = v;
    });
    return obj;
  });
}

// ---------- Pairs ----------

function listPairs() {
  return rowsToObjects(getSheet(SHEET_PAIRS));
}

function savePair(pair) {
  if (!pair) throw new Error("pair is required");

  const sheet = getSheet(SHEET_PAIRS);
  const existing = listPairs();

  // Duplicate check (exact match on pairKey + textA + textB + style)
  const dup = existing.find(p =>
    p.pairKey === pair.pairKey &&
    p.textA === pair.textA &&
    p.textB === pair.textB &&
    (p.style || "") === (pair.style || "")
  );
  if (dup) return { skipped: true, id: dup.id };

  const id = pair.id || Utilities.getUuid();
  const createdAt = new Date().toISOString();
  sheet.appendRow([
    id,
    pair.pairKey || "",
    pair.langA || "",
    pair.textA || "",
    pair.langB || "",
    pair.textB || "",
    pair.style || "",
    createdAt
  ]);
  return { id, created: true };
}

function updatePair(pair) {
  if (!pair || !pair.id) throw new Error("pair.id is required");
  const sheet = getSheet(SHEET_PAIRS);
  const data = sheet.getDataRange().getValues();
  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === pair.id) {
      const row = i + 1;
      if (pair.pairKey !== undefined) sheet.getRange(row, 2).setValue(pair.pairKey);
      if (pair.langA   !== undefined) sheet.getRange(row, 3).setValue(pair.langA);
      if (pair.textA   !== undefined) sheet.getRange(row, 4).setValue(pair.textA);
      if (pair.langB   !== undefined) sheet.getRange(row, 5).setValue(pair.langB);
      if (pair.textB   !== undefined) sheet.getRange(row, 6).setValue(pair.textB);
      if (pair.style   !== undefined) sheet.getRange(row, 7).setValue(pair.style);
      return { updated: true };
    }
  }
  throw new Error("Pair not found: " + pair.id);
}

function deletePair(id) {
  if (!id) throw new Error("id is required");
  const sheet = getSheet(SHEET_PAIRS);
  const data = sheet.getDataRange().getValues();
  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === id) {
      sheet.deleteRow(i + 1);
      deleteScoresByPairId(id);
      return { deleted: true };
    }
  }
  throw new Error("Pair not found: " + id);
}

// ---------- Scores ----------

function listScores() {
  return rowsToObjects(getSheet(SHEET_SCORES));
}

function updateScore(score) {
  if (!score || !score.pairId || !score.direction) {
    throw new Error("pairId and direction are required");
  }
  const sheet = getSheet(SHEET_SCORES);
  const data = sheet.getDataRange().getValues();
  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === score.pairId && data[i][1] === score.direction) {
      const row = i + 1;
      if (score.easeFactor    !== undefined) sheet.getRange(row, 3).setValue(score.easeFactor);
      if (score.interval      !== undefined) sheet.getRange(row, 4).setValue(score.interval);
      if (score.nextReview    !== undefined) sheet.getRange(row, 5).setValue(score.nextReview);
      if (score.lastReviewed  !== undefined) sheet.getRange(row, 6).setValue(score.lastReviewed);
      if (score.repetitions   !== undefined) sheet.getRange(row, 7).setValue(score.repetitions);
      return { updated: true };
    }
  }
  sheet.appendRow([
    score.pairId,
    score.direction,
    score.easeFactor   != null ? score.easeFactor : 2.5,
    score.interval     != null ? score.interval   : 0,
    score.nextReview   || "",
    score.lastReviewed || "",
    score.repetitions  != null ? score.repetitions : 0
  ]);
  return { created: true };
}

function deleteScoresByPairId(pairId) {
  const sheet = getSheet(SHEET_SCORES);
  const data = sheet.getDataRange().getValues();
  for (let i = data.length - 1; i >= 1; i--) {
    if (data[i][0] === pairId) {
      sheet.deleteRow(i + 1);
    }
  }
}

function deleteScoreByDirection(pairId, direction) {
  if (!pairId || !direction) throw new Error("pairId and direction are required");
  const sheet = getSheet(SHEET_SCORES);
  const data = sheet.getDataRange().getValues();
  for (let i = 1; i < data.length; i++) {
    if (data[i][0] === pairId && data[i][1] === direction) {
      sheet.deleteRow(i + 1);
      return { deleted: true };
    }
  }
  throw new Error("Score not found");
}

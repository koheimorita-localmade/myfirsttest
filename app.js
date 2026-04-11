// ========================================
// AI翻訳 - Gemini Translation App
// ========================================

const LANG_NAMES = {
    auto: "自動検出",
    ja: "日本語",
    en: "English",
    zh: "中文 (中国語)",
    ko: "한국어 (韓国語)",
    es: "Español (スペイン語)",
    fr: "Français (フランス語)",
    de: "Deutsch (ドイツ語)",
    pt: "Português (ポルトガル語)",
    th: "ไทย (タイ語)",
    vi: "Tiếng Việt (ベトナム語)",
    ar: "العربية (アラビア語)",
};

const GEMINI_MODEL = "gemini-2.0-flash";
const GEMINI_API_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;
const STORAGE_KEY_API = "gemini_api_key";
const STORAGE_KEY_HISTORY = "translation_history";
const MAX_HISTORY = 20;

// ---- DOM Elements ----
const sourceText = document.getElementById("source-text");
const sourceLang = document.getElementById("source-lang");
const targetLang = document.getElementById("target-lang");
const translateBtn = document.getElementById("translate-btn");
const btnText = translateBtn.querySelector(".btn-text");
const btnLoading = translateBtn.querySelector(".btn-loading");
const resultContainer = document.getElementById("result-container");
const resultText = document.getElementById("result-text");
const resultLang = document.getElementById("result-lang");
const copyBtn = document.getElementById("copy-btn");
const clearBtn = document.getElementById("clear-btn");
const charCount = document.getElementById("char-count");
const swapBtn = document.getElementById("swap-btn");
const settingsBtn = document.getElementById("settings-btn");
const settingsModal = document.getElementById("settings-modal");
const closeSettings = document.getElementById("close-settings");
const apiKeyInput = document.getElementById("api-key");
const toggleKeyBtn = document.getElementById("toggle-key");
const saveKeyBtn = document.getElementById("save-key");
const keyStatus = document.getElementById("key-status");
const historyContainer = document.getElementById("history-container");
const historyList = document.getElementById("history-list");
const clearHistoryBtn = document.getElementById("clear-history-btn");

// ---- State ----
let isTranslating = false;

// ---- Init ----
function init() {
    loadApiKey();
    loadHistory();
    bindEvents();
    updateTranslateButton();
}

function bindEvents() {
    sourceText.addEventListener("input", onSourceInput);
    translateBtn.addEventListener("click", handleTranslate);
    swapBtn.addEventListener("click", swapLanguages);
    copyBtn.addEventListener("click", copyResult);
    clearBtn.addEventListener("click", clearInput);

    // Settings
    settingsBtn.addEventListener("click", openSettings);
    closeSettings.addEventListener("click", closeSettingsModal);
    settingsModal.querySelector(".modal-backdrop").addEventListener("click", closeSettingsModal);
    toggleKeyBtn.addEventListener("click", toggleKeyVisibility);
    saveKeyBtn.addEventListener("click", saveApiKey);
    apiKeyInput.addEventListener("keydown", (e) => {
        if (e.key === "Enter") saveApiKey();
    });

    // History
    clearHistoryBtn.addEventListener("click", clearHistory);

    // Keyboard shortcut: Ctrl/Cmd + Enter to translate
    sourceText.addEventListener("keydown", (e) => {
        if ((e.metaKey || e.ctrlKey) && e.key === "Enter") {
            e.preventDefault();
            handleTranslate();
        }
    });
}

// ---- Source Input ----
function onSourceInput() {
    const len = sourceText.value.length;
    charCount.textContent = `${len}文字`;
    clearBtn.style.display = len > 0 ? "inline" : "none";
    updateTranslateButton();
}

function clearInput() {
    sourceText.value = "";
    onSourceInput();
    resultContainer.style.display = "none";
    sourceText.focus();
}

function updateTranslateButton() {
    const hasKey = !!getApiKey();
    const hasText = sourceText.value.trim().length > 0;
    translateBtn.disabled = !hasKey || !hasText || isTranslating;
}

// ---- Language Swap ----
function swapLanguages() {
    if (sourceLang.value === "auto") {
        showToast("自動検出からは入れ替えできません");
        return;
    }
    const temp = sourceLang.value;
    sourceLang.value = targetLang.value;
    targetLang.value = temp;

    // Swap text and result if both exist
    if (resultText.textContent && resultContainer.style.display !== "none") {
        const tempText = sourceText.value;
        sourceText.value = resultText.textContent;
        resultText.textContent = tempText;
        onSourceInput();
    }
}

// ---- Translation ----
async function handleTranslate() {
    const text = sourceText.value.trim();
    if (!text || isTranslating) return;

    const apiKey = getApiKey();
    if (!apiKey) {
        openSettings();
        return;
    }

    setLoading(true);

    try {
        const srcLang = sourceLang.value;
        const tgtLang = targetLang.value;
        const srcName = LANG_NAMES[srcLang] || srcLang;
        const tgtName = LANG_NAMES[tgtLang] || tgtLang;

        let prompt;
        if (srcLang === "auto") {
            prompt = `Translate the following text to ${tgtName}. Output ONLY the translated text, nothing else. No explanations, no notes.\n\n${text}`;
        } else {
            prompt = `Translate the following text from ${srcName} to ${tgtName}. Output ONLY the translated text, nothing else. No explanations, no notes.\n\n${text}`;
        }

        const response = await fetch(`${GEMINI_API_URL}?key=${apiKey}`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                contents: [{ parts: [{ text: prompt }] }],
                generationConfig: {
                    temperature: 0.2,
                    maxOutputTokens: 4096,
                },
            }),
        });

        if (!response.ok) {
            const errData = await response.json().catch(() => null);
            if (response.status === 400 || response.status === 403) {
                throw new Error("APIキーが無効です。設定を確認してください。");
            }
            throw new Error(errData?.error?.message || `APIエラー (${response.status})`);
        }

        const data = await response.json();
        const translated = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim();

        if (!translated) {
            throw new Error("翻訳結果を取得できませんでした。");
        }

        // Show result
        resultText.textContent = translated;
        resultLang.textContent = tgtName;
        resultContainer.style.display = "block";

        // Save to history
        addToHistory({
            source: text,
            result: translated,
            srcLang: srcLang === "auto" ? "auto" : srcLang,
            tgtLang,
            timestamp: Date.now(),
        });
    } catch (error) {
        showToast(error.message || "翻訳に失敗しました");
    } finally {
        setLoading(false);
    }
}

function setLoading(loading) {
    isTranslating = loading;
    btnText.style.display = loading ? "none" : "inline";
    btnLoading.style.display = loading ? "inline-flex" : "none";
    updateTranslateButton();
}

// ---- Copy ----
async function copyResult() {
    const text = resultText.textContent;
    if (!text) return;

    try {
        await navigator.clipboard.writeText(text);
        showToast("コピーしました");
    } catch {
        // Fallback for older browsers
        const ta = document.createElement("textarea");
        ta.value = text;
        ta.style.position = "fixed";
        ta.style.opacity = "0";
        document.body.appendChild(ta);
        ta.select();
        document.execCommand("copy");
        document.body.removeChild(ta);
        showToast("コピーしました");
    }
}

// ---- Settings ----
function openSettings() {
    settingsModal.style.display = "flex";
    apiKeyInput.value = getApiKey() || "";
    keyStatus.textContent = "";
    keyStatus.className = "key-status";
}

function closeSettingsModal() {
    settingsModal.style.display = "none";
}

function toggleKeyVisibility() {
    apiKeyInput.type = apiKeyInput.type === "password" ? "text" : "password";
}

function saveApiKey() {
    const key = apiKeyInput.value.trim();
    if (!key) {
        keyStatus.textContent = "APIキーを入力してください";
        keyStatus.className = "key-status error";
        return;
    }
    localStorage.setItem(STORAGE_KEY_API, key);
    keyStatus.textContent = "保存しました";
    keyStatus.className = "key-status success";
    updateTranslateButton();
    setTimeout(closeSettingsModal, 800);
}

function loadApiKey() {
    const key = getApiKey();
    if (!key) {
        // First visit: auto-open settings
        setTimeout(openSettings, 500);
    }
}

function getApiKey() {
    return localStorage.getItem(STORAGE_KEY_API) || "";
}

// ---- History ----
function getHistory() {
    try {
        return JSON.parse(localStorage.getItem(STORAGE_KEY_HISTORY) || "[]");
    } catch {
        return [];
    }
}

function addToHistory(entry) {
    const history = getHistory();
    history.unshift(entry);
    if (history.length > MAX_HISTORY) history.length = MAX_HISTORY;
    localStorage.setItem(STORAGE_KEY_HISTORY, JSON.stringify(history));
    renderHistory(history);
}

function loadHistory() {
    const history = getHistory();
    renderHistory(history);
}

function renderHistory(history) {
    if (history.length === 0) {
        historyContainer.style.display = "none";
        return;
    }
    historyContainer.style.display = "block";
    historyList.innerHTML = history
        .map(
            (item, i) => `
        <div class="history-item" data-index="${i}">
            <div class="history-item-lang">${LANG_NAMES[item.srcLang] || item.srcLang} → ${LANG_NAMES[item.tgtLang] || item.tgtLang}</div>
            <div class="history-item-source">${escapeHtml(item.source)}</div>
            <div class="history-item-result">${escapeHtml(item.result)}</div>
        </div>
    `
        )
        .join("");

    // Click to reuse
    historyList.querySelectorAll(".history-item").forEach((el) => {
        el.addEventListener("click", () => {
            const idx = parseInt(el.dataset.index);
            const item = history[idx];
            if (!item) return;
            sourceText.value = item.source;
            if (item.srcLang !== "auto") sourceLang.value = item.srcLang;
            targetLang.value = item.tgtLang;
            resultText.textContent = item.result;
            resultLang.textContent = LANG_NAMES[item.tgtLang] || item.tgtLang;
            resultContainer.style.display = "block";
            onSourceInput();
            window.scrollTo({ top: 0, behavior: "smooth" });
        });
    });
}

function clearHistory() {
    localStorage.removeItem(STORAGE_KEY_HISTORY);
    renderHistory([]);
    showToast("履歴を削除しました");
}

// ---- Utilities ----
function escapeHtml(str) {
    const div = document.createElement("div");
    div.textContent = str;
    return div.innerHTML;
}

function showToast(message) {
    const existing = document.querySelector(".toast");
    if (existing) existing.remove();

    const toast = document.createElement("div");
    toast.className = "toast";
    toast.textContent = message;
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 2200);
}

// ---- Start ----
init();

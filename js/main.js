/* ============================================
   ICS Watch Dog
   Cutaway Security, LLC

   Based on CutSec Base JavaScript.
   Provides: dark/light theme toggle,
   copy-to-clipboard, response block toggle,
   collapsible section toggle, and nav toggle.

   All interactive handlers use event delegation
   (single listener on document) for CSP
   compatibility and dynamic content support.
   ============================================ */

/**
 * Dark / light theme toggle.
 * Persists choice in localStorage; respects prefers-color-scheme as default.
 */
(function () {
  var STORAGE_KEY = 'theme';

  function getPreferred() {
    var saved = localStorage.getItem(STORAGE_KEY);
    if (saved === 'dark' || saved === 'light') return saved;
    if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) return 'dark';
    return 'light';
  }

  function applyTheme(theme) {
    document.documentElement.setAttribute('data-theme', theme);
    var btn = document.querySelector('.theme-toggle');
    if (btn) btn.textContent = theme === 'dark' ? '\u2600' : '\u263E';
  }

  document.addEventListener('DOMContentLoaded', function () {
    var btn = document.querySelector('.theme-toggle');
    if (!btn) return;
    applyTheme(getPreferred());
  });

  window._cutsecApplyTheme = applyTheme;
  window._cutsecGetPreferred = getPreferred;
})();

/**
 * Copy the text content of a query block to the clipboard.
 */
function copyBlock(button) {
  var block = button.closest('.query-block');
  var code = block.querySelector('pre code');
  if (!code) return;

  var text = code.textContent;

  navigator.clipboard.writeText(text).then(function () {
    button.textContent = 'Copied!';
    button.classList.add('copied');
    setTimeout(function () {
      button.textContent = 'Copy';
      button.classList.remove('copied');
    }, 2000);
  }).catch(function () {
    var textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    textarea.select();
    try {
      document.execCommand('copy');
      button.textContent = 'Copied!';
      button.classList.add('copied');
      setTimeout(function () {
        button.textContent = 'Copy';
        button.classList.remove('copied');
      }, 2000);
    } catch (e) {
      button.textContent = 'Failed';
      setTimeout(function () {
        button.textContent = 'Copy';
      }, 2000);
    }
    document.body.removeChild(textarea);
  });
}

/**
 * Toggle visibility of a response block's content.
 */
function toggleResponse(button) {
  var block = button.closest('.response-block');
  var content = block.querySelector('.response-content');
  if (!content) return;

  var isHidden = content.hasAttribute('hidden');
  if (isHidden) {
    content.removeAttribute('hidden');
    button.textContent = 'Hide Expected Response';
  } else {
    content.setAttribute('hidden', '');
    button.textContent = 'Show Expected Response';
  }
}

/**
 * Toggle visibility of a collapsible section.
 * Used only for the JS-based .collapsible component (advanced use).
 */
function toggleSection(button) {
  var block = button.closest('.collapsible');
  var content = block.querySelector('.collapsible-content');
  if (!content) return;

  var isHidden = content.hasAttribute('hidden');
  if (isHidden) {
    content.removeAttribute('hidden');
    block.classList.add('open');
    button.setAttribute('aria-expanded', 'true');
  } else {
    content.setAttribute('hidden', '');
    block.classList.remove('open');
    button.setAttribute('aria-expanded', 'false');
  }
}

/**
 * Delegated click handler.
 * Routes clicks to the appropriate handler based on the target element.
 * Replaces inline onclick attributes for CSP compatibility.
 */
document.addEventListener('click', function (event) {
  /* Theme toggle */
  var themeBtn = event.target.closest('.theme-toggle');
  if (themeBtn) {
    var current = document.documentElement.getAttribute('data-theme') || 'light';
    var next = current === 'dark' ? 'light' : 'dark';
    localStorage.setItem('theme', next);
    window._cutsecApplyTheme(next);
    return;
  }

  /* Mobile nav toggle */
  var navToggle = event.target.closest('.nav-toggle');
  if (navToggle) {
    var navLinks = navToggle.nextElementSibling;
    if (navLinks) navLinks.classList.toggle('open');
    return;
  }

  /* Copy button */
  var copyBtn = event.target.closest('.copy-btn');
  if (copyBtn) {
    copyBlock(copyBtn);
    return;
  }

  /* Response toggle */
  var toggleBtn = event.target.closest('.toggle-btn');
  if (toggleBtn) {
    toggleResponse(toggleBtn);
    return;
  }

  /* Collapsible section toggle */
  var sectionToggle = event.target.closest('.section-toggle');
  if (sectionToggle) {
    toggleSection(sectionToggle);
    return;
  }
});

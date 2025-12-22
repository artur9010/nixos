// AI GENERATED

// ==UserScript==
// @name         Piped Redirect (Watch + Shorts + SPA)
// @namespace    Backend
// @version      2.2
// @description  Redirect YouTube watch/shorts/youtu.be to Piped (SPA-safe)
// @include      *://*.youtube.com/*
// @include      *://youtube.com/*
// @include      *://m.youtube.com/*
// @include      *://music.youtube.com/*
// @include      *://youtu.be/*
// @homepageURL  https://chatgpt.com/c/6948c045-96d0-832b-8807-86fd79eb060a
// @run-at       document-start
// @grant        none
// ==/UserScript==

(function () {
  'use strict';

  // nie rób nic w iframe
  if (window.top !== window.self) return;

  const PIPED_BASE = 'https://piped.r00t.party';
  const CHECK_EVERY_MS = 400;

  let lastHref = '';

  function buildTarget(url) {
    // youtu.be/ID
    if (url.hostname === 'youtu.be') {
      const id = url.pathname.split('/').filter(Boolean)[0];
      if (!id) return null;
      const params = new URLSearchParams(url.searchParams);
      params.set('v', id);
      return `${PIPED_BASE}/watch?${params.toString()}`;
    }

    // tylko domeny youtube
    if (!url.hostname.endsWith('youtube.com')) return null;

    // /watch?v=...
    if (url.pathname === '/watch') {
      const v = url.searchParams.get('v');
      if (!v) return null;

      // nie przekierowuj "Watch Later"
      if (url.searchParams.get('list') === 'WL') return null;

      return `${PIPED_BASE}/watch?${url.searchParams.toString()}`;
    }

    // /shorts/ID  -> /watch?v=ID
    if (url.pathname.startsWith('/shorts/')) {
      const parts = url.pathname.split('/').filter(Boolean);
      const id = parts[1];
      if (!id) return null;

      const params = new URLSearchParams(url.searchParams);
      params.set('v', id);
      params.delete('feature'); // często z share

      return `${PIPED_BASE}/watch?${params.toString()}`;
    }

    return null;
  }

  function checkAndRedirect() {
    const href = location.href;
    if (href === lastHref) return;
    lastHref = href;

    let url;
    try {
      url = new URL(href);
    } catch {
      return;
    }

    const target = buildTarget(url);
    if (!target) return;

    if (location.href !== target) {
      location.replace(target);
    }
  }

  // start
  checkAndRedirect();

  // YouTube SPA navigation events
  window.addEventListener('yt-navigate-start', checkAndRedirect, true);
  window.addEventListener('yt-navigate-finish', checkAndRedirect, true);
  window.addEventListener('popstate', checkAndRedirect, true);

  // fallback (gdy eventy nie przejdą)
  setInterval(checkAndRedirect, CHECK_EVERY_MS);
})();

/**
 * Promo Auto-Archive — Archives promotional emails older than 21 days.
 *
 * Setup:
 *   1. Go to https://script.google.com → New Project
 *   2. Paste this entire file into Code.gs
 *   3. Run archiveOldPromos() once manually to grant permissions
 *   4. Go to Triggers (clock icon) → Add Trigger:
 *      - Function: archiveOldPromos
 *      - Event source: Time-driven
 *      - Type: Day timer
 *      - Time: 2am-3am (runs while you sleep)
 *   5. Save. Done. It runs daily.
 */

var DAYS_THRESHOLD = 21;

function archiveOldPromos() {
  var cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - DAYS_THRESHOLD);

  var formattedDate = Utilities.formatDate(cutoffDate, Session.getScriptTimeZone(), 'yyyy/MM/dd');

  // Search for promotional emails older than threshold that are still in inbox
  var query = 'category:promotions in:inbox before:' + formattedDate;

  var threads = GmailApp.search(query, 0, 100);

  if (threads.length === 0) {
    Logger.log('No promotional emails older than ' + DAYS_THRESHOLD + ' days found in inbox.');
    return;
  }

  // Archive them (removes from inbox, keeps in All Mail)
  for (var i = 0; i < threads.length; i++) {
    threads[i].moveToArchive();
  }

  Logger.log('Archived ' + threads.length + ' promotional email threads older than ' + DAYS_THRESHOLD + ' days.');

  // If there might be more than 100, run again
  if (threads.length === 100) {
    Logger.log('Hit batch limit — re-running to catch remaining threads.');
    archiveOldPromos();
  }
}

/**
 * One-time cleanup: archives ALL old promos, not just inbox ones.
 * Run this once if you want a fresh start, then let the daily trigger handle the rest.
 */
function initialPromoCleanup() {
  var cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - DAYS_THRESHOLD);
  var formattedDate = Utilities.formatDate(cutoffDate, Session.getScriptTimeZone(), 'yyyy/MM/dd');

  var query = 'category:promotions is:unread before:' + formattedDate;
  var threads = GmailApp.search(query, 0, 100);

  if (threads.length === 0) {
    Logger.log('No old unread promos found.');
    return;
  }

  for (var i = 0; i < threads.length; i++) {
    threads[i].markRead();
    threads[i].moveToArchive();
  }

  Logger.log('Cleaned up ' + threads.length + ' old unread promo threads.');

  if (threads.length === 100) {
    initialPromoCleanup();
  }
}

/**
 * Academic Deadline Watcher — Sends ADHD-friendly reminder emails
 * for upcoming Canvas calendar events.
 *
 * Setup:
 *   1. Go to https://script.google.com → New Project
 *   2. Paste this entire file into Code.gs
 *   3. Run sendDeadlineDigest() once manually to grant permissions
 *   4. Go to Triggers (clock icon) → Add Trigger:
 *      - Function: sendDeadlineDigest
 *      - Event source: Time-driven
 *      - Type: Day timer
 *      - Time: 7am-8am (before Morning Launch Pad)
 *   5. Save. Done.
 *
 * Also add a Sunday trigger for sendWeeklyDeadlineOverview() at 9am
 * (before your Weekly Planning & Review block at 10am).
 */

// === CONFIGURATION ===
var CONFIG = {
  canvasCalendarId: 'ngogo45475nlor5d2p3t3avfh4his7cp@import.calendar.google.com',
  recipientEmail: 'shelcaddell@gmail.com',
  // ADHD time multiplier: how much longer things actually take vs. estimate
  // 1.5x is a good ADHD baseline. Adjust based on experience.
  timeMultiplier: 1.5,
  // How many days ahead to look for the daily digest
  dailyLookaheadDays: 3,
  // How many days ahead for the weekly overview
  weeklyLookaheadDays: 10
};

// === DAILY DIGEST ===
function sendDeadlineDigest() {
  var now = new Date();
  var lookahead = new Date(now.getTime() + CONFIG.dailyLookaheadDays * 24 * 60 * 60 * 1000);

  var calendar = CalendarApp.getCalendarById(CONFIG.canvasCalendarId);
  if (!calendar) {
    Logger.log('ERROR: Canvas calendar not found. Check calendar ID.');
    return;
  }

  var events = calendar.getEvents(now, lookahead);

  if (events.length === 0) {
    Logger.log('No upcoming deadlines in the next ' + CONFIG.dailyLookaheadDays + ' days.');
    return;
  }

  // Sort by start time
  events.sort(function(a, b) { return a.getStartTime() - b.getStartTime(); });

  var subject = '[Deadlines] ' + events.length + ' item(s) due in next ' + CONFIG.dailyLookaheadDays + ' days';
  var body = buildDailyEmail(events, now);

  GmailApp.sendEmail(CONFIG.recipientEmail, subject, '', {
    htmlBody: body,
    name: 'Deadline Watcher'
  });

  Logger.log('Sent deadline digest with ' + events.length + ' events.');
}

function buildDailyEmail(events, now) {
  var html = '<div style="font-family: -apple-system, sans-serif; max-width: 600px; margin: 0 auto;">';
  html += '<h2 style="color: #d32f2f; margin-bottom: 4px;">Upcoming Deadlines</h2>';
  html += '<p style="color: #666; margin-top: 0;">As of ' + Utilities.formatDate(now, Session.getScriptTimeZone(), 'EEEE, MMM d \'at\' h:mm a') + '</p>';

  for (var i = 0; i < events.length; i++) {
    var event = events[i];
    var start = event.getStartTime();
    var hoursUntil = Math.round((start.getTime() - now.getTime()) / (1000 * 60 * 60));
    var urgencyColor = hoursUntil <= 24 ? '#d32f2f' : hoursUntil <= 48 ? '#f57c00' : '#388e3c';
    var urgencyLabel = hoursUntil <= 24 ? 'DUE TODAY/TOMORROW' : hoursUntil <= 48 ? 'DUE SOON' : 'UPCOMING';

    html += '<div style="border-left: 4px solid ' + urgencyColor + '; padding: 8px 12px; margin: 12px 0; background: #fafafa;">';
    html += '<div style="display: flex; justify-content: space-between;">';
    html += '<strong>' + event.getTitle() + '</strong>';
    html += '</div>';
    html += '<div style="color: #666; font-size: 14px;">';
    html += '<span style="background: ' + urgencyColor + '; color: white; padding: 2px 6px; border-radius: 3px; font-size: 11px; font-weight: bold;">' + urgencyLabel + '</span> ';
    html += Utilities.formatDate(start, Session.getScriptTimeZone(), 'EEE MMM d, h:mm a');
    html += ' (' + hoursUntil + 'h from now)';
    html += '</div>';

    // ADHD time budget
    var estimatedMinutes = Math.round(60 * CONFIG.timeMultiplier);
    html += '<div style="color: #1565c0; font-size: 13px; margin-top: 4px;">';
    html += 'ADHD time budget: ~' + estimatedMinutes + ' min (default 1hr x ' + CONFIG.timeMultiplier + ' multiplier)';
    html += '</div>';

    html += '</div>';
  }

  html += '<hr style="margin-top: 20px; border: none; border-top: 1px solid #ddd;">';
  html += '<p style="color: #999; font-size: 12px;">Sent by Academic Deadline Watcher. ';
  html += 'Edit time multiplier in script config (currently ' + CONFIG.timeMultiplier + 'x).</p>';
  html += '</div>';

  return html;
}

// === WEEKLY OVERVIEW (run Sundays before Weekly Planning block) ===
function sendWeeklyDeadlineOverview() {
  var now = new Date();
  var lookahead = new Date(now.getTime() + CONFIG.weeklyLookaheadDays * 24 * 60 * 60 * 1000);

  var calendar = CalendarApp.getCalendarById(CONFIG.canvasCalendarId);
  if (!calendar) {
    Logger.log('ERROR: Canvas calendar not found.');
    return;
  }

  var events = calendar.getEvents(now, lookahead);
  events.sort(function(a, b) { return a.getStartTime() - b.getStartTime(); });

  var subject = '[Week Ahead] ' + events.length + ' deadline(s) in next ' + CONFIG.weeklyLookaheadDays + ' days';
  var html = '<div style="font-family: -apple-system, sans-serif; max-width: 600px; margin: 0 auto;">';
  html += '<h2 style="color: #1565c0;">Week Ahead: Academic Deadlines</h2>';
  html += '<p style="color: #666;">Use this during your Weekly Planning & Review block (Sun 10-11 AM).</p>';

  // Group by day
  var dayMap = {};
  for (var i = 0; i < events.length; i++) {
    var dayKey = Utilities.formatDate(events[i].getStartTime(), Session.getScriptTimeZone(), 'yyyy-MM-dd');
    if (!dayMap[dayKey]) dayMap[dayKey] = [];
    dayMap[dayKey].push(events[i]);
  }

  var sortedDays = Object.keys(dayMap).sort();
  for (var d = 0; d < sortedDays.length; d++) {
    var day = sortedDays[d];
    var dayEvents = dayMap[day];
    var dayDate = new Date(day + 'T12:00:00');
    var dayLabel = Utilities.formatDate(dayDate, Session.getScriptTimeZone(), 'EEEE, MMM d');

    html += '<h3 style="color: #333; margin-bottom: 4px; border-bottom: 1px solid #eee; padding-bottom: 4px;">' + dayLabel + '</h3>';

    for (var j = 0; j < dayEvents.length; j++) {
      var evt = dayEvents[j];
      html += '<div style="padding: 4px 0 4px 12px; font-size: 14px;">';
      html += '&#8226; <strong>' + evt.getTitle() + '</strong>';
      if (!evt.isAllDayEvent()) {
        html += ' <span style="color: #666;">at ' + Utilities.formatDate(evt.getStartTime(), Session.getScriptTimeZone(), 'h:mm a') + '</span>';
      }
      html += '</div>';
    }
  }

  if (events.length === 0) {
    html += '<p style="color: #388e3c; font-size: 16px;">No deadlines in the next ' + CONFIG.weeklyLookaheadDays + ' days. Rare W.</p>';
  }

  html += '<hr style="margin-top: 20px; border: none; border-top: 1px solid #ddd;">';
  html += '<p style="color: #999; font-size: 12px;">Sent by Academic Deadline Watcher (weekly overview).</p>';
  html += '</div>';

  GmailApp.sendEmail(CONFIG.recipientEmail, subject, '', {
    htmlBody: html,
    name: 'Deadline Watcher'
  });

  Logger.log('Sent weekly overview with ' + events.length + ' events over ' + sortedDays.length + ' days.');
}

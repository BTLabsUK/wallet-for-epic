// SPDX-License-Identifier: Apache-2.0
/// The short payment lists on Home (phone), Overview (desktop) and a contact's page: how many
/// rows they show, and when their "View all" link shows. One rule for both platforms.
library;

/// Rows a short payment list shows.
const int recentActivityCount = 5;

/// Whether a short list of [count] payments offers "View all": only from
/// [recentActivityCount] payments on, so one or a few rows never carry a link to the same rows.
bool showViewAll(int count) => count >= recentActivityCount;
